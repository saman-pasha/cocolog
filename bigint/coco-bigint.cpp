#include <cstdio>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <string>
#include <vector>
struct coco_engine ;
extern "C" { 
int coco_module_register(const char*, int (*)(struct coco_engine*, const char*, uint32_t, size_t, int*), const char*, int (*)(struct coco_engine*)); 
size_t coco_m_arg(struct coco_engine*, size_t, uint32_t); 
int coco_m_int(struct coco_engine*, size_t, int64_t*); 
int coco_m_text(struct coco_engine*, size_t, char*, size_t); 
int coco_m_unify_atom(struct coco_engine*, size_t, const char*); 
int coco_m_unify_int(struct coco_engine*, size_t, int64_t); 
int coco_m_type_error(struct coco_engine*, const char*, size_t); 
int coco_m_domain_error(struct coco_engine*, const char*, size_t); 
int coco_m_error(struct coco_engine*, const char*, const char*); 
} 
int coco_module_register (const char * name , int (*dispatch) (coco_engine * e , const char * nm , uint32_t arity , size_t g , int * found ), const char * prolog , int (*init) (coco_engine * e ));
size_t coco_m_arg (coco_engine * e , size_t g , uint32_t i );
int coco_m_int (coco_engine * e , size_t t , int64_t * out );
int coco_m_text (coco_engine * e , size_t t , char * buf , size_t cap );
int coco_m_unify_atom (coco_engine * e , size_t t , const char * s );
int coco_m_unify_int (coco_engine * e , size_t t , int64_t v );
int coco_m_type_error (coco_engine * e , const char * type , size_t culprit );
int coco_m_domain_error (coco_engine * e , const char * domain , size_t culprit );
int coco_m_error (coco_engine * e , const char * what , const char * detail );
#include <bigint.hpp> 
#include <bufferstream.hpp> 
using Zigurat::BigInt; 
#define BI_MAX_DIGITS 4096 
static void mag_mul10_add(std::vector<uint8_t>& m, int d) { 
  int carry = d; 
  for (size_t i = m.size(); i > 0; i--) { 
    int v = (int)m[i-1] * 10 + carry; m[i-1] = (uint8_t)(v & 0xff); carry = v >> 8; } 
  while (carry) { m.insert(m.begin(), (uint8_t)(carry & 0xff)); carry >>= 8; } } 
static int mag_divmod10(std::vector<uint8_t>& m) { 
  int rem = 0; 
  for (size_t i = 0; i < m.size(); i++) { 
    int cur = (rem << 8) | m[i]; m[i] = (uint8_t)(cur / 10); rem = cur % 10; } 
  while (m.size() > 1 && m[0] == 0) m.erase(m.begin()); 
  return rem; } 
static bool mag_zero(const std::vector<uint8_t>& m) { 
  for (size_t i = 0; i < m.size(); i++) if (m[i]) return false; return true; } 
static bool bi_parse(const char* s, BigInt& out) { 
  if (!s) return false; 
  bool neg = false; if (*s == '-') { neg = true; s++; } else if (*s == '+') s++; 
  if (!*s) return false; 
  std::vector<uint8_t> mag; mag.push_back(0); 
  if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) { 
    const char* h = s + 2; if (!*h) return false; 
    size_t n = strlen(h); if (n > BI_MAX_DIGITS) return false; 
    std::vector<uint8_t> b; std::vector<int> d; 
    for (size_t i = 0; i < n; i++) { 
      int c = h[i], v; 
      if (c >= '0' && c <= '9') v = c - '0'; 
      else if (c >= 'a' && c <= 'f') v = 10 + c - 'a'; 
      else if (c >= 'A' && c <= 'F') v = 10 + c - 'A'; 
      else return false; 
      d.push_back(v); } 
    size_t start = 0; 
    if (d.size() % 2 == 1) { b.push_back((uint8_t)d[0]); start = 1; } 
    for (size_t i = start; i + 1 < d.size(); i += 2) 
      b.push_back((uint8_t)(d[i] * 16 + d[i+1])); 
    if (b.empty()) b.push_back(0); 
    mag = b; } 
  else { 
    size_t n = strlen(s); if (n > BI_MAX_DIGITS) return false; 
    for (size_t i = 0; i < n; i++) { 
      if (s[i] < '0' || s[i] > '9') return false; 
      mag_mul10_add(mag, s[i] - '0'); } } 
  out = BigInt(mag.data(), mag.size(), false); 
  if (neg && !out.is_zero()) out.sign(true); 
  return true; } 
