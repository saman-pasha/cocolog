/* probe.c -- proves the C client against a running server.
 *
 * This is not a unit test and does not pretend to be one: every case here
 * needs a server on the other end, and what it is checking is that the bytes
 * this client writes are the bytes the C++ server expects. A mock would check
 * that the client agrees with itself, which is the one thing that was never in
 * doubt.
 *
 * IT DOES NOT COMPILE ANYTHING OVER THE WIRE. `compile' is refused unless
 * COMPILER/REMOTE_MODE is TRUE, and it is FALSE by default for a good reason:
 * it is remote code execution by design. The objects this exercises are
 * compiled by cocolog/build.sh with the parsi program, which is the way
 * ZiguratIP expects objects to arrive.
 *
 * Run it with Test/run-c-connector.sh, which raises a server with a store of
 * its own, compiles the objects, runs this against it, and stops it again.
 *
 * Usage: zgc-probe [host] [port]
 */

#include "zigurat.h"
#include "zeytun.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int failures = 0;

static void ok(const char *what, int passed, const char *detail)
{
  if (passed) printf("ok   %-46s %s\n", what, detail ? detail : "");
  else      { printf("FAIL %-46s %s\n", what, detail ? detail : ""); failures++; }
}

/* Reads a call's results to the end, keeping the RETURN_VALUE if there is one.
 * Every call has to be read to SUCCESSFUL_DONE: what is left unread stays in
 * the stream and the next call reads it instead of its own reply. */
static int finish_long(zg_conn *c, int64_t *returned, int row_fields)
{
  zg_result_t r;
  int got = 0;
  for (;;) {
    if (!zg_result(c, &r)) return -1;
    if (r == ZG_SUCCESSFUL_DONE) break;
    if (r == ZG_RETURN_VALUE) {
      if (!zg_read_long(c, returned, NULL)) return -1;
      got = 1;
    } else if (r == ZG_CURSOR_OPEN) {
      char cols[ZG_MAX_STRING + 1];
      if (!zg_columns(c, cols, sizeof cols)) return -1;
    } else if (r == ZG_CURSOR_FETCH) {
      int i;
      for (i = 0; i < row_fields; i++)
        if (!zg_skip_field(c)) return -1;
    }
  }
  return got;
}

static int call_forget_all(zg_conn *c, const char *kb, int64_t *gone)
{
  if (!zg_call(c, "cocolog::forget_all")) return 0;
  if (!zg_write_string(c, kb)) return 0;
  return finish_long(c, gone, 0) >= 0;
}

static int call_assert(zg_conn *c, const char *kb, const char *name, int32_t arity,
                       int64_t ordinal, const char *body, int64_t *id)
{
  if (!zg_call(c, "cocolog::assert_clause")) return 0;
  if (!zg_write_string(c, kb)) return 0;
  if (!zg_write_string(c, name)) return 0;
  if (!zg_write_int(c, arity)) return 0;
  if (!zg_write_long(c, ordinal)) return 0;
  if (!zg_write_text(c, body)) return 0;
  return finish_long(c, id, 0) == 1;
}

