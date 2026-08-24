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
static char *slurp(int fd, size_t *out_len, char *err, size_t errcap)
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

    k = recv(fd, buf + len, cap - len - 1, 0);
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

int zt_get(const char *host, const char *service, const char *path,
           int timeout_seconds, char **body, size_t *len,
           char *err, size_t errcap)
{
  int fd;
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

  fd = dial(host, service, timeout_seconds, err, errcap);
  if (fd < 0) return 0;

  {
    size_t sent = 0, total = (size_t)n;
    while (sent < total) {
      ssize_t k = send(fd, request + sent, total - sent, MSG_NOSIGNAL);
      if (k <= 0) {
        if (k < 0 && errno == EINTR) continue;
        close(fd);
        return fail(err, errcap, "write failed", strerror(errno));
      }
      sent += (size_t)k;
    }
  }

  raw = slurp(fd, &raw_len, err, errcap);
  close(fd);
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
