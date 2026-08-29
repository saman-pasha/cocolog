/* zigurat.c -- the Zigurat binary protocol, in C. See zigurat.h. */

#include "zigurat.h"

#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

/* A write to a connection the server has already dropped raises SIGPIPE, and
 * the default disposition of SIGPIPE kills the process -- so a library that
 * did not ask for MSG_NOSIGNAL would take its caller down instead of answering
 * 0 with "the server closed the connection". Changing the signal disposition
 * would work too and is not a library's business: it is global, and a program
 * linking this one may want SIGPIPE for something else.
 *
 * Not every platform has the flag; where it is missing it is 0, and send()
 * behaves as it always did. */
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

/* Type-descriptor bytes, from Type/tdbyte.cpp. Written out rather than
 * computed so that a change on that side shows up here as a mismatch in one
 * place instead of as a wrong-looking value somewhere downstream. */
#define TDB_IS_NULL   0x80u

#define TDB_SCALE_MASK 0x60u
#define TDB_SCALE_ATOM 0x00u   /* the value itself                     */
#define TDB_SCALE_BYTE 0x20u   /* uint8  count, then that many elements */
#define TDB_SCALE_WORD 0x40u   /* uint16 count                          */
#define TDB_SCALE_DWRD 0x60u   /* uint32 count -- a Vector              */

#define TDB_TYPE_MASK  0x07u   /* size class: bytes = 1 << (class - 1)  */

#define TDB_BOOL      0x09u
#define TDB_INT       0x0Bu
#define TDB_LONG      0x0Cu
#define TDB_DOUBLE    0x1Cu
#define TDB_STRING    0x29u
#define TDB_TEXT      0x49u

/* One request is a few dozen bytes -- a verb, a name and a handful of
 * parameters -- and anything longer than this goes straight out rather than
 * being copied in, so it never has to be large. */
#define ZG_OUT_SIZE 1024
/* One page of read-ahead. Bigger than any single protocol value, so the common
 * case is one syscall per exchange rather than one per byte. */
#define ZG_IN_SIZE  8192

/* THE EMBEDDED ENGINE, WHEN A BUILD CARRIES ONE. embed/embed.o implements
 * the same eighteen procedures the server does, in-process, and these are
 * its entry points. They are declared WEAK: a build that did not link the
 * engine leaves them null, zg_open_embed then refuses with a message, and
 * nothing else in this file is any different -- which is what keeps the
 * client buildable with nothing but libc, as its head promises.
 * `weak_import' on Darwin, for the reason zeytun.h's COCO_WEAK gives. */
#ifdef __APPLE__
#define CE_WEAK __attribute__((weak_import))
#else
#define CE_WEAK __attribute__((weak))
#endif
extern int  ce_engine_open(const char *dir, char *err, size_t errcap) CE_WEAK;
extern void ce_engine_close(void) CE_WEAK;
extern void *ce_session_new(void) CE_WEAK;
extern void ce_session_free(void *s) CE_WEAK;
extern const char *ce_error(void *s) CE_WEAK;
extern int  ce_call(void *s, const char *proc) CE_WEAK;
extern int  ce_write_num(void *s, int tag, long long v) CE_WEAK;
extern int  ce_write_str(void *s, int tag, const char *v) CE_WEAK;
extern int  ce_write_dvector(void *s, const double *v, uint32_t n) CE_WEAK;
extern int  ce_read_dvector(void *s, double *out, uint32_t cap, uint32_t *n) CE_WEAK;
extern int  ce_result(void *s, int *out) CE_WEAK;
extern int  ce_columns(void *s, char *buf, size_t cap) CE_WEAK;
extern int  ce_read_num(void *s, long long *v) CE_WEAK;
extern int  ce_read_str(void *s, char *buf, size_t cap) CE_WEAK;
extern int  ce_read_str_alloc(void *s, char **out, size_t *len) CE_WEAK;
extern int  ce_skip(void *s) CE_WEAK;
extern int  ce_commit(void *s) CE_WEAK;
extern int  ce_rollback(void *s) CE_WEAK;
extern int  ce_isolate(void *s, int level) CE_WEAK;
extern int  ce_reset(void *s) CE_WEAK;

struct zg_conn {
  int  fd;
  /* THE TLS HANDLE, or null on a plain connection. ZiguratIP's
   * `SERVER/TLS_MODE: TRUE' turns 2160 into an encrypted port -- the same
   * port, a different thing on it.
   *
   * A CLIENT CERTIFICATE IS OPTIONAL HERE, and the server says which:
   * `SERVER/TLS_CLIENT_AUTH' takes REQUIRED (the default), OPTIONAL or
   * NONE, so `--tls' with no `--cert' is a real arrangement and not a
   * half-configured one.
   *
   * WHAT A CERTIFICATE IS MANDATORY FOR is PERMISSIONS. ZiguratIP's TLS
   * handler identifies every TLS peer, certificate or not -- a peer with
   * none is identified with an empty subject and an empty permission set
   * -- and `Globals::permits' allows everything only to a peer that is
   * NOT identified, which is to say a plain connection. So with
   * `SECURITY/PERMISSIONS_MODE' on: plain reaches everything, TLS with a
   * certificate reaches what the certificate grants, and TLS WITHOUT one
   * reaches nothing. Turning TLS on is what turns access control on.
   *
   * REACHED WEAKLY, like zeytun.c's: client/tls.o is linked into the
   * cocolog binary and NOT into libcocologc.a, so a program that links
   * only the archive gets null here and plaintext is unaffected. */
  void *tls;
  /* the embedded session, when zg_open_embed made this handle; null on a
   * socket handle, and every verb below branches on it first */
  void *ce;
  uint64_t transaction_id;
  char err[512];
  /* Taking turns: see zg_serialise. lockfd is -1 when nothing is serialised
   * and `held' says whether this connection is holding the turn. */
  int  lockfd;
  int  held;
  int  lockwait;
  /* Outgoing bytes, held back until something wants to read. See wr(). */
  unsigned char out[ZG_OUT_SIZE];
  size_t nout;
  /* Incoming bytes, read ahead. See rd(). `pin' is how far the protocol has
   * consumed and `nin' how far the socket has filled. */
  unsigned char in[ZG_IN_SIZE];
  size_t nin, pin;
};

