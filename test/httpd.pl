%% library(httpd) -- the server half: routing, path safety, and two cocolog
%% instances talking to each other over a socket.
%%
%% MOST OF THIS OPENS NO PORT, and that is the design paying off:
%% httpd_answer/3 is the whole server minus the accept loop, so every
%% routing rule is checkable as a pure goal. A test that had to raise a
%% listener to find out what `/../../etc/passwd' does would be slower, and
%% would be measuring the socket layer at the same time.
%%
%% THE PATH SECTION IS THE ONE THAT MATTERS. Traversal, encoded traversal,
%% NUL truncation, and source disclosure are the four ways a static file
%% server hands out something it was never asked for. Each has a case here
%% with the file it would have leaked actually sitting on disk, because a
%% defence tested against a file that is not there proves nothing.
%%
%% THE SOCKET SECTIONS ARE THE POINT OF THE LIBRARY: one cocolog serves
%% pages written in Prolog and a SECOND fetches them -- with library(curl),
%% with raw bytes down a library(tcp) socket, and with several requests
%% held on one connection -- which crosses sockets, the grammar, the router
%% and libcurl in one go.
%%
%%     cocolog -s test/httpd.pl        from the checkout root
%%
%% ONE PROCESS FOR THE ROUTER, where test/httpd.sh spawned one per check;
%% and each of its seventeen servers is still a second process -- that is
%% the claim -- but waited for through lsof rather than slept for three
%% seconds each, which was most of a minute of the case. lsof, never a
%% probe connection: httpd's accept loop counts accepts, and a probe would
%% be one of them.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(httpd)), _, fail)
    ->  true
    ;   skip('(library(httpd) will not load)')
    ),
    scratch(D),
    tree(D),
    atom_concat(D, '/root', Root),
    a_file(Root), every_byte(Root), path_rules(Root), never_served(Root), methods(Root),
    the_builtin, the_fence, outer_budget(D), head(Root), no_root,
    pages(D, Root), over_a_socket(D, Root), keep_alive(D, Root), the_pool(D, Root),
    module_registry(D), knowledge_base(D, Root),
    shl(['rm -rf ', D]),
    checks_done.

%% The tree every static case reads. Written rather than assumed, and the
%% secret is written OUTSIDE the root on purpose: a traversal case has to
%% have something real to reach or it cannot fail.
tree(D) :-
    atom_concat(D, '/root', Root), make_directory(Root),
    atom_concat(Root, '/sub', Sub), make_directory(Sub),
    atom_concat(D, '/pages', Pages), make_directory(Pages),
    atom_concat(Root, '/index.html', Index), fixture(Index, ['<h1>home</h1>']),
    atom_concat(Root, '/a.txt', A), fixture(A, ['plain text here']),
    atom_concat(Sub, '/b.txt', B), fixture(B, ['deeper']),
    atom_concat(Root, '/i.png', Png), write_file_from_codes(Png, [137, 80, 78, 71, 13, 10, 26, 10]),
    atom_concat(Root, '/leak.pl', Leak), fixture(Leak, ['secret_clause.']),
    atom_concat(D, '/outside.txt', Outside), fixture(Outside, ['THE SECRET']),
    atom_concat(Root, '/big.txt', Big), length(Xs, 5000), maplist(=(0'x), Xs), write_file_from_codes(Big, Xs).

%% A request term, built here so each case is one line. Path is what
%% library(http) would have handed over: already percent-decoded.
req(M, P, request(M, P, [], http(1,1), [], [])).

%% Status only, out of the response bytes.
st(Opts, M, P, S) :-
    req(M, P, Req), httpd_answer(Opts, Req, Cs), atom_codes(A, Cs), sub_atom(A, 9, 3, _, S).

%% the whole answer as an atom
ans(Opts, M, P, A) :-
    req(M, P, Req), httpd_answer(Opts, Req, Cs), atom_codes(A, Cs).

a_file(Root) :-
    section('a file comes back, with the right type and the right length'),
    R = [root(Root)],
    written(st(R, get, '/a.txt', S1), S1, G1),
    check('a text file is 200', G1, '200'),
    written(( ans(R, get, '/a.txt', A2), sub_atom(A2, B2, _, _, 'text/plain'), B2 > 0 ), found, G2),
    check('and carries its content type', G2, found),
    written(( ans(R, get, '/a.txt', A3), sub_atom(A3, _, 15, 1, X3) ), X3, G3),
    check('the body is the file', G3, 'plain text here'),
    written(st(R, get, '/sub/b.txt', S4), S4, G4),
    check('a nested file resolves', G4, '200'),
    written(st(R, get, '/', S5), S5, G5),
    check('a directory answers with its index', G5, '200'),
    written(( ans(R, get, '/i.png', A6), ( sub_atom(A6, _, _, _, 'image/png') -> X6 = png ; X6 = other ) ), X6, G6),
    check('an unknown extension is not text', G6, png),
    written(st(R, get, '/nope.txt', S7), S7, G7),
    check('a file that is not there is 404', G7, '404').

every_byte(Root) :-
    section('every byte of a binary file survives the round trip'),
    %% The PNG signature has a high byte (0x89) and a CR in it. If the body
    %% were carried as an atom anywhere in the server, this is where it would
    %% show.
    atom_concat(Root, '/i.png', Png),
    written(( req(get, '/i.png', Req), httpd_answer([root(Root)], Req, Cs), length(Cs, T),
              size_file(Png, F), H is T - F ), H, G),
    atom_length('HTTP/1.1 200 OK\r\nContent-Length: 8\r\nContent-Type: image/png\r\n\r\n', Want),
    format(atom(WantA), "~w", [Want]),
    check('the body length is the file''s byte count', G, WantA).

path_rules(Root) :-
    section('the path rules, with a real file waiting on the other side'),
    R = [root(Root)],
    written(st(R, get, '/../outside.txt', S1), S1, G1),
    check('plain traversal is refused', G1, '400'),
    written(st(R, get, '/sub/../../outside.txt', S2), S2, G2),
    check('and so is a deeper one', G2, '400'),
    %% `..' that stays inside is LEGITIMATE and must still work -- this is
    %% why the rule resolves rather than rejecting every `..' on sight.
    written(st(R, get, '/sub/../a.txt', S3), S3, G3),
    check('but .. that stays inside still resolves', G3, '200'),
    written(st(R, get, '/..', S4), S4, G4),
    check('a lone .. at the root is refused', G4, '400'),
    written(st(R, get, '//a.txt', S5), S5, G5),
    check('// collapses rather than escaping', G5, '200'),
    %% A NUL NEVER REACHES THE ROUTER. An atom in cocolog is a C string, so
    %% library(http) has already truncated the path at the NUL by the time it
    %% builds one -- `/a.txt\0/../../outside.txt' IS the atom `/a.txt'. That
    %% is safe in the only direction that matters, because truncation can only
    %% make a path SHORTER, and a prefix of a contained path is still
    %% contained. The check is that the trailing half cannot be reached, not
    %% that it is rejected: there is nothing left to reject.
    NulPath = [0'/, 0'a, 0'., 0't, 0'x, 0't, 0, 0'/, 0'., 0'., 0'/, 0'., 0'., 0'/, 0'o, 0'u, 0't],
    written(( atom_codes(P6, NulPath), atom_length(P6, L6) ), L6, G6),
    check('a NUL truncates the path rather than extending it', G6, '6'),
    written(( atom_codes(P7, NulPath),
              httpd_answer(R, request(get, P7, [], http(1,1), [], []), Cs7),
              atom_codes(A7, Cs7), sub_atom(A7, 9, 3, _, S7) ), S7, G7),
    check('and what it truncates to is the safe file, not the escape', G7, '200'),
    %% THE DECODED FORM IS THE ONE THAT ARRIVES. library(http) decodes the
    %% target before the server sees it, so this is the byte sequence a
    %% request for `/..%2foutside.txt' actually turns into.
    written(st(R, get, '/../outside.txt', S8), S8, G8),
    check('encoded traversal is the same request, and refused', G8, '400').

never_served(Root) :-
    section('a .pl file is never served as a file'),
    R = [root(Root)],
    written(st(R, get, '/leak.pl', S1), S1, G1),
    check('an unrouted .pl is 404, not its source', G1, '404'),
    written(( ans(R, get, '/leak.pl', A2), ( sub_atom(A2, _, _, _, secret_clause) -> X2 = leaked ; X2 = safe ) ), X2, G2),
    check('and its text does not appear in the answer', G2, safe).

methods(Root) :-
    section('methods, and how big is too big'),
    R = [root(Root)],
    written(st(R, post, '/a.txt', S1), S1, G1),
    check('a POST to a static file is 405', G1, '405'),
    written(( ans(R, post, '/a.txt', A2), ( sub_atom(A2, _, _, _, 'Allow: GET, HEAD') -> X2 = yes ; X2 = no ) ), X2, G2),
    check('which says what it would allow', G2, yes),
    written(st([root(Root), max_file(1024)], get, '/big.txt', S3), S3, G3),
    check('a file over max_file is 413, not a slow 200', G3, '413'),
    written(st([root(Root), max_file(999999)], get, '/big.txt', S4), S4, G4),
    check('and under it, the same file is 200', G4, '200').

the_builtin :-
    %% A REGRESSION GUARD FOR A BUILTIN, kept here because this is what found
    %% it. `sub_atom/5' had two fixed 4096-byte buffers and reported the
    %% overflow as `type_error(atom, <the atom>)' -- a diagnosis naming the
    %% one thing that was not wrong. 4095 characters worked and 4096 threw,
    %% which is why nothing had noticed: every test atom until now was short.
    %% A 5 KiB response is an ordinary web page, so the server tripped over
    %% it on its first big file.
    section('and the builtin this library broke on the way in'),
    written(( length(L1, 20000), maplist(=(0'x), L1), atom_codes(A1, L1),
              sub_atom(A1, 0, 3, Aft1, S1), atomic_list_concat([S1, '-', Aft1], X1) ), X1, G1),
    check('sub_atom reaches past 4096 characters', G1, 'xxx-19997'),
    written(catch(sub_atom(f(1), 0, 1, _, _), error(E2, _),
                  ( E2 = type_error(atom, _) -> X2 = type_error ; X2 = other )), X2, G2),
    check('and a real non-atom still gets the real error', G2, type_error).

the_fence :-
    section('the fence itself, which is why a page cannot end the server'),
    written(call_limited((between(1, 100000000, _), fail), 5000, R1), R1, G1),
    check('a runaway is stopped and says so', G1, inference_limit_exceeded),
    %% A FENCE THAT LOST THE ANSWER would be useless: the page's reply comes
    %% back as bindings, so they have to survive a success.
    written(call_limited(append(X2, [c], [a,b,c]), 10000, _), X2, G2),
    check('a success keeps its bindings', G2, '[a,b]'),
    %% ...and must NOT survive the ceiling, or a half-run page would answer
    %% with half a term.
    written(( call_limited((X3 = bound, between(1, 100000000, _), fail), 5000, _),
              ( var(X3) -> W3 = unbound ; W3 = X3 ) ), W3, G3),
    check('and the ceiling leaves none behind', G3, unbound),
    written(( call_limited(fail, 1000, _) -> W4 = succeeded ; W4 = failed ), W4, G4),
    check('a goal that merely fails, fails', G4, failed),
    %% ZERO WOULD MEAN `NO LIMIT' one layer down, where 0 is how max_steps
    %% spells unbounded -- so asking for nothing would silently get everything.
    written(catch(call_limited(true, 0, _), error(E5, _),
                  ( E5 = domain_error(positive_integer, _) -> W5 = refused ; W5 = other )), W5, G5),
    check('a ceiling of zero is refused, not read as unlimited', G5, refused),
    %% THE ONE THAT COST A FIELD ON THE ENGINE. A nested engine unwinds its
    %% own stack, so the ball's term is gone by the time control is back --
    %% and the first version of this builtin let an exception out as a
    %% message only, which turned every page error into a dead request
    %% handler. The ball is now kept in the store and thrown again outside.
    written(catch(call_limited((X6 is 1/0, write(X6)), 10000, _), error(E6, _),
                  ( E6 = evaluation_error(zero_divisor) -> W6 = reraised ; W6 = other )), W6, G6),
    check('an exception inside is catchable outside', G6, reraised),
    written(catch(call_limited(atom_length(1, _, _), 10000, _), _, Y7 = recovered), Y7, G7),
    check('and the recovery goal really runs', G7, recovered),
    %% A catch INSIDE the fence is inside the nested engine with the throw, so
    %% it never needed any of that machinery -- checked so the two paths stay
    %% apart.
    written(call_limited(catch(atom_length(1, _, _), _, true), 10000, R8), R8, G8),
    check('a catch within the goal still works normally', G8, true).