static void bi_mag(const BigInt& v, std::vector<uint8_t>& out) { 
  out.clear(); 
  Zigurat::bufferstream buf; 
  v.to_octet_string(buf, false); 
  size_t n = buf.length(); 
  for (size_t i = 0; i < n; i++) out.push_back((uint8_t)buf.get()); 
  while (out.size() > 1 && out[0] == 0) out.erase(out.begin()); 
  if (out.empty()) out.push_back(0); } 
static bool bi_dec(const BigInt& v, std::string& out) { 
  std::vector<uint8_t> m; bi_mag(v, m); 
  std::string d; 
  if (mag_zero(m)) { out = "0"; return true; } 
  while (!mag_zero(m)) { int r = mag_divmod10(m); d.push_back((char)('0' + r)); 
    if (d.size() > BI_MAX_DIGITS) return false; } 
  out.clear(); if (v.sign()) out.push_back('-'); 
  for (size_t i = d.size(); i > 0; i--) out.push_back(d[i-1]); 
  return true; } 
static bool bi_hexs(const BigInt& v, std::string& out) { 
  std::vector<uint8_t> m; bi_mag(v, m); 
  const char* hx = "0123456789abcdef"; 
  std::string h; 
  for (size_t i = 0; i < m.size(); i++) { h.push_back(hx[m[i] >> 4]); h.push_back(hx[m[i] & 15]); } 
  size_t z = 0; while (z + 1 < h.size() && h[z] == '0') z++; 
  out.clear(); if (v.sign() && !mag_zero(m)) out.push_back('-'); 
  out += h.substr(z); 
  return true; } 
#include <cmath> 
static double bi_log2(const BigInt& v) { 
  std::vector<uint8_t> m; bi_mag(v, m); 
  if (mag_zero(m)) return 0.0; 
  size_t n = m.size(), take = n < 8 ? n : 8; double top = 0.0; 
  for (size_t i = 0; i < take; i++) top = top * 256.0 + (double)m[i]; 
  return std::log2(top) + 8.0 * (double)(n - take); } 
static bool bi_sqrt(const BigInt& n, BigInt& out) { 
  if (n.sign()) return false; 
  if (n.is_zero()) { out = BigInt((int32_t)0); return true; } 
  BigInt one((int32_t)1), two((int32_t)2); 
  if (BigInt::cmp(n, one) <= 0) { out = one; return true; } 
  BigInt x = n, y = (n / two) + one; 
  while (BigInt::cmp(y, x) < 0) { x = y; y = (x + (n / x)) / two; } 
  out = x; return true; } 
extern "C" int coco_bi_eval(const char* op, const char* a, const char* b, 
                             const char* c, char* out, size_t cap) { 
  BigInt A, B, C; 
  if (a && !bi_parse(a, A)) return 1; 
  if (b && !bi_parse(b, B)) return 2; 
  if (c && !bi_parse(c, C)) return 3; 
  BigInt R; std::string s; 
  if (!strcmp(op, "add")) R = A + B; 
  else if (!strcmp(op, "sub")) R = A - B; 
  else if (!strcmp(op, "mul")) R = A * B; 
  else if (!strcmp(op, "div")) { if (B.is_zero()) return 4; R = A / B; } 
  else if (!strcmp(op, "mod")) { if (B.is_zero()) return 4; R = A % B; } 
  else if (!strcmp(op, "gcd")) R = BigInt::gcd(A, B); 
  else if (!strcmp(op, "lcm")) { if (A.is_zero() || B.is_zero()) return 4; R = BigInt::lcm(A, B); } 
  else if (!strcmp(op, "inverse")) { if (B.is_zero()) return 4; 
    BigInt g = BigInt::gcd(A, B); BigInt one((int32_t)1); 
    if (BigInt::cmp(g, one) != 0) return 6; 
    R = BigInt::inverse(A, B); } 
  else if (!strcmp(op, "mod_pow")) { if (C.is_zero()) return 4; 
    if (B.sign()) return 8; R = BigInt::mod_pow(A, B, C); } 
  else if (!strcmp(op, "pow")) { 
    if (B.sign()) return 8; 
    std::string es; if (!bi_dec(B, es)) return 5; 
    if (es.size() > 7) return 5; 
    long ex = atol(es.c_str()); 
    if (bi_log2(A) * 0.30103 * (double)ex + 1.0 > (double)BI_MAX_DIGITS) return 5; 
    R = BigInt::pow(A, B); } 
  else if (!strcmp(op, "sqrt")) { if (!bi_sqrt(A, R)) return 8; } 
  else if (!strcmp(op, "abs")) { R = A; R.sign(false); } 
  else if (!strcmp(op, "neg")) { R = A; if (!R.is_zero()) R.sign(!A.sign()); } 
  else if (!strcmp(op, "dec")) R = A; 
  else if (!strcmp(op, "cmp")) { 
    int r = BigInt::cmp(A, B); 
    const char* t = (r < 0) ? "<" : (r > 0 ? ">" : "="); 
    if (strlen(t) + 1 > cap) return 5; strcpy(out, t); return 0; } 
  else if (!strcmp(op, "hex")) { if (!bi_hexs(A, s)) return 5; 
    if (s.size() + 1 > cap) return 5; strcpy(out, s.c_str()); return 0; } 
  else return 7; 
  if (!bi_dec(R, s)) return 5; 
  if (s.size() + 1 > cap) return 5; 
  strcpy(out, s.c_str()); return 0; } 