/* ------------------------------------------------------------------ */
/* errors                                                             */
/* ------------------------------------------------------------------ */

/* Every failure goes through one of these two, so a caller that answers 0 has
 * always left a message behind. There is no printf-shaped helper: the messages
 * are a literal, or a literal and one string, and a varargs one would be the
 * only thing in this file that could overflow a buffer. */
static int say(zg_conn *c, const char *what)
{
  if (c) snprintf(c->err, sizeof c->err, "%s", what);
  return 0;
}

static int say2(zg_conn *c, const char *what, const char *detail)
{
  if (c) snprintf(c->err, sizeof c->err, "%s: %s", what, detail);
  return 0;
}

const char *zg_error(const zg_conn *c) { return c ? c->err : "no connection"; }

int zg_is_open(const zg_conn *c) { return (c && (c->ce || c->fd >= 0)) ? 1 : 0; }

uint64_t zg_transaction_id(const zg_conn *c) { return c ? c->transaction_id : 0; }

/* ------------------------------------------------------------------ */
/* taking turns                                                       */
/* ------------------------------------------------------------------ */

/* Waits for this connection's turn. Answers 1 immediately when nothing is
 * serialised, or when this connection already holds it.
 *
 * IT IS A POLL AND NOT A BLOCKING flock, and the reason is a deadlock that a
 * blocking one really does reach. A worker holding the turn can end up waiting
 * on the server for a row another worker's uncommitted transaction has locked
 * -- and that other worker is waiting for the turn so that it can commit and
 * let go. Neither ever moves. Giving up after a bounded wait turns that into
 * an ordinary failure: the caller redials, the abandoned transaction goes with
 * the connection, and the row is free again.
 *
 * 2ms between tries. A call is short, so the wait is nearly always the first
 * or second one, and a thousand of them still only add up to two seconds. */
static int take_turn(zg_conn *c)
{
  int waited_ms = 0;
  if (c->lockfd < 0 || c->held) return 1;
  for (;;) {
    if (flock(c->lockfd, LOCK_EX | LOCK_NB) == 0) { c->held = 1; return 1; }
    if (errno != EWOULDBLOCK && errno != EINTR)
      return say2(c, "cannot take the turn", strerror(errno));
    if (c->lockwait > 0 && waited_ms >= c->lockwait * 1000)
      return say(c, "timed out waiting for another cocolog process");
    usleep(2000);
    waited_ms += 2;
  }
}

/* Gives the turn up. Safe to call when it is not held, which is what makes it
 * usable on every path out of every verb. */
static void give_turn(zg_conn *c)
{
  if (c->lockfd >= 0 && c->held) {
    flock(c->lockfd, LOCK_UN);
    c->held = 0;
  }
}

int zg_embedded(zg_conn *c)
{
  return c && c->ce ? 1 : 0;
}

int zg_serialise(zg_conn *c, const char *path, int wait_seconds)
{
  /* an embedded store has no second process to take turns with */
  if (c && c->ce) return 1;
  int fd;
  if (!c) return 0;
  if (c->lockfd >= 0) { give_turn(c); close(c->lockfd); c->lockfd = -1; }
  if (!path || !*path) return 1;             /* asked for none: none it is */
  fd = open(path, O_RDWR | O_CREAT, 0666);
  if (fd < 0) return say2(c, "cannot open the turn file", strerror(errno));
  c->lockfd   = fd;
  c->lockwait = wait_seconds;
  return 1;
}

/* ------------------------------------------------------------------ */
/* the socket                                                         */
/* ------------------------------------------------------------------ */

/* A FAILED TRANSFER ENDS THE CONNECTION. This protocol has no resynchronising
 * point: every value is a length the other side already committed to, so a read
 * that stopped halfway or a write that did not land leaves the stream at an
 * offset neither side agrees on. Carrying on down it reads one field as
 * another. Both of these therefore drop the socket on their way out, and
 * zg_is_open answers the question "is there anything left to talk to". */
static int lost(zg_conn *c, const char *what, const char *detail)
{
  if (c->fd >= 0) { close(c->fd); c->fd = -1; }
  /* Whatever was read ahead belonged to the connection that just died. */
  c->nin = c->pin = 0;
  give_turn(c);
  return detail ? say2(c, what, detail) : say(c, what);
}

static int flush_out(zg_conn *c);

/* WHY A READ OR WRITE STOPPED, in the words of whichever layer knows.
 * On a plain socket that is errno and nothing else. On a TLS one errno
 * is usually 0 or misleading -- the failure happened inside the session
 * -- and client/tls.c has the alert. THE CASE THIS IS FOR: a ZiguratIP
 * with `SERVER/TLS_CLIENT_AUTH: REQUIRED' and a cocolog with no
 * `--cert'. Under TLS 1.3 the client finishes talking before the server
 * examines what it sent, so the handshake succeeds and the refusal comes
 * back as an alert on the first read -- which without this reads as
 * `read failed: Success' and sends the reader to the wrong end. */
static const char *why(zg_conn *c, char *buf, size_t cap)
{
  if (c->tls && coco_client_tls_why && coco_client_tls_why(c->tls, buf, cap))
    return buf;
  return strerror(errno);
}

