#define _GNU_SOURCE 1
/* backend.c -- the tensor_* surface over TensorFlow's C API.
 *
 * THE BACK END of library(tensorflow): TensorFlow's C library, wrapped once,
 * in C, as the handful of operations the predicates in coco-tensorflow.cicili
 * ask for. It has two modes, read from the torch module's switch through
 * coco_tensor_graph_mode() -- tensor_execution(tensorflow, eager | graph) --
 * and ONE MECHANISM under both, so that a program is the same program on
 * either path, and the same program it is on library(torch):
 *
 *   eager  every producer is a TFE_Execute, now, on the device, and a handle
 *          holds the TFE_TensorHandle; a producer that a PARAMETER reaches
 *          also records what it did -- the operation, its attributes, its
 *          inputs -- which is the tape.
 *   graph  every producer only records; a read runs what it needs.
 *
 * A read of a recorded tensor, and a gradient in either mode, collects the
 * CLOSURE of what it needs -- the nodes down to the values they rest on --
 * keys it by structure, and the first time a key is seen COMPILES it, once:
 * a TF_Graph of placeholders and operations, TF_AddGradients over it for a
 * gradient (TensorFlow's own symbolic differentiation), and the whole made a
 * TensorFlow FUNCTION the eager runtime calls, with the leaves' handles as
 * its arguments and handles as its results. Nothing crosses to the host: a
 * parameter lives on the device and the function that steps it finds it
 * there, which is what tf.function is, done from C. Every later time the
 * same key is one call. Under eager the gradient's function recomputes the
 * forward pass it differentiates; under graph one call a step computes the
 * loss, the gradients and the new parameters together.
 *
 * Handles are integers into a slot table, as the torch module's are. The two
 * backends never share a tensor: the switch is per process and a program
 * keeps to one at a time.
 *
 * Random leaves -- randn, rand, randperm -- draw at once in both modes,
 * through the eager context, and are values: a random OP in a graph would
 * redraw at every run, and a leaf read twice would not be one leaf. They are
 * the stateless ops, so a seed set again gives the draws again.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <dlfcn.h>
#include <stdarg.h>
#include <time.h>
#include "tensorflow/c/c_api.h"
#include "tensorflow/c/eager/c_api.h"

#define TF_SLOTS 65536
#define TF_MAXIN 65                /* an operation's inputs: cat takes up to 64, as the front end allows */
#define TF_MAXDIM 8
#define TF_MAXLEAF 4096
#define TF_MAXNODE 8192
#define TF_MAXENTRY 4096
#define TF_MAXPARAM 64

/* THE DESIGN, FOURTH DRAFT. The first built one graph a predicate at a time
 * and ran a session per read, quadratic in the steps. The second keyed the
 * closure of a read and compiled it once, but fed every leaf from the host
 * and fetched every result back, a round trip per step for each parameter,
 * and ran the loss and the gradient as two sessions. The third had no eager
 * gradient at all, the C eager API having no tape. This one:
 *
 *   a slot with a VALUE holds a TFE_TensorHandle, on the device;
 *   a slot with STRUCTURE holds its recipe -- operation, attributes, inputs
 *   -- and a reference on each input; under eager a node has both;
 *   a closure compiles to a TF_Function, called through the eager runtime;
 *   a node keeps its structure after it has a value only when a parameter
 *   is under it -- a loss read by item may still be asked for its gradient
 *   -- and a parameter made by a step lets go of its history at once: a
 *   step is a boundary, not a history.
 *
 * The graph grows with the distinct shapes of computation a program has, not
 * with its steps. Which nodes of a closure are RESULTS of the call -- the
 * ones the program still names, the parameters, the one asked for -- is part
 * of the key, because a function's outputs are fixed when it is made. */

enum { K_FREE = 0, K_VALUE = 1, K_NODE = 2 };

typedef struct {
  const char* op;
  int64_t in[TF_MAXIN]; int nin;
  int list_n;                  /* >0: the first list_n inputs are one input list (ConcatV2) */
  const char* type_attrs[4]; TF_DataType type_vals[4]; int ntypes;
  const char* int_attrs[2]; int64_t int_vals[2]; int nints;
  const char* bool_attrs[2]; unsigned char bool_vals[2]; int nbools;
} OpSpec;

typedef struct {
  int kind;                    /* K_FREE, K_VALUE (a value, no structure), K_NODE (structure; a value too once run) */
  TFE_TensorHandle* eh;        /* the value, on the device */
  TF_Tensor* val;              /* a made constant's host copy (ckey): its values are structure */
  OpSpec spec;                 /* a node's recipe */
  int refs, released;          /* held by nodes that read it; released by the program */
  int ckey;                    /* a leaf made here (an axis, a shape): its VALUES go into the key, and it compiles as a Const */
  int is_param;
  int under_param;             /* a parameter somewhere under it */
  int64_t shape[TF_MAXDIM]; int nd; int shape_known;
  TF_DataType dtype;
} TfSlot;

typedef struct {
  int64_t leaves[TF_MAXLEAF]; int nleaves;
  int64_t nodes[TF_MAXNODE]; int nnodes;
  unsigned char want[TF_MAXNODE];   /* node i is a result of the call */
  char key[1048576]; size_t klen;
} Closure;

typedef struct {
  char* key; uint64_t hash;
  TF_Graph* graph;
  TF_Output* ph; int nleaves;       /* a placeholder or a Const per leaf */
  TF_Output* out; int nnodes;       /* an operation per node */
  int* in_leaf; int nin;            /* the function's arguments: the leaves fed, in order */
  int* out_node; int nwant;         /* the function's first results: the nodes wanted, in order */
  TF_Output grads[TF_MAXPARAM]; int grad_at[TF_MAXPARAM]; int ngrads;  /* then the gradients that exist */
  int noutputs; int calls;
  TF_Function* fn; char fname[40];
} Entry;

static TfSlot slots[TF_SLOTS];
static Entry* entries[TF_MAXENTRY]; static int nentries = 0;
static TFE_Context* ctx = 0;
static TF_Status* st = 0;
static char cpu_name[256], gpu_name[256];   /* the first CPU's and the first GPU's device names; gpu_name empty when there is none */
static int dev_gpu = 0;              /* where new work goes: the GPU, or the CPU */
static int opcount = 0, fncount = 0;
static int64_t seed_base = 1234, seed_next = 0;
static char errbuf[512];
static long long stat_rec = 0, stat_exe = 0, stat_rep = 0;
static int (*graph_mode_fn)(void) = 0;
/* what a run cost, by phase, printed at exit under COCO_TF_TRACE=1 */
static int tf_trace = 0;
enum { P_EXEC, P_CLOSURE, P_COMPILE, P_PLACED, P_SPEC, P_READ, P_N };
static const char* prof_names[P_N] = { "calls", "closures", "compiles", "device copies", "eager ops", "reads" };
static double prof_ms[P_N]; static long prof_n[P_N];
static double now_ms(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return (double) t.tv_sec * 1e3 + (double) t.tv_nsec / 1e6; }
static void prof_add(int k, double t0) { prof_ms[k] += now_ms() - t0; prof_n[k]++; }
static void prof_report(void) {
  fprintf(stderr, "cocolog: tensorflow: what it cost --");
  for (int k = 0; k < P_N; k++) fprintf(stderr, " %s %ld in %.0f ms%s", prof_names[k], prof_n[k], prof_ms[k], k + 1 < P_N ? "," : "\n");
}

/* ---- status --------------------------------------------------------- */
static int bad(void) {
  if (TF_GetCode(st) == TF_OK) return 0;
  snprintf(errbuf, sizeof errbuf, "%s", TF_Message(st));
  TF_SetStatus(st, TF_OK, "");
  return 1;
}
const char* tfb_error(void) { return errbuf; }
static void fail(const char* m) { snprintf(errbuf, sizeof errbuf, "%s", m); }

int tfb_mode(void) { return graph_mode_fn ? graph_mode_fn() : 0; }

