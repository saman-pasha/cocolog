# Status

Where this stands, what is proven, and what is not. Written to be picked up
again rather than to look finished.

## Done and tested

`make test` ends `red: 0`. The database suites **skip** rather than fail when
there is no server, because "no server here" and "the backend is wrong" are
different findings.

| suite | what it establishes |
|---|---|
| `test/term.cicili` | interning, unification, the trail undoing exactly, copying that renames consistently, the standard order, and the term DSL — 27 checks |
| `test/syntax.cicili` | the reader and the writer against each other: precedence, associativity, the spacing that decides whether `-(1)` reads back as a compound or an integer, lists, curly terms, quoting, radix and character literals — 41 checks |
| `test/solve.cicili` | backtracking, cut, negation, if-then-else, arithmetic, lists, term inspection, assert/retract, `:- dynamic` in all three spec shapes and as a goal, `listing`, a 50000-deep deterministic recursion that must leave no choice points, and a failing goal that must not grow the heap |
| `test/module.cicili` | the module seam itself: no modules behaves as before modules, three at once, a module's Coco half calling its own C half, a module that is only clauses, precedence against both builtins and the knowledge base, a failing module predicate leaving no binding, and the Coco half coming back after the store is emptied — 22 checks |
| `test/files/*.pl` | the Files, Lists, Apply, Builtins and DCG libraries — and SWI's own `dcg/basics` and `dcg/high_order`, unedited — run by **both swipl and cocolog** in the same fresh directory and compared byte for byte. 555 lines of agreement across nineteen cases |
| `test/state.cicili` | a machine run to one solution, frozen, its machine and store **freed**, thawed into new ones, and finishing the proof correctly; and `freeze(thaw(x)) == x` byte for byte |
| `test/zigurat.cicili` | the Cicili binding against a real server: every parameter width, a cursor, and a Text large enough to matter |
| `test/shared.cicili` | ten interpreters in sequence — one writes the knowledge base, a second built from nothing answers from it, a third suspends mid-proof and is freed, a fourth picks it up and finishes it, a fifth asserts at run time, a sixth sees it, a seventh retracts, an eighth agrees it is gone, a ninth declares two predicates dynamic and a tenth — which starts knowing nothing — warms its store and finds them declared and empty. Then the same knowledge base over HTTP, and a machine written over the binary protocol picked up over HTTP — 39 checks |
| `test/groups.sh` | **twelve interpreters at once over four machine states** — below |
| `test/ruler.sh` | **one interpreter writing the knowledge base while eight read it** — below |
| `client/probe.c` | the C client against a real server, including a clause made of nothing but the five HTML-escapable characters, asserted over the binary protocol and read back through a page unchanged |
| `test/engine.sh` | the engine's COMPLEXITY, which nothing else here checks: 100 000 solutions from `between/3`, a `findall` over the same range, ten times the work in far less than a hundred times the time, and a 500 000-deep deterministic recursion — with the answers still right, because a representation change that made everything fast and one thing wrong would pass every timing check |
| `test/thread.sh` | `library(thread)`: what a thread can see and what it cannot, what a closed channel does, backpressure, and the two claims that cannot be checked by reading — eight senders putting 800 terms through one channel with all 800 arriving, and four threads doing four times the work in 1.7× the time — 20 checks |
| `test/httpd.sh` | the server: the grammar, routing, path safety, keep-alive and pipelining, the inference fence, the worker pool, pages that reach the KNOWLEDGE BASE from a worker thread with the count taken by a separate process, and the four cases that hold the pool's one rule — a worker serves a page loaded as a MODULE and not one that only reached the parent's store — 63 checks |
| `test/crypto.sh` | ZiguratIP's cryptography and its CA as cocolog predicates, held to FIPS 180, RFC 4231, NIST SP 800-38A and DER's own worked examples where there are vectors, and to a round trip where there are not. The CA is exercised for real -- a key generated, a request made, a certificate issued against the sample authority, validated, signed with and checked -- 74 checks |
| `test/tutorials.sh` | **the documentation, run as a suite**: sixty-five tutorial files in three categories — eleven `basics/` and thirty `library/` proving their own claims through `must/3`, and twenty-four `torch/` networks as three processes each against a store of their own. A lesson that stops being true FAILS and names both answers |
| `test/tls.sh` | `library(tls)`: a server and three clients AS SEPARATE PROCESSES -- enrolled, impostor, browser -- because a handshake is between two ends that do not share memory. The permissions that rode in with alice's certificate, the impostor refused and told why, the server carrying on serving afterwards, a certificate-less client admitted and granted nothing, four bogus handles refusing rather than crashing, and an accept that times out and frees its slot -- 19 checks |
| `test/httpd-tls.sh` | the same server over TLS, and the seam that keeps them one server: routing, keep-alive, the path rules and `httpd_answer/3` are the SAME code on both, and a page reads the peer's subject and permissions as two synthetic headers. Weighted on the reverse-proxy hole -- a client sending `Tls-Peer-Subject: CN=root` must not be believed, and on a plain connection those headers are stripped and not replaced -- 9 checks |
| `test/zigurat-tls.sh` | `--tls`, the binary protocol over TLS, against TWO terminators -- one per `SERVER/TLS_CLIENT_AUTH` setting. The handshake before the greeting, a clause written and read back by two processes over an encrypted connection, the hostname checked and not just the chain, plaintext against a TLS port refused, and all four certificate combinations including the one that must be legible: no certificate where one is required -- 11 checks |
| `test/serialize.sh` | `library(json)`, `library(xml)` and `library(html)`, both directions. Weighted toward escaping and refusals, because those are where a serialiser is silently wrong rather than loudly wrong, and six ROUND TRIPS — write, read, write again, compare the texts — because a reader and a writer that disagree are worse than either alone. 101 checks |

## The three document libraries, and the round trip that checks them

`library(json)`, `library(xml)` and `library(html)` write a term out as a
document and read one back in. All six halves are DCGs; there is no C in any
of them.

**The round trip is what makes the pair honest.** Hand-written expectations
on a writer and hand-written expectations on a reader can both be satisfied
by two implementations that disagree with each other. Writing a document,
reading it and writing it again cannot.

Two decisions are worth recording because both were paid for:

**A CODE LIST IS A LIST, AND `str/1` IS THE WAY OUT.** cocolog has no string
type — `double_quotes` is `codes` — so `"hello"` *is* `[104,101,…]` and
nothing in the term says which you meant. The first draft of `xml.pl`
guessed the friendly way and `element(p,[],["hello"])` came out as
`<p>104101108108111</p>`. A bare list is now an array in JSON and an error
in XML and HTML.

**AN INTEGER PAST 64 BITS IS REFUSED, NOT WRAPPED.** `number_codes/2`
answers `-1` for a twenty-digit literal and complains about nothing, so the
parser writes the digits back and compares. A silently wrong balance is the
worst thing a JSON parser can do.

`library(xml)` skips the DOCTYPE — internal subset and all — and has no code
that could open a file or a socket, so the XXE family is structurally
impossible rather than defended against. `library(html)` is deliberately
**not** an HTML5 tree builder, and its header says so: a half one produces a
tree that looks right and quietly is not the one a browser built.

## A page reaches the knowledge base, and a request is a turn

The open end this file used to name — *"a worker still has no database"* —
is closed. `coco_m_kb_install` in `lib/module.cicili` is the seam:
`lib/module.cicili` can make a machine and a store but cannot know whether
this process is `--local`, a socket, Zeytun or embedded; the composition
root can, so it installs a pair of hooks and every isolated proof opens a
connection of its own.

**It was not enough to give a worker a connection.** Three sequential POSTs
through a pool of three left **two** facts in the database, reproducibly,
with no concurrency involved at all. A store CACHES — the first proof to ask
for `visit/1` marks the predicate loaded and never asks again — and the
Zigurat backend flushes a dirty predicate WHOLESALE, so the second worker
committed its own stale copy over the first's row.

So a request is a TURN, which is this project's own rule everywhere else:
`run_isolated/2` gives it a fresh machine, a fresh store and a fresh
connection, one commit at the end and a rollback when the goal did not
prove. Connections NEST — the previous one is saved and restored — which is
what lets a worker hold one while each request opens another.

**The cost is one rule, and the failure is silent**: a worker's store is
filled from the process-wide MODULE REGISTRY, so pages must be loaded with
`use_module` rather than consulted, asserted, or written into the file
handed to `cocolog run`. `workers(0)` serves those perfectly well, which is
exactly how it is easy to meet in a demo and lose the moment a pool is
added. Four cases hold both halves.

## ZiguratIP's cryptography, imported rather than rewritten

The question was whether to bind ZiguratIP's crypto and CA or write
them in cocolog as DCGs. **The answer is neither wholesale, and the
line is not "crypto vs CA" -- it is arithmetic, grammar, policy.**

* **ARITHMETIC IS BOUND, NEVER REWRITTEN.** RSA modexp, the AES rounds,
  the SHA compression function. A Prolog implementation is not merely
  slow: it cannot be made constant-time, so a private-key operation
  would leak by timing. There is no hash and no cipher code in any of
  these files -- `Zigurat::SHA` is the one RSA signs with and `Zigurat::AES`
  the one X.509 encrypts key files with, and a second implementation
  would be a second thing to disagree with the first.
* **GRAMMAR IS PROLOG.** `library(der)`'s C++ half knows exactly one
  tag-length-value: read a tag and a length, hand back the content and
  the rest. Walking a sequence of them is a two-clause recursion, and it
  is written as one. Note where the C++ itself gave up: `x509.cpp`
  reaches for OpenSSL's ASN.1 rather than hand-rolling DER.
* **POLICY IS CLAUSES**, and this is the part that is better here than
  in any C++ stack. `ca_may/2` and `ca_covers/2` are four lines you can
  read, `listing/1`, and argue with. A permission system nobody can read
  is a permission system nobody can audit.

Five libraries, all tier 2, none of them prefixed `zigurat_`:

| | is | links |
|---|---|---|
| `library(sha)` | SHA-1/224/256/384/512, HMAC, and a file hashed without being read in | libCryptography |
| `library(aes)` | AES-128/192/256, CBC and ECB, PKCS #7 both ways | libCryptography |
| `library(der)` | DER as terms, both directions | **libEncoding only** |
| `library(x509)` | the whole `ca` tool, plus sign/verify/encrypt/decrypt | libCryptography |
| `library(ca)` | clauses only: roots, enrolment, authorisation | -- |

**`library(der)` LINKS NO CIPHER.** `Zigurat::DER` lives in libEncoding
beside base16/32/64, because it is an encoding and not a secret -- so
everything a certificate is made of can be taken apart with no OpenSSL
in the process at all.

**THE TWO HALVES MEET, and that is the demonstration.** A public key
that came out of C++, read in Prolog:

    ?- x509_public_key('ca.crt', K), der_wrap(48, K, Spki),
       der_decode(Spki, sequence([Alg, bit_string(Bits)])),
       der_decode(Bits, sequence([integer(N), integer(E)])).
    Alg = sequence([oid('1.2.840.113549.1.1.1'), null]),
    N = '13455941168279...'  (617 digits),  E = '65537'.

**A CERTIFICATE BECOMES CLAUSES**, which is the thesis applied to PKI.
An issuer may write permissions into a certificate under ZiguratIP's own
OID arc, and they mean nothing to the certificate: they are matched by
whoever cares. `ca_load/1` turns a signed document into `ca_holder/2`
and `ca_grants/2` facts -- which are ROWS, so another process can ask. A
gateway loads what it trusts at start-up and every later authorisation
is a query against the store rather than a signature check against a
file.

**KEYS ARE FILES, NOT TERMS**, and that is the one decision to preserve.
A private key read into an atom would be on the heap, in the trail, in
every copy a channel made of the term holding it, and in the knowledge
base the moment anything asserted it. This project's whole claim is that
a clause is a row somebody else can read; a signing key is the one thing
that must never become one. `getenv/2` is how a pass phrase arrives, for
the same reason -- the one channel into a program that does not pass
through the store.

### `library(tls)`: the connection the certificates were for

**"cocolog has no stream layer" WAS THE WRONG OBJECTION**, and this
section replaces the one that said so. `Zigurat::tlsstream` is a C++
iostream and there is genuinely nothing in cocolog to hand one to -- but
nothing has to be. **The stream stays inside the module for its whole
life and what crosses into Prolog is an INDEX INTO A TABLE**, which is
exactly what `library(tcp)` does with a descriptor. A TLS connection is
no more a term than a socket is.

So `modules/tls` is `modules/tcp`'s shape with a handshake in front of
it: 256 slots, each a listener or a connection, and a handle that is a
slot rather than a pointer. Underneath it is real OpenSSL -- TLS 1.2 at
the lowest, ECDHE and AEAD, `!kRSA` so static key transport cannot be
negotiated at all, no record compression. None of that is decided here;
it is `SocketIO/tlsbuf.cpp`, and this module offers no way to weaken it.

**THE PERMISSIONS ARRIVE WITH THE HANDSHAKE**, which is the part that
makes this more than a socket:

    Peer    = '127.0.0.1:34844',
    Who     = 'C=IR, O=Coco, CN=alice, emailAddress=alice@example.org',
    Granted = [read, 'ledger.write'].

They were written into alice's certificate by an issuer and checked
against the authority before a byte moved. So a server does not
authenticate its peer -- that already happened -- and what is left is
AUTHORISATION, which is a `library(ca)` rule over facts. The three
libraries close on each other: x509 issued it, tls carried it, ca
decides what it means.

**A REFUSED HANDSHAKE FAILS RATHER THAN RAISING.** A stranger, a
certificate this authority did not sign, and nobody arriving inside the
timeout are all ordinary answers to "did somebody connect", and
`tls_why/1` says which -- `tlsv1 alert unknown ca` from the server,
`certificate verify failed` from the other end. A server that raised
would stop serving everybody else because one impostor knocked.

Two smaller decisions worth keeping: **the socket is ours in both
directions**, because owning the descriptor is what lets `tls_read/4`
put a deadline on it -- a connection whose fd lives inside somebody
else's stream can be waited on for ever; and **`tls_read/4` is
at-least-one-byte**, via `peek()` then `in_avail()`, because a blocking
`read(buf, max)` waits for ALL of max and a reader asking for 4096 bytes
of a 20-byte request never returns.

