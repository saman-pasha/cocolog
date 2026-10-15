%% library(flow/debug), part: where a run's inferences went -- each
%% predicate's calls and the inferences spent inside them, over the
%% recorded window; the window's inferences by what took them; who made
%% the calls; the goals asked again; and where the window's time went.
%%
%%     flow_debug(Goal, Base, [profile(P)|Options], Run)
%%     flow_profile_text(+Profile, -Text)
%%     flow_steps_text(+Profile, -Text)
%%     flow_debug(Goal, Base, [callers(C)|Options], Run)
%%     flow_callers_text(+Callers, -Text)
%%     flow_debug(Goal, Base, [repeats(R)|Options], Run)
%%     flow_repeats_text(+Repeats, -Text)
%%     flow_debug(Goal, Base, [time(T)|Options], Run)
%%     flow_time_text(+Time, -Text)
%%     flow_debug(Goal, Base, [profile_rows(Rows)|Options], Run)
%%     flow_profile_merge(+RowLists, -Profile, -Callers, -Repeats)
%%     flow_profile_merge(+RowLists, -Profile, -Callers, -Repeats, -Time)
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
%%
%% flow_steps_text/2 writes the same profile as the window's inferences by
%% what took them (1.11.10, the reasoning session's point 7): each
%% predicate's calls, an inference each, and the steps of the control
%% constructs, which make no call -- `true/0' 4.1 %, `=/2' 4.2 % and the
%% constructs' share, where a run's time goes step by step.
%%
%% callers(C) binds C to callers(From, To, Rows), a callers(Name/Arity,
%% Calls, [Caller-N, ...]) for each predicate the window saw called, the
%% most called first, its callers the most calling first: the predicate of
%% the call each call was made in, `(the query)' for the query's own goal,
%% or `(outside the window)' for one whose caller began before the window
%% opened (1.11.10, the reasoning session's point 7: `tr_class_of/2' 648
%% calls, of them `tr_determiner/3' 234).
%%
%% repeats(R) binds R to repeats(From, To, Rows), a repeats(Name/Arity,
%% Calls, Distinct, [Goal-N, ...]) for each predicate whose window asked a
%% goal more than once, the most repeats (Calls - Distinct) first, its goals
%% asked more than once the most asked first -- Goal the text it was called
%% with, as BASE.txt writes it, so two goals whose values were cut at text(N)
%% alike are one (1.11.10: `tr_solve/1' 1 528 calls of 391 goals).
%%
%% profile_rows(Rows) binds Rows to the window as rows a file can hold a
%% term a line -- win(From, To, Spent), p(Pred, Inclusive, Calls, Largest),
%% c(Pred, Caller, N), and g(Pred, Goal, N) for EVERY goal, asked once or
%% more, so that windows add up -- and flow_profile_merge/4 sums such rows
%% from several windows into the three answers again, their From a
%% windows([From-To, ...]): what tools/flow/debug.pl's windows=N writes as
%% BASE.prof. With time(T) asked as well, the rows hold the window's time
%% (tw/5, tp/5), which flow_profile_merge/5 adds up into a fourth answer.
%%
%% time(T) (1.13.3) binds T to where the window's TIME went:
%%
%%     time(From, To, total(Ns, Reads, ClockNs, GcNs, Gcs), Rows)
%%
%% Ns the window's nanoseconds by the clock, Reads the inferences the clock
%% read, ClockNs its own cost at those readings (taken off Ns), GcNs and
%% Gcs the collections the window ran (in no inference's time), and a
%% t(Name/Arity, Calls, Inclusive, Self, Largest) for each predicate the
%% window saw called, the most inclusive first, in nanoseconds: the time
%% inside its calls (their spans' union, as the profile's inclusive
%% count), the time of its calls' own inferences, and the most one call
%% took.
%%
%% THE TIME IS THE PROBE'S, the run untraced, never the replay's: the
%% probe reads the monotonic clock at the top of every step of the window
%% ('$trace_window'/4's time(F, K), lib/builtins.cicili), and an
%% inference's time is from its reading to the next -- its goal's own
%% work: a predicate's head, and the guards its clause runs as it is
%% entered (whose inferences the clock does not see, and read 0); a
%% builtin's whole run, findall/3's less the inner goals' own. The replay,
%% numbered as the probe is, says whose each inference was. A READING
%% COSTS TIME TOO, some 35 ns on the four-vCPU box against an inference's
%% 15 to 60: what it costs where nothing else runs is measured as the
%% probe starts and taken off every inference read, so a cheap predicate's
%% time is an estimate within some 10 ns a call -- its inference count
%% (profile(P)) is the surer measure of it -- and what time says that a
%% count cannot is the one inference that costs a thousand: a sort, a
%% findall/3, a store's lookup, a file read.

flow_dbg_profile(Facts, profile(From, To, Spent, Rows)) :-
    Facts = dbg(Sum, SEs, Calls, _, _, _, _, _, _),
    arg(5, Sum, From),
    arg(6, Sum, To),
    flow_dbg_prof_spans(SEs, Calls, PSE0),
    keysort(PSE0, PSE),
    pairs_values(PSE, All0),
    msort(All0, All),
    flow_dbg_prof_union(All, 0, -1, Spent),
    flow_dbg_prof_rows(PSE, Rows0),
    findall(NI-R, ( member(R, Rows0), R = prof(_, I, _, _), NI is -I ), KRs),
    keysort(KRs, SKRs),
    pairs_values(SKRs, Rows).

%% EACH CALL'S SPAN, Pred-(S-End): to its first Exit or Fail, or, with
%% neither in the window, to the last inference under it -- the latest
%% call made below it. Sorted and walked down the call tree (1.11.10):
%% through 1.11.9 each first Exit and each call's last went into an AVL
%% tree, 6.3 s of a window of 100 000 inferences of the translator
flow_dbg_prof_spans(SEs, Calls, PSE) :-
    findall(S-I, ( member(ev(I, Port, S, _, _, _), SEs), ( Port == exit ; Port == fail ) ), SIs0),
    keysort(SIs0, SIs),
    flow_dbg_prof_firsts(SIs, Firsts),
    flow_dbg_prof_lasts(Calls, Lasts),
    flow_dbg_prof_zip(Calls, Firsts, Lasts, PSE).

%% the first of each call's Exits and Fails, sorted by call
flow_dbg_prof_firsts([], []).
flow_dbg_prof_firsts([S-I|SIs], [S-I|Fs]) :-
    flow_dbg_prof_skip(SIs, S, Rest),
    flow_dbg_prof_firsts(Rest, Fs).

flow_dbg_prof_skip([S1-_|SIs], S, Rest) :-
    S1 =:= S, !,
    flow_dbg_prof_skip(SIs, S, Rest).
flow_dbg_prof_skip(Rest, _, Rest).

%% each call's last: the latest call made in the tree under it, itself
%% when it made none -- S-Last, sorted by call
flow_dbg_prof_lasts(Calls, Lasts) :-
    findall(Pa-S, member(call(S, _, _, Pa, _, _, _, _, _, _), Calls), PSs0),
    keysort(PSs0, PSs),
    group_pairs_by_key(PSs, Groups),
    list_to_assoc(Groups, Kids),
    (   get_assoc(0, Kids, Roots) -> true ; Roots = [] ),
    flow_dbg_prof_trees(Roots, Kids, Ls0, []),
    keysort(Ls0, Lasts).

flow_dbg_prof_trees([], _, Ls, Ls).
flow_dbg_prof_trees([S|Ss], Kids, Ls0, Ls) :-
    flow_dbg_prof_tree(S, Kids, _, Ls0, Ls1),
    flow_dbg_prof_trees(Ss, Kids, Ls1, Ls).

flow_dbg_prof_tree(S, Kids, M, [S-M|Ls0], Ls) :-
    (   get_assoc(S, Kids, Cs) -> true ; Cs = [] ),
    flow_dbg_prof_kids(Cs, Kids, S, M, Ls0, Ls).

flow_dbg_prof_kids([], _, M, M, Ls, Ls).
flow_dbg_prof_kids([C|Cs], Kids, M0, M, Ls0, Ls) :-
    flow_dbg_prof_tree(C, Kids, MC, Ls0, Ls1),
    M1 is max(M0, MC),
    flow_dbg_prof_kids(Cs, Kids, M1, M, Ls1, Ls).

%% the calls, the firsts and the lasts, each sorted by call, as spans
flow_dbg_prof_zip([], _, _, []).
flow_dbg_prof_zip([call(S, P, _, _, _, _, _, _, _, _)|Cs], Fs0, Ls0, [P-(S-E)|PSE]) :-
    (   Ls0 = [S1-L|Ls1], S1 =:= S -> true ; L = S, Ls1 = Ls0 ),
    (   Fs0 = [S2-F|Fs1], S2 =:= S -> E = F ; E = L, Fs1 = Fs0 ),
    flow_dbg_prof_zip(Cs, Fs1, Ls1, PSE).

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

%% ---- who made the calls (1.11.10) ---------------------------------------------

flow_dbg_callers(Facts, callers(From, To, Rows)) :-
    Facts = dbg(Sum, _, Calls, _, _, _, _, _, _),
    arg(5, Sum, From),
    arg(6, Sum, To),
    flow_dbg_prof_by_call(Calls, ByS),
    %% the query's goal is the run's first call, at inference 1 (a depth is
    %% counted from where the window opened)
    findall(P-C,
            ( member(call(S, P, _, Pa, _, _, _, _, _, _), Calls),
              (   Pa =\= 0, get_assoc(Pa, ByS, CP) -> C = CP
              ;   S =:= 1 -> C = '(the query)'
              ;   C = '(outside the window)'
              ) ),
            PCs0),
    msort(PCs0, PCs),
    group_pairs_by_key(PCs, Groups),
    findall(NK-callers(P, N, Cs),
            ( member(P-Callers, Groups),
              length(Callers, N),
              clumped(Callers, CNs),
              flow_dbg_by_count(CNs, Cs),
              NK is -N ),
            KRs),
    keysort(KRs, SKRs),
    pairs_values(SKRs, Rows).

%% each call's predicate by the inference of its Call, which no two calls
%% share (the calls come in that order)
flow_dbg_prof_by_call(Calls, ByS) :-
    findall(S-P, member(call(S, P, _, _, _, _, _, _, _, _), Calls), SPs),
    list_to_assoc(SPs, ByS).

%% X-N pairs, the most first; a tie keeps its order
flow_dbg_by_count(XNs, Sorted) :-
    findall(NK-(X-N), ( member(X-N, XNs), NK is -N ), Ks),
    keysort(Ks, SKs),
    pairs_values(SKs, Sorted).

%% ---- the goals asked again (1.11.10) -----------------------------------------

flow_dbg_repeats(Facts, repeats(From, To, Rows)) :-
    Facts = dbg(Sum, _, Calls, _, _, _, _, _, _),
    arg(5, Sum, From),
    arg(6, Sum, To),
    flow_dbg_goal_counts(Calls, PGNs),
    flow_dbg_repeats_of(PGNs, Rows).

%% each predicate's goals and how often each was asked, P-[Goal-N, ...],
%% a goal the text it was called with, its variables named in the order
%% they come (flow_dbg_goal_canon/2)
flow_dbg_goal_counts(Calls, PGNs) :-
    findall(P-G,
            ( member(call(_, P, _, _, _, _, _, In, _, _), Calls),
              P = Name/_,
              flow_dbg_text_goal(Name, In, G0),
              flow_dbg_goal_canon(G0, G) ),
            PGs0),
    msort(PGs0, PGs),
    group_pairs_by_key(PGs, Groups),
    findall(P-GNs, ( member(P-Gs, Groups), clumped(Gs, GNs) ), PGNs).

%% A GOAL ASKED AGAIN WITH FRESH VARIABLES IS THE SAME GOAL: the window
%% writes a variable by its heap position, `_G180', and each call's are its
%% own, so a goal's variables are named in the order they come, `_1', `_2'
%% -- look(even,_G180) and look(even,_G521) are look(even,_1), and
%% f(_G3,_G3) stays apart from f(_G3,_G4). A `_G' and digits right after a
%% letter, a digit or `_' is part of a name, not a variable
flow_dbg_goal_canon(T0, T) :-
    (   atomic_list_concat([_, _|_], '_G', T0)
    ->  atom_codes(T0, Cs),
        flow_dbg_canon(Cs, 0' , [], Out),
        atom_codes(T, Out)
    ;   T = T0
    ).

flow_dbg_canon([], _, _, []).
flow_dbg_canon([0'_, 0'G, D|Cs], Prev, Map0, Out) :-
    D >= 0'0, D =< 0'9,
    \+ flow_dbg_name_code(Prev), !,
    flow_dbg_canon_digits([D|Cs], Ds, Rest),
    (   memberchk(Ds-K, Map0) -> Map1 = Map0
    ;   length(Map0, N), K is N + 1, Map1 = [Ds-K|Map0]
    ),
    number_codes(K, KCs),
    Out = [0'_|Out0],
    append(KCs, Out1, Out0),
    flow_dbg_canon(Rest, 0'0, Map1, Out1).
flow_dbg_canon([C|Cs], _, Map, [C|Out]) :-
    flow_dbg_canon(Cs, C, Map, Out).

flow_dbg_canon_digits([C|Cs], [C|Ds], Rest) :-
    C >= 0'0, C =< 0'9, !,
    flow_dbg_canon_digits(Cs, Ds, Rest).
flow_dbg_canon_digits(Rest, [], Rest).

flow_dbg_name_code(C) :-
    (   C >= 0'a, C =< 0'z -> true
    ;   C >= 0'A, C =< 0'Z -> true
    ;   C >= 0'0, C =< 0'9 -> true
    ;   C =:= 0'_
    ).

%% the predicates that asked a goal more than once, the most repeats first,
%% each with its goals asked more than once, the most asked first
flow_dbg_repeats_of(PGNs, Rows) :-
    findall(RK-repeats(P, N, D, Rep),
            ( member(P-GNs, PGNs),
              length(GNs, D),
              flow_dbg_prof_sum(GNs, 0, N),
              N > D,
              findall(G-K, ( member(G-K, GNs), K > 1 ), Many),
              flow_dbg_by_count(Many, Rep),
              RK is D - N ),
            KRs),
    keysort(KRs, SKRs),
    pairs_values(SKRs, Rows).

flow_dbg_prof_sum([], N, N).
flow_dbg_prof_sum([_-K|XKs], N0, N) :-
    N1 is N0 + K,
    flow_dbg_prof_sum(XKs, N1, N).

%% ---- where the window's time went (1.13.3) -------------------------------------

flow_dbg_time(Facts, Clock, time(From, To, total(Ns, Reads, ClockNs, GcNs, NGc), Rows)) :-
    Facts = dbg(Sum, SEs, Calls, _, _, _, _, _, _),
    arg(5, Sum, From),
    arg(6, Sum, To),
    flow_dbg_time_clock(Clock, From, To, PD, PR, Per, Gcs),
    flow_dbg_time_raw(From, To, From, To, PD, PR, Raw, Reads),
    flow_dbg_time_off(Raw, Reads, Per, Ns),
    ClockNs is round(Per * Reads),
    findall(G, ( member(I-G, Gcs), I >= From, I =< To ), GNs),
    length(GNs, NGc),
    sum_list(GNs, GcNs),
    flow_dbg_prof_spans(SEs, Calls, PSE0),
    keysort(PSE0, PSE),
    flow_dbg_time_rows(PSE, From, To, PD, PR, Per, Rows0),
    findall(NI-R, ( member(R, Rows0), R = t(_, _, I, _, _), NI is -I ), KRs),
    keysort(KRs, SKRs),
    pairs_values(SKRs, Rows).

%% THE WINDOW'S INFERENCES AS TWO RUNNING SUMS, each a term to read in one
%% step (arg/3): PD's K-th argument the nanoseconds of the window's first
%% K - 1 inferences, PR's how many of them the clock read -- an inference
%% it did not read has 0 nanoseconds (one a clause's guards took, or one
%% outside the probe's timed span). Per a reading's own cost; Gcs I-Ns
flow_dbg_time_clock(none, From, To, PD, PR, 0.0, []) :- !,
    N is max(0, To - From + 1),
    length(Zs, N),
    maplist(=(0), Zs),
    flow_dbg_time_sums(Zs, PD, PR).
flow_dbg_time_clock(clock(First, Last, Per, Ds, Gcs), From, To, PD, PR, Per, Gcs) :-
    N is max(0, To - From + 1),
    (   From >= First
    ->  Skip is From - First,
        ( length(Pre, Skip), append(Pre, Ds1, Ds) -> true ; Ds1 = [] ),
        Ds2 = Ds1
    ;   Z is min(N, First - From),
        length(Zs, Z), maplist(=(0), Zs),
        append(Zs, Ds, Ds2)
    ),
    Have is max(0, min(N, Last - From + 1)),
    flow_dbg_prof_first(Ds2, Have, Ds3),
    length(Ds3, L3),
    Pad is N - L3,
    length(Ps, Pad), maplist(=(0), Ps),
    append(Ds3, Ps, Ds4),
    flow_dbg_time_sums(Ds4, PD, PR).

flow_dbg_time_sums(Ds, PD, PR) :-
    flow_dbg_time_sums(Ds, 0, 0, SDs, SRs),
    PD =.. [d, 0|SDs],
    PR =.. [r, 0|SRs].

flow_dbg_time_sums([], _, _, [], []).
flow_dbg_time_sums([D|Ds], A0, R0, [A|As], [R|Rs]) :-
    A is A0 + D,
    ( D > 0 -> R is R0 + 1 ; R = R0 ),
    flow_dbg_time_sums(Ds, A, R, As, Rs).

%% the nanoseconds of inferences S to E and how many the clock read,
%% within the window F to T
flow_dbg_time_raw(S0, E0, F, T, PD, PR, Raw, Reads) :-
    S is max(S0, F),
    E is min(E0, T),
    (   S =< E
    ->  A is S - F + 1, B is E - F + 2,
        arg(A, PD, DA), arg(B, PD, DB), Raw is DB - DA,
        arg(A, PR, RA), arg(B, PR, RB), Reads is RB - RA
    ;   Raw = 0, Reads = 0
    ).

%% RAW nanoseconds over READS readings, their cost taken off: never below 0
flow_dbg_time_off(Raw, Reads, Per, Ns) :-
    Ns is max(0, round(Raw - Per * Reads)).

%% one row a predicate, as the profile's: its calls' spans in the order
%% made, their union's time, their own inferences' and the largest span's
flow_dbg_time_rows([], _, _, _, _, _, []).
flow_dbg_time_rows([P-SE|PSEs], F, T, PD, PR, Per, [t(P, N, Incl, Self, Max)|Rows]) :-
    flow_dbg_prof_take(PSEs, P, Mine, Rest),
    Spans = [SE|Mine],
    length(Spans, N),
    findall(L, ( member(S-E, Spans),
                 flow_dbg_time_raw(S, E, F, T, PD, PR, R1, K1),
                 flow_dbg_time_off(R1, K1, Per, L) ),
            Ls),
    max_list(Ls, Max),
    flow_dbg_time_self(Spans, F, T, PD, PR, 0, 0, SRaw, SReads),
    flow_dbg_time_off(SRaw, SReads, Per, Self),
    msort(Spans, Sorted),
    flow_dbg_time_union(Sorted, -1, F, T, PD, PR, 0, 0, URaw, UReads),
    flow_dbg_time_off(URaw, UReads, Per, Incl),
    flow_dbg_time_rows(Rest, F, T, PD, PR, Per, Rows).

flow_dbg_time_self([], _, _, _, _, R, K, R, K).
flow_dbg_time_self([S-_|SEs], F, T, PD, PR, R0, K0, R, K) :-
    flow_dbg_time_raw(S, S, F, T, PD, PR, R1, K1),
    R2 is R0 + R1,
    K2 is K0 + K1,
    flow_dbg_time_self(SEs, F, T, PD, PR, R2, K2, R, K).

%% the union of spans sorted by where they begin, as the profile takes it
%% (flow_dbg_prof_union/4): a span inside the one before adds nothing
flow_dbg_time_union([], _, _, _, _, _, R, K, R, K).
flow_dbg_time_union([S-E|SEs], Top, F, T, PD, PR, R0, K0, R, K) :-
    (   E =< Top
    ->  flow_dbg_time_union(SEs, Top, F, T, PD, PR, R0, K0, R, K)
    ;   Lo is max(S, Top + 1),
        flow_dbg_time_raw(Lo, E, F, T, PD, PR, R1, K1),
        R2 is R0 + R1,
        K2 is K0 + K1,
        flow_dbg_time_union(SEs, E, F, T, PD, PR, R2, K2, R, K)
    ).

%% ---- a window as rows, and windows merged (1.11.10) ----------------------------

flow_dbg_profile_rows(Facts, Clock, Rows) :-
    flow_dbg_profile(Facts, profile(F, T, S, PRows)),
    flow_dbg_callers(Facts, callers(_, _, CRows)),
    Facts = dbg(_, _, Calls, _, _, _, _, _, _),
    flow_dbg_goal_counts(Calls, PGNs),
    findall(p(P, I, N, M), member(prof(P, I, N, M), PRows), Ps),
    findall(c(P, C, K), ( member(callers(P, _, Cs), CRows), member(C-K, Cs) ), Cs1),
    findall(g(P, G, K), ( member(P-GNs, PGNs), member(G-K, GNs) ), Gs),
    %% the window's time, with time(T) asked (1.13.3)
    (   Clock == none
    ->  Ts = []
    ;   flow_dbg_time(Facts, Clock, time(_, _, total(TN, TR, TC, TG, TK), TRows)),
        findall(tp(P, N, I, Se, M), member(t(P, N, I, Se, M), TRows), TPs),
        Ts = [tw(TN, TR, TC, TG, TK)|TPs]
    ),
    append([[win(F, T, S)], Ps, Cs1, Gs, Ts], Rows).

%% THE WINDOWS ADD UP: a predicate's inclusive inferences and calls are
%% summed and its largest call is the largest of any window's -- the
%% windows are apart, so no span is counted twice -- and the callers and
%% the goals are counted over all of them, so a goal asked once in each of
%% two windows is a repeat
flow_profile_merge(RowLists,
                   profile(windows(Ws), none, Spent, PRows),
                   callers(windows(Ws), none, CRows),
                   repeats(windows(Ws), none, RRows)) :-
    append(RowLists, All),
    findall(F-T, member(win(F, T, _), All), Ws),
    findall(S, member(win(_, _, S), All), Ss),
    sum_list(Ss, Spent),
    findall(P-(I-N-M), member(p(P, I, N, M), All), PIs0),
    keysort(PIs0, PIs),
    group_pairs_by_key(PIs, PGroups),
    findall(NI-prof(P, I, N, M),
            ( member(P-Vs, PGroups),
              flow_dbg_prof_merge3(Vs, 0, 0, 0, I, N, M),
              NI is -I ),
            KPs),
    keysort(KPs, SKPs),
    pairs_values(SKPs, PRows),
    findall(P-(C-K), member(c(P, C, K), All), PCKs0),
    msort(PCKs0, PCKs),
    group_pairs_by_key(PCKs, CGroups),
    findall(NK-callers(P, N, Cs),
            ( member(P-CKs, CGroups),
              flow_dbg_prof_add(CKs, Merged),
              flow_dbg_prof_sum(Merged, 0, N),
              flow_dbg_by_count(Merged, Cs),
              NK is -N ),
            KCs),
    keysort(KCs, SKCs),
    pairs_values(SKCs, CRows),
    findall(P-(G-K), member(g(P, G, K), All), PGKs0),
    msort(PGKs0, PGKs),
    group_pairs_by_key(PGKs, GGroups),
    findall(P-GNs, ( member(P-GKs, GGroups), flow_dbg_prof_add(GKs, GNs) ), PGNs),
    flow_dbg_repeats_of(PGNs, RRows).

%% ... AND THEIR TIME (1.13.3): each window's total and each predicate's
%% calls, inclusive and own time summed, its largest call the largest of
%% any window's; none with no window timed
flow_profile_merge(RowLists, P, C, R,
                   time(windows(Ws), none, total(Ns, Rd, Ck, Gc, NG), TRows)) :-
    flow_profile_merge(RowLists, P, C, R),
    P = profile(windows(Ws), _, _, _),
    append(RowLists, All),
    findall(t(A, B, X, Y, Z), member(tw(A, B, X, Y, Z), All), TWs),
    flow_dbg_time_add(TWs, t(0, 0, 0, 0, 0), t(Ns, Rd, Ck, Gc, NG)),
    findall(Pr-t(N1, I1, S1, M1), member(tp(Pr, N1, I1, S1, M1), All), PTs0),
    keysort(PTs0, PTs),
    group_pairs_by_key(PTs, Groups),
    findall(NI-t(Pr, N, I, S, M),
            ( member(Pr-Ts, Groups),
              flow_dbg_time_merge(Ts, 0, 0, 0, 0, N, I, S, M),
              NI is -I ),
            KTs),
    keysort(KTs, SKTs),
    pairs_values(SKTs, TRows).

flow_dbg_time_add([], T, T).
flow_dbg_time_add([t(A, B, C, D, E)|Ts], t(A0, B0, C0, D0, E0), T) :-
    A1 is A0 + A, B1 is B0 + B, C1 is C0 + C, D1 is D0 + D, E1 is E0 + E,
    flow_dbg_time_add(Ts, t(A1, B1, C1, D1, E1), T).

flow_dbg_time_merge([], N, I, S, M, N, I, S, M).
flow_dbg_time_merge([t(N1, I1, S1, M1)|Ts], N0, I0, S0, M0, N, I, S, M) :-
    N2 is N0 + N1, I2 is I0 + I1, S2 is S0 + S1, M2 is max(M0, M1),
    flow_dbg_time_merge(Ts, N2, I2, S2, M2, N, I, S, M).

flow_dbg_prof_merge3([], I, N, M, I, N, M).
flow_dbg_prof_merge3([I1-N1-M1|Vs], I0, N0, M0, I, N, M) :-
    I2 is I0 + I1,
    N2 is N0 + N1,
    M2 is max(M0, M1),
    flow_dbg_prof_merge3(Vs, I2, N2, M2, I, N, M).

%% X-K pairs sorted by X, the counts of equal Xs added
flow_dbg_prof_add([], []).
flow_dbg_prof_add([X-K|XKs], [X-N|Rest]) :-
    flow_dbg_prof_add_same(XKs, X, K, N, After),
    flow_dbg_prof_add(After, Rest).

flow_dbg_prof_add_same([Y-K1|XKs], X, K0, N, After) :-
    Y == X, !,
    K is K0 + K1,
    flow_dbg_prof_add_same(XKs, X, K, N, After).
flow_dbg_prof_add_same(XKs, _, N, N, XKs).

%% ---- as text ---------------------------------------------------------------

%% what a profile is of: the window, or the windows merged
flow_dbg_prof_span(windows(Ws), _, Span) :- !,
    length(Ws, N),
    findall(W, ( member(F-T, Ws), format(atom(W), '~w to ~w', [F, T]) ), WTs),
    atomic_list_concat(WTs, ', ', WA),
    format(atom(Span), 'the ~d windows ~w', [N, WA]).
flow_dbg_prof_span(F, T, Span) :-
    format(atom(Span), 'the window ~w to ~w', [F, T]).

flow_profile_text(profile(From, To, W, Rows), Text) :-
    length(Rows, NP),
    flow_dbg_prof_span(From, To, Span),
    format(atom(H), '% ~d inferences spent by the calls of ~w, ~d predicates -- a call spends from its Call to its first Exit or Fail',
           [W, Span, NP]),
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

%% THE WINDOW'S INFERENCES BY WHAT TOOK THEM (1.11.10, the reasoning
%% session's point 7c): every inference is a step, and a step is either a
%% call -- one inference, the whole of a predicate's own (self) cost -- or
%% a control construct's, which has no port and is no call: an if-then-
%% else, a cut, catch/3 and its exit, \+, call/N. So each predicate's
%% calls are its share, the most first, and what no call took is the
%% constructs'. From the profile alone: its rows' calls, and the window's
%% length (each window's, the windows merged)
flow_steps_text(profile(From, To, _, Rows), Text) :-
    flow_dbg_prof_window_len(From, To, W),
    flow_dbg_prof_span(From, To, Span),
    findall(N, member(prof(_, _, N, _), Rows), Ns),
    sum_list(Ns, NC),
    length(Rows, NP),
    K is max(0, W - NC),
    flow_dbg_prof_count(NC, call, NCText),
    flow_dbg_prof_count(NP, predicate, NPText),
    format(atom(H), '% the ~d inferences of ~w by what took them: ~w of ~w, an inference each, and ~d by control constructs, which make no call (an if-then-else, a cut, catch/3 and its exit, \\+, call/N)',
           [W, Span, NCText, NPText, K]),
    T = '%    steps       %  predicate',
    findall(NK-(N-P), ( member(prof(P, _, N, _), Rows), NK is -N ), Ks0),
    KK is -K,
    append(Ks0, [KK-(K-'(control constructs)')], Ks1),
    keysort(Ks1, Ks),
    findall(L,
            ( member(_-(N-P), Ks),
              Pc is 100 * N / max(1, W),
              format(atom(PcA), '~1f', [Pc]),
              flow_dbg_prof_pad(N, 9, NA), flow_dbg_prof_pad(PcA, 8, PA),
              (   P = _/_ -> format(atom(L), '~w~w  ~q', [NA, PA, P])
              ;   format(atom(L), '~w~w  ~w', [NA, PA, P])
              ) ),
            Ls),
    atomic_list_concat([H, T|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% `1 call', `2 calls'
flow_dbg_prof_count(N, Word, Text) :-
    (   N =:= 1 -> format(atom(Text), '1 ~w', [Word])
    ;   format(atom(Text), '~d ~ws', [N, Word])
    ).

%% the inferences a profile is of: its window's, or its windows'
flow_dbg_prof_window_len(windows(Ws), _, W) :- !,
    findall(L, ( member(F-T, Ws), L is max(0, T - F + 1) ), Ls),
    sum_list(Ls, W).
flow_dbg_prof_window_len(F, T, W) :-
    W is max(0, T - F + 1).

%% each predicate's calls, then each of its callers with the calls it made,
%% indented under it
flow_callers_text(callers(From, To, Rows), Text) :-
    length(Rows, NP),
    flow_dbg_prof_span(From, To, Span),
    flow_dbg_prof_count(NP, predicate, NPText),
    format(atom(H), '% the callers of the ~w ~w called, the most called first: its calls, then each predicate that called it and how many of them it made -- (the query) for the query''s own goal, (outside the window) where the call it was made in began before the window opened',
           [NPText, Span]),
    T = '%    calls  predicate / caller',
    findall(L,
            ( member(callers(P, N, Cs), Rows),
              (   flow_dbg_prof_pad(N, 9, NA),
                  format(atom(L), '~w  ~q', [NA, P])
              ;   member(C-K, Cs),
                  flow_dbg_prof_pad(K, 9, KA),
                  (   C = _/_ -> format(atom(CT), '~q', [C]) ; CT = C ),
                  format(atom(L), '~w    ~w', [KA, CT])
              ) ),
            Ls),
    atomic_list_concat([H, T|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% each predicate that asked a goal again: its calls, the distinct goals
%% among them, the repeats and their share of its calls; then its goals
%% asked more than once, the ten most asked, and how many more there are
flow_repeats_text(repeats(From, To, Rows), Text) :-
    length(Rows, NP),
    flow_dbg_prof_span(From, To, Span),
    format(atom(H), '% the goals ~w asked more than once, by predicate (~d), the most repeats first: its calls, the distinct goals among them, the repeats and their share of the calls, then its goals asked more than once and how often, written as BASE.txt writes a call',
           [Span, NP]),
    T = '%    calls  distinct   repeats       %  predicate / goal',
    findall(L,
            ( member(repeats(P, N, D, Gs), Rows),
              (   R is N - D,
                  Pc is 100 * R / max(1, N),
                  format(atom(PcA), '~1f', [Pc]),
                  flow_dbg_prof_pad(N, 9, NA), flow_dbg_prof_pad(D, 10, DA),
                  flow_dbg_prof_pad(R, 10, RA), flow_dbg_prof_pad(PcA, 8, PA),
                  format(atom(L), '~w~w~w~w  ~q', [NA, DA, RA, PA, P])
              ;   flow_dbg_prof_first(Gs, 10, G10),
                  member(G-K, G10),
                  flow_dbg_prof_pad(K, 9, KA),
                  format(atom(L), '~w    ~w', [KA, G])
              ;   length(Gs, NG),
                  NG > 10,
                  More is NG - 10,
                  format(atom(L), '         ... and ~d more goals asked more than once', [More])
              ) ),
            Ls),
    atomic_list_concat([H, T|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% WHERE THE WINDOW'S TIME WENT (1.13.3): each predicate's inclusive and
%% self time, the most inclusive first, and the control constructs' -- the
%% time no call's own inference took -- in microseconds, each with its
%% share of the window's; the header says what the clock read and cost,
%% and what the collections took beside
flow_time_text(time(From, To, total(Ns, Reads, ClockNs, GcNs, NGc), Rows), Text) :-
    flow_dbg_prof_window_len(From, To, W),
    flow_dbg_prof_span(From, To, Span),
    flow_dbg_time_us(Ns, NsA),
    flow_dbg_time_us(ClockNs, CkA),
    (   Reads > 0 -> Per is ClockNs / Reads ; Per = 0.0 ),
    flow_dbg_time_us(GcNs, GcA),
    flow_dbg_prof_count(NGc, collection, GcT),
    format(atom(H1), '% the ~d inferences of ~w took ~w us as the probe ran them untraced, read from the clock at ~d of them less its own ~w us there (~1f ns a reading, measured as the probe began); ~w took ~w us more, in no inference',
           [W, Span, NsA, Reads, CkA, Per, GcT, GcA]),
    H2 = '% a call takes from its Call to its first Exit or Fail, as the profile counts it; its self time is its Call''s own inference -- a predicate''s head and the guards its clause runs as it is entered, a builtin''s whole run -- and what no call''s own inference took is the control constructs''',
    T = '% inclusive us       %     self us       %    calls  largest us  predicate',
    findall(S, member(t(_, _, _, S, _), Rows), Ss),
    sum_list(Ss, SAll),
    K is max(0, Ns - SAll),
    findall(L,
            ( member(t(P, N, I, S, M), Rows),
              flow_dbg_time_us(I, IA), flow_dbg_time_us(S, SA), flow_dbg_time_us(M, MA),
              flow_dbg_time_pc(I, Ns, IP), flow_dbg_time_pc(S, Ns, SP),
              flow_dbg_prof_pad(IA, 12, IAp), flow_dbg_prof_pad(IP, 8, IPp),
              flow_dbg_prof_pad(SA, 12, SAp), flow_dbg_prof_pad(SP, 8, SPp),
              flow_dbg_prof_pad(N, 9, NA), flow_dbg_prof_pad(MA, 12, MAp),
              format(atom(L), '~w~w~w~w~w~w  ~q', [IAp, IPp, SAp, SPp, NA, MAp, P]) ),
            Ls0),
    flow_dbg_time_us(K, KA), flow_dbg_time_pc(K, Ns, KP),
    flow_dbg_prof_pad('', 12, B12), flow_dbg_prof_pad('', 8, B8), flow_dbg_prof_pad('', 9, B9),
    flow_dbg_prof_pad(KA, 12, KAp), flow_dbg_prof_pad(KP, 8, KPp),
    format(atom(LK), '~w~w~w~w~w~w  (control constructs)', [B12, B8, KAp, KPp, B9, B12]),
    append(Ls0, [LK], Ls),
    atomic_list_concat([H1, H2, T|Ls], '\n', T0),
    atom_concat(T0, '\n', Text).

%% nanoseconds as microseconds, one place; a share of the window's, one place
flow_dbg_time_us(Ns, A) :-
    Us is Ns / 1000,
    format(atom(A), '~1f', [Us]).

flow_dbg_time_pc(X, Of, A) :-
    Pc is 100 * X / max(1, Of),
    format(atom(A), '~1f', [Pc]).

%% the first N of a list, or all of it
flow_dbg_prof_first(Xs, N, First) :-
    (   length(First, N), append(First, _, Xs) -> true ; First = Xs ).

%% a value right-aligned in W columns
flow_dbg_prof_pad(V, W, A) :-
    format(atom(A0), '~w', [V]),
    atom_length(A0, L),
    N is max(0, W - L),
    length(Sp, N),
    maplist(=(0' ), Sp),
    atom_codes(Pad, Sp),
    atom_concat(Pad, A0, A).
