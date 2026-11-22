%  flag/3, get_flag/2, set_flag/2, current_flag/1 and shell/1,2, swipl
%  9.0.4's (cocolog 3.70.0): COMPAT.md's fourth group of small built-ins,
%  the process's. The case holds:
%  - a key as swipl's getKeyEx() reads it: an atom, [] apart from '[]',
%    an integer within 2^56 either side, a compound by its name and arity
%    (f() apart from f), anything else type_error(key, K), unbound an
%    instantiation error, each named by the predicate asked;
%  - a value: an atom, an integer of 64 bits, a float -0.0, an infinity
%    and a NaN among them, a get of a float bound already compared as a C
%    double; anything else type_error(flag_value, V) named flag/3;
%  - flag/3: Old == New a get, else Old unified and New stored as it is
%    where it is an atom and evaluated where it is not, its errors named
%    '$syspreds':update_flag/3, a rational refused as set_flag/2 refuses it;
%  - current_flag/1: a key asked of the table, its errors its own, and the
%    walk over every key made, f() walked as f;
%  - shell/1,2: the command as text, its status, a child's output before
%    the text a buffer holds, PROLOGCHILD=yes, SIGINT ignored while the
%    child runs, the text's errors;
%  - the six as predicate_property/2, listing/1 and clause/2 see them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.69.1 cocolog had none of them, and a call raised
%  existence_error. Not here, cocolog's own: a child a signal ended, which
%  swipl 9.0.4 answers 1 for, saying that shell/2 `did not clear
%  exception' (test/errors.pl), flags shared by threads and green tasks
%  (test/thread.pl, test/async.pl), and the integers past 64 bits swipl
%  makes (COMPAT.md).

%% the goals below name a variable to see what a call bound it to
:- style_check(-singleton).

%% a term with its variables named, by a walk of its own
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended, with its bindings; an error by its formal and the
%% predicate its context names
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    % cocolint: C2 -- each ball here is a builtin's, whose context names it as swipl's
    (   R = caught(error(F, context(C, _)))
    ->  pv(L-caught(F, C))
    ;   pv(L-R)
    ),
    nl.

%% a shell/1,2 goal, what came before it put out first: the child writes
%% to the descriptor the two systems' buffers are written to later
s(L, G) :- flush_output, t(L, G), flush_output.

%% the properties swipl's predicate_property/2 gives a system predicate,
%% less those that move with the build and the file swipl's is read from
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_),
                                  file(_), line_count(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

main :-
    keys,
    values,
    flags,
    walks,
    shells,
    seen.

keys :-
    t(k1, get_flag(ka, V1)),
    t(k2, flag(ka, O2, O2+1)),
    t(k3, get_flag(ka, V3)),
    %% the list's end and the atom of two characters are two keys
    t(k4, set_flag([], 2)),
    t(k5, get_flag('[]', V5)),
    t(k6, get_flag([], V6)),
    t(k7, set_flag('[]', 5)),
    t(k8, get_flag([], V8)),
    %% an integer, a negative one, and the tagged integer's edges
    t(k9, set_flag(1, one)),
    t(k10, get_flag(1, V10)),
    t(k11, get_flag('1', V11)),
    t(k12, set_flag(-3, m3)),
    t(k13, get_flag(-3, V13)),
    A14 is 2**56 - 1, t(k14, set_flag(A14, top)),
    t(k15, get_flag(A14, V15)),
    A16 is -(2**56), t(k16, set_flag(A16, bottom)),
    t(k17, get_flag(A16, V17)),
    A18 is 2**56, t(k18, get_flag(A18, V18)),
    A19 is -(2**56) - 1, t(k19, set_flag(A19, x)),
    A20 is 2**59, t(k20, flag(A20, _, 1)),
    A21 is 2**62, t(k21, current_flag(A21)),
    %% a compound by its name and arity, f() apart from f
    t(k22, set_flag(f(a), 3)),
    t(k23, get_flag(f(b), V23)),
    t(k24, get_flag(f(a, b), V24)),
    t(k25, get_flag(f, V25)),
    t(k26, set_flag(f(), 4)),
    t(k27, get_flag(f(), V27)),
    t(k28, get_flag(f, V28)),
    t(k29, set_flag([a], 9)),
    t(k30, get_flag([x, y], V30)),
    t(k31, get_flag([a|b], V31)),
    t(k32, get_flag(g(_, _, _), V32)),
    %% no key: unbound, a float, a rational, a string, each named by the
    %% predicate asked
    t(k33, get_flag(_, V33)),
    t(k34, set_flag(_, 1)),
    t(k35, flag(_, O35, 1)),
    t(k36, get_flag(1.5, V36)),
    t(k37, set_flag(1.0, 1)),
    t(k38, flag(1r2, O38, 1)),
    atom_string(k, S39), t(k39, get_flag(S39, V39)),
    t(k40, set_flag(S39, 1)),
    t(k41, flag(S39, O41, O41)),
    t(k42, current_flag(S39)),
    t(k43, current_flag(2.5)),
    nl.

values :-
    t(v1, set_flag(va, abc)),
    t(v2, get_flag(va, V2)),
    t(v3, get_flag(va, abc)),
    t(v4, get_flag(va, abd)),
    t(v5, set_flag(va, [])),
    t(v6, get_flag(va, V6)),
    %% Old == New is a get: [] is never evaluated
    t(v6a, flag(va, O6a, O6a)),
    t(v7, get_flag(va, '[]')),
    t(v8, set_flag(va, '[]')),
    t(v9, get_flag(va, [])),
    t(v10, get_flag(va, '[]')),
    t(v11, set_flag(va, 'hello world')),
    t(v12, get_flag(va, V12)),
    t(v13, set_flag(va, nan)),
    t(v14, get_flag(va, V14)),
    %% the two ends of 64 bits
    t(v15, set_flag(vi, 9223372036854775807)),
    t(v16, get_flag(vi, V16)),
    t(v17, set_flag(vi, -9223372036854775808)),
    t(v18, get_flag(vi, V18)),
    t(v19, get_flag(vi, -9223372036854775808.0)),
    %% a float: 1.5, -0.0, an infinity and a NaN, and a get of a float
    %% bound already compared as a C double, as PL_unify_float() does
    t(v20, set_flag(vf, 1.5)),
    t(v21, get_flag(vf, V21)),
    t(v22, get_flag(vf, 1.5)),
    t(v23, get_flag(vf, 3r2)),
    t(v24, set_flag(vf, -0.0)),
    t(v25, get_flag(vf, V25)),
    t(v26, get_flag(vf, 0.0)),
    t(v27, get_flag(vf, -0.0)),
    t(v28, get_flag(vf, 0)),
    I29 is inf, t(v29, set_flag(vf, I29)),
    t(v30, get_flag(vf, V30)),
    t(v31, get_flag(vf, I29)),
    N32 is nan, t(v32, set_flag(vf, N32)),
    t(v33, get_flag(vf, V33)),
    t(v34, get_flag(vf, N32)),
    t(v35, set_flag(vf, 2)),
    t(v36, get_flag(vf, 2.0)),
    %% no value: unbound, a compound, a rational, a string, named flag/3
    t(v37, set_flag(vx, _)),
    t(v38, set_flag(vx, f(x))),
    t(v39, set_flag(vx, 2**3)),
    t(v40, set_flag(vx, 1r3)),
    atom_string(s, S41), t(v41, set_flag(vx, S41)),
    t(v42, get_flag(vx, V42)),
    nl.

flags :-
    t(f1, flag(fa, O1, O1+1)),
    t(f2, flag(fa, O2, O2+1)),
    t(f3, flag(fa, P3, P3)),
    %% Old == New: a get, which a value that is not Old fails
    t(f4, flag(fa, O4, O4)),
    t(f5, flag(fa, a, a)),
    t(f6, flag(fa, 2, 2)),
    %% Old unified first
    t(f7, flag(fa, 7, 5)),
    t(f8, flag(fa, x, 5)),
    t(f9, flag(fa, 2, 5)),
    t(f10, get_flag(fa, V10)),
    %% New evaluated, or stored as it is where it is an atom
    t(f11, flag(fb, _, 2*3+1)),
    t(f12, get_flag(fb, V12)),
    t(f13, flag(fb, _, 5/2)),
    t(f14, get_flag(fb, V14)),
    t(f15, flag(fb, O15, O15+1)),
    t(f16, get_flag(fb, V16)),
    t(f17, flag(fb, _, 5//2)),
    t(f18, get_flag(fb, V18)),
    t(f19, flag(fb, _, max(1, 2.0))),
    t(f20, get_flag(fb, V20)),
    t(f21, flag(fb, _, pi)),
    t(f22, get_flag(fb, V22)),
    t(f23, flag(fb, _, e)),
    t(f24, get_flag(fb, V24)),
    t(f25, flag(fb, _, abc)),
    t(f26, flag(fb, O26, O26+1)),
    t(f27, get_flag(fb, V27)),
    t(f28, flag(fb, _, -(3))),
    t(f29, get_flag(fb, V29)),
    t(f30, flag(fb, _, 1.0Inf)),
    t(f31, get_flag(fb, V31)),
    %% what New's evaluation raises, named update_flag/3, and the value
    %% it makes that set_flag/2 refuses, named flag/3
    t(f32, flag(fc, _, _)),
    t(f33, flag(fc, _, foo+1)),
    t(f34, flag(fc, _, f(x))),
    t(f35, flag(fc, _, [])),
    t(f36, flag(fc, _, 0.0/0.0)),
    t(f37, flag(fc, _, 1/0)),
    t(f38, flag(fc, _, 1r3)),
    t(f39, flag(fc, _, 2r4 + 1r4)),
    t(f40, get_flag(fc, V40)),
    %% a key asked by flag/3 is made, Old or no Old
    t(f41, flag(fd, 3, 4)),
    t(f42, current_flag(fd)),
    t(f43, flag(fe, a, a)),
    t(f44, current_flag(fe)),
    %% Old unified before New is evaluated: a New that is no number is
    %% never asked where Old fails
    t(f45, flag(fa, 99, foo+1)),
    t(f46, flag(fa, 5, foo+1)),
    nl.

walks :-
    t(w1, current_flag(ka)),
    t(w2, current_flag(never_made)),
    t(w3, current_flag(f(_))),
    t(w4, current_flag(f(_, _))),
    t(w5, current_flag(g(1, 2, 3))),
    t(w6, current_flag(f())),
    t(w7, current_flag([])),
    t(w8, current_flag('[]')),
    t(w9, current_flag(1)),
    t(w10, current_flag(2)),
    %% asked, a key is made: get_flag/2 of one with no value yet
    t(w11, current_flag(wz)),
    t(w12, get_flag(wz, 1)),
    t(w13, current_flag(wz)),
    %% every key made, in the standard order (the walk's own order is
    %% each system's table's)
    findall(K, current_flag(K), Ks), msort(Ks, Ss), length(Ss, N),
    pv(walk(N, Ss)), nl,
    %% bound to something the keys are not
    findall(X, current_flag(f(X)), Fs), length(Fs, NF), pv(fs(NF)), nl,
    t(w14, current_flag(x(_, _, _, _, _))),
    nl.

shells :-
    s(h1, shell(true)),
    s(h2, shell(false)),
    s(h3, shell('exit 3')),
    s(h4, shell('exit 3', S4)),
    s(h5, shell('exit 0', S5)),
    s(h6, shell('exit 300', S6)),
    s(h7, shell(true, 0)),
    s(h8, shell(true, 1)),
    s(h9, shell(true, a)),
    s(h10, shell('', S10)),
    %% the command is text: an atom, codes, characters, a number
    atom_codes('exit 4', C11), s(h11, shell(C11, S11)),
    atom_chars('exit 5', C12), s(h12, shell(C12, S12)),
    atom_string('exit 6', C13), s(h13, shell(C13, S13)),
    s(h14, shell(true, S14)),
    s(h15, shell([e, x, i, t, ' ', 5], S15)),
    s(h16, shell(_)),
    s(h17, shell(_, S17)),
    s(h18, shell(f(x))),
    %% the child's line comes before the text the buffer holds
    flush_output, write(before), shell('echo child'), write(after), nl, flush_output,
    s(h19, shell('echo "[$PROLOGCHILD]"')),
    s(h20, shell('echo $0', S20)),
    s(h21, shell('printf x; printf y; echo', S21)),
    %% SIGINT the process is sent while the child runs is ignored
    s(h22, shell('sleep 0.2; kill -INT $PPID; sleep 0.2; exit 3', S22)),
    s(h23, shell('exit 1', S23)),
    nl.

seen :-
    forall(member(H, [flag(_, _, _), get_flag(_, _), set_flag(_, _),
                      current_flag(_), shell(_), shell(_, _)]),
           pp(H)),
    listing(get_flag/2),
    listing(set_flag/2),
    listing(current_flag/1),
    listing(shell/2),
    t(s1, clause(get_flag(_, _), _)),
    t(s2, clause(shell(_, _), _)),
    t(s3, clause(current_flag(_), _)),
    t(s4, once(clause(flag(_, _, _), B4))),
    t(s5, clause(shell(_), B5)).