`test/tls.sh` raises a server and runs three clients at it AS SEPARATE
PROCESSES -- enrolled, impostor, browser -- because a handshake is
between two ends that do not share memory, and a test proving one
process can talk to itself would have proved the least interesting half.

### HTTPS, and the transport that became a term

`library(httpd)` serves over TLS, and ONLY THE TRANSPORT CHANGED. A
connection became a TAGGED TERM -- `plain(S)` or `secure(S)`, a listener
carrying its credentials as `secure(S, Creds)` -- and five predicates
dispatch on the tag. Routing, keep-alive, the path rules and
`httpd_answer/3' are the same code on both, which is the point of doing
it as a term rather than a flag: HTTPS cannot drift away from HTTP by
being maintained separately, and `test/httpd.sh' still passes unchanged.

    httpd_serve(9443, [ tls([ certificate('node.crt'),
                              key('node.key'),
                              authority('ca.crt') ]),
                        workers(4) ]).

**The tag survives a channel**, so the worker pool needed nothing: a
channel copies in canonical text and `conn(secure(7))' reads back on
another machine exactly as `conn(7)' did.

**THE PEER'S IDENTITY REACHES A PAGE AS TWO SYNTHETIC HEADERS**, which
is the part that makes this more than encryption:

    httpd_page('/ledger', Request, reply(200, [], 'write applied')) :-
        http_header(Request, 'Tls-Peer-Permissions', Granted),
        atomic_list_concat(Gs, ',', Granted),
        member(G, Gs), ca_covers(G, 'ledger.write').

A page needs no new predicate and no access to the socket, and
`httpd_answer/3' stays a request in and bytes out -- which is what lets
`test/httpd.sh' check every routing rule with no port open.

**THEY ARE STRIPPED FROM THE CLIENT'S REQUEST FIRST, on both
transports.** A client may send any header it likes; a server that merely
ADDED its own would leave two, with the client's first, which is the one
`http_header/3' finds. That is the standard reverse-proxy hole. On a
plain connection they are stripped and NOT replaced, so a page that
trusts them is closed to port 80 by construction. `test/httpd-tls.sh'
sends `Tls-Peer-Subject: CN=root' and `Tls-Peer-Permissions:
ledger.write,admin' and checks the page still sees alice.

Two things learned on the way. **`current_predicate/1' is not an
availability probe**: it answers about the knowledge base, and a module's
predicates are not clauses in it, so it says no for a library that is
loaded and working -- and the probe call that replaced it raised
`domain_error(port_number, 0)' from the library that WAS there. Catch
`existence_error' around the real call instead. And **`tls_connect/4'
succeeding does not mean you were accepted**: under TLS 1.3 a client's
certificate is not examined until after it has sent its Finished, so a
stranger gets success out of connect and hears the refusal afterwards.
The property to check is that a refused peer gets no answer.

### Four transports, named -- `--tcp`, `--tls`, `--http`, `--https`

The arrangement is spelled rather than inferred. `--tcp' is what naming
`--kb' or `--host' already chose; `--tls' is the same port with
ZiguratIP's `SERVER/TLS_MODE: TRUE' on the other end; `--http' and
`--https' are Zeytun. Every port is optional -- 2160, 2160, 80, 443.

**`--tls` KEEPS THE PORT AND `--https` CHANGES IT**, and the asymmetry is
ZiguratIP's rather than an inconsistency here: TLS_MODE changes what is
ON 2160, while 80 and 443 are two different ports.

**Both clients share one TLS unit**, `client/tls.c`, because a handshake
is a handshake -- and its functions are `coco_client_tls_*` rather than
`coco_tls_*` because `library(tls)`'s module already owns the latter and
both live in one process when a cocolog serves and queries at once.
`zigurat.c` and `zeytun.c` stay libc and the sockets API; each reaches it
weakly, and neither the archive nor a test target carries OpenSSL.

`test/zigurat-tls.sh` is the rehearsal, and says what it is: a TLS
terminator in front of the suite's own server, the same shape `tunnel`
uses for the Cloudflare edge. What it proves is the CLIENT half -- the
handshake happening before the server's greeting, the framing surviving,
a clause written and read back by TWO PROCESSES over an encrypted
connection, the hostname checked, and plaintext against a TLS port not
going through. What it does not prove is ZiguratIP's server side, which
is ZiguratIP's suite's business. (It runs TWO terminators now, one per
client-auth setting, and holds all four certificate combinations -- see
"TLS with and without a certificate" below.)

### `--https`, and two older bugs it uncovered

The Zeytun client speaks TLS. `--https [PORT]` sits beside `--http
[PORT]` and both ports are OPTIONAL now -- 443 and 80 -- because a
querier behind Cloudflare should not have to know what port an edge
listens on. `--cacert`, `--capath`, `--cert`, `--key`, `--key-pass` and
`--insecure` are the rest of it.

**THE TLS IS IN `client/tls.c` AND NOWHERE ELSE**, so
`client/zeytun.c` is still libc and the sockets API and nothing else: it
reaches OpenSSL through six functions behind an opaque pointer, and a
build without OpenSSL compiles that file's stub half -- `--https` then
reports the missing feature by name rather than failing to link.

**The hostname is checked, not merely the chain.** That is the check a
hand-rolled client forgets, and a certificate valid for somebody else is
exactly what a man in the middle presents. SNI takes the same name, which
makes them one decision rather than two.

**TWO REAL BUGS FELL OUT, both older than this change.** `--http'
dialled the BINARY SERVER as well -- `open_connection' had no Zeytun
branch -- so a querier that could only reach the HTTP edge got `no server
at NAME:2160' from an arrangement that was never going to use it, which
defeats the whole point of the tunnel. It went unnoticed because the
suite always has a server: the `tunnel' case raises its edge stand-in on
localhost, where 2160 is answering too. And **a failed Zeytun fetch was
SILENT**: the reason went into the store and the hook answered 0, which
the engine reads as "no clauses" -- so an unreachable edge, a refused
certificate and an empty knowledge base were all
`existence_error(procedure, p/1)'. For a verification failure that is
unacceptable: the purpose of checking a server's name is to REFUSE, and a
refusal nobody can tell from an empty database is not one.

`test/tunnel.sh` gains a TLS-terminating edge stand-in -- which is what
Cloudflare is -- and checks a query through it, `--insecure` going
through loudly, and a second edge presenting a certificate for a name
nobody asked for, refused by name with `hostname mismatch`.

### `flush_output/0`, which was also not there

cocolog writes to the literal stdout, which the C library buffers by
LINE at a terminal and by BLOCK everywhere else. So a program that
printed a marker and then blocked -- a server saying it is listening --
printed nothing into a pipe or a file and everything at once when it
finally exited. Found by writing `test/tls.sh`, whose harness waited for
a READY that was sitting in a buffer. Interactively it had always
worked, which is why nothing had noticed.

### Five things that cost time, and one finding not applied

A `:cpp #t` target must declare the SDK's prototypes RAW inside
`extern "C"` **before** `(coco-sdk)`, or C++ gives them C++ linkage and
`use_module` fails with a mangled `undefined symbol` for a function the
interpreter exports unmangled -- and wrapping `(coco-sdk)` in
`(extern-c ...)` is not the fix, because a Cicili macro must emit one
form. `$`-prefixed predicate names must be QUOTED in a module's Prolog
half, or the clause is two tokens and will not read. Which library a
symbol lives in is not guessable and a miss LINKS FINE -- `DER::encode_oid`
is in libEncoding, not Core. Every transitive dependency must be named,
because `-rpath` applies only to what this link records. And
`X509::issue`'s issuer argument is a NAME CONFIGURATION, not a
certificate: handing it the issuer's `.crt` fails inside a configuration
parser with `key error at line 1` and some DER bytes.

**Reported, not patched**: `x509.hpp` says `certificate_public_key`
yields "the same shape the .pub files hold". It yields the SPKI's
CONTENTS -- 289 bytes against `dont-use-public.key`'s 293, exactly a
four-byte `30 82 01 21` header short. `der_wrap(48, K, S)` puts it back.

### `once/1` and `ignore/1` are control constructs now

They were Prolog clauses in `lib/builtins.cicili` for a day -- the way
every textbook writes them, and the wrong shape here. Both are
`(G -> true ; X)` with a different X, and the engine has an if-then-else
construct already, so they are two lines in `lib/solve.cicili` beside
`\+`, calling the same `coco_ite`.

What that buys beyond a frame and a `call` per invocation: the goal gets
its cut barrier FROM THE CONSTRUCT rather than from a hand-written `!`,
which is what makes `once/1` opaque to cut the way ISO 8.15.2 requires.
`findall(X, (member(X,[1,2,3]), once((X > 1, !))), L)` answers `[2,3]` --
the inner cut confined to the inner goal -- and there is nothing left to
get wrong.

### `get_time/1`, which was simply not there

Nothing in cocolog could ask what time it is. `time_file/2` answered
when a file was last written and that was the whole of it, so a program
that wanted to stamp a row, expire a session or set a certificate's
validity window had nowhere to get the number from. It is in
`lib/files.cicili` beside `time_file/2` -- same type, same units, and
`<time.h>` already included for the neighbour.

## Documentation that runs, and the three bugs it found

`tutorials/` is three categories now, and `test/tutorials.sh` is a case
in the suite rather than a script beside it:

| | | needs |
|---|---|---|
| `tutorials/basics/` | eleven lessons: facts and rules, unification, lists, arithmetic, cut, `findall`, assert and retract, atoms and codes, exceptions, grammars, and the knowledge base | nothing at all |
| `tutorials/library/` | thirty lessons, **one per library that ships** — tier 1 and tier 2 alike | `$COCOLOG_LIBRARY` for tier 2 |
| `tutorials/torch/` | the twenty-four networks, unchanged, moved under their own directory | libtorch |

**Every claim in the first two is a `must/3`**, which is what makes them
tests: `Got == Want` or the lesson fails, printing both. Fifty-nine
files, fifty-nine green, in forty-five seconds.

That was not a formality. Writing them found three real bugs in the
interpreter, all in `lib/builtins.cicili`, and all the same shape —
Prolog written from habit against a Prolog whose builtins backtrack:

* **`once/1` and `ignore/1` did not exist.** Nothing in the suite had
  ever called them, because everything in the suite was written by
  somebody who knew they were missing.
* **`retractall/1` retracted exactly one clause.** It was the classic
  failure-driven loop:

      retractall(H) :- retract(H), fail.
      retractall(_).

  which works in a Prolog where `retract/1` leaves a choice point and
  can be driven to the next clause by `fail`. **Every builtin in
  cocolog is deterministic**, so `fail` had nothing to back into: the
  first clause ran once, retracted one clause, failed, and the second
  clause said yes. A predicate that reported success having done a
  third of its job. It is now recursive, over `copy_term/2` so that a
  partially-bound head is not narrowed by whatever the first match
  bound it to.

The general lesson is worth keeping: **a failure-driven loop is not
merely slow here, it is wrong, and it is wrong quietly.** Anywhere in
`lib/` that a `G, fail` appears, it runs the body once.

The corrections the library lessons forced are the other half of the
value, and there were a dozen: `bigint_cmp/3` answers `<`, `=` and `>`
rather than `-1/0/1`; `curl_get/2` was never the API — the status is in
every arity, deliberately, because a client that hands you the body of a
500 turns an outage into corrupt data; `httpd_content_type/2` is keyed
on the bare extension and `httpd_type/2` is the one that takes a file
name; `tcp_accept/4`'s peer is `address:port`; `model_spec/2` answers a
NORMALISED spec, `dense(1)` coming back `dense(1,none)`, which is what
makes it safe to save. Each was documentation that had drifted from a
surface nobody had walked end to end.

**So the convention is now written down**: a new library gets a
`tutorials/library/NN-name.pl` in the same commit. The numbering is one
per library and a gap is visible, which is the point.

## The engine was quadratic

`coco_make` now dereferences every argument as it stores it. An argument was
kept as a REF cell pointing at whatever index it was handed, and `coco_arg`
hands back a REF — so every structure built on a previous one added a link,
and the continuation `$k(Goal, Barrier, Rest)` is exactly that. A recursion
3 000 deep left a chain **8 999 links long** and `coco_deref` walked it on
every engine step.

`callgrind` put **85% of all instructions in `coco_deref`**. With the deref
the longest chain is **2**.

| | before | after |
|---|---|---|
| `between(1,20000,_), fail` | 15 529 ms | **51 ms** |
| `findall` over 20 000 | 9 167 ms | **53 ms** |
| `between(1,100000,_), fail` | never finished | **226 ms** |
| naive reverse of 700 | 178 ms | 182 ms (noise) |

Enormous for deep recursion that backtracks, free everywhere else. It is
safe for the reason the WAM dereferences into a structure too: a cell built
after a binding lives above that choice point's `heap_mark`, and
backtracking truncates the heap to the mark, so anything that could see a
stale value has already been dropped.

## Built by clang, all of it

The interpreter, the client, the embedded store, every `.so` under
`library/`, and — in ZiguratIP — libCore and the server the tests talk to.
Not a preference: cocolog links ZiguratIP's C++ libraries into its own
binary and `dlopen`s modules into its own process, so a mixed toolchain is
one address space with two ABIs in it.

Four things had to be found first, and each is in `tools/cc/README`:

* **Cicili names `gcc` outright** and takes no override, so the build puts
  two shims on `PATH` for the one step it compiles. The three-line Cicili
  patch that would retire them is written down, offered, not applied.
* **`clang++` alone does not compile C++ on Ubuntu 24.04.** It borrows
  libstdc++ from the newest gcc it finds — gcc-14's *runtime* directory,
  which ships no headers — so every file dies at `'string' file not found`
  naming a header that is plainly installed.
* **`libCryptography.so` was under-linked**, and had been for years: it
  calls `Zigurat::Configuration` and named no `-lConfiguration`. g++ let
  every consumer through; clang reported it.
* **`CC ?=` and `CXX ?=` do nothing** — make's built-ins have origin
  `default`, not `undefined` — so the final link went on being a gcc link
  while every other line said clang. Only `readelf -p .comment` showed it.

## atom_concat/3 could only go one way

`atom_concat(Prefix, Rest, Whole)` with `Whole` bound and `Rest` unbound
raised `instantiation_error`. So did the mirror image. Only the
concatenating mode worked, and the two SPLITTING modes -- which ISO
8.16.6 requires and every other Prolog answers -- were unreachable.

**It was found from a caller, not from reading the code.** A namespace
check, written the obvious way:

```prolog
scoped(Chain, Head) :-
    functor(Head, Name, _),
    atom_concat(Chain, '_', Prefix),
    atom_concat(Prefix, _, Name).      % is Name in Chain's namespace?
```

That is how anyone writes "does this atom start with that one", and here
it threw rather than answering. A guard that raises instead of failing is
worse than one that is missing, because the caller's error handling is
now doing the guard's job by accident.

**Three of the four modes are now served, and the fourth is refused on
purpose.**

| mode | what it does |
|---|---|
| `(+,+,?)` | concatenate — what it always did |
| `(+,-,+)` | is A a prefix of C, and what is left |
| `(-,+,+)` | is B a suffix of C, and what is left |
| `(-,-,+)` | **still `instantiation_error`** |

The last one is the mode that ENUMERATES every split of an atom, and it
stays out for the reason written at the top of `lib/solve.cicili`: it
needs a choice point, and a builtin holding the choice stack in its hands
would be the one piece of this system nobody else could have written.
That mode belongs in the Prolog library beside `between/3`, over
`sub_atom/5`, and it is a few lines there.

**A wrong prefix FAILS rather than raising**, which is the other half of
the fix and the half that matters to a caller: guessing wrong about an
atom's shape is an ordinary answer, not an error. Seven checks in
`test/solve.cicili` cover the splits, the empty cases at both ends, and
the three ways to be wrong.

## Twelve interpreters, four states

`test/groups.sh`. Four groups of three: twelve `cocolog work` processes at once,
each group taking turns on one machine and handing it back and forth through the
database. Every machine produces its full answer set with **no answer twice**,
every member of every group takes turns, and nothing is left suspended.

```
     turns: a1=6 a2=4 a3=7
     turns: b1=4 b2=4 b3=4
     turns: c1=10 c2=10 c3=10
     turns: d1=11 d2=7 d3=12
GREEN: 0 failure(s)
```

Three things had to be right, and each was wrong first.

**The claim has to be SERIALIZABLE.** It is a read followed by a write of the
row it read: find an idle machine, then mark it. At READ COMMITTED — which is
what every other procedure runs at, and rightly — two workers arriving together
both see `suspended`, both take it, and both advance the same state from the same
point. The answers come out twice. It is the one place in cocolog that needs the
strongest level, and ZiguratIP's SERIALIZABLE excludes only other SERIALIZABLE
transactions, so twelve claims queue for microseconds each while the work that
matters — loading, proving, saving — goes on at READ COMMITTED all at once.

**An empty claim means two different things.** The machine is either gone —
proved out and dropped — or busy in a partner, which is the normal state of
affairs and no reason at all to stop. Treating the second as the first made every
machine get finished by whichever worker reached it first.

**And "gone" is not quite proof the first time you see it.** A worker gives up
only after the machine has been out of sight *continuously* for
`COCO_GONE_CONFIRM` polls — and waits far longer for one it has never seen at all,
because absence before the first sighting means "not created yet". That is what
lets a pool of twelve be started before the work exists, which is the only way to
start twelve without the first few finishing before the last are running.

That confirmation used to be three hundred polls — a second and a half — and is
now two. Both reductions are ZiguratIP fixes. A reader at READ COMMITTED used to
*wait* on the lock of a row another transaction was rewriting, and by the time
the wait ended the version it was waiting on had been retired and the replacement
was at an address it had already passed: for the whole length of a save, a
partner asking after the machine was told it did not exist. With the wait gone
the same thing remained in miniature, because a scan spans time. A reader now
takes the version that was current when its statement began, decided against a
microsecond clock, so a machine being saved is there throughout and there exactly
once.

Two polls and not none, because a worker's `exists` and its next `claim` are
separate transactions and a partner may drop the machine between them.

That last number is a heuristic and is allowed to be: what it decides is only
**when a worker goes home**. It cannot make two workers advance one machine, lose
a turn, or produce an answer twice. The claim settles all of that exactly.

## One ruler, eight queriers

`test/ruler.sh`. One process asserts a program one clause at a time — rules
first, so that for most of the run there are rules whose facts have not arrived —
while eight others query the same knowledge base against the same server.

The check is deliberately one-sided: **no querier may ever answer anything
outside the finished program's answer set**. A rule that cannot prove anything
yet is not wrong, it is early. Anything else means a querier read a clause that
was never committed, or half of one. The suite also checks that the queriers were
genuinely reading while it was being written — the number of answers has to grow
across the run, or they were only ever reading a finished program and the run
proved nothing about concurrency.

## The database is the knowledge base, all the way

`:- dynamic`, `listing`, `assert` and `retract` now mean the same thing whether
the clauses are in this process's memory or in a table several interpreters
share. Four things had to change for that, and three of them were bugs.

**A directive was asserted as a clause.** `:- dynamic counter/1.` in a consulted
file was read as a term whose functor is `:-` and arity 1, and put in the store
under a predicate called `:-`. `coco_directive` handles the declarations that are
about the store itself — `dynamic/1` in all three shapes a spec is written in
(`a/1`, `a/1, b/2`, `[a/1, b/2]`), `discontiguous/1` parsed and deliberately
ignored — and REFUSES anything else by name rather than storing it. Directives
that are goals still want an engine, which the store is a layer below.

**`retract` was local.** The clause came out of the store in memory and the
database never heard: it was back the next time the predicate was fetched, and
no other interpreter ever saw it go. An interpreter that can assert into a
shared knowledge base and not retract from it is halfway to being one. The
`on_retract` hook is the other half.

**A query never committed.** `cocolog query` opened a transaction, proved the
goal, printed the answers and closed the connection — so a goal that asserted
or retracted said it had and changed nothing. It commits now, and rolls back
whole when the goal ended in an error.

**And a declaration has to outlive the process that made it.** In a knowledge
base kept in memory `:- dynamic` can be a flag on a struct, because the program
that declared it is the program that runs. Here the clauses are shared and the
declaration is about them, so it is a row in `cocolog::props` and the `warm`
hook brings it back. A predicate declared and never written to exists and is
empty, which is not the same as its not being there — `listing` shows the
difference and so does the store.

Two smaller things fell out of it:

* **A PAGE and a PROCEDURE of the same name are one object.** `cocolog::
  predicates` was both, and pages are compiled last, so the procedure's `.so`
  was silently replaced and every call to it died with `undefined symbol: call`.
  The procedures are `predicates_of` and `props_of` now. Worth knowing before
  naming anything in Parsi.
* **Writing a predicate back must not clear its declaration.** Assert and
  retract both rewrite the whole predicate, and the procedure they called to
  clear it was `cocolog::forget` — which, once it also removed the `:- dynamic`
  row, would have undeclared a predicate the moment anything was asserted into
  it. They call `forget_clauses`; `forget` still takes the whole predicate,
  declaration and all, because a predicate that is not there is not declared
  either.

## What had to be fixed in ZiguratIP

cocolog began as a client that modified nothing. Most of what follows was found
by pointing twelve of them at one server, and it is fixed in ZiguratIP itself now
rather than worked around here. See its `doc/concurrency.md`.

* **The B-tree indexes took no lock on the shared page streams.** Two clients
  doing `WHERE indexed_column == value` at once read from each other's file
  position: `hexmap ends inside the chunk at NNNNN`, and often enough a dead
  server and a store to throw away.
* **A reader at READ COMMITTED waited for a writer, and then saw neither
  version** of the row it had waited for. A machine being saved did not exist as
  far as its partners were concerned, for as long as the save took.
* **A scan had no fixed view**, so a row rewritten while one was running could be
  counted twice or missed — 865 double counts in one run of three scanners
  against a single writer. Version stamps were at one-second resolution, which
  cannot tell two versions of a busy row apart.
* **`TRANSACTION ISOLATION LEVEL` had never compiled.** The generated C++ used
  `->` on a value member, so every procedure carrying the documented clause
  failed to build.
* **An isolation level outlived the transaction that set it**, and with
  SERIALIZABLE that leaked a server-wide semaphore slot — one client did all the
  work and the rest hung.
* **`SERVER/POOL_SIZE` shipped as 5**, which is the most clients that can be
  connected at once. The twelve did not get an error; they got silence until
  their own sockets timed out.

## Modules, and the Files library

`lib/module.cicili` adds a second seam beside the knowledge base one: two null
function pointers in `lib/solve.cicili` that a module fills in. A module carries
predicates written in Cicili and clauses written in Prolog, and a program cannot
tell which half answered it. MODULES.md is how to write one.

Two ship, and they are mirror images of each other. `lib/files.cicili` is
SWI's file-system predicates: seventeen in C, five in Prolog on three private
primitives. `lib/lists.cicili` is all thirty-six of `library(lists)` the other
way round — thirty-odd in Prolog, seven in C.

**That shape is forced, not chosen.** `member/2`, `select/3`, `append/3` and
`permutation/2` answer many times, and a module's C half cannot: it has no
access to the choice stack, deliberately, so that no module can break the
invariant suspension depends on. In the Coco half the engine provides the
choice points, and a machine frozen mid-backtrack thaws in another process and
goes on. Written in C they would work until the first `cocolog step`.

Lists also needed `call/N` in the engine — `max_member/3` takes a comparison
predicate and is `call(Pred, A, B)` and nothing else — and four SWI builtins
cocolog lacked: `length/2`, `msort/2`, `sort/2` and `sort/4`.

`lib/apply.cicili` is all seventeen of `library(apply)` with **no C half at
all**, and `lib/builtins.cicili` is the thirty-eight ISO-core builtins cocolog
was missing, computed against SWI's list rather than remembered. SWI has 655
builtins; the ones that cannot exist here are the stream, module, thread,
tabling, foreign-interface and string families, and that is stated in
MODULES.md rather than left to be discovered.

`findall/3` had to be an ENGINE service — it runs a goal to exhaustion and a
module cannot see the engine — so `coco_engine_findall` starts a nested engine on
the same machine and store. **Its solutions travel through the store and not
the heap**, because backtracking truncates the heap to the choice point's mark
and a copy made there during the search is gone by the time the search ends.

`bagof/3` and `setof/3` are in, and they are not findall plus a sort: they
answer once per distinct binding of the goal's free variables and FAIL where
findall answers `[]`. They are clauses, because the backtracking comes from
`member/2` over the groups.

**Implementing them found a real bug in `findall/3`.** The sub-engine's last
solution left its bindings on the trail — a predicate's final clause drops its
own choice point, so there was no frame left to backtrack through and undo
them. `findall(X, p(X,Y), L)` came back with Y still bound to whatever the last
solution made it, which is invisible until something reuses Y and then sees one
solution where there were four. `coco_engine_findall` puts the machine back as it
was before building the answer, which also reclaims everything the search
built.

**It is checked against a real SWI rather than against its author.**
`test/files/*.pl` are Prolog programs run twice — by `swipl` and by
`cocolog --local run` — in a freshly made empty directory that is the same
absolute path both times, and the two outputs compared byte for byte. That is
the only form of compatibility claim that cannot be fooled by what the author
believes SWI does, and it earned itself on the first run:
`file_name_extension(B, E, '.bashrc')` gives `B = ''` and `E = bashrc` in SWI,
because a leading dot **is** an extension separator. This library had the rule
everybody would guess instead.

Three things had to be added to make that comparison possible at all:

* **`cocolog run FILE [GOAL]`** — consult and prove in one process, with no
  database. Deliberately the shape of `swipl -q -g GOAL -t halt FILE`: nothing
  is printed but what the program writes.
* **A muted store.** A module's clauses belong to the build, not the knowledge
  base. Written through they would be saved into the shared database, come back
  on every fetch, and be listed as the user's own — and the next interpreter to
  open the same knowledge base would hold two copies of the library.
* **A `library` flag on a predicate**, so `listing` with no argument is the
  program and not everything reachable. `listing(Name)` still shows a library
  predicate, because asking for one by name is asking about that one.

## The writer agrees with SWI about spacing

It used to put a space around every operator: `1 + 2 * 3`, `a - b`. SWI writes
`1+2*3` and `a-b`, and the difference meant the shared tests could not print a
compound term at all without measuring formatting rather than the library.

**The rule is the reader's own tokeniser read backwards.** A space goes in
exactly where the two pieces would otherwise lex as ONE token: `a` and `-` do
not merge, so `a-b`; `-` and `-` do, so `1- -2`; `mod` and `b` do, so
`a mod b`. A solo character never merges, which is why `a,-1` has no space.

The operator and the right operand are rendered into buffers of their own
before the decision, because it needs their real first and last characters — a
quoted atom begins with a quote and a negative number with a minus, and neither
is knowable from the term.

Prefix position has one rule that is not a merge at all: **a digit after a
symbolic prefix operator takes a space** — `- 1`, because `-1` is not the
operator applied to one, it is the integer. `1-2` is right without one, so it
is genuinely about prefix position. An opening parenthesis takes one too,
which is what SWI does: `- (a+b)`.

Sixty-two terms were compared against a running SWI 9 term by term; sixty-one
now agree, and the one that does not is a *reader* gap — `:` is not an operator
in cocolog — and nothing to do with spacing. `test/syntax.cicili` holds the
rule as twenty golden cases and seven round-trips, because a writer that agrees
with SWI and no longer reads back would be a worse writer.

One real bug came out of it and is worth remembering: routing the operator
through `coco_write_atom` quoted the comma, so `a:-b,c` became `a:-b','c`, which
reads back as something else entirely. The comma is the only operator in the
table that gets quoted, and it is now written directly.

## catch/3 and throw/1, and errors that are SWI's

A goal that cannot be run used to report through the engine's `err` string and
stop the query. It now raises `error(Formal, _)` with the same Formal SWI
raises, and a program catches it with the portable
`catch(G, error(type_error(T, V), _), R)`. Ten error terms are compared against
a running SWI in `test/files/catch.pl` and all ten agree.

**A catch is a choice-point frame, and that is what made it affordable.** The
engine already writes every frame into a frozen machine field by field with its
kind, and the catcher and the recovery goal ride on the heap as one
`'$catch'(C, R)` term — which the heap serialiser already carries. So a machine
suspended *inside* a `catch` comes back inside it. `test/state.cicili` freezes
one part-way through a guarded goal, thaws it into a new machine and store, and
the throw is still caught by the frame that came back; `cocolog step` does the
same thing five times over a real database.