/* Reads exactly N bytes or fails. A short read is not an error condition the
 * protocol can recover from -- every value has a known length -- so it is
 * always looped.
 *
 * IT READS AHEAD, and that is not an optimisation of the tidying-up kind. The
 * protocol is made of small values -- a result byte, a length, a field -- and
 * rd_u8 asks for exactly one byte. Unbuffered, that is one recv syscall per
 * byte: one `cocolog step' against an idle server measured 957 recvfrom and
 * 383 sendto for a few dozen bytes of actual conversation, and the syscalls,
 * not the work, were what made twelve workers take a minute.
 *
 * Reading ahead is safe because this end owns the socket outright: anything
 * the server has sent is this connection's, whether or not the protocol has
 * asked for it yet. The buffer is emptied wherever the socket is replaced --
 * see lost() and zg_redial -- because bytes from a connection that is gone
 * must not be read as if they came from its successor. */
static int rd(zg_conn *c, void *buf, size_t n)
{
  unsigned char *p = (unsigned char *)buf;
  size_t got = 0;
  if (c->fd < 0) return say(c, "the connection is closed");
  while (got < n) {
    size_t have = c->nin - c->pin;
    if (have > 0) {
      size_t take = (have < n - got) ? have : n - got;
      memcpy(p + got, c->in + c->pin, take);
      c->pin += take;
      got += take;
      continue;
    }
    /* Nothing left in hand. Nothing of ours may sit unsent while this end
     * waits for an answer to it, so the outgoing buffer goes first. */
    if (!flush_out(c)) return 0;
    c->nin = c->pin = 0;
    {
      ssize_t k = c->tls ? (ssize_t) coco_client_tls_recv(c->tls, c->in, sizeof c->in)
                         : recv(c->fd, c->in, sizeof c->in, 0);
      if (k <= 0) {
        char w[256];
        if (k < 0 && errno == EINTR) continue;
        /* A TLS read answers 0 for both a clean close and a broken one,
         * and the reason is what tells them apart. */
        if (k == 0 && !(c->tls && coco_client_tls_why &&
                        coco_client_tls_why(c->tls, w, sizeof w)))
          return lost(c, "the server closed the connection", NULL);
        return lost(c, "read failed", why(c, w, sizeof w));
      }
      c->nin = (size_t)k;
    }
  }
  return 1;
}

/* client/tls.c, weakly -- see the note by `tls' in struct zg_conn. */

/* THE PROCESS-WIDE SETTING, for the same reason zeytun.c has one: a
 * cocolog reaches one server, in an arrangement chosen once from argv
 * before the first goal runs. `zg_reopen' needs it too -- a connection
 * that was secure must come back secure, and it has nowhere else to
 * learn that from. */
static coco_tls_options g_tls;
static int              g_tls_on = 0;

void zg_tls_configure_flat(const char *cacert, const char *capath,
                           const char *cert, const char *key,
                           const char *key_pass, int insecure)
{
  memset(&g_tls, 0, sizeof g_tls);
  g_tls.cacert = cacert;
  g_tls.capath = capath;
  g_tls.cert = cert;
  g_tls.key = key;
  g_tls.key_pass = key_pass;
  g_tls.insecure = insecure;
  g_tls_on = 1;
}

/* Puts N bytes on the wire, now. */
static int wr_now(zg_conn *c, const void *buf, size_t n)
{
  const unsigned char *p = (const unsigned char *)buf;
  size_t sent = 0;
  if (c->fd < 0) return say(c, "the connection is closed");
  while (sent < n) {
    ssize_t k = c->tls ? (ssize_t) coco_client_tls_send(c->tls, p + sent, n - sent)
                       : send(c->fd, p + sent, n - sent, MSG_NOSIGNAL);
    if (k <= 0) {
      char w[256];
      if (k < 0 && errno == EINTR) continue;
      return lost(c, "write failed", why(c, w, sizeof w));
    }
    sent += (size_t)k;
  }
  return 1;
}

/* Sends whatever wr() has been holding. */
static int flush_out(zg_conn *c)
{
  size_t n = c->nout;
  if (n == 0) return 1;
  c->nout = 0;                    /* cleared first: a failed flush ends the
                                   * connection, and these bytes must not be
                                   * sent a second time by a later one */
  return wr_now(c, c->out, n);
}

/* A REQUEST GOES OUT IN ONE PIECE, AND THAT IS NOT ABOUT SYSCALL COUNT. Written
 * a field at a time -- a length byte, then the bytes, then the next type
 * descriptor -- a request reaches the server as a dozen separate arrivals, and
 * the server reads it through a std::streambuf whose underflow() flushes the
 * replies IT has pending only when it is about to block on the socket. Feed it
 * in dribs and it is never quite about to block: it comes back round its loop
 * with the next fragment already sitting in its get area, so it does not
 * flush, and the reply this end is waiting for stays in the server's put
 * buffer. Both ends then wait for each other, for ever.
 *
 * Measured: a client that writes field by field wedges after somewhere between
 * thirty and ninety calls on one connection, at no fixed point, and never once
 * it is slowed down enough to lose the race -- which is why it looks like a
 * different bug every time it is caught. Holding a request until it is
 * complete and sending it in one piece puts the server back to one arrival per
 * request, which is where it blocks, which is where it flushes.
 *
 * Anything longer than the buffer -- a Text carrying a chunk of a frozen
 * machine -- pushes out what is waiting and then goes straight to the socket. */
static int wr(zg_conn *c, const void *buf, size_t n)
{
  if (c->fd < 0) return say(c, "the connection is closed");
  if (n >= sizeof c->out) {
    if (!flush_out(c)) return 0;
    return wr_now(c, buf, n);
  }
  if (c->nout + n > sizeof c->out)
    if (!flush_out(c)) return 0;
  memcpy(c->out + c->nout, buf, n);
  c->nout += n;
  return 1;
}

