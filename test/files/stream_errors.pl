%  library(stream)'s errors and the checks behind them, as swipl's.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Through 3.15.2 a stream that was no stream raised its error with the
%  bare context stream_slot/2, the C half's with stream:'$stream_get_char'/3
%  and the like, put_code/2 checked its code after the stream, a get with
%  its argument bound did not read first, the character, line and term
%  predicates refused a binary stream, open/4 passed most options by, a
%  position was a byte offset, and an alias was no stream. swipl names the
%  predicate the program called -- context(system:get_char/2, _), and
%  read_util:read_line_to_codes/2, system:read_string/5 and
%  system:'$stream_property'/2 where its own clauses raise -- checks a
%  put's character before the stream and a stream's direction before its
%  kind, reads a binary stream's bytes as characters (octet), and answers
%  '$stream_position'(Char, Line, LinePos, Byte) for a position.
%
%  Every case opens the streams it needs afresh, and a stream in an answer
%  is written by the name it was opened as: swipl writes <stream>(0x...).
%  Not compared, as not swipl's: read_line_to_codes/2 and
%  read_stream_to_codes/2 of an OUTPUT stream (swipl reads the file under
%  it, or raises io_error(write, S)); the order stream_property/2 walks the
%  streams in; and a position of a standard stream.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  the stream named K stands for S in an answer
subst(T, _, T) :- var(T), !.
subst(T, s(Name, H), R) :- T == H, !, R = Name.
subst(T, S, R) :- compound(T), !, T =.. [F|As], subst_l(As, S, Bs), R =.. [F|Bs].
subst(T, _, T).
subst_l([], _, []).
subst_l([A|As], S, [B|Bs]) :- subst(A, S, B), subst_l(As, S, Bs).

bind([]).
bind(['_'|Vs]) :- bind(Vs).

shown(R0, R) :- copy_term(R0, R), term_variables(R, Vs), bind(Vs).

%  the streams, each opened for the one case
fresh(in, S) :- open('se_in.txt', read, S, [encoding(utf8)]).
fresh(out, S) :- open('se_out.txt', write, S, [encoding(utf8)]).
fresh(bin, S) :- open('se_in.bin', read, S, [type(binary)]).
fresh(bout, S) :- open('se_out.bin', write, S, [type(binary)]).
fresh(closed, S) :- open('se_in.txt', read, S), close(S).
fresh(var, _).
fresh(foo, foo).
fresh(int, 3).
fresh(comp, f(x)).

closes(S) :- ( nonvar(S), S \== foo, S \== 3, S \== f(x) -> catch(close(S), _, true) ; true ).

