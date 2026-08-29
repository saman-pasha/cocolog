#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/utsname.h>
struct coco_engine_opaque; struct coco_machine_opaque; ;
#define coco_engine struct coco_engine_opaque 
#define coco_machine struct coco_machine_opaque 
#define u32 uint32_t 
#define i64 int64_t 
int coco_module_register (const char * name , int (*dispatch) (coco_engine * e , const char * nm , uint32_t arity , size_t g , int * found ), const char * prolog , int (*init) (coco_engine * e ));
size_t coco_m_arg (coco_engine * e , size_t g , uint32_t i );
coco_machine * coco_m_machine (coco_engine * e );
size_t coco_m_mark (coco_engine * e );
void coco_m_undo (coco_engine * e , size_t mark );
int coco_m_is_var (coco_engine * e , size_t t );
int coco_m_is_atom (coco_engine * e , size_t t );
const char * coco_m_atom (coco_engine * e , size_t t );
int coco_m_int (coco_engine * e , size_t t , int64_t * out );
int coco_m_float (coco_engine * e , size_t t , double * out );
int coco_m_text (coco_engine * e , size_t t , char * buf , size_t cap );
int coco_m_unify (coco_engine * e , size_t t , size_t u );
int coco_m_unify_atom (coco_engine * e , size_t t , const char * s );
int coco_m_unify_int (coco_engine * e , size_t t , int64_t v );
int coco_m_unify_float (coco_engine * e , size_t t , double v );
size_t coco_m_new_int (coco_engine * e , int64_t v );
char * coco_m_term_text (coco_engine * e , size_t t );
size_t coco_m_read_term (coco_engine * e , const char * src );
int coco_m_run_isolated (const char * src , char * err , size_t errlen );
size_t coco_m_new_float (coco_engine * e , double v );
size_t coco_m_new_atom (coco_engine * e , const char * s );
size_t coco_m_nil (coco_engine * e );
size_t coco_m_cons (coco_engine * e , size_t h , size_t t );
size_t coco_m_atom_list (coco_engine * e , char ** v , size_t n );
size_t coco_m_list (coco_engine * e , const size_t * items , size_t n );
int coco_m_list_length (coco_engine * e , size_t t , size_t * out );
int coco_m_list_array (coco_engine * e , size_t t , size_t ** out , size_t * n );
int coco_m_tensor_put (coco_engine * e , const char * name , int64_t seq , const double * v , uint32_t n );
int coco_m_tensor_row (coco_engine * e , const char * name , int64_t seq , double * out , uint32_t cap , uint32_t * n );
int coco_m_tensor_forget (coco_engine * e , const char * name );
int coco_m_type_error (coco_engine * e , const char * type , size_t culprit );
int coco_m_instantiation_error (coco_engine * e );
int coco_m_domain_error (coco_engine * e , const char * domain , size_t culprit );
int coco_m_existence_error (coco_engine * e , const char * kind , size_t what );
int coco_m_error (coco_engine * e , const char * what , const char * detail );
pid_t getppid ();
static int coco_os_int1 (coco_engine * e , size_t g , int64_t v ) {
  return coco_m_unify_int (e , coco_m_arg (e , g , 0), v );
}
int coco_os_uname (coco_engine * e , size_t g ) {
  { /* let164 */
    char sys [256];
    char node [256];
    char rel [256];
    char ver [512];
    char mach [256];
    int ok  = 0;
    // ----------
    { struct utsname u; if (uname(&u) == 0) { ok = 1;
                   snprintf(sys, sizeof sys, "%s", u.sysname);
                   snprintf(node, sizeof node, "%s", u.nodename);
                   snprintf(rel, sizeof rel, "%s", u.release);
                   snprintf(ver, sizeof ver, "%s", u.version);
                   snprintf(mach, sizeof mach, "%s", u.machine); } } ;
    if (!ok )
      return 0;
    if (!coco_m_unify_atom (e , coco_m_arg (e , g , 0), sys ))
      return 0;
    if (!coco_m_unify_atom (e , coco_m_arg (e , g , 1), node ))
      return 0;
    if (!coco_m_unify_atom (e , coco_m_arg (e , g , 2), rel ))
      return 0;
    if (!coco_m_unify_atom (e , coco_m_arg (e , g , 3), ver ))
      return 0;
    return coco_m_unify_atom (e , coco_m_arg (e , g , 4), mach );
  }
}
int coco_os_pid (coco_engine * e , size_t g ) {
  return coco_os_int1 (e , g , ((int64_t)getpid ()));
}
int coco_os_ppid (coco_engine * e , size_t g ) {
  return coco_os_int1 (e , g , ((int64_t)getppid ()));
}
int coco_os_uid (coco_engine * e , size_t g ) {
  return coco_os_int1 (e , g , ((int64_t)getuid ()));
}
int coco_os_gid (coco_engine * e , size_t g ) {
  return coco_os_int1 (e , g , ((int64_t)getgid ()));
}
int coco_os_cpus (coco_engine * e , size_t g ) {
  { /* let182 */
    long n  = 0;
    // ----------
    n  = sysconf(_SC_NPROCESSORS_ONLN) ;
    if (n  <  1 )
      n  = 1;
    return coco_os_int1 (e , g , ((int64_t)n ));
  }
}
int coco_os_hostname (coco_engine * e , size_t g ) {
  { /* let188 */
    char h [256];
    // ----------
    if (0 !=  gethostname (h , 255) )
      return 0;
    h [255] = ((char)0);
    return coco_m_unify_atom (e , coco_m_arg (e , g , 0), h );
  }
}
int coco_os_environ (coco_engine * e , size_t g ) {
  { /* let193 */
    size_t lst  = 0;
    // ----------
    { extern char **environ; size_t n = 0;
                   while (environ[n] != NULL) n++;
                   lst = coco_m_nil(e);
                   while (n > 0) { n--; lst = coco_m_cons(e, coco_m_new_atom(e, environ[n]), lst); } } ;
    return coco_m_unify (e , coco_m_arg (e , g , 0), lst );
  }
}
static int coco_os_text (coco_engine * e , size_t g , uint32_t i , char * buf , size_t cap , int * rc ) {
  { /* let197 */
    size_t t  = coco_m_arg (e , g , i );
    // ----------
    if (coco_m_is_var (e , t ))
      { /* block201 */
        (*rc ) = coco_m_instantiation_error (e );
        return 0;
      }
    if (!coco_m_text (e , t , buf , cap ))
      { /* block205 */
        (*rc ) = coco_m_type_error (e , "atom", t );
        return 0;
      }
    return 1;
  }
}
int coco_os_setenv (coco_engine * e , size_t g ) {
  { /* let208 */
    char name [256];
    char value [4096];
    int rc  = 0;
    // ----------
    if (!coco_os_text (e , g , 0, name , 256, (&rc )))
      return rc ;
    if (!coco_os_text (e , g , 1, value , 4096, (&rc )))
      return rc ;
    return (((0 ==  setenv (name , value , 1) )) ? 1 : 0);
  }
}
int coco_os_unsetenv (coco_engine * e , size_t g ) {
  { /* let215 */
    char name [256];
    int rc  = 0;
    // ----------
    if (!coco_os_text (e , g , 0, name , 256, (&rc )))
      return rc ;
    return (((0 ==  unsetenv (name ) )) ? 1 : 0);
  }
}
int coco_os_which (coco_engine * e , size_t g ) {
  { /* let220 */
    char tool [1024];
    char dir [1024];
    char path [2200];
    int rc  = 0;
    // ----------
    if (!coco_os_text (e , g , 0, tool , 1024, (&rc )))
      return rc ;
    if (!coco_os_text (e , g , 1, dir , 1024, (&rc )))
      return rc ;
    if (dir [0] ==  ((char)0) )
      snprintf (path , 2200, "%s", tool );
    else
      snprintf (path , 2200, "%s/%s", dir , tool );
    if (0 !=  access (path , 1) )
      return 0;
    return coco_m_unify_atom (e , coco_m_arg (e , g , 2), path );
  }
}
int coco_os_dispatch (coco_engine * e , const char * name , uint32_t arity , size_t g , int * found ) {
  (*found ) = 1;
  if (arity  ==  1 ) {
      if (0 ==  strcmp (name , "os_pid") ) {
          return coco_os_pid (e , g );
      }
      else if (0 ==  strcmp (name , "os_ppid") ) {
          return coco_os_ppid (e , g );
      }
      else if (0 ==  strcmp (name , "os_uid") ) {
          return coco_os_uid (e , g );
      }
      else if (0 ==  strcmp (name , "os_gid") ) {
          return coco_os_gid (e , g );
      }
      else if (0 ==  strcmp (name , "os_cpus") ) {
          return coco_os_cpus (e , g );
      }
      else if (0 ==  strcmp (name , "os_hostname") ) {
          return coco_os_hostname (e , g );
      }
      else if (0 ==  strcmp (name , "$os_environ") ) {
          return coco_os_environ (e , g );
      }
      else if (0 ==  strcmp (name , "os_unsetenv") ) {
          return coco_os_unsetenv (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  2 ) {
      if (0 ==  strcmp (name , "os_setenv") ) {
          return coco_os_setenv (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  3 ) {
      if (0 ==  strcmp (name , "$os_which") ) {
          return coco_os_which (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  5 ) {
      if (0 ==  strcmp (name , "$os_uname") ) {
          return coco_os_uname (e , g );
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
int coco_library_entry () {
  if (!coco_module_register ("os", coco_os_dispatch , "os_uname(S, N, R, V, M) :- '$os_uname'(S, N, R, V, M). os_name(Name) :- '$os_uname'(S, _, _, _, _), downcase_atom(S, Name). os_is(Name) :- os_name(Name). os_arch(M) :- '$os_uname'(_, _, _, _, M). os_environ(Pairs) :- '$os_environ'(Lines), os_env_pairs(Lines, Pairs). os_env_pairs([], []). os_env_pairs([L|Ls], [N-V|Ps]) :- ( sub_atom(L, B, 1, _, '='), sub_atom(L, 0, B, _, N), B1 is B + 1, sub_atom(L, B1, _, 0, V) -> true ; N = L, V = '' ), !, os_env_pairs(Ls, Ps). os_env(Name, Value) :- getenv(Name, Value). os_env(Name, Value, Default) :- ( getenv(Name, V) -> Value = V ; Value = Default ). os_home(H) :- os_env('HOME', H). os_user(U) :- ( os_env('USER', U) -> true ; os_env('LOGNAME', U) ). os_shell(S) :- os_env('SHELL', S, '/bin/sh'). os_tmp(T) :- os_env('TMPDIR', T0, '/tmp'), ( atom_concat(T1, '/', T0), T1 \\== '' -> T = T1 ; T = T0 ). os_path(Dirs) :- os_env('PATH', P, ''), atomic_list_concat(Dirs, ':', P). os_which(Tool, Path) :- ( sub_atom(Tool, _, 1, _, '/') -> '$os_which'(Tool, '', Path) ; os_path(Dirs), member(D, Dirs), D \\== '', '$os_which'(Tool, D, Path) ), !. os_has(Tool) :- os_which(Tool, _). os_lib_path_var(V) :- ( os_is(darwin) -> V = 'DYLD_LIBRARY_PATH' ; V = 'LD_LIBRARY_PATH' ). os_setsid_prefix(P) :- ( os_has(setsid) -> P = 'setsid ' ; P = '' ). os_describe(A) :- os_name(N), os_arch(M), os_cpus(C), atomic_list_concat([N, ' ', M, ' ', C, ' cpus'], A). ", NULL ))
    return 0;
  return 1;
}
