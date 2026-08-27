%% library(httpd) -- an HTTP server whose pages are Prolog, in this process.
%%
%% THE POINT IS THE LAST WORD. Zeytun serves a knowledge base over HTTP and
%% is C++; it answers with rows. This answers with whatever a clause can
%% compute, in the same process that holds the store -- so a page sees the
%% knowledge base directly, with no protocol in between, and two cocolog
%% instances can talk to each other in Prolog rather than in JSON about
%% Prolog. That is what makes replicators, gates and peer-to-peer work
%% something you write as clauses instead of something you write around.
%%
%% EVERY PREDICATE IS `httpd_'-PREFIXED, helpers included, for the reason
%% library(http) spells out at length: cocolog has ONE namespace, a
%% library's private names are everybody's, and the first clash is silent.
%%
%% IT IS ALL CLAUSES. The sockets are library(tcp)'s C, the parse is
%% library(http)'s grammar, and everything between them -- routing, path
%% safety, content types, the loop -- is here, in Prolog, where it can be
%% read and tested a predicate at a time.
%%
%%
%% THE SHAPE
%%
%%     httpd_serve(Port, Options)          accept forever
%%     httpd_serve(Port, Options, Count)   accept exactly Count, then stop
%%     httpd_answer(Options, Request, Codes)   a request in, bytes out
%%
%% `httpd_answer/3' touches no socket, which is why the suite can check
%% every routing decision without opening one. The loop is four clauses
%% over it.
%%
%% OPTIONS, all with defaults, none required:
%%
%%     root(Dir)          serve static files from here. ABSENT MEANS NO
%%                        STATIC FILES AT ALL -- a server with only pages
%%                        should not have a document root by accident
%%     index(Name)        what a directory answers with  (default index.html)
%%     pages(Bool)        consult httpd_page/3 first     (default true)
%%     max_file(Bytes)    larger is 413, not a slow 200  (default 1 MiB)
%%     max_request(Bytes) larger is refused              (default 64 KiB)
%%     read_timeout(Ms)   per read while a request arrives    (default 5000)
%%     accept_timeout(Ms) how long the loop waits for a client (default 1 hour)
%%
%%
%% A PAGE IS A FILE OF CLAUSES, and it claims a path:
%%
%%     %% pages/hello.pl
%%     httpd_page('/hello', _Request, reply(200, [], 'hi')).
%%
%%     httpd_page('/who', request(_,_,Query,_,_,_), reply(200, [], Answer)) :-
%%         memberchk(name-N, Query),
%%         atom_concat('hello ', N, Answer).
%%
%% Load it with `use_module('/path/to/hello.pl')' -- as a MODULE and not a
%% consult, which matters in every arrangement but --local: a module's
%% clauses are muted, so they belong to this process and are never written
%% through to the shared knowledge base. A page consulted instead of loaded
%% would be saved into the database, come back on every fetch, and be
%% listed as somebody's own program.
%%
%% ONE NAMESPACE IS THE DISPATCH MECHANISM, not a problem to work around.
%% Every page adds clauses to the same `httpd_page/3', each guarded by its
%% own path, and the server simply calls it. Loading two pages merges their
%% clauses, which is exactly what a router is. What it also means is that
%% pages are NOT isolated from each other: what one asserts, the next sees.
%% They are parts of one program that happen to live in separate files.
%%
%% A page that FAILS is a 404 -- it did not claim the path, so the static
%% half gets its turn. A page that THROWS is a 500 and does not fall
%% through, because an error is a page saying "this is mine and it broke".
%%
%%
%% WHERE IT IS STRICT, and every one of these is a decision:
%%
%%   `.pl' IS NEVER A STATIC FILE. Not when pages are off, not when no page
%%   claims the path, not ever. This is the one that would have been a real
%%   vulnerability: a page nobody routed would otherwise fall through to the
%%   static half and SERVE ITS OWN SOURCE -- the classic misconfiguration
%%   that hands out database credentials. A .pl path no page answers is 404.
%%
%%   `..' IS RESOLVED AND THEN REFUSED IF IT ESCAPES. Not stripped, not
%%   rejected on sight: `/a/../b' is `/b' as RFC 3986 says, and a `..' with
%%   nothing left to pop is a 400. Stripping would turn `/a/../../etc' into
%%   `/a/etc' and quietly serve the wrong file; rejecting every `..' would
%%   break a legitimate relative URL a browser resolved for us.
%%
%%   THE PATH IS ALREADY DECODED when it gets here -- library(http) decodes
%%   it -- so `/..%2f..%2fetc/passwd' arrives as `/../../etc/passwd' and
%%   meets the same rule. A server that checked for `..' BEFORE decoding
%%   would see none in that request and serve the file.
%%
%%   AN UNKNOWN EXTENSION IS `application/octet-stream'. A browser renders
%%   what it is told; guessing text/html for an unknown upload is how a
%%   file server becomes a cross-site-scripting host.
%%
%%   HEAD SENDS THE HEADERS GET WOULD, Content-Length included, and no
%%   body. Answering HEAD with a zero Content-Length -- the easy way to
%%   write it -- lies to every client that asks how big a file is.
%%
%%
%% WHAT IT IS NOT: there is no chunked encoding (library(http) refuses it
%% on the way in too), no keep-alive -- one request per connection, and the
%% close is the end of the body -- and no TLS. It is one connection at a
%% time, which is the honest shape for a server whose pages share one
%% knowledge base: two requests mutating the same store concurrently is a
%% question this file does not get to answer on its own.

