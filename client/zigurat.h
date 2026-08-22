/* zigurat.h -- a Zigurat client for C, with no C++ in it.
 *
 * WHY THIS EXISTS. Connector/ is the client, and it is C++: std::string in the
 * signatures, templates over the Type classes, exceptions for errors. A C
 * program cannot call it, and a C program that wants to would have to link the
 * C++ runtime and wrap every entry point. This is the same protocol spoken
 * straight from C: one .h, one .c, libc and the sockets API and nothing else.
 *
 * It was written for cocolog -- a Prolog interpreter that keeps its knowledge
 * base in Zigurat and is compiled from Cicili to C -- but there is nothing
 * about it that is specific to that.
 *
 * WHAT IT IS NOT. It does not do TLS. Connector/ does, through this project's
 * own TLS implementation, which is C++; a C client that needed an encrypted
 * connection would have to bring one. Use this inside a trust boundary, or put
 * a tunnel in front of it.
 *
 * ERRORS ARE RETURN CODES, not exceptions: every call answers 1 for success
 * and 0 for failure, and zg_error() then says what went wrong.
 *
 * A failure that the SERVER reported -- a suite that will not compile, a
 * procedure that threw -- leaves the connection in step and usable: the
 * message is read off the wire as part of reporting it. A failure in the
 * TRANSPORT does not, and neither does one this client raises after it has
 * started writing: the protocol is a stream, and a call that stopped half way
 * through has left bytes in it that the next call would read as its own. The
 * length limits below are therefore all checked BEFORE anything goes out, so
 * an over-long value is a failure you can carry on from.
 *
 * THE WIRE, for anyone maintaining this against the C++ side:
 *
 *   integers   native size, NETWORK byte order -- big-endian, including
 *              doubles. StreamIO has two stream families and the socket uses
 *              the reversing one: SocketIO/tcpstream.hpp is
 *              `class tcpstream : public nbostream'. (hbostream, which does
 *              NOT reorder, is for files and buffers -- reading that one by
 *              mistake costs an afternoon, because the symptom is a hang in a
 *              call that has a Text in it and nothing else looks wrong.)
 *   string     uint8 length, then that many bytes. 255 is the limit, and it is
 *              a hard one: the C++ side truncates the length to a byte rather
 *              than failing, so a longer value is silently cut.
 *   text       uint16 length, then the bytes. 65535, same caveat.
 *   field      a type-descriptor byte, then the value -- unless the high bit
 *              of that byte is set, which means NULL and no value follows.
 *
 * A CONVERSATION:
 *
 *   connect                       -> server sends a size_t transaction id
 *   write string "call"           -> server sends a result byte
 *   write string "demo::proc"     -> server sends a result byte
 *   write the IN parameters as fields
 *   read results until SUCCESSFUL_DONE
 *
 * Reading the results is not optional. What is left unread stays in the
 * stream, and the next call reads it instead of its own reply.
 */

#ifndef ZIGURAT_C_H
#define ZIGURAT_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Matches Connector/resulttype.hpp. */
typedef enum {
  ZG_SUCCESSFUL_DONE   = 0,
  ZG_CURSOR_OPEN       = 1,
  ZG_CURSOR_FETCH      = 2,
  ZG_CURSOR_CLOSE      = 3,
  ZG_RETURN_VALUE      = 4,
  ZG_EXCEPTION_THROWN  = 5
} zg_result_t;

/* Matches MVCCS/isolationlevel.hpp. */
typedef enum {
  ZG_READ_UNCOMMITTED = 0,
  ZG_READ_COMMITTED   = 1,
  ZG_REPEATABLE_READ  = 2,
  ZG_SNAPSHOT         = 3,
  ZG_SERIALIZABLE     = 4
} zg_isolation_t;

/* What the WIRE can carry in one value. Longer than this and the C++ side
 * truncates the length rather than complaining, so this client refuses
 * instead: a silently shortened knowledge base is worse than a failed call.
 *
 * WHAT A COLUMN WILL HOLD IS SMALLER, and the protocol does not know it. A row
 * has to fit in a page, and MVCCS/PAGE_SIZE is 8192 by default -- a Text of
 * 8000 stores, one of 8192 comes back as "allocation overflow". Anything
 * putting large values in a table should chunk them well under the page size
 * rather than up to ZG_MAX_TEXT. */
#define ZG_MAX_STRING 255u
#define ZG_MAX_TEXT   65535u

typedef struct zg_conn zg_conn;

/* Connects and reads the transaction id the server opens with. Answers NULL on
 * failure; ERR, if given, is filled with the reason. TIMEOUT_SECONDS of 0
 * means no timeout. */
zg_conn *zg_open(const char *host, const char *service, int timeout_seconds,
                 char *err, size_t errcap);

void zg_close(zg_conn *c);
int  zg_is_open(const zg_conn *c);

/* Dials again down the SAME zg_conn, so every pointer to it stays valid.
 *
 * WHY THIS EXISTS AND zg_close/zg_open WOULD NOT DO. A server-side exception
 * ends the connection (see zg_result), and under concurrent access ZiguratIP
 * raises transient ones -- so a worker that means to keep going has to redial.
 * By then the connection has been handed to things that hold it: a co_zg
 * knowledge-base backend keeps the pointer it was attached with. Closing and
 * opening would give a new pointer and leave every one of those dangling, so
 * this reuses the object and only replaces the socket underneath it.
 *
 * Answers 1, or 0 with the reason in zg_error. Whatever the old connection had
 * open -- its transaction included -- is gone either way: this is recovery,
 * not resumption. */
int zg_reopen(zg_conn *c, const char *host, const char *service,
              int timeout_seconds);