`throw/1` puts the ball in the **store** before unwinding, for the same reason
`findall` does: unwinding truncates the heap to the frame's mark, and the ball
was built above it.

One thing had to change in the engine's dispatch and is worth remembering: a
builtin that threw *and was caught* must answer **2**, not 1. The engine sets
the continuation from the builtin's own `k` on a 1, which would throw away the
recovery goal `throw/1` had just installed and carry on as if nothing had been
raised. That bug printed nothing at all and returned success.

## op/3, and what it forced about the database

`*operators*` is read at BUILD time and emits both halves of the grammar, which
is what stops the reader and the writer disagreeing about an operator. `op/3`
cannot change that table, so it adds a second one consulted first — and an
entry there with priority 0 hides the built-in of the same name, which is how
`op(0, xfx, =)` takes one away.

**`:- op(...)` is handled by `coco_directive` and not by the engine**, because a
declaration has to take effect for the *rest of the file being read*. A
directive dealt with after the whole file was parsed would be too late to
matter. That is why `lib/kb.cicili`, which is compiled below the engine and
cannot run a goal, reaches into `lib/syntax.cicili`: the operator table is the
reader's, and this directive is about the reader.

**And it exposed something the database had wrong all along.** A clause lives
in ZiguratIP as text and is parsed by whichever process fetches it. Written
with operators, `rule(a ===> b)` can only be read back by a process that has
declared `===>` — and a second interpreter opening the same knowledge base has
declared nothing. It did not fail loudly either: the text simply did not parse
and the predicate looked empty. Measured, not reasoned about — a fresh process
answered `false.` to `rule(X)` for two clauses that were plainly there.

Clauses are stored functionally now — `rule(===>(a,b))` — through
`coco_write_storable`, so they need no operator table at all and read the same in
every process for ever. `listing` still shows operators, because that is for a
person; `test/shared.cicili` proves the cross-process case.

A machine's declared operators also travel with it, in an optional `O` section
of the frozen form. Optional so that a machine frozen by an older build still
thaws.

**One writer bug came out of it.** An operator atom was bracketed in every
position but the top: `f((-))`, `[(-)]`. SWI brackets one only as an OPERAND —
`f(-)` and `[a,-]` are fine as they stand, because an argument is read at
priority 999 and a `-` followed by `,` or `]` cannot be a prefix operator.
`- (-)` and `(-)-a` are not fine, and are still bracketed.

## The reader knows what can start a term

An atom that is a prefix operator is only a prefix operator if what follows it
could begin a term. `- - a` is prefix `-` applied to `-a`, because the second
`-` can begin one. `- = a` is infix `=` with the **atom** `-` on its left,
because `=` is only ever infix and begins nothing.

The reader used to say that any name could start a term, so it read `- = a` as
prefix `-` applied to the atom `=` and stopped with `a` unread. `- * a` and
`- mod a` were misread the same way.

**And a quoted atom is never a prefix operator.** `'-' - a` is infix with the
atom `-` on the left where `- - a` is prefix applied to `-a` — the same tokens,
differing only in the quotes, so the lexer has to remember which it saw.

One more thing had to give: an operator atom used as a plain operand now has
**priority 0**. Carrying the operator's priority made `- * a` unreadable — the
atom `-` came back at 500, `*` is 400 yfx and admits a left operand of at most
400, and the reader gave up with the `*` unconsumed. Every Prolog is lenient
there; the strict reading buys nothing and refuses terms that are perfectly
clear. The **writer** is where the priority still matters, and it brackets such
an atom when it stands as an operand.

## Twelve workers: what was actually wrong, and what still is

`test/groups.sh` used to fail, and the cause was none of the things it looked
like. Written down because several wrong answers looked right for a while, and
two of them were acted on before being checked.

**It was never a hang.** Run without the `timeout` wrapper the suite always
completed — every worker finished, every answer appeared. It was slow, and
`WORKER_TIMEOUT` is 60 seconds.

**It was not the SERIALIZABLE gate**, though a profile showed 63 samples sitting
on `_serialize_mutex` and three threads waiting on `_serialize_cv` with the
counter at zero. Removing `TRANSACTION ISOLATION LEVEL SERIALIZABLE` from both
procedures made it *slower* — 58s against 52s. The profile pointed at a queue
that was a symptom.

**What was actually fixed, and it was latency:**

* **`TCP_NODELAY`, at both ends** (`client/zigurat.c`, and ZiguratIP's
  `TCPServer::run`). Small request, small reply, wait: the pattern Nagle
  coalesces and delayed ACK stalls 40ms at a time.
* **The client read one byte at a time.** `rd_u8` called `recv` for a single
  byte — one `cocolog step` measured **957 `recvfrom` and 383 `sendto`** for a
  few dozen bytes of conversation. Reads now fill 8KB: 957 down to 383, one per
  exchange. With NODELAY, 155ms per step became 85ms.
* **A busy poll no longer writes.** A worker waiting on a claimed machine used
  to find out by *attempting the claim* — a write transaction, at SERIALIZABLE,
  committed, several times a second per waiting worker. It now asks with a read
  and only writes when nobody holds it.

`make test` ends `red: 0`, and `groups` runs in about 16 seconds.

### What is still wrong: the store only grows

A deleted row is kept under MVCC so that a transaction entitled to an earlier
view can still read it, and **there is no vacuum**. `machine_open` saves a
machine by deleting its row and inserting a replacement, so a proof of thirty
turns leaves twenty-nine dead rows; `forget` then `consult` leaves a dead copy of
every clause. Eight consult+forget cycles netting *zero* rows added 32KB to the
file every time.

Measured, twelve workers over four machines, no compaction between runs:

| run | wall | data file |
|---|---|---|
| 1 | 14s | 34736 KB |
| 2 | 20s | 34752 KB |
| 3 | 24s | 34776 KB |
| 4 | 29s | 34792 KB |
| 5 | 32s | 34808 KB |

More than double, on identical work, while the file grew 72KB. It is not size —
it is how many dead versions each index entry has to be walked past.

**ZiguratIP's `TRUNCATE` is the vacuum, and cocolog cannot currently use it.**
A `cocolog compact` command was built and then withdrawn, for two reasons:

1. **It spends something real.** `TRUNCATE` gives up exactly the deleted
   versions that `rollback_transaction_to` and SNAPSHOT are made of, so after it
   the store cannot be read at a point in time before it ran. That is a
   capability of the knowledge base, not a cache.
2. **It does not work on any store cocolog has already written.** `TRUNCATE`
   reads whole rows to unlink their index entries, and a NULL column cannot be
   read back at all — the engine refuses the row with `NULL value`. `machines.note`
   was nullable and the client wrote the empty string into it, which the store
   keeps as NULL. Both are fixed going forward (the column is `NOT NULL`, the
   client writes `-`), but every row already written carries a NULL and cannot
   be reclaimed.

So on a store from before the schema fix the growth is unmitigated, and the
only cure is a fresh data directory. On a store written since, the pass works —
and it came back, this time with the permission model the withdrawal was
asking for. `cocolog vacuum` is the verb, on the wire (`cocolog::vacuum`,
which `make schema` ships) and embedded (`--store`, the Cicili engine's own
truncate) alike; `vacuum_kb/0,1` is the builtin, and it is **gated**: without
`--vacuum` on the command line it raises
`permission_error(vacuum, knowledge_base, _)`, because spending the store's
point-in-time reads is the operator's scheduled decision and never a
program's side effect. README's "A worked store slows down. Truncate it."
carries the measured numbers (12s empty, 60s aged, 16s after one pass) and
the schedule doctrine; `test/vacuum.sh` proves the pass and the gate in both
arrangements, and the concurrency suites run the verb in setup, which is why
they no longer slow down run over run. The honest long-term fix is still a
vacuum that does not cost point-in-time reads.

### The one-core ceiling is lifted, and parallel reads are the default

The ceiling was `Memory::Streams`: one global mutex pair over the two shared
file streams, every read serialised against every other. The Cicili engine
now has the design the first attempt was reaching for, with the lesson that
attempt taught built in — **the lock mode follows the isolation level**. The
guard is a read-write lock; a cursor whose isolation writes nothing
(READ UNCOMMITTED, READ COMMITTED, SNAPSHOT) takes it shared and reads
through the thread's own private streams; REPEATABLE READ and SERIALIZABLE
cursors — which stamp shared row locks as they scan — and every writer take
it exclusive, and an exclusive release flushes both canonical streams so a
private reader taken the next instant cannot miss bytes still sitting in
their buffers.

Measured, the twelve-worker embedded choreography on a fresh store: 5.3s at
~119% CPU with the guard exclusive; **1.6s at ~150% CPU with the shared side
on** — three times faster, on more than one core. About one run in three
under the flag once timed out, and all three causes of that stall are now
found and killed. Two were in the walk: a cursor's page-list snapshot
missing a page a writer committed into mid-walk (the walk now repeats until
a pass adds no pages), and the find-then-write procedures acting on a
lookup that could race a writer (they now hold one exclusive guard for
their whole body). The third was the engine's, and it is the interesting
one: **a stage does not always still belong to the transaction that comes
back to flip it**. A SERIALIZABLE claim stamps SHARED row locks as it
scans; a concurrent save's delete checks only for EXCLUSIVE conflicts, so
it stages its delete over the claim's stamp; the claim then loses its
serialization race, and its partial rollback "restored" the row — erasing
the save's staged delete, so the save's commit found nothing of its own to
flip and the row came back from the dead. Twelve workers then bounced their
saves between a machine and its twin forever. The fix is an ownership rule
in both engines' `commit_pointer` and `rollback_pointer`: a control block
whose `transaction_id` is not the caller's is no longer the caller's
business and is left exactly as found (startup recovery, whose job is
precisely other transactions' recorded intentions, stands outside the
rule). Traced by instrumenting every claim, save and drop with its thread
and the row's control block, and replaying the ledger: one row deleted
twice, then found pristine and alive. Measured after: **40 runs under the
flag, zero stalls, exact answer sets every time**, and the C++ suite —
whose commit and rollback walk through the same guard — stays green. With
the stall dead and 55 post-fix runs green without one, **the shared side is
now the default** for an embedded store; `COCOLOG_PARALLEL_READS=0` keeps
the exclusive guard, so one env var still separates the two modes in any
future bisect. The C++ server has since taken the same design — the story
continues below, after the turn became one transaction.

### A dead transaction's lock breaks on contact

The ownership guard exposed a debt the engine had always carried: a
transaction that dies without commit or rollback — a crashed client, a
pooled connection abandoned mid-turn — leaves its staged row locks on disk,
and nothing sweeps them until the next restart's recovery. Measured, in the
server: one turn killed mid-save left `state-c` wedged behind a stale lock,
`start` refused with `lock wait timeout`, and every following `groups` run
failed the same way until the server was restarted. Before the guard that
debris was sometimes scrubbed by accident, by exactly the promiscuous
rollback the guard exists to forbid; with the accident gone, the sweep had
to become deliberate.

It is now lazy recovery, in both engines. A transaction id names one
transaction (the C++ engine's id was per-THREAD — every transaction a
pooled connection ever ran shared it, so "is the owner still running" had
no answer; the Cicili engine's was hashed from the thread and the wall
second, so two begins in one second collided), and a process-wide registry
holds the ids currently between begin and end — taken at a fresh begin,
released only after commit or rollback has cleared every lock. A begin on
a thread whose transaction is still open CONTINUES it, id and registration
standing: the server begins once per request while a turn's transaction
spans many, and the first cut of this work handed those nested begins
fresh ids — orphaning every stage the turn had already made, which the
commit's ownership guard then skipped, and a fresh store grew ghost
machine rows and torn index chains within a handful of runs (387 unique-key
refusals in one afternoon; 7 after the fix). What makes an id dead is
death: commit and rollback retire it, a dying thread's destructor retires
it after its best-effort rollback, and a crashed process's ids are simply
unknown to the next process's registry. When `check_lock` meets a lock
whose owner is not in the registry, it no longer waits on the corpse: it
rolls that one pointer back in place — the same foreign-id work startup
recovery does, done on contact — and looks at the row again. A live owner,
however slow, is never touched: its id is in the registry until its locks
are already gone.

Proven at the engine seam in both engines: the C++ suite gained
`a_dead_transactions_lock_breaks_on_contact` (stage, abandon, second writer
through in milliseconds instead of a ten-second refusal, committed data
intact, the abandoned stage never landing) and the standalone Cicili
harness the same case; 304 C++ cases and the full cocolog suite stay green.
The stale expectation this flushed out of the standalone harness — a
truncate count written before superseded UPDATED versions became
reclaimable — was corrected to match the documented behaviour.

Settling that debris surfaced one more engine debt. The C++ index's
truncate walks every value chain to unlink the settled dead, and a link
whose address never finished landing — a stage cut off mid-write, exactly
the kind of record the breaker now settles — read back NULL and refused
the WHOLE pass with `NULL value`: one torn link in a machine-state chain
made every `cocolog vacuum` fail on that store forever, with a fresh data
directory the only cure. A NULL address in a chain now ends the chain
exactly as `-1` does — nothing lies beyond a link that never landed — and
the store that was refusing every vacuum healed in place, no restart, no
new data directory. (The Cicili engine never had the debt: its truncate
rebuilds each index wholesale instead of editing chains.)

The last residue — about one run in three losing a group to a
`unique key 'IDX_COCOLOG_MACHINES_NAME'` refusal — was then hunted to
ground with ledgers at three depths (ZiguratIP 1c2c86f). The refusals
were CORRECT verdicts on a ghost: an alive committed index entry whose
machines row was gone. The ghost was born when the breaker rolled back a
LIVE transaction's staged index entry — and the registry was right too,
because the stage had been made AFTER its transaction's commit: the
server's layer commits between statements without always beginning before
the next one, so the next statement's stages arrived under the retired id,
alive by every intention and dead by the registry. The fix is the oldest
idea in autocommit engines, applied at the engine's own seam: **a stage
that arrives with no transaction open opens one** — the push, the three
control writers and the SERIALIZABLE read stamp lazily begin, which the
begin-continues rule makes idempotent. Measured after, twelve-worker wire
choreography, fresh store: **15/15 runs green at 6–8 seconds flat, zero
breaker fires, zero unique-key refusals, zero lost unmaps, and the full
cocolog suite `red: 0`** — wall-to-wall at last.

