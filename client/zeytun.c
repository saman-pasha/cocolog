/* zeytun.c -- reading Zeytun pages from C. See zeytun.h. */

#include "zeytun.h"

#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

static int fail(char *err, size_t cap, const char *what, const char *detail)
{
  if (err && cap) {
    if (detail) snprintf(err, cap, "%s: %s", what, detail);
    else        snprintf(err, cap, "%s", what);
  }
  return 0;
}

static int dial(const char *host, const char *service, int timeout_seconds,
                char *err, size_t errcap)
{
  struct addrinfo hints, *list = NULL, *ai;
  int fd = -1, rc;

  memset(&hints, 0, sizeof hints);
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  rc = getaddrinfo(host, service, &hints, &list);
  if (rc != 0) { fail(err, errcap, "cannot resolve", gai_strerror(rc)); return -1; }

  for (ai = list; ai != NULL; ai = ai->ai_next) {
    fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) continue;
    if (connect(fd, ai->ai_addr, ai->ai_addrlen) == 0) break;
    close(fd);
    fd = -1;
  }
  freeaddrinfo(list);

  if (fd < 0) { fail(err, errcap, "cannot connect", strerror(errno)); return -1; }

  if (timeout_seconds > 0) {
    struct timeval tv;
    tv.tv_sec = timeout_seconds;
    tv.tv_usec = 0;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
  }
  return fd;
}

/* Reads a response: the headers, and then exactly as many body bytes as
 * Content-Length says.
 *
 * STOPPING AT CONTENT-LENGTH IS NOT AN OPTIMISATION. Zeytun keeps the
 * connection alive whatever `Connection: close' asks for, so a reader that
 * waits for end-of-file waits for the socket timeout on every single request
 * -- which looks exactly like the server not answering. The first version of
 * this did that, and every call took ten seconds and then failed.
 *
 * A response with no Content-Length is read to end-of-file, which is the only
 * thing left to do with one; no cocolog page produces such a response. */
/* THE TLS HALF IS REACHED WEAKLY, and that is what keeps libcocologc what
 * it says it is. The archive holds this file and zigurat.c and nothing
 * else; client/tls.o is linked into the cocolog BINARY, beside
 * -lssl -lcrypto. A program that links only the archive -- every
 * test/*.cicili target does -- gets NULL here, and plaintext is
 * unaffected.
 *
 * FOUND BY THE SUITE, which is the argument for having it: putting
 * zeytun-tls.o in the archive made `test/shared.cicili' fail to link with
 * `undefined reference to SSL_free', from a test that has never opened a
 * socket to anything but the binary protocol. The archive is a
 * dependency of things that want no TLS, and it should stay one. */

/* THE TRANSPORT, IN ONE STRUCT AND THREE FUNCTIONS. `tls' is NULL for a
 * plain connection, and every read and write below goes through these --
 * which is what keeps the HTTP in this file identical on both. */
typedef struct { int fd; void *tls; } zt_conn;

static long zt_write(zt_conn *c, const void *buf, size_t n)
{
  if (c->tls) return coco_client_tls_send(c->tls, buf, n);
  return (long) send(c->fd, buf, n, MSG_NOSIGNAL);
}

static long zt_read(zt_conn *c, void *buf, size_t n)
{
  if (c->tls) return coco_client_tls_recv(c->tls, buf, n);
  return (long) recv(c->fd, buf, n, 0);
}

static void zt_hangup(zt_conn *c)
{
  if (c->tls) coco_client_tls_close(c->tls);
  if (c->fd >= 0) close(c->fd);
  c->tls = NULL;
  c->fd = -1;
}

