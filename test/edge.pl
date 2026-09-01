%% edge.pl -- the edge stand-in test/tunnel.sh raises.
%%
%%     cocolog -s test/edge.pl -- PORT PUBLIC ORIGIN LOGFILE [CERT.pem]
%%
%% THE COCOLOG REWRITE OF the edge.py tunnel.sh used to write into $OUT.
%% Admits only requests whose Host header is exactly PUBLIC -- the way the
%% Cloudflare edge routes a quick tunnel by its registered hostname -- and
%% forwards verbatim to Zeytun on ORIGIN, which is what cloudflared does at
%% the far end. Every Host seen is appended to LOGFILE.
%%
%% TLS WHEN A CERTIFICATE IS NAMED. The real edge terminates TLS and speaks
%% plaintext to cloudflared, which is exactly this: accept the handshake and
%% forward the decrypted bytes to Zeytun unchanged. One .pem carries both the
%% certificate and the key, as ssl.load_cert_chain(CERT, CERT) did, and there
%% is NO client authentication -- an edge does not ask a browser for one.
%%
%% SERIAL, WHERE THE PYTHON WAS THREADED, and that is a deliberate
%% simplification rather than an oversight: tunnel.sh drives this with one
%% request at a time and a second would wait in the listen backlog. A thread
%% per connection would be library(thread) and a channel to buy nothing this
%% test asks for. If tunnel.sh ever overlaps two requests, this is the line
%% to revisit.
%%
%% main/1 AND NOT main/0, so `-s' works: library(main) supplies main/0, takes
%% the executable off the argv flag and calls this with the rest. Defining
%% main/0 here as well would be the N1 collision -- two of them in one
%% namespace, and which runs depends on how the file was loaded.
%%
%% IT PRINTS `edge up' OR `CANNOT BIND' AND FLUSHES. wait_edge greps for one
%% of the two and the flush is not decoration: cocolog writes to the literal
%% stdout, which the C library buffers by BLOCK into a file, so a marker
%% printed and not flushed reaches the log only when the process exits --
%% which for a server is never, and the harness waits fifteen seconds and
%% gives up.

:- use_module(library(main)).
:- use_module(library(tcp)).

main(Argv) :-
    ed_args(Argv, Port, Public, Origin, Log, Cert),
    ed_listen(Port, Cert, Server),
    !,
    format("edge up~n"), flush_output,
    ed_loop(Server, Public, Origin, Log, Cert).
main(_) :-
    format("CANNOT BIND~n"), flush_output.

ed_args([P, Public, O, Log|Rest], Port, Public, Origin, Log, Cert) :-
    atom_number(P, Port),
    atom_number(O, Origin),
    ( Rest = [C|_] -> Cert = C ; Cert = none ).

%% A CERTIFICATE CHOOSES THE LISTENER, and library(tls) is loaded only when
%% one is named: a build without modules/tls should still run the plain half
%% of this test rather than failing to consult.
ed_listen(Port, none, plain(S)) :- !, tcp_listen(Port, S).
ed_listen(Port, _Cert, secure(S)) :-
    use_module(library(tls)),
    tls_listen(Port, S).

ed_loop(Server, Public, Origin, Log, Cert) :-
    (   ed_accept(Server, Cert, Conn)
    ->  ( catch(ed_serve(Conn, Public, Origin, Log), _, true) -> true ; true ),
        ed_close(Conn),
        ed_loop(Server, Public, Origin, Log, Cert)
    ;   ed_loop(Server, Public, Origin, Log, Cert)
    ).

ed_accept(plain(S), _, plain(C)) :- !, tcp_accept(S, 60000, C, _Peer).
ed_accept(secure(S), Cert, secure(C)) :-
    tls_accept(S, 60000, [certificate(Cert), key(Cert)], C, _Peer).

ed_close(plain(C)) :- !, tcp_close(C).
ed_close(secure(C)) :- tls_close(C).

ed_read(plain(C), Max, Ms, Cs) :- !, tcp_read(C, Max, Ms, Cs).
ed_read(secure(C), Max, Ms, Cs) :- tls_read(C, Max, Ms, Cs).

ed_write(plain(C), Cs) :- !, tcp_write(C, Cs).
ed_write(secure(C), Cs) :- tls_write(C, Cs).

%% ---- one conversation ----------------------------------------------------

ed_serve(Conn, Public, Origin, Log) :-
    ed_head(Conn, [], Head),
    ed_host(Head, Host),
    ed_log(Log, Host),
    (   Host == Public
    ->  ed_forward(Conn, Origin, Head)
    ;   ed_write(Conn, "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
    ).

%% UP TO THE BLANK LINE, over as many reads as it takes. tcp_read/4 is
%% at-least-one-byte and at-most-max, so a request head can arrive in
%% pieces and usually does not.
ed_head(Conn, Acc, Head) :-
    (   ed_contains(Acc, "\r\n\r\n")
    ->  Head = Acc
    ;   ed_read(Conn, 4096, 20000, Cs),
        Cs \== [],
        append(Acc, Cs, Acc1),
        ed_head(Conn, Acc1, Head)
    ).

%% `host:' in any case, its value trimmed.
ed_host(Head, Host) :-
    ed_lines(Head, Lines),
    (   member(L, Lines),
        ed_ci_prefix("host:", L, Rest)
    ->  ed_strip(Rest, R), atom_codes(Host, R)
    ;   Host = ''
    ).

ed_log(Log, Host) :-
    atom_codes(Host, H),
    append(H, "\n", Line),
    append_file_from_codes(Log, Line).

%% VERBATIM, both ways. The point of the stand-in is that nothing between
%% the client and Zeytun edits the bytes.
ed_forward(Conn, Origin, Head) :-
    tcp_connect('127.0.0.1', Origin, O),
    tcp_write(O, Head),
    ed_relay(O, Conn),
    tcp_close(O).

ed_relay(O, Conn) :-
    (   tcp_read(O, 65536, 20000, Cs), Cs \== []
    ->  ed_write(Conn, Cs),
        ed_relay(O, Conn)
    ;   true
    ).

%% ---- text ----------------------------------------------------------------

ed_contains(Hay, Needle) :- append(_, R, Hay), append(Needle, _, R), !.

ed_lines([], []) :- !.
ed_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\r, 0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [] -> Ls = [] ; ed_lines(R, Ls) ).

ed_ci_prefix([], Rest, Rest).
ed_ci_prefix([W|Ws], [C|Cs], R) :- ed_ci(W, C), ed_ci_prefix(Ws, Cs, R).

ed_ci(W, C) :- W == C, !.
ed_ci(W, C) :- W >= 0'a, W =< 0'z, C =:= W - 32.

ed_space(0' ). ed_space(0'\t). ed_space(0'\r). ed_space(0'\n).

ed_strip(Cs, Out) :-
    ed_ws(Cs, A), reverse(A, R0), ed_ws(R0, R1), reverse(R1, Out).

ed_ws([C|T], R) :- ed_space(C), !, ed_ws(T, R).
ed_ws(L, L).
