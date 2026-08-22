/* zigurat.c -- the Zigurat binary protocol, in C. See zigurat.h. */

#include "zigurat.h"

#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
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

struct zg_conn {
  int  fd;
  uint64_t transaction_id;
  char err[512];
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

int zg_is_open(const zg_conn *c) { return (c && c->fd >= 0) ? 1 : 0; }

uint64_t zg_transaction_id(const zg_conn *c) { return c ? c->transaction_id : 0; }

/* ------------------------------------------------------------------ */
/* the socket                                                         */
/* ------------------------------------------------------------------ */

/* Reads exactly N bytes or fails. A short read is not an error condition the
 * protocol can recover from -- every value has a known length -- so it is
 * always looped. */
static int rd(zg_conn *c, void *buf, size_t n)
{
  unsigned char *p = (unsigned char *)buf;
  size_t got = 0;
  if (c->fd < 0) return say(c, "the connection is closed");
  while (got < n) {
    ssize_t k = recv(c->fd, p + got, n - got, 0);
    if (k == 0) return say(c, "the server closed the connection");
    if (k < 0) {
      if (errno == EINTR) continue;
      return say2(c, "read failed", strerror(errno));
    }
    got += (size_t)k;
  }
  return 1;
}

static int wr(zg_conn *c, const void *buf, size_t n)
{
  const unsigned char *p = (const unsigned char *)buf;
  size_t sent = 0;
  if (c->fd < 0) return say(c, "the connection is closed");
  while (sent < n) {
    ssize_t k = send(c->fd, p + sent, n - sent, MSG_NOSIGNAL);
    if (k <= 0) {
      if (k < 0 && errno == EINTR) continue;
      return say2(c, "write failed", strerror(errno));
    }
    sent += (size_t)k;
  }
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

zg_conn *zg_open(const char *host, const char *service, int timeout_seconds,
                 char *err, size_t errcap)
{
  struct addrinfo hints, *list = NULL, *ai;
  zg_conn *c;
  int rc;

  c = (zg_conn *)calloc(1, sizeof *c);
  if (!c) {
    if (err) snprintf(err, errcap, "out of memory");
    return NULL;
  }
  c->fd = -1;

  memset(&hints, 0, sizeof hints);
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  rc = getaddrinfo(host, service, &hints, &list);
  if (rc != 0) {
    if (err) snprintf(err, errcap, "cannot resolve %s:%s: %s", host, service, gai_strerror(rc));
    free(c);
    return NULL;
  }

  for (ai = list; ai != NULL; ai = ai->ai_next) {
    int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) continue;
    if (connect(fd, ai->ai_addr, ai->ai_addrlen) == 0) { c->fd = fd; break; }
    close(fd);
  }
  freeaddrinfo(list);

  if (c->fd < 0) {
    if (err) snprintf(err, errcap, "cannot connect to %s:%s: %s", host, service, strerror(errno));
    free(c);
    return NULL;
  }

  if (timeout_seconds > 0) {
    struct timeval tv;
    tv.tv_sec = timeout_seconds;
    tv.tv_usec = 0;
    setsockopt(c->fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    setsockopt(c->fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
  }

  /* The server speaks first: the id of the transaction this connection is. */
  {
    size_t tid = 0;
    if (!rd_sz(c, &tid)) {
      if (err) snprintf(err, errcap, "%s", c->err);
      close(c->fd);
      free(c);
      return NULL;
    }
    c->transaction_id = (uint64_t)tid;
  }

  if (err && errcap) err[0] = '\0';
  return c;
}

void zg_close(zg_conn *c)
{
  if (!c) return;
  if (c->fd >= 0) close(c->fd);
  c->fd = -1;
  free(c);
}

/* ------------------------------------------------------------------ */
/* results                                                            */
/* ------------------------------------------------------------------ */

int zg_result(zg_conn *c, zg_result_t *out)
{
  uint8_t r;
  if (!c) return 0;
  if (!rd_u8(c, &r)) return 0;
  if (r == ZG_EXCEPTION_THROWN) {
    char msg[ZG_MAX_STRING + 1];
    if (!rd_std_string(c, msg, sizeof msg)) return 0;
    return say2(c, "the server refused it", msg);
  }
  if (out) *out = (zg_result_t)r;
  return 1;
}

/* Names a verb and checks the server took it. Every verb starts this way. */
static int verb(zg_conn *c, const char *name)
{
  zg_result_t r;
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
  if (!wr_std_string(c, text)) return 0;
  return rd_std_string(c, out, outcap);
}

int zg_compile(zg_conn *c, const char *suite)
{
  zg_result_t r;
  if (strlen(suite) > ZG_MAX_TEXT) return say(c, "a Text is limited to 65535 bytes");
  if (!verb(c, "compile")) return 0;
  if (!wr_std_text(c, suite)) return 0;
  if (!zg_result(c, &r)) return 0;
  if (r != ZG_SUCCESSFUL_DONE) return say(c, "the suite would not compile");
  return 1;
}

int zg_call(zg_conn *c, const char *procedure)
{
  zg_result_t r;
  if (strlen(procedure) > ZG_MAX_STRING) return say(c, "a String is limited to 255 bytes");
  if (!verb(c, "call")) return 0;
  if (!wr_std_string(c, procedure)) return 0;
  if (!zg_result(c, &r)) return 0;
  if (r != ZG_SUCCESSFUL_DONE) return say2(c, "the server would not call", procedure);
  return 1;
}

int zg_auto_commit(zg_conn *c, int on)
{
  zg_result_t r;
  uint8_t b = on ? 1 : 0;
  if (!verb(c, "auto_commit")) return 0;
  if (!wr(c, &b, 1)) return 0;
  if (!zg_result(c, &r)) return 0;
  return (r == ZG_SUCCESSFUL_DONE) ? 1 : say(c, "auto_commit was refused");
}

int zg_isolate(zg_conn *c, zg_isolation_t level)
{
  zg_result_t r;
  if (!verb(c, "isolate")) return 0;
  if (!wr_u8(c, (uint8_t)level)) return 0;
  if (!zg_result(c, &r)) return 0;
  return (r == ZG_SUCCESSFUL_DONE) ? 1 : say(c, "the isolation level was refused");
}

static int simple_verb(zg_conn *c, const char *name)
{
  zg_result_t r;
  if (!verb(c, name)) return 0;
  if (!zg_result(c, &r)) return 0;
  return (r == ZG_SUCCESSFUL_DONE) ? 1 : say2(c, "refused", name);
}

int zg_commit(zg_conn *c)   { return simple_verb(c, "commit"); }
int zg_rollback(zg_conn *c) { return simple_verb(c, "rollback"); }

int zg_columns(zg_conn *c, char *out, size_t outcap)
{
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

int zg_write_int(zg_conn *c, int32_t v)   { return wr_field(c, TDB_INT, &v, 4); }
int zg_write_long(zg_conn *c, int64_t v)  { return wr_field(c, TDB_LONG, &v, 8); }
int zg_write_double(zg_conn *c, double v) { return wr_field(c, TDB_DOUBLE, &v, sizeof v); }

int zg_write_string(zg_conn *c, const char *s)
{
  if (!wr_u8(c, TDB_STRING)) return 0;
  return wr_std_string(c, s);
}

int zg_write_text(zg_conn *c, const char *s)
{
  if (!wr_u8(c, TDB_TEXT)) return 0;
  return wr_std_text(c, s);
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

int zg_read_int(zg_conn *c, int32_t *v, int *is_null)   { return rd_scalar(c, v, 4, is_null); }
int zg_read_long(zg_conn *c, int64_t *v, int *is_null)  { return rd_scalar(c, v, 8, is_null); }
int zg_read_double(zg_conn *c, double *v, int *is_null) { return rd_scalar(c, v, sizeof(double), is_null); }

int zg_read_string(zg_conn *c, char *buf, size_t cap, int *is_null)
{
  uint8_t tdb;
  int null = 0;
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

/* One field of any type, without knowing which. The descriptor byte carries
 * the size class and the scale, which between them say exactly how many bytes
 * follow -- see the table at the top of this file. */
int zg_skip_field(zg_conn *c)
{
  uint8_t tdb;
  int null = 0;
  unsigned esize;

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

int zg_drain(zg_conn *c, unsigned row_fields)
{
  for (;;) {
    zg_result_t r;
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