outer_budget(D) :-
    %% THE CEILING NARROWS, NEVER WIDENS. An inner limit of 100 million inside
    %% an outer budget of 3000 gets the 3000 -- otherwise a fenced goal would
    %% be a way AROUND the outer budget rather than a limit under it. Needs a
    %% database, because `step' is the only thing that sets an outer budget,
    %% and --embed is one without a server.
    atom_concat(D, '/fencekb', KB), make_directory(KB),
    cocolog(C),
    sh_join(['timeout 60 ', C, ' --embed ', KB, ' start fencer "call_limited((between(1,100000000,_), fail), 100000000, R), write(r(R)), nl" >/dev/null 2>&1'], Start),
    (   sh_exit(Start, 0)
    ->  sh_join(['timeout 120 ', C, ' --embed ', KB, ' --steps 3000 step fencer 2>&1'], Step),
        proc_run(Step, 120000, Out1, _),
        %% 3002 rather than 100000000: without the narrowing this runs for minutes
        (   re_first_atom('suspended at [0-9]+', Out1, At1)
        ->  ( re_match('suspended at 3[0-9]{3}$', At1) -> W1 = narrowed ; W1 = At1 )
        ;   W1 = no_suspension_line
        ),
        check('an outer budget narrows an inner ceiling', W1, narrowed),
        sh_join(['timeout 120 ', C, ' --embed ', KB, ' --steps 5000 finish fencer 2>&1'], Finish),
        proc_run(Finish, 120000, Out2, _),
        ( re_first_atom('r\\(inference_limit_exceeded\\)', Out2, W2) -> true ; W2 = none ),
        check('and the program carries on past the fence', W2, 'r(inference_limit_exceeded)')
    ;   format("     (skipped: the outer-budget case -- no embedded store here)~n", [])
    ).

head(Root) :-
    section('HEAD says what GET would, without the body'),
    R = [root(Root)],
    written(st(R, head, '/a.txt', S1), S1, G1),
    check('HEAD is 200', G1, '200'),
    %% THE WHOLE POINT: the length is the FILE's, not zero. A server that
    %% answered HEAD with an empty body and a computed Content-Length would
    %% report 0 here and every client asking how big a file is would be lied to.
    written(( ans(R, head, '/a.txt', A2), ( sub_atom(A2, _, _, _, 'Content-Length: 16') -> X2 = right ; X2 = wrong ) ), X2, G2),
    check('HEAD reports the real Content-Length', G2, right),
    written(( ans(R, head, '/a.txt', A3), ( sub_atom(A3, _, _, _, 'plain text') -> X3 = body ; X3 = none ) ), X3, G3),
    check('and sends no body at all', G3, none).

no_root :-
    section('no root means no files, rather than the working directory'),
    written(st([], get, '/a.txt', S1), S1, G1),
    check('a server with no root serves nothing', G1, '404').

pages(D, Root) :-
    section('pages: clauses answering a path'),
    atom_concat(D, '/pages/hello.pl', Hello),
    fixture(Hello,
            [ 'httpd_page(''/hello'', _, reply(200, [''Content-Type''-''text/plain''], ''hi from a clause'')).',
              '',
              'httpd_page(''/who'', request(_,_,Query,_,_,_), reply(200, [], Answer)) :-',
              '    memberchk(name-N, Query),',
              '    atom_concat(''hello '', N, Answer).',
              '',
              'httpd_page(''/boom'', _, _) :- X is 1/0, write(X).',
              '',
              '%% The one that would take the server with it. Not an infinite loop written',
              '%% as one -- between/3 to a hundred million is finite and would simply take',
              '%% minutes, which is the same thing to anybody waiting on the socket.',
              'httpd_page(''/loop'', _, _) :- between(1, 100000000, _), fail.',
              '',
              '%% Claims a .pl path, to prove a page may be REACHED at one even though a',
              '%% .pl file is never SERVED at one.',
              'httpd_page(''/app.pl'', _, reply(200, [], ''a page, not a file'')).' ]),
    use_module(Hello),
    R = [root(Root)],
    written(( ans(R, get, '/hello', A1), sub_atom(A1, _, 16, 0, X1) ), X1, G1),
    check('a page answers its path', G1, 'hi from a clause'),
    written(( httpd_answer(R, request(get, '/who', [name-ada], http(1,1), [], []), Cs2),
              atom_codes(A2, Cs2), sub_atom(A2, _, 9, 0, X2) ), X2, G2),
    check('a page reads the query string', G2, 'hello ada'),
    %% A page that fails did not claim the path, so the static half gets it
    %% -- which here means 404. A page that THROWS claimed it and broke: 500.
    written(( httpd_answer(R, request(get, '/who', [], http(1,1), [], []), Cs3),
              atom_codes(A3, Cs3), sub_atom(A3, 9, 3, _, S3) ), S3, G3),
    check('a page that fails falls through to static', G3, '404'),
    written(st(R, get, '/boom', S4), S4, G4),
    check('a page that throws is 500, not a fall-through', G4, '500'),
    written(( ans(R, get, '/app.pl', A5), sub_atom(A5, _, 18, 0, X5) ), X5, G5),
    check('a page may claim a .pl path the file rule refuses', G5, 'a page, not a file'),
    written(st(R, get, '/hello', S6), S6, G6),
    check('a page shadows a file of the same path', G6, '200'),
    %% THE CEILING, and the case the whole fence exists for. Without it this
    %% request never comes back and neither does the server.
    Fenced = [root(Root), page_limit(20000)],
    written(st(Fenced, get, '/loop', S7), S7, G7),
    check('a page that loops is stopped, and answers 500', G7, '500'),
    written(( ans(Fenced, get, '/loop', A8), ( sub_atom(A8, _, _, _, 'inference limit') -> X8 = named ; X8 = vague ) ), X8, G8),
    check('and says what happened, not just that something did', G8, named),
    %% AND THE SERVER IS STILL THERE afterwards, which is the actual claim. A
    %% fence that stopped the page by stopping the process would pass the two
    %% cases above and be worthless.
    written(( st(Fenced, get, '/loop', _), st(R, get, '/a.txt', S9) ), S9, G9),
    check('the next request after a stopped page is answered normally', G9, '200'),
    written(st(Fenced, get, '/hello', S10), S10, G10),
    check('a page well under the ceiling is untouched by it', G10, '200'),
    written(st([root(Root), pages(false)], get, '/hello', S11), S11, G11),
    check('with pages off, the same request is static again', G11, '404').

%% ---- servers: spawned, waited for through lsof, reaped -----------------

%% `cocolog ARGS' in a session of its own, under a two-minute cap, until
%% its port listens
serving(Args, Port, Pid) :-
    cocolog(C),
    sh_join(['timeout 120 ', C, ' ', Args, ' >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    sh_join(['lsof -iTCP:', Port, ' -sTCP:LISTEN >/dev/null 2>&1'], Listening),
    ( proc_until(sh_exit(Listening, 0), 8000, 100) -> true ; true ).

%% A SERVER THAT HAS ANSWERED IS DONE. One told to accept more times than
%% the case connects would sit in accept until its cap -- the .sh `wait'ed
%% for exactly that, forty seconds a server, and it was most of the case's
%% four minutes -- so a moment for it to end on its own, then it is stopped.
reap(Pid) :- ( proc_wait(Pid, 1500, _) -> true ; proc_stop(Pid) ).

%% curl's status code for a URL
hit(Url, Code) :- shl_atom(['timeout 90 curl -s -o /dev/null -w ''%{http_code}'' ', Url], Code).

%% curl's body for a URL
fetch(Url, Body) :- shl_atom(['timeout 30 curl -s ', Url], Body).

over_a_socket(D, Root) :-
    section('and now over a real socket, one cocolog to another'),
    (   catch(use_module(library(curl)), _, fail)
    ->  atom_concat(D, '/server.pl', Server),
        atom_concat(D, '/pages/hello.pl', Hello),
        sh_join([':- use_module(''', Hello, ''').'], UseHello),
        sh_join(['serve(Port) :- httpd_serve(Port, [root(''', Root, ''')], 4).'], Serve),
        sh_join(['serve_ka(Port) :- httpd_serve(Port, [root(''', Root, ''')], 1).'], ServeKa),
        sh_join(['serve_capped(Port) :- httpd_serve(Port, [root(''', Root, '''), max_keep_alive(2)], 1).'], ServeCapped),
        sh_join(['serve_noka(Port) :- httpd_serve(Port, [root(''', Root, '''), keep_alive(false)], 1).'], ServeNoka),
        fixture(Server,
                [ ':- use_module(library(httpd)).', UseHello, '', Serve,
                  '',
                  '%% ONE ACCEPT. Everything the keep-alive cases do happens on the single',
                  '%% connection that accept returns, which is what makes "one accept, three',
                  '%% answers" a proof rather than a coincidence.',
                  ServeKa, ServeCapped, ServeNoka ]),
        sh_join(['run ', Server, ' "serve(18860)"'], Args),
        serving(Args, 18860, Pid),
        written(( curl_get('http://127.0.0.1:18860/a.txt', S1, B1), atom_codes(A1, B1),
                  sub_atom(A1, 0, 15, _, X1), atomic_list_concat([S1, ' ', X1], Y1) ), Y1, G1),
        check('a second cocolog fetches a static file', G1, '200 plain text here'),
        written(( curl_get('http://127.0.0.1:18860/hello', S2, B2), atom_codes(A2, B2),
                  atomic_list_concat([S2, ' ', A2], Y2) ), Y2, G2),
        check('and a page computed by clauses', G2, '200 hi from a clause'),
        %% CURL WILL NOT SEND A TRAVERSAL, which is worth knowing and useless
        %% here: libcurl applies RFC 3986 remove_dot_segments itself, so
        %% `http://host/../outside.txt' goes out as `GET /outside.txt'.
        %% Verified by putting a socket in front of it and reading the request
        %% line. To ask the SERVER what it does, the bytes have to be written
        %% by hand -- which is library(tcp), and keeps the whole test inside
        %% this repository.
        written(( use_module(library(tcp)), tcp_connect('127.0.0.1', 18860, S3),
                  atom_codes(Q3, "GET /../outside.txt HTTP/1.1\r\nHost: x\r\n\r\n"),
                  atom_codes(Q3, QC3), tcp_write(S3, QC3), tcp_read(S3, 4096, 5000, R3),
                  tcp_close(S3), atom_codes(A3, R3), sub_atom(A3, 9, 3, _, St3) ), St3, G3),
        check('raw traversal bytes, straight down a socket, are refused', G3, '400'),
        reap(Pid)
    ;   format("     (skipped: the client half -- no library/curl.so; sh modules/curl/build.sh)~n", [])
    ).

keep_alive(D, Root) :-
    section('keep-alive: more than one request down one socket'),
    atom_concat(D, '/server.pl', Server),
    (   exists_file(Server)
    ->  true
    ;   %% the socket section skipped for want of curl; the server file is
        %% still needed here, and needs no curl
        atom_concat(D, '/pages/hello.pl', Hello),
        sh_join([':- use_module(''', Hello, ''').'], UseHello),
        sh_join(['serve_ka(Port) :- httpd_serve(Port, [root(''', Root, ''')], 1).'], ServeKa),
        sh_join(['serve_capped(Port) :- httpd_serve(Port, [root(''', Root, '''), max_keep_alive(2)], 1).'], ServeCapped),
        sh_join(['serve_noka(Port) :- httpd_serve(Port, [root(''', Root, '''), keep_alive(false)], 1).'], ServeNoka),
        fixture(Server, [':- use_module(library(httpd)).', UseHello, ServeKa, ServeCapped, ServeNoka])
    ),
    %% THE CLIENT HAS TO HOLD THE SOCKET, which curl will not be told to do
    %% per-request and which is the whole thing under test -- so it is
    %% written with library(tcp), in this repository, one connection and
    %% several write/read turns on it.
    atom_concat(D, '/client.pl', Client),
    fixture(Client,
            [ ':- use_module(library(tcp)).',
              '%% Sends each request in Reqs down ONE connection and collects what came',
              '%% back. Status only, plus whether the response said keep-alive or close --',
              '%% between them that is the entire contract.',
              'talk(Port, Reqs, Out) :-',
              '    tcp_connect(''127.0.0.1'', Port, S),',
              '    turns(S, Reqs, Parts),',
              '    tcp_close(S),',
              '    atomic_list_concat(Parts, '' '', Out).',
              '',
              'turns(_, [], []).',
              'turns(S, [R|Rs], [P|Ps]) :-',
              '    atom_codes(R, C), tcp_write(S, C),',
              '    (   tcp_read(S, 65536, 3000, Bytes)',
              '    ->  atom_codes(A, Bytes), verdict(A, P)',
              '    ;   P = ''no-answer''',
              '    ),',
              '    turns(S, Rs, Ps).',
              '',
              '%% BOTH HALVES MATTER: a server can answer correctly and still have closed,',
              '%% and the next turn would then read nothing at all.',
              'verdict(A, P) :-',
              '    sub_atom(A, 9, 3, _, St),',
              '    (   sub_atom(A, _, _, _, ''Connection: keep-alive'') -> K = keep',
              '    ;   sub_atom(A, _, _, _, ''Connection: close'')      -> K = close',
              '    ;   K = silent',
              '    ),',
              '    atomic_list_concat([St, ''/'', K], P).',
              '',
              '%% Everything in one write, which is what pipelining is.',
              'pipeline(Port, Text, Out) :-',
              '    tcp_connect(''127.0.0.1'', Port, S),',
              '    atom_codes(Text, C), tcp_write(S, C),',
              '    drain(S, [], Bytes),',
              '    tcp_close(S),',
              '    atom_codes(A, Bytes),',
              '    findall(x, sub_atom(A, _, _, _, ''HTTP/1.1 200''), Xs),',
              '    length(Xs, N),',
              '    atomic_list_concat([n, N], Out).',
              '',
              '%% READ UNTIL NOTHING MORE COMES. The server answers a pipelined pair with',
              '%% TWO writes, so they need not arrive in one segment -- and reading once',
              '%% and counting is how this case first claimed the server had answered ONE',
              '%% request when a socket-level check showed it had answered both. The',
              '%% timeout ends the drain: after the last response the server is waiting',
              '%% for another request, so nothing further arrives.',
              'drain(S, Acc, Out) :-',
              '    (   tcp_read(S, 65536, 2000, B)',
              '    ->  append(Acc, B, More),',
              '        drain(S, More, Out)',
              '    ;   Out = Acc',
              '    ).' ]),
    use_module(Client),
    %% ONE ACCEPT, several requests. httpd_serve/3 counts ACCEPTS, so a server
    %% told to accept once that answers three requests has kept the
    %% connection alive -- there was no second connection for them to arrive on.
    ka_server(Server, serve_ka, 18861, Pid1),
    written(talk(18861, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                         'GET /hello HTTP/1.1\r\nHost: x\r\n\r\n',
                         'GET /nope HTTP/1.1\r\nHost: x\r\n\r\n'], O1), O1, G1),
    check('three requests, one connection, one accept', G1, '200/keep 200/keep 404/keep'),
    reap(Pid1),
    %% `Connection: close' ENDS IT, and the response says so before it does.
    ka_server(Server, serve_ka, 18862, Pid2),
    written(talk(18862, ['GET /a.txt HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n',
                         'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O2), O2, G2),
    check('a client asking to close is told close, and then is', G2, '200/close no-answer'),
    reap(Pid2),
    %% HTTP/1.0 IS THE OTHER HALF OF RFC 7230 6.3, and the half that is easy
    %% to get wrong: it must NOT persist unless it asked to. A 1.0 client left
    %% hanging waits for an end-of-body that never comes.
    ka_server(Server, serve_ka, 18863, Pid3),
    written(talk(18863, ['GET /a.txt HTTP/1.0\r\nHost: x\r\n\r\n',
                         'GET /a.txt HTTP/1.0\r\nHost: x\r\n\r\n'], O3), O3, G3),
    check('HTTP/1.0 closes unless it asks to persist', G3, '200/close no-answer'),
    reap(Pid3),
    ka_server(Server, serve_ka, 18864, Pid4),
    written(talk(18864, ['GET /a.txt HTTP/1.0\r\nHost: x\r\nConnection: keep-alive\r\n\r\n',
                         'GET /a.txt HTTP/1.0\r\nHost: x\r\nConnection: keep-alive\r\n\r\n'], O4), O4, G4),
    check('and persists when it does ask', G4, '200/keep 200/keep'),
    reap(Pid4),
    %% PIPELINING: both requests in ONE write. This is what http_request/3's
    %% remainder buys -- without it the second request's bytes are read as
    %% part of the first and silently dropped.
    ka_server(Server, serve_ka, 18865, Pid5),
    written(pipeline(18865, 'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\nGET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n', O5), O5, G5),
    check('two requests in one write get two answers', G5, n2),
    reap(Pid5),
    %% THE CEILING ON A CONNECTION. max_keep_alive(2) means the SECOND
    %% response is the last, and says close rather than simply going quiet.
    ka_server(Server, serve_capped, 18866, Pid6),
    written(talk(18866, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                         'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                         'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O6), O6, G6),
    check('max_keep_alive closes the connection, and announces it', G6, '200/keep 200/close no-answer'),
    reap(Pid6),
    %% AND OFF IS OFF, for anyone who would rather pay the handshakes.
    ka_server(Server, serve_noka, 18867, Pid7),
    written(talk(18867, ['GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n',
                         'GET /a.txt HTTP/1.1\r\nHost: x\r\n\r\n'], O7), O7, G7),
    check('keep_alive(false) closes after one, as it always did', G7, '200/close no-answer'),
    reap(Pid7).

ka_server(Server, Goal, Port, Pid) :-
    sh_join(['run ', Server, ' "', Goal, '(', Port, ')"'], Args),
    serving(Args, Port, Pid).

the_pool(D, Root) :-
    section('the worker pool: a slow request no longer holds everybody'),
    (   \+ exists_file('library/thread.so')
    ->  format("     (skipped: the pool -- no library/thread.so; sh modules/thread/build.sh)~n", [])
    ;   \+ sh_exit('command -v curl >/dev/null 2>&1', 0)
    ->  format("     (skipped: the pool -- no curl to make concurrent requests with)~n", [])
    ;   atom_concat(D, '/pages2.pl', Pages2),
        fixture(Pages2,
                [ '%% A page that takes a WHILE, and one that does not. Under one connection',
                  '%% at a time the slow one blocks every other client; that is the whole',
                  '%% claim the pool makes, and it cannot be checked without a slow page.',
                  'httpd_page(''/slow'', _, reply(200, [], done)) :- pool_spin(4000000).',
                  'httpd_page(''/fast'', _, reply(200, [], quick)).',
                  '%% A page that BREAKS, to check one bad request does not take a worker',
                  '%% with it -- a pool that dies a thread at a time is worse than no pool.',
                  'httpd_page(''/boom2'', _, _) :- X is 1/0, write(X).',
                  'pool_spin(0) :- !.',
                  'pool_spin(N) :- M is N - 1, pool_spin(M).' ]),
        atom_concat(D, '/pool.pl', Pool),
        sh_join([':- use_module(''', Pages2, ''').'], UsePages2),
        sh_join(['pool(Port, N, Accepts) :- httpd_serve(Port, [root(''', Root, '''), workers(N)], Accepts).'], PoolClause),
        sh_join(['alone(Port, Accepts)   :- httpd_serve(Port, [root(''', Root, ''')], Accepts).'], AloneClause),
        fixture(Pool, [':- use_module(library(httpd)).', UsePages2, '', PoolClause, AloneClause]),
        %% It serves at all, through a worker rather than the accepting thread.
        pool_server(Pool, 'pool(18910, 4, 2)', 18910, Pid1),
        hit('http://127.0.0.1:18910/a.txt', C1),
        check('a static file comes back through the pool', C1, '200'),
        hit('http://127.0.0.1:18910/fast', C2),
        check('and so does a page', C2, '200'),
        reap(Pid1),
        %% ONE SLOW REQUEST, for the ratio below to mean anything.
        pool_server(Pool, 'alone(18911, 1)', 18911, Pid2),
        get_time(T0), hit('http://127.0.0.1:18911/slow', _), get_time(T1),
        One is round((T1 - T0) * 1000), reap(Pid2),
        %% FOUR AT ONCE, one connection at a time: they queue, and the wall
        %% clock is four of them end to end. This is the arrangement the pool
        %% replaces.
        pool_server(Pool, 'alone(18912, 4)', 18912, Pid3),
        get_time(T2), four_at_once(18912), get_time(T3),
        Serial is round((T3 - T2) * 1000), reap(Pid3),
        %% FOUR AT ONCE THROUGH FOUR WORKERS: they overlap.
        pool_server(Pool, 'pool(18913, 4, 4)', 18913, Pid4),
        get_time(T4), four_at_once(18913), get_time(T5),
        Pooled is round((T5 - T4) * 1000), reap(Pid4),
        format("     one ~wms; four serially ~wms; four pooled ~wms~n", [One, Serial, Pooled]),
        %% THE THRESHOLD IS LOOSE ON PURPOSE. Four requests overlapping cannot
        %% take three times one of them; four queued cannot take less than
        %% two. How much more or less depends on the machine, and this is not
        %% a benchmark.
        ( One > 0, Serial > One * 2 -> Q = queued ; Q = overlapped ),
        check('queued, four slow requests take about four times one', Q, queued),
        ( One > 0, Pooled < One * 3 -> P = overlapped ; P = queued ),
        check('pooled, the same four take about one', P, overlapped),
        %% A PAGE THAT THROWS MUST NOT TAKE ITS WORKER WITH IT. The pool answers
        %% 500 and the same worker takes the next connection.
        pool_server(Pool, 'pool(18914, 2, 2)', 18914, Pid5),
        hit('http://127.0.0.1:18914/boom2', C5),
        check('a page that throws is 500, from a worker', C5, '500'),
        hit('http://127.0.0.1:18914/fast', C6),
        check('and the pool serves the next request anyway', C6, '200'),
        reap(Pid5)
        %% ASKING FOR WORKERS WITHOUT library(thread) SAYS SO, and there is no
        %% case for it here because it CANNOT BE PRODUCED without moving a
        %% build artifact out of the way mid-run. Pointing COCOLOG_LIBRARY at
        %% a directory with no thread.so does not do it: the loader also
        %% searches `<exedir>/library', which is where thread.so lives, and
        %% that fallback is deliberate -- it is what lets an installed cocolog
        %% find its own libraries. Verified by hand with the file genuinely
        %% moved aside:
        %%
        %%   cocolog: uncaught exception:
        %%     error(existence_error(procedure,channel_new/2),
        %%           'httpd: workers(N) needs library(thread) --
        %%            sh modules/thread/build.sh')
        %%
        %% A case that renamed a .so and put it back would fail dirty if the
        %% run died in between, and would be testing the rename.
    ).

pool_server(Pool, Goal, Port, Pid) :-
    sh_join(['run ', Pool, ' "', Goal, '"'], Args),
    serving(Args, Port, Pid).

%% four curls at once, the shell's own `&' and `wait'
four_at_once(Port) :-
    sh_join(['for i in 1 2 3 4; do timeout 90 curl -s -o /dev/null http://127.0.0.1:', Port, '/slow & done; wait'], Cmd),
    sh_exit(Cmd, _).

module_registry(D) :-
    section('a pooled worker serves pages from the MODULE REGISTRY, and only those'),
    %% THE ONE THING A POOL ASKS OF THE PROGRAM ABOVE IT, and the failure is
    %% a silent 404 rather than an error -- which is why it is a case and not
    %% just a paragraph. A worker answers each request as an isolated proof,
    %% and a fresh store is filled from the process-wide module registry that
    %% `use_module' writes. A page CONSULTED, or written straight into the
    %% file handed to `cocolog run', lives in the parent's store and no worker
    %% ever sees it. `workers(0)' serves it perfectly well, which is exactly
    %% how this is easy to meet in a demo and lose the moment a pool is added.
    (   \+ exists_file('library/thread.so')
    ->  format("     (skipped: no library/thread.so)~n", [])
    ;   \+ sh_exit('command -v curl >/dev/null 2>&1', 0)
    ->  format("     (skipped: no curl)~n", [])
    ;   atom_concat(D, '/modpage.pl', ModPage),
        fixture(ModPage, ['httpd_page(''/from_module'', _, reply(200, [], from_module)).']),
        %% BOTH PAGES IN ONE SERVER, so the run cannot pass by failing to
        %% start: one arrives through use_module, the other is written here,
        %% in the file `run' is given -- which puts it in the store and
        %% nowhere else.
        atom_concat(D, '/twoways.pl', TwoWays),
        sh_join([':- use_module(''', ModPage, ''').'], UseMod),
        fixture(TwoWays,
                [ ':- use_module(library(httpd)).', UseMod,
                  'httpd_page(''/from_store'', _, reply(200, [], from_store)).',
                  'pooled(P) :- httpd_serve(P, [workers(2)], 2).',
                  'alone(P)  :- httpd_serve(P, [], 2).' ]),
        pool_server(TwoWays, 'pooled(18940)', 18940, Pid1),
        fetch('http://127.0.0.1:18940/from_module', B1),
        check('a pooled worker serves a page loaded as a module', B1, from_module),
        fetch('http://127.0.0.1:18940/from_store', B2),
        check('and NOT one that only reached the parent''s store', B2, 'not found'),
        reap(Pid1),
        %% ...AND WITHOUT A POOL BOTH WORK, which is what makes the rule a
        %% property of the pool rather than of `httpd_page/3'.
        pool_server(TwoWays, 'alone(18941)', 18941, Pid2),
        fetch('http://127.0.0.1:18941/from_store', B3),
        check('workers(0) serves the store page too', B3, from_store),
        fetch('http://127.0.0.1:18941/from_module', B4),
        check('and the module page as well', B4, from_module),
        reap(Pid2)
    ).

knowledge_base(D, Root) :-
    section('pages that reach the knowledge base, from a worker thread'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    sh_join(['--kb httpd_kb_case --host ', Host, ' --tcp ', Port, ' --timeout 30'], KB),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' ', KB, ' list >/dev/null 2>&1'], Probe),
    (   \+ exists_file('library/thread.so')
    ->  format("     (skipped: no library/thread.so)~n", [])
    ;   \+ sh_exit('command -v curl >/dev/null 2>&1', 0)
    ->  format("     (skipped: no curl)~n", [])
    ;   \+ sh_exit(Probe, 0)
    ->  format("     (skipped: no Zigurat server at ~w:~w)~n", [Host, Port])
    ;   sh_join(['timeout 60 ', C, ' ', KB, ' forget >/dev/null 2>&1'], Forget),
        sh_join(['timeout 60 ', C, ' ', KB, ' query "assertz(stock(widget, 7))" >/dev/null 2>&1'], Seed),
        sh_exit(Forget, _), sh_exit(Seed, _),
        atom_concat(D, '/kbpages.pl', KbPages),
        fixture(KbPages,
                [ '%% READS the knowledge base -- a clause a DIFFERENT PROCESS wrote, which',
                  '%% is the whole claim: a worker''s store is its own, so this can only work',
                  '%% through a connection of the thread''s own.',
                  'httpd_page(''/stock'', _, reply(200, [], Body)) :-',
                  '    stock(widget, N),',
                  '    atomic_list_concat([''widget '', N], Body).',
                  '',
                  '%% ...and WRITES it. Every hit adds a row, so counting them afterwards',
                  '%% from another process counts requests that really settled.',
                  'httpd_page(''/visit'', _, reply(200, [], counted)) :- assertz(visit(now)).' ]),
        atom_concat(D, '/kbsrv.pl', KbSrv),
        sh_join([':- use_module(''', KbPages, ''').'], UseKb),
        sh_join(['pooled(P, W, A) :- httpd_serve(P, [root(''', Root, '''), workers(W)], A).'], Pooled),
        sh_join(['alone(P, A)     :- httpd_serve(P, [root(''', Root, ''')], A).'], Alone),
        fixture(KbSrv, [':- use_module(library(httpd)).', UseKb, Pooled, Alone]),
        %% A WORKER READS. Before the kb hook a thread was a --local proof
        %% whatever the parent was, and this page answered 404 because stock/2
        %% was not there.
        kb_server(KB, KbSrv, 'pooled(18930, 3, 1)', 18930, Pid1),
        fetch('http://127.0.0.1:18930/stock', B1),
        check('a page in a worker reads what another process wrote', B1, 'widget 7'),
        reap(Pid1),
        %% THREE WORKERS WRITE, and the count is taken by a SEPARATE PROCESS
        %% -- which is the only way to prove the transaction settled rather
        %% than merely happening inside the server's own head.
        kb_server(KB, KbSrv, 'pooled(18931, 3, 3)', 18931, Pid2),
        fetch('http://127.0.0.1:18931/visit', _), fetch('http://127.0.0.1:18931/visit', _),
        fetch('http://127.0.0.1:18931/visit', _),
        reap(Pid2),
        kb_count(KB, N3),
        check('three pooled writes are all visible to another process', N3, answer(3)),
        %% ONE TRANSACTION PER REQUEST, not per worker. A worker's goal is the
        %% whole loop, so a per-worker commit would leave these invisible
        %% until the server stopped -- and the server is still running when
        %% this is counted.
        sh_exit(Forget, _), sh_exit(Seed, _),
        kb_server(KB, KbSrv, 'pooled(18932, 2, 4)', 18932, Pid3),
        fetch('http://127.0.0.1:18932/visit', _),
        kb_count(KB, Mid),
        fetch('http://127.0.0.1:18932/visit', _),
        check('the first write settles while the server is still running', Mid, answer(1)),
        reap(Pid3),
        %% AND THE SINGLE-THREADED PATH TOO, which had the same bug and no
        %% pool to blame it on: httpd_loop is one goal as well.
        sh_exit(Forget, _),
        kb_server(KB, KbSrv, 'alone(18933, 2)', 18933, Pid4),
        fetch('http://127.0.0.1:18933/visit', _),
        kb_count(KB, N4),
        check('workers(0) settles per request as well', N4, answer(1)),
        reap(Pid4),
        sh_exit(Forget, _)
    ).

kb_server(KB, Srv, Goal, Port, Pid) :-
    sh_join([KB, ' run ', Srv, ' "', Goal, '"'], Args),
    serving(Args, Port, Pid).

kb_count(KB, Got) :-
    sh_join([KB, ' query "findall(x, visit(_), L), length(L, N), write(answer(N)), nl"'], Args),
    cocolog_answer(Args, Got).