/* Skips N bytes of a value this client does not want. */
static int skip(zg_conn *c, size_t n)
{
  unsigned char pail[512];
  while (n > 0) {
    size_t want = n < sizeof pail ? n : sizeof pail;
    if (!rd(c, pail, want)) return 0;
    n -= want;
  }
  return 1;
}

/* ------------------------------------------------------------------ */
/* primitives -- NETWORK byte order, native widths                     */
/* ------------------------------------------------------------------ */

/* THE WIRE IS BIG-ENDIAN, and it took a while to find out. StreamIO has two
 * stream families: hbostream writes the object's bytes as they sit in memory,
 * and nbostream reverses them on a little-endian host. Files and buffers use
 * the first; the SOCKET uses the second -- SocketIO/tcpstream.hpp reads
 * `class tcpstream : public nbostream'.
 *
 * Getting this wrong is not loud. A one-byte String length is unaffected, so
 * `echo' works perfectly; a four-byte Int is consumed at the right width and
 * merely holds the wrong number; but a Text's two-byte length arrives
 * byte-swapped, so a 15-byte value announces itself as 3840 and the server
 * blocks forever waiting for the rest of it. The first symptom of a
 * byte-order bug here is a hang in an unrelated-looking call. */
static int host_is_big_endian(void)
{
  const uint16_t one = 1;
  return ((const unsigned char *)&one)[0] == 0;
}

static void reorder(void *p, size_t n)
{
  unsigned char *b = (unsigned char *)p;
  size_t i;
  if (host_is_big_endian()) return;
  for (i = 0; i < n / 2; i++) {
    unsigned char t = b[i];
    b[i] = b[n - 1 - i];
    b[n - 1 - i] = t;
  }
}

/* Reads N bytes and puts them the way round this machine wants them. */
static int rd_be(zg_conn *c, void *v, size_t n)
{
  if (!rd(c, v, n)) return 0;
  reorder(v, n);
  return 1;
}

/* Writes N bytes the way round the wire wants them, without disturbing the
 * caller's value. 16 bytes is room for the widest thing the protocol carries
 * (a Real, which is a long double). */
static int wr_be(zg_conn *c, const void *v, size_t n)
{
  unsigned char tmp[16];
  if (n > sizeof tmp) return say(c, "a value wider than the protocol carries");
  memcpy(tmp, v, n);
  reorder(tmp, n);
  return wr(c, tmp, n);
}

static int rd_u8 (zg_conn *c, uint8_t  *v) { return rd(c, v, 1); }
static int rd_u16(zg_conn *c, uint16_t *v) { return rd_be(c, v, 2); }
static int rd_u32(zg_conn *c, uint32_t *v) { return rd_be(c, v, 4); }
static int rd_sz (zg_conn *c, size_t   *v) { return rd_be(c, v, sizeof(size_t)); }

static int wr_u8 (zg_conn *c, uint8_t  v)  { return wr(c, &v, 1); }
static int wr_u16(zg_conn *c, uint16_t v)  { return wr_be(c, &v, 2); }

/* uint8 length, then the bytes. */
static int wr_std_string(zg_conn *c, const char *s)
{
  size_t n = strlen(s);
  if (n > ZG_MAX_STRING) return say(c, "a String is limited to 255 bytes");
  if (!wr_u8(c, (uint8_t)n)) return 0;
  return n ? wr(c, s, n) : 1;
}

static int rd_std_string(zg_conn *c, char *buf, size_t cap)
{
  uint8_t n;
  if (!rd_u8(c, &n)) return 0;
  if ((size_t)n + 1 > cap) {
    /* The bytes still have to come off the wire, or the stream is left out of
     * step and every later call reads the tail of this one. */
    if (!skip(c, n)) return 0;
    return say(c, "the answer does not fit in the buffer given");
  }
  if (n && !rd(c, buf, n)) return 0;
  buf[n] = '\0';
  return 1;
}

/* uint16 length, then the bytes. */
static int wr_std_text(zg_conn *c, const char *s)
{
  size_t n = strlen(s);
  if (n > ZG_MAX_TEXT) return say(c, "a Text is limited to 65535 bytes");
  if (!wr_u16(c, (uint16_t)n)) return 0;
  return n ? wr(c, s, n) : 1;
}

/* ------------------------------------------------------------------ */
/* opening and closing                                                */
/* ------------------------------------------------------------------ */

/* The dial itself, shared by zg_open and zg_reopen. On success C has a
 * connected socket and the transaction id the server opened with; on failure C
 * is left closed with the reason in c->err. */
