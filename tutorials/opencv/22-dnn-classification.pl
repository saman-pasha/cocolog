%% OPENCV 22 -- dnn: an ImageNet classifier from an ONNX file
%%
%%     ./cocolog run tutorials/opencv/22-dnn-classification.pl download
%%     ./cocolog run tutorials/opencv/22-dnn-classification.pl main
%%
%% OpenCV's "Load Caffe framework models" lesson, with an ONNX model
%% instead: SqueezeNet 1.1, five megabytes, a thousand ImageNet classes.
%% The dnn module RUNS networks; it does not train them. A picture goes
%% in as a BLOB -- resized, scaled, mean-subtracted, channels first -- and
%% the answer comes out as one more image, 1 by 1000 here, which the
%% ordinary predicates read.
%%
%%     cv_dnn_read(+Model, -Net)   cv_dnn_read(+Model, +Config, -Net)
%%     cv_dnn_blob(+Img, +Scale, +[W, H], +Mean, +SwapRB, +Crop, -Blob)
%%     cv_dnn_input(+Net, +Blob)   cv_dnn_forward(+Net, -Out)   cv_dnn_forward(+Net, +Layer, -Out)
%%     cv_dnn_outputs(+Net, -Outs)   cv_dnn_layers(+Net, -Names)   cv_dnn_out_layers(+Net, -Names)
%%     cv_dnn_time(+Net, -Ms)   cv_dnn_top(+Out, -Class, -Score)
%%
%% THE MODEL IS NOT IN THE REPOSITORY. `download' fetches it (and the
%% class names) into tutorials/opencv/models/ with curl; without it
%% `main' says so and ends, so the tutorial suite stays green offline.

:- use_module(library(opencv)).
:- use_module(library(process)).

model('tutorials/opencv/models/squeezenet1.1-7.onnx',
      'https://github.com/onnx/models/raw/main/validated/vision/classification/squeezenet/model/squeezenet1.1-7.onnx').
labels('tutorials/opencv/models/synset.txt',
       'https://raw.githubusercontent.com/onnx/models/main/validated/vision/classification/synset.txt').

download :-
    sh('mkdir -p tutorials/opencv/models', _),
    forall(( model(F, U) ; labels(F, U) ),
           ( exists_file(F) -> format("have ~w~n", [F])
           ; format("fetching ~w~n", [U]), atomic_list_concat(['curl -sSL -o ', F, ' ', U], Cmd), sh(Cmd, _),
             ( exists_file(F) -> format("   -> ~w~n", [F]) ; format("   FAILED~n") ) )),
    format("done~n").

main :-
    model(M, _), labels(L, _),
    (   exists_file(M), exists_file(L)
    ->  classify(M, L)
    ;   format("~n   the model is not here: run this file's `download' goal first~n"),
        format("   (./cocolog run tutorials/opencv/22-dnn-classification.pl download)~n")
    ),
    format("~ndone~n").

classify(M, L) :-
    ensure_out,
    format("~n-- the network~n"),
    cv_dnn_read(M, Net),
    cv_dnn_layers(Net, Layers), length(Layers, NL), show('layers', NL),
    cv_dnn_out_layers(Net, Outs), show('output layers', Outs),
    ( NL > 30 -> Deep = yes ; Deep = NL ), must('SqueezeNet has a few dozen', Deep, yes),

    format("~n-- the blob: 224 by 224, scaled, mean-subtracted, RGB, channels first~n"),
    photo(P), cv_imread(P, Img),
    %% ImageNet normalisation, (x / 255 - mean) / std, as one scale and one mean:
    %% 1 / (0.226 * 255) and the means times 255
    cv_dnn_blob(Img, 0.017353, [224, 224], [123.675, 116.28, 103.53], true, true, Blob),
    cv_shape(Blob, BS), must('a blob is N by C by H by W', BS, [1, 3, 224, 224]),
    cv_type(Blob, BT), must('32f', BT, '32f'),

    format("~n-- forward~n"),
    cv_dnn_input(Net, Blob), cv_dnn_forward(Net, Out),
    cv_shape(Out, OS), must('one row of a thousand scores', OS, [1, 1000, 1]),
    cv_dnn_time(Net, Ms), show('milliseconds', Ms),
    cv_dnn_top(Out, Class, Score), show('the top class index and raw score', Class-Score),
    class_names(L, Names), nth0(Class, Names, Name), show('which is', Name),
    %% the index belongs to the CURRENT 42-detection-1.jpg: tutorial 42's predict redraws
    %% the photographs, and a new picture is a new class -- re-pin it with the pictures
    must('the same picture, the same model, the same class every run', Class, 843),

    format("~n-- softmax in Prolog: the top five with probabilities~n"),
    cv_to_list(Out, [Scores]), max_list(Scores, Max),
    findall(E, (member(S, Scores), E is exp(S - Max)), Es), sum_list(Es, Z),
    findall(Pr-I, (nth0(I, Es, E2), Pr is E2 / Z), Probs), msort(Probs, Asc), reverse(Asc, Desc),
    Desc = [Top|_], Top = P1-_, ( P1 > 0.2 -> Sure = fairly_confident ; Sure = P1 ), show('top probability', Sure),
    forall((nth0(K, Desc, Pk-Ik), K < 5), (nth0(Ik, Names, Nk), format("   ~w  ~4f  ~w~n", [Ik, Pk, Nk]))),

    format("~n-- the same net, a different picture: a synthetic scene is nothing in particular~n"),
    scene(Sc), cv_dnn_blob(Sc, 0.017353, [224, 224], [123.675, 116.28, 103.53], true, true, Blob2),
    cv_dnn_input(Net, Blob2), cv_dnn_forward(Net, Out2), cv_dnn_top(Out2, Class2, _), nth0(Class2, Names, Name2),
    show('the scene is called', Name2),

    cv_free_all([Net, Img, Blob, Out, Sc, Blob2, Out2]),
    cv_handles(N), must('every handle freed', N, 0).

%% synset.txt: one class per line, "n01440764 tench, Tinca tinca"; the name after the id
class_names(File, Names) :-
    read_file_to_codes(File, Codes), lines(Codes, Lines),
    findall(Name, (member(Line, Lines), Line \== [], ( append(_, [32|Rest], Line) -> true ; Rest = Line ), atom_codes(Name, Rest)), Names).
lines([], []).
lines(Codes, [Line|Lines]) :- append(Line, [10|Rest], Codes), !, lines(Rest, Lines).
lines(Codes, [Codes]).

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

photo('tutorials/tensor/42-detection-1.jpg').
out_dir('/tmp/cocolog-opencv').
ensure_out :- out_dir(D), atom_concat('mkdir -p ', D, Cmd), sh(Cmd, _).

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
