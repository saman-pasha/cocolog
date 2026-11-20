%  A stream with no place to seek to -- a FIFO -- opened for a text read,
%  which looks for a BOM, as swipl's. Run by BOTH SWI-Prolog and cocolog,
%  output compared byte for byte; test/files.pl's fixture makes each FIFO in
%  the sandbox and a writer for it, which waits for this program to open it.
%
%  Through 3.64.4 library(stream) looked for a BOM by reading three bytes
%  and seeking back, which a FIFO cannot do: its first three bytes were
%  lost, so `x. y. zz.' read as y and zz, `a.' as end_of_file, and a UTF-16
%  text with its BOM lost the character after it. swipl reads every byte.
%  Each FIFO is opened once and read to its end; an atom past ASCII is
%  written as its codes, which no locale writes two ways.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  the FIFO, the open's options, and what is read: terms or characters
fifo(plain,    [],                    terms).
fifo(bom8,     [],                    terms).
fifo(two,      [],                    terms).
fifo(one,      [],                    terms).
fifo(empty,    [],                    terms).
fifo(le_bom,   [],                    terms).
fifo(le_nobom, [encoding(utf16le)],   terms).
fifo(be_bom,   [encoding(utf16be)],   terms).
fifo(chars,    [],                    chars).
fifo(nobom,    [bom(false)],          terms).

terms(S, L) :-
    catch(read(S, T), error(E, _), T = err(E)),
    (   T == end_of_file -> L = [T]
    ;   T = err(_) -> L = [T]
    ;   L = [T|R], terms(S, R)
    ).

chars(S, L) :-
    get_char(S, C),
    (   C == end_of_file -> L = []
    ;   L = [C|R], chars(S, R)
    ).

show(T) :- atom(T), atom_codes(T, Cs), member(C, Cs), C > 127, !, writeq(codes(Cs)).
show(T) :- writeq(T).

show_all([]).
show_all([T|Ts]) :- show(T), write(' '), show_all(Ts).

main :-
    forall(fifo(Name, Opts, How),
           ( open(Name, read, S, Opts),
             call(How, S, L),
             ( stream_property(S, bom(B)) -> true ; B = none ),
             close(S),
             format("~w: ", [Name]), show_all(L), format("bom ~w~n", [B]) )).
