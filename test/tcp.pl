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
%%   A UNIX SOCKET IS AN ADDRESS (2.4.0): `unix(Path)' where a port stands,
%%   the same slots and the same bytes -- and a FILE, whose three rules each
%%   have a case with the file really there: a leftover of a process killed
%%   while it listened is replaced, a live server's is refused and left
%%   alone, a regular file is never touched; and a listener's close removes
%%   its file only while the name is still its own.
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
    scratch(D),
    unix_sockets(D), socket_files(D), a_leftover(D),
    shl(['rm -rf ', D]),
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

%% ---- a unix socket --------------------------------------------------------

unix_sockets(D) :-
    section('a unix socket: unix(Path) where a port stands'),
    atom_concat(D, '/a.sock', P1),
    answer(( tcp_listen(unix(P1), S1), tcp_connect(unix(P1), C1), tcp_accept(S1, 2000, A1, Peer1),
             tcp_write(C1, [104,105,0,255]), tcp_read(A1, 100, 2000, Cs1),
             tcp_write(A1, back), tcp_read(C1, 100, 2000, Bs1), atom_codes(B1, Bs1),
             tcp_close(C1), tcp_close(A1), tcp_close(S1) ), [Peer1, Cs1, B1], G1),
    check('listen, connect, accept, and every byte both ways; the peer is unix:', G1,
          ['unix:', [104,105,0,255], back]),
    %% THE FILE IS THE LISTENER'S: made by the listen, there while a
    %% connection comes and goes, removed by the listener's own close
    atom_concat(D, '/b.sock', P2),
    written(( tcp_listen(unix(P2), S2), ( access_file(P2, exist) -> M2 = made ; M2 = none ),
              tcp_connect(unix(P2), C2), tcp_accept(S2, 2000, A2, _), tcp_close(C2), tcp_close(A2),
              ( access_file(P2, exist) -> K2 = kept ; K2 = gone ),
              tcp_close(S2), ( access_file(P2, exist) -> R2 = left ; R2 = removed ) ), M2/K2/R2, G2),
    check('the listen makes the file, a connection leaves it, the close removes it', G2,
          'made/kept/removed'),
    atom_concat(D, '/none.sock', P3),
    written(( tcp_connect(unix(P3), _) -> W3 = connected ; tcp_why(W3) ), W3, G3),
    check('nobody made the file: the connect fails, and tcp_why/1 says why', G3,
          'No such file or directory'),
    %% Host:Port IS tcp_connect/3 SPELT AS ONE TERM, and a TCP connect that
    %% fails says why as well now
    p1(Port4),
    written(( tcp_listen(Port4, S4), tcp_connect('127.0.0.1':Port4, C4), tcp_accept(S4, 2000, A4, _),
              tcp_write(C4, hi), tcp_read(A4, 100, 2000, Cs4), atom_codes(T4, Cs4),
              tcp_close(C4), tcp_close(A4), tcp_close(S4),
              ( tcp_connect('127.0.0.1':Port4, _) -> W4 = connected ; tcp_why(W4) ) ), T4/W4, G4),
    check('Host:Port connects as tcp_connect/3 does, and a refusal is named', G4,
          'hi/Connection refused'),
    %% A PROGRAM'S MISTAKE RAISES, by name; the network's answer FAILS
    findall(F5, ( member(Goal5, [ tcp_listen(unix(''), _), tcp_connect(unix(_), _),
                                  tcp_connect(unix(f(x)), _), tcp_connect(foo, _),
                                  tcp_connect(_, _) ]),
                  catch(( call(Goal5), F5 = none ), error(F5, _), true) ), Fs5),
    check('an empty path, an unbound one, one that is no text, an address of no kind', Fs5,
          [domain_error(socket_path, ''), instantiation_error, type_error(atom, f(x)),
           domain_error(socket_address, foo), instantiation_error]),
    length(L6, 200), maplist(=(0'a), L6), atom_codes(Long6, L6),
    ( catch(tcp_listen(unix(Long6), _), error(domain_error(Dom6, Got6), _), true),
      Got6 == Long6 -> W6 = Dom6 ; W6 = other ),
    check('a path longer than the struct holds is refused, never cut short', W6, socket_path),
    %% A CONNECTION THE CALLER WILL NOT TAKE IS CLOSED AGAIN: a connect or
    %% an accept whose variable is bound to another number fails, and
    %% leaves no slot open that nobody holds
    atom_concat(D, '/c.sock', P8),
    answer(( tcp_listen(unix(P8), S8), ( tcp_connect(unix(P8), 99) -> X8 = took ; X8 = refused ),
             tcp_connect(unix(P8), C8), ( tcp_accept(S8, 2000, 99, _) -> Y8 = took ; Y8 = refused ),
             tcp_sockets(L8), tcp_close(C8), tcp_close(S8) ), X8/Y8/L8/S8/C8, G8),
    (   G8 = X8a/Y8a/L8a/S8a/C8a
    ->  check('a connect or an accept the caller will not take leaves nothing open', X8a/Y8a/L8a,
              refused/refused/[S8a, C8a])
    ;   check('a connect or an accept the caller will not take leaves nothing open', G8, ran)
    ),
    written(tcp_sockets(L7), L7, G7),
    check('and nothing is left open afterwards', G7, '[]').

socket_files(D) :-
    section('a socket file: a live one refused, a regular file untouched, a name taken kept'),
    %% A LIVE SERVER KEEPS ITS FILE. The second listen asks whether anybody
    %% listens -- a connect -- is answered, and fails; the first server sees
    %% the question as a connection that closes at once, and goes on.
    atom_concat(D, '/live.sock', P1),
    tcp_listen(unix(P1), S1),
    ( tcp_listen(unix(P1), X1) -> tcp_close(X1), W1 = bound ; tcp_why(W1) ),
    check('a live server''s socket file is refused, by name', W1, 'Address already in use'),
    (   tcp_accept(S1, 2000, Q1, _)
    ->  ( tcp_read(Q1, 10, 2000, _) -> R1 = data ; tcp_why(R1) ), tcp_close(Q1)
    ;   R1 = no_question
    ),
    check('the server saw the question as a connection that closed at once', R1, 'end of stream'),
    written(( tcp_connect(unix(P1), C2), tcp_accept(S1, 2000, A2, _), tcp_write(C2, still),
              tcp_read(A2, 100, 2000, Cs2), atom_codes(T2, Cs2), tcp_close(C2), tcp_close(A2) ), T2, G2),
    check('and goes on serving', G2, still),
    tcp_close(S1),
    %% A REGULAR FILE IS NEVER TOUCHED
    atom_concat(D, '/plain.sock', P3),
    fixture(P3, ['not a socket']),
    ( tcp_listen(unix(P3), X3) -> tcp_close(X3), W3 = bound ; tcp_why(W3) ),
    ( read_file_to_codes(P3, Cs3) -> atom_codes(T3, Cs3) ; T3 = gone ),
    check('a regular file of that name is refused, and is still what it was', W3/T3,
          'Address already in use'/'not a socket\n'),
    %% A NAME TAKEN SINCE IS NOT THE CLOSE'S TO REMOVE: the first server's
    %% file is deleted, a second binds the name anew, and the first one's
    %% close leaves the second's file alone, by its inode
    atom_concat(D, '/taken.sock', P4),
    tcp_listen(unix(P4), S4a), delete_file(P4),
    tcp_listen(unix(P4), S4b), tcp_close(S4a),
    ( access_file(P4, exist) -> K4 = kept ; K4 = gone ),
    written(( tcp_connect(unix(P4), C4), tcp_accept(S4b, 2000, A4, _), tcp_close(C4), tcp_close(A4) ),
            reached, G4),
    tcp_close(S4b),
    ( access_file(P4, exist) -> R4 = left ; R4 = removed ),
    check('a name another server has taken since is left to it, and its own close removes it',
          K4/G4/R4, kept/reached/removed).

%% A LEFTOVER, AND ACROSS PROCESSES: a second cocolog listens on a socket
%% file and echoes, and is killed (9) while it listens, as a crash would
%% be. Its file stays; nobody answers on it, so this process's listen
%% replaces it. Spawned with no `timeout' in front, because the kill has to
%% reach the cocolog itself; it stops listening on its own after a minute
%% (or twenty seconds once the round trip is done) in any case. THE FIRST
%% ACCEPT WAITS A MINUTE because `unix_listening' has no lsof state to find
%% on macOS: it spends its whole budget and goes on, and the ten seconds
%% this fixture used to allow had run out before the connect.
a_leftover(D) :-
    section('a leftover: the socket file of a server that was killed is replaced'),
    atom_concat(D, '/left.sock', P),
    atom_concat(D, '/unix-listener.pl', Listener),
    fixture(Listener,
            [ ':- use_module(library(tcp)).',
              '',
              'serve(P) :-',
              '    tcp_listen(unix(P), S),',
              '    tcp_accept(S, 60000, C, _),',
              '    tcp_read(C, 4096, 5000, Codes),',
              '    append(Codes, [32,98,97,99,107], Reply),   % " back"',
              '    tcp_write(C, Reply),',
              '    tcp_close(C),',
              '    ( tcp_accept(S, 20000, _, _) -> true ; true ).   % listening, for the kill' ]),
    cocolog(Bin),
    sh_join([Bin, ' run ', Listener, ' "serve(''', P, ''')" >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    unix_listening(P),
    written(( tcp_connect(unix(P), C1), tcp_write(C1, 'over a file'),
              tcp_read(C1, 4096, 5000, Cs1), atom_codes(T1, Cs1), tcp_close(C1) ), T1, G1),
    check('a second process reaches the first through its socket file', G1, 'over a file back'),
    proc_kill(Pid, 9), ( proc_wait(Pid, 5000, _) -> true ; true ),
    ( access_file(P, exist) -> K2 = left ; K2 = gone ),
    ( tcp_connect(unix(P), X2) -> tcp_close(X2), W2 = connected ; tcp_why(W2) ),
    check('killed while it listened, its file is left, and nobody answers on it', K2/W2,
          left/'Connection refused'),
    written(( tcp_listen(unix(P), S3), tcp_connect(unix(P), C3), tcp_accept(S3, 2000, A3, _),
              tcp_close(C3), tcp_close(A3), tcp_close(S3),
              ( access_file(P, exist) -> R3 = left ; R3 = removed ) ), R3, G3),
    check('a listen replaces the leftover, and its close removes the file', G3, removed).