int main(int argc, char **argv)
{
  const char *host = (argc > 1) ? argv[1] : "127.0.0.1";
  const char *port = (argc > 2) ? argv[2] : "2160";
  const char *KB   = "probe";
  char err[512];
  zg_conn *c;

  c = zg_open(host, port, 20, err, sizeof err);
  if (!c) {
    fprintf(stderr, "cannot reach a server at %s:%s -- %s\n", host, port, err);
    return 2;
  }
  ok("connected", 1, host);

  /* The server speaks first, with the id of the transaction this connection
   * is. A zero would mean the eight bytes were not read, or were read at the
   * wrong width. */
  {
    char d[64];
    snprintf(d, sizeof d, "%llu", (unsigned long long)zg_transaction_id(c));
    ok("the server opened a transaction", zg_transaction_id(c) != 0, d);
  }

  /* echo is the whole framing in one call: a verb, a result byte, a string out
   * and a string back. If the length prefix or the byte order were wrong,
   * nothing below would work either. */
  {
    char back[300];
    int got = zg_echo(c, "cocolog", back, sizeof back);
    ok("echo round trip", got && strcmp(back, "cocolog") == 0, got ? back : zg_error(c));
  }
  {
    char back[300];
    int got = zg_echo(c, "", back, sizeof back);
    ok("echo of nothing", got && back[0] == '\0', got ? "(empty)" : zg_error(c));
  }
  {
    char big[300], back[300];
    memset(big, 'x', 255); big[255] = '\0';
    ok("echo at the 255 byte limit",
       zg_echo(c, big, back, sizeof back) && strlen(back) == 255, "255");

    memset(big, 'x', 256); big[256] = '\0';
    ok("a longer String is refused, not cut", zg_echo(c, big, back, sizeof back) == 0,
       zg_error(c));
  }
  /* The refusal above must not have desynchronised anything: the length is
   * checked before the verb goes out precisely so that this still works. */
  {
    char back[300];
    int got = zg_echo(c, "still here", back, sizeof back);
    ok("and the connection is still in step", got && strcmp(back, "still here") == 0,
       got ? back : zg_error(c));
  }

  /* ---- the knowledge base ------------------------------------------- */

  {
    int64_t gone = 0;
    ok("cleared the probe knowledge base", call_forget_all(c, KB, &gone), "");
  }

  {
    int64_t id = 0;
    int all = 1;
    all &= call_assert(c, KB, "parent", 2, 0, "parent(tom,bob)", &id);
    all &= call_assert(c, KB, "parent", 2, 1, "parent(bob,ann)", &id);
    all &= call_assert(c, KB, "ancestor", 2, 0,
                       "ancestor(X,Y) :- parent(X,Y)", &id);
    ok("asserted three clauses", all, all ? "3" : zg_error(c));
  }

  {
    int64_t n = -1;
    int got = zg_call(c, "cocolog::clause_count");
    if (got) got = zg_write_string(c, KB);
    if (got) got = zg_write_string(c, "parent");
    if (got) got = zg_write_int(c, 2);
    if (got) got = (finish_long(c, &n, 0) == 1);
    ok("parent/2 has two clauses", got && n == 2, got ? "2" : zg_error(c));
  }

  /* Reading a cursor field by field, in the column order the server just
   * announced. This is the call the interpreter's knowledge-base backend
   * makes, so it is the one that has to work. */
  {
    int rows = 0, ordered = 1;
    char cols[ZG_MAX_STRING + 1];
    char seen[4][256];
    int got = zg_call(c, "cocolog::clauses_of");
    cols[0] = '\0';
    if (got) got = zg_write_string(c, KB);
    if (got) got = zg_write_string(c, "parent");
    if (got) got = zg_write_int(c, 2);
    if (got) {
      zg_result_t r;
      while (zg_result(c, &r) && r != ZG_SUCCESSFUL_DONE) {
        if (r == ZG_CURSOR_OPEN) {
          zg_columns(c, cols, sizeof cols);
        } else if (r == ZG_CURSOR_FETCH) {
          int64_t ordinal = -1;
          char *body = NULL;
          size_t len = 0;
          if (!zg_read_long(c, &ordinal, NULL)) break;
          if (!zg_read_text_alloc(c, &body, &len, NULL)) break;
          /* A cursor is not ordered. `ordinal' is a column precisely so that
           * the client can put the clauses back in the order the program was
           * written in -- indexing by row number instead was wrong, and the
           * rows came back the other way round often enough to catch it. */
          if (ordinal >= 0 && ordinal < 4 && body)
            snprintf(seen[ordinal], sizeof seen[0], "%s", body);
          free(body);
          rows++;
        } else if (r == ZG_RETURN_VALUE) {
          zg_skip_field(c);
        }
      }
    }
    ok("read both clauses back", rows == 2, cols);
    ok("and they sort into the order they were asserted in",
       rows == 2 && strcmp(seen[0], "parent(tom,bob)") == 0
                 && strcmp(seen[1], "parent(bob,ann)") == 0,
       rows == 2 ? seen[0] : "");
    (void)ordered;
  }

  /* ---- a suspended machine ------------------------------------------- */

  {
    int64_t mid = 0;
    int got = zg_call(c, "cocolog::machine_open");
    if (got) got = zg_write_string(c, "probe-machine");
    if (got) got = zg_write_string(c, KB);
    if (got) got = zg_write_string(c, "suspended");
    if (got) got = zg_write_int(c, 2);
    if (got) got = zg_write_string(c, "written by zgc-probe");
    if (got) got = (finish_long(c, &mid, 0) == 1);
    ok("registered a machine", got && mid > 0, got ? "probe-machine" : zg_error(c));

    if (got) {
      int64_t rid = 0;
      int put = zg_call(c, "cocolog::machine_chunk");
      if (put) put = zg_write_long(c, mid);
      if (put) put = zg_write_int(c, 0);
      if (put) put = zg_write_text(c, "cocolog 1 chunk zero ");
      if (put) put = (finish_long(c, &rid, 0) == 1);

      if (put) put = zg_call(c, "cocolog::machine_chunk");
      if (put) put = zg_write_long(c, mid);
      if (put) put = zg_write_int(c, 1);
      if (put) put = zg_write_text(c, "and chunk one");
      if (put) put = (finish_long(c, &rid, 0) == 1);
      ok("stored its state in two chunks", put, put ? "2" : zg_error(c));

      /* Put back together in seq order, which is why seq is a column. */
      {
        char whole[512];
        char parts[8][256];
        int n = 0, i;
        int read = zg_call(c, "cocolog::machine_load");
        whole[0] = '\0';
        for (i = 0; i < 8; i++) parts[i][0] = '\0';
        if (read) read = zg_write_long(c, mid);
        if (read) {
          zg_result_t r;
          while (zg_result(c, &r) && r != ZG_SUCCESSFUL_DONE) {
            if (r == ZG_CURSOR_OPEN) { char cc[256]; zg_columns(c, cc, sizeof cc); }
            else if (r == ZG_CURSOR_FETCH) {
              int32_t seq = -1;
              char *chunk = NULL;
              size_t len = 0;
              if (!zg_read_int(c, &seq, NULL)) break;
              if (!zg_read_text_alloc(c, &chunk, &len, NULL)) break;
              if (seq >= 0 && seq < 8 && chunk) snprintf(parts[seq], sizeof parts[0], "%s", chunk);
              free(chunk);
              n++;
            } else if (r == ZG_RETURN_VALUE) zg_skip_field(c);
          }
        }
        for (i = 0; i < 8; i++)
          if (parts[i][0]) strncat(whole, parts[i], sizeof whole - strlen(whole) - 1);
        ok("reassembled it in seq order",
           n == 2 && strcmp(whole, "cocolog 1 chunk zero and chunk one") == 0, whole);
      }
    }
  }

  ok("committed", zg_commit(c), "");

  /* A Text field is what a frozen machine travels in, so its limit is worth
   * knowing rather than discovering. The client refuses the length rather than
   * letting the server truncate it to 16 bits. */
  {
    char *big = (char *)malloc(ZG_MAX_TEXT + 2);
    int refused;
    memset(big, 'z', ZG_MAX_TEXT + 1);
    big[ZG_MAX_TEXT + 1] = '\0';
    refused = (zg_call(c, "cocolog::machine_chunk") &&
               zg_write_long(c, 1) && zg_write_int(c, 0) &&
               zg_write_text(c, big) == 0);
    ok("a Text over 65535 bytes is refused", refused, zg_error(c));
    free(big);
    /* That one DID desynchronise the connection -- the verb went out and the
     * argument did not -- which is exactly what the header warns about, so
     * nothing is attempted on it afterwards. */
  }

  zg_close(c);

  /* ---- the same knowledge base over Zeytun's pages ------------------- */
  /* The rows above were committed, so a second connection -- an HTTP one,
   * on a different port, in a different transaction -- can see them. That is
   * the whole point of the second transport, and the one thing a test of it
   * has to show. */
  {
    char err[512], path[512], enc[256], *body = NULL;
    zt_urlencode(KB, enc, sizeof enc);
    snprintf(path, sizeof path, "/cocolog/kb.zt?kb=%s&name=parent", enc);
    if (zt_get("127.0.0.1", "2190", path, 15, &body, NULL, err, sizeof err)) {
      zt_unescape(body);
      ok("the page served the same clauses",
         strstr(body, "parent(tom,bob)") != NULL && strstr(body, "parent(bob,ann)") != NULL,
         "kb.zt");
      free(body);
    } else {
      ok("the page served the same clauses", 0, err);
    }
  }

  /* Escaping is the one thing the HTTP path can silently corrupt, so a clause
   * made of nothing but the five escaped characters is asserted and read back
   * through a page. */
  {
    char err[512], path[512], enc[256], *body = NULL;
    const char *awkward = "tricky('a<b>c&d\"e''f')";
    int64_t id = 0;
    zg_conn *w = zg_open(host, port, 20, err, sizeof err);
    int stored = 0;
    if (w) {
      stored = call_assert(w, KB, "tricky", 1, 0, awkward, &id) && zg_commit(w);
      zg_close(w);
    }
    ok("stored a clause full of escapable characters", stored, stored ? awkward : err);

    zt_urlencode(KB, enc, sizeof enc);
    snprintf(path, sizeof path, "/cocolog/kb.zt?kb=%s&name=tricky", enc);
    if (stored && zt_get("127.0.0.1", "2190", path, 15, &body, NULL, err, sizeof err)) {
      zt_unescape(body);
      ok("and it survived the page unchanged", strstr(body, awkward) != NULL,
         strstr(body, awkward) ? awkward : body);
      free(body);
    } else {
      ok("and it survived the page unchanged", 0, err);
    }
  }

  printf("\n%s: %d failure(s)\n", failures ? "RED" : "GREEN", failures);
  return failures ? 1 : 0;
}
