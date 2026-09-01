%% term.pl -- the TLS terminator test/zigurat-tls.sh raises.
%%
%%     cocolog -s test/term.pl -- FULL.pem PORT ORIGIN MODE [CA.crt]
%%
%% THE COCOLOG REWRITE OF the term.py that file used to write into $OUT.
%%
%% ONE TERMINATOR, TWO CLIENT-AUTH SETTINGS, which is the whole point of the
%% MODE argument: `none' stands in for TLS_CLIENT_AUTH: NONE and `required'
%% for the default REQUIRED, and the two ports the harness raises are the two
%% arrangements a cocolog has to be able to speak. Under `required' the
%% authority is named and library(tls) refuses a peer it did not sign, which
%% is what ssl.CERT_REQUIRED plus load_verify_locations did.
%%
%% FULL DUPLEX BY ALTERNATION, NOT BY THREADS, and that is the one real
%% design difference from the Python. term.py ran two pump threads per
%% connection; this polls each side with a short timeout and forwards
%% whichever speaks. It can do that because tcp_read/4 and tls_read/4 FAIL on
%% a timeout and tcp_why/1 says which kind of failure it was -- so `nobody
%% spoke yet' and `the other end is gone' are distinguishable, which is the
%% whole difficulty of writing a proxy without threads.
%%
%% The binary protocol this carries is request/response, so alternation costs
%% one poll interval per turn and nothing else. A protocol with unsolicited
%% traffic in both directions at once would want library(thread) and two
%% channels; this one does not.
%%
%% THE IDLE CAP IS A SAFETY NET, not the way a connection normally ends. A
%% client that closes gives end-of-stream on the next read and the loop
%% returns at once; the cap is there so a wedged peer cannot hold the
%% terminator for ever and take the suite's time budget with it.

:- use_module(library(main)).
:- use_module(library(tcp)).
:- use_module(library(tls)).

tm_poll_ms(50).
tm_idle_cap(400).           %% 400 * 2 * 50ms = 40s of silence

main(Argv) :-
    tm_args(Argv, Full, Port, Origin, Creds),
    tls_listen(Port, S),
    !,
    format("up~n"), flush_output,
    tm_loop(S, Origin, Creds),
    Full = Full.
main(_) :-
    format("CANNOT BIND~n"), flush_output.

tm_args([Full, P, O, Mode|Rest], Full, Port, Origin, Creds) :-
    atom_number(P, Port),
    atom_number(O, Origin),
    (   Mode == required, Rest = [CA|_]
    ->  Creds = [certificate(Full), key(Full), authority(CA)]
    ;   Creds = [certificate(Full), key(Full)]
    ).

tm_loop(S, Origin, Creds) :-
    (   tls_accept(S, 60000, Creds, C, _Peer)
    ->  (   catch(tm_serve(C, Origin), _, true) -> true ; true ),
        catch(tls_close(C), _, true)
    ;   true
    ),
    tm_loop(S, Origin, Creds).

tm_serve(C, Origin) :-
    tcp_connect('127.0.0.1', Origin, O),
    tm_pump(C, O, 0),
    catch(tcp_close(O), _, true).

%% Whichever side speaks, forward it and start the idle count again.
tm_pump(C, O, Idle) :-
    tm_poll_ms(Ms),
    (   tls_read(C, 65536, Ms, DC), DC \== []
    ->  tcp_write(O, DC), tm_pump(C, O, 0)
    ;   tm_gone(tls)
    ->  true
    ;   tcp_read(O, 65536, Ms, DO), DO \== []
    ->  tls_write(C, DO), tm_pump(C, O, 0)
    ;   tm_gone(tcp)
    ->  true
    ;   tm_idle_cap(Cap),
        Idle1 is Idle + 1,
        Idle1 < Cap
    ->  tm_pump(C, O, Idle1)
    ;   true
    ).

%% END OF STREAM AND A TIMEOUT ARE BOTH PLAIN FAILURES, which is what the
%% two modules document -- and tcp_why/1 and tls_why/1 are what tells them
%% apart. Anything that is not the word `timeout' is treated as gone, which
%% errs towards closing a connection rather than spinning on a broken one.
tm_gone(tcp) :- ( tcp_why(W) -> W \== timeout ; true ).
tm_gone(tls) :- ( tls_why(W) -> W \== timeout ; true ).