:- use_module(library(http)).

%% ---- the loop ---------------------------------------------------------

%% httpd_serve(+Port, +Options) is det.
%% Accepts until something stops it. `Count' of -1 is what "forever" is
%% spelt as below, so the two arities are one loop.
httpd_serve(Port, Options) :- httpd_serve(Port, Options, -1).

httpd_serve(Port, Options, Count) :-
    tcp_listen(Port, S),
    (   httpd_loop(S, Options, Count)
    ->  tcp_close(S)
    ;   tcp_close(S), fail
    ).

httpd_loop(_, _, 0) :- !.
httpd_loop(S, Options, N) :-
    httpd_option(accept_timeout(AT), Options, 3600000),
    %% ACCEPT FAILING ENDS THE LOOP rather than spinning on it. A timeout
    %% and a closed listener look the same here, and retrying either one in
    %% a tight loop is how a server burns a core saying nothing.
    tcp_accept(S, AT, C, _Peer),
    !,
    %% ONE CONNECTION MUST NOT TAKE THE SERVER WITH IT. A malformed request,
    %% a client that vanished, a page that threw -- each ends this
    %% conversation and nothing more, and the socket closes either way.
    (   catch(httpd_transact(C, Options), _, true)
    ->  true
    ;   true
    ),
    tcp_close(C),
    (   N < 0
    ->  N1 = N
    ;   N1 is N - 1
    ),
    httpd_loop(S, Options, N1).
httpd_loop(_, _, _).

httpd_transact(C, Options) :-
    httpd_option(max_request(MR), Options, 65536),
    httpd_option(read_timeout(RT), Options, 5000),
    (   httpd_read_request(C, MR, RT, [], Request)
    ->  httpd_answer(Options, Request, Out)
    ;   http_response(400, [], 'bad request', Out)
    ),
    tcp_write(C, Out).

%% READ UNTIL IT PARSES, because one tcp_read is not a request. A POST
%% larger than a segment arrives in pieces, and library(http) fails on a
%% body shorter than its Content-Length -- which is the signal to read
%% again, not to answer 400. It terminates because tcp_read FAILS at end of
%% input and on timeout, and because the accumulated length is checked
%% against the ceiling every round: a client that sends for ever is cut off
%% by max_request rather than believed.
httpd_read_request(C, MR, RT, Acc, Request) :-
    tcp_read(C, MR, RT, Chunk),
    append(Acc, Chunk, All),
    length(All, N),
    N =< MR,
    (   http_request(All, Request)
    ->  true
    ;   httpd_read_request(C, MR, RT, All, Request)
    ).

%% ---- a request in, bytes out ------------------------------------------

%% httpd_answer(+Options, +Request, -Codes) is semidet.
%% The whole server, minus the socket. Every routing rule below is reachable
%% from here with no listener and no client, which is how test/httpd.sh
%% checks the path rules without opening a port.

%% HEAD IS GET WITH THE BODY REMOVED, and removed at the END -- after
%% Content-Length has been computed from the real body -- so the headers
%% are byte for byte the ones GET would have sent. The split is arithmetic
%% rather than a search for the blank line: http_response/4 appends the
%% body last, so the head is everything but the final |Body| codes, and a
%% body that happens to contain CRLFCRLF cannot confuse it.
httpd_answer(Options, request(head, P, Q, V, H, B), Codes) :-
    !,
    httpd_route(Options, request(get, P, Q, V, H, B), reply(S, Hs, Body)),
    http_response(S, Hs, Body, Full),
    http_body_codes(Body, BC),
    length(BC, BL),
    length(Full, T),
    HL is T - BL,
    length(Codes, HL),
    append(Codes, _, Full).
httpd_answer(Options, Request, Codes) :-
    httpd_route(Options, Request, reply(S, Hs, Body)),
    http_response(S, Hs, Body, Codes).

%% ---- routing ----------------------------------------------------------

%% A PAGE GETS FIRST REFUSAL, then the static half. That order is what
%% every server does and the only one that lets a page shadow a file.
%%
%% The catch is what separates "not mine" from "mine and broken": a page
%% that fails leaves Reply unbound and this clause fails, so the static
%% clause runs; a page that throws is answered 500 here and the static
%% clause never sees it.
httpd_route(Options, Request, Reply) :-
    httpd_option(pages(Pages), Options, true),
    Pages == true,
    Request = request(_, Path, _, _, _, _),
    catch(httpd_page(Path, Request, R), _, R = reply(500, [], 'page raised')),
    !,
    Reply = R.
httpd_route(Options, Request, Reply) :-
    httpd_static(Options, Request, Reply).

%% THE PREDICATE MUST EXIST even when no page has been loaded, or calling it
%% raises an existence error and the catch above turns "no pages here" into
%% a 500 for every request. A clause that fails costs one inference and says
%% the right thing.
httpd_page(_, _, _) :- fail.

%% ---- static files -----------------------------------------------------

%% NO ROOT MEANS NO FILES. Not "the working directory", which is what a
%% default of '.' would mean -- and the working directory of a server is
%% whatever the shell that started it happened to be in.
httpd_static(Options, Request, Reply) :-
    httpd_option(root(Root), Options, ''),
    (   Root == ''
    ->  Reply = reply(404, [], 'not found')
    ;   httpd_static_(Root, Options, Request, Reply)
    ).

httpd_static_(Root, Options, request(Method, Path, _, _, _, _), Reply) :-
    (   \+ httpd_safe_path(Path, _)
    ->  Reply = reply(400, [], 'bad path')
    ;   \+ httpd_reads(Method)
    ->  Reply = reply(405, ['Allow'-'GET, HEAD'], 'method not allowed')
    ;   httpd_safe_path(Path, Segs),
        httpd_resolve(Root, Segs, Options, File),
        httpd_file(File, Options, Reply)
    ).

%% GET and HEAD only. A static file has nothing to say to a POST, and 405
%% with an Allow header is the answer that tells a client so.
httpd_reads(get).
httpd_reads(head).

httpd_file(File, Options, Reply) :-
    (   httpd_is_page_source(File)
    ->  %% THE SOURCE-DISCLOSURE RULE, and the reason it is here rather than
        %% in the extension table: reaching this clause means NO page
        %% claimed the path, so the only way to serve it would be as text --
        %% which is to say, to hand out the program.
        Reply = reply(404, [], 'not found')
    ;   \+ exists_file(File)
    ->  Reply = reply(404, [], 'not found')
    ;   httpd_option(max_file(Max), Options, 1048576),
        size_file(File, Size),
        Size > Max
    ->  Reply = reply(413, [], 'file too large')
    ;   read_file_to_codes(File, Codes)
    ->  httpd_type(File, Type),
        Reply = reply(200, ['Content-Type'-Type], Codes)
    ;   %% It existed a moment ago and will not read now: a permission, a
        %% race with a writer, a device. 500 rather than 404, because 404
        %% would say it is not there and it is.
        Reply = reply(500, [], 'cannot read')
    ).

httpd_is_page_source(File) :- file_name_extension(_, pl, File).

%% ---- the path rule ----------------------------------------------------

%% httpd_safe_path(+Path, -Segments) is semidet.
%% Fails on anything that is not a path this server will resolve, and that
%% failure is a 400. Path arrives PERCENT-DECODED from library(http).
httpd_safe_path(Path, Segs) :-
    atom(Path),
    atom_codes(Path, Cs),
    %% A NUL ENDS A C STRING, and this check CANNOT FIRE TODAY -- said
    %% plainly rather than left to look like a working defence. An atom in
    %% cocolog is a C string, so library(http) truncated the target at the
    %% NUL before it ever built the atom: `/a.txt\0/../../etc/passwd' IS
    %% the atom `/a.txt' by the time it arrives here, and there is nothing
    %% left to reject.
    %%
    %% That truncation is safe in the only direction that matters, which is
    %% why this is a guard and not a repair: it can only make a path
    %% SHORTER, and a prefix of a contained path is still contained. The
    %% attack it defeats elsewhere -- appending an escape past a check --
    %% needs the tail to survive, and here it does not.
    %%
    %% The line stays because the guard is one inference and the day
    %% cocolog grows a byte-safe atom is the day it starts mattering.
    %% test/httpd.sh checks the truncation itself, not this clause.
    \+ memberchk(0, Cs),
    atomic_list_concat(Raw, '/', Path),
    %% An origin-form request target is absolute, so the split's first piece
    %% is the empty atom before the leading slash. Anything else is not a
    %% path we were asked for.
    Raw = ['' | Rest],
    httpd_segments(Rest, [], Segs).

httpd_segments([], Acc, Segs) :- reverse(Acc, Segs).
%% `//' collapses, and so does a trailing slash -- both leave an empty piece
httpd_segments([''|T], Acc, Segs) :- !, httpd_segments(T, Acc, Segs).
httpd_segments(['.'|T], Acc, Segs) :- !, httpd_segments(T, Acc, Segs).
%% THE CUT IS BEFORE THE POP ON PURPOSE. With nothing to pop, this fails the
%% whole predicate -- a 400 -- instead of falling to the last clause and
%% treating `..' as the NAME of a directory to look up.
httpd_segments(['..'|T], Acc, Segs) :- !, Acc = [_|Rest], httpd_segments(T, Rest, Segs).
httpd_segments([S|T], Acc, Segs) :- httpd_segments(T, [S|Acc], Segs).

%% A directory answers with its index file. Checked after joining rather
%% than by looking for a trailing slash, because `/docs' and `/docs/' name
%% the same directory and only one of them says so.
httpd_resolve(Root, Segs, Options, File) :-
    atomic_list_concat([Root|Segs], '/', Joined),
    (   exists_directory(Joined)
    ->  httpd_option(index(Ix), Options, 'index.html'),
        atomic_list_concat([Joined, Ix], '/', File)
    ;   File = Joined
    ).

