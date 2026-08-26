#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <curl/curl.h>
#define ubyte_t unsigned char 
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
typedef struct cu_buf {
  char * data ;
  size_t len ;
} cu_buf;
size_t cu_write (char * chunk , size_t size , size_t nmemb , void * user ) {
  { /* let172 */
    size_t add  = (size  *  nmemb  );
    cu_buf * b  = ((cu_buf *)user );
    char * grown  = NULL ;
    // ----------
    grown  = ((char *)realloc ((b -> data), ((b -> len) +  add  +  1 )));
    if (grown  ==  NULL  )
      return 0;
    (b -> data) = grown ;
    memcpy (((b -> data) +  (b -> len) ), chunk , add );
    (b -> len) += add  ;
    (b -> data)[(b -> len)] = '\0';
    return add ;
  }
}
void cu_buf_free (cu_buf * b ) {
  if ((b -> data) !=  NULL  )
    curl_free ((b -> data));
  (b -> data) = NULL ;
  (b -> len) = 0;
}
static int cl_ready  = 0;
static void cl_start () {
  if (cl_ready )
    return ;
  curl_global_init (CURL_GLOBAL_DEFAULT );
  cl_ready  = 1;
}
static struct curl_slist * cl_headers (char * text ) {
  { /* let184 */
    struct curl_slist * hs  = NULL ;
    char * p  = text ;
    char * q ;
    // ----------
    if ((text  ==  NULL  ) ||  (text [0] ==  ((char)0) ) )
      return ((struct curl_slist *)NULL );
    while ((p  !=  NULL  )) {
        q  = strchr (p , 10);
        if (q  !=  NULL  )
          (*q ) = ((char)0);
        if (p [0] !=  ((char)0) )
          { /* let194 */
            struct curl_slist * next  = curl_slist_append (hs , p );
            // ----------
            if (next  !=  NULL  )
              hs  = next ;
          }
        p  = (((q  ==  NULL  )) ? NULL  : (q  +  1 ));
    }
    return ((struct curl_slist *)hs );
  }
}
int cl_p_do (coco_engine * e , size_t g ) {
  { /* let199 */
    char method [16];
    char url [4096];
    char hdrs [8192];
    char ca [4096];
    int64_t timeout  = 30;
    int64_t follow  = 0;
    int64_t verify  = 1;
    int64_t maxsize  = 16777216;
    int64_t httpcode  = 0;
    ubyte_t * data  = NULL ;
    size_t dlen  = 0;
    int rc  = 0;
    int ok  = 0;
    // ----------
    if (!coco_m_text (e , coco_m_arg (e , g , 0), method , sizeof(method)))
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if (!coco_m_text (e , coco_m_arg (e , g , 1), url , sizeof(url)))
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 1));
    if (!coco_m_text (e , coco_m_arg (e , g , 2), hdrs , sizeof(hdrs)))
      hdrs [0] = ((char)0);
    if (!coco_m_text (e , coco_m_arg (e , g , 7), ca , sizeof(ca)))
      ca [0] = ((char)0);
    if (!coco_m_int (e , coco_m_arg (e , g , 4), (&timeout )))
      timeout  = 30;
    if (!coco_m_int (e , coco_m_arg (e , g , 5), (&follow )))
      follow  = 0;
    if (!coco_m_int (e , coco_m_arg (e , g , 6), (&verify )))
      verify  = 1;
    if (!coco_m_int (e , coco_m_arg (e , g , 8), (&maxsize )))
      maxsize  = 16777216;
    { /* let217 */
      size_t n  = 0;
      size_t * items  = NULL ;
      // ----------
      if (coco_m_list_length (e , coco_m_arg (e , g , 3), (&n )))
        {
        if (n  >  0 )
          { /* block223 */
            data  = ((ubyte_t *)malloc ((n  +  1 )));
            if (data  ==  NULL  )
              return 0;
            if (!coco_m_list_array (e , coco_m_arg (e , g , 3), (&items ), (&n )))
              { /* block229 */
                free (data );
                return 0;
              }
            for (size_t i  = 0; (i  <  n  ); (++i )) {
                { /* let234 */
                  int64_t v  = 0;
                  // ----------
                  coco_m_int (e , items [i ], (&v ));
                  data [i ] = ((ubyte_t)(v  &  255 ));
                }
            }
            free (items );
            data [n ] = ((ubyte_t)0);
            dlen  = n ;
          }
          }    }
    cl_start ();
    ({ /* progn237 */
      ({ /* letn239 */
        CURL * h  = curl_easy_init ();
        // ----------
        { /* let241 */
          cu_buf body  = { NULL , 0};
          struct curl_slist * hs  = cl_headers (hdrs );
          // ----------
          rc  = ({ /* progn245 */
                ({ /* letn247 */
                  int cu_rc_244  = 0;
                  // ----------
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_URL , ((const char *)url ));
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = ({ /* progn253 */
                          curl_easy_setopt (h , CURLOPT_WRITEFUNCTION , cu_write );
                          curl_easy_setopt (h , CURLOPT_WRITEDATA , (&body ));
                        });
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_TIMEOUT , ((long)timeout ));
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_FOLLOWLOCATION , ((long)follow ));
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_SSL_VERIFYPEER , ((long)verify ));
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_SSL_VERIFYHOST , ((long)((verify ) ? 2 : 0)));
                  if (cu_rc_244  ==  CURLE_OK  )
                    cu_rc_244  = curl_easy_setopt (h , CURLOPT_USERAGENT , ((const char *)"cocolog/library(curl)"));
                  cu_rc_244 ;
                });
              });
          if ((rc  ==  CURLE_OK  ) &&  (hs  !=  NULL  ) )
            rc  = ({ /* progn269 */
                  ({ /* letn271 */
                    int cu_rc_268  = 0;
                    // ----------
                    if (cu_rc_268  ==  CURLE_OK  )
                      cu_rc_268  = curl_easy_setopt (h , CURLOPT_HTTPHEADER , hs );
                    cu_rc_268 ;
                  });
                });
          if ((rc  ==  CURLE_OK  ) &&  (ca [0] !=  ((char)0) ) )
            rc  = ({ /* progn279 */
                  ({ /* letn281 */
                    int cu_rc_278  = 0;
                    // ----------
                    if (cu_rc_278  ==  CURLE_OK  )
                      cu_rc_278  = curl_easy_setopt (h , CURLOPT_CAINFO , ((const char *)ca ));
                    cu_rc_278 ;
                  });
                });
          if ((rc  ==  CURLE_OK  ) &&  (0 ==  strcmp (method , "post") ) )
            rc  = ({ /* progn289 */
                  ({ /* letn291 */
                    int cu_rc_288  = 0;
                    // ----------
                    if (cu_rc_288  ==  CURLE_OK  )
                      cu_rc_288  = curl_easy_setopt (h , CURLOPT_POSTFIELDS , ((const char *)((const char *)data )));
                    if (cu_rc_288  ==  CURLE_OK  )
                      cu_rc_288  = curl_easy_setopt (h , CURLOPT_POSTFIELDSIZE , ((long)((int64_t)dlen )));
                    cu_rc_288 ;
                  });
                });
          if ((rc  ==  CURLE_OK  ) &&  (0 ==  strcmp (method , "head") ) )
            rc  = ({ /* progn301 */
                  ({ /* letn303 */
                    int cu_rc_300  = 0;
                    // ----------
                    if (cu_rc_300  ==  CURLE_OK  )
                      cu_rc_300  = curl_easy_setopt (h , CURLOPT_NOBODY , ((long)1));
                    cu_rc_300 ;
                  });
                });
          if ((rc  ==  CURLE_OK  ) &&  ((0 !=  strcmp (method , "get") ) &&  ((0 !=  strcmp (method , "post") ) &&  (0 !=  strcmp (method , "head") ) ) ) )
            { /* let309 */
              char up [16];
              // ----------
              snprintf (up , sizeof(up), "%s", method );
              for (size_t i  = 0; (i  <  strlen (up ) ); (++i )) {
                  up [i ] = ((char)toupper (up [i ]));
              }
              rc  = ({ /* progn316 */
                    ({ /* letn318 */
                      int cu_rc_315  = 0;
                      // ----------
                      if (cu_rc_315  ==  CURLE_OK  )
                        cu_rc_315  = curl_easy_setopt (h , CURLOPT_CUSTOMREQUEST , ((const char *)up ));
                      cu_rc_315 ;
                    });
                  });
            }
          if (rc  ==  CURLE_OK  )
            rc  = curl_easy_perform (h );
          if (rc  ==  CURLE_OK  )
            { /* let327 */
              long code  = 0;
              // ----------
              curl_easy_getinfo (h , CURLINFO_RESPONSE_CODE , (&code ));
              httpcode  = ((int64_t)code );
              ok  = 1;
            }
          if (ok  &&  (((int64_t)(body . len)) >  maxsize  ) )
            ok  = 0;
          if (ok )
            { /* let333 */
              size_t lst  = coco_m_nil (e );
              // ----------
              for (size_t i  = (body . len); (i  >  0 ); (--i )) {
                  lst  = coco_m_cons (e , coco_m_new_int (e , ((int64_t)(body . data)[(i  -  1 )])), lst );
              }
              if (coco_m_unify_int (e , coco_m_arg (e , g , 9), httpcode ))
                ok  = coco_m_unify (e , coco_m_arg (e , g , 10), lst );
              else
                ok  = 0;
            }
          ({ /* progn342 */
            curl_slist_free_all (hs );
            hs  = NULL ;
          });
          cu_buf_free ((&body ));
        }
        curl_easy_cleanup (h );
      });
    });
    if (data  !=  NULL  )
      free (data );
    return ok ;
  }
}
int cl_p_ssl (coco_engine * e , size_t g ) {
  return coco_m_unify_atom (e , coco_m_arg (e , g , 0), (((0 !=  (({ /* progn350 */
            ({ /* letn352 */
              struct curl_version_info_data * cu_ver_349  = curl_version_info (CURLVERSION_NOW );
              // ----------
              (cu_ver_349 -> features);
            });
          }) &  CURL_VERSION_SSL  ) )) ? ({ /* progn356 */
        ({ /* letn358 */
          struct curl_version_info_data * cu_ver_355  = curl_version_info (CURLVERSION_NOW );
          // ----------
          (cu_ver_355 -> ssl_version);
        });
      }) : "none"));
}
int cl_p_version (coco_engine * e , size_t g ) {
  return coco_m_unify_atom (e , coco_m_arg (e , g , 0), curl_version ());
}
int cl_dispatch (coco_engine * e , const char * name , uint32_t arity , size_t g , int * found ) {
  (*found ) = 1;
  if (arity  ==  1 ) {
      if (0 ==  strcmp (name , "curl_ssl") ) {
          return cl_p_ssl (e , g );
      }
      else if (0 ==  strcmp (name , "curl_version") ) {
          return cl_p_version (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  11 ) {
      if (0 ==  strcmp (name , "$curl_do") ) {
          return cl_p_do (e , g );
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
  if (!coco_module_register ("curl", cl_dispatch , "curl_get(Url, Status, Body) :- curl_request(get, Url, [], Status, Body). curl_get(Url, Opts, Status, Body) :- curl_request(get, Url, Opts, Status, Body). curl_post(Url, Type, Data, Status, Body) :- curl_post(Url, Type, Data, [], Status, Body). curl_post(Url, Type, Data, Opts, Status, Body) :- atom_concat('Content-Type: ', Type, H), curl_request(post, Url, [body(Data), header(H)|Opts], Status, Body). curl_request(Method, Url, Opts, Status, Body) :- curl_opt(Opts, timeout, 30, T), curl_opt(Opts, follow, 0, F), curl_opt(Opts, verify_peer, 1, V), curl_opt(Opts, ca_info, '', CA), curl_opt(Opts, max_size, 16777216, MX), curl_body(Opts, Data), curl_headers(Opts, HL), '$curl_do'(Method, Url, HL, Data, T, F, V, CA, MX, Status, Body). curl_opt(Opts, Name, _, V) :- Term =.. [Name, V0], memberchk(Term, Opts), !, curl_bool(V0, V). curl_opt(_, _, Default, Default). curl_bool(true, 1) :- !. curl_bool(false, 0) :- !. curl_bool(V, V). curl_body(Opts, Data) :- ( memberchk(body(D), Opts) -> curl_codes(D, Data) ; Data = [] ). curl_codes(D, D) :- is_list(D), !. curl_codes(D, Cs) :- atom_codes(D, Cs). curl_headers(Opts, Joined) :- findall(H, member(header(H), Opts), Hs), curl_join(Hs, Joined). curl_join([], ''). curl_join([H], H) :- !. curl_join([H|T], Out) :- curl_join(T, Rest), atom_concat(H, '\\n', H1), atom_concat(H1, Rest, Out). curl_get_json(Url, Status, Body) :- curl_get(Url, [header('Accept: application/json')], Status, Body). ", NULL ))
    return 0;
  return 1;
}