static int dial(zg_conn *c, const char *host, const char *service,
                int timeout_seconds)
{
  struct addrinfo hints, *list = NULL, *ai;
  int rc;

  if (c->tls) { if (coco_client_tls_close) coco_client_tls_close(c->tls); c->tls = NULL; }
  if (c->fd >= 0) { close(c->fd); c->fd = -1; }
  /* Whatever the old connection was in the middle of is over, turn included --
   * and letting go here is what unwedges the worker whose lock wait timed out
   * and sent us round to redial. */
  give_turn(c);
  c->nout = 0;              /* a fresh socket starts with an empty request */
  c->nin = c->pin = 0;      /* ...and with nothing read ahead from the old one */
  c->transaction_id = 0;

  memset(&hints, 0, sizeof hints);
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  rc = getaddrinfo(host, service, &hints, &list);
  if (rc != 0) return say2(c, "cannot resolve the server", gai_strerror(rc));

  for (ai = list; ai != NULL; ai = ai->ai_next) {
    int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) continue;
    if (connect(fd, ai->ai_addr, ai->ai_addrlen) == 0) { c->fd = fd; break; }
    close(fd);
  }
  freeaddrinfo(list);

  if (c->fd < 0) return say2(c, "cannot connect", strerror(errno));

  /* NAGLE OFF. The protocol is a conversation of small messages -- write a
     request, wait for the reply, write the next -- which is the exact pattern
     Nagle's algorithm was written to batch and delayed ACK was written to
     stall. Together they hold a small write for up to 40ms waiting for either
     more data to coalesce or an ACK that the peer is not sending because it
     has nothing to say yet. One turn of a worker is a few dozen of these
     exchanges, so the cost is not the 40ms; it is 40ms several times over,
     per turn, and it is what made twelve workers take a minute to do a
     second's work. Best effort: a server that cannot set it still works,
     slowly. */
  {
    int one = 1;
    (void)setsockopt(c->fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
  }

  if (timeout_seconds > 0) {
    struct timeval tv;
    tv.tv_sec = timeout_seconds;
    tv.tv_usec = 0;
    setsockopt(c->fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    setsockopt(c->fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
  }

  /* THE HANDSHAKE BEFORE THE GREETING, and that ordering is the whole of
   * what `--tls' changes here: the server speaks first, so if TLS is on
   * there has to be a TLS session before there is anything to read. The
   * dial, Nagle and the timeouts are settled above for both. */
  if (g_tls_on) {
    if (coco_client_tls_open == NULL) {
      close(c->fd); c->fd = -1;
      return say(c, "this build has no TLS");
    }
    c->tls = coco_client_tls_open(c->fd, host, &g_tls, c->err, sizeof c->err);
    if (c->tls == NULL) { close(c->fd); c->fd = -1; return 0; }
  }

  /* The server speaks first: the id of the transaction this connection is. */
  {
    size_t tid = 0;
    if (!rd_sz(c, &tid)) { close(c->fd); c->fd = -1; return 0; }
    c->transaction_id = (uint64_t)tid;
  }

  c->err[0] = '\0';
  return 1;
}

zg_conn *zg_open(const char *host, const char *service, int timeout_seconds,
                 char *err, size_t errcap)
{
  zg_conn *c = (zg_conn *)calloc(1, sizeof *c);
  if (!c) {
    if (err) snprintf(err, errcap, "out of memory");
    return NULL;
  }
  c->fd     = -1;
  c->tls    = NULL;
  c->lockfd = -1;              /* 0 from calloc would be standard input */

  if (!dial(c, host, service, timeout_seconds)) {
    if (err) snprintf(err, errcap, "%s", c->err);
    free(c);
    return NULL;
  }

  if (err && errcap) err[0] = '\0';
  return c;
}

zg_conn *zg_open_embed(const char *dir, char *err, size_t errcap)
{
  zg_conn *c;
  if (!ce_engine_open) {
    if (err) snprintf(err, errcap,
                      "this build carries no embedded engine (see embed/build.sh)");
    return NULL;
  }
  c = (zg_conn *)calloc(1, sizeof *c);
  if (!c) {
    if (err) snprintf(err, errcap, "out of memory");
    return NULL;
  }
  c->fd     = -1;
  c->tls    = NULL;
  c->lockfd = -1;
  if (!ce_engine_open(dir, c->err, sizeof c->err)) {
    if (err) snprintf(err, errcap, "%s", c->err);
    free(c);
    return NULL;
  }
  c->ce = ce_session_new();
  if (!c->ce) {
    if (err) snprintf(err, errcap, "cannot begin an embedded session");
    ce_engine_close();
    free(c);
    return NULL;
  }
  if (err && errcap) err[0] = '\0';
  return c;
}

/* the embedded verbs fail with the engine's words in this handle's err,
 * so zg_error answers the same way for both ends */
static int emb(zg_conn *c, int ok)
{
  if (ok) return 1;
  return say(c, ce_error(c->ce));
}

int zg_reopen(zg_conn *c, const char *host, const char *service,
              int timeout_seconds)
{
  if (!c) return 0;
  if (c->ce) return emb(c, ce_reset(c->ce));
  return dial(c, host, service, timeout_seconds);
}

void zg_close(zg_conn *c)
{
  if (!c) return;
  if (c->ce) {
    ce_session_free(c->ce);
    ce_engine_close();
    free(c);
    return;
  }
  give_turn(c);
  if (c->lockfd >= 0) close(c->lockfd);
  if (c->tls) { if (coco_client_tls_close) coco_client_tls_close(c->tls); c->tls = NULL; }
  if (c->fd >= 0) close(c->fd);
  c->fd = c->lockfd = -1;
  free(c);
}

/* ------------------------------------------------------------------ */
/* results                                                            */
/* ------------------------------------------------------------------ */

int zg_result(zg_conn *c, zg_result_t *out)
{
  uint8_t r;
  if (!c) return 0;
  if (c->ce) {
    int er = 0;
    if (!ce_result(c->ce, &er)) return say(c, ce_error(c->ce));
    if (out) *out = (zg_result_t)er;
    return 1;
  }
  if (!rd_u8(c, &r)) return 0;
  if (r == ZG_EXCEPTION_THROWN) {
    char msg[ZG_MAX_STRING + 1];
    int  got = rd_std_string(c, msg, sizeof msg);
    /* AN EXCEPTION ENDS THE CONNECTION, NOT JUST THE CALL. Every catch in the
     * server's request loop writes this byte and then breaks out of the loop,
     * so the socket is already on its way down. Left open here, the next verb
     * written down it comes back as `write failed: Broken pipe' several calls
     * later and reads like a protocol bug rather than like the refusal that
     * caused it. Closing now means the caller is told once, in the right
     * words, and everything after it says `the connection is closed'.
     * A caller that means to carry on calls zg_reopen. */
    if (!got) return 0;
    return lost(c, "the server refused it", msg);
  }
  if (out) *out = (zg_result_t)r;
  return 1;
}

/* Names a verb and checks the server took it. Every verb starts this way, and
 * every verb waits for its turn here -- taking it if this connection is not
 * already in the middle of a transaction that holds it. */
static int verb(zg_conn *c, const char *name)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  c->err[0] = '\0';           /* so that a later "was anything said?" is true */
  if (!take_turn(c)) return 0;
  if (!wr_std_string(c, name)) return 0;
  if (!zg_result(c, &r)) return 0;
  if (r != ZG_SUCCESSFUL_DONE) return say2(c, "the server would not take the verb", name);
  return 1;
}

/* ------------------------------------------------------------------ */
/* verbs                                                              */
/* ------------------------------------------------------------------ */

/* THE LENGTH IS CHECKED BEFORE THE VERB IS SENT, and that is not fussiness
 * about ordering. A call that names its verb and then refuses to send the
 * argument leaves the server waiting for an argument that never comes, and
 * every later call on that connection reads the reply to this one. Refusing
 * before anything has gone out leaves the connection exactly as it was, so an
 * over-long value is an ordinary failure the caller can carry on from. */
int zg_echo(zg_conn *c, const char *text, char *out, size_t outcap)
{
  if (strlen(text) > ZG_MAX_STRING) return say(c, "a String is limited to 255 bytes");
  if (!verb(c, "echo")) return 0;
  return wr_std_string(c, text) && rd_std_string(c, out, outcap);
}

int zg_compile(zg_conn *c, const char *suite)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  int ok;
  if (strlen(suite) > ZG_MAX_TEXT) return say(c, "a Text is limited to 65535 bytes");
  if (!verb(c, "compile")) return 0;
  ok = wr_std_text(c, suite) && zg_result(c, &r) && r == ZG_SUCCESSFUL_DONE;
  if (!ok && c->err[0] == '\0') return say(c, "the suite would not compile");
  return ok;
}

