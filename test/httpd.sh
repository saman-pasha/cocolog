#!/bin/sh
# library(httpd) -- the server half: routing, path safety, and two cocolog
# instances talking to each other over a socket.
#
# MOST OF THIS OPENS NO PORT, and that is the design paying off:
# httpd_answer/3 is the whole server minus the accept loop, so every
# routing rule is checkable as a pure goal. A test that had to raise a
# listener to find out what `/../../etc/passwd' does would be slower, and
# would be measuring the socket layer at the same time.
#
# THE PATH SECTION IS THE ONE THAT MATTERS. Traversal, encoded traversal,
# NUL truncation, and source disclosure are the four ways a static file
# server hands out something it was never asked for. Each has a case here
# with the file it would have leaked actually sitting on disk, because a
# defence tested against a file that is not there proves nothing.
#
# THE LAST SECTION IS THE POINT OF THE LIBRARY: one cocolog serves pages
# written in Prolog and a SECOND fetches them with library(curl), which
# crosses sockets, the grammar, the router and libcurl in one go.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
export COCOLOG_LIBRARY="$ROOT/library"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-50s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else
    printf 'FAIL %-50s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi

U="use_module(library(httpd))"
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

# The tree every static case reads. Written rather than assumed, and the
# secret is written OUTSIDE the root on purpose: a traversal case has to
# have something real to reach or it cannot fail.
D=/tmp/coco-httpd-test
rm -rf "$D"; mkdir -p "$D/root/sub" "$D/pages"
printf '<h1>home</h1>\n'      > "$D/root/index.html"
printf 'plain text here\n'    > "$D/root/a.txt"
printf 'deeper\n'             > "$D/root/sub/b.txt"
printf '\211PNG\r\n\032\n'    > "$D/root/i.png"
printf 'secret_clause.\n'     > "$D/root/leak.pl"
printf 'THE SECRET\n'         > "$D/outside.txt"
head -c 5000 /dev/zero | tr '\0' 'x' > "$D/root/big.txt"

R="[root('$D/root')]"
# A request term, built here so each case is one line. Path is what
# library(http) would have handed over: already percent-decoded.
req() { echo "request($1,'$2',[],http(1,1),[],[])"; }

# Status only, out of the response bytes.
st() { q "httpd_answer($R, $(req "$1" "$2"), Cs), atom_codes(A, Cs),
          sub_atom(A, 9, 3, _, S), write(answer(S)), nl"; }

echo "-- a file comes back, with the right type and the right length"
check "a text file is 200" "$(st get /a.txt)" "200"
check "and carries its content type" \
  "$(q "httpd_answer($R, $(req get /a.txt), Cs), atom_codes(A, Cs),
        sub_atom(A, B, _, _, 'text/plain'), B > 0, write(answer(found)), nl")" "found"
check "the body is the file" \
  "$(q "httpd_answer($R, $(req get /a.txt), Cs), atom_codes(A, Cs),
        sub_atom(A, _, 15, 1, X), write(answer(X)), nl")" "plain text here"
check "a nested file resolves" "$(st get /sub/b.txt)" "200"
check "a directory answers with its index" "$(st get /)" "200"
check "an unknown extension is not text" \
  "$(q "httpd_answer($R, $(req get /i.png), Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, 'image/png') -> X = png ; X = other ),
        write(answer(X)), nl")" "png"
check "a file that is not there is 404" "$(st get /nope.txt)" "404"

echo "-- every byte of a binary file survives the round trip"
# The PNG signature has a high byte (0x89) and a CR in it. If the body were
# carried as an atom anywhere in the server, this is where it would show.
check "the body length is the file's byte count" \
  "$(q "httpd_answer($R, $(req get /i.png), Cs), length(Cs, T),
        size_file('$D/root/i.png', F), H is T - F, write(answer(H)), nl")" \
  "$(printf 'HTTP/1.1 200 OK\r\nContent-Length: 8\r\nContent-Type: image/png\r\n\r\n' | wc -c)"

