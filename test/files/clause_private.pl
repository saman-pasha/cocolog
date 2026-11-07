%  clause/2 of a predicate written in C, as swipl 9.0.4's pl-proc.c refuses
%  it (cocolog 3.38.0): error(permission_error(access, private_procedure,
%  Name/Arity), context(system:clause/2, _)) for each predicate swipl
%  defines in C that cocolog defines -- in C, or by its library's clauses
%  (between/3, atom_concat/3, sub_atom/5, nb_current/2) -- unless the
%  program defines the name itself; and swipl's qualifiers: an atom's come
%  off, the innermost `system' is the system's definition alone, and any
%  other qualifier makes the head one of (:)/2, which no clause has. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Not here (COMPAT.md): what cocolog writes in C where swipl writes it in
%  Prolog -- call/1, findall/3, format/1, length/2, the control constructs
%  -- whose clauses swipl shows and cocolog refuses as private; a library
%  predicate the program did not import, which swipl's clause/2 does not
%  load (cocolog shows its own clauses: its library is always there); a
%  fact asserted under a builtin's name (`number(dos)'), which swipl
%  refuses and cocolog keeps and shows; and what swipl defines in C and
%  cocolog not at all (tty_size/2), which cocolog finds no clause of.

zz(1).
zz(2) :- zz(1).
msort(a, b).
:- dynamic dd/1.

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% each answer of clause(G, B) as G-B, or the error
t(G) :- t(G, _).
t(G, B) :-
    catch(findall(G-B, clause(G, B), L), E, L = caught(E)),
    pv(L), nl.

%% a head of each indicator, then its answers
ts(PIs) :-
    forall(member(N/A, PIs), ( functor(H, N, A), t(H) )).

main :-
    control, terms, arithmetic, text, database, globals, output, files,
    system, qualifiers, program, errors.

control :-
    format("~n=== control~n"),
    ts([true/0, fail/0, !/0, throw/1, halt/1, trace/0, notrace/0,
        with_output_to/2, strip_module/3, source_location/2,
        redefine_system_predicate/1]).

terms :-
    format("~n=== terms~n"),
    ts([var/1, nonvar/1, atom/1, number/1, integer/1, float/1, atomic/1,
        compound/1, callable/1, is_list/1, ground/1, string/1, rational/1,
        rational/3, cyclic_term/1, acyclic_term/1, (=)/2, (\=)/2, (==)/2,
        (\==)/2, (@<)/2, (@=<)/2, (@>)/2, (@>=)/2, (=@=)/2, (\=@=)/2,
        compare/3, functor/3, arg/3, (=..)/2, compound_name_arity/3,
        compound_name_arguments/3, copy_term/2, copy_term_nat/2, setarg/3,
        nb_setarg/3, term_variables/2, subsumes_term/2,
        unify_with_occurs_check/2]).

arithmetic :-
    format("~n=== arithmetic~n"),
    ts([(is)/2, (=:=)/2, (=\=)/2, (<)/2, (=<)/2, (>)/2, (>=)/2, succ/2,
        plus/3, between/3, set_random/1, random_property/1]).

text :-
    format("~n=== text~n"),
    ts([atom_length/2, atom_codes/2, atom_chars/2, char_code/2,
        atom_number/2, atom_string/2, atom_to_term/3, atom_concat/3,
        atomic_concat/3, atomic_list_concat/2, atomic_list_concat/3,
        atomics_to_string/2, atomics_to_string/3, char_type/2, code_type/2,
        downcase_atom/2, upcase_atom/2, name/2, number_chars/2,
        number_codes/2, number_string/2, read_term_from_atom/3,
        split_string/4, string_bytes/3, string_chars/2, string_code/3,
        string_codes/2, string_concat/3, string_length/2, string_lower/2,
        string_upper/2, get_string_code/3, sub_atom/5, sub_atom_icasechk/3,
        sub_string/5, term_string/2, term_to_atom/2, text_to_string/2]).

database :-
    format("~n=== database~n"),
    ts([assert/1, asserta/1, assertz/1, retract/1, retractall/1,
        abolish/1, abolish/2, clause/2, current_predicate/1, current_op/3,
        op/3, keysort/2, sort/2, sort/4]).

globals :-
    format("~n=== globals~n"),
    ts([nb_getval/2, b_getval/2, b_setval/2, nb_current/2,
        current_prolog_flag/2, set_prolog_flag/2, statistics/2, getenv/2,
        setenv/2, unsetenv/1, get_time/1, sleep/1]).

output :-
    format("~n=== output~n"),
    ts([write/1, writeln/1, print/1, writeq/1, write_canonical/1,
        write_term/2, nl/0, tab/1, format/2, format/3, flush_output/0]).

files :-
    format("~n=== files~n"),
    ts([access_file/2, delete_directory/1, delete_file/1,
        directory_files/2, exists_directory/1, exists_file/1,
        expand_file_name/2, file_base_name/2, file_directory_name/2,
        file_name_extension/3, is_absolute_file_name/1, make_directory/1,
        prolog_to_os_filename/2, read_link/3, rename_file/2, same_file/2,
        size_file/2, time_file/2, tmp_file/2]).

%% a name of the system's the program defines too: its own clauses, and
%% under `system:' the system's
system :-
    format("~n=== system~n"),
    t(msort(_, _)),
    t(system:msort(_, _)),
    t(user:msort(_, _)),
    t(system:user:msort(_, _)),
    t(user:system:msort(_, _)).

%% the qualifiers: an atom's taken off, the innermost the one that counts,
%% and one that is no atom leaving a head of (:)/2
qualifiers :-
    format("~n=== qualifiers~n"),
    t(system:atom_length(_, _)),
    t(user:atom_length(_, _)),
    t(lists:atom_length(_, _)),
    t(system:between(_, _, _)),
    t(system:true),
    t(user:zz(_)),
    t(system:zz(_)),
    t(system:user:zz(_)),
    t(user:system:zz(_)),
    t(system:dd(_)),
    t(system:qqqqqq(_)),
    t(_:zz(_)),
    t(f(x):zz(_)),
    t([]:zz(_)),
    t(3:zz(_)),
    t(user:_:zz(_)),
    t(f(x):3),
    t(_:3),
    t(user:f(x):3).

%% the program's own: its clauses, none of a declared one or an unknown
%% one, and a body that is no goal is one no clause unifies with
program :-
    format("~n=== program~n"),
    t(zz(_)),
    t(zz(2)),
    t(zz(_), zz(_)),
    t(zz(_), 3),
    t(zz(_), (true, 3)),
    t(dd(_)),
    t(qqqqqq(_)),
    t(atom_length(_, _), 3).

errors :-
    format("~n=== errors~n"),
    t(_),
    t(3),
    t(1.5),
    t(user:_),
    t(foo:3),
    t(system:_),
    t(_, true).
