%% modules/tcp/tcp.cicili -- the socket seam, and the three claims its header makes.
%%
%% WHAT IS BEING PINNED, and why each one is here rather than assumed:
%%
%%   A HANDLE IS NOT A FILE DESCRIPTOR. This is the claim the whole design
%%   rests on. Prolog does arithmetic, so any integer can arrive at any of
%%   these predicates -- and if a handle were an fd, `tcp_close(1)' would
%%   close stdout and the next `write/1' would vanish into a closed pipe.
%%   The test closes 1 and then writes, so a regression is not a subtle
%%   wrong answer: the proof of stdout is stdout -- and in ONE process it
%%   is every line this case prints after that check.
%%
%%   A TIMEOUT FAILS RATHER THAN HANGING. A suite that hangs tells you
%%   nothing at all, which is the one test outcome with no information in
%%   it. Every blocking call takes a timeout and the timeout expiring is an
%%   ordinary failure, so `accept' with nobody there is a false goal and not
%%   a wedged run.
%%
%%   READS CARRY EVERY BYTE. An atom in cocolog is a C string and stops at
%%   the first NUL, so a read that answered an atom would silently truncate
%%   a body -- the kind of bug that only appears against real traffic. The
%%   test sends a NUL in the middle and counts what comes back.
%%
%%   AND IT WORKS ACROSS PROCESSES, which is the only version of this claim
%%   worth making. One cocolog listens, a SECOND one that consulted nothing
%%   connects to it, and the bytes cross. An in-process round trip proves
%%   the API; two processes prove the socket.
%%
%%     cocolog -s test/tcp.pl        from the checkout root
%%
%% ONE PROCESS FOR SIXTEEN CHECKS, where test/tcp.sh spawned one per check
%% and slept three seconds for its listener (7.3 s on this machine). The
%% listener is still a second process -- that is the claim -- and is
%% waited for through lsof, not a probe: it accepts once.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(tcp)), _, fail)
    ->  true
    ;   skip('(no library/tcp.so -- sh modules/tcp/build.sh)')
    ),
    (   catch(tcp_sockets(_), _, fail)
    ->  true
    ;   skip('(library(tcp) will not load)')
    ),
    round_trip, not_a_descriptor, timeouts, every_byte, across_processes,
    checks_done.

%% Ports chosen high and fixed rather than random: a fixed port that is busy
%% fails loudly, and a random one that is busy fails one run in a hundred.
p1(18810).
p2(18811).
p3(18812).
p4(18813).

round_trip :-
    section('the round trip'),
    p1(P1), p2(P2), p3(P3),
    written(( tcp_listen(P1, S1), tcp_connect('127.0.0.1', P1, C1), tcp_accept(S1, 2000, A1, _),
              tcp_write(C1, 'hello sockets'), tcp_read(A1, 100, 2000, Cs1), atom_codes(T1, Cs1),
              tcp_close(C1), tcp_close(A1), tcp_close(S1) ), T1, G1),
    check('listen, connect, accept, write, read', G1, 'hello sockets'),
    written(( tcp_listen(P2, S2), tcp_connect('127.0.0.1', P2, C2), tcp_accept(S2, 2000, A2, Peer2),
              sub_atom(Peer2, 0, 9, _, Head2), tcp_close(C2), tcp_close(A2), tcp_close(S2) ), Head2, G2),
    check('the peer is named, host and port', G2, '127.0.0.1'),
    written(( tcp_listen(P3, S3), tcp_connect('127.0.0.1', P3, C3), tcp_accept(S3, 2000, A3, _),
              tcp_close(C3), tcp_close(A3), tcp_close(S3), tcp_sockets(L3) ), L3, G3),
    check('and nothing is left open afterwards', G3, '[]').

not_a_descriptor :-
    section('a handle is not a file descriptor'),
    %% THE ONE THAT MATTERS. If a handle were an fd, this would close stdout
    %% and every line after it would go nowhere -- so the check is the output
    %% itself, this case's own.
    written(( tcp_close(1) -> R1 = closed ; R1 = refused ), R1, G1),
    check('tcp_close(1) is refused', G1, refused),
    written(( ( tcp_close(1) -> true ; true ), R2 = stdout_lives ), R2, G2),
    check('and stdout is still there to say so', G2, stdout_lives),
    written(( tcp_write(2, 'x') -> R3 = wrote ; R3 = refused ), R3, G3),
    check('writing to a slot nobody opened is refused', G3, refused),
    written(( tcp_close(-1) -> R4 = bad ; R4 = refused ), R4, G4),
    check('a negative handle is refused', G4, refused),
    written(( tcp_close(99999) -> R5 = bad ; R5 = refused ), R5, G5),
    check('a handle past the table is refused', G5, refused),
    p1(P1),
    written(( tcp_listen(P1, S6), tcp_close(S6),
              ( tcp_read(S6, 10, 100, _) -> R6 = read ; R6 = refused ) ), R6, G6),
    check('reading a closed socket is refused, not a crash', G6, refused),
    %% A NON-INTEGER IN THE BYTE LIST NAMES ITSELF, and this case is here
    %% because the path that names it was a use-after-free: the error term was
    %% read out of the array AFTER the array had been freed. It answered
    %% correctly anyway -- free'd memory usually still holds what it held -- so
    %% nothing but valgrind could see it, which is exactly why it needs a case
    %% rather than a memory. The same shape was copied into lib/files.cicili's
    %% write_file_from_codes/2 and SEGFAULTED there.
    p4(P4),
    written(( tcp_listen(P4, S7), tcp_connect('127.0.0.1', P4, C7), tcp_accept(S7, 2000, A7, _),
              catch(tcp_write(C7, [foo]), error(type_error(Want7, Got7), _), true),
              tcp_close(C7), tcp_close(A7), tcp_close(S7) ), Want7-Got7, G7),
    check('a non-integer in the byte list is named, not walked after free', G7, 'integer-foo').

timeouts :-
    section('a timeout is a failure, not a hang'),
    p2(P2), p3(P3),
    written(( tcp_listen(P2, S1), ( tcp_accept(S1, 300, _, _) -> R1 = accepted ; R1 = timed_out ),
              tcp_close(S1) ), R1, G1),
    check('accept with nobody there fails', G1, timed_out),
    %% The bound is generous; what it rules out is the thing that matters: a
    %% call that never returns at all.
    get_time(T0),
    tcp_listen(P3, S2), ( tcp_accept(S2, 500, _, _) -> true ; true ), tcp_close(S2),
    get_time(T1),
    ( T1 - T0 < 10 -> R2 = bounded ; R2 = hung ),
    check('and it comes back in seconds, not never', R2, bounded).

every_byte :-
    section('every byte survives'),
    p1(P1), p2(P2), p3(P3),
    %% An atom would stop at the NUL. Codes do not, and this is the only test
    %% that can tell the difference.
    written(( tcp_listen(P1, S1), tcp_connect('127.0.0.1', P1, C1), tcp_accept(S1, 2000, A1, _),
              tcp_write(C1, [104,105,0,116,104,101,114,101]), tcp_read(A1, 100, 2000, Cs1),
              length(Cs1, N1), tcp_close(C1), tcp_close(A1), tcp_close(S1) ), N1, G1),
    check('a NUL in the middle does not truncate', G1, '8'),
    written(( tcp_listen(P2, S2), tcp_connect('127.0.0.1', P2, C2), tcp_accept(S2, 2000, A2, _),
              tcp_write(C2, [104,105,0,116]), tcp_read(A2, 100, 2000, Cs2), nth0(3, Cs2, B2),
              tcp_close(C2), tcp_close(A2), tcp_close(S2) ), B2, G2),
    check('and the byte after it is the right one', G2, '116'),
    written(( tcp_listen(P3, S3), tcp_connect('127.0.0.1', P3, C3), tcp_accept(S3, 2000, A3, _),
              tcp_write(C3, [255,128,127]), tcp_read(A3, 100, 2000, Cs3),
              tcp_close(C3), tcp_close(A3), tcp_close(S3) ), Cs3, G3),
    check('high bytes are not sign-extended', G3, '[255,128,127]').

across_processes :-
    section('and it crosses PROCESSES, which is the only claim worth making'),
    %% One cocolog listens and echoes; a SECOND, which consulted nothing,
    %% connects to it. Spawned in a session of its own, because a plain `&'
    %% from a tool call does not survive the turn -- the same hazard the
    %% server has in CLAUDE.md.
    scratch(D),
    atom_concat(D, '/listener.pl', Listener),
    fixture(Listener,
            [ ':- use_module(library(tcp)).',
              '',
              'serve :-',
              '    tcp_listen(18820, S),',
              '    tcp_accept(S, 10000, C, _),',
              '    tcp_read(C, 4096, 5000, Codes),',
              '    append(Codes, [32,98,97,99,107], Reply),   % " back"',
              '    tcp_write(C, Reply),',
              '    tcp_close(C),',
              '    tcp_close(S).' ]),
    cocolog(Bin),
    sh_join(['timeout 25 ', Bin, ' run ', Listener, ' serve >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    ( proc_until(sh_exit('lsof -iTCP:18820 -sTCP:LISTEN >/dev/null 2>&1', 0), 5000, 100) -> true ; true ),
    written(( tcp_connect('127.0.0.1', 18820, C1), tcp_write(C1, 'over the wire'),
              tcp_read(C1, 4096, 5000, Cs1), atom_codes(T1, Cs1), tcp_close(C1) ), T1, G1),
    check('a second process reaches the first', G1, 'over the wire back'),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ),
    shl(['rm -rf ', D]).