/* Makes this connection take turns with every other process using the same
 * PATH, so that no two of them are inside the server's storage engine at once.
 * WAIT_SECONDS bounds how long a call will wait for its turn; 0 means wait for
 * as long as it takes. Answers 1, or 0 with the reason in zg_error.
 *
 * WHY A CLIENT HAS TO DO THIS. ZiguratIP serves each connection on its own
 * thread and gives each thread its own transaction -- Memory::transaction is
 * `static thread_local' -- but the two streams a transaction reads and writes
 * through, MVCCS/memory.hpp's `_hexmap_io' and `_data_io', are one pair shared
 * by all of them. Memory::_pointer seeks one of them and then reads it, and
 * takes no lock over the pair (Memory::truncate, on the same streams, takes
 * both _hexmap_access and _data_access). Two threads in there at once
 * therefore read from each other's file position. What comes back is
 * `hexmap ends inside the chunk at NNNNN' -- and with four clients it is
 * sometimes worse than an exception: the server dies and takes the store with
 * it. Measured, repeatedly, with a program that does nothing but claim and
 * release a row.
 *
 * ZiguratIP IS NOT OURS TO FIX -- cocolog uses it and does not modify it -- so
 * cocolog stays out of the way instead. The lock is held for the length of one
 * CALL and not for a transaction: the server's thread is blocked reading the
 * socket between calls and is not in the engine then, so serialising the calls
 * is enough to keep the engine single-threaded while leaving the interpreters
 * to run at the same time as each other. Which is the point: four
 * interpreters, proving concurrently, taking turns only on the wire.
 *
 * flock(2) is what it is built on, so it holds between processes on one
 * machine and is released by the kernel if one of them dies -- a worker killed
 * mid-call cannot wedge the rest. Workers on DIFFERENT machines share no such
 * file and this does nothing for them; see STATUS.md. */
int zg_serialise(zg_conn *c, const char *path, int wait_seconds);

/* The last failure on this connection, or "" if there has not been one. */
const char *zg_error(const zg_conn *c);

/* The transaction the server opened when this connection was made. With the
 * shipped NON-AUTOCOMMIT setting the transaction IS the connection: everything
 * done down it is one transaction until commit or rollback. */
uint64_t zg_transaction_id(const zg_conn *c);

/* ---- verbs ---- */

/* Round-trips TEXT through the server. The cheapest proof that a connection
 * works, and what the test uses first. */
int zg_echo(zg_conn *c, const char *text, char *out, size_t outcap);

/* Compiles a Parsi suite -- TABLE, SEQUENCE, PROCEDURE, CLASS, PAGE, TYPE,
 * ENUM declarations. A bare statement is not a suite and comes back as an
 * error. Limited to ZG_MAX_TEXT. */
int zg_compile(zg_conn *c, const char *suite);

/* Names the procedure to run. The IN parameters go out after this, as fields,
 * and then the results are read. */
int zg_call(zg_conn *c, const char *procedure);

int zg_auto_commit(zg_conn *c, int on);
int zg_isolate(zg_conn *c, zg_isolation_t level);
int zg_commit(zg_conn *c);
int zg_rollback(zg_conn *c);

/* Reads the next result byte. An EXCEPTION_THROWN is turned into a failure
 * with the server's message in zg_error(), and the exception's message is
 * consumed -- so the stream is left in step and the connection may be used
 * again. */
int zg_result(zg_conn *c, zg_result_t *out);

/* After CURSOR_OPEN: the column names, comma separated. */
int zg_columns(zg_conn *c, char *out, size_t outcap);

/* Reads results until SUCCESSFUL_DONE, throwing the rows away. Use it when a
 * procedure's output does not matter but the stream still has to be left
 * clean. Rows are skipped by COLUMN COUNT, so the caller must say how many
 * fields a fetched row has -- the protocol does not carry that. Pass 0 when
 * the procedure produces no cursor. */
int zg_drain(zg_conn *c, unsigned row_fields);

/* ---- writing parameters ---- */

int zg_write_bool(zg_conn *c, int v);
int zg_write_int(zg_conn *c, int32_t v);
int zg_write_long(zg_conn *c, int64_t v);
int zg_write_double(zg_conn *c, double v);
int zg_write_string(zg_conn *c, const char *s);   /* up to ZG_MAX_STRING */
int zg_write_text(zg_conn *c, const char *s);     /* up to ZG_MAX_TEXT   */

/* ---- reading fields ---- */
/* IS_NULL may be NULL if the caller does not care; a null field leaves the
 * value untouched. A string or text that does not fit is an error rather than
 * a truncation. */

int zg_read_bool(zg_conn *c, int *v, int *is_null);
int zg_read_int(zg_conn *c, int32_t *v, int *is_null);
int zg_read_long(zg_conn *c, int64_t *v, int *is_null);
int zg_read_double(zg_conn *c, double *v, int *is_null);
int zg_read_string(zg_conn *c, char *buf, size_t cap, int *is_null);
int zg_read_text(zg_conn *c, char *buf, size_t cap, int *is_null);

/* Reads a Text field into a buffer this call allocates. The caller frees it.
 * Text is the only field big enough to be worth not putting on the stack. */
int zg_read_text_alloc(zg_conn *c, char **out, size_t *len, int *is_null);

/* Skips one field of any type, reading exactly as many bytes as its
 * type-descriptor byte says it has. This is what makes zg_drain able to walk
 * past a row it does not want without knowing the column types. */
int zg_skip_field(zg_conn *c);

#ifdef __cplusplus
}
#endif

#endif /* ZIGURAT_C_H */
