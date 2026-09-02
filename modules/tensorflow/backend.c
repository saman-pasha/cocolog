#define _GNU_SOURCE 1
/* backend.c -- the tensor_* surface over TensorFlow's C API.
 *
 * THE BACK END of library(tensorflow): TensorFlow's C library, wrapped once,
 * in C, as the handful of operations the predicates in coco-tensorflow.cicili
 * ask for. It has two modes, read from the torch module's switch through
 * coco_tensor_graph_mode() -- tensor_execution(tensorflow, eager | graph):
 *
 *   eager  every producer is a TFE_Execute, now, and a handle holds a
 *          TFE_TensorHandle. Forward only: TensorFlow's eager C API has no
 *          tape, so tensor_grad under eager is refused, and says so.
 *   graph  every producer ADDS AN OPERATION to one TF_Graph and a handle
 *          holds a TF_Output; a consumer runs the session for what it
 *          needs, with every already-computed ancestor FED as a value, so
 *          nothing is computed twice; tensor_grad is TF_AddGradients over
 *          that graph, TensorFlow's own symbolic differentiation.
 *
 * Handles are integers into a slot table, as the torch module's are. The
 * two backends never share a tensor: the switch is per process and a
 * program keeps to one at a time.
 *
 * Random leaves -- randn, rand, randperm -- draw at once in both modes,
 * through the eager context, and reach the graph as constants: a random
 * OP in a graph would redraw at every run, and a leaf read twice would
 * not be one leaf.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <dlfcn.h>
#include <stdarg.h>
#include "tensorflow/c/c_api.h"
#include "tensorflow/c/eager/c_api.h"

#define TF_SLOTS 4096
#define TF_MAXIN 8
#define TF_MAXDIM 8
#define TF_MAXLEAF 256
#define TF_MAXNODE 2048
#define TF_MAXENTRY 4096

/* THE DESIGN, SECOND DRAFT. The first built the graph one predicate at a
 * time and ran a session per read, and each step made the graph longer:
 * eager execution done badly, and quadratic in the steps. TensorFlow's
 * graph mode is a graph built ONCE and run many times with fresh values
 * fed in -- the arrangement library(torch)'s replay has too. So, under
 * (tensorflow, graph):
 *
 *   a producer RECORDS a node: its operation, attributes and inputs;
 *   a read collects the CLOSURE of what it needs -- the nodes down to the
 *   values they rest on -- and KEYS it by structure: operation by
 *   operation, with every leaf as a placeholder of its shape;
 *   the first time a key is seen its graph is COMPILED, placeholders and
 *   operations, once; every later time the same structure is one session
 *   run with the current values fed to the placeholders;
 *   a gradient is TF_AddGradients over that compiled closure, once per
 *   key, and thereafter a run.
 *
 * The graph grows with the distinct shapes of computation a program has,
 * not with its steps. A node keeps its structure after it has a value, so
 * a loss read by item/2 can still be differentiated by grad/3 after it;
 * and a node holds its inputs alive by reference until it is freed. */

enum { K_FREE = 0, K_EAGER = 1, K_VALUE = 2, K_NODE = 3 };

typedef struct {
  const char* op;
  int64_t in[TF_MAXIN]; int nin;
  int list_n;                  /* >0: the first list_n inputs are one input list (ConcatV2) */
  const char* type_attrs[4]; TF_DataType type_vals[4]; int ntypes;
  const char* int_attrs[2]; int64_t int_vals[2]; int nints;
  const char* bool_attrs[2]; unsigned char bool_vals[2]; int nbools;
} OpSpec;

typedef struct {
  int kind;                    /* K_FREE, K_EAGER, K_VALUE (a leaf holding a tensor), K_NODE (recorded; val once run) */
  TFE_TensorHandle* eh;        /* eager */
  TF_Tensor* val;              /* a value: a leaf's, or a node's once it has run */
  OpSpec spec;                 /* a node's recipe */
  int refs, released;          /* held by nodes that read it; released by the program */
  int ckey;                    /* a leaf made here (an axis, a shape, a scalar): its VALUES go into the key, and it compiles as a Const */
  int is_param;
  int under_param;             /* a node with a parameter somewhere under it: keeps its structure once it has a value */
  int64_t shape[TF_MAXDIM]; int nd; int shape_known;
  TF_DataType dtype;
} TfSlot;