/* ---- init ------------------------------------------------------------ */
int tfb_init(void* torch_so) {
  tf_trace = getenv("COCO_TF_TRACE") ? 1 : 0; if (tf_trace) atexit(prof_report);
  if (ctx) return 1;
  st = TF_NewStatus();
  /* a ConfigProto, serialised: gpu_options.allow_growth = true, or TensorFlow
   * would take the whole card at start and share it with nobody; and
   * allow_soft_placement = true, so an operation pinned to a device it has no
   * kernel for runs on the CPU instead of failing */
  static const char grow[] = { 0x32, 0x02, 0x20, 0x01, 0x38, 0x01 };
  TFE_ContextOptions* o = TFE_NewContextOptions();
  TFE_ContextOptionsSetConfig(o, grow, sizeof grow, st); TF_SetStatus(st, TF_OK, "");
  TFE_ContextOptionsSetDevicePlacementPolicy(o, TFE_DEVICE_PLACEMENT_SILENT);
  ctx = TFE_NewContext(o, st); TFE_DeleteContextOptions(o);
  if (bad()) { ctx = 0; return 0; }
  gpu_name[0] = 0; cpu_name[0] = 0;
  TF_DeviceList* dl = TFE_ContextListDevices(ctx, st);
  if (!bad() && dl) {
    int n = TF_DeviceListCount(dl);
    for (int i = 0; i < n; i++) {
      const char* ty = TF_DeviceListType(dl, i, st); if (bad()) break;
      const char* nm = TF_DeviceListName(dl, i, st); if (bad()) break;
      if (ty && nm && 0 == strcmp(ty, "GPU") && !gpu_name[0]) snprintf(gpu_name, sizeof gpu_name, "%s", nm);
      if (ty && nm && 0 == strcmp(ty, "CPU") && !cpu_name[0]) snprintf(cpu_name, sizeof cpu_name, "%s", nm);
    }
    TF_DeleteDeviceList(dl);
  }
  dev_gpu = gpu_name[0] ? 1 : 0;     /* auto, until tensor_execution/3 says otherwise */
  if (torch_so) graph_mode_fn = (int (*)(void)) dlsym(torch_so, "coco_tensor_graph_mode");
  memset(slots, 0, sizeof slots);
  return 1;
}
const char* tfb_version(void) { return TF_Version(); }
/* the device: 0 cpu, 1 cuda, 2 auto (cuda when there is one). Answers 1 when
 * the choice stands, 0 when cuda was asked for and there is none -- the work
 * goes to the CPU then, and the caller says so */
int tfb_device_set(int kind) {
  if (kind == 0) { dev_gpu = 0; return 1; }
  if (kind == 2) { dev_gpu = gpu_name[0] ? 1 : 0; return 1; }
  if (gpu_name[0]) { dev_gpu = 1; return 1; }
  dev_gpu = 0; return 0;
}
int tfb_on_gpu(void) { return dev_gpu; }
/* every operation and every call is pinned to the chosen device, once a
 * machine has more than one to choose from; with only a CPU, nothing is */
static void pin(TFE_Op* op) { if (gpu_name[0]) { TFE_OpSetDevice(op, dev_gpu ? gpu_name : cpu_name, st); TF_SetStatus(st, TF_OK, ""); } }
void tfb_seed(int64_t s) { seed_base = s; seed_next = 0; }

/* ---- slots ----------------------------------------------------------- */
static int64_t slot_cursor = 1;
static int64_t slot_new(void) {
  for (int64_t n = 1; n < TF_SLOTS; n++) {
    int64_t i = slot_cursor; slot_cursor = (slot_cursor + 1 < TF_SLOTS) ? slot_cursor + 1 : 1;
    if (slots[i].kind == K_FREE) { memset(&slots[i], 0, sizeof(TfSlot)); return i; }
  }
  fail("handle table full"); return -1;
}
int tfb_exists(int64_t h) { return h > 0 && h < TF_SLOTS && slots[h].kind != K_FREE && !slots[h].released; }
static int live(int64_t h) { return h > 0 && h < TF_SLOTS && slots[h].kind != K_FREE; }
static void really_free(int64_t h);
static void unref(int64_t h) {
  if (!live(h)) return;
  if (slots[h].refs > 0) slots[h].refs--;
  if (slots[h].released && slots[h].refs == 0) really_free(h);
}
static void really_free(int64_t h) {
  TfSlot* s = &slots[h];
  if (s->eh) TFE_DeleteTensorHandle(s->eh);
  if (s->val) TF_DeleteTensor(s->val);
  int kind = s->kind; OpSpec sp = s->spec;
  memset(s, 0, sizeof *s);
  if (kind == K_NODE) for (int i = 0; i < sp.nin; i++) unref(sp.in[i]);
}
/* the program is done naming it; it goes when nothing reads it any more. A
 * node the tape still holds keeps its recipe and lets its VALUE go: nothing
 * can read it now, and a gradient recomputes it from the leaves -- as torch
 * frees an intermediate once the program has dropped it */
int tfb_free(int64_t h) {
  if (!tfb_exists(h)) return 0;
  slots[h].released = 1;
  if (slots[h].refs == 0) { really_free(h); return 1; }
  if (slots[h].kind == K_NODE && slots[h].eh) { TFE_DeleteTensorHandle(slots[h].eh); slots[h].eh = 0; }
  return 1;
}
/* a node that is a value now, and only a value: its inputs are let go */
static void drop_structure(int64_t h) {
  TfSlot* s = &slots[h];
  if (s->kind != K_NODE) return;
  OpSpec sp = s->spec; memset(&s->spec, 0, sizeof s->spec); s->kind = K_VALUE;
  for (int k = 0; k < sp.nin; k++) unref(sp.in[k]);
}
static void set_shape_from_tensor(TfSlot* s, TF_Tensor* t) {
  s->nd = TF_NumDims(t); if (s->nd > TF_MAXDIM) s->nd = TF_MAXDIM;
  for (int i = 0; i < s->nd; i++) s->shape[i] = TF_Dim(t, i);
  s->shape_known = 1; s->dtype = TF_TensorType(t);
}
/* the slot takes the handle as its value */
static void take_handle(TfSlot* s, TFE_TensorHandle* eh) {
  if (s->eh) TFE_DeleteTensorHandle(s->eh);
  s->eh = eh;
  s->nd = TFE_TensorHandleNumDims(eh, st); TF_SetStatus(st, TF_OK, "");
  if (s->nd < 0) s->nd = 0;
  if (s->nd > TF_MAXDIM) s->nd = TF_MAXDIM;
  for (int i = 0; i < s->nd; i++) { s->shape[i] = TFE_TensorHandleDim(eh, i, st); TF_SetStatus(st, TF_OK, ""); }
  s->shape_known = 1; s->dtype = TFE_TensorHandleDataType(eh);
}
/* a float made on the host goes to the device once, at birth: the function
 * that reads it every step then finds it there. Integers -- axes, shapes,
 * indices -- are host-side operands and stay. */
static TFE_TensorHandle* placed_(TFE_TensorHandle* h) {
  if (!dev_gpu || TFE_TensorHandleDataType(h) != TF_FLOAT) return h;
  TFE_TensorHandle* d = TFE_TensorHandleCopyToDevice(h, ctx, gpu_name, st);
  if (TF_GetCode(st) != TF_OK || !d) { TF_SetStatus(st, TF_OK, ""); return h; }
  TFE_DeleteTensorHandle(h);
  return d;
}
static TFE_TensorHandle* placed(TFE_TensorHandle* h) { double t = now_ms(); TFE_TensorHandle* r = placed_(h); prof_add(P_PLACED, t); return r; }


/* ---- tensors from data --------------------------------------------- */
static TF_Tensor* tensor_f32(const double* data, const int64_t* shape, int nd) {
  int64_t n = 1; for (int i = 0; i < nd; i++) n *= shape[i];
  TF_Tensor* t = TF_AllocateTensor(TF_FLOAT, shape, nd, (size_t)(n * 4));
  float* p = (float*) TF_TensorData(t);
  for (int64_t i = 0; i < n; i++) p[i] = (float) data[i];
  return t;
}
static TF_Tensor* tensor_i32(const int64_t* data, const int64_t* shape, int nd) {
  int64_t n = 1; for (int i = 0; i < nd; i++) n *= shape[i];
  TF_Tensor* t = TF_AllocateTensor(TF_INT32, shape, nd, (size_t)(n * 4));
  int32_t* p = (int32_t*) TF_TensorData(t);
  for (int64_t i = 0; i < n; i++) p[i] = (int32_t) data[i];
  return t;
}
/* a slot holding a value made on the host */
static int64_t slot_from_tensor(TF_Tensor* t, int ckey) {
  int64_t h = slot_new(); if (h < 0) { TF_DeleteTensor(t); return -1; }
  TfSlot* s = &slots[h];
  set_shape_from_tensor(s, t);
  s->eh = TFE_NewTensorHandle(t, st);
  if (bad()) { TF_DeleteTensor(t); s->kind = K_FREE; return -1; }
  s->kind = K_VALUE; s->ckey = ckey;
  if (ckey) s->val = t;                      /* the values stay readable: they are structure */
  else { s->eh = placed(s->eh); TF_DeleteTensor(t); }
  return h;
}
/* a slot holding a value the runtime made */
static int64_t slot_from_handle(TFE_TensorHandle* eh) {
  int64_t h = slot_new(); if (h < 0) { TFE_DeleteTensorHandle(eh); return -1; }
  slots[h].kind = K_VALUE; take_handle(&slots[h], eh);
  return h;
}
int64_t tfb_from_doubles(const double* data, const int64_t* shape, int nd) {
  return slot_from_tensor(tensor_f32(data, shape, nd), 0);
}
int64_t tfb_from_ints(const int64_t* data, int64_t n) {
  int64_t shape[1] = { n };
  return slot_from_tensor(tensor_i32(data, shape, 1), 0);
}
static int64_t ivec(const int64_t* v, int n) { int64_t shape[1] = { n }; return slot_from_tensor(tensor_i32(v, shape, 1), 1); }
static int64_t iscalar(int64_t v) { TF_Tensor* t = TF_AllocateTensor(TF_INT32, 0, 0, 4); *(int32_t*) TF_TensorData(t) = (int32_t) v; return slot_from_tensor(t, 1); }
/* a scalar OPERAND is data, an argument each call and keyed by its shape alone -- a learning
 * rate that changes every step must not change the key, or every step compiles anew */
