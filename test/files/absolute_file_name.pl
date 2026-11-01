%  absolute_file_name/2,3, expand_file_search_path/2, file_name_extension/3
%  and expand_file_name/2. Run by BOTH SWI-Prolog and cocolog in the same
%  fresh sandbox, its fixture d1/a.pl, d1/b.txt and d1/sub/c.pl made by
%  test/files.pl, and the output compared byte for byte.
%
%  A PATH IS SHOWN RELATIVE TO THE WORKING DIRECTORY (`rel/2'), and a term is
%  shown with its variables bound to `v' (`show/1'), so neither the sandbox's
%  name nor a variable's number reaches the output. No "..." text: a string
%  in swipl is a list of codes in cocolog.

:- dynamic seen/1.

file_search_path(myal, d1).
file_search_path(myal2, myal(sub)).
file_search_path(loop1, loop2(x)).
file_search_path(loop2, loop1(y)).
prolog_file_type(txt, mytext).

rel(A, R) :- atom(A), working_directory(W, W), atom_concat(W, R0, A), !, atom_concat('./', R0, R).
rel(T, T).

show(T) :- copy_term(T, C), term_variables(C, Vs), bindv(Vs), rels(C, D), print(D), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

%  every atom of the term that names a place under the working directory,
%  relative
rels(T, R) :- atom(T), !, rel(T, R).
rels(T, T) :- \+ compound(T), !.
rels(T, R) :- T =.. [F|As], rels_list(As, Bs), R =.. [F|Bs].
rels_list([], []).
rels_list([A|As], [B|Bs]) :- rels(A, B), rels_list(As, Bs).

t(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), show(G-R).

main :-
    files_found, options, errors, aliases, names, extensions, expansion.

files_found :-
    t(absolute_file_name(d1/a, _, [extensions([pl])])),
    t(absolute_file_name(d1/a, _, [file_type(prolog)])),
    t(absolute_file_name(d1/zz, _, [file_type(prolog)])),
    t(absolute_file_name(d1/a, _, [file_type(source), access(read)])),
    t(absolute_file_name(d1, _, [file_type(directory)])),
    t(absolute_file_name(d1/sub, _, [file_type(directory), access(write)])),
    t(absolute_file_name(b, _, [relative_to(d1), extensions([txt])])),
    t(absolute_file_name(d1/'a.pl', _, [relative_to('d1/sub/c.pl')])),
    t(absolute_file_name('a.pl', _, [relative_to('d1/sub/')])),
    t(absolute_file_name(d1/a, _, [extensions([pl]), access(read), relative_to(d1)])),
    t(absolute_file_name(a, _, [extensions(['.pl'])])),
    t(absolute_file_name(d1/sub/c, _, [solutions(all), extensions([pl, '']), access(exist)])),
    findall(F, absolute_file_name(d1/a, F, [solutions(all), extensions(['', pl, txt])]), L1), show(L1),
    findall(F, absolute_file_name('d1/*', F, [expand(true), solutions(all)]), L2), show(L2),
    t(absolute_file_name(d1/'*.pl', _, [expand(true)])),
    t(absolute_file_name(d1/'a.pl', _, [access([read, write])])),
    t(absolute_file_name(d1/zzz, _, [access(write)])),
    t(absolute_file_name(d1/zzz, _, [access(none)])),
    t(absolute_file_name(d1/a, _, [file_type(txt)])),
    t(absolute_file_name(d1/a, [extensions([pl])], _)),
    t(absolute_file_name(d1/a, _, [file_type(prolog), a-1])),
    t(absolute_file_name(foo, _, [extensions=[pl]])),
    t(absolute_file_name(foo, _, [solutions=all, access=read])),
    t(absolute_file_name(foo, _, [bad(1)])).

options :-
    t(absolute_file_name(d1/zz, _, [access(read), file_errors(fail)])),
    t(absolute_file_name(d1/a, _, [extensions([pl]), file_type(directory)])),
    t(absolute_file_name(d1/a, _, [file_type(prolog), solutions(all), file_errors(fail)])),
    t(absolute_file_name(d1/a, _, [expand(1)])),
    t(absolute_file_name(a/b/c, _, [])),
    t(absolute_file_name(a/(b/c), _, [])),
    t(absolute_file_name(a/'', _, [])),
    t(absolute_file_name(a/1, _, [])).

