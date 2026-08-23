/* A C smoke run over the ce_* surface: the same call/write/result/read
 * conversation client/zigurat.c will forward, without cocolog on top. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

extern int ce_engine_open(const char *dir, char *err, size_t errcap);
extern void ce_engine_close(void);
extern void *ce_session_new(void);
extern void ce_session_free(void *s);
extern const char *ce_error(void *s);
extern int ce_call(void *s, const char *proc);
extern int ce_write_num(void *s, int tag, long long v);
extern int ce_write_str(void *s, int tag, const char *v);
extern int ce_result(void *s, int *out);
extern int ce_columns(void *s, char *buf, size_t cap);
extern int ce_read_num(void *s, long long *v);
extern int ce_read_str(void *s, char *buf, size_t cap);
extern int ce_skip(void *s);
extern int ce_commit(void *s);
extern int ce_rollback(void *s);

#define TDB_INT 0x0B
#define TDB_LONG 0x0C
#define TDB_STRING 0x29
#define TDB_TEXT 0x49

static int failures = 0;
static void check(const char *what, long long got, long long want)
{
  if (got == want) printf("ok   %-44s %lld\n", what, got);
  else { printf("FAIL %-44s got %lld want %lld\n", what, got, want); failures++; }
}

/* runs a call already parameterised, expecting RETURN + a long */
static long long ret_long(void *s)
{
  int r = -1; long long v = -99;
  if (!ce_result(s, &r) || r != 4) { printf("  (no RETURN: %s)\n", ce_error(s)); return -99; }
  if (!ce_read_num(s, &v)) return -99;
  if (!ce_result(s, &r) || r != 0) return -98;
  return v;
}

struct claimer { const char *worker; char got[256]; };
static void *claim_thread(void *arg)
{
  struct claimer *cl = (struct claimer *)arg;
  void *s = ce_session_new();
  int r = -1;
  cl->got[0] = '\0';
  ce_call(s, "cocolog::machine_claim_named");
  ce_write_str(s, TDB_STRING, "m-race");
  ce_write_str(s, TDB_STRING, cl->worker);
  if (ce_result(s, &r) && r == 4) {
    ce_read_str(s, cl->got, sizeof cl->got);
    ce_result(s, &r);
  }
  ce_commit(s);
  ce_session_free(s);
  return NULL;
}

int main(void)
{
  char err[512];
  system("rm -rf /tmp/ce-smoke-store");
  if (!ce_engine_open("/tmp/ce-smoke-store", err, sizeof err)) {
    printf("FAIL open: %s\n", err); return 1;
  }
  void *s = ce_session_new();

  /* two clauses in, read back ordered by what was written */
  ce_call(s, "cocolog::assert_clause");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  ce_write_num(s, TDB_LONG, 1);
  ce_write_str(s, TDB_TEXT, "parent(tom, bob).");
  check("assert_clause answers the first id", ret_long(s), 1);

  ce_call(s, "cocolog::assert_clause");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  ce_write_num(s, TDB_LONG, 2);
  ce_write_str(s, TDB_TEXT, "parent(bob, ann).");
  check("and the second", ret_long(s), 2);
  ce_commit(s);

  ce_call(s, "cocolog::clause_count");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  check("clause_count sees both", ret_long(s), 2);

  /* the cursor shape: OPEN, columns, FETCH rows, CLOSE, DONE */
  {
    int r = -1, rows = 0; char cols[256]; long long ordsum = 0;
    ce_call(s, "cocolog::clauses_of");
    ce_write_str(s, TDB_STRING, "kb1");
    ce_write_str(s, TDB_STRING, "parent");
    ce_write_num(s, TDB_INT, 2);
    while (ce_result(s, &r)) {
      if (r == 0) break;
      if (r == 1) ce_columns(s, cols, sizeof cols);
      else if (r == 2) {
        long long o; char body[512];
        ce_read_num(s, &o); ce_read_str(s, body, sizeof body);
        ordsum += o; rows++;
        if (o == 1) check("the first body survives byte for byte",
                          strcmp(body, "parent(tom, bob)."), 0);
      }
    }
    check("clauses_of fetches two rows", rows, 2);
    check("with their ordinals", ordsum, 3);
  }

  ce_call(s, "cocolog::declare_dynamic");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "mood");
  ce_write_num(s, TDB_INT, 1);
  check("declare_dynamic says it wrote", ret_long(s), 1);
  ce_call(s, "cocolog::declare_dynamic");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "mood");
  ce_write_num(s, TDB_INT, 1);
  check("and then that it did not", ret_long(s), 0);

  ce_call(s, "cocolog::forget_clauses");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  check("forget_clauses counts what went", ret_long(s), 2);
  ce_call(s, "cocolog::clause_count");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  check("and they are gone", ret_long(s), 0);
  ce_commit(s);

  /* a machine, its chunks, and the claim */
  ce_call(s, "cocolog::machine_open");
  ce_write_str(s, TDB_STRING, "m-race");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "suspended");
  ce_write_num(s, TDB_INT, 2);
  ce_write_str(s, TDB_STRING, "a goal");
  long long mid = ret_long(s);
  check("machine_open answers an id", mid > 0, 1);
  ce_call(s, "cocolog::machine_chunk");
  ce_write_num(s, TDB_LONG, mid);
  ce_write_num(s, TDB_INT, 0);
  ce_write_str(s, TDB_TEXT, "chunk-zero");
  check("a chunk stores", ret_long(s) > 0, 1);
  ce_commit(s);

  /* two threads race one claim; exactly one may win */
  {
    pthread_t t1, t2; struct claimer a = {"w1", ""}, b = {"w2", ""};
    pthread_create(&t1, NULL, claim_thread, &a);
    pthread_create(&t2, NULL, claim_thread, &b);
    pthread_join(t1, NULL); pthread_join(t2, NULL);
    int wins = (a.got[0] != '\0') + (b.got[0] != '\0');
    check("two racing claims, one winner", wins, 1);
  }

  ce_call(s, "cocolog::machine_release");
  ce_write_str(s, TDB_STRING, "m-race");
  check("release answers", ret_long(s), 1);
  ce_call(s, "cocolog::machine_drop");
  ce_write_str(s, TDB_STRING, "m-race");
  check("drop answers the id it dropped", ret_long(s), mid);
  ce_commit(s);

  ce_call(s, "cocolog::forget_all");
  ce_write_str(s, TDB_STRING, "kb1");
  ret_long(s);
  ce_commit(s);
  ce_session_free(s);
  ce_engine_close();

  /* and everything committed survives a fresh open */
  if (!ce_engine_open("/tmp/ce-smoke-store", err, sizeof err)) {
    printf("FAIL reopen: %s\n", err); return 1;
  }
  s = ce_session_new();
  ce_call(s, "cocolog::clause_count");
  ce_write_str(s, TDB_STRING, "kb1");
  ce_write_str(s, TDB_STRING, "parent");
  ce_write_num(s, TDB_INT, 2);
  check("the forget survived the restart", ret_long(s), 0);
  ce_session_free(s);
  ce_engine_close();

  if (failures == 0) printf("\nce-smoke: all green\n");
  else printf("\nce-smoke: %d FAILED\n", failures);
  return failures;
}
