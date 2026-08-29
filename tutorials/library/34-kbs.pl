%% Lesson 34 -- library(kbs): many knowledge bases from one script.
%%
%% Run it (needs a Zigurat server):
%%   COCOLOG_LIBRARY=library ./cocolog run tutorials/library/34-kbs.pl main
%%
%% Every kb_* goal is ONE PROCESS-PROOF over the wire -- that is the
%% library's definition, not a workaround: a store half exists to show
%% a SECOND process sees the rows. Goals are TERMS; term_to_atom does
%% the quoting a shell suite pays for by hand.

:- use_module(library(kbs)).

main :-
    (   kb_up(kbs_lesson)
    ->  kb_forget(kbs_lesson),
        kb_forget(kbs_lesson2),
        kb_run(kbs_lesson, assertz(city(akkad, 'New Founding'))),
        kb_run(kbs_lesson2, assertz(city(kish, old))),
        kb_answer(kbs_lesson, ( city(C, K), write(answer(C-K)), nl ), A1),
        must('base one answers its own rows', A1, 'answer(akkad-New Founding)'),
        kb_answer(kbs_lesson2, ( city(C, K), write(answer(C-K)), nl ), A2),
        must('base two answers different ones', A2, 'answer(kish-old)'),
        ( kb_run(kbs_lesson, city(kish, _)) -> X = leaked ; X = separate ),
        must('and the two bases share nothing', X, separate),
        kb_forget(kbs_lesson),
        kb_forget(kbs_lesson2),
        format("~nlesson 34: every claim held~n", [])
    ;   format("~nlesson 34: no Zigurat server -- the claims need one; skipped honestly~n", [])
    ),
    write(done), nl.

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