int coco_bi_eval (const char * op , const char * a , const char * b , const char * c , char * out , size_t cap );
#include <cerrno> 
static void bi_i64_text(int64_t v, char* buf, size_t cap) { 
  snprintf(buf, cap, "%lld", (long long)v); } 
void bi_i64_text (int64_t v , char * buf , size_t cap );
static int bi_fits_i64(const char* dec, int64_t* out) { 
  char* end = 0; errno = 0; 
  long long v = strtoll(dec, &end, 10); 
  if (errno != 0 || end == dec || *end != '\0') return 0; 
  *out = (int64_t)v; return 1; } 
int bi_fits_i64 (const char * dec , int64_t * out );
static int bi_text (coco_engine * e , size_t slot , char * buf , size_t cap ) {
  { /* let270 */
    int64_t iv  = 0;
    // ----------
    if (coco_m_int (e , slot , (&iv )))
      { /* block274 */
        bi_i64_text (iv , buf , cap );
        return 1;
      }
    return coco_m_text (e , slot , buf , cap );
  }
}
static int bi_fail (coco_engine * e , int code , size_t sa , size_t sb , size_t sc ) {
  if (code  ==  1 ) {
      return coco_m_domain_error (e , "an integer in digits", sa );
  }
  else if (code  ==  2 ) {
      return coco_m_domain_error (e , "an integer in digits", sb );
  }
  else if (code  ==  3 ) {
      return coco_m_domain_error (e , "an integer in digits", sc );
  }
  else if (code  ==  4 ) {
      return coco_m_error (e , "bigint division by zero", "the divisor is zero");
  }
  else if (code  ==  5 ) {
      return coco_m_error (e , "bigint result too large", "above 4096 decimal digits");
  }
  else if (code  ==  6 ) {
      return coco_m_error (e , "bigint has no inverse", "the arguments are not coprime");
  }
  else if (code  ==  8 ) {
      return coco_m_error (e , "bigint domain", "a negative exponent or root");
  }
  else if (true ) {
      return coco_m_error (e , "bigint", "the operation is not one of these");
  }
}
static int bi_do2 (coco_engine * e , size_t g , const char * op ) {
  { /* let287 */
    size_t sa  = coco_m_arg (e , g , 0);
    size_t sb  = coco_m_arg (e , g , 1);
    size_t sr  = coco_m_arg (e , g , 2);
    char ab [4200];
    char bb [4200];
    char rb [4200];
    // ----------
    if (!bi_text (e , sa , ab , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sa );
    if (!bi_text (e , sb , bb , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sb );
    { /* let293 */
      int rc  = coco_bi_eval (op , ab , bb , NULL , rb , 4200);
      // ----------
      if (rc  !=  0 )
        return bi_fail (e , rc , sa , sb , sb );
      return coco_m_unify_atom (e , sr , rb );
    }
  }
}
static int bi_do1 (coco_engine * e , size_t g , const char * op ) {
  { /* let298 */
    size_t sa  = coco_m_arg (e , g , 0);
    size_t sr  = coco_m_arg (e , g , 1);
    char ab [4200];
    char rb [4200];
    // ----------
    if (!bi_text (e , sa , ab , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sa );
    { /* let302 */
      int rc  = coco_bi_eval (op , ab , NULL , NULL , rb , 4200);
      // ----------
      if (rc  !=  0 )
        return bi_fail (e , rc , sa , sa , sa );
      return coco_m_unify_atom (e , sr , rb );
    }
  }
}
static int bi_do3 (coco_engine * e , size_t g , const char * op ) {
  { /* let307 */
    size_t sa  = coco_m_arg (e , g , 0);
    size_t sb  = coco_m_arg (e , g , 1);
    size_t sc  = coco_m_arg (e , g , 2);
    size_t sr  = coco_m_arg (e , g , 3);
    char ab [4200];
    char bb [4200];
    char cb [4200];
    char rb [4200];
    // ----------
    if (!bi_text (e , sa , ab , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sa );
    if (!bi_text (e , sb , bb , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sb );
    if (!bi_text (e , sc , cb , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sc );
    { /* let315 */
      int rc  = coco_bi_eval (op , ab , bb , cb , rb , 4200);
      // ----------
      if (rc  !=  0 )
        return bi_fail (e , rc , sa , sb , sc );
      return coco_m_unify_atom (e , sr , rb );
    }
  }
}
static int bi_to_int (coco_engine * e , size_t g ) {
  { /* let320 */
    size_t sa  = coco_m_arg (e , g , 0);
    size_t sr  = coco_m_arg (e , g , 1);
    char ab [4200];
    char rb [4200];
    // ----------
    if (!bi_text (e , sa , ab , 4200))
      return coco_m_type_error (e , "an integer or a numeric atom", sa );
    { /* let324 */
      int rc  = coco_bi_eval ("dec", ab , NULL , NULL , rb , 4200);
      // ----------
      if (rc  !=  0 )
        return bi_fail (e , rc , sa , sa , sa );
    }
    { /* let328 */
      int64_t v  = 0;
      // ----------
      if (!bi_fits_i64 (rb , (&v )))
        return coco_m_error (e , "bigint does not fit an integer", "outside 64 bits, so it would wrap");
      return coco_m_unify_int (e , sr , v );
    }
  }
}
extern "C" 
{ /* block335 */
  int coco_bigint_dispatch (coco_engine * e , const char * name , uint32_t arity , size_t g , int * found ) {
    (*found ) = 1;
    if (arity  ==  2 ) {
        if (0 ==  strcmp (name , "bigint_sqrt") ) {
            return bi_do1 (e , g , "sqrt");
        }
        else if (0 ==  strcmp (name , "bigint_dec") ) {
            return bi_do1 (e , g , "dec");
        }
        else if (0 ==  strcmp (name , "bigint_hex") ) {
            return bi_do1 (e , g , "hex");
        }
        else if (0 ==  strcmp (name , "bigint_abs") ) {
            return bi_do1 (e , g , "abs");
        }
        else if (0 ==  strcmp (name , "bigint_neg") ) {
            return bi_do1 (e , g , "neg");
        }
        else if (0 ==  strcmp (name , "bigint_int") ) {
            return bi_to_int (e , g );
        }
        else if (true ) {
            (*found ) = 0;
            return 0;
        }
    }
    else if (arity  ==  3 ) {
        if (0 ==  strcmp (name , "bigint_add") ) {
            return bi_do2 (e , g , "add");
        }
        else if (0 ==  strcmp (name , "bigint_sub") ) {
            return bi_do2 (e , g , "sub");
        }
        else if (0 ==  strcmp (name , "bigint_mul") ) {
            return bi_do2 (e , g , "mul");
        }
        else if (0 ==  strcmp (name , "bigint_div") ) {
            return bi_do2 (e , g , "div");
        }
        else if (0 ==  strcmp (name , "bigint_mod") ) {
            return bi_do2 (e , g , "mod");
        }
        else if (0 ==  strcmp (name , "bigint_pow") ) {
            return bi_do2 (e , g , "pow");
        }
        else if (0 ==  strcmp (name , "bigint_gcd") ) {
            return bi_do2 (e , g , "gcd");
        }
        else if (0 ==  strcmp (name , "bigint_lcm") ) {
            return bi_do2 (e , g , "lcm");
        }
        else if (0 ==  strcmp (name , "bigint_cmp") ) {
            return bi_do2 (e , g , "cmp");
        }
        else if (0 ==  strcmp (name , "bigint_inverse") ) {
            return bi_do2 (e , g , "inverse");
        }
        else if (true ) {
            (*found ) = 0;
            return 0;
        }
    }
    else if (arity  ==  4 ) {
        if (0 ==  strcmp (name , "bigint_mod_pow") ) {
            return bi_do3 (e , g , "mod_pow");
        }
        else if (true ) {
            (*found ) = 0;
            return 0;
        }
    }
    else if (true ) {
        (*found ) = 0;
        return 0;
    }
  }
  int coco_bigint_module () {
    return coco_module_register ("bigint", coco_bigint_dispatch , NULL , NULL );
  }
}