The begin-continues rule then claimed one victim of its own: the EMBEDDED
choreography went twelve reds in twelve runs while the wire ran green on
the same engine. The embed-side ledgers named it (ZiguratIP 5af6c36): only
the READ-ONLY commit path nulled the transaction record pointer, so after
a writing commit the next begin CONTINUED a committed-out transaction —
its stages carried the retired id and the breaker ate live machine saves.
The wire never showed it because the request layer's rollback hygiene
nulls the pointer between requests; the embedded arrangement speaks to the
engine bare. A writing commit now spends its pointer exactly as the
read-only path always has, and both arrangements are green on one engine:
embedded 12/12 at 1–2 seconds (parallel default) and 4/4 at 5 seconds
(exclusive), wire 6/6 at 6–8 seconds with zero engine errors, vacuum and
torch green in both arrangements, the full suite `red: 0`, 304 C++ cases
and the standalone Cicili harness green.

### A turn is one transaction, in both arrangements

The turn used to be two: the claim committed ahead of the work "so it would
stand before the machine was touched", and that standing claim was the
stranded-machine hazard in person — a worker killed mid-turn left the
machine marked as its own forever, `drop` would not clear it, and CLAUDE.md
taught the manual recovery. The claim now RIDES the turn's single
transaction: the turn-final commit is what makes it stand, a turn that
fails in-band is rolled back explicitly, and a worker that dies takes its
claim down with the server's rollback of the broken connection — the
machine goes straight back to the pool. Proven directly: a worker
SIGKILLed mid-run leaves its machine `suspended`, not stranded. The
`release` hand-back function is gone with the hazard it existed for.

What made this affordable is the isolation hand-back: the claim procedures
(and the embedded claim) drop from SERIALIZABLE to READ COMMITTED after
their update, inside the still-open transaction — the stamps stay staged
until the turn commits, but the slot-of-one goes to the next claimant
after the claim's few statements instead of being held for a whole turn.
Measured with the turn as one transaction, and then benchmarked again on
AGED stores to prove the numbers hold: embedded 12/12 green at **2–3
seconds flat** on a store thirty-plus runs deep, wire 12/12 green at **5–6
seconds flat** on a store eighteen runs deep, zero engine errors across all
of it, vacuum and torch green in both arrangements. And the halved commit
count collapsed the guard-mode gap: **exclusive mode now runs the same
choreography at ~2 seconds too**, down from 4–5 — the old turn paid the
commit's three-syncs-of-two-files dance twice, once for the claim and once
for the work, and in exclusive mode those serialised syncs were most of
what a turn cost. The parallel default keeps its edge under heavier read
mixes; the exclusive fallback is simply no longer a 2–3× penalty here.

### The wire server runs parallel reads too

The C++ engine now carries the same shared-read architecture the Cicili
engine proved out, member for member: a writer-preferring read-write lock
behind `Streams`, the lock mode following the isolation level, per-thread
private read streams for eligible cursors, an exclusive release flushing
both canonical streams, the fixed-point page-list re-walk, and index
cursors staying exclusive — the same eligibility line the Cicili engine
drew. The port surfaced one lesson of its own: a thread's private streams
are opened against a store's files and can OUTLIVE that store — the test
suite hops stores, and the first shared-mode run failed 73 cases reading
the previous store's dead files through cached streams. A reader epoch
fixes it: opening reader paths stamps the store from a global counter, and
a thread whose streams predate the stamp reopens them before reading.

The server turns it on by default; `ZIGURATIP_PARALLEL_READS=0` keeps the
exclusive guard, mirroring the embedded flag. The C++ test fixture opens
reader paths too, so all 304 cases run against the shared shape — green,
five runs in a row. On the wire, twelve workers: 12/12 green at **5–6
seconds flat**, zero engine errors, the full cocolog suite `red: 0` with
every server case really running. The twelve-worker number matches the
exclusive server's — that choreography is commit-bound, not read-bound, so
the win here is queueing behaviour (readers no longer serialise behind one
stream pair) and one engine design in both languages, not a headline
seconds cut. One bring-up hazard worth recording: the first parallel
server heap-smashed at startup (`malloc(): invalid next size`) because the
binary had been built minutes BEFORE the header gained the reader-epoch
members while the library was built after — `Memory` allocated at the old
size, constructed at the new one. After ANY engine header change, rebuild
the library, the server binary, and the schema objects together.

The embedded side was re-benchmarked against the same engine state to
prove the port moved nothing it should not have: on the aged persistent
store, now thirty-plus runs deep, 12/12 green at **2–3 seconds** with the
parallel default and 4/4 at **2 seconds flat** exclusive — the converged
numbers exactly, no drift. The torch suite ran green against the same
engine state too — train, store, reload in a fresh process with identical
predictions, the conv net's batch-norm buffers back out of Zigurat intact.
So did the vacuum, in both arrangements against the parallel server: the
verb reclaims, a second pass finds nothing more, the gate refuses without
`--vacuum`, and live clauses survive — the reclaim machinery running under
the new shared-read guard, with zero engine errors in the server log.
And the cross-process case — one process writing through the wire, a
second that consulted nothing reading it back, the claim the project
exists to make — reconfirmed green against the same server instance,
which by then had absorbed the twelve-worker benchmark, the vacuum and
the full suite without one engine error. The ruler — one writer growing
the program clause by clause under eight concurrent queriers, the very
mix the shared guard exists for — ran green on it too: readers
demonstrably read WHILE the writer wrote (a querier's answer count grew
from 0 to 37 across its own run), nobody answered outside the program,
and the finished program proved the full closure. Every server-dependent
case has now run standalone against the parallel server: groups, vacuum,
shared, ruler, and zigurat — the backend case that pushes frozen machine
state through the wire in its 4000-byte chunks — all green, one server
instance, zero engine errors. The pure C client's probe ran against the
same instance too, 20 checks green: protocol framing and its refusals
(the String and Text limits refused cleanly, connection still in step),
the transaction lifecycle, ordered clause reads, machine state in chunks
and back in seq order, the Zeytun page serving the same clauses over
HTTP, and escapable characters surviving the full round trip. (The state and files cases are green too,
but they are local ones — state freezes and thaws in-process, files runs
cocolog and SWI side by side and diffs their answers line for line, and
neither has a server in the loop; that is exactly why state reads GREEN,
not SKIP, on a serverless run, and why files' SKIP condition is "no
swipl", not "no server".)
That closes the loop: one shared-read design, both engines, both
arrangements, benchmarked green on aged stores at wire 5–6s and embedded
2–3s, with the heaviest module the store carries confirmed on top.

### A torn chain link ends the walk instead of wedging the server

Found by a routine groups run after the AI e2e test: the setup vacuum
froze the whole parallel server — 80% CPU, log stopped at
`cocolog::vacuum`, every new connection refused. GDB showed the vacuum
thread spinning in the machines-id index's dead-value walk with
`address = 0` on every sample, and the preserved store told the rest:
a value's `next_address` was ZERO, address 0's data was all zeros, and
address 0's hexmap chunk was FREE — never allocated. The walks had
learned (STATUS above) that NULL and -1 end a chain, but 0 is a "valid"
address, so the walk chased it into free space, where `_pointer` scanned
the whole hexmap per call, forever — and because the vacuum holds the
streams guard exclusive, every other thread queued behind the spin. A
torn in-place chain edit is how such a link lands, the same family as
the NULL link before it, and a torn link can equally point BACK into its
own chain, which no free-space check can see.

The rules now, in both engines: `_pointer` refuses a chunk without the
DATA bit instead of walking free space; every chain walk asks whether a
link resolves to an allocated record before following it, and an
unresolvable or REVISITED address ends the chain exactly as NULL and -1
do (a visited set in C++, Brent's cycle check in Cicili; the free walk
is additionally self-limiting, because freeing marks chunks free and a
link that comes around again stops resolving before it can double-free).
The SELECT-path walk — every index read, not just the vacuum — got the
same guards and the NULL normalization it had never had. Proven by a
C++ case that forges both shapes into a real chain through the store's
own stream: a self-loop answers one row and ends, an unresolvable link
answers the rows before it and ends, reclaim over the torn chain
completes — and against the unfixed engine the same case hangs forever,
the wedge reproduced in miniature. Validated after: C++ suite 305/305 in
shared mode, Cicili harness green, embedded groups 2s on the aged store,
wire groups 6/6 at 5–6s on a parallel server, suite `red: 0`, zero
engine errors. And benchmarked, because the guards sit on the hottest
read path in the engine — every index SELECT's value walk now asks
whether each link resolves and remembers where it has been: the
twelve-worker wire choreography ran 12/12 green at **5–7 seconds,
effectively 6s flat**, on a store eighteen runs deep — the established
band, unmoved. The embedded arrangement holds its band the same way:
27 of 28 runs green at **2–3 seconds flat** on the aged store, parallel
default and exclusive alike. The one red exited through a worker's
normal "nothing left to do" line with healthy claim counts and did not
recur in 23 straight runs after — the rare-flake territory the
Contention watch already covers, not a property of the guards. And the
vacuum itself — the walk that wedged — is confirmed from both ends: the
vacuum test green in both arrangements against the fixed parallel
server, all ten checks, and the groups setup vacuum, the exact path
that spun, green more than eighteen times over on the ageing store it
originally died on. Torch ran green on the guarded walks too — its model
chunks travel exactly the multi-value chains the walks now guard, and
train, store, fresh-process reload with identical predictions, and the
conv net's buffers all came back intact in 3 seconds. And the
cross-process case — one process writing through the wire, a second that
consulted nothing reading it back — is green on the guarded SELECT walk
too, which is the read path every one of that second process's queries
takes. So are state and zigurat: state locally (freeze and thaw have no
server in the loop), and zigurat against the fixed server — the case
that matters here, because machine state travels in 4000-byte chunks
that land as exactly the multi-value chains the torn link corrupted.
With ruler green under eight concurrent readers as well, and the pure C
client's probe green through all twenty checks — its reads riding the
guarded SELECT walk, its machine-state chunks landing as the very chain
shape that tore, the Zeytun page serving the same clauses over HTTP —
every case the store has now runs green on the guarded walks. The
wedge-immunity came for free.

### The torn-link producer, hunted to one byte

The zero links had a maker, and it took eight instrumented reproduction
rounds to corner it: not a torn write, not a kill catching a flush, not
a poisoned stream — every one of those was hypothesized, instrumented,
and ruled out by a run that refused to show it. What the ledger finally
proved, with a preserved store and a byte-watcher bracketing every step,
was this: the corruption appeared at STARTUP, deterministically at the
eleventh run's restart, and the startup page walk was the producer. That
walk asked `_pointer` whether each address held a record, and `_pointer`
seeks past the control chunks before measuring — right for a record, and
a read STRAIGHT THROUGH a short free run into the record behind it. A
one-chunk free run parsed as a 64-byte "record", the walk went one phase
out of step, read data codes as control bytes, mistook a live index
node's standalone code for an online lock, and rolled back live rows as
uncommitted debris. The next restart read the scribbled region as
reclaimable, the page went back to the allocator, and the recycle
zero-filled a node the tree still linked — the zero link of both
preserved specimens, born whenever the store's churn laid down a short
free run in the walk's path. The engine's own comment KNEW free runs
read through — the free branch measured them from the hexmap for exactly
that reason — but the record-or-free decision gating the two branches
came out of the same misparsing call. The fix is one byte read first: a
record's first chunk is a control chunk and always carries the high bit,
a free chunk never does.

The hunt hardened everything it touched on the way through, in both
engines: offline inserts now land data and control under one flush
BEFORE the hexmap marking goes durable, so a death mid-insert leaves
unmarked bytes instead of an allocated record of zeros; every canonical
write clears a poisoned stream first, as the read accessors already did;
and a node reading degree 0 with a keys head of 0 — the torn shape no
real node writes — walks as empty. Proven end to end: startup on the
preserved store that lost its node at every eleventh-run restart now
keeps it byte for byte; fifteen kill-and-restart pressure cycles ran
30/30 groups runs green where cycle six used to fail every time; the
C++ suite 305/305, the Cicili harness green, the full suite `red: 0`
with zero engine errors, and groups-embed green on the aged store.

### Twenty networks through the Torch module

The PyTorch tutorial classics, each rewritten as a Prolog program
against the module's own surface and run as one suite
(`test/torch-nets.sh`): linear regression under sgd and adam,
polynomial features, sine through tanh and a gaussian bump through
relu, step-scheduled sgd, mae over deliberate outliers, two regression
targets at once; logistic regression on a bce sigmoid head, xor, two
moons, four blobs under nll, a three-arm spiral on raw
cross-entropy logits, and dropout proven inert at predict time (two
forwards, one answer); conv/pool bars on an 8×8 canvas, a two-stage
mini LeNet over three shapes, and batch-norm whose running buffers
serve at eval; an 8→3→8 autoencoder and a denoiser; and the save/load
round trip through the knowledge base, params and predictions
identical. Every net builds its own data — deterministic by
`torch_seed` and a sin-hash noise, no files, no downloads — trains,
and tests against a threshold. **All twenty run green in about ten
seconds on a CPU**, and the suite SKIPs without a `make full` build
because "no libtorch here" and "the module is wrong" are different
findings. The tuning lessons the suite keeps: the 8-3-8 bottleneck
wants encoder and decoder hidden layers around it, and sgd at 0.3 on a
tanh net diverges to NaN where relu at 0.1 glides — both now written
into the nets as they stand.

### The Torch module learns sequences

Three spec terms close the gap the twenty-net suite could not touch:
`sequence(L)` as the input (a row is L steps — plain numbers reach the
net as `[N,L,1]`, token ids stay `[N,L]` when an `embedding(V,D)`
follows directly and widens each id to D learned dimensions), and
`lstm(H)`, batch-first, where stacked lstms read the full sequence from
each other and the dense head after the last one reads its final step —
marked on the layer at `model_new`, so the shape still flows down the
list and a mismatch is still a refusal: an lstm without a sequence, an
embedding anywhere but right after it, a net ending inside a sequence.
The parameter walk was already generic, so lstm weights and the
embedding table travel through `model_params` and the store unchanged.
The suite is twenty-three now: an lstm sums plain-number sequences at
rmse 0.007, embedding-plus-lstm remembers whether a token ever appeared
at accuracy 1.0, and a stacked lstm goes into the knowledge base and
comes back with params and predictions identical — all green, about
fourteen seconds on a CPU.

### The tutorials, one file each

The suite's twenty-three networks rewritten as standalone tutorial
programs (`tutorials/torch/NN-name.pl`) — plus a twenty-fourth the suite does
not have: reinforcement learning, as fitted Q-iteration on a gridworld,
the DQN idea built from nothing but `model_predict` for the Bellman
targets and `model_train` for the regression, whose greedy policy walks
the optimal six moves around the pit. Each file is documented in
place and carries three goals meant to be three PROCESSES against one
store: `train` builds its data, fits, and `model_save`s; `test`
`model_load`s in a fresh process and judges against a threshold;
`predict` loads and answers for visible inputs beside the truth —
`xor(0, 1) = 1 (confidence 1.00)`, `[3,0,0,0,0,0] -> contains token 3`.
`test/tutorials.sh` runs all seventy-two processes green in about
seventy-seven seconds, and the main README features 22-embedding-lstm
with its transcript — the token remembered across five steps, in a
model trained by one process and answering in another. And with all of
it in the tree, the full `make test` was run once more against a fresh
parallel server: every one of the eleven cases GREEN — the four
server-dependent ones genuinely running, nothing skipped — `red: 0`,
zero engine errors. The tutorials suite then ran once more on top —
all twenty-four files, seventy-two processes, green in seventy-four
seconds, its third consecutive full-green run at essentially the same
clock, which is the determinism doing its job. The whole stack, engine
to tutorials, green at once.

Writing them taught two properties of the platform the hard way, both
now documented in `tutorials/torch/README.md`. Consulted clauses live in the
knowledge base like everything else, so twenty-three tutorials sharing
one store shadowed each other's `train` — the first tutorial consulted
answered for all of them, and the first "all green" run had mostly
proven tutorial one twenty-three times (the runner now gives each
tutorial its own store). And a second consult of the same file APPENDS
duplicate clauses: a nondeterministic helper inside an inner findall
then widens data rows, which surfaced as `model_evaluate` refusing
exactly the wide tutorials — images, autoencoders, sequences. Every
single-clause data helper now ends in a cut, and the full run dropping
from 372 to 76 seconds is that diagnosis confirmed from the other
side: the duplicates had been silently doubling everybody's data.

The main README now makes the case in full. Its "Prolog that trains"
section opens with the thesis — a network is a term you assert,
training is a goal you call, and the learned weights are facts, saved
and reloaded through the same knowledge base that holds the rules —
then names the challenges the tutorial suite passes, regression to
fitted Q-iteration, green deterministically in about seventy-five
seconds, and closes on what sits underneath: the full torch surface
with honest CUDA refusal, models persisted as terms, the MVCC store —
and the point of the whole arrangement, that where a neural net stops
(explaining, constraining, chaining conclusions) the Prolog engine
picks up, because they were never in different systems to begin with.

### The test that blocked all of it is fixed

`readers_do_not_queue_behind_staged_writes` — the suite's ~one-in-three
failure that made the first ceiling attempt unvalidatable — was a REAL
dirty read, and it is fixed at its source. `_rollback_pointer` flags a
never-committed row `DELETED` with `modify_time = now` but left
`create_time = 0`, and `_alive_at` only rejects future births when
`create_time` is set — so a reader whose statement began before a peer's
ROLLBACK read "died after my snapshot" on a row that was never alive. The
rollback now stamps the birth too (born and died at the same instant, so no
snapshot anywhere can see it), `_alive_at` refuses the old unstamped shape,
and the SNAPSHOT branches require a version to have been born by the
snapshot before "deleted after it" can mean "visible to it". Measured: the
suite failed 4 of 10 runs before the fix and 0 of 21 after, in both
engines. (A different, much rarer Contention flake — one failure in ten
runs, not reproduced in six retries — remains under watch.)

### One binary, four arrangements, and the emacs mode held to it

The build variants collapsed: `cocolog`, `cocolog-embed`,
`cocolog-torch` and `cocolog-full` are ONE binary now, the full one —
interpreter, embedded MVCCS engine and torch module linked together,
the engines still registering through the weak symbols the interpreter
always carried. Which knowledge base a run uses became a runtime
choice, never a build: `--local` (memory, now the DEFAULT — naming
`--kb`, `--host` or `--port` chooses the server, since local keeps no
named knowledge bases), the server, `--http`, and `--store DIR` — with
`--embed [DIR]` as its synonym, a bare `--embed` opening `./KB`. The
README grew an Installing section to match: prerequisites, the three
checkouts side by side, ZiguratIP built first, and four first runs,
one per arrangement. Proven at each step on the one binary: the whole
suite GREEN against a live server, the tutorials, vacuum's both
halves, groups-embed.

Alongside it, the emacs mode was pointed at coco instead of SWI: its
conformance harness (`make coco` in `emacs/`) asks the engine of the
mode and the cocolog binary the same questions — every example-file
query, every conformance query, and every example the snippet pickers
show — 234 queries, 0 differ. Getting there fixed real gaps in
cocolog's own arithmetic (`round`, `gcd`, `^`, integer `**`,
`number_codes` accepting a written `+`), taught the harness SWI's
shadowing rule for a flat-namespace Prolog, and gave `C-c C-g` the
three-column torch rule picker beside `C-c C-i`'s goals.