static char *slurp(zt_conn *c, size_t *out_len, char *err, size_t errcap)
{
  size_t cap = 8192, len = 0;
  size_t header_len = 0;         /* bytes up to and including the blank line */
  long content_length = -1;
  char *buf = (char *)malloc(cap);
  if (!buf) { fail(err, errcap, "out of memory", NULL); return NULL; }
  buf[0] = 0;

  for (;;) {
    ssize_t k;

    if (header_len > 0 && content_length >= 0 &&
        len >= header_len + (size_t)content_length)
      break;

    if (len + 4096 > cap) {
      char *nb;
      size_t ncap = cap * 2;
      while (len + 4096 > ncap) ncap *= 2;
      nb = (char *)realloc(buf, ncap);
      if (!nb) { free(buf); fail(err, errcap, "out of memory", NULL); return NULL; }
      buf = nb;
      cap = ncap;
    }

    k = (ssize_t) zt_read(c, buf + len, cap - len - 1);
    if (k == 0) break;                       /* the server did close after all */
    if (k < 0) {
      if (errno == EINTR) continue;
      free(buf);
      fail(err, errcap, "read failed", strerror(errno));
      return NULL;
    }
    len += (size_t)k;
    buf[len] = 0;

    if (header_len == 0) {
      char *end = strstr(buf, "\r\n\r\n");
      if (end) {
        char *cl;
        header_len = (size_t)(end - buf) + 4;
        /* Header names are case-insensitive, so both spellings are looked for
         * rather than the one Zeytun happens to write today. */
        cl = strstr(buf, "\r\nContent-Length:");
        if (!cl) cl = strstr(buf, "\r\ncontent-length:");
        if (cl) {
          char *colon = strchr(cl + 2, 0x3A);
          if (colon) content_length = strtol(colon + 1, NULL, 10);
        }
      }
    }
  }

  if (out_len) *out_len = len;
  return buf;
}

/* See zeytun.h: the transport is a property of the process, because a
 * cocolog reaches one Zeytun in an arrangement chosen once from argv. */
static coco_tls_options g_tls;
static int            g_tls_on = 0;

void coco_client_tls_configure(const coco_tls_options *o)
{
  if (o == NULL) { g_tls_on = 0; return; }
  g_tls = *o;
  g_tls_on = 1;
}

void coco_client_tls_configure_flat(const char *cacert, const char *capath,
                           const char *cert, const char *key,
                           const char *key_pass, int insecure)
{
  coco_tls_options o;
  memset(&o, 0, sizeof o);
  o.cacert = cacert;
  o.capath = capath;
  o.cert = cert;
  o.key = key;
  o.key_pass = key_pass;
  o.insecure = insecure;
  coco_client_tls_configure(&o);
}

int zt_get(const char *host, const char *service, const char *path,
           int timeout_seconds, char **body, size_t *len,
           char *err, size_t errcap)
{
  return zt_get2(host, service, path, timeout_seconds,
                 g_tls_on ? &g_tls : NULL, body, len, err, errcap);
}

