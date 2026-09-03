%% OPENCV 23 -- dnn: YOLOv4-tiny, detection boxes decoded in Prolog
%%
%%     ./cocolog run tutorials/opencv/23-dnn-detection.pl download
%%     ./cocolog run tutorials/opencv/23-dnn-detection.pl main
%%
%% OpenCV's "YOLO DNNs" lesson. A detector answers many rows, each a
%% candidate box with an objectness and eighty class scores; turning
%% those into a few good boxes is bookkeeping -- keep the confident rows,
%% scale the coordinates to the picture, suppress the overlaps -- and the
%% bookkeeping is written here in Prolog over the lists cv_to_list/2
%% answers, with cv_dnn_nms/5 for the suppression.
%%
%%     cv_dnn_read(+Weights, +Config, -Net)      a Darknet pair
%%     cv_dnn_outputs(+Net, -Outs)               every output layer, in order
%%     cv_dnn_nms(+Rects, +Scores, +ScoreT, +NmsT, -Indices)
%%
%% THE MODEL IS NOT IN THE REPOSITORY: `download' fetches the config,
%% the weights (24 MB) and the class names into tutorials/opencv/models/.

:- use_module(library(opencv)).
:- use_module(library(process)).

file(cfg, 'tutorials/opencv/models/yolov4-tiny.cfg', 'https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4-tiny.cfg').
file(weights, 'tutorials/opencv/models/yolov4-tiny.weights', 'https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v4_pre/yolov4-tiny.weights').
file(names, 'tutorials/opencv/models/coco.names', 'https://raw.githubusercontent.com/AlexeyAB/darknet/master/data/coco.names').

download :-
    sh('mkdir -p tutorials/opencv/models', _),
    forall(file(_, F, U),
           ( exists_file(F) -> format("have ~w~n", [F])
           ; format("fetching ~w~n", [U]), atomic_list_concat(['curl -sSL -o ', F, ' ', U], Cmd), sh(Cmd, _),
             ( exists_file(F) -> format("   -> ~w~n", [F]) ; format("   FAILED~n") ) )),
    format("done~n").

main :-
    file(cfg, Cfg, _), file(weights, Wts, _), file(names, Nm, _),
    (   exists_file(Cfg), exists_file(Wts), exists_file(Nm)
    ->  detect(Cfg, Wts, Nm)
    ;   format("~n   the model is not here: run this file's `download' goal first~n"),
        format("   (./cocolog run tutorials/opencv/23-dnn-detection.pl download)~n")
    ),
    format("~ndone~n").

detect(Cfg, Wts, Nm) :-
    ensure_out,
    cv_dnn_read(Wts, Cfg, Net), cv_dnn_out_layers(Net, Outs), show('YOLOv4-tiny output layers', Outs),
    read_file_to_codes(Nm, Codes), lines(Codes, Lines), findall(A, (member(Li, Lines), Li \== [], atom_codes(A, Li)), Names),
    length(Names, NN), must('eighty COCO classes', NN, 80),
    forall(photo(K, P), detect_in(Net, Names, K, P)),
    cv_free(Net),
    cv_handles(N), must('every handle freed', N, 0).

detect_in(Net, Names, K, P) :-
    format("~n-- photo ~w~n", [K]),
    cv_imread(P, Img), cv_shape(Img, [H, W, _]),
    %% YOLO wants [0, 1] RGB, 416 square, no cropping
    cv_dnn_blob(Img, 0.00392157, [416, 416], [0, 0, 0], true, false, Blob),
    cv_dnn_input(Net, Blob), cv_dnn_outputs(Net, OutHs),
    findall(Rows, (member(Oh, OutHs), cv_to_list(Oh, Rows)), RowLists), append(RowLists, AllRows),
    length(AllRows, NCand), show('candidate rows', NCand),
    findall(box(Rect, Score, Cls),
            ( member([Cx, Cy, Bw, Bh, _Obj|Scores], AllRows),
              max_list(Scores, Score), Score > 0.4, nth0(Cls, Scores, Score),
              X is round((Cx - Bw / 2) * W), Y is round((Cy - Bh / 2) * H),
              RW is round(Bw * W), RH is round(Bh * H), Rect = [X, Y, RW, RH] ),
            Boxes),
    length(Boxes, NBoxes), show('rows above 0.4', NBoxes),
    findall(R, member(box(R, _, _), Boxes), Rects), findall(S, member(box(_, S, _), Boxes), Scores2),
    cv_dnn_nms(Rects, Scores2, 0.4, 0.45, Keep), length(Keep, NKeep), show('after non-maximum suppression', NKeep),
    forall(member(I, Keep),
           ( nth0(I, Boxes, box(Rc, Sc, Cl)), nth0(Cl, Names, Name),
             format("   ~w  ~3f  ~w~n", [Name, Sc, Rc]),
             cv_rectangle(Img, Rc, green, 2), Rc = [TX, TY|_], TY2 is max(TY - 6, 12), cv_put_text(Img, Name, [TX, TY2], 0.6, green, 2) )),
    findall(1, (member(I2, Keep), nth0(I2, Boxes, box(_, _, C2)), nth0(C2, Names, person)), Persons), length(Persons, NPersons),
    ( NPersons >= 1 -> Found = at_least_one ; Found = NPersons ), must('people in a picture of pedestrians', Found, at_least_one),
    atom_concat('23-detection-', K, F0), atom_concat(F0, '.png', F), out(F, Path), cv_imwrite(Path, Img), show('written', Path),
    cv_free_all([Img, Blob|OutHs]).

lines([], []).
lines(Codes, [Line|Lines]) :- append(Line, [10|Rest], Codes), !, lines(Rest, Lines).
lines(Codes, [Codes]).

photo(1, 'tutorials/tensor/42-detection-1.jpg').
photo(2, 'tutorials/tensor/42-detection-2.jpg').
photo(3, 'tutorials/tensor/42-detection-3.jpg').

out_dir('/tmp/cocolog-opencv').
out(File, Path) :- out_dir(D), atom_concat(D, '/', D1), atom_concat(D1, File, Path).
ensure_out :- out_dir(D), atom_concat('mkdir -p ', D, Cmd), sh(Cmd, _).

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