int zg_call(zg_conn *c, const char *procedure)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  if (strlen(procedure) > ZG_MAX_STRING) return say(c, "a String is limited to 255 bytes");
  if (c->ce) return emb(c, ce_call(c->ce, procedure));
  if (!verb(c, "call")) return 0;
  if (!wr_std_string(c, procedure)) return 0;
  if (!zg_result(c, &r)) return 0;
  if (r != ZG_SUCCESSFUL_DONE) return say2(c, "the server would not call", procedure);
  return 1;
}

int zg_auto_commit(zg_conn *c, int on)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  uint8_t b = on ? 1 : 0;
  int ok;
  if (c->ce) return 1;
  if (!verb(c, "auto_commit")) return 0;
  ok = wr(c, &b, 1) && zg_result(c, &r) && r == ZG_SUCCESSFUL_DONE;
  if (!ok && c->err[0] == '\0') return say(c, "auto_commit was refused");
  return ok;
}

int zg_isolate(zg_conn *c, zg_isolation_t level)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  int ok;
  if (c->ce) return emb(c, ce_isolate(c->ce, (int)level));
  if (!verb(c, "isolate")) return 0;
  ok = wr_u8(c, (uint8_t)level) && zg_result(c, &r) && r == ZG_SUCCESSFUL_DONE;
  if (!ok && c->err[0] == '\0') return say(c, "the isolation level was refused");
  return ok;
}

/* commit and rollback, and so THE PLACE THE TURN GOES BACK.
 *
 * WHY THE TURN IS THE TRANSACTION AND NOT THE CALL. Releasing at the end of
 * each call was tried first, and is not enough: the server is still finishing
 * with the store after it has written the byte that ends a call -- committing
 * under auto-commit, closing the procedure's library -- and a transaction left
 * open goes on holding rows either way. Another process let in during that gap
 * meets the same shared file streams and the same `hexmap ends inside the
 * chunk'. Held across the transaction there is no gap: one process has one
 * transaction open at a time, which is the only arrangement the engine is
 * actually safe under. It costs nothing that matters, because a cocolog
 * transaction is a handful of round trips and the proving between them is
 * microseconds. */
static int simple_verb(zg_conn *c, const char *name)
{
  zg_result_t r = ZG_SUCCESSFUL_DONE;
  int ok;
  if (!verb(c, name)) return 0;
  ok = zg_result(c, &r) && r == ZG_SUCCESSFUL_DONE;
  give_turn(c);
  if (!ok && c->err[0] == '\0') return say2(c, "refused", name);
  return ok;
}

int zg_commit(zg_conn *c)
{
  if (c && c->ce) return emb(c, ce_commit(c->ce));
  return simple_verb(c, "commit");
}
int zg_rollback(zg_conn *c)
{
  if (c && c->ce) return emb(c, ce_rollback(c->ce));
  return simple_verb(c, "rollback");
}

int zg_columns(zg_conn *c, char *out, size_t outcap)
{
  if (c->ce) return emb(c, ce_columns(c->ce, out, outcap));
  return rd_std_string(c, out, outcap);
}

/* ------------------------------------------------------------------ */
/* writing parameters                                                 */
/* ------------------------------------------------------------------ */

/* A field is its type-descriptor byte and then its value, in the machine's own
 * layout. That is what the C++ side does and there is no conversion in it. */
static int wr_field(zg_conn *c, uint8_t tdb, const void *v, size_t n)
{
  if (!wr_u8(c, tdb)) return 0;
  return wr_be(c, v, n);
}

/* One byte, so byte order does not arise -- it goes through the same path as
 * the others so that there is one way a field is written. */
int zg_write_bool(zg_conn *c, int v)
{
  uint8_t b = v ? 1 : 0;
  return wr_field(c, TDB_BOOL, &b, 1);
}

int zg_write_int(zg_conn *c, int32_t v)
{
  if (c->ce) return emb(c, ce_write_num(c->ce, TDB_INT, (long long)v));
  return wr_field(c, TDB_INT, &v, 4);
}
int zg_write_long(zg_conn *c, int64_t v)
{
  if (c->ce) return emb(c, ce_write_num(c->ce, TDB_LONG, (long long)v));
  return wr_field(c, TDB_LONG, &v, 8);
}
int zg_write_double(zg_conn *c, double v) { return wr_field(c, TDB_DOUBLE, &v, sizeof v); }