### The four-port tracer, held to SWI port for port

cocolog has a tracer now: `--trace` prints `Call`, `Exit`, `Redo` and
`Fail` in SWI-Prolog's own format on stderr for every goal proved, and
`trace/0`/`notrace/0` switch it from inside a program. The engine's
design paid for itself — the `Exit` port is a `'$trace_exit'` marker
the body proves its way through, pushed below the frame's heap mark
the way `catch/3` protects its `'$catch'` term, and `Redo`/`Fail`
live on a tracer shadow of the choice stack, index-aligned and
deliberately outside the frozen format, so a machine frozen mid-trace
thaws anywhere and carries its pending exits with it (they are heap
terms). Under trace the last matching clause keeps its frame, because
failing back past it is what prints the `Fail` port.

The subtleties were learned from SWI empirically and reproduced one by
one: a `Redo` shows the call with its bindings just undone, so the
goal is painted before head selection binds it; taking the other arm
of a `;`, the else of an `->` or the way out of a `\+` is a `Redo` of
the call it sits in, and silent at the toplevel; a deeper `Redo`
reopens every call it is nested in, so their `Fail` fires when the
failure finally crosses them; a call whose remaining heads cannot
match is discarded in silence — the quiet SWI's clause indexing buys
by never keeping the frame, bought here without indexing by
remembering the exit; and the desugared arms of `->` and `\+` travel
as `$true`/`$fail`, which the program never wrote and the trace never
shows. `test/trace.sh` holds all of it: twenty-one queries over one
program, both tracers, port lines compared one for one after
normalising the depth base, variable names and spacing — the `trace`
case of the suite, SKIPping without swipl. TRACING.md is the
document, linked from the README beside the mode's own introduction.

And the mode uses it everywhere: `C-c C-e` traces a goal over the
buffer's file into a colour-coded `*coco trace*` buffer under any of
the four arrangements (the `cocolog-coco` settings group), and — the
engine draws, coco certifies — every graph `C-c C-t`, `C-c C-a` or
`C-c C-q` draws on a machine with a binary is re-asked of the real
interpreter on the spot, in memory, touching no store: agreement is a
word in the echo area, disagreement a loud warning naming both
answers, and the rule's four-port trace refreshes alongside. The
elisp engine stays for what the binary cannot give — the clause-level
graphs, the machine with nothing installed, the instant redraw — as a
shadow held to cocolog twice over, offline by the 234 and live on
every draw. All of it sits on the Coco menu too, in an "Under coco"
group: the trace (with C-c C-e shown beside it), the no-tracer run as
a command of its own (`cocolog-coco-run`, what C-u C-c C-e does), the
arrangement picker, and tick-box toggles for certifying and the live
trace — each asking for the menu bar to be drawn again, which the
mode's own toggle test demands because the bar is drawn from a copy
and a flipped tick can otherwise show stale for a whole session. The
mode's suite: 160 tests, 0 unexpected.

### The Mac taught the Type layer about integers

The first macOS build of ZiguratIP died where the parsi compiler
JIT-compiles the generated C++ of `serializer.parsi`: `conversion from
'unsigned long' to 'ULONG' is ambiguous`. The cause is a platform
split hiding inside the fixed-width names: on LP64 Linux `uint64_t`
IS `unsigned long`, so a `0ul` literal, a `size_t` or a `strlen()`
matches `ULong`'s `uint64_t` constructor exactly — while on Apple's
LP64 `uint64_t` is spelled `unsigned long long`, so the same value
matches no fixed-type overload and drowns among equal-rank
conversions to `uint64_t`, `int` and `unsigned int`. `int64_t` splits
the same way, so `Long` carried the identical trap for `0l`. Linux
could never see any of it, which is why every sandbox build was
clean.

The fix took two rounds, and the second was earned honestly: a
constrained template constructor (an exact match for any plain
integral, losing to the non-template constructors everywhere they
already applied) moved the error exactly one step — `SET i = 0ul;`
then died on ASSIGNMENT, the same value converting equally well to
the wide type's rvalue and lvalue `operator=` and resolving to
neither. That round was reproduced on Linux before it was fixed: the
mirror spelling (`0ull`, the type that is not `uint64_t` here) makes
gcc say exactly what clang said. `==` and `!=` carry the same
four-candidate pattern, with real literals waiting in the System
pages the Mac build never reached (`a_time == 0l`, `type.size() ==
2ul`), so `ULong` and `Long` each gained the same integral template
on three surfaces — constructor, assignment, the two comparisons —
each delegating through a named const lvalue so the forwarded call
picks the `const&` overload with no second overload decision. The
relationals take only the class type and were never ambiguous.
Header-only and additive both rounds: no members, no virtuals, the
ABI stands, and everything that compiled before means what it meant.

Proven on Linux before pushing, both rounds: the mirror repro
ambiguous without the templates and clean with them, the full
ZiguratIP build with every System page (serializer and mem among
them), then cocolog's schema against the rebuilt home and the whole
suite — twelve cases GREEN against a live server, `red: 0`.

### The toplevel: bare cocolog is what bare swipl is

No command at all now enters a REPL, in whichever of the four
arrangements the options name — `cocolog` is a `?- ` in memory,
`cocolog --kb demo` is a `?- ` on the server's `demo`. The pieces were
waiting. The reader keeps a variable-name table per clause whose own
comment says what it is for — "`X = 1` rather than `_G17 = 1` — which
is what a REPL and the tests need" — so answers wear the query's own
names, the one thing `query` cannot promise, its machine possibly
thawed from a store the names never reached. The engine re-asks on
`coco_engine_ask`, so one machine, one store and one engine live for
the whole session: what a goal asserts or consults the next goal sees,
and against a database every finished goal is one committed
transaction, exactly as `query` has it. `halt/0` was already an
engine affair (`halted`, `halt_code`), so `halt.` is not even a
special case — the loop notices and leaves.

The answer shapes are held to a live SWI, not to memory of one. The
ambiguous cases — which variable does a still-unbound shared cell get
named for? — were put to `swipl` on this machine and the answers
copied: the cell is named for the LAST variable standing on it
(`X = Y.` answers `X = Y.`; `f(A,B) = f(B,A).` answers `A = B.`), a
bound value shows that name where the writer said `_G<cell>`
(`X = f(Z), Y = Z.` answers `X = f(Y), Z = Y.` — an exact
substitution, the writer's `_G` number being the cell index), and a
`_`-named variable names cells without ever getting a line of its own
(`X = f(_Q).` answers itself). The punctuation is honest because the
engine's choice stack is: a solution that left no choice point ends
`.` with nobody asked, one that did prints a space and waits for `;`.
Prompts and the banner go to stderr and only at a terminal; piped
input has the `;` a terminal would have echoed restored on the way
out, so a piped transcript reads as a terminal session and stdout is
the answers alone.

`test/repl.sh` — the suite's thirteenth case — holds sixteen local
cases (the SWI alias trio verbatim from the live run) and the
cross-process claim in both store arrangements: a piped session
asserts and `halt.`s, and a second process that consulted nothing
reads the fact back — embedded always, wire SKIPping without a
server. One expectation failed the right way while writing it: a
dynamic predicate's last clause answers determinately (`fact(X).`
closes `X = two.` unprompted, the store knowing its clause count)
where `member/2`, whose alternatives live in a recursive clause body,
waits a third `;` and closes with `false.` — each the honest reading
of its own choice stack, and SWI's own machinery splits the same way
for its own reasons. All thirteen GREEN against a live server,
`red: 0`.

### The toplevel gets a line editor, written rather than linked

Task 61 could have been `-lreadline`, and deliberately is not: GNU
readline's license is not this project's BSD-2, and vendoring linenoise
would have made the editor the one piece of C in the tree somebody else
wrote. A line editor is not much code, so cocolog's toplevel now has
its own: the emacs keys (`C-a C-e C-b C-f C-k C-u C-w C-l`), the
arrows, Home, End and Delete read by their escape sequences and
normalised to their control twins so every key has exactly one arm in
the dispatch, and a history walked with `C-p`/`C-n` or up/down that
survives in `~/.cocolog_history` — capped at a thousand lines,
consecutive duplicates collapsed, the file brought up to date after
every goal so a session that dies keeps what was typed, and a
multi-line goal flattened to one line, which is what a list of lines
can hold. Byte-based and single-line by design: a multi-byte character
arrives as its bytes and the arrows step through them, and a goal wider
than the terminal wraps visually while the editing stays correct.

The terminal goes raw through termios, reached entirely through
cicili's `(code ...)` escapes so only C ever sees a `struct termios`,
and is put back before every way out — with `TCSADRAIN`, never
`TCSAFLUSH`, and that word is the story's one real finding. FLUSH
discards pending input: at a terminal that eats a fast typist's
type-ahead between goals, and under the pseudo-terminal tests it ate
the entire piped script — the pty had the whole session queued before
raw mode was entered, and FLUSH threw it away, which presented as an
editor that printed one prompt and found end of input. DRAIN waits for
output and keeps the queue.

Only the toplevel at a terminal comes near any of this. Piped input
takes the plain path it always took, byte for byte, and the piped half
of `test/repl.sh` stands untouched to prove it. The tty half is new,
through a pseudo-terminal from `script(1)`: the editing is proven by
what the READER got — an answer can only say `X = 1.` if the
backspaces really deleted — the arrows and `C-e` by an inserted digit
landing where the cursor stood, the history file by its contents after
a session, and the recall by a second session re-running the first
one's goal off two `C-p`s. All thirteen suite cases GREEN against a
live server, `red: 0`, and the emacs suite's 160 at 0 unexpected.

