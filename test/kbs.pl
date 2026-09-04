%% library/kbs.pl -- many knowledge bases from one script.
%%
%% WHAT IS BEING PINNED:
%%
%%   TWO BASES, ONE STORY. A script seeds kbs_case_a and kbs_case_b and
%%   reads DIFFERENT answers back from each -- the claim the .sh suites
%%   made by spawning cocolog per touch, now one clause per touch.
%%
%%   GOALS ARE TERMS. enroll-style goals carry quoted atoms
%%   ('Two Words') through term_to_atom untouched -- the quote-doubling
%%   that eats shell suites is gone, and the pin proves the atom came
%%   back whole.
%%
%%   EVERY TOUCH IS STILL A PROCESS-PROOF. kb_run spawns; that is the
%%   point, not a workaround -- a store half exists to show a second
%%   process sees the rows. The across-processes claim is the library's
%%   own definition.
%%
%%     cocolog -s test/kbs.pl        from the checkout root
%%
%% ONE PROCESS FOR THE CASE ITSELF, where test/kbs.sh wrapped each of its
%% four checks in a cocolog of its own around the library's children.
%% SKIPs without a Zigurat server.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(kbs)), _, fail)
    ->  true
    ;   skip('(library(kbs) will not load -- it rides process.so and text.so)')
    ),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --host ', Host, ' --tcp ', Port, ' --timeout 10 --kb kbs_case_a list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  true
    ;   sh_join(['(no Zigurat server at ', Host, ':', Port, ')'], Why), skip(Why)
    ),
    two_bases,
    checks_done.

two_bases :-
    section('two bases, one story'),
    written(( kb_forget(kbs_case_a), kb_forget(kbs_case_b),
              kb_run(kbs_case_a, assertz(color(red))), kb_run(kbs_case_a, assertz(color(green))),
              kb_run(kbs_case_b, assertz(color(blue))),
              kb_answer(kbs_case_a, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), A1),
              kb_answer(kbs_case_b, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), B1) ), A1-B1, G1),
    check('seed two bases, read two different answers', G1, 'answer([red,green])-answer([blue])'),
    written(( kb_run(kbs_case_a, assertz(unit(w, 'Two Words'))),
              kb_answer(kbs_case_a, ( unit(w, N), write(answer(N)), nl ), A2) ), A2, G2),
    check('a term goal carries its quoted atom whole', G2, 'answer(Two Words)'),
    written(( ( kb_run(kbs_case_a, no_such_thing_here(1)) -> R3 = proved ; R3 = refused ),
              kb_answer(kbs_case_a, ( findall(X, color(X), Xs), write(answer(Xs)), nl ), A3) ), R3-A3, G3),
    check('a failing goal is a failing kb_run, and the base stands', G3, 'refused-answer([red,green])'),
    written(( kb_fresh(kbs_case_a, []), ( kb_run(kbs_case_a, color(_)) -> R4 = still ; R4 = empty ),
              kb_forget(kbs_case_b) ), R4, G4),
    check('kb_fresh empties and reloads in one word', G4, empty).