%  K names the stream, G is the goal with `s' where the stream stands
t(K, G0) :-
    fresh(K, S), subst(G0, s(S, s), G),
    catch((G -> R = yes(G) ; R = no), E, R = E),
    closes(S),
    subst(R, s(K, S), R1), shown(R1, R2), shown(G0, G3),
    write(K), write(': '), print(G3), write(' => '), print(R2), nl.

%  a goal of no stream
u(G0) :-
    copy_term(G0, G),
    catch((G -> R = yes ; R = no), E, R = E),
    shown(G0, G1), shown(R, R1),
    print(G1), write(' => '), print(R1), nl.

goal(get_char(s, _)). goal(peek_char(s, _)). goal(put_char(s, a)).
goal(get_code(s, _)). goal(peek_code(s, _)). goal(put_code(s, 0'a)).
goal(get_byte(s, _)). goal(peek_byte(s, _)). goal(put_byte(s, 1)).
goal(read(s, _)). goal(read_term(s, _, [])). goal(write(s, a)). goal(writeq(s, a)).
goal(print(s, a)). goal(write_canonical(s, a)). goal(write_term(s, a, [])).
goal(writeln(s, a)). goal(nl(s)). goal(tab(s, 1)). goal(flush_output(s)). goal(at_end_of_stream(s)).
goal((set_input(s), set_input(user_input))). goal((set_output(s), set_output(user_output))).
goal(read_line_to_string(s, _)). goal(format(s, "x", [])).
goal(close(s)). goal(close(s, [])). goal(set_stream_position(s, _)).

%  of an output stream not compared (the header says why)
goal_on(K, read_line_to_codes(s, _)) :- K \== out, K \== bout.
goal_on(K, read_stream_to_codes(s, _)) :- K \== out, K \== bout.
goal_on(K, stream_property(s, mode(_))) :- K \== var.
goal_on(_, G) :- goal(G).

arg(X) :- member(X, [_, 1, ab, -1, -2, 1.5, f(x), [], "a", 0'a, a, 255, 1114111, 1114112,
                     [a], [97|_], "ab", end_of_file, '']).
%  a string of one character, which double_quotes(codes) cannot write
arg(X) :- atom_string(a, X).

main :-
    write_file('se_in.txt', "abc. d.\n"),
    write_file('se_in.bin', [97, 46, 10, 233, 169, 10, 98]),
    write_file('se_q.bin', [39, 233, 39, 46]),
    write_file('se_c.bin', [37, 233, 10, 97, 46, 10]),
    forall(( member(K, [var, foo, int, comp, closed, in, out, bin, bout]), goal_on(K, G) ), t(K, G)),
    forall(( member(K, [in, out, bin, bout]), arg(X),
             member(G, [put_char(s, X), put_code(s, X), put_byte(s, X), tab(s, X),
                        get_char(s, X), get_code(s, X), get_byte(s, X),
                        peek_char(s, X), peek_code(s, X), peek_byte(s, X)]) ),
           t(K, G)),
    %  a put checks its character or its byte before the stream
    forall(member(G, [put_char(foo, ab), put_char(_, ab), put_code(foo, -1), put_byte(foo, 300),
                      put_byte(_, a), get_char(foo, ab), get_byte(foo, ab), peek_char(foo, ab)]),
           u(G)),
    %  a character is an atom of one, a code, or a list of one of them
    forall(member(X, [[a], [97], [-1], [1114112], [ab], [a, b], [], [0'a, 0'b], 1.5, f(x)]), t(out, put_char(s, X))),
    opens, closes, reads, positions, aliases, octets, currents, formats.

write_file(F, Codes) :- open(F, write, S, [type(binary)]), forall(member(C, Codes), put_byte(S, C)), close(S).

%  open/3,4: the options a list, the mode, each option, the stream
%  unbound, the alias free, the file -- swipl's order
opens :-
    forall(member(G, [ open(_, read, _), open('se_in.txt', foo, _), open('se_in.txt', 1, _),
                       open('se_in.txt', read, x), open('se_none.txt', read, x), open('se_none.txt', read, _), open('.', write, _),
                       open(f(x), read, _), open('se_in.txt', _, _), open('', read, _),
                       open('se_in.txt', read, _, foo), open('se_in.txt', read, _, [type(foo)]),
                       open('se_in.txt', read, _, [foo]), open('se_in.txt', read, _, [_]),
                       open('se_in.txt', read, _, [alias(1)]), open('se_in.txt', read, _, [alias(_)]),
                       open('se_in.txt', read, _, [type(_)]), open('se_in.txt', read, _, [bar]),
                       open('se_in.txt', read, _, [type(text), foo(1,2)]),
                       open('se_in.txt', read, _, [eof_action(foo)]), open('se_in.txt', read, _, [encoding(foo)]),
                       open('se_in.txt', read, _, [encoding(_)]), open('se_in.txt', read, _, [close_on_abort(x)]),
                       open('se_in.txt', read, _, [lock(x)]), open('se_in.txt', read, _, [wait(x)]),
                       open('se_in.txt', read, _, [bom(x)]), open('se_in.txt', read, _, [create(x)]),
                       open('se_in.txt', read, _, [reposition(x)]), open('se_in.txt', read, _, [type(binary)|x]),
                       open('se_in.txt', read, _, [type(binary)|_]), open('se_in.txt', read, _, [type(text)|bar]),
                       open('se_in.txt', foo, _, [type(foo)]), open(_, read, _, [type(foo)]),
                       open('se_in.txt', read, x, [type(foo)]), open('se_in.txt', read, x, foo),
                       open('se_in.txt', _, _, foo), open(f(x), read, _, [type(foo)]),
                       open('se_in.txt', read, _, [alias(user_input)]) ]),
           u(G)),
    forall(member(O, [ [bar(1)], [buffer(foo)], [encoding(octet)], [encoding(utf8)],
                       [eof_action(error), lock(none), create([read]), bom(true), close_on_abort(true),
                        wait(false), reposition(false)] ]),
           ( catch(( open('se_in.txt', read, S, O), close(S), R = yes ), E, R = E ),
             shown(O-R, P), print(open(O)-P), nl )),
    %  of two types, the last
    open('se_in.txt', read, S2, [type(binary), type(text)]), stream_property(S2, type(T2)), close(S2),
    print(type(T2)), nl,
    open('se_in.txt', read, S3, [alias(se1)]),
    u(open('se_in.txt', read, _, [alias(se1)])), close(S3),
    %  the file is opened before the stream is asked: a write made it
    u(open('se_made.txt', write, x)), ( exists_file('se_made.txt') -> M = made ; M = none ),
    %  with an alias the stream is the alias, and another term fails
    ( open('se_in.txt', read, se6, [alias(se6)]) -> close(se6), A6 = yes ; A6 = no ),
    ( open('se_in.txt', read, b, [alias(se7)]) -> A7 = yes ; A7 = no ),
    ( stream_property(S7, alias(se7)) -> close(S7) ; true ),
    print(bound(M, A6, A7)), nl.

closes :-
    forall(member(G, [ close(_), close(foo), close(1), close(f(x)), close(user_input), close(user_output),
                       close(_, foo), close(_, [_]), close(user_input, [force(_)]), close(foo, [force(x)]),
                       close(foo, [foo]), close(user_input, [bar(1)]), close(user_input, [force(true)|bar]),
                       close(user_input, [force(true)|_]), close(user_output, [force(true)]) ]),
           u(G)),
    open('se_in.txt', read, S), close(S),
    catch(close(S), E1, true), subst(E1, s(closed, S), E1b), print(E1b), nl,
    catch(close(S, []), E2, true), subst(E2, s(closed, S), E2b), print(E2b), nl,
    catch(close(S, foo), E3, true), shown(E3, E3b), print(E3b), nl.

%  read_term/2,3: the stream, then the options, before a byte is read
reads :-
    forall(member(G, [ read_term(s, _, _), read_term(s, _, foo), read_term(s, _, [_]),
                       read_term(s, _, [foo(x)]), read_term(s, _, [variable_names(x)]),
                       read_term(s, _, [foo]), read_term(s, _, [foo(1,2)]), read_term(s, _, [a|_]),
                       read_term(s, _, [foo|bar]), read_term(s, _, [variable_names(_)|bar]),
                       read_term(s, _, [syntax_errors(x)]) ]),
           ( t(in, G),
             %  what the stream reads next: an option refused read nothing
             fresh(in, S), subst(G, s(S, s), G1), ( catch(G1, _, true) -> true ; true ), read(S, Next), close(S),
             write('  then '), print(Next), nl )),
    forall(member(G, [read_term(foo, _, foo), read_term(_, _, [_]), read(foo, _), read_term(1, _, [])]), u(G)).

%  '$stream_position'(Char, Line, LinePos, Byte), read and set
positions :-
    open('se_in.txt', read, S), stream_property(S, position(P0)), get_char(S, _),
    stream_property(S, position(P1)), get_char(S, _), get_char(S, _), get_char(S, _), get_char(S, _),
    stream_property(S, position(P2)), set_stream_position(S, P1), get_char(S, C1),
    set_stream_position(S, '$stream_position'(0, 1, 0, 6)), get_char(S, C2), stream_property(S, position(P3)),
    print(positions(P0, P1, P2, C1, C2, P3)), nl,
    forall(member(G, [ set_stream_position(S, 0), set_stream_position(S, _),
                       set_stream_position(S, '$stream_position'(a, b, c, d)), set_stream_position(S, foo),
                       set_stream_position(foo, x) ]),
           ( catch((G -> R = yes ; R = no), E, R = E), subst(R, s(in, S), R1), shown(R1, R2),
             subst(G, s(in, S), G1), shown(G1, G2), print(G2), write(' => '), print(R2), nl )),
    close(S),
    open('se_out.txt', write, O), stream_property(O, position(Q0)), write(O, 'ab\ncd'),
    stream_property(O, position(Q1)), close(O),
    open('se_out.txt', append, A), stream_property(A, position(Q2)), write(A, x),
    stream_property(A, position(Q3)), close(A),
    open('se_in.bin', read, B, [type(binary)]), get_char(B, _), get_char(B, _), get_char(B, _),
    get_char(B, _), get_char(B, _), stream_property(B, position(Q4)), close(B),
    print(positions(Q0, Q1, Q2, Q3, Q4)), nl.

%  an alias given is the stream
aliases :-
    open('se_in.txt', read, S, [alias(se2)]),
    ( S == se2 -> A = alias ; A = handle ), stream_property(S, alias(Al)), get_char(se2, C), close(S),
    print(aliases(A, Al, C)), nl,
    open('se_in.txt', read, S2, [alias(se3), alias(se4)]),
    ( S2 == se4 -> A2 = last ; A2 = other ), close(S2), print(aliases(A2)), nl,
    open('se_out.txt', write, O, [alias(se5)]), close(se5), u(close(se5)), u(close(O)).

%  a binary stream's characters are its bytes, swipl's octets
octets :-
    open('se_in.bin', read, B, [type(binary)]), get_char(B, C1), get_char(B, C2), peek_code(B, P3),
    get_code(B, C3), get_char(B, C4), char_code(C4, K4), read_line_to_codes(B, L), read_line_to_codes(B, L2),
    close(B),
    open('se_q.bin', read, B2, [type(binary)]), read_term(B2, T, []), close(B2), atom_codes(T, Tc),
    print(octets(C1, C2, P3, C3, K4, L, L2)), nl,
    print(read(Tc)), nl,
    %  a term's position on a binary stream counts its bytes, an octet past 127 too
    open('se_c.bin', read, B3, [type(binary)]), read_term(B3, T3, [term_position(Q3)]), close(B3),
    print(read(T3, Q3)), nl,
    open('se_out.bin', write, O, [type(binary)]), put_char(O, '\xE9\'), put_code(O, 255), write(O, 'x'),
    format(O, "~w", ['\xFC\']), nl(O), writeq(O, 'a b'), tab(O, 1), close(O),
    open('se_out.bin', read, R, [type(binary)]), read_bytes(R, Bs), close(R),
    print(bytes(Bs)), nl,
    open('se_out.bin', write, O2, [type(binary)]),
    forall(member(K-G, [put_char-put_char(O2, '\x101\'), put_code-put_code(O2, 256), write-write(O2, 'a\x101\')]),
           ( catch((G -> Rs = yes ; Rs = no), E, Rs = E), subst(Rs, s(bout, O2), Rs1), shown(Rs1, Rs2),
             print(K), write(' => '), print(Rs2), nl )),
    close(O2),
    open('se_out.bin', read, R2, [type(binary)]), read_bytes(R2, Bs2), close(R2),
    print(bytes(Bs2)), nl.

read_bytes(S, Bs) :- get_byte(S, B), ( B =:= -1 -> Bs = [] ; Bs = [B|Rest], read_bytes(S, Rest) ).

%  current_input/1 and current_output/1 compare a stream given; the forms
%  of one argument name the stream current_input or current_output
currents :-
    forall(member(G, [ current_input(foo), current_output(3), current_input(f(x)),
                       current_output(user_output), current_input(user_input), current_input(user_output) ]),
           u(G)),
    open('se_in.txt', read, I), set_input(I),
    findall(G-R, ( member(G, [get_char(1.5), get_byte(_), peek_byte(_), peek_code(f(x)), get_char(_)]),
                   catch((G -> R = yes(G) ; R = no), E, R = E) ), Rs),
    set_input(user_input), close(I),
    forall(member(G-R, Rs), ( shown(G-R, P), print(P), nl )),
    open('se_out.txt', write, O), set_output(O),
    findall(G-R, ( member(G, [put_char(ab), put_code(-1), put_byte(a), put_byte(1), put_char(_)]),
                   catch((G -> R = yes ; R = no), E, R = E) ), Ws),
    set_output(user_output), close(O),
    forall(member(G-R, Ws), ( shown(G-R, P), print(P), nl )).

%  the formatted writers into a stream that takes no output
formats :-
    forall(member(G, [ format(user_input, "x", []), write_term(user_input, a, foo),
                       write_term(foo, a, []), write_term(user_output, a, foo), write_term(foo, a, [bad]),
                       write_term(_, a, [bad]), write_term(user_output, a, [bad]), nl(foo),
                       write(_, a), writeq(f(x), a), print(foo, a), write_canonical(user_input, a),
                       flush_output(user_input), at_end_of_stream(user_output), at_end_of_stream(_),
                       stream_property(foo, alias(_)), stream_property(foo, _), stream_property(_, 1),
                       stream_property(user_input, foo) ]),
           u(G)).
