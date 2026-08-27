/* tls.c -- TLS for BOTH C clients, and nothing else.
 *
 * WHY IT IS A SEPARATE FILE. zigurat.c and zeytun.c both say they are
 * libc and the sockets API and nothing else, and that stays true: this is
 * the only translation unit in client/ that knows OpenSSL exists, and
 * both reach it through six functions that hand back an opaque pointer.
 * A build without OpenSSL compiles the stub half below and `--tls' and
 * `--https' then say so by name rather than failing to link.
 *
 * ONE FILE FOR TWO PROTOCOLS, because a handshake is a handshake. The
 * binary protocol on 2160 and Zeytun's HTTP on 2190 differ in what they
 * send afterwards and in nothing before it -- ZiguratIP's own
 * `SERVER/TLS_MODE' and `HTTP/TLS_MODE' are the same switch on two
 * ports. A second copy here would be a second place to forget the
 * hostname check.
 *
 * IT IS A CLIENT ONLY. There is no accept and no server context:
 * library(tls) is the module for a cocolog that LISTENS, and its names
 * are `coco_tls_*' -- which is why these are `coco_client_tls_*'. Both
 * live in one process when a cocolog serves and queries at once, and two
 * `coco_tls_close' would be one symbol.
 *
 * WHAT IT VERIFIES, BY DEFAULT AND WITHOUT ASKING: the chain, against
 * the system store or a named CA, AND THE HOSTNAME. The second is the
 * one a hand-rolled client forgets: a certificate that is valid for
 * somebody else is exactly what a man in the middle presents, and
 * OpenSSL will not check the name unless it is told to.
 * X509_VERIFY_PARAM_set1_host is that instruction.
 *
 * SNI IS SET TOO, and for Cloudflare it is not optional: an edge serving
 * many names decides which certificate to present from the name in the
 * ClientHello, and one that gets no SNI answers with whatever it
 * defaults to -- which then fails the hostname check that was just
 * described, confusingly.
 */

#include "zeytun.h"

#include <string.h>
#include <stdio.h>
#include <errno.h>

#ifdef COCO_ZT_TLS

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>

struct zt_tls {
  SSL_CTX *ctx;
  SSL     *ssl;
  /* WHY THE LAST READ OR WRITE STOPPED, when TLS knows and the socket
   * does not. This is the field that makes a refused CLIENT certificate
   * legible: under TLS 1.3 the server does not look at what the client
   * sent -- or did not send -- until after the client is finished
   * talking, so `SSL_connect' SUCCEEDS and the refusal arrives as an
   * alert on the next read. Without this the caller has `read failed'
   * and an errno; with it, "tlsv13 alert certificate required". */
  char     why[256];
};

static void ssl_why(char *err, size_t cap, const char *what)
{
  unsigned long e = ERR_get_error();
  char buf[256];
  if (e) {
    ERR_error_string_n(e, buf, sizeof buf);
    snprintf(err, cap, "%s: %s", what, buf);
  } else {
    snprintf(err, cap, "%s", what);
  }
}

int coco_client_tls_available(void) { return 1; }