int zg_write_string(zg_conn *c, const char *s)
{
  if (strlen(s) > ZG_MAX_STRING) return say(c, "a String is limited to 255 bytes");
  if (c->ce) return emb(c, ce_write_str(c->ce, TDB_STRING, s));
  if (!wr_u8(c, TDB_STRING)) return 0;
  return wr_std_string(c, s);
}

int zg_write_text(zg_conn *c, const char *s)
{
  if (strlen(s) > ZG_MAX_TEXT) return say(c, "a Text is limited to 65535 bytes");
  if (c->ce) return emb(c, ce_write_str(c->ce, TDB_TEXT, s));
  if (!wr_u8(c, TDB_TEXT)) return 0;
  return wr_std_text(c, s);
}

/* The type layer's Vector<T> serialises as its own descriptor byte -- the
 * DWORD scale bit over the element's -- then a u32 count, then each element
 * through the element type's own operator, tag and all. This mirrors that
 * for Vector<Double>, the one vector the tensors table wants. */
int zg_write_dvector(zg_conn *c, const double *v, uint32_t n)
{
  uint32_t i;
  if (c->ce) return emb(c, ce_write_dvector(c->ce, v, n));
  if (!wr_u8(c, TDB_SCALE_DWRD | TDB_DOUBLE)) return 0;
  if (!wr_be(c, &n, 4)) return 0;
  for (i = 0; i < n; i++) {
    if (!wr_u8(c, TDB_DOUBLE)) return 0;
    if (!wr_be(c, &v[i], 8)) return 0;
  }
  return 1;
}

/* ------------------------------------------------------------------ */
/* reading fields                                                     */
/* ------------------------------------------------------------------ */

/* Reads the descriptor byte and says whether a value follows. */
static int field_head(zg_conn *c, uint8_t *tdb, int *is_null)
{
  if (!rd_u8(c, tdb)) return 0;
  *is_null = (*tdb & TDB_IS_NULL) ? 1 : 0;
  return 1;
}

static int rd_scalar(zg_conn *c, void *v, size_t n, int *is_null)
{
  uint8_t tdb;
  int null = 0;
  if (!field_head(c, &tdb, &null)) return 0;
  if (is_null) *is_null = null;
  if (null) return 1;
  return rd_be(c, v, n);
}

int zg_read_bool(zg_conn *c, int *v, int *is_null)
{
  uint8_t b = 0;
  if (!rd_scalar(c, &b, 1, is_null)) return 0;
  if (v) *v = b ? 1 : 0;
  return 1;
}

int zg_read_int(zg_conn *c, int32_t *v, int *is_null)
{
  if (c->ce) {
    long long n = 0;
    if (!ce_read_num(c->ce, &n)) return say(c, ce_error(c->ce));
    if (v) *v = (int32_t)n;
    if (is_null) *is_null = 0;
    return 1;
  }
  return rd_scalar(c, v, 4, is_null);
}
int zg_read_long(zg_conn *c, int64_t *v, int *is_null)
{
  if (c->ce) {
    long long n = 0;
    if (!ce_read_num(c->ce, &n)) return say(c, ce_error(c->ce));
    if (v) *v = (int64_t)n;
    if (is_null) *is_null = 0;
    return 1;
  }
  return rd_scalar(c, v, 8, is_null);
}
int zg_read_double(zg_conn *c, double *v, int *is_null) { return rd_scalar(c, v, sizeof(double), is_null); }

int zg_read_string(zg_conn *c, char *buf, size_t cap, int *is_null)
{
  uint8_t tdb;
  int null = 0;
  if (c->ce) {
    if (!ce_read_str(c->ce, buf, cap)) return say(c, ce_error(c->ce));
    if (is_null) *is_null = 0;
    return 1;
  }
  if (!field_head(c, &tdb, &null)) return 0;
  if (is_null) *is_null = null;
  if (null) { if (cap) buf[0] = '\0'; return 1; }
  return rd_std_string(c, buf, cap);
}

int zg_read_text(zg_conn *c, char *buf, size_t cap, int *is_null)
{
  uint8_t tdb;
  uint16_t n;
  int null = 0;
  if (c->ce) {
    if (!ce_read_str(c->ce, buf, cap)) return say(c, ce_error(c->ce));
    if (is_null) *is_null = 0;
    return 1;
  }
  if (!field_head(c, &tdb, &null)) return 0;
  if (is_null) *is_null = null;
  if (null) { if (cap) buf[0] = '\0'; return 1; }
  if (!rd_u16(c, &n)) return 0;
  if ((size_t)n + 1 > cap) {
    if (!skip(c, n)) return 0;
    return say(c, "the Text does not fit in the buffer given");
  }
  if (n && !rd(c, buf, n)) return 0;
  buf[n] = '\0';
  return 1;
}

int zg_read_text_alloc(zg_conn *c, char **out, size_t *len, int *is_null)
{
  uint8_t tdb;
  uint16_t n;
  int null = 0;
  char *buf;

  if (out) *out = NULL;
  if (len) *len = 0;
  if (c->ce) {
    if (!ce_read_str_alloc(c->ce, out, len)) return say(c, ce_error(c->ce));
    if (is_null) *is_null = 0;
    return 1;
  }
  if (!field_head(c, &tdb, &null)) return 0;
  if (is_null) *is_null = null;
  if (null) return 1;
  if (!rd_u16(c, &n)) return 0;

  buf = (char *)malloc((size_t)n + 1);
  if (!buf) { skip(c, n); return say(c, "out of memory reading a Text"); }
  if (n && !rd(c, buf, n)) { free(buf); return 0; }
  buf[n] = '\0';
  if (out) *out = buf; else free(buf);
  if (len) *len = n;
  return 1;
}