Two build lessons paid for along the way, kept here so they are paid
once: `make | head` kills a build by SIGPIPE when `head` exits, which
leaves the freshly transpiled objects unlinked and a STALE binary
passing for the new one — pipe a build into a file, never into `head`
— and an edited `.el` under an old `.elc` reports the old behaviour,
because Emacs loads the compiled file when one exists: recompile or
delete the `.elc` before believing a test.

### Tensors: a table of one vector field

Model parameters used to be text twice over — floats printed into
120-float chunk clauses, stored in the clauses table like any other
Prolog. Now they are what they are: doubles, in `cocolog::tensors`, a
table of one `Vector<Double>` column whose id columns (`kb`, `name`)
say WHICH tensor a row belongs to and whose `seq` says which piece,
512 doubles to a piece because a row has to fit in a page. The spec
stays a clause, so `torch_model(Name, _)` is still the question the
coworker pollers ask; what moved is only the weight of the thing.

The build ran outside-in, each layer proven before the next was
written. A sandboxed ZiguratIP home showed the Parsi compiler takes a
`Vector<Double>` column and emits a loadable table; the C client then
learned the type layer's own wire form for the vector — the descriptor
byte, a u32 count, each element tagged as the Double writer sends it
(`zg_write_dvector`/`zg_read_dvector`) — and a 600-double field went
into a real table row and came back **bit-exact** before a line of
engine code existed. The seam is three optional store hooks
(`tensor_put`, `tensor_row`, `tensor_forget` in kb.cicili), reached by
the torch module through the module API, filled per arrangement, and
null where the arrangement has no tensor storage — in which case
`model_save`/`model_load` fall back to the old clause chunks. That is
`--local` by nature — and was the embedded store by fact, until the
Cicili engine grew its VECTOR column kind (the story below).
`forget_all` and the vacuum clear and reclaim the new table with the
rest.