void *coco_client_tls_open(int fd, const char *host, const coco_tls_options *o,
                  char *err, size_t errcap)
{
  struct zt_tls *t = NULL;

  t = (struct zt_tls *) calloc(1, sizeof *t);
  if (t == NULL) { snprintf(err, errcap, "out of memory"); return NULL; }

  t->ctx = SSL_CTX_new(TLS_client_method());
  if (t->ctx == NULL) { ssl_why(err, errcap, "cannot make a TLS context"); goto bad; }

  /* Nothing below TLS 1.2. The versions under it are broken in ways that
   * have names, and an edge worth talking to has not offered them for
   * years. */
  SSL_CTX_set_min_proto_version(t->ctx, TLS1_2_VERSION);

  if (o->cacert != NULL || o->capath != NULL) {
    if (SSL_CTX_load_verify_locations(t->ctx, o->cacert, o->capath) != 1) {
      ssl_why(err, errcap, "cannot read the authority"); goto bad;
    }
  } else if (SSL_CTX_set_default_verify_paths(t->ctx) != 1) {
    ssl_why(err, errcap, "cannot read the system authorities"); goto bad;
  }

  /* A CLIENT CERTIFICATE IS OPTIONAL and asked for only when both halves
   * are named -- a certificate without its key is a configuration
   * mistake worth reporting rather than half-applying. */
  if (o->cert != NULL && o->key != NULL) {
    if (SSL_CTX_use_certificate_file(t->ctx, o->cert, SSL_FILETYPE_PEM) != 1 &&
        SSL_CTX_use_certificate_file(t->ctx, o->cert, SSL_FILETYPE_ASN1) != 1) {
      ssl_why(err, errcap, "cannot read this end's certificate"); goto bad;
    }
    if (o->key_pass != NULL) {
      SSL_CTX_set_default_passwd_cb_userdata(t->ctx, (void *) o->key_pass);
    }
    if (SSL_CTX_use_PrivateKey_file(t->ctx, o->key, SSL_FILETYPE_PEM) != 1 &&
        SSL_CTX_use_PrivateKey_file(t->ctx, o->key, SSL_FILETYPE_ASN1) != 1) {
      ssl_why(err, errcap, "cannot read this end's private key"); goto bad;
    }
    if (SSL_CTX_check_private_key(t->ctx) != 1) {
      snprintf(err, errcap, "this end's private key does not belong to its certificate");
      goto bad;
    }
  } else if (o->cert != NULL || o->key != NULL) {
    snprintf(err, errcap, "a client certificate needs both --cert and --key");
    goto bad;
  }

  t->ssl = SSL_new(t->ctx);
  if (t->ssl == NULL) { ssl_why(err, errcap, "cannot make a TLS connection"); goto bad; }

  /* SNI, and the hostname check. Both take the SAME name, which is the
   * property that makes them one decision rather than two. */
  SSL_set_tlsext_host_name(t->ssl, host);

  if (!o->insecure) {
    X509_VERIFY_PARAM *p = SSL_get0_param(t->ssl);
    X509_VERIFY_PARAM_set_hostflags(p, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
    if (X509_VERIFY_PARAM_set1_host(p, host, 0) != 1) {
      snprintf(err, errcap, "cannot check the name %s", host);
      goto bad;
    }
    SSL_set_verify(t->ssl, SSL_VERIFY_PEER, NULL);
  }

  if (SSL_set_fd(t->ssl, fd) != 1) { ssl_why(err, errcap, "cannot use the socket"); goto bad; }

  if (SSL_connect(t->ssl) != 1) {
    /* THE VERIFICATION RESULT IS THE USEFUL HALF of a failed handshake:
     * "certificate verify failed" says nothing about WHICH check, and
     * "self-signed certificate in certificate chain" says everything. */
    long v = SSL_get_verify_result(t->ssl);
    if (v != X509_V_OK) {
      snprintf(err, errcap, "the server's certificate was refused: %s",
               X509_verify_cert_error_string(v));
    } else {
      ssl_why(err, errcap, "the handshake failed");
    }
    goto bad;
  }

  return t;

bad:
  if (t != NULL) {
    if (t->ssl != NULL) SSL_free(t->ssl);
    if (t->ctx != NULL) SSL_CTX_free(t->ctx);
    free(t);
  }
  return NULL;
}

/* Records why an SSL call stopped, in the handle, for the caller to ask
 * about afterwards. A clean shutdown leaves the field EMPTY: there is
 * nothing wrong with the far end having finished. */
static void tls_note(struct zt_tls *t, int k)
{
  int e = SSL_get_error(t->ssl, k);
  t->why[0] = '\0';
  if (e == SSL_ERROR_ZERO_RETURN) return;
  if (e == SSL_ERROR_SSL) {
    unsigned long q = ERR_get_error();
    if (q) {
      const char *r = ERR_reason_error_string(q);
      if (r == NULL) r = "the TLS session failed";
      /* THE ONE ALERT WORTH A SENTENCE OF ITS OWN. A server whose
       * `TLS_CLIENT_AUTH' is REQUIRED and a client with no certificate
       * is a configuration mismatch with an exact remedy, and the bare
       * alert names the problem without naming the two flags that fix
       * it. Every other alert is left in OpenSSL's words. */
      if (strstr(r, "certificate required") != NULL)
        snprintf(t->why, sizeof t->why,
                 "%s -- this server wants a client certificate: --cert and --key", r);
      else
        snprintf(t->why, sizeof t->why, "%s", r);
      return;
    }
  }
  if (e == SSL_ERROR_SYSCALL && errno != 0) {
    snprintf(t->why, sizeof t->why, "%s", strerror(errno));
    return;
  }
  if (e != SSL_ERROR_NONE) {
    snprintf(t->why, sizeof t->why, "the TLS session ended unexpectedly");
  }
}

long coco_client_tls_send(void *handle, const void *buf, size_t n)
{
  struct zt_tls *t = (struct zt_tls *) handle;
  int k = SSL_write(t->ssl, buf, (int) n);
  if (k > 0) return (long) k;
  tls_note(t, k);
  return -1;
}

long coco_client_tls_recv(void *handle, void *buf, size_t n)
{
  struct zt_tls *t = (struct zt_tls *) handle;
  int k = SSL_read(t->ssl, buf, (int) n);
  if (k > 0) return (long) k;
  tls_note(t, k);
  /* A clean close and a broken one both end the read. The caller has
   * Content-Length and does not need to tell them apart; what it must
   * not do is treat either as more bytes. `coco_client_tls_why' is where
   * a caller that DOES care goes to ask. */
  return 0;
}

int coco_client_tls_why(void *handle, char *buf, size_t cap)
{
  struct zt_tls *t = (struct zt_tls *) handle;
  if (t == NULL || t->why[0] == '\0' || cap == 0) return 0;
  snprintf(buf, cap, "%s", t->why);
  return 1;
}

void coco_client_tls_close(void *handle)
{
  struct zt_tls *t = (struct zt_tls *) handle;
  if (t == NULL) return;
  if (t->ssl != NULL) { SSL_shutdown(t->ssl); SSL_free(t->ssl); }
  if (t->ctx != NULL) SSL_CTX_free(t->ctx);
  free(t);
}

#else  /* no OpenSSL at build time */

/* THE STUB IS NOT AN ERROR PATH, it is the honest answer to a build that
 * had no OpenSSL. `--https' reports it by name; everything else in the
 * client is unaffected, and zeytun.c still knows nothing about TLS. */

int coco_client_tls_available(void) { return 0; }

void *coco_client_tls_open(int fd, const char *host, const coco_tls_options *o,
                  char *err, size_t errcap)
{
  (void) fd; (void) host; (void) o;
  snprintf(err, errcap,
           "this cocolog was built without TLS -- rebuild where OpenSSL headers are present");
  return NULL;
}

long coco_client_tls_send(void *h, const void *b, size_t n) { (void)h; (void)b; (void)n; return -1; }
long coco_client_tls_recv(void *h, void *b, size_t n)       { (void)h; (void)b; (void)n; return 0; }
void coco_client_tls_close(void *h)                          { (void)h; }
int  coco_client_tls_why(void *h, char *b, size_t c)         { (void)h; (void)b; (void)c; return 0; }

#endif