%% ---- content types ----------------------------------------------------

httpd_type(File, Type) :-
    file_name_extension(_, Ext, File),
    (   httpd_content_type(Ext, T)
    ->  Type = T
    ;   Type = 'application/octet-stream'
    ).

%% A CHARSET ON EVERY TEXT TYPE. Without one a browser guesses, and a
%% guessed encoding on attacker-controlled bytes has been a cross-site
%% scripting vector for as long as there have been browsers.
httpd_content_type(html, 'text/html; charset=utf-8').
httpd_content_type(htm,  'text/html; charset=utf-8').
httpd_content_type(txt,  'text/plain; charset=utf-8').
httpd_content_type(md,   'text/plain; charset=utf-8').
httpd_content_type(css,  'text/css; charset=utf-8').
httpd_content_type(js,   'text/javascript; charset=utf-8').
httpd_content_type(json, 'application/json').
httpd_content_type(xml,  'application/xml').
httpd_content_type(csv,  'text/csv; charset=utf-8').
httpd_content_type(png,  'image/png').
httpd_content_type(jpg,  'image/jpeg').
httpd_content_type(jpeg, 'image/jpeg').
httpd_content_type(gif,  'image/gif').
httpd_content_type(svg,  'image/svg+xml').
httpd_content_type(ico,  'image/x-icon').
httpd_content_type(webp, 'image/webp').
httpd_content_type(pdf,  'application/pdf').
httpd_content_type(wasm, 'application/wasm').
httpd_content_type(gz,   'application/gzip').
httpd_content_type(zip,  'application/zip').

%% ---- options ----------------------------------------------------------

%% httpd_option(+Template, +Options, +Default) is det.
%% Template is the option with its argument UNBOUND -- `index(Ix)' -- so
%% memberchk binds it from the list, and `arg/3' binds it from the default
%% when the list has nothing to say. Called with a bound argument it would
%% test rather than fetch, which is not what any caller here wants.
httpd_option(Template, Options, Default) :-
    (   memberchk(Template, Options)
    ->  true
    ;   arg(1, Template, Default)
    ).