/* ONE DEVICE TENSOR PER DISTINCT SCALAR VALUE. Adam makes seven scalar
 * operands per parameter per step -- the betas, the epsilon, the corrected
 * rate -- and each was a host tensor copied to the device at birth: on a T4
 * those copies, a hundred and more a step, cost tutorial 34 more than its
 * calls did (7.9 s against 6.7 s, COCO_TF_TRACE=1). A value made once is
 * shared now, the slot holding a handle on the same device tensor; the
 * table keeps the last TF_SCALARS distinct values, and the rate that changes
 * every step turns over one entry a step. Nothing is ever written into a
 * value, so sharing is safe. */
#define TF_SCALARS 256
static struct { float v; TFE_TensorHandle* eh; } scalar_cache[TF_SCALARS];
static int nscalars = 0, scalar_next = 0;
static int64_t fscalar(double v) {
  float f = (float) v;
  for (int i = 0; i < nscalars; i++) if (scalar_cache[i].v == f) {
    TFE_TensorHandle* sh = TFE_TensorHandleCopySharingTensor(scalar_cache[i].eh, st); if (bad()) return -1;
    return slot_from_handle(sh);
  }
  TF_Tensor* t = TF_AllocateTensor(TF_FLOAT, 0, 0, 4); *(float*) TF_TensorData(t) = f;
  int64_t h = slot_from_tensor(t, 0); if (h < 0) return -1;
  TFE_TensorHandle* keep = TFE_TensorHandleCopySharingTensor(slots[h].eh, st);
  if (bad()) return h;
  int i = nscalars < TF_SCALARS ? nscalars++ : scalar_next;
  if (i == scalar_next) scalar_next = (scalar_next + 1) % TF_SCALARS;
  if (scalar_cache[i].eh) TFE_DeleteTensorHandle(scalar_cache[i].eh);
  scalar_cache[i].v = f; scalar_cache[i].eh = keep;
  return h;
}
static int64_t with_free(int64_t result, int64_t tmp) { if (tmp > 0) tfb_free(tmp); return result; }

/* ---- the closure of a node, and its key ------------------------------------- */
static void kput(Closure* c, const char* fmt, ...) {
  va_list ap; va_start(ap, fmt);
  if (c->klen < sizeof c->key - 1) {
    int n = vsnprintf(c->key + c->klen, sizeof c->key - c->klen, fmt, ap);
    if (n > 0) { c->klen += (size_t) n; if (c->klen >= sizeof c->key) c->klen = sizeof c->key - 1; }
  }
  va_end(ap);
}
/* grad_mode: do not stop at a node that has a value -- its structure is wanted,
 * down to the parameters; a parameter with a value is where it stops */
static int visit(int64_t h, Closure* c, unsigned char* seen, int grad_mode) {
  if (!live(h)) { fail("a tensor this one needs has been freed"); return 0; }
  if (seen[h]) return 1;
  seen[h] = 1;
  TfSlot* s = &slots[h];
  int leaf = (s->kind == K_VALUE) || (s->eh && (!grad_mode || s->is_param));
  if (leaf) { if (c->nleaves >= TF_MAXLEAF) { fail("too many leaves"); return 0; } c->leaves[c->nleaves++] = h; return 1; }
  for (int i = 0; i < s->spec.nin; i++) if (!visit(s->spec.in[i], c, seen, grad_mode)) return 0;
  if (c->nnodes >= TF_MAXNODE) { fail("too many nodes"); return 0; }
  c->nodes[c->nnodes++] = h;
  return 1;
}
static int leaf_index(Closure* c, int64_t h) { for (int j = 0; j < c->nleaves; j++) if (c->leaves[j] == h) return j; return -1; }
static int node_index(Closure* c, int64_t h) { for (int i = 0; i < c->nnodes; i++) if (c->nodes[i] == h) return i; return -1; }
static void key_leaf(Closure* c, int j) {
  TfSlot* s = &slots[c->leaves[j]];
  kput(c, "L%d:%d[", j, (int) s->dtype);
  for (int d = 0; d < s->nd; d++) kput(c, "%lld,", (long long) s->shape[d]);
  kput(c, "]");
  if (s->ckey && s->val) {    /* a made constant: its values are part of the structure */
    int64_t n = TF_TensorElementCount(s->val); kput(c, "=");
    if (s->dtype == TF_INT32) { int32_t* p = (int32_t*) TF_TensorData(s->val); for (int64_t i = 0; i < n && i < 32; i++) kput(c, "%d,", p[i]); }
    else if (s->dtype == TF_FLOAT) { float* p = (float*) TF_TensorData(s->val); for (int64_t i = 0; i < n && i < 32; i++) kput(c, "%g,", p[i]); }
  }
  kput(c, " ");
}
/* the closure of h, keyed; the results of a call on it are the nodes without a
 * value that the program still names, the parameters, and h itself */
static int closure_of_(int64_t h, int grad_mode, Closure* c) {
  c->nleaves = 0; c->nnodes = 0; c->klen = 0; c->key[0] = 0;
  unsigned char* seen = (unsigned char*) calloc(TF_SLOTS, 1);
  int ok = visit(h, c, seen, grad_mode);
  free(seen);
  if (!ok) return 0;
  for (int i = 0; i < c->nnodes; i++) {
    TfSlot* s = &slots[c->nodes[i]];
    c->want[i] = (unsigned char)(!s->eh && (!s->released || s->is_param || c->nodes[i] == h));
  }
  for (int j = 0; j < c->nleaves; j++) key_leaf(c, j);
  for (int i = 0; i < c->nnodes; i++) {
    OpSpec* p = &slots[c->nodes[i]].spec;
    kput(c, "N%d=%s{", i, p->op);
    for (int k = 0; k < p->ntypes; k++) kput(c, "%s:%d,", p->type_attrs[k], (int) p->type_vals[k]);
    for (int k = 0; k < p->nints; k++) kput(c, "%s:%lld,", p->int_attrs[k], (long long) p->int_vals[k]);
    for (int k = 0; k < p->nbools; k++) kput(c, "%s:%d,", p->bool_attrs[k], p->bool_vals[k]);
    kput(c, "}%d(", p->list_n);
    for (int k = 0; k < p->nin; k++) {
      int64_t in = p->in[k]; int li = leaf_index(c, in);
      if (li >= 0) kput(c, "L%d,", li); else kput(c, "N%d,", node_index(c, in));
    }
    kput(c, ")%s ", c->want[i] ? "o" : "");
  }
  return 1;
}
static int closure_of(int64_t h, int grad_mode, Closure* c) { double t = now_ms(); int r = closure_of_(h, grad_mode, c); prof_add(P_CLOSURE, t); return r; }


/* ---- compiling a closure, once per key ---------------------------------------- */
static uint64_t fnv(const char* k) { uint64_t h = 1469598103934665603ULL; while (*k) { h ^= (unsigned char) *k++; h *= 1099511628211ULL; } return h; }
static Entry* entry_find(const char* key) {
  uint64_t h = fnv(key);
  for (int i = 0; i < nentries; i++) if (entries[i]->hash == h && 0 == strcmp(entries[i]->key, key)) return entries[i];
  return 0;
}
static void entry_drop(Entry* e) {
  if (e->graph) TF_DeleteGraph(e->graph);
  free(e->key); free(e->ph); free(e->out); free(e->in_leaf); free(e->out_node); free(e);
}
/* the graph of a closure: a placeholder or a Const per leaf, an operation per node */
static Entry* entry_compile_(Closure* c) {
  if (nentries >= TF_MAXENTRY) { fail("too many compiled closures"); return 0; }
  Entry* e = (Entry*) calloc(1, sizeof(Entry));
  e->key = strdup(c->key); e->hash = fnv(c->key); e->nleaves = c->nleaves; e->nnodes = c->nnodes;
  e->graph = TF_NewGraph();
  e->ph = (TF_Output*) calloc((size_t)(c->nleaves > 0 ? c->nleaves : 1), sizeof(TF_Output));
  e->out = (TF_Output*) calloc((size_t)(c->nnodes > 0 ? c->nnodes : 1), sizeof(TF_Output));
  e->in_leaf = (int*) calloc((size_t)(c->nleaves > 0 ? c->nleaves : 1), sizeof(int));
  e->out_node = (int*) calloc((size_t)(c->nnodes > 0 ? c->nnodes : 1), sizeof(int));
  for (int i = 0; i < TF_MAXPARAM; i++) e->grad_at[i] = -1;
  char name[48];
  for (int j = 0; j < c->nleaves; j++) {
    TfSlot* s = &slots[c->leaves[j]];
    snprintf(name, sizeof name, "l%d_%d", opcount++, j);
    TF_OperationDescription* d;
    if (s->ckey && s->val) {
      d = TF_NewOperation(e->graph, "Const", name);
      TF_SetAttrTensor(d, "value", s->val, st); TF_SetAttrType(d, "dtype", TF_TensorType(s->val));
    } else {
      d = TF_NewOperation(e->graph, "Placeholder", name);
      TF_SetAttrType(d, "dtype", s->dtype); TF_SetAttrShape(d, "shape", s->shape, s->nd);
      e->in_leaf[e->nin++] = j;
    }
    TF_Operation* op = TF_FinishOperation(d, st);
    if (bad()) { entry_drop(e); return 0; }
    e->ph[j].oper = op; e->ph[j].index = 0;
  }
  for (int i = 0; i < c->nnodes; i++) {
    OpSpec* p = &slots[c->nodes[i]].spec;
    snprintf(name, sizeof name, "n%d_%d", opcount++, i);
    TF_OperationDescription* d = TF_NewOperation(e->graph, p->op, name);
    for (int k = 0; k < p->ntypes; k++) TF_SetAttrType(d, p->type_attrs[k], p->type_vals[k]);
    for (int k = 0; k < p->nints; k++) TF_SetAttrInt(d, p->int_attrs[k], p->int_vals[k]);
    for (int k = 0; k < p->nbools; k++) TF_SetAttrBool(d, p->bool_attrs[k], p->bool_vals[k]);
    TF_Output ins[TF_MAXIN];
    for (int k = 0; k < p->nin; k++) {
      int li = leaf_index(c, p->in[k]);
      ins[k] = (li >= 0) ? e->ph[li] : e->out[node_index(c, p->in[k])];
    }
    if (p->list_n > 0) { TF_AddInputList(d, ins, p->list_n); for (int k = p->list_n; k < p->nin; k++) TF_AddInput(d, ins[k]); }
    else for (int k = 0; k < p->nin; k++) TF_AddInput(d, ins[k]);
    TF_Operation* op = TF_FinishOperation(d, st);
    if (bad()) { entry_drop(e); return 0; }
    e->out[i].oper = op; e->out[i].index = 0;
    if (c->want[i]) e->out_node[e->nwant++] = i;
  }
  entries[nentries++] = e;
  return e;
}
static Entry* entry_compile(Closure* c) { double t = now_ms(); Entry* r = entry_compile_(c); prof_add(P_COMPILE, t); return r; }

