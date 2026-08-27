/* zeytun.h -- reading Zeytun pages from C.
 *
 * The other half of this project's C client. zigurat.h speaks the binary
 * protocol on 2160, which is the better transport: real transactions,
 * isolation levels, cursors. This speaks HTTP to Zeytun on 2190, which is the
 * one that gets through a proxy.
 *
 * IT ONLY READS, and deliberately. One HTTP request is one transaction, so
 * anything that has to write several rows atomically -- a suspended machine is
 * a header row and a row per chunk -- cannot be done over it without leaving
 * half a machine behind on a failure. Writes belong on the binary protocol,
 * where the connection is the transaction. See cocolog/03-pages.parsi.
 *
 * HTTPS IS HERE NOW, and it is the one thing this file did not have. An edge
 * -- Cloudflare in front of a Colab VM is the worked case -- speaks TLS and
 * nothing else, and a client that could only speak plaintext had to be given
 * port 80 and hope the edge did not redirect. `zt_get2' takes a
 * `coco_tls_options *' and NULL means plaintext, so the old path is byte for
 * byte what it was.
 *
 * THE TLS IS IN client/tls.c, ON PURPOSE. This file is still libc and
 * the sockets API and nothing else: it reaches OpenSSL through four functions
 * behind an opaque pointer, and a build without OpenSSL compiles that file's
 * stub half -- so `--https' reports the missing feature by name rather than
 * failing to link.
 *
 * IT IS A MINIMAL CLIENT AND SAYS SO. One request per call, no keep-alive, no
 * chunked transfer encoding, no redirects. Zeytun answers a GET with
 * Content-Length and closes when asked to, which is all of the protocol this
 * needs; anything more belongs to a real HTTP library, and a program that
 * wants one should use it instead.
 *
 * WHAT A PAGE'S OUTPUT NEEDS DOING TO IT. Zeytun escapes every value a page
 * emits that did not come from a literal, with exactly five rules:
 *
 *     &  ->  &amp;      <  ->  &lt;       >  ->  &gt;
 *     "  ->  &quot;     '  ->  &#39;
 *
 * zt_unescape undoes those five and nothing else. The mapping is unambiguous
 * in both directions because & is itself escaped, so an & in the output can
 * only be the start of an entity.
 */

#ifndef ZEYTUN_C_H
#define ZEYTUN_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* One GET. PATH is everything after the host, query string included, and must
 * already be encoded -- see zt_urlencode.
 *
 * On success answers 1, and BODY holds a NUL-terminated copy of the response
 * body which the caller frees. LEN, if given, is its length; the body may
 * contain NULs in principle, though no cocolog page emits one.
 *
 * A status other than 200 is a failure with the status line in ERR: a page
 * that does not exist is a 404, and a page whose name collides with a table is
 * a 500, both of which are worth reporting rather than parsing. */
int zt_get(const char *host, const char *service, const char *path,
           int timeout_seconds, char **body, size_t *len,
           char *err, size_t errcap);

/* WHAT A SECURE FETCH NEEDS TOLD. Everything is optional and NULL means the
 * sensible thing:
 *
 *   cacert/capath  the authority to check the server against. Neither given
 *                  means the SYSTEM store, which is what an edge with a
 *                  public certificate wants.
 *   cert/key       this end's own certificate, for a Zeytun that demands one.
 *                  BOTH or NEITHER; one alone is a configuration mistake and
 *                  is reported rather than half-applied.
 *   key_pass       its pass phrase, if it has one.
 *   insecure       do not verify at all. It exists because a self-signed
 *                  rehearsal is a real thing to want, and it is spelled out
 *                  at every layer so nobody reaches it by accident.
 *
 * THE HOSTNAME IS ALWAYS CHECKED unless `insecure' is set, and that is the
 * check a hand-rolled client forgets: a certificate that is valid for
 * somebody else is exactly what a man in the middle presents. */