echo "-- the path rules, with a real file waiting on the other side"
check "plain traversal is refused" "$(st get /../outside.txt)" "400"
check "and so is a deeper one" "$(st get /sub/../../outside.txt)" "400"
# `..' that stays inside is LEGITIMATE and must still work -- this is why
# the rule resolves rather than rejecting every `..' on sight.
check "but .. that stays inside still resolves" "$(st get /sub/../a.txt)" "200"
check "a lone .. at the root is refused" "$(st get /..)" "400"
check "// collapses rather than escaping" "$(st get //a.txt)" "200"
# A NUL NEVER REACHES THE ROUTER. An atom in cocolog is a C string, so
# library(http) has already truncated the path at the NUL by the time it
# builds one -- `/a.txt\0/../../outside.txt' IS the atom `/a.txt'. That is
# safe in the only direction that matters, because truncation can only make
# a path SHORTER, and a prefix of a contained path is still contained. The
# check is that the trailing half cannot be reached, not that it is
# rejected: there is nothing left to reject.
check "a NUL truncates the path rather than extending it" \
  "$(q "atom_codes(P, [0'/, 0'a, 0'., 0't, 0'x, 0't, 0, 0'/, 0'., 0'., 0'/,
                       0'., 0'., 0'/, 0'o, 0'u, 0't]),
        atom_length(P, L), write(answer(L)), nl")" "6"
check "and what it truncates to is the safe file, not the escape" \
  "$(q "atom_codes(P, [0'/, 0'a, 0'., 0't, 0'x, 0't, 0, 0'/, 0'., 0'., 0'/,
                       0'., 0'., 0'/, 0'o, 0'u, 0't]),
        httpd_answer($R, request(get, P, [], http(1,1), [], []), Cs),
        atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "200"
# THE DECODED FORM IS THE ONE THAT ARRIVES. library(http) decodes the
# target before the server sees it, so this is the byte sequence a request
# for `/..%2foutside.txt' actually turns into.
check "encoded traversal is the same request, and refused" \
  "$(st get /../outside.txt)" "400"

echo "-- a .pl file is never served as a file"
check "an unrouted .pl is 404, not its source" "$(st get /leak.pl)" "404"
check "and its text does not appear in the answer" \
  "$(q "httpd_answer($R, $(req get /leak.pl), Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, secret_clause) -> X = leaked ; X = safe ),
        write(answer(X)), nl")" "safe"

echo "-- methods, and how big is too big"
check "a POST to a static file is 405" "$(st post /a.txt)" "405"
check "which says what it would allow" \
  "$(q "httpd_answer($R, $(req post /a.txt), Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, 'Allow: GET, HEAD') -> X = yes ; X = no ),
        write(answer(X)), nl")" "yes"
check "a file over max_file is 413, not a slow 200" \
  "$(q "httpd_answer([root('$D/root'), max_file(1024)], $(req get /big.txt), Cs),
        atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "413"
check "and under it, the same file is 200" \
  "$(q "httpd_answer([root('$D/root'), max_file(999999)], $(req get /big.txt), Cs),
        atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "200"

