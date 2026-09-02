#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
typedef struct coco_engine coco_engine ;
typedef struct coco_machine coco_machine ;
int coco_module_register (const char * name , int (*dispatch) (coco_engine * e , const char * nm , uint32_t arity , size_t g , int * found ), const char * prolog , int (*init) (coco_engine * e ));
size_t coco_m_arg (coco_engine * e , size_t g , uint32_t i );
coco_machine * coco_m_machine (coco_engine * e );
int coco_m_is_atom (coco_engine * e , size_t t );
const char * coco_m_atom (coco_engine * e , size_t t );
int coco_m_int (coco_engine * e , size_t t , int64_t * out );
int coco_m_float (coco_engine * e , size_t t , double * out );
int coco_m_text (coco_engine * e , size_t t , char * buf , size_t cap );
int coco_m_unify (coco_engine * e , size_t a , size_t b );
int coco_m_unify_int (coco_engine * e , size_t t , int64_t v );
int coco_m_unify_float (coco_engine * e , size_t t , double v );
size_t coco_m_list (coco_engine * e , const size_t * cells , size_t n );
int coco_m_list_array (coco_engine * e , size_t t , size_t ** cells , size_t * n );
int coco_m_type_error (coco_engine * e , const char * what , size_t t );
int coco_m_domain_error (coco_engine * e , const char * what , size_t t );
size_t coco_deref (coco_machine * m , size_t t );
size_t coco_new_float (coco_machine * m , double v );
size_t coco_new_int (coco_machine * m , int64_t v );
size_t coco_new_atom (coco_machine * m , const char * name );
size_t coco_make1 (coco_machine * m , const char * name , size_t a );
size_t coco_make (coco_machine * m , const char * name , uint32_t n , const size_t * args );
int tfb_attach (int (*fn) (coco_engine * e , const char * nm , uint32_t arity , size_t g , int * found ));
const char * tfb_error ();
const char * tfb_version ();
void tfb_seed (int64_t s );
int tfb_mode ();
int tfb_exists (int64_t h );
int tfb_free (int64_t h );
int tfb_force (int64_t h );
int64_t tfb_from_doubles (const double * data , const int64_t * shape , int nd );
int64_t tfb_from_ints (const int64_t * data , int64_t n );
double * tfb_values (int64_t h , int64_t * n , int64_t * shape , int * nd );
int tfb_is_int (int64_t h );
int tfb_shape (int64_t h , int64_t * shape , int * nd );
int64_t tfb_unary (const char * nm , int64_t a );
int64_t tfb_binary (const char * nm , int64_t a , int64_t b );
int64_t tfb_scalar (const char * nm , int64_t a , double v );
int64_t tfb_agg (const char * nm , int64_t a );
int64_t tfb_argmax (int64_t a , int64_t dim );
int64_t tfb_reshape (int64_t a , const int64_t * shape , int nd );
int64_t tfb_cat (const int64_t * hs , int n , int64_t dim );
int64_t tfb_gather (int64_t a , int64_t idx );
int64_t tfb_slice (int64_t a , int axis , int64_t from , int64_t to );
int64_t tfb_standardise (int64_t a , int64_t ntrain );
int64_t tfb_fill (const int64_t * shape , int nd , double v );
int64_t tfb_random (const int64_t * shape , int nd , int normal );
int64_t tfb_eye (int64_t n );
int64_t tfb_arange (int64_t n );
int64_t tfb_randperm (int64_t n );
int64_t tfb_parameter (int64_t a );
int64_t tfb_step (int64_t w , int64_t g , double lr );
int tfb_grad (int64_t loss , const int64_t * ps , int n , int64_t * gs );
void tfb_stats (long long * rec , long long * exe , long long * rep , long long * pend );
int64_t tfb_load_csv (const char * path );
int64_t harg (coco_engine * e , size_t t ) {
  { /* let164 */
    int64_t h  = 0;
    // ----------
    if (!coco_m_int (e , t , (&h )))
      return -1;
    if (!tfb_exists (h ))
      return -1;
    return h ;
  }
}
int numarg (coco_engine * e , size_t t , double * out ) {
  { /* let171 */
    double v  = 0.0;
    int64_t iv  = 0;
    // ----------
    if (coco_m_float (e , t , (&v )))
      { /* block175 */
        (*out ) = v ;
        return 1;
      }
    if (coco_m_int (e , t , (&iv )))
      { /* block179 */
        (*out ) = ((double)iv );
        return 1;
      }
    return 0;
  }
}
int shape_arg (coco_engine * e , size_t t , int64_t * out ) {
  { /* let182 */
    size_t * cells  = NULL ;
    size_t n  = 0;
    size_t i  = 0;
    int ok  = 1;
    // ----------
    if (!coco_m_list_array (e , t , (&cells ), (&n )))
      return -1;
    if (n  >  8 )
      { /* block188 */
        free (((void *)cells ));
        return -1;
      }
    while ((i  <  n  )) {
        { /* let192 */
          int64_t v  = 0;
          // ----------
          if (!coco_m_int (e , cells [i ], (&v )))
            ok  = 0;
          else
            out [i ] = v ;
        }
        i  = (i  +  1 );
    }
    free (((void *)cells ));
    if (!ok )
      return -1;
    return ((int)n );
  }
}
int handles_arg (coco_engine * e , size_t t , int64_t * out ) {
  { /* let200 */
    size_t * cells  = NULL ;
    size_t n  = 0;
    size_t i  = 0;
    int ok  = 1;
    // ----------
    if (!coco_m_list_array (e , t , (&cells ), (&n )))
      return -1;
    if (n  >  64 )
      { /* block206 */
        free (((void *)cells ));
        return -1;
      }
    while ((i  <  n  )) {
        { /* let210 */
          int64_t h  = harg (e , cells [i ]);
          // ----------
          if (h  <  0 )
            ok  = 0;
          else
            out [i ] = h ;
        }
        i  = (i  +  1 );
    }
    free (((void *)cells ));
    if (!ok )
      return -1;
    return ((int)n );
  }
}
int refuse (coco_engine * e , size_t g ) {
  return coco_m_domain_error (e , tfb_error (), g );
}
int answer (coco_engine * e , size_t g , uint32_t i , int64_t h ) {
  if (h  <  0 )
    return refuse (e , g );
  return coco_m_unify_int (e , coco_m_arg (e , g , i ), h );
}
int p_from_list (coco_engine * e , size_t g ) {
  { /* let222 */
    size_t lt  = coco_m_arg (e , g , 0);
    size_t * rows  = NULL ;
    size_t nrows  = 0;
    // ----------
    if (!coco_m_list_array (e , lt , (&rows ), (&nrows )))
      return coco_m_type_error (e , "list", lt );
    if (nrows  ==  0 )
      { /* block228 */
        if (rows  !=  NULL  )
          free (((void *)rows ));
        return coco_m_domain_error (e , "non_empty_list", lt );
      }
    { /* let232 */
      double probe  = 0.0;
      int64_t iprobe  = 0;
      // ----------
      if (coco_m_float (e , rows [0], (&probe )) ||  coco_m_int (e , rows [0], (&iprobe )) )
        { /* let236 */
          double * data  = ((double *)malloc ((nrows  *  sizeof(double) )));
          int64_t * idata  = ((int64_t *)malloc ((nrows  *  sizeof(int64_t) )));
          int allint  = 1;
          int ok  = 1;
          size_t i  = 0;
          // ----------
          while ((i  <  nrows  )) {
              { /* let240 */
                double v  = 0.0;
                int64_t iv  = 0;
                // ----------
                if (coco_m_int (e , rows [i ], (&iv ))) {
                    data [i ] = ((double)iv );
                    idata [i ] = iv ;
                }
                else if (coco_m_float (e , rows [i ], (&v ))) {
                    data [i ] = v ;
                    allint  = 0;
                }
                else if (true ) {
                    ok  = 0;
                }
              }
              i  = (i  +  1 );
          }
          free (((void *)rows ));
          if (!ok )
            { /* block248 */
              free (((void *)data ));
              free (((void *)idata ));
              return coco_m_type_error (e , "number", lt );
            }
          { /* let250 */
            int64_t h  = 0;
            int64_t shape [1];
            // ----------
            shape [0] = ((int64_t)nrows );
            if (allint )
              h  = tfb_from_ints (idata , ((int64_t)nrows ));
            else
              h  = tfb_from_doubles (data , shape , 1);
            free (((void *)data ));
            free (((void *)idata ));
            return answer (e , g , 1, h );
          }
        }
      else
        { /* let256 */
          size_t * cols  = NULL ;
          size_t ncols  = 0;
          // ----------
          if (!coco_m_list_array (e , rows [0], (&cols ), (&ncols )))
            { /* block260 */
              free (((void *)rows ));
              return coco_m_type_error (e , "tensor_data", lt );
            }
          if (cols  !=  NULL  )
            free (((void *)cols ));
          { /* let264 */
            double * data  = ((double *)malloc (((nrows  *  ncols  ) *  sizeof(double) )));
            int ok  = 1;
            size_t r  = 0;
            // ----------
            while ((r  <  nrows  )) {
                { /* let268 */
                  size_t * cs  = NULL ;
                  size_t nc  = 0;
                  // ----------
                  if ((!coco_m_list_array (e , rows [r ], (&cs ), (&nc ))) ||  (nc  !=  ncols  ) )
                    ok  = 0;
                  else
                    { /* let273 */
                      size_t c  = 0;
                      // ----------
                      while ((c  <  nc  )) {
                          if (!numarg (e , cs [c ], (&data [((r  *  ncols  ) +  c  )])))
                            ok  = 0;
                          c  = (c  +  1 );
                      }
                    }
                  if (cs  !=  NULL  )
                    free (((void *)cs ));
                }
                r  = (r  +  1 );
            }
            free (((void *)rows ));
            if (!ok )
              { /* block283 */
                free (((void *)data ));
                return coco_m_type_error (e , "tensor_data", lt );
              }
            { /* let285 */
              int64_t shape [2];
              int64_t h  = 0;
              // ----------
              shape [0] = ((int64_t)nrows );
              shape [1] = ((int64_t)ncols );
              h  = tfb_from_doubles (data , shape , 2);
              free (((void *)data ));
              return answer (e , g , 1, h );
            }
          }
        }
    }
  }
}
int values_list (coco_engine * e , int64_t h , size_t * out ) {
  { /* let288 */
    int64_t n  = 0;
    int64_t shape [8];
    int nd  = 0;
    double * buf  = tfb_values (h , (&n ), shape , (&nd ));
    coco_machine * m  = coco_m_machine (e );
    int isint  = tfb_is_int (h );
    // ----------
    if (buf  ==  NULL  )
      return 0;
    { /* let292 */
      size_t * cells  = ((size_t *)malloc ((((size_t)(((n  >  0 )) ? n  : 1)) *  sizeof(size_t) )));
      int64_t i  = 0;
      // ----------
      while ((i  <  n  )) {
          if (isint )
            cells [i ] = coco_new_int (m , ((int64_t)buf [i ]));
          else
            cells [i ] = coco_new_float (m , buf [i ]);
          i  = (i  +  1 );
      }
      if ((nd  ==  2 ) &&  (shape [1] >  0 ) )
        { /* let301 */
          int64_t nr  = shape [0];
          int64_t nc  = shape [1];
          size_t * rcells  = ((size_t *)malloc ((((size_t)(((nr  >  0 )) ? nr  : 1)) *  sizeof(size_t) )));
          int64_t r  = 0;
          // ----------
          while ((r  <  nr  )) {
              rcells [r ] = coco_m_list (e , (&cells [(r  *  nc  )]), ((size_t)nc ));
              r  = (r  +  1 );
          }
          (*out ) = coco_m_list (e , rcells , ((size_t)nr ));
          free (((void *)rcells ));
        }
      else
        (*out ) = coco_m_list (e , cells , ((size_t)n ));
      free (((void *)cells ));
      free (((void *)buf ));
      return 1;
    }
  }
}
int p_to_list (coco_engine * e , size_t g ) {
  { /* let307 */
    int64_t h  = harg (e , coco_m_arg (e , g , 0));
    size_t lst  = 0;
    // ----------
    if (h  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (!values_list (e , h , (&lst )))
      return refuse (e , g );
    return coco_m_unify (e , coco_m_arg (e , g , 1), lst );
  }
}
int p_item (coco_engine * e , size_t g ) {
  { /* let314 */
    int64_t h  = harg (e , coco_m_arg (e , g , 0));
    int64_t n  = 0;
    int64_t shape [8];
    int nd  = 0;
    // ----------
    if (h  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    { /* let318 */
      double * buf  = tfb_values (h , (&n ), shape , (&nd ));
      // ----------
      if (buf  ==  NULL  )
        return refuse (e , g );
      if (n  !=  1 )
        { /* block324 */
          free (((void *)buf ));
          return coco_m_domain_error (e , "scalar_tensor", coco_m_arg (e , g , 0));
        }
      { /* let326 */
        double v  = buf [0];
        // ----------
        free (((void *)buf ));
        return coco_m_unify_float (e , coco_m_arg (e , g , 1), v );
      }
    }
  }
}
int p_shape (coco_engine * e , size_t g ) {
  { /* let329 */
    int64_t h  = harg (e , coco_m_arg (e , g , 0));
    int64_t shape [8];
    int nd  = 0;
    coco_machine * m  = coco_m_machine (e );
    // ----------
    if (h  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (!tfb_shape (h , shape , (&nd )))
      return refuse (e , g );
    { /* let335 */
      size_t cells [8];
      int i  = 0;
      // ----------
      while ((i  <  nd  )) {
          cells [i ] = coco_new_int (m , shape [i ]);
          i  = (i  +  1 );
      }
      return coco_m_unify (e , coco_m_arg (e , g , 1), coco_m_list (e , cells , ((size_t)nd )));
    }
  }
}
int p_new (coco_engine * e , size_t g ) {
  { /* let340 */
    int64_t shape [8];
    int nd  = shape_arg (e , coco_m_arg (e , g , 0), shape );
    const char * kind  = coco_m_atom (e , coco_m_arg (e , g , 1));
    // ----------
    if (nd  <  1 )
      return coco_m_type_error (e , "shape", coco_m_arg (e , g , 0));
    if (kind  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 1));
    if (0 ==  strcmp (kind , "zeros") ) {
        return answer (e , g , 2, tfb_fill (shape , nd , 0.0));
    }
    else if (0 ==  strcmp (kind , "ones") ) {
        return answer (e , g , 2, tfb_fill (shape , nd , 1.0));
    }
    else if (0 ==  strcmp (kind , "randn") ) {
        return answer (e , g , 2, tfb_random (shape , nd , 1));
    }
    else if (0 ==  strcmp (kind , "rand") ) {
        return answer (e , g , 2, tfb_random (shape , nd , 0));
    }
    else if (true ) {
        return coco_m_domain_error (e , "tensor_kind", coco_m_arg (e , g , 1));
    }
  }
}
int p_full (coco_engine * e , size_t g ) {
  { /* let353 */
    int64_t shape [8];
    int nd  = shape_arg (e , coco_m_arg (e , g , 0), shape );
    double v  = 0.0;
    // ----------
    if (nd  <  1 )
      return coco_m_type_error (e , "shape", coco_m_arg (e , g , 0));
    if (!numarg (e , coco_m_arg (e , g , 1), (&v )))
      return coco_m_type_error (e , "number", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_fill (shape , nd , v ));
  }
}
int p_by_count (coco_engine * e , size_t g , int which ) {
  { /* let360 */
    int64_t n  = 0;
    // ----------
    if (!coco_m_int (e , coco_m_arg (e , g , 0), (&n )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 0));
    if (n  <  1 )
      return coco_m_domain_error (e , "positive_integer", coco_m_arg (e , g , 0));
    if (which  ==  0 ) {
        return answer (e , g , 1, tfb_eye (n ));
    }
    else if (which  ==  1 ) {
        return answer (e , g , 1, tfb_arange (n ));
    }
    else if (true ) {
        return answer (e , g , 1, tfb_randperm (n ));
    }
  }
}
int p_unary (coco_engine * e , size_t g ) {
  { /* let371 */
    const char * op  = coco_m_atom (e , coco_m_arg (e , g , 0));
    int64_t a  = harg (e , coco_m_arg (e , g , 1));
    // ----------
    if (op  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_unary (op , a ));
  }
}
int p_binary (coco_engine * e , size_t g ) {
  { /* let378 */
    const char * op  = coco_m_atom (e , coco_m_arg (e , g , 0));
    int64_t a  = harg (e , coco_m_arg (e , g , 1));
    int64_t b  = harg (e , coco_m_arg (e , g , 2));
    // ----------
    if (op  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if ((a  <  0 ) ||  (b  <  0 ) )
      return coco_m_domain_error (e , "tensor", g );
    return answer (e , g , 3, tfb_binary (op , a , b ));
  }
}
int p_scalar (coco_engine * e , size_t g ) {
  { /* let385 */
    const char * op  = coco_m_atom (e , coco_m_arg (e , g , 0));
    int64_t a  = harg (e , coco_m_arg (e , g , 1));
    double v  = 0.0;
    // ----------
    if (op  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 1));
    if (!numarg (e , coco_m_arg (e , g , 2), (&v )))
      return coco_m_type_error (e , "number", coco_m_arg (e , g , 2));
    return answer (e , g , 3, tfb_scalar (op , a , v ));
  }
}
int p_agg (coco_engine * e , size_t g ) {
  { /* let394 */
    const char * op  = coco_m_atom (e , coco_m_arg (e , g , 0));
    int64_t a  = harg (e , coco_m_arg (e , g , 1));
    // ----------
    if (op  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_agg (op , a ));
  }
}
int p_reduce (coco_engine * e , size_t g ) {
  { /* let401 */
    const char * op  = coco_m_atom (e , coco_m_arg (e , g , 0));
    int64_t a  = harg (e , coco_m_arg (e , g , 1));
    // ----------
    if (op  ==  NULL  )
      return coco_m_type_error (e , "atom", coco_m_arg (e , g , 0));
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 1));
    { /* let407 */
      int64_t r  = tfb_agg (op , a );
      int64_t n  = 0;
      int64_t shape [8];
      int nd  = 0;
      // ----------
      if (r  <  0 )
        return refuse (e , g );
      { /* let411 */
        double * buf  = tfb_values (r , (&n ), shape , (&nd ));
        // ----------
        tfb_free (r );
        if (buf  ==  NULL  )
          return refuse (e , g );
        { /* let415 */
          double v  = buf [0];
          // ----------
          free (((void *)buf ));
          return coco_m_unify_float (e , coco_m_arg (e , g , 2), v );
        }
      }
    }
  }
}
int p_argmax (coco_engine * e , size_t g ) {
  { /* let418 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    int64_t dim  = 0;
    // ----------
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (!coco_m_int (e , coco_m_arg (e , g , 1), (&dim )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_argmax (a , dim ));
  }
}
int p_reshape (coco_engine * e , size_t g ) {
  { /* let425 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    int64_t shape [8];
    int nd  = shape_arg (e , coco_m_arg (e , g , 1), shape );
    // ----------
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (nd  <  1 )
      return coco_m_type_error (e , "shape", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_reshape (a , shape , nd ));
  }
}
int p_cat (coco_engine * e , size_t g ) {
  { /* let432 */
    int64_t hs [64];
    int n  = handles_arg (e , coco_m_arg (e , g , 0), hs );
    int64_t dim  = 0;
    // ----------
    if (n  <  1 )
      return coco_m_type_error (e , "tensor_list", coco_m_arg (e , g , 0));
    if (!coco_m_int (e , coco_m_arg (e , g , 1), (&dim )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_cat (hs , n , dim ));
  }
}
int p_index_rows (coco_engine * e , size_t g ) {
  { /* let439 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    int64_t i  = harg (e , coco_m_arg (e , g , 1));
    // ----------
    if ((a  <  0 ) ||  (i  <  0 ) )
      return coco_m_domain_error (e , "tensor", g );
    return answer (e , g , 2, tfb_gather (a , i ));
  }
}
int p_slice (coco_engine * e , size_t g , int axis ) {
  { /* let444 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    int64_t from  = 0;
    int64_t to  = 0;
    // ----------
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if ((!coco_m_int (e , coco_m_arg (e , g , 1), (&from ))) ||  (!coco_m_int (e , coco_m_arg (e , g , 2), (&to ))) )
      return coco_m_type_error (e , "integer", g );
    return answer (e , g , 3, tfb_slice (a , axis , from , to ));
  }
}
int p_standardise (coco_engine * e , size_t g ) {
  { /* let451 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    int64_t n  = 0;
    // ----------
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (!coco_m_int (e , coco_m_arg (e , g , 1), (&n )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 1));
    return answer (e , g , 2, tfb_standardise (a , n ));
  }
}
int p_parameter (coco_engine * e , size_t g ) {
  { /* let458 */
    int64_t a  = harg (e , coco_m_arg (e , g , 0));
    // ----------
    if (a  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    return answer (e , g , 1, tfb_parameter (a ));
  }
}
int p_step (coco_engine * e , size_t g ) {
  { /* let463 */
    int64_t w  = harg (e , coco_m_arg (e , g , 0));
    int64_t gr  = harg (e , coco_m_arg (e , g , 1));
    double lr  = 0.0;
    // ----------
    if ((w  <  0 ) ||  (gr  <  0 ) )
      return coco_m_domain_error (e , "tensor", g );
    if (!numarg (e , coco_m_arg (e , g , 2), (&lr )))
      return coco_m_type_error (e , "number", coco_m_arg (e , g , 2));
    return answer (e , g , 3, tfb_step (w , gr , lr ));
  }
}
int p_grad (coco_engine * e , size_t g ) {
  { /* let470 */
    int64_t loss  = harg (e , coco_m_arg (e , g , 0));
    int64_t ps [64];
    int64_t gs [64];
    int n  = handles_arg (e , coco_m_arg (e , g , 1), ps );
    coco_machine * m  = coco_m_machine (e );
    // ----------
    if (loss  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (n  <  0 )
      return coco_m_type_error (e , "tensor_list", coco_m_arg (e , g , 1));
    if (!tfb_grad (loss , ps , n , gs ))
      return refuse (e , g );
    { /* let478 */
      size_t cells [64];
      int i  = 0;
      // ----------
      while ((i  <  n  )) {
          cells [i ] = coco_new_int (m , gs [i ]);
          i  = (i  +  1 );
      }
      return coco_m_unify (e , coco_m_arg (e , g , 2), coco_m_list (e , cells , ((size_t)n )));
    }
  }
}
int p_free (coco_engine * e , size_t g ) {
  { /* let483 */
    int64_t h  = 0;
    // ----------
    if (!coco_m_int (e , coco_m_arg (e , g , 0), (&h )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 0));
    return tfb_free (h );
  }
}
int p_force (coco_engine * e , size_t g ) {
  { /* let488 */
    int64_t h  = harg (e , coco_m_arg (e , g , 0));
    // ----------
    if (h  <  0 )
      return coco_m_domain_error (e , "tensor", coco_m_arg (e , g , 0));
    if (!tfb_force (h ))
      return refuse (e , g );
    return 1;
  }
}
int p_stats (coco_engine * e , size_t g ) {
  { /* let495 */
    long long rec  = 0;
    long long exe  = 0;
    long long rep  = 0;
    long long pend  = 0;
    coco_machine * m  = coco_m_machine (e );
    size_t args [4];
    // ----------
    tfb_stats ((&rec ), (&exe ), (&rep ), (&pend ));
    args [0] = coco_make1 (m , "recorded", coco_new_int (m , ((int64_t)rec )));
    args [1] = coco_make1 (m , "executed", coco_new_int (m , ((int64_t)exe )));
    args [2] = coco_make1 (m , "replayed", coco_new_int (m , ((int64_t)rep )));
    args [3] = coco_make1 (m , "pending", coco_new_int (m , ((int64_t)pend )));
    return coco_m_unify (e , coco_m_arg (e , g , 0), coco_make (m , "stats", 4, args ));
  }
}
int p_load_csv (coco_engine * e , size_t g ) {
  { /* let498 */
    char path [4096];
    // ----------
    if (!coco_m_text (e , coco_m_arg (e , g , 0), path , 4096))
      return coco_m_type_error (e , "text", coco_m_arg (e , g , 0));
    return answer (e , g , 1, tfb_load_csv (path ));
  }
}
int p_seed (coco_engine * e , size_t g ) {
  { /* let503 */
    int64_t s  = 0;
    // ----------
    if (!coco_m_int (e , coco_m_arg (e , g , 0), (&s )))
      return coco_m_type_error (e , "integer", coco_m_arg (e , g , 0));
    tfb_seed (s );
    return 1;
  }
}
int p_version (coco_engine * e , size_t g ) {
  { /* let508 */
    coco_machine * m  = coco_m_machine (e );
    // ----------
    return coco_m_unify (e , coco_m_arg (e , g , 0), coco_new_atom (m , tfb_version ()));
  }
}
int tf_backend_dispatch (coco_engine * e , const char * name , uint32_t arity , size_t g , int * found ) {
  (*found ) = 1;
  if (arity  ==  1 ) {
      if (0 ==  strcmp (name , "tensor_free") ) {
          return p_free (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_force") ) {
          return p_force (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_graph_stats") ) {
          return p_stats (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  2 ) {
      if (0 ==  strcmp (name , "tensor_from_list") ) {
          return p_from_list (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_to_list") ) {
          return p_to_list (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_shape") ) {
          return p_shape (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_item") ) {
          return p_item (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_eye") ) {
          return p_by_count (e , g , 0);
      }
      else if (0 ==  strcmp (name , "tensor_arange") ) {
          return p_by_count (e , g , 1);
      }
      else if (0 ==  strcmp (name , "tensor_randperm") ) {
          return p_by_count (e , g , 2);
      }
      else if (0 ==  strcmp (name , "tensor_parameter") ) {
          return p_parameter (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_load_csv") ) {
          return p_load_csv (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  3 ) {
      if (0 ==  strcmp (name , "tensor_unary") ) {
          return p_unary (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_new") ) {
          return p_new (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_full") ) {
          return p_full (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_agg") ) {
          return p_agg (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_reduce") ) {
          return p_reduce (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_argmax") ) {
          return p_argmax (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_reshape") ) {
          return p_reshape (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_cat") ) {
          return p_cat (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_index_rows") ) {
          return p_index_rows (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_standardise") ) {
          return p_standardise (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_grad") ) {
          return p_grad (e , g );
      }
      else if (true ) {
          (*found ) = 0;
          return 0;
      }
  }
  else if (arity  ==  4 ) {
      if (0 ==  strcmp (name , "tensor_binary") ) {
          return p_binary (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_scalar") ) {
          return p_scalar (e , g );
      }
      else if (0 ==  strcmp (name , "tensor_rows") ) {
          return p_slice (e , g , 0);
      }
      else if (0 ==  strcmp (name , "tensor_cols") ) {
          return p_slice (e , g , 1);
      }
      else if (0 ==  strcmp (name , "tensor_step") ) {
          return p_step (e , g );
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
int tf_module_dispatch (coco_engine * e , const char * name , uint32_t arity , size_t g , int * found ) {
  (*found ) = 1;
  if (arity  ==  1 )
    if (0 ==  strcmp (name , "tensorflow_version") ) {
        return p_version (e , g );
    }
    else if (0 ==  strcmp (name , "tensorflow_seed") ) {
        return p_seed (e , g );
    }
  (*found ) = 0;
  return 0;
}
int coco_library_entry () {
  if (!tfb_attach (tf_backend_dispatch ))
    { /* block562 */
      fprintf (stderr , "cocolog: library(tensorflow): %s\n", tfb_error ());
      return 0;
    }
  if (!coco_module_register ("tensorflow", tf_module_dispatch , NULL , NULL ))
    return 0;
  return 1;
}