typedef struct {
  const char *cacert;
  const char *capath;
  const char *cert;
  const char *key;
  const char *key_pass;
  int         insecure;
} coco_tls_options;

/* THE PROCESS-WIDE SETTING, and why there is one. A cocolog reaches exactly
 * one Zeytun, in an arrangement chosen once from argv before the first goal
 * runs -- so the transport is a property of the process rather than of a
 * call, and threading it through `coco_zt' and four call sites in
 * lib/zeytun-kb.cicili would be four chances for one of them to stay
 * plaintext.
 *
 * `zt_get' uses whatever this was last given; NULL puts it back to plain
 * HTTP. The struct is COPIED but its strings are not -- they are argv, which
 * outlives everything. A caller that wants neither the global nor the copy
 * uses `zt_get2' and says what it means at the call. */
void coco_client_tls_configure(const coco_tls_options *o);

/* THE SAME THING, FLAT, and it exists for Cicili. A Cicili form reaching
 * into a C struct needs that struct's MEMBERS declared to it, not merely
 * its name -- `($ t cacert)' on a type it only knows the name of is
 * `unknown struct type'. Six arguments say the same thing with nothing to
 * declare, which is the seam-one-function-wide shape the modules use. */
void coco_client_tls_configure_flat(const char *cacert, const char *capath,
                           const char *cert, const char *key,
                           const char *key_pass, int insecure);

/* One GET, over TLS when TLS is not NULL and over plain HTTP when it is.
 * `zt_get' is this with whatever `coco_client_tls_configure' was given. */
int zt_get2(const char *host, const char *service, const char *path,
            int timeout_seconds, const coco_tls_options *tls,
            char **body, size_t *len, char *err, size_t errcap);

/* client/tls.c, shared with zigurat.c. Answers 0 from a build with no OpenSSL, in which
 * case `coco_client_tls_open' fills ERR with a sentence saying so. */
/* DECLARED WEAK, AND HERE RATHER THAN IN EACH .c. client/tls.o is linked
 * into the cocolog BINARY and not into libcocologc.a, so a program that
 * links only the archive -- every test .cicili target does -- must get
 * null for these and speak plaintext. A weak attribute has to be on the
 * FIRST declaration the compiler sees: putting it only in the .c files,
 * after this header had already declared them strongly, left
 * `undefined reference to coco_client_tls_recv' at every such link. */
#define COCO_WEAK __attribute__((weak))

COCO_WEAK int   coco_client_tls_available(void);
COCO_WEAK void *coco_client_tls_open(int fd, const char *host,
                                     const coco_tls_options *o,
                                     char *err, size_t errcap);
COCO_WEAK long  coco_client_tls_send(void *handle, const void *buf, size_t n);
COCO_WEAK long  coco_client_tls_recv(void *handle, void *buf, size_t n);
COCO_WEAK void  coco_client_tls_close(void *handle);
/* WHY THE LAST SEND OR RECV STOPPED, when TLS knows and the socket does
 * not: fills BUF and answers 1, or answers 0 when there is nothing to
 * add. THE CASE IT EXISTS FOR is a server whose `TLS_CLIENT_AUTH' is
 * REQUIRED and a client with no `--cert': under TLS 1.3 the client is
 * finished talking before the server looks, so the handshake SUCCEEDS
 * and the refusal arrives as an alert on the first read. Without this
 * the client reports `read failed'; with it, the alert. */
COCO_WEAK int   coco_client_tls_why(void *handle, char *buf, size_t cap);

/* Undoes Zeytun's five escapes, in place. Answers the resulting length; the
 * result is always shorter or the same, so nothing is reallocated. */
size_t zt_unescape(char *s);

/* Percent-encodes IN into OUT for use in a query string. Answers 1, or 0 if it
 * does not fit. */
int zt_urlencode(const char *in, char *out, size_t cap);

#ifdef __cplusplus
}
#endif

#endif /* ZEYTUN_C_H */