Zeytun reads it **paged**, the way anything over HTTP should face a
table that can hold a huge number of rows: the tensor page takes
`from` and `limit`, each response carries only the pieces asked for,
and the loader walks a piece per request — a tensor of any width
streams and never travels whole. The elements cross as the IEEE bits
of the double printed as a signed 64-bit integer, because the first
draft of the page printed `99.833417` where the row held
99.8334166468… — the default decimal rendering keeps six digits and a
model weight does not survive it. `Utility::double_bits` (new in
ZiguratIP's Core) is the exact-bits primitive; the reader is one
memcpy. Getting the page to compile offline at all fixed a ZiguratIP
compiler bug on the way: a generated PAGE header only forward-declared
the request and the response, the server's request-time compile got
the real headers by include-order accident, and somewhere a generated
header had been hand-patched above its own include guard to paper over
it — the compiler now emits the includes itself.

`test/tensors.sh`, the suite's fifteenth case, holds the whole story:
the wire arrangement trains and saves and `torch_params/3` answers
**false** — the parameters are rows, not clauses — while a second
process loads the model back at 100%; a 1994-parameter model makes
four pieces (`T 4`, `V 0 512` straight off the page) and loads over
`--http` exact; the embedded store holds the same rows through the
engine's VECTOR column (below — it kept clause chunks until then). All
fifteen GREEN against a live server, `red: 0`.

### The overlapping-writers hunt: the server walks free

Building the coworker tasks surfaced what looked like a server bug
with three faces — overlapping clause-write transactions that wedge;
overlapping writes that report success to every client and persist
nothing; a single 150-row consult that hangs where 100 passes — and
the hunt took each face apart and found **cocolog holding the knife
every time**. The server was reproduced doing exactly what it is
configured to do, and not once doing anything else: gdb on a "wedged"
server showed `FORGET_CLAUSES` actively walking cursors, its log
showed zero errors and idle client threads, and every missing row
traced to a client-side cause.

The three faces, unmasked:

* **The 150-row "hang" was O(N²), and it finished.** cocolog's
  `on_assert` hook re-synced the WHOLE predicate on every assert —
  forget every stored clause, re-assert all N — so consulting N rows
  cost N²/2 round-trips, each pass walking the MVCC dead versions the
  previous passes left. 40 rows took 3.7s, 120 took 35.4s, 150 took
  61s — past every timeout that had pronounced it hung. The fix is a
  batch mode on the Zigurat store (`coco_zg_batch`): `consult` and
  `run` mark predicates dirty as clauses arrive and sync each one
  once, at commit. The 61-second consult now takes **944ms**.
* **The "wedge" was the hunter's own timeout.** The stress goals spun
  `between/3` over millions of elements — more than ten minutes of
  engine time — and the harness killed the clients mid-transaction at
  60s. A killed client's open transaction rolls back; the next
  observer read an empty store and called it wedged.
* **The lost commits were real, and cocolog was losing them.** Three
  concurrent trainings oversubscribed the four cores, a training turn
  stretched to 122s of in-turn silence, and the server closed the
  idle connection at its configured `TIMEOUT: 60` — correctly. The
  commit then failed with "the connection is closed", and cocolog
  **ignored `zg_commit`'s return value** in all four places it
  commits (`run`, `query`, `consult`, the REPL): success reported,
  nothing persisted, nobody told. All four sites now fail loudly —
  `cocolog: commit failed: ...` and a non-zero exit — and the
  discipline the coworker READMEs name (long compute in `--local`,
  never inside a turn) keeps turns clear of the idle timeout in the
  first place.

The coworker scripts dropped their write mutex on the verdict: the
accumulator's three publishes and the balancer's three seed turns now
run concurrently, and both arrangements go GREEN that way, repeatedly,
on a fresh store and an aged one. One writer with parallel readers was
already proven (ruler), twelve machine-state writers were proven
(groups) — overlapping clause writers are now proven with them, and
the balancer got its ordering rule stated while the mutex came out: a
worker seeds its own third first and only then polls its peers, so
nobody waits on a worker that is itself still waiting.

### A VECTOR column kind for the Cicili MVCCS engine

The one gap the tensors table left: the embedded arrangement kept
model parameters in clause chunks, because the Parsi compiler's
generated Cicili twin degraded a `Vector<Double>` column to an int64.
Closed from the bottom up:

* **The engine.** `deftable` grew a third column kind beside int64 and
  `(TEXT c)`: `(VECTOR c)`, a `std::vector<double>` member (`dvec_t`,
  one `@define`) packed as an int64 count and the doubles, eight bytes
  each, exactly as they are — so what round-trips is the bits, the
  same claim the wire form and the Zeytun page already made.
  `schema_test` proves it at the engine level: a vector row goes in,
  comes back equal, and survives a restart.
* **The compiler.** The Parsi compiler's `.cicili` twin emitter now
  writes `(VECTOR col)` for a `Vector` column instead of degrading it,
  so `make schema` emits a loadable tensors twin beside the C++ pair.
* **The embedded backend.** embed.cicili imports the generated tensors
  twins and implements the three tensor procedures over them —
  `tensor_put`, `tensor_piece`, `tensors_forget`, the exact bodies
  02-procedures.parsi runs on the server — with the vector crossing
  the client seam through two new calls (`ce_write_dvector`,
  `ce_read_dvector`) that the C client's `zg_write_dvector`/
  `zg_read_dvector` dispatch to when the connection is embedded.
  `forget_all` empties the kb's tensors and the vacuum truncates and
  counts the fifth table, as on the server.
* **The hooks.** zigurat-kb.cicili installs the tensor hooks
  unconditionally now — the same client code serves both ends — so the
  embedded store stores model parameters as rows and `torch_params/3`
  answers **false** there too. The clause-chunk fallback remains for
  what it was always for: `--local`, which has no store behind it.

`test/tensors.sh`'s embed half flipped from "the parameters stay in
chunk clauses" to "the parameters are rows, not clauses", and a second
process loads the model back at 100% from the store files alone. All
fifteen GREEN against a live server, `red: 0`.

### use_module: libraries load at run time

cocolog loads libraries the way SWI does, and a module author has
exactly two languages -- MODULES.md now says so as a guide rather than
an implication. **Coco**: a clauses-only library is a `.pl` file on
`$COCOLOG_LIBRARY`, no build, no registration. **Cicili against the
module API**: the C half, always Cicili and never raw C, either linked
into the build as the five shipped libraries are, or written against
`lib/sdk.cicili` -- the same macros and API over opaque engine types --
compiled with `gcc -shared -fPIC`, and dlopen'd at run time.

`use_module(library(Name))`, as a goal and as a directive, resolves in
order: a registered module by that name; `Name.so` on the path, whose
`coco_library_entry` registers it exactly as a linked-in module
registers (the binary is linked `-rdynamic` so the object resolves the
module API from it; the entry answers the ABI version, and the loader
refuses any but 1 by name); `Name.pl`, registered as a clauses-only
module so reset-and-reload and never-twice come free. `library(Dir/Name)`
reaches subdirectories, SWI's `library(dcg/basics)` spelling. The module
loader itself went incremental on the way: a store now consults only the
modules it has not seen, counted per store, because a module registering
mid-session must not re-consult the ones before it.

A library loads INTO THE PROCESS, exactly as in SWI: its clauses are
muted, so a second process on the same knowledge base does not see them
-- `test/library.sh`, the suite's sixteenth case, proves that across
processes, along with both halves of a dlopen'd module answering
(`test/hoot.cicili`, the twenty-line worked example), load-twice
answering once, and the goal/directive split: a goal throws a catchable
error where a directive passes a not-found library over in silence --
borrowed files name libraries this build carries under other
arrangements, and the files case (byte-for-byte against SWI) is what
caught the first draft warning about them. All sixteen GREEN against a
live server, `red: 0`.

### An atom is as long as it is written

The parser truncated every name past 255 characters, silently, for the
whole life of the project. `'aaa…'` with a thousand `a`s in it read back
as 255 of them; `atom_length/2` agreed, because by then there was nothing
left to disagree with.

Neither side of the copy had that limit. The reader's token buffer is a
`coco_strbuf` and grows; the atom table stores names by length and holds
any of them. The 256 bytes were in `lib/syntax.cicili` between the two:
`coco_parse_primary` copied the NAME token into a `char [256]` with
`snprintf` — it has to copy, because `r->text` is one buffer that the
lookahead overwrites — and `coco_parse_term` did the same for an infix
operator. `snprintf` truncates and says nothing. So did we.

It surfaced three layers away and looking like someone else's fault. The
Coco fed a Bitcoin transaction — 408 hex digits, an ordinary thing to
hand a program — to a hash module, and got `domain_error(hexadecimal, …)`
back. The module was right: it had been given 255 digits, an odd count,
which is not hexadecimal. A second, independently written decoder in
another module failed identically on the same atom, and two unrelated
decoders agreeing is what said the fault was upstream of both. A length
sweep put it between 100 bytes and 200; `atom_length/2` on a 408-digit
atom answering 255 put it exactly.

Both sites now use `coco_tok_name`: a `char [256]` for the common case,
with no allocation at all, and a heap buffer that grows for anything
longer. The NAME case of `coco_parse_primary` became `coco_parse_named`
so the buffer is freed at one place rather than at each of the seven ways
that case can end; `coco_parse_term` keeps its buffer across the loop and
outside the recursion, since each nesting level parses its own operator.
`test/syntax.cicili` holds it at three lengths in the three places the
copy happened — a 1000-character atom, a 700-character functor, and a
400-character operand of an infix operator, that last one because the
operator path is a separate copy that a test of atoms alone would miss.

All sixteen cases GREEN against a live server, `red: 0`. The bug is worth
the paragraph it got: it never crashed, never warned, and never returned
an error of its own. It returned a confident answer about data that was
no longer the data it was given.

### The ISO bitwise functors, and a table that holds names as themselves

`/\`, `\/`, `xor`, `\` and `msb` were missing — from the operator table
and from the evaluator both. The way they were missing is the point.

`/\` is a symbolic token whether or not it is an operator, so the reader
did not refuse `X is 12 /\ 10`. It read `X is 12`, met an operator it did
not know, stopped, and left the rest of the term unread. **The goal
succeeded and bound X to 12** — a missing feature that answers is worse
than one that fails, which is why each of the new checks in
`test/solve.cicili` checks a value rather than that the goal ran.

They sit where ISO puts them: the three infix at 500 yfx alongside `+`
and `-`, so `A /\ B =:= C` needs no brackets; `\` at 200 fy beside unary
minus, and not to be confused with `\+` at 900. `msb` came along because
it is the one place an integer's bit width is asked for directly.

Getting `/\` into the table needed one change underneath. **A Cicili
string literal reaches C raw and may not end in a backslash** — `\"`
still escapes the closing quote — so `/\` has no spelling as a literal at
all, and the failure is not a nice one: the source is slurped and
re-read, the quote is swallowed, and the reader desynchronises and
reports something baffling from forty lines further down. The table
therefore now holds each name as **the text the reader will actually
see**, and `c-escape` puts back the escaping C needs on the way out. The
four names that were written pre-escaped — `\+`, `\=`, `\==`, `=\=` — are
written plainly now, and the two with no spelling at all are built from
their character codes. `lib/solve.cicili` matches them against
`COCO_OP_AND`/`COCO_OP_OR`/`COCO_OP_NOT` for the same reason.

The four rewritten names are checked explicitly, because rewriting a
working operator's spelling to fix a missing one is exactly the trade
that goes wrong silently. Sixteen cases GREEN against a live server,
`red: 0`.

### A dynamic declaration outlives the process, as README always said

README's table of store hooks says of `on_dynamic`: *a declaration is
about the knowledge base, so it has to outlive the process.* It did not.

The row was written and the row was read back — none of that was broken.
The gap was between them. Ordinary resolution loads a predicate LAZILY,
one at a time, through the `fetch` hook, and that path learns a
predicate's CLAUSES. `warm` is what learns the DECLARATIONS, and warm ran
only for `listing` and `$predicates`. So a predicate another process had
declared dynamic and never written to had no clauses to fetch, this
process had never heard of it, and the call raised `existence_error`
where SWI simply fails.

The engine already knew the distinction — "NO CLAUSES IS NOT THE SAME AS
UNDEFINED" is a comment above the branch that was being skipped. The fix
is to warm on the path that was about to throw, and re-check: a round
trip on an error path, which is not a path anything runs in a loop, and
no cost at all on any other. A genuinely undefined predicate raises
exactly as before, and `test/library.sh` checks both — the same case that
proves a library does NOT outlive the process now proves a declaration
does, which are the two halves of one question.

Found from The Coco, where a ledger node's `head_mark/2` was declared in
the file every node consults and was unknown to every node that ran.

### getenv/2, setenv/2, unsetenv/1

SWI's, and `getenv/2` fails rather than throws for a name that is not set
— "is this set" is an ordinary question with an ordinary no.

Worth having for a reason beyond convenience: this is the one channel by
which a value reaches a program WITHOUT passing through the knowledge
base. A consulted file becomes clauses and clauses become rows, so a
secret that must not become a row — a ledger node's signing key, a token
— had nowhere else to arrive from. The Coco's ledger nodes take their
private keys this way and no key appears in any file.

### TLS with and without a certificate, and `--port` retired

Two questions the four-transport work left open, settled by reading
ZiguratIP rather than by assuming.

**CAN ZIGURAT DO TLS WITHOUT A CLIENT CERTIFICATE? Yes.**
`loadzigurat.cpp` accepts REQUIRED (the default), OPTIONAL and NONE for
`SERVER/TLS_CLIENT_AUTH`, and `loadsecurity.cpp`'s `require_security()`
demands only the SERVER's own certificate, key and authority. The earlier
note here — that the binary protocol "has no anonymous use" — read a
default as a requirement, and is corrected above.

**WHAT A CERTIFICATE IS MANDATORY FOR IS PERMISSIONS**, and the mechanism
is worth writing down because it is the reverse of the obvious guess.
`zigurat_tls_handler` calls `Globals::set_peer(...)` for **every** TLS
peer, certificate or not; `Globals::permits` opens with
`if (!_identified) return true;`, and `globals.hpp` says why:
"Unidentified means a plain connection, where there is no peer to ask
about and everything is allowed -- turning TLS on is what turns access
control on." So with `SECURITY/PERMISSIONS_MODE: TRUE`, a **plain**
connection reaches everything, a TLS connection with a certificate
reaches what the certificate grants, and a TLS connection **without** one
is identified with an empty subject and an empty permission set and
reaches nothing. Encryption without a certificate is a real arrangement;
it is simply not an authorised one.

The client already did both -- `--cert`/`--key` were optional and only
their pairing was checked -- so what this turn added is the half that was
missing: **the refusal is legible**. Under TLS 1.3 a missing client
certificate is NOT a failed handshake: the server does not examine what
the client sent until the client has finished talking, so `SSL_connect`
succeeds and the alert arrives on the first read. That read used to
report `read failed: Success`, which sends the reader to the wrong end
entirely. `client/tls.c` now keeps the reason in the handle and hands it
back through `coco_client_tls_why`, and `client/zigurat.c` prefers it to
errno on a TLS connection:

    cocolog: no server at HOST:2160 -- read failed: tlsv13 alert
    certificate required -- this server wants a client certificate:
    --cert and --key

`test/zigurat-tls.sh` runs TWO terminators now, one per client-auth
setting, and holds all four combinations: a certificate offered where
none is wanted, a certificate where one is required, none where none is
required (which every other check in the case already was), and none
where one is required -- that last asserting the sentence above, word for
word. Eleven checks.

**`--port` IS DEPRECATED, AND STILL WORKS.** It is exactly `--tcp PORT`:
the same field, the same default, the same choice of arrangement. It
named a number back when there was one transport; there are four now and
each says WHICH as well as where.

**Nothing warns.** A deprecation notice on stderr every run would land in
the output of every script that pipes cocolog -- including several in
this suite that compare stderr exactly -- and the flag is a spelling
rather than a mistake. It is marked deprecated in `--help` and in the
documentation, the repository's own thirty-odd uses moved to `--tcp`
(tests, the two coworkers, the tutorials, the emacs mode and its test),
and `test/zigurat-lib.sh` holds it to both halves: that it still reaches
the server, and that it prints nothing while doing so.

### What the client is worth, measured somewhere else

A transport is only as good as what somebody builds on it, and the
strongest thing this one can say was not said here. **The Coco ran its
three consensus rungs over `--tls`** -- proof of authority, proof of
history, proof of stake -- and required every verdict to come back
unchanged: 25, 16 and 37 of them, seventy-eight in all, byte for byte
identical to the plaintext run, including the three attacks that are
supposed to succeed.

Worth recording here for two reasons.

**It is a real exercise of this client**, by a repository that treats
cocolog as frozen and did not touch a line of it. Three federated nodes
sealing, gossiping and re-verifying; a fork opened and closed by rule; a
chain audited by a process that consulted nothing; a PoH spine verified
in parallel segments; a stake-weighted BFT vote to finality -- all of it
through `zg_conn`'s TLS path, with the handshake before the greeting and
the framing surviving every one of them. `test/zigurat-tls.sh` proves the
transport in the small. That proved it under load, in an arrangement
nobody wrote to test a socket.

**And it is the honest bound on what TLS buys.** Every law those rungs
enforce is about CONTENT -- a hash recomputed, a signature checked
against a published key, a tick count re-run, a quorum weighed against
rows -- so none of them can be improved by encrypting the link, and none
should be. The Coco's case makes the point by putting an attacker on a
VERIFIED TLS connection to the same store the honest nodes use and
checking she is refused exactly as before: **an authenticated peer is not
a trusted one.** If anything in this repository ever tempts a caller to
skip verification because a connection was authenticated, that is the
bug, and this is the sentence it violated.

### Where cocolog stands among languages, written down once

The comparison a reader of this file eventually wants -- cocolog against
Python and against SWI-Prolog, across the language aspects, the backend
work, and the four separate senses of "AI-friendly" -- exists, and it is
deliberately NOT here. It is The Coco's `bench/languages.md`, in a
bench/ directory because a comparison is a benchmark of a different
kind, under the same rule as the harness beside it: no sentence claims a
number that has not been printed. The figures it does claim are this
family's own, arrangement beside each -- several of them this
repository's, from the tables above.

It OPENS with the everyday row, because that is where most language
choices are actually made -- ease of entry, syntax weight, how a page
reads, how much code a thought costs -- and there the "less code" claim
is a measurement rather than an adjective: The Coco's whole
proof-of-authority consensus is 39 non-comment lines, outnumbered by its
own explanatory prose nearly three to one. The concessions travel with
the number -- Python wins ease of entry outright, Prolog's steepness
lives in semantics rather than syntax (a better language to read RULES
in, a worse one to read EXECUTION in), and misapplied Prolog is MORE
code than Python, not less.

What it says about cocolog is what this file already says, gathered:
where it loses (strings are codes, no GC inside a solution, no clause
indexing, no tabling or constraints, no debugger GUI or profiler or
package manager, an ecosystem of one family) and where it differs in
POSITION rather than language -- a clause is a row other processes read,
a turn is a transaction, a suspended proof is data any process can
finish, determinism and metering are the engine's guarantee. Every one
of those sentences has its proving story somewhere in this file; the
comparison is the view of them from outside.

ONE copy, pointed at from here, from this repository's README, and from
The Coco's thesis -- because a comparison kept in two files disagrees
with itself eventually, and the losing rows are exactly the ones a
second copy would soften first.

### library(ray): a game window from clauses, held to pixels

raylib as a loadable module -- `modules/ray`, twenty-eight predicates
of window, 2D, 3D camera and primitives, polled keyboard and mouse,
frame time and a screenshot. raylib over every other engine for the one
property the module seam cannot fake: **the caller owns the loop.**
Input is polled, a frame is whatever happens between `ray_begin` and
`ray_end`, and nothing ever calls back -- so a game is a Prolog
predicate, and THE WORLD IS THE KNOWLEDGE BASE: entities are facts, the
draw is a `forall` over them, and everything this repository proves
about clauses -- freeze/thaw, a shared store, deterministic replay --
now applies to a game state.

The division is curl's, exactly. The C half is FLAT --
`'$ray_rect'(X,Y,W,H,R,G,B,A)` -- and the Coco half is the surface:
colors are NAMES from raylib's own palette carried as FACTS
(`ray_color/4` enumerates what raylib ships as #defines, which no
#define can), or `rgb/3`, or `rgba/4`; keys are names or letters or raw
codes, resolved by clauses. The by-value structs raylib passes
everywhere (`Color`, `Camera3D`, `Vector3`) are the one place the
`(code ...)` fire escape is used, for what it is for: describing them
to Cicili would emit a second definition beside raylib.h's, so each
such call gets a one-line scalar wrapper with no logic in it, and
everything scalar is declared to Cicili with `(decl)` and called from
Cicili.

**THE TEST IS HELD TO PIXELS, HEADLESS.** A graphics test that checks
exit codes has proved a linker worked. `test/ray.sh` runs the windowed
half under Xvfb -- a real X server, Mesa's software GL, only the glass
missing -- and its assertions are about FILES: the screenshot is a real
PNG by its magic bytes, and two frames the clauses drew differently are
different files byte for byte, which is what catches a context that
silently rendered nothing. A 2D frame drawn by a `forall` over asserted
facts, a 3D scene over a camera, and the loop's questions (closing,
frame time, mouse, an unpressed key) -- 17 checks.

One raylib behaviour was worth routing around: `TakeScreenshot` strips
the directory off the path it is given and writes the basename into its
own storage dir, so `ray_screenshot/1` goes through `LoadImageFromScreen`
+ `ExportImage` instead -- the path is honoured and a failed write is a
goal that FAILS rather than a warning on a log level the caller turned
off.

`tutorials/library/29-ray.pl` is the lesson, in the same commit as the
rule demands; like the curl lesson it assumes no display, holds the
clauses-only half to `must/3` and shows the loop. What is NOT there
yet, honestly: textures and models from files, sound, gamepads,
shaders, text measuring -- each a predicate away rather than a
redesign. `modules/ray/build.sh` says where a raylib comes from and why
the archive must be PIC.

## Known limitations, by choice

* **`--lock` is off by default and should stay off.** It makes cocolog processes
  take turns through a `flock`, one per transaction, which is what a server that
  cannot take concurrent clients needs and is about as concurrent as a queue. It
  is kept for talking to a ZiguratIP without the fixes above.
* **A claim has no lease.** `cocolog::machine_release` puts a machine back, and a
  worker that loses its connection calls it — but one killed outright strands its
  machine as claimed, and only `cocolog drop` clears it. A lease with an expiry
  would want a timestamp column and a clock the server agrees with.
* **The HTTP backend does not write.** One request is one transaction; a machine
  is a header row plus a row per chunk. Stated in `lib/zeytun-kb.cicili` and in
  `parsi/03-pages.parsi`.
* **`consult` asserts, it does not replace.** Consult the same file twice and
  every proof answers everything twice; `cocolog forget` is how a knowledge base
  is emptied.
* **A directive is not run as a goal.** `coco_directive` handles `dynamic/1` and
  `op/3`, ignores `discontiguous/1`, `multifile/1`, `module/2`, `use_module/1,2`
  and `meta_predicate/1`, and accepts `set_prolog_flag(double_quotes, codes)`
  because that is what the reader actually does — any other value of that flag
  is refused rather than nodded at. Anything else in a consulted file is an
  error naming what it was. `:- initialization(main).` and
  `:- ( catch(...) -> ... ; ... ).` would want an engine, and the store is a
  layer below the engine — the file that would have to call into solve.cicili is
  compiled before it.
* **`format/2` has no column directives.** `~t`, `~|` and `~+` measure what has
  been written since the last column stop, which is a second pass over the
  buffer this does not make. They raise an error naming themselves rather than
  being quietly ignored — dropping them turns a table into a run-on line and
  blames the program.
* **`with_output_to/2` redirects file descriptor 1**, because cocolog writes to
  the literal `stdout` in some seventy places rather than to a stream it passes
  around. Its goal runs in a nested engine, so — like `findall/3` — it cannot be
  suspended.
* **`listing` writes to stdout.** It is a builtin that prints, not one that
  builds a term, so a program cannot capture what it produces. `listing/0` and
  `listing/1` both answer once and are deterministic like every other builtin.
* **Builtins are all deterministic.** One that could leave a choice point behind
  — `between/3`, `clause/2` — would need the engine's choice stack in its hands.
  They belong in a Prolog-level library instead, which does not yet exist.
* **Resuming assumes the clauses have not moved.** A choice point remembers a
  predicate by name and the position of the next clause to try, so retracting
  from underneath a suspended machine makes it resume at the wrong one. This is
  the hazard `retract` has always had against a running query; the fix is to hold
  a transaction over the clause tables.
* **`asserta` rewrites its whole predicate** in the database, because putting a
  clause at the front changes every later clause's ordinal. O(n) per assert and
  always right.
* **The reader is lenient where SWI raises a syntax error.** `- \+ a` is an
  operator clash in SWI — `\+` is 900 and `-` admits an argument of at most
  200 — and this reader accepts it. Leniency is the safe direction: it accepts
  terms SWI rejects and misreads none of them. `dynamic foo` as an argument is
  the other way round: SWI accepts it and this reader wants brackets, because
  `dynamic` is 1150 and an argument is read at 999.
* **A list cell is `'.'`/2 and not SWI 7's `'[|]'`/2.** Deliberate: `.` is the
  traditional and ISO name. It shows in `X =.. L` on a list and nowhere else.
* **A module still cannot declare an operator from its C half**, though a
  program can with `op/3` and a module's Coco half can carry a `:- op(...)`.
  The remaining seam limits — no choice points, no per-session state — are the
  price of being suspendable and are not going to change.
* **No garbage collection.** The heap only grows within a solution; it is
  reclaimed on backtracking and on a new query. A long deterministic run that
  builds structure will grow until it ends.

## Not started

* Strings as a type; `"abc"` reads as a code list, which is the ISO default.
* Any indexing on the first argument. A predicate's clauses are tried in order.
* The Coco — the intelligent aggregator hub this project's machinery makes
  possible: chains as knowledge bases, consensus as clauses, contracts
  that learn. Its missions moved to their own repository, where the hub
  is built OF cocolog programs, not INTO cocolog — Prolog modules, its
  own Parsi objects and choreography, using cicili, ZiguratIP and
  cocolog and modifying none of them. cocolog itself remains what it
  is: a Prolog with advanced knowledge-base machinery, and the stories
  above are the foundations The Coco's STATUS.md builds on.