typedef struct {
  int64_t leaves[TF_MAXLEAF]; int nleaves;
  int64_t nodes[TF_MAXNODE]; int nnodes;
  char key[65536]; size_t klen;
} Closure;

typedef struct {
  char* key; uint64_t hash;
  TF_Output ph[TF_MAXLEAF]; int nleaves;
  TF_Output out[TF_MAXNODE]; int nnodes;
  TF_Output grads[64]; int ngrads;
} Entry;

static TfSlot slots[TF_SLOTS];
static Entry* entries[TF_MAXENTRY]; static int nentries = 0;
static TFE_Context* ctx = 0;
static TF_Graph* graph = 0;
static TF_Session* sess = 0;
static TF_Status* st = 0;
static int opcount = 0;
static int64_t seed_base = 1234, seed_next = 0;
static char errbuf[512];
static long long stat_rec = 0, stat_exe = 0, stat_rep = 0;
static int (*graph_mode_fn)(void) = 0;

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
  if (ctx) return 1;
  st = TF_NewStatus();
  /* a ConfigProto with gpu_options.allow_growth = true, serialised: TensorFlow
   * would otherwise take the whole card at start, and share it with nobody */
  static const char grow[] = { 0x32, 0x02, 0x20, 0x01 };
  TFE_ContextOptions* o = TFE_NewContextOptions();
  TFE_ContextOptionsSetConfig(o, grow, sizeof grow, st); TF_SetStatus(st, TF_OK, "");
  ctx = TFE_NewContext(o, st); TFE_DeleteContextOptions(o);
  if (bad()) { ctx = 0; return 0; }
  graph = TF_NewGraph();
  TF_SessionOptions* so = TF_NewSessionOptions();
  TF_SetConfig(so, grow, sizeof grow, st); TF_SetStatus(st, TF_OK, "");
  sess = TF_NewSession(graph, so, st); TF_DeleteSessionOptions(so);
  if (bad()) { sess = 0; return 0; }
  if (torch_so) graph_mode_fn = (int (*)(void)) dlsym(torch_so, "coco_tensor_graph_mode");
  memset(slots, 0, sizeof slots);
  return 1;
}
const char* tfb_version(void) { return TF_Version(); }
void tfb_seed(int64_t s) { seed_base = s; seed_next = 0; }

