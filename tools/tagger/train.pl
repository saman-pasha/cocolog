%% tools/tagger/train.pl -- trains the SHIPPED tagger, the one
%% tagger_pretrained/1 loads, into the knowledge base this process proves
%% against, under the name `tagger', and measures it. Run by
%% tools/tagger/train.sh over a fresh --embed store:
%%
%%     sh tools/tagger/train.sh                 # writes library/reasoning/model
%%
%% The defaults of tagger_train/2 -- 16384 pairs, 400 steps -- about two
%% minutes on four cores. Errors are thrown, not printed: a training that
%% did not finish leaves no model to ship.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/tagger)).

main :-
    tagger_train(tagger, [verbose(true)]),
    tagger_load(tagger, M),
    tagger_evaluate(M, 30001, 300, report(Tok, Sent, Acc, _)),
    tagger_refused(M, 6001, 300, Rate),
    format("tagger: tokens ~4f sentences ~4f accepted ~4f, real prose refused ~4f~n", [Tok, Sent, Acc, Rate]),
    tagger_free(M).