# A REGRESSION GUARD FOR A BUILTIN, kept here because this is what found
# it. `sub_atom/5' had two fixed 4096-byte buffers and reported the overflow
# as `type_error(atom, <the atom>)' -- a diagnosis naming the one thing that
# was not wrong. 4095 characters worked and 4096 threw, which is why nothing
# had noticed: every test atom until now was short. A 5 KiB response is an
# ordinary web page, so the server tripped over it on its first big file.
echo "-- and the builtin this library broke on the way in"
check "sub_atom reaches past 4096 characters" \
  "$(timeout 60 "$C" query "length(L, 20000), maplist(=(0'x), L), atom_codes(A, L),
        sub_atom(A, 0, 3, Aft, S), atomic_list_concat([S, '-', Aft], X),
        write(answer(X)), nl" 2>/dev/null \
     | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//')" "xxx-19997"
check "and a real non-atom still gets the real error" \
  "$(timeout 60 "$C" query "catch(sub_atom(f(1), 0, 1, _, _), error(E, _),
        ( E = type_error(atom, _) -> write(answer(type_error)) ; write(answer(other)) )), nl" \
     2>/dev/null | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//')" "type_error"

echo "-- the fence itself, which is why a page cannot end the server"
b() { timeout 90 "$C" query "$1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
check "a runaway is stopped and says so" \
  "$(b "call_limited((between(1,100000000,_), fail), 5000, R), write(answer(R)), nl")" \
  "inference_limit_exceeded"
# A FENCE THAT LOST THE ANSWER would be useless: the page's reply comes back
# as bindings, so they have to survive a success.
check "a success keeps its bindings" \
  "$(b "call_limited(append(X, [c], [a,b,c]), 10000, _), write(answer(X)), nl")" "[a,b]"
# ...and must NOT survive the ceiling, or a half-run page would answer with
# half a term.
check "and the ceiling leaves none behind" \
  "$(b "call_limited((X = bound, between(1,100000000,_), fail), 5000, _),
        ( var(X) -> W = unbound ; W = X ), write(answer(W)), nl")" "unbound"
check "a goal that merely fails, fails" \
  "$(b "( call_limited(fail, 1000, _) -> W = succeeded ; W = failed ),
        write(answer(W)), nl")" "failed"
# ZERO WOULD MEAN `NO LIMIT' one layer down, where 0 is how max_steps spells
# unbounded -- so asking for nothing would silently get everything.
check "a ceiling of zero is refused, not read as unlimited" \
  "$(b "catch(call_limited(true, 0, _), error(E, _),
        ( E = domain_error(positive_integer, _) -> write(answer(refused))
        ; write(answer(other)) )), nl")" "refused"

# THE ONE THAT COST A FIELD ON THE ENGINE. A nested engine unwinds its own
# stack, so the ball's term is gone by the time control is back -- and the
# first version of this builtin let an exception out as a message only,
# which turned every page error into a dead request handler. The ball is now
# kept in the store and thrown again outside.
check "an exception inside is catchable outside" \
  "$(b "catch(call_limited((X is 1/0, write(X)), 10000, _), error(E, _),
        ( E = evaluation_error(zero_divisor) -> write(answer(reraised))
        ; write(answer(other)) )), nl")" "reraised"
check "and the recovery goal really runs" \
  "$(b "catch(call_limited(atom_length(1,_,_), 10000, _), _,
        (Y = recovered, write(answer(Y)))), nl")" "recovered"
# A catch INSIDE the fence is inside the nested engine with the throw, so it
# never needed any of that machinery -- checked so the two paths stay apart.
check "a catch within the goal still works normally" \
  "$(b "call_limited(catch(atom_length(1,_,_), _, true), 10000, R),
        write(answer(R)), nl")" "true"

# THE CEILING NARROWS, NEVER WIDENS. An inner limit of 100 million inside an
# outer budget of 3000 gets the 3000 -- otherwise a fenced goal would be a
# way AROUND the outer budget rather than a limit under it. Needs a
# database, because `step' is the only thing that sets an outer budget, and
# --embed is one without a server.
KB="$D/fencekb"
mkdir -p "$KB"
if timeout 60 "$C" --embed "$KB" start fencer \
     "call_limited((between(1,100000000,_), fail), 100000000, R), write(r(R)), nl" \
     >/dev/null 2>&1; then
  got=$(timeout 120 "$C" --embed "$KB" --steps 3000 step fencer 2>&1 \
        | grep -oE 'suspended at [0-9]+' | head -1)
  # 3002 rather than 100000000: without the narrowing this runs for minutes
  check "an outer budget narrows an inner ceiling" \
    "$(echo "$got" | grep -qE 'suspended at 3[0-9]{3}$' && echo narrowed || echo "$got")" \
    "narrowed"
  got=$(timeout 120 "$C" --embed "$KB" --steps 5000 finish fencer 2>&1 \
        | grep -oE 'r\(inference_limit_exceeded\)' | head -1)
  check "and the program carries on past the fence" "$got" "r(inference_limit_exceeded)"
else
  echo "   (outer-budget case SKIPPED -- no embedded store here)"
fi

echo "-- HEAD says what GET would, without the body"
check "HEAD is 200" "$(st head /a.txt)" "200"
# THE WHOLE POINT: the length is the FILE's, not zero. A server that
# answered HEAD with an empty body and a computed Content-Length would
# report 0 here and every client asking how big a file is would be lied to.
check "HEAD reports the real Content-Length" \
  "$(q "httpd_answer($R, $(req head /a.txt), Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, 'Content-Length: 16') -> X = right ; X = wrong ),
        write(answer(X)), nl")" "right"
check "and sends no body at all" \
  "$(q "httpd_answer($R, $(req head /a.txt), Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, 'plain text') -> X = body ; X = none ),
        write(answer(X)), nl")" "none"

echo "-- no root means no files, rather than the working directory"
check "a server with no root serves nothing" \
  "$(q "httpd_answer([], $(req get /a.txt), Cs), atom_codes(A, Cs),
        sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "404"

echo "-- pages: clauses answering a path"
cat > "$D/pages/hello.pl" <<'PL'
httpd_page('/hello', _, reply(200, ['Content-Type'-'text/plain'], 'hi from a clause')).

httpd_page('/who', request(_,_,Query,_,_,_), reply(200, [], Answer)) :-
    memberchk(name-N, Query),
    atom_concat('hello ', N, Answer).

httpd_page('/boom', _, _) :- X is 1/0, write(X).

%% The one that would take the server with it. Not an infinite loop written
%% as one -- between/3 to a hundred million is finite and would simply take
%% minutes, which is the same thing to anybody waiting on the socket.
httpd_page('/loop', _, _) :- between(1, 100000000, _), fail.

%% Claims a .pl path, to prove a page may be REACHED at one even though a
%% .pl file is never SERVED at one.
httpd_page('/app.pl', _, reply(200, [], 'a page, not a file')).
PL
P="$Q, use_module('$D/pages/hello.pl')"
pq() { timeout 60 "$C" query "$U, use_module('$D/pages/hello.pl'), $1" 2>/dev/null \
       | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

check "a page answers its path" \
  "$(pq "httpd_answer($R, $(req get /hello), Cs), atom_codes(A, Cs),
         sub_atom(A, _, 16, 0, X), write(answer(X)), nl")" "hi from a clause"
check "a page reads the query string" \
  "$(pq "httpd_answer($R, request(get,'/who',[name-ada],http(1,1),[],[]), Cs),
         atom_codes(A, Cs), sub_atom(A, _, 9, 0, X), write(answer(X)), nl")" "hello ada"
# A page that fails did not claim the path, so the static half gets it --
# which here means 404. A page that THROWS claimed it and broke: 500.
check "a page that fails falls through to static" \
  "$(pq "httpd_answer($R, request(get,'/who',[],http(1,1),[],[]), Cs),
         atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "404"
check "a page that throws is 500, not a fall-through" \
  "$(pq "httpd_answer($R, $(req get /boom), Cs), atom_codes(A, Cs),
         sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "500"
check "a page may claim a .pl path the file rule refuses" \
  "$(pq "httpd_answer($R, $(req get /app.pl), Cs), atom_codes(A, Cs),
         sub_atom(A, _, 18, 0, X), write(answer(X)), nl")" "a page, not a file"
check "a page shadows a file of the same path" \
  "$(pq "httpd_answer($R, $(req get /hello), Cs), atom_codes(A, Cs),
         sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "200"
# THE CEILING, and the case the whole fence exists for. Without it this
# request never comes back and neither does the server.
check "a page that loops is stopped, and answers 500" \
  "$(pq "httpd_answer([root('$D/root'), page_limit(20000)], $(req get /loop), Cs),
         atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "500"
check "and says what happened, not just that something did" \
  "$(pq "httpd_answer([root('$D/root'), page_limit(20000)], $(req get /loop), Cs),
         atom_codes(A, Cs),
         ( sub_atom(A, _, _, _, 'inference limit') -> X = named ; X = vague ),
         write(answer(X)), nl")" "named"
# AND THE SERVER IS STILL THERE afterwards, which is the actual claim. A
# fence that stopped the page by stopping the process would pass the two
# cases above and be worthless.
check "the next request after a stopped page is answered normally" \
  "$(pq "httpd_answer([root('$D/root'), page_limit(20000)], $(req get /loop), _),
         httpd_answer($R, $(req get /a.txt), Cs), atom_codes(A, Cs),
         sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "200"
check "a page well under the ceiling is untouched by it" \
  "$(pq "httpd_answer([root('$D/root'), page_limit(20000)], $(req get /hello), Cs),
         atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "200"

check "with pages off, the same request is static again" \
  "$(pq "httpd_answer([root('$D/root'), pages(false)], $(req get /hello), Cs),
         atom_codes(A, Cs), sub_atom(A, 9, 3, _, S), write(answer(S)), nl")" "404"

echo "-- and now over a real socket, one cocolog to another"
if [ ! -f "$ROOT/library/curl.so" ]; then
  echo "   (client half SKIPPED -- no library/curl.so; sh modules/curl/build.sh)"
else
cat > "$D/server.pl" <<PL
:- use_module(library(httpd)).
:- use_module('$D/pages/hello.pl').

serve(Port) :- httpd_serve(Port, [root('$D/root')], 4).

%% ONE ACCEPT. Everything the keep-alive cases do happens on the single
%% connection that accept returns, which is what makes "one accept, three
%% answers" a proof rather than a coincidence.
serve_ka(Port) :- httpd_serve(Port, [root('$D/root')], 1).
serve_capped(Port) :-
    httpd_serve(Port, [root('$D/root'), max_keep_alive(2)], 1).
serve_noka(Port) :-
    httpd_serve(Port, [root('$D/root'), keep_alive(false)], 1).
PL

# Detached: a plain \`&' from a tool call does not survive the turn, the
# same hazard test/curl.sh names.
setsid timeout 40 "$C" run "$D/server.pl" "serve(18860)" >/dev/null 2>&1 &
sleep 3
cq() { timeout 60 "$C" query "use_module(library(curl)), $1" 2>/dev/null \
       | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

check "a second cocolog fetches a static file" \
  "$(cq "curl_get('http://127.0.0.1:18860/a.txt', S, B), atom_codes(A, B),
         sub_atom(A, 0, 15, _, X), atomic_list_concat([S,' ',X], Y),
         write(answer(Y)), nl")" "200 plain text here"
check "and a page computed by clauses" \
  "$(cq "curl_get('http://127.0.0.1:18860/hello', S, B), atom_codes(A, B),
         atomic_list_concat([S,' ',A], Y), write(answer(Y)), nl")" \
  "200 hi from a clause"
# CURL WILL NOT SEND A TRAVERSAL, which is worth knowing and useless here:
# libcurl applies RFC 3986 remove_dot_segments itself, so
# `http://host/../outside.txt' goes out as `GET /outside.txt'. Verified by
# putting a socket in front of it and reading the request line. To ask the
# SERVER what it does, the bytes have to be written by hand -- which is
# library(tcp), and keeps the whole test inside this repository.
check "raw traversal bytes, straight down a socket, are refused" \
  "$(timeout 60 "$C" query "use_module(library(tcp)), tcp_connect('127.0.0.1', 18860, S),
        atom_codes(Q, \"GET /../outside.txt HTTP/1.1\\r\\nHost: x\\r\\n\\r\\n\"),
        atom_codes(Q, QC), tcp_write(S, QC), tcp_read(S, 4096, 5000, R),
        tcp_close(S), atom_codes(A, R), sub_atom(A, 9, 3, _, St),
        write(answer(St)), nl" 2>/dev/null \
     | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//')" "400"
wait 2>/dev/null
fi

echo "-- keep-alive: more than one request down one socket"
if [ ! -x "$C" ]; then :; else
# THE CLIENT HAS TO HOLD THE SOCKET, which curl will not be told to do
# per-request and which is the whole thing under test -- so it is written
# with library(tcp), in this repository, one connection and several
# write/read turns on it.
cat > "$D/client.pl" <<'PL'
:- use_module(library(tcp)).
%% Sends each request in Reqs down ONE connection and collects what came
%% back. Status only, plus whether the response said keep-alive or close --
%% between them that is the entire contract.
talk(Port, Reqs, Out) :-
    tcp_connect('127.0.0.1', Port, S),
    turns(S, Reqs, Parts),
    tcp_close(S),
    atomic_list_concat(Parts, ' ', Out).

turns(_, [], []).
turns(S, [R|Rs], [P|Ps]) :-
    atom_codes(R, C), tcp_write(S, C),
    (   tcp_read(S, 65536, 3000, Bytes)
    ->  atom_codes(A, Bytes), verdict(A, P)
    ;   P = 'no-answer'
    ),
    turns(S, Rs, Ps).

%% BOTH HALVES MATTER: a server can answer correctly and still have closed,
%% and the next turn would then read nothing at all.
verdict(A, P) :-
    sub_atom(A, 9, 3, _, St),
    (   sub_atom(A, _, _, _, 'Connection: keep-alive') -> K = keep
    ;   sub_atom(A, _, _, _, 'Connection: close')      -> K = close
    ;   K = silent
    ),
    atomic_list_concat([St, '/', K], P).

%% Everything in one write, which is what pipelining is.
pipeline(Port, Text, Out) :-
    tcp_connect('127.0.0.1', Port, S),
    atom_codes(Text, C), tcp_write(S, C),
    drain(S, [], Bytes),
    tcp_close(S),
    atom_codes(A, Bytes),
    findall(x, sub_atom(A, _, _, _, 'HTTP/1.1 200'), Xs),
    length(Xs, N),
    atomic_list_concat([n, N], Out).

%% READ UNTIL NOTHING MORE COMES. The server answers a pipelined pair with
%% TWO writes, so they need not arrive in one segment -- and reading once
%% and counting is how this case first claimed the server had answered ONE
%% request when a socket-level check showed it had answered both. The
%% timeout ends the drain: after the last response the server is waiting
%% for another request, so nothing further arrives.
drain(S, Acc, Out) :-
    (   tcp_read(S, 65536, 2000, B)
    ->  append(Acc, B, More),
        drain(S, More, Out)
    ;   Out = Acc
    ).
PL

G="use_module('$D/client.pl')"
kq() { timeout 60 "$C" query "$G, $1" 2>/dev/null \
       | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

# ONE ACCEPT, several requests. httpd_serve/3 counts ACCEPTS, so a server
# told to accept once that answers three requests has kept the connection
# alive -- there was no second connection for them to arrive on.
setsid timeout 40 "$C" run "$D/server.pl" "serve_ka(18861)" >/dev/null 2>&1 &
sleep 3
check "three requests, one connection, one accept" \
  "$(kq "talk(18861, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                      'GET /hello HTTP/1.1\r\nHost: x\r\n\r\n',
                      'GET /nope HTTP/1.1\r\nHost: x\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/keep 200/keep 404/keep"
wait 2>/dev/null

# `Connection: close' ENDS IT, and the response says so before it does.
setsid timeout 40 "$C" run "$D/server.pl" "serve_ka(18862)" >/dev/null 2>&1 &
sleep 3
check "a client asking to close is told close, and then is" \
  "$(kq "talk(18862, ['GET /a.txt HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n',
                      'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/close no-answer"
wait 2>/dev/null

# HTTP/1.0 IS THE OTHER HALF OF RFC 7230 6.3, and the half that is easy to
# get wrong: it must NOT persist unless it asked to. A 1.0 client left
# hanging waits for an end-of-body that never comes.
setsid timeout 40 "$C" run "$D/server.pl" "serve_ka(18863)" >/dev/null 2>&1 &
sleep 3
check "HTTP/1.0 closes unless it asks to persist" \
  "$(kq "talk(18863, ['GET /a.txt HTTP/1.0\r\nHost: x\r\n\r\n',
                      'GET /a.txt HTTP/1.0\r\nHost: x\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/close no-answer"
wait 2>/dev/null

setsid timeout 40 "$C" run "$D/server.pl" "serve_ka(18864)" >/dev/null 2>&1 &
sleep 3
check "and persists when it does ask" \
  "$(kq "talk(18864, ['GET /a.txt HTTP/1.0\r\nHost: x\r\nConnection: keep-alive\r\n\r\n',
                      'GET /a.txt HTTP/1.0\r\nHost: x\r\nConnection: keep-alive\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/keep 200/keep"
wait 2>/dev/null

# PIPELINING: both requests in ONE write. This is what http_request/3's
# remainder buys -- without it the second request's bytes are read as part
# of the first and silently dropped.
setsid timeout 40 "$C" run "$D/server.pl" "serve_ka(18865)" >/dev/null 2>&1 &
sleep 3
check "two requests in one write get two answers" \
  "$(kq "pipeline(18865, 'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\nGET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n', O),
         write(answer(O)), nl")" "n2"
wait 2>/dev/null

# THE CEILING ON A CONNECTION. max_keep_alive(2) means the SECOND response
# is the last, and says close rather than simply going quiet.
setsid timeout 40 "$C" run "$D/server.pl" "serve_capped(18866)" >/dev/null 2>&1 &
sleep 3
check "max_keep_alive closes the connection, and announces it" \
  "$(kq "talk(18866, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                      'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                      'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/keep 200/close no-answer"
wait 2>/dev/null

# AND OFF IS OFF, for anyone who would rather pay the handshakes.
setsid timeout 40 "$C" run "$D/server.pl" "serve_noka(18867)" >/dev/null 2>&1 &
sleep 3
check "keep_alive(false) closes after one, as it always did" \
  "$(kq "talk(18867, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                      'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O),
         write(answer(O)), nl")" \
  "200/close no-answer"
wait 2>/dev/null
fi

echo "-- the worker pool: a slow request no longer holds everybody"
if [ ! -f "$ROOT/library/thread.so" ]; then
  echo "   (pool SKIPPED -- no library/thread.so; sh modules/thread/build.sh)"
elif ! command -v curl >/dev/null 2>&1; then
  echo "   (pool SKIPPED -- no curl to make concurrent requests with)"
else
cat > "$D/pages2.pl" <<'PL'
%% A page that takes a WHILE, and one that does not. Under one connection
%% at a time the slow one blocks every other client; that is the whole
%% claim the pool makes, and it cannot be checked without a slow page.
httpd_page('/slow', _, reply(200, [], done)) :- pool_spin(4000000).
httpd_page('/fast', _, reply(200, [], quick)).
%% A page that BREAKS, to check one bad request does not take a worker
%% with it -- a pool that dies a thread at a time is worse than no pool.
httpd_page('/boom2', _, _) :- X is 1/0, write(X).
pool_spin(0) :- !.
pool_spin(N) :- M is N - 1, pool_spin(M).
PL
cat > "$D/pool.pl" <<PL
:- use_module(library(httpd)).
:- use_module('$D/pages2.pl').

pool(Port, N, Accepts) :- httpd_serve(Port, [root('$D/root'), workers(N)], Accepts).
alone(Port, Accepts)   :- httpd_serve(Port, [root('$D/root')], Accepts).
PL

hit() { timeout 90 curl -s -o /dev/null -w '%{http_code}' "$1"; }

# It serves at all, through a worker rather than the accepting thread.
setsid timeout 60 "$C" run "$D/pool.pl" "pool(18910, 4, 2)" >/dev/null 2>&1 &
sleep 3
check "a static file comes back through the pool" "$(hit http://127.0.0.1:18910/a.txt)" "200"
check "and so does a page" "$(hit http://127.0.0.1:18910/fast)" "200"
wait 2>/dev/null

# ONE SLOW REQUEST, for the ratio below to mean anything.
setsid timeout 90 "$C" run "$D/pool.pl" "alone(18911, 1)" >/dev/null 2>&1 &
sleep 3
t0=$(date +%s%3N); hit http://127.0.0.1:18911/slow >/dev/null; t1=$(date +%s%3N)
one=$((t1-t0)); wait 2>/dev/null

# FOUR AT ONCE, one connection at a time: they queue, and the wall clock
# is four of them end to end. This is the arrangement the pool replaces.
setsid timeout 120 "$C" run "$D/pool.pl" "alone(18912, 4)" >/dev/null 2>&1 &
sleep 3
t0=$(date +%s%3N)
for i in 1 2 3 4; do hit http://127.0.0.1:18912/slow >/dev/null & done; wait
t1=$(date +%s%3N); serial=$((t1-t0))

# FOUR AT ONCE THROUGH FOUR WORKERS: they overlap.
setsid timeout 120 "$C" run "$D/pool.pl" "pool(18913, 4, 4)" >/dev/null 2>&1 &
sleep 3
t0=$(date +%s%3N)
for i in 1 2 3 4; do hit http://127.0.0.1:18913/slow >/dev/null & done; wait
t1=$(date +%s%3N); pooled=$((t1-t0))

printf '     one %sms; four serially %sms; four pooled %sms\n' "$one" "$serial" "$pooled"
# THE THRESHOLD IS LOOSE ON PURPOSE. Four requests overlapping cannot take
# three times one of them; four queued cannot take less than two. How much
# more or less depends on the machine, and this is not a benchmark.
check "queued, four slow requests take about four times one" \
  "$(awk -v o="$one" -v s="$serial" 'BEGIN { print (o > 0 && s > o * 2) ? "queued" : "overlapped" }')" \
  "queued"
check "pooled, the same four take about one" \
  "$(awk -v o="$one" -v p="$pooled" 'BEGIN { print (o > 0 && p < o * 3) ? "overlapped" : "queued" }')" \
  "overlapped"

# A PAGE THAT THROWS MUST NOT TAKE ITS WORKER WITH IT. The pool answers
# 500 and the same worker takes the next connection.
setsid timeout 60 "$C" run "$D/pool.pl" "pool(18914, 2, 2)" >/dev/null 2>&1 &
sleep 3
check "a page that throws is 500, from a worker" "$(hit http://127.0.0.1:18914/boom2)" "500"
check "and the pool serves the next request anyway" "$(hit http://127.0.0.1:18914/fast)" "200"
wait 2>/dev/null

# ASKING FOR WORKERS WITHOUT library(thread) SAYS SO, and there is no
# case for it here because it CANNOT BE PRODUCED without moving a build
# artifact out of the way mid-run. Pointing COCOLOG_LIBRARY at a
# directory with no thread.so does not do it: the loader also searches
# `<exedir>/library', which is where thread.so lives, and that fallback
# is deliberate -- it is what lets an installed cocolog find its own
# libraries. Verified by hand with the file genuinely moved aside:
#
#   cocolog: uncaught exception:
#     error(existence_error(procedure,channel_new/2),
#           'httpd: workers(N) needs library(thread) --
#            sh modules/thread/build.sh')
#
# A case that renamed a .so and put it back would fail dirty if the run
# died in between, and would be testing the rename.
fi

echo "-- pages that reach the knowledge base, from a worker thread"
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
KB="--kb httpd_kb_case --host $HOST --port $PORT --timeout 30"
if [ ! -f "$ROOT/library/thread.so" ]; then
  echo "   (SKIPPED -- no library/thread.so)"
elif ! command -v curl >/dev/null 2>&1; then
  echo "   (SKIPPED -- no curl)"
elif ! timeout 20 "$C" $KB list >/dev/null 2>&1; then
  echo "   (SKIPPED -- no Zigurat server at $HOST:$PORT)"
else
timeout 60 "$C" $KB forget >/dev/null 2>&1
timeout 60 "$C" $KB query "assertz(stock(widget, 7))" >/dev/null 2>&1

cat > "$D/kbpages.pl" <<'PL'
%% READS the knowledge base -- a clause a DIFFERENT PROCESS wrote, which
%% is the whole claim: a worker's store is its own, so this can only work
%% through a connection of the thread's own.
httpd_page('/stock', _, reply(200, [], Body)) :-
    stock(widget, N),
    atomic_list_concat(['widget ', N], Body).

%% ...and WRITES it. Every hit adds a row, so counting them afterwards
%% from another process counts requests that really settled.
httpd_page('/visit', _, reply(200, [], counted)) :- assertz(visit(now)).
PL
cat > "$D/kbsrv.pl" <<PL
:- use_module(library(httpd)).
:- use_module('$D/kbpages.pl').
pooled(P, W, A) :- httpd_serve(P, [root('$D/root'), workers(W)], A).
alone(P, A)     :- httpd_serve(P, [root('$D/root')], A).
PL
kb_count() { timeout 60 "$C" $KB query \
  "findall(x, visit(_), L), length(L, N), write(answer(N)), nl" 2>/dev/null \
  | grep -a '^answer(' | head -1 | sed 's/^answer(//; s/)$//'; }

# A WORKER READS. Before the kb hook a thread was a --local proof whatever
# the parent was, and this page answered 404 because stock/2 was not there.
setsid timeout 60 "$C" $KB run "$D/kbsrv.pl" "pooled(18930, 3, 1)" >/dev/null 2>&1 &
sleep 3
check "a page in a worker reads what another process wrote" \
  "$(timeout 30 curl -s http://127.0.0.1:18930/stock)" "widget 7"
wait 2>/dev/null

# THREE WORKERS WRITE, and the count is taken by a SEPARATE PROCESS --
# which is the only way to prove the transaction settled rather than
# merely happening inside the server's own head.
setsid timeout 60 "$C" $KB run "$D/kbsrv.pl" "pooled(18931, 3, 3)" >/dev/null 2>&1 &
sleep 3
for i in 1 2 3; do timeout 30 curl -s -o /dev/null http://127.0.0.1:18931/visit; done
wait 2>/dev/null
check "three pooled writes are all visible to another process" "$(kb_count)" "3"

# ONE TRANSACTION PER REQUEST, not per worker. A worker's goal is the
# whole loop, so a per-worker commit would leave these invisible until the
# server stopped -- and the server is still running when this is counted.
timeout 60 "$C" $KB forget >/dev/null 2>&1
timeout 60 "$C" $KB query "assertz(stock(widget, 7))" >/dev/null 2>&1
setsid timeout 60 "$C" $KB run "$D/kbsrv.pl" "pooled(18932, 2, 4)" >/dev/null 2>&1 &
sleep 3
timeout 30 curl -s -o /dev/null http://127.0.0.1:18932/visit
mid=$(kb_count)
timeout 30 curl -s -o /dev/null http://127.0.0.1:18932/visit
check "the first write settles while the server is still running" "$mid" "1"
wait 2>/dev/null

# AND THE SINGLE-THREADED PATH TOO, which had the same bug and no pool to
# blame it on: httpd_loop is one goal as well.
timeout 60 "$C" $KB forget >/dev/null 2>&1
setsid timeout 60 "$C" $KB run "$D/kbsrv.pl" "alone(18933, 2)" >/dev/null 2>&1 &
sleep 3
timeout 30 curl -s -o /dev/null http://127.0.0.1:18933/visit
check "workers(0) settles per request as well" "$(kb_count)" "1"
wait 2>/dev/null
timeout 60 "$C" $KB forget >/dev/null 2>&1
fi

rm -rf "$D"
echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