/* ---- slots ----------------------------------------------------------- */
static int64_t slot_new(void) {
  for (int64_t i = 1; i < TF_SLOTS; i++) if (slots[i].kind == K_FREE) { memset(&slots[i], 0, sizeof(TfSlot)); return i; }
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
/* the program is done naming it; it goes when nothing reads it any more */
int tfb_free(int64_t h) {
  if (!tfb_exists(h)) return 0;
  slots[h].released = 1;
  if (slots[h].refs == 0) really_free(h);
  return 1;
}
static void set_shape_from_tensor(TfSlot* s, TF_Tensor* t) {
  s->nd = TF_NumDims(t); if (s->nd > TF_MAXDIM) s->nd = TF_MAXDIM;
  for (int i = 0; i < s->nd; i++) s->shape[i] = TF_Dim(t, i);
  s->shape_known = 1; s->dtype = TF_TensorType(t);
}

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
/* a slot holding a value: an eager handle, or a leaf of the graph */
static int64_t slot_from_tensor(TF_Tensor* t, int ckey) {
  int64_t h = slot_new(); if (h < 0) { TF_DeleteTensor(t); return -1; }
  TfSlot* s = &slots[h];
  set_shape_from_tensor(s, t);
  if (tfb_mode() == 0) {
    s->kind = K_EAGER;
    s->eh = TFE_NewTensorHandle(t, st);
    TF_DeleteTensor(t);
    if (bad()) { s->kind = K_FREE; return -1; }
  } else {
    s->kind = K_VALUE; s->val = t; s->ckey = ckey;
  }
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
static int64_t fscalar(double v) { TF_Tensor* t = TF_AllocateTensor(TF_FLOAT, 0, 0, 4); *(float*) TF_TensorData(t) = (float) v; return slot_from_tensor(t, 1); }
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
/* grad_mode: do not stop at a node that has a value -- its structure is wanted */
static int visit(int64_t h, Closure* c, unsigned char* seen, int grad_mode) {
  if (!live(h)) { fail("a tensor this one needs has been freed"); return 0; }
  if (seen[h]) return 1;
  seen[h] = 1;
  TfSlot* s = &slots[h];
  if (s->kind == K_EAGER) { fail("an eager tensor in a graph: the switch was moved mid-way"); return 0; }
  int leaf = (s->kind == K_VALUE) || (s->kind == K_NODE && s->val && (!grad_mode || s->is_param));
  if (leaf) { if (c->nleaves >= TF_MAXLEAF) { fail("too many leaves"); return 0; } c->leaves[c->nleaves++] = h; return 1; }
  int up = 0;
  for (int i = 0; i < s->spec.nin; i++) {
    if (!visit(s->spec.in[i], c, seen, grad_mode)) return 0;
    TfSlot* in = &slots[s->spec.in[i]];
    if (in->is_param || (in->kind == K_NODE && in->under_param)) up = 1;
  }
  s->under_param = up;
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
static int closure_of(int64_t h, int grad_mode, Closure* c) {
  c->nleaves = 0; c->nnodes = 0; c->klen = 0; c->key[0] = 0;
  unsigned char* seen = (unsigned char*) calloc(TF_SLOTS, 1);
  int ok = visit(h, c, seen, grad_mode);
  free(seen);
  if (!ok) return 0;
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
    kput(c, ") ");
  }
  return 1;
}

/* ---- compiling a closure, once per key ---------------------------------------- */
static uint64_t fnv(const char* k) { uint64_t h = 1469598103934665603ULL; while (*k) { h ^= (unsigned char) *k++; h *= 1099511628211ULL; } return h; }
static Entry* entry_find(const char* key) {
  uint64_t h = fnv(key);
  for (int i = 0; i < nentries; i++) if (entries[i]->hash == h && 0 == strcmp(entries[i]->key, key)) return entries[i];
  return 0;
}
static Entry* entry_compile(Closure* c) {
  if (nentries >= TF_MAXENTRY) { fail("too many compiled closures"); return 0; }
  Entry* e = (Entry*) calloc(1, sizeof(Entry));
  e->key = strdup(c->key); e->hash = fnv(c->key); e->nleaves = c->nleaves; e->nnodes = c->nnodes;
  char name[48];
  for (int j = 0; j < c->nleaves; j++) {
    TfSlot* s = &slots[c->leaves[j]];
    snprintf(name, sizeof name, "l%d_%d", opcount++, j);
    TF_OperationDescription* d;
    if (s->ckey && s->val) {
      d = TF_NewOperation(graph, "Const", name);
      TF_SetAttrTensor(d, "value", s->val, st); TF_SetAttrType(d, "dtype", TF_TensorType(s->val));
    } else {
      d = TF_NewOperation(graph, "Placeholder", name);
      TF_SetAttrType(d, "dtype", s->dtype); TF_SetAttrShape(d, "shape", s->shape, s->nd);
    }
    TF_Operation* op = TF_FinishOperation(d, st);
    if (bad()) { free(e->key); free(e); return 0; }
    e->ph[j].oper = op; e->ph[j].index = 0;
  }
  for (int i = 0; i < c->nnodes; i++) {
    OpSpec* p = &slots[c->nodes[i]].spec;
    snprintf(name, sizeof name, "n%d_%d", opcount++, i);
    TF_OperationDescription* d = TF_NewOperation(graph, p->op, name);
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
    if (bad()) { free(e->key); free(e); return 0; }
    e->out[i].oper = op; e->out[i].index = 0;
  }
  entries[nentries++] = e;
  return e;
}
static Entry* entry_for(Closure* c, int* hit) {
  Entry* e = entry_find(c->key);
  if (e) { *hit = 1; return e; }
  *hit = 0; return entry_compile(c);
}
/* feed every leaf that is not a compiled constant */
static int feeds_of(Closure* c, Entry* e, TF_Output* fo, TF_Tensor** ft) {
  int n = 0;
  for (int j = 0; j < c->nleaves; j++) {
    TfSlot* s = &slots[c->leaves[j]];
    if (s->ckey) continue;
    if (!s->val) { fail("a leaf without a value"); return -1; }
    fo[n] = e->ph[j]; ft[n] = s->val; n++;
  }
  return n;
}
/* run the closure of h: every node in it gets its value */
static int run_closure(int64_t h) {
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(h, 0, c)) { free(c); return 0; }
  if (c->nnodes == 0) { free(c); return 1; }
  int hit = 0; Entry* e = entry_for(c, &hit);
  if (!e) { free(c); return 0; }
  TF_Output fo[TF_MAXLEAF]; TF_Tensor* ft[TF_MAXLEAF];
  int nf = feeds_of(c, e, fo, ft); if (nf < 0) { free(c); return 0; }
  TF_Tensor** res = (TF_Tensor**) calloc((size_t) c->nnodes, sizeof(TF_Tensor*));
  TF_SessionRun(sess, 0, fo, ft, nf, e->out, res, c->nnodes, 0, 0, 0, st);
  if (bad()) { free(res); free(c); return 0; }
  /* A NODE KEEPS ITS STRUCTURE after it has a value only when a parameter
   * is under it -- a loss read by item may still be asked for its gradient.
   * A closure with no parameter in it -- an optimiser's moments, a metric --
   * is just values now: its nodes let go of their inputs, or a chain of
   * moments would hold every step before it alive. */
  for (int i = 0; i < c->nnodes; i++) {
    TfSlot* s = &slots[c->nodes[i]];
    if (s->val) TF_DeleteTensor(s->val);
    s->val = res[i]; set_shape_from_tensor(s, res[i]); stat_exe++;
  }
  for (int i = 0; i < c->nnodes; i++) {
    TfSlot* s = &slots[c->nodes[i]];
    if (s->under_param && !s->is_param) continue;
    OpSpec sp = s->spec; s->spec.nin = 0; s->kind = K_VALUE;
    for (int k = 0; k < sp.nin; k++) unref(sp.in[k]);
  }
  if (hit) stat_rep++;
  free(res); free(c);
  return 1;
}
int tfb_force(int64_t h) {
  if (!tfb_exists(h)) return 0;
  TfSlot* s = &slots[h];
  if (s->kind == K_NODE && !s->val) return run_closure(h);
  return 1;
}

/* ---- reading a value ------------------------------------------------ */
/* values as doubles, the caller frees; shape and nd filled */
double* tfb_values(int64_t h, int64_t* n, int64_t* shape, int* nd) {
  if (!tfb_exists(h)) { fail("not a tensor"); return 0; }
  TfSlot* s = &slots[h];
  TF_Tensor* t = 0; int mine = 0;
  if (s->kind == K_EAGER) { t = TFE_TensorHandleResolve(s->eh, st); if (bad()) return 0; mine = 1; }
  else { if (!tfb_force(h)) return 0; t = s->val; }
  int64_t cnt = TF_TensorElementCount(t);
  double* buf = (double*) malloc((size_t)(cnt > 0 ? cnt : 1) * sizeof(double));
  TF_DataType dt = TF_TensorType(t);
  if (dt == TF_FLOAT) { float* p = (float*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_DOUBLE) { double* p = (double*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_INT32) { int32_t* p = (int32_t*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = p[i]; }
  else if (dt == TF_INT64) { int64_t* p = (int64_t*) TF_TensorData(t); for (int64_t i = 0; i < cnt; i++) buf[i] = (double) p[i]; }
  else { free(buf); if (mine) TF_DeleteTensor(t); fail("unsupported dtype"); return 0; }
  *nd = TF_NumDims(t); for (int i = 0; i < *nd && i < TF_MAXDIM; i++) shape[i] = TF_Dim(t, i);
  *n = cnt;
  if (mine) TF_DeleteTensor(t);
  return buf;
}
int tfb_is_int(int64_t h) { return tfb_exists(h) && (slots[h].dtype == TF_INT32 || slots[h].dtype == TF_INT64); }
/* the shape without running anything, when the compiled graph knows it */
int tfb_shape(int64_t h, int64_t* shape, int* nd) {
  if (!tfb_exists(h)) return 0;
  TfSlot* s = &slots[h];
  if (s->kind == K_EAGER) {
    *nd = TFE_TensorHandleNumDims(s->eh, st); if (bad()) return 0;
    for (int i = 0; i < *nd; i++) shape[i] = TFE_TensorHandleDim(s->eh, i, st);
    return 1;
  }
  if (s->shape_known) { *nd = s->nd; for (int i = 0; i < s->nd; i++) shape[i] = s->shape[i]; return 1; }
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(h, 0, c)) { free(c); return 0; }
  int hit = 0; Entry* e = entry_for(c, &hit);
  if (!e) { free(c); return 0; }
  TF_Output o = e->out[node_index(c, h)];
  free(c);
  int n = TF_GraphGetTensorNumDims(graph, o, st);
  if (bad() || n < 0) { if (!run_closure(h)) return 0; *nd = s->nd; for (int i = 0; i < s->nd; i++) shape[i] = s->shape[i]; return 1; }
  int64_t dims[TF_MAXDIM]; TF_GraphGetTensorShape(graph, o, dims, n, st); if (bad()) return 0;
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
      !strcmp(op, "Relu") || !strcmp(op, "Sigmoid") || !strcmp(op, "Tanh")) { *nd = na; for (int i = 0; i < na; i++) sh[i] = a[i]; return 1; }
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

static int64_t run_spec(OpSpec* p) {
  for (int i = 0; i < p->nin; i++) if (!tfb_exists(p->in[i])) { fail("not a tensor"); return -1; }
  int64_t h = slot_new(); if (h < 0) return -1;
  TfSlot* s = &slots[h];
  if (tfb_mode() == 0) {
    TFE_Op* op = TFE_NewOp(ctx, p->op, st); if (bad()) { s->kind = K_FREE; return -1; }
    for (int i = 0; i < p->ntypes; i++) TFE_OpSetAttrType(op, p->type_attrs[i], p->type_vals[i]);
    for (int i = 0; i < p->nints; i++) TFE_OpSetAttrInt(op, p->int_attrs[i], p->int_vals[i]);
    for (int i = 0; i < p->nbools; i++) TFE_OpSetAttrBool(op, p->bool_attrs[i], p->bool_vals[i]);
    if (p->list_n > 0) {
      TFE_TensorHandle* hs[TF_MAXIN];
      for (int i = 0; i < p->list_n; i++) hs[i] = slots[p->in[i]].eh;
      TFE_OpAddInputList(op, hs, p->list_n, st); if (bad()) { TFE_DeleteOp(op); s->kind = K_FREE; return -1; }
      for (int i = p->list_n; i < p->nin; i++) { TFE_OpAddInput(op, slots[p->in[i]].eh, st); if (bad()) { TFE_DeleteOp(op); s->kind = K_FREE; return -1; } }
    } else {
      for (int i = 0; i < p->nin; i++) { TFE_OpAddInput(op, slots[p->in[i]].eh, st); if (bad()) { TFE_DeleteOp(op); s->kind = K_FREE; return -1; } }
    }
    TFE_TensorHandle* ret = 0; int nret = 1;
    TFE_Execute(op, &ret, &nret, st); TFE_DeleteOp(op);
    if (bad() || nret < 1) { s->kind = K_FREE; return -1; }
    s->kind = K_EAGER; s->eh = ret;
    s->nd = TFE_TensorHandleNumDims(ret, st); if (s->nd > TF_MAXDIM) s->nd = TF_MAXDIM;
    for (int i = 0; i < s->nd; i++) s->shape[i] = TFE_TensorHandleDim(ret, i, st);
    s->shape_known = 1; s->dtype = TFE_TensorHandleDataType(ret);
    return h;
  }
  /* graph: record, hold the inputs, and ask the compiled graph for the shape --
   * which is also where a wrong shape is refused, at this goal */
  s->kind = K_NODE; s->spec = *p;
  for (int i = 0; i < p->nin; i++) slots[p->in[i]].refs++;
  s->dtype = TF_FLOAT;
  for (int i = 0; i < p->ntypes; i++) if (0 == strcmp(p->type_attrs[i], "output_type")) s->dtype = p->type_vals[i];
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
int64_t tfb_gather(int64_t a, int64_t idx) {
  int64_t ax = iscalar(0); if (ax < 0) return -1;
  OpSpec p; spec_init(&p, "GatherV2"); spec_in(&p, a); spec_in(&p, idx); spec_in(&p, ax);
  spec_type(&p, "Tparams", tfb_is_int(a) ? slots[a].dtype : TF_FLOAT); spec_type(&p, "Tindices", tfb_is_int(idx) ? slots[idx].dtype : TF_INT32); spec_type(&p, "Taxis", TF_INT32);
  spec_int(&p, "batch_dims", 0);
  return with_free(run_spec(&p), ax);
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
/* random leaves draw NOW through the eager context, and are values */
int64_t tfb_random(const int64_t* shape, int nd, int normal) {
  int64_t sh[1] = { nd }; TF_Tensor* t = tensor_i32(shape, sh, 1);
  TFE_TensorHandle* shp = TFE_NewTensorHandle(t, st); TF_DeleteTensor(t); if (bad()) return -1;
  TFE_Op* op = TFE_NewOp(ctx, normal ? "RandomStandardNormal" : "RandomUniform", st); if (bad()) return -1;
  TFE_OpSetAttrType(op, "dtype", TF_FLOAT); TFE_OpSetAttrType(op, "T", TF_INT32);
  TFE_OpSetAttrInt(op, "seed", seed_base); TFE_OpSetAttrInt(op, "seed2", ++seed_next);
  TFE_OpAddInput(op, shp, st);
  TFE_TensorHandle* ret = 0; int nret = 1; TFE_Execute(op, &ret, &nret, st); TFE_DeleteOp(op); TFE_DeleteTensorHandle(shp);
  if (bad()) return -1;
  TF_Tensor* val = TFE_TensorHandleResolve(ret, st); TFE_DeleteTensorHandle(ret); if (bad()) return -1;
  return slot_from_tensor(val, 0);
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
int64_t tfb_randperm(int64_t n) {
  int64_t* v = (int64_t*) malloc((size_t)(n > 0 ? n : 1) * sizeof(int64_t));
  for (int64_t i = 0; i < n; i++) v[i] = i;
  uint64_t x = (uint64_t) seed_base * 6364136223846793005ULL + (uint64_t)(++seed_next) * 1442695040888963407ULL;
  for (int64_t i = n - 1; i > 0; i--) { x = x * 6364136223846793005ULL + 1442695040888963407ULL; int64_t j = (int64_t)((x >> 33) % (uint64_t)(i + 1)); int64_t t = v[i]; v[i] = v[j]; v[j] = t; }
  int64_t h = tfb_from_ints(v, n); free(v); return h;
}
/* a parameter: a leaf holding a's value, with gradient wanted */
int64_t tfb_parameter(int64_t a) {
  int64_t shape[TF_MAXDIM]; int nd = 0; int64_t n = 0;
  double* buf = tfb_values(a, &n, shape, &nd); if (!buf) return -1;
  int64_t h = tfb_from_doubles(buf, shape, nd); free(buf);
  if (h > 0) slots[h].is_param = 1;
  return h;
}
/* a step: W - lr G, RECORDED like any node and marked a parameter, so that
 * the next loss's one run computes it along with everything else, and the
 * gradient walk stops at it -- a step is a boundary, not a history. Once it
 * has a value it is a plain leaf and lets its inputs go. */
int64_t tfb_step(int64_t w, int64_t g, double lr) {
  int64_t scaled = tfb_scalar("mul", g, lr); if (scaled < 0) return -1;
  int64_t next = tfb_binary("sub", w, scaled); tfb_free(scaled); if (next < 0) return -1;
  if (tfb_mode() == 1) { slots[next].is_param = 1; return next; }
  int64_t leaf = tfb_parameter(next); tfb_free(next); return leaf;
}
/* the gradients of loss for ps: the closure of loss in grad mode, keyed with
 * the parameters' places in it, TF_AddGradients once per key, then a run */
int tfb_grad(int64_t loss, const int64_t* ps, int n, int64_t* gs) {
  if (tfb_mode() == 0) { fail("gradients need tensor_execution(tensorflow, graph): the eager C API has no tape"); return 0; }
  if (!tfb_exists(loss) || slots[loss].kind != K_NODE) { fail("the loss is not a recorded tensor"); return 0; }
  if (n > 64) { fail("at most 64 parameters"); return 0; }
  for (int i = 0; i < n; i++) if (!tfb_exists(ps[i]) || !(slots[ps[i]].kind == K_VALUE || (slots[ps[i]].kind == K_NODE && slots[ps[i]].is_param))) { fail("a parameter must be a leaf: tensor_parameter/2 or tensor_step/4 makes one"); return 0; }
  /* one run: the loss, and with it every recorded step and moment it rests on */
  if (!run_closure(loss)) return 0;
  for (int i = 0; i < n; i++) if (slots[ps[i]].kind == K_NODE && !slots[ps[i]].val) { if (!run_closure(ps[i])) return 0; }
  Closure* c = (Closure*) malloc(sizeof(Closure));
  if (!closure_of(loss, 1, c)) { free(c); return 0; }
  int li[64];
  kput(c, "|G:");
  for (int i = 0; i < n; i++) { li[i] = leaf_index(c, ps[i]); kput(c, "%d,", li[i]); }
  int hit = 0; Entry* e = entry_find(c->key);
  if (e) hit = 1;
  else {
    e = entry_compile(c); if (!e) { free(c); return 0; }
    TF_Output y = e->out[node_index(c, loss)];
    TF_Output xs[64]; int nx = 0; int which[64];
    for (int i = 0; i < n; i++) if (li[i] >= 0) { xs[nx] = e->ph[li[i]]; which[nx] = i; nx++; }
    for (int i = 0; i < 64; i++) { e->grads[i].oper = 0; e->grads[i].index = 0; }
    if (nx > 0) {
      TF_Output dys[64];
      TF_AddGradients(graph, &y, 1, xs, nx, 0, st, dys);
      if (TF_GetCode(st) == TF_OK) { for (int k = 0; k < nx; k++) e->grads[which[k]] = dys[k]; }
      else {
        TF_SetStatus(st, TF_OK, "");
        for (int k = 0; k < nx; k++) {
          TF_Output dy; dy.oper = 0; dy.index = 0;
          TF_AddGradients(graph, &y, 1, &xs[k], 1, 0, st, &dy);
          if (TF_GetCode(st) == TF_OK) e->grads[which[k]] = dy;
          TF_SetStatus(st, TF_OK, "");
        }
      }
    }
    e->ngrads = n;
  }
  TF_Output fo[TF_MAXLEAF]; TF_Tensor* ft[TF_MAXLEAF];
  int nf = feeds_of(c, e, fo, ft); if (nf < 0) { free(c); return 0; }
  TF_Output fetch[64]; TF_Tensor* res[64]; int at[64]; int nfetch = 0;
  for (int i = 0; i < n; i++) if (e->grads[i].oper) { fetch[nfetch] = e->grads[i]; at[nfetch] = i; nfetch++; }
  if (nfetch > 0) {
    TF_SessionRun(sess, 0, fo, ft, nf, fetch, res, nfetch, 0, 0, 0, st);
    if (bad()) { free(c); return 0; }
    if (hit) stat_rep++;
  }
  for (int i = 0; i < n; i++) {
    int64_t h; int k = -1; for (int j = 0; j < nfetch; j++) if (at[j] == i) k = j;
    if (k < 0) {    /* the loss never reached it: zeros of its shape */
      int64_t shape[TF_MAXDIM]; int nd = 0; if (!tfb_shape(ps[i], shape, &nd)) { free(c); return 0; }
      h = tfb_fill(shape, nd, 0.0); if (h < 0) { free(c); return 0; }
    } else {
      h = slot_new(); if (h < 0) { free(c); return 0; }
      TfSlot* s = &slots[h]; s->kind = K_VALUE; s->val = res[k]; set_shape_from_tensor(s, res[k]); stat_exe++;
    }
    gs[i] = h;
  }
  free(c);
  return 1;
}
void tfb_stats(long long* rec, long long* exe, long long* rep, long long* pend) {
  long long p = 0; for (int i = 1; i < TF_SLOTS; i++) if (slots[i].kind == K_NODE && !slots[i].val && !slots[i].released) p++;
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
