/* test/refuse.c -- a preload that refuses memory, for test/async.pl
 * (`refusals'): what a program does when the allocator answers nothing.
 *
 * An address-space ceiling (`ulimit -v') refuses whichever allocation
 * happens to be the one that does not fit, which is nearly always a big
 * one. This refuses exactly the N-th allocation a program makes between
 * two marks, so that over a row of runs every allocation of the stretch
 * -- a machine, a token's buffer, a status' copy, a table's growth -- is
 * the one refused, once.
 *
 *   LD_PRELOAD=refuse.so REFUSE_N=k PROGRAM   the k-th allocation counted
 *                                             answers NULL, and no other
 *   LD_PRELOAD=refuse.so REFUSE_REPORT=1 ...  none is refused; `REFUSE
 *                                             count N' on stderr at exit
 *   REFUSE_BT=1                               with REFUSE_N: each refused
 *                                             call's backtrace on stderr
 *   REFUSE_SIZE=b                             only requests of exactly b
 *                                             bytes are counted
 *   REFUSE_MIN=b                              only requests of b bytes or
 *                                             more are counted: with
 *                                             REFUSE_N=1 REFUSE_RUN=0, a
 *                                             ceiling on what is big and
 *                                             on nothing else
 *   REFUSE_RUN=r                              the k-th and the r - 1 after
 *                                             it are refused; 0, every one
 *                                             from the k-th to the end of
 *                                             the stretch
 *
 * ONE REFUSAL NEVER ENDS A GROWTH of the machine's arrays, the store's or
 * a character buffer: each, refused its doubling, asks again for less
 * (cocolog's `coco_grow_short', `coco_store_grow', `coco_sb_grow') and is
 * given it. Two in a row is such a growth refused outright, and all of
 * them from the k-th on is what a machine out of memory is like: nothing
 * more until the stretch ends. A walk's stack and a builtin's own scratch
 * array ask once: there one refusal is the growth refused.
 *
 * THE PROGRAM MARKS THE STRETCH ITSELF: getenv("REFUSE_ON") starts the
 * count and getenv("REFUSE_OFF") stops it, each answered NULL (in cocolog,
 * getenv/2 fails). Nothing is counted or refused outside the marks.
 *
 * Built by the case that uses it, with the suite's compiler and -O3; never
 * committed built. glibc only: the allocator behind is called by its
 * __libc names.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <execinfo.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern void *__libc_malloc(size_t);
extern void *__libc_calloc(size_t, size_t);
extern void *__libc_realloc(void *, size_t);
extern char **environ;

static atomic_long count;
static atomic_int on;
static long target = -2, only, atleast, run = 1;
static int report, bt;
/* inside the backtrace, which allocates on its own account: not counted */
static __thread int inside;

/* the environment, read without getenv (which is ours) and without memory */
static const char *env(const char *key) {
    size_t n = strlen(key);
    for (char **e = environ; e != NULL && *e != NULL; e++)
        if (strncmp(*e, key, n) == 0 && (*e)[n] == '=') return *e + n + 1;
    return NULL;
}

static void init(void) {
    const char *s = env("REFUSE_N");
    report = env("REFUSE_REPORT") != NULL;
    bt = env("REFUSE_BT") != NULL;
    target = s != NULL ? atol(s) : -1;
    s = env("REFUSE_SIZE");
    only = s != NULL ? atol(s) : 0;
    s = env("REFUSE_MIN");
    atleast = s != NULL ? atol(s) : 0;
    s = env("REFUSE_RUN");
    run = s != NULL ? atol(s) : 1;
}

static int refuse(size_t bytes) {
    long c;
    if (target == -2) init();
    if (!on || inside || (only != 0 && (long) bytes != only)
        || (atleast != 0 && (long) bytes < atleast)) return 0;
    c = atomic_fetch_add(&count, 1) + 1;
    if (target < 1 || c < target || (run != 0 && c >= target + run)) return 0;
    if (bt) {
        void *frames[32];
        char line[64];
        int n = snprintf(line, sizeof line, "REFUSED #%ld, %zu bytes\n", c, bytes);
        inside = 1;
        if (write(2, line, (size_t) n) >= 0)
            backtrace_symbols_fd(frames, backtrace(frames, 32), 2);
        inside = 0;
    }
    errno = ENOMEM;
    return 1;
}

void *malloc(size_t n) { return refuse(n) ? NULL : __libc_malloc(n); }
void *calloc(size_t a, size_t b) { return refuse(a * b) ? NULL : __libc_calloc(a, b); }
void *realloc(void *p, size_t n) { return refuse(n) ? NULL : __libc_realloc(p, n); }

char *getenv(const char *name) {
    if (strcmp(name, "REFUSE_ON") == 0) { on = 1; return NULL; }
    if (strcmp(name, "REFUSE_OFF") == 0) { on = 0; return NULL; }
    return (char *) env(name);
}

__attribute__((destructor)) static void said(void) {
    char line[64];
    int n;
    if (!report) return;
    n = snprintf(line, sizeof line, "REFUSE count %ld\n", (long) count);
    if (write(2, line, (size_t) n) < 0) return;
}
