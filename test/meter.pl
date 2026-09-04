%% `call_metered/4' -- a goal under a ceiling, and WHAT IT COST.
%%
%% The engine has counted inferences since the day it was written: the
%% machine runner prints "finished after N inference(s)", and
%% `coco_engine_call_limited' fills in a `used' it keeps for its own
%% accounting. Both of those are outside the proof -- one is C, the other a
%% line on a terminal -- so nothing a PROGRAM ran could read the number.
%% `call_metered/4' hands it to Prolog, and this case is what it promises.
%%
%% WHAT IS BEING CHECKED, and why each part is here:
%%
%%   IT IS A MEASUREMENT, NOT AN ECHO. A tiny goal under a huge ceiling
%%   costs a tiny number, and ten times the work costs strictly more than
%%   the work. A meter that answered the limit back, or a constant, would
%%   pass a check that only asked whether it answered.
%%
%%   IT ANSWERS FOR A GOAL THAT FAILED, which is the whole reason it is not
%%   `call_limited/3'. Searching for a proof that is not there is real work
%%   -- it is precisely the work somebody would like to be free -- and a
%%   meter that goes silent on failure cannot charge for it.
%%
%%   THE COUNT IS DETERMINISTIC ACROSS PROCESSES. Two invocations that
%%   share nothing but the goal report the same number. That is the
%%   property that makes a count usable as a PRICE: two parties who never
%%   met can compute the same fee and check each other's arithmetic.
%%
%%   AND EVERY LAW `call_limited/3' HAS, this one has too, because it is the
%%   same engine call underneath: the ceiling narrows to what an outer
%%   budget has left, a limit below 1 is a domain error rather than
%%   "unlimited", bindings survive only a success, and an exception inside
%%   is an exception outside -- with the composition that makes a throwing
%%   goal chargeable (a `catch/3' INSIDE the meter) checked beside it.
%%
%%     cocolog -s test/meter.pl        from the checkout root
%%
%% ONE PROCESS FOR FOURTEEN CHECKS, where test/meter.sh spawned one per
%% check. Two children remain because they ARE the claim -- two processes
%% that share nothing but the goal -- and one because `step' is the only
%% thing that sets an outer budget, and `--embed' on a scratch directory is
%% the one without a server.

:- use_module('test/prelude.pl').

main :-
    outcomes, measurement, deterministic, laws, throwing, outer_budget,
    checks_done.