static Entry* entry_for(Closure* c, int* hit) {
  Entry* e = entry_find(c->key);
  if (e) { *hit = 1; return e; }
  *hit = 0; return entry_compile(c);
}
/* the graph as a function of the eager runtime, made once, after any gradients are in */
static int entry_function_(Entry* e) {
  if (e->fn) return 1;
  int nout = e->nwant;
  for (int i = 0; i < e->ngrads; i++) e->grad_at[i] = e->grads[i].oper ? nout++ : -1;
  TF_Output* ins = (TF_Output*) calloc((size_t)(e->nin > 0 ? e->nin : 1), sizeof(TF_Output));
  TF_Output* outs = (TF_Output*) calloc((size_t)(nout > 0 ? nout : 1), sizeof(TF_Output));
  for (int k = 0; k < e->nin; k++) ins[k] = e->ph[e->in_leaf[k]];
  for (int k = 0; k < e->nwant; k++) outs[k] = e->out[e->out_node[k]];
  for (int i = 0; i < e->ngrads; i++) if (e->grad_at[i] >= 0) outs[e->grad_at[i]] = e->grads[i];
  snprintf(e->fname, sizeof e->fname, "Coco_%d", fncount++);
  e->fn = TF_GraphToFunction(e->graph, e->fname, 0, -1, 0, e->nin, ins, nout, outs, 0, 0, "a cocolog closure", st);
  free(ins); free(outs);
  if (bad()) { e->fn = 0; return 0; }
  TFE_ContextAddFunction(ctx, e->fn, st);
  if (bad()) return 0;
  e->noutputs = nout;
  return 1;
}
static int entry_function(Entry* e) { double t = now_ms(); int r = entry_function_(e); prof_add(P_COMPILE, t); return r; }

/* one call: the leaves in, the wanted nodes and the gradients out.
 * COCO_TF_TRACE=1 in the environment prints each call to stderr -- its
 * function, arguments, results, gradients and milliseconds -- which is how
 * a step is counted in calls, the number that decides what it costs. */
static int execute_(Closure* c, Entry* e, const int64_t* ps, int np, int64_t* gs);
static int execute(Closure* c, Entry* e, const int64_t* ps, int np, int64_t* gs) {
  if (!tf_trace) return execute_(c, e, ps, np, gs);
  double t0 = now_ms();
  int ok = execute_(c, e, ps, np, gs);
  prof_add(P_EXEC, t0);
  fprintf(stderr, "cocolog: tensorflow: call %s: %d nodes, %d in, %d out, %d gradients, %.1f ms%s\n",
          e->fname, e->nnodes, e->nin, e->nwant, np, now_ms() - t0, ok ? "" : " FAILED");
  return ok;
}
static int execute_(Closure* c, Entry* e, const int64_t* ps, int np, int64_t* gs) {
  if (!entry_function(e)) return 0;
  TFE_TensorHandle** ret = 0;
  if (e->noutputs > 0) {
    TFE_Op* op = TFE_NewOp(ctx, e->fname, st); if (bad()) return 0;
    pin(op);
    static int xla = -1; if (xla < 0) xla = getenv("COCO_TF_XLA") ? atoi(getenv("COCO_TF_XLA")) : 0;
    if (xla > 0 && ++e->calls > xla) { TFE_OpSetAttrBool(op, "_XlaMustCompile", 1); }
    for (int k = 0; k < e->nin; k++) {
      TFE_OpAddInput(op, slots[c->leaves[e->in_leaf[k]]].eh, st);
      if (bad()) { TFE_DeleteOp(op); return 0; }
    }
    ret = (TFE_TensorHandle**) calloc((size_t) e->noutputs, sizeof(TFE_TensorHandle*));
    int nret = e->noutputs;
    TFE_Execute(op, ret, &nret, st); TFE_DeleteOp(op);
    if (bad()) { for (int k = 0; k < nret; k++) if (ret[k]) TFE_DeleteTensorHandle(ret[k]); free(ret); return 0; }
    /* A NODE KEEPS ITS STRUCTURE after it has a value only when a parameter
     * is under it -- a loss read by item may still be asked for its gradient.
     * A node with no parameter under it -- an optimiser's moments, a metric --
     * is just a value now and lets its inputs go, or a chain of moments would
     * hold every step before it alive. A parameter made by a step is a
     * boundary: a value, and nothing behind it. */
    for (int k = 0; k < e->nwant; k++) {
      int64_t h = c->nodes[e->out_node[k]];
      take_handle(&slots[h], ret[k]); ret[k] = 0; stat_exe++;
      if (!slots[h].under_param || slots[h].is_param) drop_structure(h);
    }
  }
  for (int i = 0; i < np; i++) {
    int at = e->grad_at[i]; int64_t h;
    if (at < 0) {    /* the loss never reached it: zeros of its shape */
      int64_t n = 1; for (int d = 0; d < slots[ps[i]].nd; d++) n *= slots[ps[i]].shape[d];
      double* buf = (double*) calloc((size_t)(n > 0 ? n : 1), sizeof(double));
      h = tfb_from_doubles(buf, slots[ps[i]].shape, slots[ps[i]].nd); free(buf);
    } else { h = slot_from_handle(ret[at]); ret[at] = 0; stat_exe++; }
    if (h < 0) { if (ret) { for (int k = 0; k < e->noutputs; k++) if (ret[k]) TFE_DeleteTensorHandle(ret[k]); free(ret); } return 0; }
    gs[i] = h;
  }
  free(ret);
  return 1;
}
/* run the closure of h: it, and every node in it the program names, get their values */
static int run_closure(int64_t h) {
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(h, 0, c)) { free(c); return 0; }
  if (c->nnodes == 0) { free(c); return 1; }
  int hit = 0; Entry* e = entry_for(c, &hit);
  if (!e) { free(c); return 0; }
  int ok = execute(c, e, 0, 0, 0);
  if (ok && hit) stat_rep++;
  free(c);
  return ok;
}
int tfb_force(int64_t h) {
  if (!tfb_exists(h)) return 0;
  if (!slots[h].eh) return run_closure(h);
  return 1;
}

