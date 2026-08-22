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
 * IT IS A MINIMAL CLIENT AND SAYS SO. One request per call, no keep-alive, no
 * chunked transfer encoding, no redirects, no TLS. Zeytun answers a GET with
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
