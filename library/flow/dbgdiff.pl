%% library(flow/debug), part: two runs compared -- the calls they made with
%% the same arguments that answered differently, deepest first, and the
%% predicates only one of them called. A regression is hunted with it: the
%% same goal over a program before and after a change, or two goals that
%% should behave alike over one.
%%
%%     flow_diff(+RunA, +RunB, -Diff)
%%     flow_diff_text(+Diff, +PlacesA, +PlacesB, -Text)
%%
%% RunA and RunB are flow_debug/4's runs; record the whole of each
%% (from(1)), or the diff sees only the windows. Diff is
%%
%%     diff(Both, Differs, OnlyA, OnlyB)
%%
%%   Both     how many INPUTS both runs called: an input is a predicate and
%%            its arguments at its Call, as the window wrote them, with each
%%            variable's _G name read as `_' (a name is a heap position, and
%%            differs between any two runs)
%%   Differs  differ(P, In, A, B) for each input both called whose ANSWERS
%%            differ -- the arguments of a call's last Exit, or how it ended
%%            when it never exited (fail, raised, unwound; open or redo at a
%%            window's end) -- one run's set of answers for that input
%%            against the other's. A and B are each c(S, Depth, Box, Panel,
%%            Answer): the first call of that input in its run whose answer
%%            the other run never gave (or its first call, when it gave none
%%            the other did not). DEEPEST FIRST: the deepest input whose
%%            answers differ is where a difference began, and the shallower
%%            ones are its consequences -- the program's inputs first, then
%%            those of a predicate whose name begins with $, the engine's
%%            or a library's own, deepest first among themselves (1.11.0:
%%            on the translator four '$pred_count'/3 inputs, 22 and 16
%%            deep, hid the cause under them)
%%   OnlyA    only(P, N, S, Box, Panel) for each predicate RunA called and
%%            RunB never did: how many calls, and the first's step,
%%            box and panel, in the order of those first calls (a $ one
%%            after the program's, as above)
%%   OnlyB    the same the other way: in a regression, the code that ran
%%            new, or no longer ran
%%
%% A value is compared as the window wrote it, so two arguments longer than
%% text(N) (60) that share their first N characters and their length read
%% as equal: give text(N) to suit the terms. Two variables in one call read
%% as `_' alike, so foo(X, X) and foo(X, Y) are one input.
%%
%% flow_diff_text/4 writes it a line or three an entry; PlacesA and PlacesB
%% are each run's places(P) (flow_debug/4's option), for where a box is
%% written and where a predicate is defined, or none:
%%
%%     % 7 inputs in both runs, 3 answered differently; 0 predicates only in a, 1 only in b
%%     differs at depth 3: add(0,1,_)
%%       a exit add(0,1,1) at step 3, p3.c1.g1 total.pl:3:27
%%       b exit add(0,1,2) at step 3, p3.c1.g1 total.pl:3:27
%%     only in b: double/2, 3 calls, the first at step 4; defined total.pl:5:1

flow_diff(RunA, RunB, diff(Both, Differs, OnlyA, OnlyB)) :-
    flow_diff_calls(RunA, CsA),
    flow_diff_calls(RunB, CsB),
    flow_diff_index(CsA, IA),
    flow_diff_index(CsB, IB),
    assoc_to_keys(IA, KsA),
    findall(K, ( member(K, KsA), get_assoc(K, IB, _) ), KsBoth),
    length(KsBoth, Both),
    findall(Key-differ(P, In, A, B),
            ( member(P-In, KsBoth),
              get_assoc(P-In, IA, LA), get_assoc(P-In, IB, LB),
              flow_diff_answers(LA, OA), flow_diff_answers(LB, OB),
              OA \== OB,
              flow_diff_rep(LA, OB, A), flow_diff_rep(LB, OA, B),
              A = c(SA, DA, _, _, _), B = c(_, DB, _, _, _),
              Deep is -max(DA, DB),
              flow_diff_own(P, Own),
              Key = Own-Deep-SA ),
            KDs),
    keysort(KDs, SDs),
    pairs_values(SDs, Differs),
    flow_diff_only(CsA, CsB, OnlyA),
    flow_diff_only(CsB, CsA, OnlyB).

%% 0 for the program's predicate, 1 for one whose name begins with $
flow_diff_own(N/_, Own) :-
    ( atom(N), atom_concat('$', _, N) -> Own = 1 ; Own = 0 ).

%% each call of a run as c(S, Depth, Box, Panel, P-In, Answer), its texts
%% with their _G names read as `_'
flow_diff_calls(run(_, _, _, _, Calls, _, _, _), Cs) :-
    findall(c(S, D, Box, Pn, P-In, Ans),
            ( member(call(S, P, D, _, Box, Pn, _, In0, Out0, Fate), Calls),
              flow_diff_texts(In0, In),
              (   Out0 == none -> Ans = Fate
              ;   flow_diff_texts(Out0, Out), Ans = exit(Out)
              ) ),
            Cs).

flow_diff_texts([], []).
flow_diff_texts([T|Ts], [U|Us]) :-
    flow_diff_text_ung(T, U),
    flow_diff_texts(Ts, Us).

flow_diff_text_ung(cut(P, L), cut(P1, L)) :- !,
    flow_dbg_ung(P, P1).
flow_diff_text_ung(T, U) :-
    flow_dbg_ung(T, U).

%% Input -> its calls, in the order they were made
flow_diff_index(Cs, I) :-
    empty_assoc(I0),
    flow_diff_index_(Cs, I0, I1),
    assoc_to_list(I1, KLs),
    findall(K-L, ( member(K-R, KLs), reverse(R, L) ), KLs1),
    list_to_assoc(KLs1, I).

flow_diff_index_([], I, I).
flow_diff_index_([c(S, D, Box, Pn, K, Ans)|Cs], I0, I) :-
    C = c(S, D, Box, Pn, Ans),
    (   get_assoc(K, I0, L0) -> put_assoc(K, I0, [C|L0], I1) ; put_assoc(K, I0, [C], I1) ),
    flow_diff_index_(Cs, I1, I).

flow_diff_answers(L, As) :-
    findall(A, member(c(_, _, _, _, A), L), As0),
    sort(As0, As).

%% the first call whose answer the other run never gave, or the first call
flow_diff_rep(L, Other, C) :-
    (   member(C, L), C = c(_, _, _, _, A), \+ memberchk(A, Other) -> true
    ;   L = [C|_]
    ).

%% each predicate one run called and the other did not: only(P, N, S, Box,
%% Panel), in the order of their first calls
flow_diff_only(Cs, Others, Only) :-
    findall(P, member(c(_, _, _, _, P-_, _), Others), Ps0),
    sort(Ps0, Ps),
    findall(P, ( member(c(_, _, _, _, P-_, _), Cs), \+ memberchk(P, Ps) ), Qs0),
    msort(Qs0, Qs),
    flow_diff_counts(Qs, Ns),
    findall(only(P, N, S, Box, Pn),
            ( member(P-N, Ns),
              once(member(c(S, _, Box, Pn, P-_, _), Cs)) ),
            Only0),
    findall(Own-S-O, ( member(O, Only0), O = only(P, _, S, _, _), flow_diff_own(P, Own) ), SOs),
    keysort(SOs, SSOs),
    pairs_values(SSOs, Only).

flow_diff_counts([], []).
flow_diff_counts([P|Ps], [P-N|Ns]) :-
    flow_diff_run(Ps, P, 1, N, Rest),
    flow_diff_counts(Rest, Ns).

flow_diff_run([Q|Qs], P, N0, N, Rest) :-
    Q == P, !,
    N1 is N0 + 1,
    flow_diff_run(Qs, P, N1, N, Rest).
flow_diff_run(Qs, _, N, N, Qs).

%% ---- as text ---------------------------------------------------------------

flow_diff_text(diff(Both, Ds, OA, OB), PA, PB, Text) :-
    length(Ds, ND), length(OA, NA), length(OB, NB),
    format(atom(H), '% ~d inputs in both runs, ~d answered differently; ~d predicates only in a, ~d only in b',
           [Both, ND, NA, NB]),
    findall(L, ( member(D, Ds), flow_diff_text_differ(D, PA, PB, L) ), DLs),
    findall(L, ( member(O, OA), flow_diff_text_only(a, O, PA, L) ), ALs),
    findall(L, ( member(O, OB), flow_diff_text_only(b, O, PB, L) ), BLs),
    append([[H], DLs, ALs, BLs], Ls),
    atomic_list_concat(Ls, '\n', T0),
    atom_concat(T0, '\n', Text).

flow_diff_text_differ(differ(N/_, In, A, B), PA, PB, Text) :-
    A = c(_, DA, _, _, _), B = c(_, DB, _, _, _),
    D is max(DA, DB),
    flow_dbg_text_goal(N, In, GT),
    flow_diff_text_call(a, N, A, PA, LA),
    flow_diff_text_call(b, N, B, PB, LB),
    format(atom(Text), 'differs at depth ~w: ~w~n  ~w~n  ~w', [D, GT, LA, LB]).

flow_diff_text_call(R, N, c(S, _, Box, _, Ans), Places, Line) :-
    (   Ans = exit(Out) -> flow_dbg_text_goal(N, Out, OT), atom_concat('exit ', OT, AT)
    ;   AT = Ans
    ),
    flow_diff_where(Box, Places, W),
    format(atom(Line), '~w ~w at step ~w, ~w', [R, AT, S, W]).

flow_diff_text_only(R, only(P, N, S, _, Pn), Places, Line) :-
    (   N =:= 1 -> CT = '1 call' ; format(atom(CT), '~d calls', [N]) ),
    (   Pn \== none, Places \== none, atom_concat(Pn, '.c1', C1), get_assoc(C1, Places, W)
    ->  atom_concat('; defined ', W, DT)
    ;   DT = ''
    ),
    format(atom(Line), 'only in ~w: ~q, ~w, the first at step ~w~w', [R, P, CT, S, DT]).

%% a box, and where it is written when the places say
flow_diff_where(none, _, '-') :- !.
flow_diff_where(Box, Places, W) :-
    (   Places \== none, get_assoc(Box, Places, P) -> atomic_list_concat([Box, ' ', P], W)
    ;   W = Box
    ).