int zg_read_dvector(zg_conn *c, double *out, uint32_t cap, uint32_t *n,
                    int *is_null)
{
  uint8_t tdb, etdb;
  uint32_t count, i;
  int null = 0;

  if (n) *n = 0;
  if (c->ce) {
    if (!ce_read_dvector(c->ce, out, cap, n)) return say(c, ce_error(c->ce));
    if (is_null) *is_null = 0;
    return 1;
  }
  if (!field_head(c, &tdb, &null)) return 0;
  if (is_null) *is_null = null;
  if (null) return 1;
  if ((tdb & TDB_SCALE_MASK) != TDB_SCALE_DWRD)
    return say(c, "the field is not a vector");
  if (!rd_u32(c, &count)) return 0;
  if (count > cap) return say(c, "a vector wider than the caller's buffer");
  for (i = 0; i < count; i++) {
    if (!rd_u8(c, &etdb)) return 0;
    if (!rd_be(c, &out[i], 8)) return 0;
  }
  if (n) *n = count;
  return 1;
}

/* One field of any type, without knowing which. The descriptor byte carries
 * the size class and the scale, which between them say exactly how many bytes
 * follow -- see the table at the top of this file. */
int zg_skip_field(zg_conn *c)
{
  uint8_t tdb;
  int null = 0;
  unsigned esize;
  if (c->ce) return emb(c, ce_skip(c->ce));

  if (!field_head(c, &tdb, &null)) return 0;
  if (null) return 1;

  esize = (tdb & TDB_TYPE_MASK) ? (1u << ((tdb & TDB_TYPE_MASK) - 1)) : 0u;

  switch (tdb & TDB_SCALE_MASK) {
  case TDB_SCALE_ATOM:
    return skip(c, esize);
  case TDB_SCALE_BYTE: {
    uint8_t n;
    if (!rd_u8(c, &n)) return 0;
    return skip(c, (size_t)n * esize);
  }
  case TDB_SCALE_WORD: {
    uint16_t n;
    if (!rd_u16(c, &n)) return 0;
    return skip(c, (size_t)n * esize);
  }
  case TDB_SCALE_DWRD: {
    /* A Vector writes a count and then each element as a whole field of its
     * own, descriptor byte and all -- so the elements are skipped by the same
     * function rather than by a size calculation. */
    uint32_t n, i;
    if (!rd_u32(c, &n)) return 0;
    for (i = 0; i < n; i++)
      if (!zg_skip_field(c)) return 0;
    return 1;
  }
  default:
    return say(c, "a field arrived with a type this client does not know");
  }
}

int zg_read_field(zg_conn *c, int *kind, int64_t *i, double *d,
                  char *text, size_t cap, uint32_t *veclen)
{
  uint8_t tdb;
  int null = 0;

  if (c->ce)
    return say(c, "reading a field without naming its type needs the wire's"
               " descriptors; an embedded connection has none to offer");

  if (!field_head(c, &tdb, &null)) return 0;
  if (null) { *kind = ZG_F_NULL; return 1; }

  switch (tdb) {
  case TDB_BOOL: {
    uint8_t b = 0;
    if (!rd_be(c, &b, 1)) return 0;
    *kind = ZG_F_LONG; if (i) *i = b ? 1 : 0;
    return 1;
  }
  case TDB_INT: {
    int32_t v = 0;
    if (!rd_be(c, &v, 4)) return 0;
    *kind = ZG_F_LONG; if (i) *i = (int64_t)v;
    return 1;
  }
  case TDB_LONG: {
    int64_t v = 0;
    if (!rd_be(c, &v, 8)) return 0;
    *kind = ZG_F_LONG; if (i) *i = v;
    return 1;
  }
  case TDB_DOUBLE: {
    double v = 0;
    if (!rd_be(c, &v, 8)) return 0;
    *kind = ZG_F_DOUBLE; if (d) *d = v;
    return 1;
  }
  case TDB_STRING:
    *kind = ZG_F_TEXT;
    return rd_std_string(c, text, cap);
  case TDB_TEXT: {
    uint16_t n;
    if (!rd_u16(c, &n)) return 0;
    if ((size_t)n + 1 > cap) {
      if (!skip(c, n)) return 0;
      return say(c, "the Text does not fit in the buffer given");
    }
    if (n && !rd(c, text, n)) return 0;
    text[n] = '\0';
    *kind = ZG_F_TEXT;
    return 1;
  }
  default:
    /* a Vector of anything: a u32 count, then that many whole fields */
    if ((tdb & TDB_SCALE_MASK) == TDB_SCALE_DWRD) {
      uint32_t n;
      if (!rd_u32(c, &n)) return 0;
      *kind = ZG_F_VECTOR; if (veclen) *veclen = n;
      return 1;
    }
    return say(c, "a field arrived with a type this client does not know");
  }
}

int zg_drain(zg_conn *c, unsigned row_fields)
{
  for (;;) {
    zg_result_t r = ZG_SUCCESSFUL_DONE;
    if (!zg_result(c, &r)) return 0;
    if (r == ZG_SUCCESSFUL_DONE) return 1;
    if (r == ZG_CURSOR_OPEN) {
      char cols[ZG_MAX_STRING + 1];
      if (!zg_columns(c, cols, sizeof cols)) return 0;
    } else if (r == ZG_CURSOR_FETCH) {
      unsigned i;
      for (i = 0; i < row_fields; i++)
        if (!zg_skip_field(c)) return 0;
    } else if (r == ZG_RETURN_VALUE) {
      if (!zg_skip_field(c)) return 0;
    }
    /* CURSOR_CLOSE carries nothing */
  }
}