errors :-
    t(absolute_file_name(_, _, [])),
    t(absolute_file_name(foo, _, bad)),
    t(absolute_file_name(foo, _, [access(bad)])),
    t(absolute_file_name(foo, _, [file_type(bad)])),
    t(absolute_file_name(foo, _, [file_errors(bad)])),
    t(absolute_file_name(foo, _, [solutions(bad)])),
    t(absolute_file_name(f(x), _, [])),
    t(absolute_file_name(a/f(x), _, [])),
    t(absolute_file_name(d1/zz, _, [file_type(prolog), access(read)])),
    t(absolute_file_name(d1/a, _, [file_type(directory)])),
    t(absolute_file_name(d1, _, [file_type(prolog), access(read)])),
    t(absolute_file_name(d1, _, [access(read)])),
    t(absolute_file_name(d1, _, [file_type(regular), access(read)])),
    t(absolute_file_name(d1/a, _, [access(execute)])),
    t(absolute_file_name(d1/'a.pl', _, [access(none), file_type(directory)])),
    t(absolute_file_name(d1/a, _, [file_type(prolog), access(execute)])),
    t(absolute_file_name(d1/a, _, [file_type(prolog), access([read, bad])])),
    t(absolute_file_name(a, _, [extensions(pl)])),
    t(absolute_file_name(d1/a, _, [extensions([1])])),
    t(absolute_file_name(d1/a, _, [file_type(1)])),
    t(absolute_file_name(d1/a, _, [solutions(1)])),
    t(absolute_file_name('d1/a', _, [expand(yes)])),
    t(absolute_file_name(d1/a, _, [access(read), access(exist), extensions([pl])])),
    t(absolute_file_name(d1/a, _, [extensions([pl]), 3])),
    t(absolute_file_name(d1/a, _, [3, extensions([pl])])),
    t(absolute_file_name(foo, _, [file_type(prolog), foo])),
    t(absolute_file_name(foo, _, [file_type(prolog), f(a, b)])),
    t(absolute_file_name(foo, _, [file_type(prolog), _])),
    t(absolute_file_name(foo, _, [file_type(prolog), f(x) = y])),
    t(absolute_file_name(foo, _, [access(read), access = exist])).

aliases :-
    t(absolute_file_name(myal(b), _, [file_type(mytext), access(read)])),
    t(absolute_file_name(myal2(c), _, [file_type(prolog), access(read)])),
    t(absolute_file_name(loop1(z), _, [])),
    t(expand_file_search_path(myal(q), _)),
    findall(E, expand_file_search_path(myal2(q/r), E), L), show(L),
    t(absolute_file_name(nosuchalias(z), _, [file_errors(fail)])),
    t(absolute_file_name(myal(b), _)),
    t(absolute_file_name(myal(nothing), _)),
    (   absolute_file_name(library(assoc), F1, [file_type(prolog), access(read)])
    ->  file_base_name(F1, B1), show(library_assoc(B1))
    ;   show(library_assoc(none))
    ).

names :-
    t(absolute_file_name('a/', _)),
    t(absolute_file_name('/tmp/', _)),
    t(absolute_file_name('a//b', _)),
    t(absolute_file_name('a/./b/', _)),
    t(absolute_file_name('a/..', _)),
    t(absolute_file_name('a/../', _)),
    t(absolute_file_name('./a', _)),
    t(absolute_file_name('/a/b/../../..', _)),
    t(absolute_file_name('//x', _)),
    t(absolute_file_name('a/b/.', _)),
    t(absolute_file_name('a/b/./', _)),
    t(absolute_file_name('~/x', _)),
    t(absolute_file_name('$HOME/x', _)),
    t(absolute_file_name('/a/b/../', _)),
    t(absolute_file_name('x/./.', _)).

extensions :-
    t(file_name_extension('a.pl', pl, _)),
    t(file_name_extension('a.b.pl', pl, _)),
    t(file_name_extension('d.pl/a', pl, _)),
    t(file_name_extension('.pl', pl, _)),
    t(file_name_extension('a.', pl, _)),
    t(file_name_extension('a.pl', '', _)),
    t(file_name_extension('a.PL', pl, _)),
    t(file_name_extension('/x/a.pl', '.pl', _)),
    t(file_name_extension(a, '.', _)),
    t(file_name_extension('a.pl', '.', _)),
    t(file_name_extension('a..pl', pl, _)),
    t(file_name_extension('x/.pl', pl, _)),
    t(file_name_extension('.', pl, _)),
    t(file_name_extension('..', pl, _)),
    t(file_name_extension(x, '..pl', _)),
    t(file_name_extension(_, '.pl', 'a.pl')),
    t(file_name_extension(a, '.pl', 'a.pl')),
    t(file_name_extension(_, txt, 'a.pl')),
    t(file_name_extension('a.pl', pl, 'a.pl')),
    t(file_name_extension(_, '.', abc)).

expansion :-
    t(expand_file_name('d1/*', _)),
    t(expand_file_name('d1/{a,b}.*', _)),
    t(expand_file_name('d1/[ab].*', _)),
    t(expand_file_name('d1/?.pl', _)),
    t(expand_file_name('nomatch_q*', _)),
    t(expand_file_name('d1/sub/', _)),
    t(expand_file_name('$NOPE_Q/x', _)),
    t(expand_file_name('a$b', _)),
    t(expand_file_name($, _)),
    t(expand_file_name('~nouser_q/x', _)),
    (   expand_file_name('~/x', [H1]), expand_file_name('$HOME/x', [H2])
    ->  show(home_same(H1 == H2))
    ;   show(home_same(no))
    ).