outcomes :-
    section('the three outcomes, each with its count'),
    written(( call_metered(append(_, [c], [a,b,c]), 10000, U1, R1),
              ( integer(U1), U1 > 0 -> W1 = R1-counted ; W1 = R1-U1 ) ), W1, G1),
    check('a goal that succeeds says so, and what it spent', G1, 'true-counted'),
    %% THE DIFFERENCE FROM call_limited/3, and the reason for the second
    %% predicate: /3 fails when the goal fails, which is the right shape for
    %% `once/1' and the wrong one for a meter. A failed search is work.
    written(( ( call_metered((between(1, 200, _), fail), 100000, U2, R2)
              -> ( integer(U2), U2 > 100 -> W2 = R2-counted ; W2 = R2-U2 )
              ;  W2 = 'THE METER FAILED WITH THE GOAL' ) ), W2, G2),
    check('a goal that FAILS still answers, and still has a bill', G2, 'failed-counted'),
    written(( call_metered((between(1, 100000000, _), fail), 5000, U3, R3),
              ( U3 >= 5000, U3 =< 5100 -> W3 = R3-at_the_ceiling ; W3 = R3-U3 ) ), W3, G3),
    check('and a runaway is stopped, at its ceiling', G3, 'inference_limit_exceeded-at_the_ceiling').

measurement :-
    section('it is a MEASUREMENT, not the argument read back'),
    %% A meter that answered its own Limit, or any constant, would pass
    %% everything above. These two are what make it a number about the goal.
    written(( call_metered(true, 1000000, U1, _), ( U1 < 100 -> W1 = small ; W1 = U1 ) ), W1, G1),
    check('a small goal under a huge ceiling costs a small number', G1, small),
    written(( call_metered((between(1, 100, _), fail), 100000, A2, _),
              call_metered((between(1, 1000, _), fail), 100000, B2, _),
              ( B2 > A2 -> W2 = more ; W2 = A2-B2 ) ), W2, G2),
    check('ten times the work costs strictly more', G2, more).

deterministic :-
    section('the count is deterministic, which is what makes it a PRICE'),
    %% Two processes that share nothing but the goal. This is the property a
    %% fee schedule stands on: whoever charges and whoever checks must arrive
    %% at the same number without talking to each other.
    Goal = 'query "call_metered((between(1, 500, N), N > 499), 100000, U, _), write(answer(U)), nl"',
    cocolog_answer(Goal, A1), cocolog_answer(Goal, B1),
    ( A1 = answer(N1), integer(N1), A1 == B1 -> W1 = agreed ; W1 = A1-B1 ),
    check('two processes report the same number for the same goal', W1, agreed),
    written(( call_metered((between(1, 500, N2a), N2a > 499), 100000, U2a, _),
              call_metered((between(1, 500, N2b), N2b > 499), 100000, U2b, _),
              ( U2a =:= U2b -> W2 = stable ; W2 = U2a-U2b ) ), W2, G2),
    check('and it is the same number again in-process', G2, stable).

laws :-
    section('the laws it shares with call_limited/3'),
    written(call_metered(append(X1, [c], [a,b,c]), 10000, _, _), X1, G1),
    check('bindings survive a success', G1, '[a,b]'),
    written(( call_metered((X2 = bound, between(1, 100000000, _), fail), 5000, _, _),
              ( var(X2) -> W2 = unbound ; W2 = X2 ) ), W2, G2),
    check('and the ceiling leaves none behind', G2, unbound),
    written(catch(call_metered(true, 0, _, _), error(E3, _),
                  ( E3 = domain_error(positive_integer, _) -> W3 = refused ; W3 = other )), W3, G3),
    check('a ceiling of zero is refused, not read as unlimited', G3, refused),
    written(catch(call_metered(true, plenty, _, _), error(E4, _),
                  ( E4 = type_error(integer, _) -> W4 = type_error ; W4 = other )), W4, G4),
    check('a non-integer ceiling is a type error', G4, type_error).

throwing :-
    section('a goal that throws, and how a caller charges for one anyway'),
    %% The count is lost with the frame that carried it, which is honest: the
    %% ball is re-thrown exactly as `call_limited/3' re-throws it.
    written(catch(call_metered((X1 is 1/0, write(X1)), 10000, _, _), error(E1, _),
                  ( E1 = evaluation_error(zero_divisor) -> W1 = reraised ; W1 = other )), W1, G1),
    check('an exception inside is an exception outside', G1, reraised),
    %% ...and this is the composition a caller that must bill everything uses:
    %% its own catch INSIDE the meter turns the throw into an outcome, which
    %% is counted like any other. Which exceptions are failures is the
    %% caller's policy, and a meter that decided would decide for everybody.
    written(( call_metered(catch((X2 is 1/0, write(X2)), _, true), 10000, U2, R2),
              ( integer(U2), U2 > 0 -> W2 = R2-counted ; W2 = R2-U2 ) ), W2, G2),
    check('a catch INSIDE the meter makes a throwing goal chargeable', G2, 'true-counted').

outer_budget :-
    section('the outer budget narrows the meter too'),
    %% A metered goal inside a metered turn cannot buy its way out of the
    %% turn's budget: the ceiling is the LOWER of the two, and the count comes
    %% back accordingly. `step' is the only thing that sets an outer budget,
    %% and `--embed' is one without a server.
    scratch(D),
    atom_concat(D, '/meterkb', KB),
    make_directory(KB),
    cocolog(C),
    sh_join(['timeout 60 ', C, ' --embed ', KB, ' start metered "call_metered((between(1,100000000,_), fail), 100000000, U, R), write(answer(R-U)), nl" >/dev/null 2>&1'], Start),
    (   sh_exit(Start, 0)
    ->  sh_join(['timeout 120 ', C, ' --embed ', KB, ' --steps 3000 step metered 2>&1'], Step),
        proc_run(Step, 120000, Out, _),
        (   re_first_atom('suspended at [0-9]+', Out, At)
        ->  ( re_match('suspended at 3[0-9]{3}$', At) -> W = narrowed ; W = At )
        ;   W = no_suspension_line
        ),
        check('an outer budget of 3000 narrows an inner ceiling of 100 million', W, narrowed)
    ;   check('could start a machine in the scratch store', failed, started)
    ),
    shl(['rm -rf ', D]).