/* ---- reading a value ------------------------------------------------ */
/* values as doubles, the caller frees; shape and nd filled */
double* tfb_values_(int64_t h, int64_t* n, int64_t* shape, int* nd) {
  if (!tfb_exists(h)) { fail("not a tensor"); return 0; }
  if (!tfb_force(h)) return 0;
  TfSlot* s = &slots[h];
  TF_Tensor* t = TFE_TensorHandleResolve(s->eh, st); if (bad()) return 0;
  int64_t cnt = TF_TensorElementCount(t);
  double* buf = (double*) malloc((size_t)(cnt > 0 ? cnt : 1) * sizeof(double));
  TF_DataType dt = TF_TensorType(t);
  if (dt == TF_FLOAT) { float* p = (float*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_DOUBLE) { double* p = (double*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_INT32) { int32_t* p = (int32_t*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_INT64) { int64_t* p = (int64_t*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = (double) p[i]; }
  else { free(buf); TF_DeleteTensor(t); fail("unsupported dtype"); return 0; }
  *nd = TF_NumDims(t); for (int i = 0; i < *nd && i < TF_MAXDIM; i++) shape[i] = TF_Dim(t, i);
  *n = cnt;
  TF_DeleteTensor(t);
  return buf;
}
double* tfb_values(int64_t h, int64_t* n, int64_t* shape, int* nd) { double t = now_ms(); double* r = tfb_values_(h, n, shape, nd); prof_add(P_READ, t); return r; }

int tfb_is_int(int64_t h) { return tfb_exists(h) && (slots[h].dtype == TF_INT32 || slots[h].dtype == TF_INT64); }
/* the shape without running anything: known at birth for a value, by rule for
 * a recorded node, or from the compiled graph's inference */
int tfb_shape(int64_t h, int64_t* shape, int* nd) {
  if (!tfb_exists(h)) return 0;
  TfSlot* s = &slots[h];
  if (s->shape_known) { *nd = s->nd; for (int i = 0; i < s->nd; i++) shape[i] = s->shape[i]; return 1; }
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(h, 0, c)) { free(c); return 0; }
  int hit = 0; Entry* e = entry_for(c, &hit);
  if (!e) { free(c); return 0; }
  TF_Output o = e->out[node_index(c, h)];
  free(c);
  int n = TF_GraphGetTensorNumDims(e->graph, o, st);
  if (bad() || n < 0) { if (!run_closure(h)) return 0; *nd = s->nd; for (int i = 0; i < s->nd; i++) shape[i] = s->shape[i]; return 1; }
  int64_t dims[TF_MAXDIM]; TF_GraphGetTensorShape(e->graph, o, dims, n, st); if (bad()) return 0;
  for (int i = 0; i < n; i++) if (dims[i] < 0) { if (!run_closure(h)) return 0; *nd = s->nd; for (int j = 0; j < s->nd; j++) shape[j] = s->shape[j]; return 1; }
  *nd = n; for (int i = 0; i < n; i++) shape[i] = dims[i];
  s->nd = n; for (int i = 0; i < n; i++) s->shape[i] = dims[i]; s->shape_known = 1;
  return 1;
}

/* ---- building an operation, in either mode -------------------------- */
static void spec_init(OpSpec* p, const char* op) { memset(p, 0, sizeof *p); p->op = op; }
static void spec_in(OpSpec* p, int64_t h) { if (p->nin < TF_MAXIN) p->in[p->nin++] = h; }
static void spec_type(OpSpec* p, const char* a, TF_DataType t) { if (p->ntypes < 4) { p->type_attrs[p->ntypes] = a; p->type_vals[p->ntypes] = t; p->ntypes++; } }
static void spec_int(OpSpec* p, const char* a, int64_t v) { if (p->nints < 2) { p->int_attrs[p->nints] = a; p->int_vals[p->nints] = v; p->nints++; } }
static void spec_bool(OpSpec* p, const char* a, int v) { if (p->nbools < 2) { p->bool_attrs[p->nbools] = a; p->bool_vals[p->nbools] = (unsigned char) v; p->nbools++; } }

/* THE SHAPE OF A RECORDED NODE, by rule, so that recording compiles nothing:
 * answers 1 with the shape, 0 when no rule applies (the compiled graph is
 * asked instead), and 0 with a '!'-prefixed error when the shapes cannot go
 * together -- which is a refusal at the goal, as eager refuses it. */
static int leaf_shape(int64_t h, int64_t* sh, int* nd) { if (!tfb_shape(h, sh, nd)) return 0; return 1; }
static int bcast(const int64_t* a, int na, const int64_t* b, int nb, int64_t* out, int* no) {
  int n = na > nb ? na : nb;
  for (int i = 0; i < n; i++) {
    int64_t da = (i < n - na) ? 1 : a[i - (n - na)], db = (i < n - nb) ? 1 : b[i - (n - nb)];
    if (da != db && da != 1 && db != 1) return 0;
    out[i] = da > db ? da : db;
  }
  *no = n; return 1;
}
static int shape_rule(OpSpec* p, int64_t* sh, int* nd) {
  const char* op = p->op;
  int64_t a[TF_MAXDIM], b[TF_MAXDIM]; int na = 0, nb = 0;
  if (p->nin >= 1 && !leaf_shape(p->in[0], a, &na)) return 0;
  if (!strcmp(op, "Neg") || !strcmp(op, "Abs") || !strcmp(op, "Exp") || !strcmp(op, "Log") || !strcmp(op, "Sqrt") ||
      !strcmp(op, "Relu") || !strcmp(op, "Sigmoid") || !strcmp(op, "Tanh") || !strcmp(op, "Cast")) { *nd = na; for (int i = 0; i < na; i++) sh[i] = a[i]; return 1; }
  if (!strcmp(op, "AddV2") || !strcmp(op, "Sub") || !strcmp(op, "Mul") || !strcmp(op, "RealDiv") || !strcmp(op, "Pow") || !strcmp(op, "Maximum")) {
    if (!leaf_shape(p->in[1], b, &nb)) return 0;
    if (!bcast(a, na, b, nb, sh, nd)) { snprintf(errbuf, sizeof errbuf, "!shapes do not broadcast"); return 0; }
    return 1;
  }
  if (!strcmp(op, "MatMul")) {
    if (!leaf_shape(p->in[1], b, &nb)) return 0;
    if (na != 2 || nb != 2) { snprintf(errbuf, sizeof errbuf, "!matmul wants two matrices"); return 0; }
    if (a[1] != b[0]) { snprintf(errbuf, sizeof errbuf, "!matmul: %lld columns against %lld rows", (long long) a[1], (long long) b[0]); return 0; }
    *nd = 2; sh[0] = a[0]; sh[1] = b[1]; return 1;
  }
  if (!strcmp(op, "Transpose")) { if (na != 2) return 0; *nd = 2; sh[0] = a[1]; sh[1] = a[0]; return 1; }
  if (!strcmp(op, "Sum") || !strcmp(op, "Mean") || !strcmp(op, "Max") || !strcmp(op, "Min")) {
    TfSlot* ax = &slots[p->in[1]]; if (!ax->val) return 0;
    int64_t nax = TF_TensorElementCount(ax->val); int32_t* axes = (int32_t*) TF_TensorData(ax->val);
    int keep = 0; for (int k = 0; k < p->nbools; k++) if (!strcmp(p->bool_attrs[k], "keep_dims")) keep = p->bool_vals[k];
    int n = 0;
    for (int i = 0; i < na; i++) {
      int reduced = 0; for (int64_t k = 0; k < nax; k++) if (axes[k] == i || axes[k] + na == i) reduced = 1;
      if (!reduced) sh[n++] = a[i]; else if (keep) sh[n++] = 1;
    }
    *nd = n; return 1;
  }
  if (!strcmp(op, "ArgMax")) {
    TfSlot* d = &slots[p->in[1]]; if (!d->val) return 0;
    int32_t dim = *(int32_t*) TF_TensorData(d->val); if (dim < 0) dim += na;
    int n = 0; for (int i = 0; i < na; i++) if (i != dim) sh[n++] = a[i];
    *nd = n; return 1;
  }
  if (!strcmp(op, "Reshape")) {
    TfSlot* sv = &slots[p->in[1]]; if (!sv->val) return 0;
    int64_t n = TF_TensorElementCount(sv->val); int32_t* v = (int32_t*) TF_TensorData(sv->val);
    int64_t total = 1; for (int i = 0; i < na; i++) total *= a[i];
    int64_t known = 1; int wild = -1;
    for (int64_t i = 0; i < n; i++) { if (v[i] == -1) wild = (int) i; else known *= v[i]; }
    for (int64_t i = 0; i < n; i++) sh[i] = v[i];
    if (wild >= 0) { if (known == 0 || total % known) { snprintf(errbuf, sizeof errbuf, "!reshape: the sizes do not divide"); return 0; } sh[wild] = total / known; }
    else if (known != total) { snprintf(errbuf, sizeof errbuf, "!reshape: %lld values into %lld", (long long) total, (long long) known); return 0; }
    *nd = (int) n; return 1;
  }
  if (!strcmp(op, "ConcatV2")) {
    TfSlot* ax = &slots[p->in[p->nin - 1]]; if (!ax->val) return 0;
    int32_t dim = *(int32_t*) TF_TensorData(ax->val); if (dim < 0) dim += na;
    *nd = na; for (int i = 0; i < na; i++) sh[i] = a[i];
    for (int k = 1; k < p->list_n; k++) {
      if (!leaf_shape(p->in[k], b, &nb)) return 0;
      if (nb != na) { snprintf(errbuf, sizeof errbuf, "!cat: ranks differ"); return 0; }
      for (int i = 0; i < na; i++) if (i != dim && a[i] != b[i]) { snprintf(errbuf, sizeof errbuf, "!cat: shapes differ off the axis"); return 0; }
      sh[dim] += b[dim];
    }
    return 1;
  }
  if (!strcmp(op, "GatherV2")) {
    if (!leaf_shape(p->in[1], b, &nb)) return 0;
    int n = 0; for (int i = 0; i < nb; i++) sh[n++] = b[i]; for (int i = 1; i < na; i++) sh[n++] = a[i];
    *nd = n; return 1;
  }
  if (!strcmp(op, "Slice")) {
    TfSlot* bg = &slots[p->in[1]]; TfSlot* sz = &slots[p->in[2]]; if (!bg->val || !sz->val) return 0;
    int32_t* begin = (int32_t*) TF_TensorData(bg->val); int32_t* size = (int32_t*) TF_TensorData(sz->val);
    for (int i = 0; i < na; i++) {
      int64_t s0 = size[i] < 0 ? a[i] - begin[i] : size[i];
      if (begin[i] < 0 || begin[i] + s0 > a[i]) { snprintf(errbuf, sizeof errbuf, "!slice: out of range"); return 0; }
      sh[i] = s0;
    }
    *nd = na; return 1;
  }
  return 0;
}

/* a producer: under eager, executed now and recorded when a parameter reaches
 * it; under graph, recorded, with its shape by rule -- which is also where a
 * wrong shape is refused, at this goal */
static int64_t run_spec_(OpSpec* p) {
  for (int i = 0; i < p->nin; i++) if (!tfb_exists(p->in[i])) { fail("not a tensor"); return -1; }
  int up = 0;
  for (int i = 0; i < p->nin; i++) { TfSlot* in = &slots[p->in[i]]; if (in->is_param || (in->kind == K_NODE && in->under_param)) up = 1; }
  if (tfb_mode() == 0) {
    /* a recorded tensor from before the switch was moved is run first */
    for (int i = 0; i < p->nin; i++) if (!slots[p->in[i]].eh && !run_closure(p->in[i])) return -1;
    TFE_Op* op = TFE_NewOp(ctx, p->op, st); if (bad()) return -1;
    pin(op);
    for (int i = 0; i < p->ntypes; i++) TFE_OpSetAttrType(op, p->type_attrs[i], p->type_vals[i]);
    for (int i = 0; i < p->nints; i++) TFE_OpSetAttrInt(op, p->int_attrs[i], p->int_vals[i]);
    for (int i = 0; i < p->nbools; i++) TFE_OpSetAttrBool(op, p->bool_attrs[i], p->bool_vals[i]);
    if (p->list_n > 0) {
      TFE_TensorHandle* hs[TF_MAXIN];
      for (int i = 0; i < p->list_n; i++) hs[i] = slots[p->in[i]].eh;
      TFE_OpAddInputList(op, hs, p->list_n, st); if (bad()) { TFE_DeleteOp(op); return -1; }
      for (int i = p->list_n; i < p->nin; i++) { TFE_OpAddInput(op, slots[p->in[i]].eh, st); if (bad()) { TFE_DeleteOp(op); return -1; } }
    } else {
      for (int i = 0; i < p->nin; i++) { TFE_OpAddInput(op, slots[p->in[i]].eh, st); if (bad()) { TFE_DeleteOp(op); return -1; } }
    }
    TFE_TensorHandle* ret = 0; int nret = 1;
    TFE_Execute(op, &ret, &nret, st); TFE_DeleteOp(op);
    if (bad() || nret < 1) return -1;
    int64_t h = slot_from_handle(ret); if (h < 0) return -1;
    if (up) {    /* the tape: what a parameter reaches keeps its recipe */
      TfSlot* s = &slots[h];
      s->kind = K_NODE; s->spec = *p; s->under_param = 1;
      for (int i = 0; i < p->nin; i++) slots[p->in[i]].refs++;
      stat_rec++;
    }
    return h;
  }
  int64_t h = slot_new(); if (h < 0) return -1;
  TfSlot* s = &slots[h];
  s->kind = K_NODE; s->spec = *p; s->under_param = up;
  for (int i = 0; i < p->nin; i++) slots[p->in[i]].refs++;
  s->dtype = TF_FLOAT;
  for (int i = 0; i < p->ntypes; i++) if (0 == strcmp(p->type_attrs[i], "output_type") || 0 == strcmp(p->type_attrs[i], "DstT")) s->dtype = p->type_vals[i];
  if (0 == strcmp(p->op, "Reshape") || 0 == strcmp(p->op, "GatherV2") || 0 == strcmp(p->op, "Slice")) s->dtype = slots[p->in[0]].dtype;
  stat_rec++;
  int64_t shape[TF_MAXDIM]; int nd = 0;
  if (shape_rule(p, shape, &nd)) { s->nd = nd; for (int i = 0; i < nd; i++) s->shape[i] = shape[i]; s->shape_known = 1; return h; }
  if (errbuf[0] == '!') { /* a rule REFUSED it: a shape that cannot be */
    memmove(errbuf, errbuf + 1, strlen(errbuf));
    for (int i = 0; i < p->nin; i++) unref(p->in[i]);
    slots[h].kind = K_FREE; stat_rec--;
    return -1;
  }
  if (!tfb_shape(h, shape, &nd)) { /* the op was refused: undo the record */
    for (int i = 0; i < p->nin; i++) unref(p->in[i]);
    slots[h].kind = K_FREE; stat_rec--;
    return -1;
  }
  return h;
}
static int64_t run_spec(OpSpec* p) { double t = now_ms(); int64_t r = run_spec_(p); prof_add(P_SPEC, t); return r; }


/* ---- the producers ---------------------------------------------------- */
int64_t tfb_unary(const char* nm, int64_t a) {
  OpSpec p;
  if (!strcmp(nm, "transpose")) {
    int64_t perm[2] = { 1, 0 }; int64_t pv = ivec(perm, 2); if (pv < 0) return -1;
    spec_init(&p, "Transpose"); spec_in(&p, a); spec_in(&p, pv); spec_type(&p, "T", TF_FLOAT); spec_type(&p, "Tperm", TF_INT32);
    return with_free(run_spec(&p), pv);
  }
  const char* op = !strcmp(nm, "neg") ? "Neg" : !strcmp(nm, "abs") ? "Abs" : !strcmp(nm, "exp") ? "Exp" : !strcmp(nm, "log") ? "Log"
                 : !strcmp(nm, "sqrt") ? "Sqrt" : !strcmp(nm, "relu") ? "Relu" : !strcmp(nm, "sigmoid") ? "Sigmoid" : !strcmp(nm, "tanh") ? "Tanh" : 0;
  if (!op) { fail("unknown unary"); return -1; }
  spec_init(&p, op); spec_in(&p, a); spec_type(&p, "T", TF_FLOAT);
  return run_spec(&p);
}
static const char* binop(const char* nm) {
  return !strcmp(nm, "add") ? "AddV2" : !strcmp(nm, "sub") ? "Sub" : !strcmp(nm, "mul") ? "Mul" : !strcmp(nm, "div") ? "RealDiv"
       : !strcmp(nm, "pow") ? "Pow" : !strcmp(nm, "matmul") ? "MatMul" : 0;
}
int64_t tfb_binary(const char* nm, int64_t a, int64_t b) {
  const char* op = binop(nm); if (!op) { fail("unknown binary"); return -1; }
  OpSpec p; spec_init(&p, op); spec_in(&p, a); spec_in(&p, b); spec_type(&p, "T", TF_FLOAT);
  if (!strcmp(op, "MatMul")) { spec_bool(&p, "transpose_a", 0); spec_bool(&p, "transpose_b", 0); }
  return run_spec(&p);
}
int64_t tfb_scalar(const char* nm, int64_t a, double v) {
  const char* op = binop(nm); if (!op || !strcmp(op, "MatMul")) { fail("unknown scalar op"); return -1; }
  int64_t s = fscalar(v); if (s < 0) return -1;
  OpSpec p; spec_init(&p, op); spec_in(&p, a); spec_in(&p, s); spec_type(&p, "T", TF_FLOAT);
  return with_free(run_spec(&p), s);
}
static int64_t reduce_all(const char* op, int64_t a, int keep) {
  int64_t shape[TF_MAXDIM]; int nd = 0;
  if (!tfb_shape(a, shape, &nd)) return -1;
  int64_t axes[TF_MAXDIM]; for (int i = 0; i < nd; i++) axes[i] = i;
  int64_t ax = ivec(axes, nd > 0 ? nd : 0); if (ax < 0) return -1;
  OpSpec p; spec_init(&p, op); spec_in(&p, a); spec_in(&p, ax); spec_type(&p, "T", TF_FLOAT); spec_type(&p, "Tidx", TF_INT32); spec_bool(&p, "keep_dims", keep);
  return with_free(run_spec(&p), ax);
}
static int64_t reduce_axis(const char* op, int64_t a, int64_t axis, int keep) {
  int64_t ax = ivec(&axis, 1); if (ax < 0) return -1;
  OpSpec p; spec_init(&p, op); spec_in(&p, a); spec_in(&p, ax); spec_type(&p, "T", TF_FLOAT); spec_type(&p, "Tidx", TF_INT32); spec_bool(&p, "keep_dims", keep);
  return with_free(run_spec(&p), ax);
}
int64_t tfb_agg(const char* nm, int64_t a) {
  if (!strcmp(nm, "sum")) return reduce_all("Sum", a, 0);
  if (!strcmp(nm, "mean")) return reduce_all("Mean", a, 0);
  if (!strcmp(nm, "max")) return reduce_all("Max", a, 0);
  if (!strcmp(nm, "min")) return reduce_all("Min", a, 0);
  if (!strcmp(nm, "std")) {
    /* the sample standard deviation, as torch's: sqrt(sum((x - mean)^2) / (n - 1)) */
    int64_t shape[TF_MAXDIM]; int nd = 0; if (!tfb_shape(a, shape, &nd)) return -1;
    int64_t n = 1; for (int i = 0; i < nd; i++) n *= shape[i];
    int64_t mu = reduce_all("Mean", a, 0); if (mu < 0) return -1;
    int64_t d = tfb_binary("sub", a, mu); tfb_free(mu); if (d < 0) return -1;
    int64_t sq = tfb_binary("mul", d, d); tfb_free(d); if (sq < 0) return -1;
    int64_t ss = reduce_all("Sum", sq, 0); tfb_free(sq); if (ss < 0) return -1;
    int64_t v = tfb_scalar("div", ss, (double)(n > 1 ? n - 1 : 1)); tfb_free(ss); if (v < 0) return -1;
    int64_t r = tfb_unary("sqrt", v); tfb_free(v); return r;
  }
  fail("unknown aggregation"); return -1;
}
int64_t tfb_argmax(int64_t a, int64_t dim) {
  int64_t d = iscalar(dim); if (d < 0) return -1;
  OpSpec p; spec_init(&p, "ArgMax"); spec_in(&p, a); spec_in(&p, d); spec_type(&p, "T", TF_FLOAT); spec_type(&p, "Tidx", TF_INT32); spec_type(&p, "output_type", TF_INT64);
  return with_free(run_spec(&p), d);
}
int64_t tfb_reshape(int64_t a, const int64_t* shape, int nd) {
  int64_t sv = ivec(shape, nd); if (sv < 0) return -1;
  OpSpec p; spec_init(&p, "Reshape"); spec_in(&p, a); spec_in(&p, sv); spec_type(&p, "T", tfb_is_int(a) ? slots[a].dtype : TF_FLOAT); spec_type(&p, "Tshape", TF_INT32);
  return with_free(run_spec(&p), sv);
}
int64_t tfb_cat(const int64_t* hs, int n, int64_t dim) {
  if (n < 1 || n > TF_MAXIN - 1) { fail("cat: 1 to 7 tensors"); return -1; }
  int64_t ax = iscalar(dim); if (ax < 0) return -1;
  OpSpec p; spec_init(&p, "ConcatV2"); for (int i = 0; i < n; i++) spec_in(&p, hs[i]); spec_in(&p, ax); p.list_n = n;
  spec_type(&p, "T", TF_FLOAT); spec_type(&p, "Tidx", TF_INT32); spec_int(&p, "N", n);
  return with_free(run_spec(&p), ax);
}
/* rows by index. An index tensor is a float tensor of whole values, as it is
 * on torch (tensor_from_list, randperm, arange); an argmax is int64. Floats
 * are cast to int32 here, where they are read -- torch's gather does the same */
int64_t tfb_gather(int64_t a, int64_t idx) {
  int64_t ix = idx, tmp = -1;
  if (!tfb_is_int(idx)) {
    OpSpec c; spec_init(&c, "Cast"); spec_in(&c, idx); spec_type(&c, "SrcT", TF_FLOAT); spec_type(&c, "DstT", TF_INT32); spec_bool(&c, "Truncate", 0);
    tmp = run_spec(&c); if (tmp < 0) return -1; ix = tmp;
  }
  int64_t ax = iscalar(0); if (ax < 0) { if (tmp > 0) tfb_free(tmp); return -1; }
  OpSpec p; spec_init(&p, "GatherV2"); spec_in(&p, a); spec_in(&p, ix); spec_in(&p, ax);
  spec_type(&p, "Tparams", tfb_is_int(a) ? slots[a].dtype : TF_FLOAT); spec_type(&p, "Tindices", slots[ix].dtype); spec_type(&p, "Taxis", TF_INT32);
  spec_int(&p, "batch_dims", 0);
  int64_t r = run_spec(&p); tfb_free(ax); if (tmp > 0) tfb_free(tmp); return r;
}
int64_t tfb_slice(int64_t a, int axis, int64_t from, int64_t to) {
  int64_t shape[TF_MAXDIM]; int nd = 0; if (!tfb_shape(a, shape, &nd)) return -1;
  if (axis >= nd) { fail("slice: no such axis"); return -1; }
  int64_t begin[TF_MAXDIM], size[TF_MAXDIM];
  for (int i = 0; i < nd; i++) { begin[i] = 0; size[i] = -1; }
  begin[axis] = from; size[axis] = to - from;
  int64_t b = ivec(begin, nd), s = ivec(size, nd); if (b < 0 || s < 0) return -1;
  OpSpec p; spec_init(&p, "Slice"); spec_in(&p, a); spec_in(&p, b); spec_in(&p, s); spec_type(&p, "T", tfb_is_int(a) ? slots[a].dtype : TF_FLOAT); spec_type(&p, "Index", TF_INT32);
  int64_t r = run_spec(&p); tfb_free(b); tfb_free(s); return r;
}
/* per column, the statistics of the first ntrain rows: the SAMPLE standard
 * deviation, as torch's, floored at 1e-7 */
int64_t tfb_standardise(int64_t a, int64_t ntrain) {
  int64_t head = tfb_slice(a, 0, 0, ntrain); if (head < 0) return -1;
  int64_t mu = reduce_axis("Mean", head, 0, 1); if (mu < 0) return -1;
  int64_t d = tfb_binary("sub", head, mu); tfb_free(head); if (d < 0) return -1;
  int64_t sq = tfb_binary("mul", d, d); tfb_free(d); if (sq < 0) return -1;
  int64_t ss = reduce_axis("Sum", sq, 0, 1); tfb_free(sq); if (ss < 0) return -1;
  int64_t var = tfb_scalar("div", ss, (double)(ntrain > 1 ? ntrain - 1 : 1)); tfb_free(ss); if (var < 0) return -1;
  int64_t sd0 = tfb_unary("sqrt", var); tfb_free(var); if (sd0 < 0) return -1;
  int64_t floor_ = fscalar(1e-7); if (floor_ < 0) return -1;
  OpSpec mx; spec_init(&mx, "Maximum"); spec_in(&mx, sd0); spec_in(&mx, floor_); spec_type(&mx, "T", TF_FLOAT);
  int64_t sd = run_spec(&mx); tfb_free(sd0); tfb_free(floor_); if (sd < 0) return -1;
  int64_t c = tfb_binary("sub", a, mu); tfb_free(mu); if (c < 0) return -1;
  int64_t r = tfb_binary("div", c, sd); tfb_free(c); tfb_free(sd); return r;
}
int64_t tfb_fill(const int64_t* shape, int nd, double v) {
  int64_t n = 1; for (int i = 0; i < nd; i++) n *= shape[i];
  double* buf = (double*) malloc((size_t)(n > 0 ? n : 1) * sizeof(double));
  for (int64_t i = 0; i < n; i++) buf[i] = v;
  int64_t h = tfb_from_doubles(buf, shape, nd); free(buf); return h;
}
/* random leaves draw NOW through the eager context, and are values. The
 * STATELESS ops, seeded by (seed, draw number): a stateful random op keeps a
 * generator per seed pair in the eager runtime and continues its stream, so
 * a program re-seeded and run again in one process would not start where it
 * started -- as tutorial 31 does, eager then graph, and expects IDENTICAL */
int64_t tfb_random(const int64_t* shape, int nd, int normal) {
  int64_t sh[1] = { nd }; TF_Tensor* t = tensor_i32(shape, sh, 1);
  TFE_TensorHandle* shp = TFE_NewTensorHandle(t, st); TF_DeleteTensor(t); if (bad()) return -1;
  int64_t sv[2] = { seed_base, ++seed_next }; int64_t s2[1] = { 2 }; TF_Tensor* ts = tensor_i32(sv, s2, 1);
  TFE_TensorHandle* sd = TFE_NewTensorHandle(ts, st); TF_DeleteTensor(ts); if (bad()) { TFE_DeleteTensorHandle(shp); return -1; }
  TFE_Op* op = TFE_NewOp(ctx, normal ? "StatelessRandomNormal" : "StatelessRandomUniform", st);
  if (bad()) { TFE_DeleteTensorHandle(shp); TFE_DeleteTensorHandle(sd); return -1; }
  pin(op);
  TFE_OpSetAttrType(op, "dtype", TF_FLOAT); TFE_OpSetAttrType(op, "T", TF_INT32); TFE_OpSetAttrType(op, "Tseed", TF_INT32);
  TFE_OpAddInput(op, shp, st); TFE_OpAddInput(op, sd, st);
  TFE_TensorHandle* ret = 0; int nret = 1; TFE_Execute(op, &ret, &nret, st); TFE_DeleteOp(op);
  TFE_DeleteTensorHandle(shp); TFE_DeleteTensorHandle(sd);
  if (bad()) return -1;
  return slot_from_handle(placed(ret));
}
int64_t tfb_eye(int64_t n) {
  double* buf = (double*) calloc((size_t)(n * n), sizeof(double));
  for (int64_t i = 0; i < n; i++) buf[i * n + i] = 1.0;
  int64_t shape[2] = { n, n }; int64_t h = tfb_from_doubles(buf, shape, 2); free(buf); return h;
}
int64_t tfb_arange(int64_t n) {
  double* buf = (double*) malloc((size_t)(n > 0 ? n : 1) * sizeof(double));
  for (int64_t i = 0; i < n; i++) buf[i] = (double) i;
  int64_t shape[1] = { n }; int64_t h = tfb_from_doubles(buf, shape, 1); free(buf); return h;
}
/* a permutation as FLOATS, as torch's is: an index tensor is a float tensor
 * whose values are whole, and index_rows casts it where it reads */
int64_t tfb_randperm(int64_t n) {
  double* v = (double*) malloc((size_t)(n > 0 ? n : 1) * sizeof(double));
  for (int64_t i = 0; i < n; i++) v[i] = (double) i;
  uint64_t x = (uint64_t) seed_base * 6364136223846793005ULL + (uint64_t)(++seed_next) * 1442695040888963407ULL;
  for (int64_t i = n - 1; i > 0; i--) { x = x * 6364136223846793005ULL + 1442695040888963407ULL; int64_t j = (int64_t)((x >> 33) % (uint64_t)(i + 1)); double t = v[i]; v[i] = v[j]; v[j] = t; }
  int64_t shape[1] = { n }; int64_t h = tfb_from_doubles(v, shape, 1); free(v); return h;
}
/* a parameter: a leaf sharing a's value, with gradient wanted -- a new name
 * for the same device tensor, and no history behind it */
int64_t tfb_parameter(int64_t a) {
  if (!tfb_exists(a)) { fail("not a tensor"); return -1; }
  if (!tfb_force(a)) return -1;
  TFE_TensorHandle* eh = TFE_TensorHandleCopySharingTensor(slots[a].eh, st); if (bad()) return -1;
  int64_t h = slot_from_handle(eh); if (h < 0) return -1;
  slots[h].is_param = 1;
  return h;
}
/* a step: W - lr G, made like any node and marked a parameter -- a boundary,
 * not a history: under eager it is a value at once and lets its inputs go;
 * under graph the next loss's one call computes it along with everything
 * else, and it is a plain leaf from then on */
int64_t tfb_step(int64_t w, int64_t g, double lr) {
  int64_t scaled = tfb_scalar("mul", g, lr); if (scaled < 0) return -1;
  int64_t next = tfb_binary("sub", w, scaled); tfb_free(scaled); if (next < 0) return -1;
  slots[next].is_param = 1;
  if (slots[next].eh) drop_structure(next);
  return next;
}
/* the gradients of loss for ps: the closure of loss down to the parameters,
 * keyed with their places in it, TF_AddGradients once per key, then a call --
 * one call, which under graph also computes the loss and every step and
 * moment it rests on */
int tfb_grad(int64_t loss, const int64_t* ps, int n, int64_t* gs) {
  if (!tfb_exists(loss)) { fail("the loss is not a tensor"); return 0; }
  if (n > TF_MAXPARAM) { fail("at most 64 parameters"); return 0; }
  for (int i = 0; i < n; i++) if (!tfb_exists(ps[i]) || !slots[ps[i]].is_param) { fail("a parameter must be a leaf: tensor_parameter/2 or tensor_step/4 makes one"); return 0; }
  TfSlot* L = &slots[loss];
  if (L->kind != K_NODE || !L->under_param) {    /* no parameter under it: zeros for each */
    for (int i = 0; i < n; i++) {
      int64_t shape[TF_MAXDIM]; int nd = 0; if (!tfb_shape(ps[i], shape, &nd)) return 0;
      gs[i] = tfb_fill(shape, nd, 0.0); if (gs[i] < 0) return 0;
    }
    return 1;
  }
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(loss, 1, c)) { free(c); return 0; }
  int li[TF_MAXPARAM], ni[TF_MAXPARAM];
  kput(c, "|G:");
  for (int i = 0; i < n; i++) {
    li[i] = leaf_index(c, ps[i]); ni[i] = li[i] >= 0 ? -1 : node_index(c, ps[i]);
    if (li[i] >= 0) kput(c, "L%d,", li[i]); else if (ni[i] >= 0) kput(c, "N%d,", ni[i]); else kput(c, "-,");
  }
  int hit = 0; Entry* e = entry_find(c->key);
  if (e) hit = 1;
  else {
    e = entry_compile(c); if (!e) { free(c); return 0; }
    TF_Output y = e->out[node_index(c, loss)];
    TF_Output xs[TF_MAXPARAM]; int nx = 0; int which[TF_MAXPARAM];
    for (int i = 0; i < n; i++) {
      if (li[i] >= 0) { xs[nx] = e->ph[li[i]]; which[nx] = i; nx++; }
      else if (ni[i] >= 0) { xs[nx] = e->out[ni[i]]; which[nx] = i; nx++; }
    }
    for (int i = 0; i < TF_MAXPARAM; i++) { e->grads[i].oper = 0; e->grads[i].index = 0; }
    if (nx > 0) {
      TF_Output dys[TF_MAXPARAM];
      TF_AddGradients(e->graph, &y, 1, xs, nx, 0, st, dys);
      if (TF_GetCode(st) == TF_OK) { for (int k = 0; k < nx; k++) e->grads[which[k]] = dys[k]; }
      else {    /* one at a time: a parameter the loss never reaches would fail the lot */
        TF_SetStatus(st, TF_OK, "");
        for (int k = 0; k < nx; k++) {
          TF_Output dy; dy.oper = 0; dy.index = 0;
          TF_AddGradients(e->graph, &y, 1, &xs[k], 1, 0, st, &dy);
          if (TF_GetCode(st) == TF_OK) e->grads[which[k]] = dy;
          TF_SetStatus(st, TF_OK, "");
        }
      }
    }
    e->ngrads = n;
  }
  int ok = execute(c, e, ps, n, gs);
  if (ok && hit) stat_rep++;
  free(c);
  return ok;
}
void tfb_stats(long long* rec, long long* exe, long long* rep, long long* pend) {
  long long p = 0; for (int i = 1; i < TF_SLOTS; i++) if (slots[i].kind == K_NODE && !slots[i].eh && !slots[i].released) p++;
  *rec = stat_rec; *exe = stat_exe; *rep = stat_rep; *pend = p;
}
/* a CSV of numbers, rows of comma or space separated values */
int64_t tfb_load_csv(const char* path) {
  FILE* f = fopen(path, "r"); if (!f) { fail("cannot open"); return -1; }
  double* buf = 0; size_t cap = 0, n = 0; int64_t rows = 0, cols = 0; char line[8192];
  while (fgets(line, sizeof line, f)) {
    int64_t c = 0; char* p = line;
    while (*p) {
      while (*p == ' ' || *p == ',' || *p == '\t' || *p == ';') p++;
      if (*p == '\n' || *p == '\r' || !*p) break;
      char* end; double v = strtod(p, &end); if (end == p) break;
      if (n == cap) { cap = cap ? cap * 2 : 1024; buf = (double*) realloc(buf, cap * sizeof(double)); }
      buf[n++] = v; c++; p = end;
    }
    if (c > 0) { if (cols == 0) cols = c; if (c != cols) { fclose(f); free(buf); fail("ragged rows"); return -1; } rows++; }
  }
  fclose(f);
  if (rows == 0) { free(buf); fail("empty"); return -1; }
  int64_t shape[2] = { rows, cols }; int64_t h = tfb_from_doubles(buf, shape, 2); free(buf); return h;
}

/* ---- attaching to the torch module, which owns the switch and the predicates ---- */
struct coco_engine;
int tfb_attach(int (*fn)(struct coco_engine*, const char*, uint32_t, size_t, int*)) {
  Dl_info info;
  if (!dladdr((void*) &tfb_attach, &info) || !info.dli_fname) { fail("dladdr: cannot find this module's own path"); return 0; }
  char path[4096]; snprintf(path, sizeof path, "%s", info.dli_fname);
  char* slash = strrchr(path, '/');
  if (slash) snprintf(slash + 1, sizeof path - (size_t)(slash + 1 - path), "torch.so"); else snprintf(path, sizeof path, "torch.so");
  void* h = dlopen(path, RTLD_NOW | RTLD_NOLOAD);
  if (!h) h = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
  if (!h) { snprintf(errbuf, sizeof errbuf, "no torch.so beside this module (%s): %s", path, dlerror()); return 0; }
  int (*set)(const char*, void*) = (int (*)(const char*, void*)) dlsym(h, "coco_tensor_backend_set");
  if (!set) { fail("torch.so has no coco_tensor_backend_set: rebuild library(torch)"); return 0; }
  if (!tfb_init(h)) return 0;
  return set("tensorflow", (void*) fn);
}
