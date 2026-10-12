%% library(flow/debug), part: where a run's inferences went -- each
%% predicate's calls and the inferences spent inside them, over the
%% recorded window.
%%
%%     flow_debug(Goal, Base, [profile(P)|Options], Run)
%%     flow_profile_text(+Profile, -Text)
%%
%% profile(P), an answer like places(P), binds P to
%%
%%     profile(From, To, Spent, Rows)
%%
%% the window, the inferences its calls spent (the union of their spans:
%% what a percentage is of), and a prof(Name/Arity, Inclusive, Calls,
%% Largest) for each predicate the window saw called, the most inclusive
%% first: its calls, the inferences spent inside them, and the most one
%% call spent.
%%
%% A CALL SPENDS THE INFERENCES FROM ITS CALL TO ITS FIRST EXIT OR FAIL.
%% Its last port is no end: after an Exit the run goes on in the call's
%% continuation, and a Redo that comes back to it later would charge it
%% with everything in between -- a profile taken that way adds to over 100
%% per cent. A call with neither (an exception ended it, or the window
%% closed on it) spends up to the last inference under it. The inferences a
%% Redo spends in a call after its first Exit are charged to the calls made
%% then, not to it. A predicate's inclusive count is over the union of its
%% calls' spans, so a recursion is not counted once a level: no predicate is
%% charged more than the window, and every call is one inference -- the
%% call itself, which is the whole of a predicate's own (self) cost.

flow_dbg_profile(Facts, profile(From, To, Spent, Rows)) :-
    Facts = dbg(Sum, SEs, Calls, _, _, _, _, _, _),
    arg(5, Sum, From),
    arg(6, Sum, To),
    empty_assoc(F0),
    flow_dbg_prof_firsts(SEs, F0, Firsts),
    flow_dbg_prof_ends(Calls, Firsts, Ends),
    findall(P-(S-E),
            ( member(call(S, P, _, _, _, _, _, _, _, _), Calls), get_assoc(S, Ends, E) ),
            PSE0),
    keysort(PSE0, PSE),
    pairs_values(PSE, All0),
    msort(All0, All),
    flow_dbg_prof_union(All, 0, -1, Spent),
    flow_dbg_prof_rows(PSE, Rows0),
    findall(NI-R, ( member(R, Rows0), R = prof(_, I, _, _), NI is -I ), KRs),
    keysort(KRs, SKRs),
    pairs_values(SKRs, Rows).

%% each call's first Exit or Fail
flow_dbg_prof_firsts([], F, F).
flow_dbg_prof_firsts([ev(I, Port, S, _, _, _)|Es], F0, F) :-
    (   ( Port == exit ; Port == fail ), \+ get_assoc(S, F0, _)
    ->  put_assoc(S, F0, I, F1)
    ;   F1 = F0
    ),
    flow_dbg_prof_firsts(Es, F1, F).

%% each call's end: its first Exit or Fail, or the last inference under it
%% -- the calls taken latest first, each lifting its parent's last
flow_dbg_prof_ends(Calls, Firsts, Ends) :-
    findall(S-Pa, member(call(S, _, _, Pa, _, _, _, _, _, _), Calls), SPs0),
    keysort(SPs0, SPs),
    reverse(SPs, Rev),
    empty_assoc(L0),
    flow_dbg_prof_lasts(Rev, L0, Lasts),
    findall(S-E,
            ( member(S-_, SPs),
              (   get_assoc(S, Firsts, E) -> true
              ;   get_assoc(S, Lasts, E) -> true
              ;   E = S
              ) ),
            SEs),
    list_to_assoc(SEs, Ends).

flow_dbg_prof_lasts([], L, L).
flow_dbg_prof_lasts([S-Pa|SPs], L0, L) :-
    (   get_assoc(S, L0, M0) -> M is max(S, M0) ; M = S ),
    put_assoc(S, L0, M, L1),
    (   Pa =\= 0
    ->  (   get_assoc(Pa, L1, PM0) -> PM is max(PM0, M) ; PM = M ),
        put_assoc(Pa, L1, PM, L2)
    ;   L2 = L1
    ),
    flow_dbg_prof_lasts(SPs, L2, L).

%% one row a predicate, from its calls' spans in the order made: a span
%% inside the one before it is inside the union already
flow_dbg_prof_rows([], []).
flow_dbg_prof_rows([P-SE|PSEs], [prof(P, Incl, N, Max)|Rows]) :-
    flow_dbg_prof_take(PSEs, P, Mine, Rest),
    Spans = [SE|Mine],
    length(Spans, N),
    findall(L, ( member(S-E, Spans), L is E - S + 1 ), Ls),
    max_list(Ls, Max),
    msort(Spans, Sorted),
    flow_dbg_prof_union(Sorted, 0, -1, Incl),
    flow_dbg_prof_rows(Rest, Rows).

flow_dbg_prof_take([Q-SE|PSEs], P, [SE|Mine], Rest) :-
    Q == P, !,
    flow_dbg_prof_take(PSEs, P, Mine, Rest).
flow_dbg_prof_take(PSEs, _, [], PSEs).

flow_dbg_prof_union([], Acc, _, Acc).
flow_dbg_prof_union([S-E|SEs], Acc0, Top, Incl) :-
    (   E =< Top
    ->  flow_dbg_prof_union(SEs, Acc0, Top, Incl)
    ;   Lo is max(S, Top + 1),
        Acc1 is Acc0 + E - Lo + 1,
        flow_dbg_prof_union(SEs, Acc1, E, Incl)
    ).

%% ---- as text ---------------------------------------------------------------

flow_profile_text(profile(From, To, W, Rows), Text) :-
    length(Rows, NP),
    format(atom(H), '% ~d inferences spent by the calls of the window ~w to ~w, ~d predicates -- a call spends from its Call to its first Exit or Fail',
           [W, From, To, NP]),
    T = '% inclusive       %    calls  largest  predicate',
    findall(L,
            ( member(prof(P, I, N, M), Rows),
              Pc is 100 * I / max(1, W),
              format(atom(PcA), '~1f', [Pc]),
              flow_dbg_prof_pad(I, 11, IA), flow_dbg_prof_pad(PcA, 8, PA),
              flow_dbg_prof_pad(N, 9, NA), flow_dbg_prof_pad(M, 9, MA),
              format(atom(L), '~w~w~w~w  ~q', [IA, PA, NA, MA, P]) ),
            Ls),
    atomic_list_concat([H, T|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% a value right-aligned in W columns
flow_dbg_prof_pad(V, W, A) :-
    format(atom(A0), '~w', [V]),
    atom_length(A0, L),
    N is max(0, W - L),
    length(Sp, N),
    maplist(=(0' ), Sp),
    atom_codes(Pad, Sp),
    atom_concat(Pad, A0, A).