int zt_get2(const char *host, const char *service, const char *path,
            int timeout_seconds, const coco_tls_options *tls,
            char **body, size_t *len, char *err, size_t errcap)
{
  zt_conn c = { -1, NULL };
  char request[2048];
  char *raw = NULL, *head_end, *status_end;
  size_t raw_len = 0, body_len;
  int n;

  if (body) *body = NULL;
  if (len) *len = 0;
  if (err && errcap) err[0] = '\0';

  /* The default port stays out of the Host header. Direct to Zeytun the
     port-qualified form is fine, but through a proxy that routes by
     hostname -- a Cloudflare tunnel in front of a Colab VM is the worked
     case -- "Host: name:80" is not the registered "Host: name", and the
     edge answers for nobody. */
  if (strcmp(service, "80") == 0 || strcmp(service, "443") == 0 ||
      strcmp(service, "http") == 0 || strcmp(service, "https") == 0)
    n = snprintf(request, sizeof request,
                 "GET %s HTTP/1.1\r\nHost: %s\r\n"
                 "User-Agent: cocolog/1\r\nAccept: text/plain\r\n"
                 "Connection: close\r\n\r\n",
                 path, host);
  else
    n = snprintf(request, sizeof request,
                 "GET %s HTTP/1.1\r\nHost: %s:%s\r\n"
                 "User-Agent: cocolog/1\r\nAccept: text/plain\r\n"
                 "Connection: close\r\n\r\n",
                 path, host, service);
  if (n < 0 || (size_t)n >= sizeof request)
    return fail(err, errcap, "the request line is too long", path);

  c.fd = dial(host, service, timeout_seconds, err, errcap);
  if (c.fd < 0) return 0;

  /* THE HANDSHAKE BEFORE THE REQUEST, and the socket is already open --
   * which is why the TLS half takes a descriptor rather than a host: the
   * dialling, the timeout and the address family are settled here, once,
   * for both transports. */
  if (tls != NULL) {
    if (coco_client_tls_open == NULL) {
      close(c.fd);
      return fail(err, errcap, "this build has no TLS", NULL);
    }
    c.tls = coco_client_tls_open(c.fd, host, tls, err, errcap);
    if (c.tls == NULL) { close(c.fd); return 0; }
  }

  {
    size_t sent = 0, total = (size_t)n;
    while (sent < total) {
      long k = zt_write(&c, request + sent, total - sent);
      if (k <= 0) {
        if (k < 0 && errno == EINTR) continue;
        zt_hangup(&c);
        return fail(err, errcap, "write failed", strerror(errno));
      }
      sent += (size_t)k;
    }
  }

  raw = slurp(&c, &raw_len, err, errcap);
  zt_hangup(&c);
  if (!raw) return 0;

  /* "HTTP/1.1 200 OK" -- anything else is reported rather than parsed. */
  status_end = strstr(raw, "\r\n");
  if (!status_end) { free(raw); return fail(err, errcap, "no status line", NULL); }
  if (strncmp(raw, "HTTP/1.", 7) != 0 || strstr(raw, " 200 ") != raw + 8) {
    char line[256];
    size_t k = (size_t)(status_end - raw);
    if (k >= sizeof line) k = sizeof line - 1;
    memcpy(line, raw, k);
    line[k] = '\0';
    free(raw);
    return fail(err, errcap, "the server answered", line);
  }

  head_end = strstr(raw, "\r\n\r\n");
  if (!head_end) { free(raw); return fail(err, errcap, "no end of headers", NULL); }
  head_end += 4;

  body_len = raw_len - (size_t)(head_end - raw);
  {
    char *out = (char *)malloc(body_len + 1);
    if (!out) { free(raw); return fail(err, errcap, "out of memory", NULL); }
    memcpy(out, head_end, body_len);
    out[body_len] = '\0';
    free(raw);
    if (body) *body = out; else free(out);
    if (len) *len = body_len;
  }
  return 1;
}

size_t zt_unescape(char *s)
{
  size_t r = 0, w = 0;
  while (s[r]) {
    if (s[r] == '&') {
      if (strncmp(s + r, "&amp;", 5) == 0)       { s[w++] = '&';  r += 5; continue; }
      if (strncmp(s + r, "&lt;", 4) == 0)        { s[w++] = '<';  r += 4; continue; }
      if (strncmp(s + r, "&gt;", 4) == 0)        { s[w++] = '>';  r += 4; continue; }
      if (strncmp(s + r, "&quot;", 6) == 0)      { s[w++] = '"';  r += 6; continue; }
      if (strncmp(s + r, "&#39;", 5) == 0)       { s[w++] = '\''; r += 5; continue; }
      /* Not one of the five. Zeytun's escaper cannot produce it, so it came
       * from a literal the page wrote, and it is passed through unchanged. */
    }
    s[w++] = s[r++];
  }
  s[w] = '\0';
  return w;
}

int zt_urlencode(const char *in, char *out, size_t cap)
{
  static const char *hex = "0123456789ABCDEF";
  size_t w = 0;
  const unsigned char *p = (const unsigned char *)in;
  for (; *p; p++) {
    unsigned char c = *p;
    int safe = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
            || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~';
    if (safe) {
      if (w + 2 > cap) return 0;
      out[w++] = (char)c;
    } else {
      if (w + 4 > cap) return 0;
      out[w++] = '%';
      out[w++] = hex[c >> 4];
      out[w++] = hex[c & 0x0F];
    }
  }
  if (w + 1 > cap) return 0;
  out[w] = '\0';
  return 1;
}
