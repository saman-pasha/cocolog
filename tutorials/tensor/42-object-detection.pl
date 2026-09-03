%% 42. Object detection: pedestrians in photographs, on a GPU
%%
%% Every tutorial before this one drew its own data. This one reads the
%% Penn-Fudan pedestrian set -- 170 photographs from the streets around two
%% campuses, 345 people, each with a box -- and learns to say where the
%% people are. A small convolutional network sees the picture at 96 by 96
%% and ends in a 12 by 12 grid of cells, and each cell answers five
%% numbers: is there a person whose centre falls in me, and if so where in
%% me and how big. That is the one-stage detector in its simplest form, the
%% idea under YOLO, and everything in it that is not tensor arithmetic is
%% Prolog: the assignment of boxes to cells (targets/6), the reading of a
%% cell's five numbers back into a box (decode/2), the suppression of
%% duplicates (nms/3), the matching of found boxes to true ones by overlap
%% (matches/4). The network is a procedure, the loss is a defined function,
%% and the same file runs on torch and on TensorFlow.
%%
%% A REAL PICTURE IS TOO BIG FOR A SHIFT MATRIX. Tutorials 32 and 33 convolve
%% with nine [H*W, H*W] matrices; at 96 by 96 each is 85 million numbers.
%% Here the nine taps are index vectors, one number per pixel, and the shift
%% is a gather: taps/4 and pool_taps/4 in library(tensor_expr), and the same
%% conv2d/3 and pool2/2 with those in place of the matrices.
%%
%% A GPU TUTORIAL, and only that: every goal begins with ready/0, which puts
%% the process on the CUDA device and checks the data is there, and where
%% either is missing the goal says so and stops, ending 0 without having
%% run. The two hundred and more launches of a step are nothing to a GPU
%% and a quarter of an hour to a CPU; this file runs on the Colab T4.
%%
%%   download   fetches the 54 MB archive, unpacks it (curl and unzip) and writes the CSVs --
%%              in Prolog, through library(opencv): each PNG read, resized, and its people's
%%              boxes read off the instance masks
%%   train      136 photographs and their mirror images, Adam, 120 passes in batches of 17; saved as t42_detector
%%   test       the 34 held out: precision and recall at IoU 0.5 after suppression; ok at F1 >= 0.5 --
%%              on the T4, precision 0.70, recall 0.44, F1 0.54 at the default confidence, after 120 s of training.
%%              (The pixels decide: OpenCV's own resize filters -- area, a Gaussian tent, lanczos,
%%              cubic, linear -- measured 0.34 to 0.45 on the same seed and training, so the filter
%%              the original Python converter used, Pillow's antialiased bilinear, is vendored into
%%              library(opencv) as cv_resample; the CSVs are byte for byte what that converter wrote.)
%%   predict    twelve of the held out, box by box, on torch and then on TensorFlow, and the two compared;
%%              then the three best drawn on the original photographs with library(opencv),
%%              42-detection-1..3.jpg beside this file
%%
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/42-object-detection.pl download
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/42-object-detection.pl "tensor_execution(torch, graph, cuda), train"
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/42-object-detection.pl "tensor_execution(torch, graph, cuda), test"
%%   ./cocolog --embed /tmp/tutorials run tutorials/tensor/42-object-detection.pl "tensor_execution(torch, graph, cuda), predict"
%%
%% The data lives under tutorials/tensor/data/pennfudan, relative to the
%% repository root the commands above run from, or under $COCO_DATA/pennfudan.
%% Under `tensor_execution(tensorflow, graph, cuda), train' the same file
%% trains on the other library; predict runs both whatever trained.

:- use_module(library(torch)).
% :- use_module(library(tensorflow)).   % the second backend; tensor_execution(tensorflow, Mode, Device) loads it on demand
:- use_module(library(tensor_expr)).
:- use_module(library(process)).
:- use_module(library(os)).

%% ---- the shape of the problem ---------------------------------------------------
%% Every predicate here ends in a cut: a `run' consults this file into the
%% store, the store keeps every consult, and a generator without a cut would
%% answer once per copy.

side(96).        % the picture, resized to a square
grid(12).        % cells across and down; a cell is 8 pixels
batch(17).       % 136 photographs are 8 batches of 17, each seen straight and mirrored
passes(120).     % over the sixteen
predict_count(12).
%% confidence(-C): a cell answers a box from this objectness up. 0.35 unless
%% COCO_CONFIDENCE says otherwise -- an environment variable rather than a
%% fact, so `test' can be run at several without consulting the file again
%% into a store that would keep the earlier clause first.
confidence(C) :- os_env('COCO_CONFIDENCE', A, '0.35'), atom_number(A, C), !.

data_dir(D) :- os_env('COCO_DATA', Base, 'tutorials/tensor/data'), atom_concat(Base, '/pennfudan', D), !.
csv_path(Split, Kind, P) :- data_dir(D), atomic_list_concat([D, '/', Split, '-', Kind, '.csv'], P), !.
have_data :- csv_path(train, pixels, P), exists_file(P), csv_path(test, boxes, Q), exists_file(Q), !.

%% ---- the guard ------------------------------------------------------------------
%% ready/0 puts the process on the CUDA device -- `auto' on whichever library
%% is selected, then a question, not a notice, since a run on the CPU would
%% be a different tutorial -- and looks for the CSVs. Each goal is
%% `( ready -> exec(...) ; true )': the notice, once, and the run ends 0.

gpu :- tensor_execution(B, M), tensor_execution(B, M, auto), tensor_execution(_, _, D), D == cuda.
no_gpu :- write('42 is a GPU tutorial: no CUDA device here, not running'), nl.
no_data :- data_dir(D), format("42 needs the Penn-Fudan CSVs under ~w: run the download goal first~n", [D]).
ready :- ( gpu -> true ; no_gpu, fail ), ( have_data -> true ; no_data, fail ), !.

%% ---- download -------------------------------------------------------------------
%% One shell line through library(process) for the archive and the unpacking,
%% then the conversion IN PROLOG through library(opencv) -- it used to be a
%% Python script beside this file, the one step that was not Prolog, because
%% cocolog read no image format. Now it does: each photograph is read,
%% resized to 96 by 96 with cv_resample's bilinear -- Pillow's antialiased filter, the
%% one the Python converter used, vendored into library(opencv) so the pixels are
%% byte for byte the same -- turned RGB and
%% written as PIXELS AS ROWS, 9216 lines of three numbers in 0..1 -- the
%% layout conv2d/3 takes; and each pedestrian's box is read off the
%% instance mask, a plain 8-bit picture whose pixel values are the person
%% numbers, as the bounding rectangle of that value, scaled to the same 96
%% by 96. Every fifth photograph is held out: 34 to test on, 136 to train
%% on, the same split every time. Nothing here is quiet: one line per split
%% says how many photographs and people it holds.

download :-
    data_dir(D),
    (   have_data
    ->  format("the data is already at ~w~n", [D])
    ;   forall(member(Tool, [curl, unzip]),
               ( os_has(Tool) -> true ; format("~w is needed on PATH~n", [Tool]), halt(1) )),
        ( catch(use_module(library(opencv)), _, fail) -> true
        ; write('library(opencv) is needed to convert the pictures: sh modules/opencv/build.sh'), nl, halt(1) ),
        atom_concat(D, '/PennFudanPed/PNGImages', Pngs),
        (   exists_directory(Pngs)
        ->  format("the archive is already unpacked at ~w~n", [D])
        ;   format("downloading Penn-Fudan, 54 MB, into ~w~n", [D]),
            atomic_list_concat(['mkdir -p ', D,
                                ' && curl -sSL -o ', D, '/PennFudanPed.zip https://www.cis.upenn.edu/~jshi/ped_html/PennFudanPed.zip',
                                ' && unzip -qo ', D, '/PennFudanPed.zip -d ', D, ' 2>&1'], Cmd),
            proc_run(Cmd, 900000, Out, Exit), atom_codes(A, Out), write(A),
            ( Exit =:= 0 -> true ; format("the download ended ~w~n", [Exit]), halt(1) )
        ),
        convert(D),
        (   have_data
        ->  write(downloaded), nl
        ;   write('the conversion left no CSVs'), nl, halt(1)
        )
    ), !.

%% convert(+D): the CSVs and test-names.txt from PennFudanPed under D.
convert(D) :-
    atom_concat(D, '/PennFudanPed', Src), atom_concat(Src, '/PNGImages', Pngs),
    directory_files(Pngs, Entries), findall(N, ( member(N, Entries), atom_concat(_, '.png', N) ), Unsorted),
    msort(Unsorted, Names),
    findall(N, ( nth0(I, Names, N), I mod 5 =:= 0 ), Test),
    findall(N, ( nth0(I, Names, N), I mod 5 =\= 0 ), Train),
    convert_split(Src, D, train, Train),
    convert_split(Src, D, test, Test),
    atom_concat(D, '/test-names.txt', NP),
    with_output_to(codes(NC), forall(member(N, Test), ( write(N), nl ))),
    write_file_from_codes(NP, NC), !.

convert_split(Src, D, Split, Names) :-
    csv_path(Split, pixels, PP), csv_path(Split, boxes, BP),
    write_file_from_codes(PP, []), write_file_from_codes(BP, []),
    side(S),
    foldl([Name, K0-P0, K-P]>>( convert_one(Src, Name, K0, S, PP, BP, People), K is K0 + 1, P is P0 + People ),
          Names, 0-0, _-People),
    length(Names, NN), format("~w: ~w photographs, ~w people~n", [Split, NN, People]), !.

%% convert_one(+Src, +Name, +K, +S, +PixelsCsv, +BoxesCsv, -People): photograph K
%% of the split -- its pixels appended as rows, its people's boxes as lines
%% `K, x1, y1, x2, y2' in the S by S frame.
convert_one(Src, Name, K, S, PP, BP, People) :-
    atomic_list_concat([Src, '/PNGImages/', Name], Path),
    cv_imread(Path, Img), cv_shape(Img, [H, W, _]),
    cv_resample(Img, [S, S], bilinear, Small), cv_cvt_color(Small, bgr2rgb, Rgb), cv_to_list(Rgb, Rows),
    with_output_to(codes(PC),
        forall(( member(Row, Rows), member([R, G, B], Row) ),
               ( Rf is R / 255, Gf is G / 255, Bf is B / 255, format("~4f,~4f,~4f~n", [Rf, Gf, Bf]) ))),
    append_file_from_codes(PP, PC),
    atom_concat(Stem, '.png', Name), atomic_list_concat([Src, '/PedMasks/', Stem, '_mask.png'], MaskPath),
    cv_imread(MaskPath, unchanged, Mask), cv_minmax(Mask, _, MaxId, _, _), Last is truncate(MaxId),
    findall([X1, Y1, X2, Y2], ( between(1, Last, Id), person_box(Mask, Id, W, H, S, X1, Y1, X2, Y2) ), Boxes),
    with_output_to(codes(BC),
        forall(member([X1, Y1, X2, Y2], Boxes), format("~w,~2f,~2f,~2f,~2f~n", [K, X1, Y1, X2, Y2]))),
    append_file_from_codes(BP, BC),
    length(Boxes, People),
    cv_free_all([Img, Small, Rgb, Mask]), !.

%% person_box(+Mask, +Id, +W, +H, +S, -X1, -Y1, -X2, -Y2): the pixels valued
%% Id, as the rectangle around them, scaled from W by H to S by S. The
%% rectangle is the union of the external contours' boxes: x2 is one past
%% the rightmost pixel, as the original converter had it.
person_box(Mask, Id, W, H, S, X1, Y1, X2, Y2) :-
    cv_in_range(Mask, Id, Id, Bin), cv_count_nonzero(Bin, N), N > 0,
    cv_find_contours(Bin, external, simple, Cs), cv_free(Bin), Cs \== [],
    findall(R, ( member(C, Cs), cv_bounding_rect(C, R) ), Rs),
    findall(X, member([X, _, _, _], Rs), Xs), min_list(Xs, Xmin),
    findall(Y, member([_, Y, _, _], Rs), Ys), min_list(Ys, Ymin),
    findall(XR, ( member([X, _, Wd, _], Rs), XR is X + Wd ), XRs), max_list(XRs, Xmax),
    findall(YB, ( member([_, Y, _, Ht], Rs), YB is Y + Ht ), YBs), max_list(YBs, Ymax),
    X1 is Xmin * S / W, Y1 is Ymin * S / H, X2 is Xmax * S / W, Y2 is Ymax * S / H, !.

%% ---- the pictures and their boxes ---------------------------------------------------
%% pictures(+Split, -X, -Boxes, -N): the pixels of a split as [N*9216, 3],
%% centred on zero, and its boxes as box(I, X1, Y1, X2, Y2) in the 96 by 96
%% frame, I the photograph's index in the split.

pictures(Split, X, Boxes, N) -->
    { csv_path(Split, pixels, PP), csv_path(Split, boxes, BP) },
    X = csv(PP) - 0.5,
    B = csv(BP), Bl = list(B),
    { findall(box(I, X1, Y1, X2, Y2), ( member([If, X1, Y1, X2, Y2], Bl), I is truncate(If) ), Boxes),
      side(S) },
    [NR, _] = shape(X), { N is NR // (S * S) }, !.

%% chunks(+List, +K, -Chunks): K at a time, the last one shorter if it must be.
chunks([], _, []) :- !.
chunks(L, K, [C|Cs]) :- length(L, Len), Len >= K, !, length(C, K), append(C, R, L), chunks(R, K, Cs).
chunks(L, _, [L]) :- !.

%% ---- the targets: boxes to cells ----------------------------------------------------
%% targets(+Ids, +Boxes, -Obj, -Box, -Npos): for the photographs Ids in batch
%% order, one row per cell -- Obj [N*144, 1] is 1.0 where a person's centre
%% falls in the cell, Box [N*144, 4] that person's (dx, dy, w, h): the centre
%% within the cell in cell units and the size as a fraction of the picture,
%% all four in 0..1 so a sigmoid can answer them. A cell holds one person; a
%% second centre in the same cell is dropped, which at 12 by 12 costs a few
%% of the 345. Npos counts the cells with someone in them.
targets(Ids, Boxes, Obj, Box, Npos) :-
    grid(G), side(S), C is S / G, G1 is G - 1, GG is G * G,
    findall(cell(K, Row, Col, Dx, Dy, W, H),
            ( nth0(K, Ids, I), member(box(I, X1, Y1, X2, Y2), Boxes),
              Cx is (X1 + X2) / 2, Cy is (Y1 + Y2) / 2,
              Col is min(G1, truncate(Cx / C)), Row is min(G1, truncate(Cy / C)),
              Dx is Cx / C - Col, Dy is Cy / C - Row, W is (X2 - X1) / S, H is (Y2 - Y1) / S ), Cells),
    length(Ids, N), NG1 is N * GG - 1,
    findall(O-[Dx, Dy, W, H],
            ( between(0, NG1, Q), K is Q // GG, Row is (Q mod GG) // G, Col is Q mod G,
              (   memberchk(cell(K, Row, Col, Dx, Dy, W, H), Cells)
              ->  O = 1.0
              ;   O = 0.0, Dx = 0.0, Dy = 0.0, W = 0.0, H = 0.0 ) ), Rows),
    findall([O], member(O-_, Rows), Obj), findall(B, member(_-B, Rows), Box),
    findall(x, member(1.0-_, Rows), Ones), length(Ones, Npos), !.

%% ---- the network ------------------------------------------------------------------
%% constants(+N, -Cs): the taps of a batch of N pictures at each size the
%% network works at -- a convolution at 96, 48, 24 and 12, a pooling between.
constants(N, t(T96, P96, T48, P48, T24, P24, T12)) -->
    taps(N, 96, 96, T96), pool_taps(N, 96, 96, P96),
    taps(N, 48, 48, T48), pool_taps(N, 48, 48, P48),
    taps(N, 24, 24, T24), pool_taps(N, 24, 24, P24),
    taps(N, 12, 12, T12), !.

parameters([K1, B1, K2, B2, K3, B3, K5, B5, K4, B4, K6, B6, Wh, Bh]) :-
    K1 := parameter(glorot(27, 16)),  B1 := parameter(zeros([1, 16])),    %  3 -> 16 at 96
    K2 := parameter(glorot(144, 32)), B2 := parameter(zeros([1, 32])),    % 16 -> 32 at 48
    K3 := parameter(glorot(288, 64)), B3 := parameter(zeros([1, 64])),    % 32 -> 64 at 24
    K5 := parameter(glorot(576, 64)), B5 := parameter(zeros([1, 64])),    % 64 -> 64 at 24
    K4 := parameter(glorot(576, 64)), B4 := parameter(zeros([1, 64])),    % 64 -> 64 at 12
    K6 := parameter(glorot(576, 64)), B6 := parameter(zeros([1, 64])),    % 64 -> 64 at 12
    Wh := parameter(glorot(64, 5)),   Bh := parameter(zeros([1, 5])), !.  % the head: five numbers a cell

%% forward(+Ps, +Cs, +X, -Out): six convolutions, three poolings, a head --
%% a PROCEDURE, a DCG rule of bindings; exec/1 runs it and frees everything
%% it made but Out. Out is [N*144, 5], one row per cell: the objectness
%% logit, then dx, dy, w, h, each read through a sigmoid. Two convolutions
%% at 24 and two at 12 give a cell a receptive field of 62 pixels, a
%% standing person's height here; with one each it was 38, and the network
%% boxed shoulders and knees as two people.
forward([K1, B1, K2, B2, K3, B3, K5, B5, K4, B4, K6, B6, Wh, Bh], t(T96, P96, T48, P48, T24, P24, T12), X, Out) -->
    A1 = relu(conv2d(X, K1, T96) + B1),                % [N*9216, 16]
    D1 = pool2(A1, P96),                               % [N*2304, 16]
    A2 = relu(conv2d(D1, K2, T48) + B2),               % [N*2304, 32]
    D2 = pool2(A2, P48),                               % [N*576, 32]
    A3 = relu(conv2d(D2, K3, T24) + B3),               % [N*576, 64]
    A5 = relu(conv2d(A3, K5, T24) + B5),               % [N*576, 64]
    D3 = pool2(A5, P24),                               % [N*144, 64]
    A4 = relu(conv2d(D3, K4, T12) + B4),               % [N*144, 64]  the grid
    A6 = relu(conv2d(A4, K6, T12) + B6),               % [N*144, 64]
    Out = A6 matmul Wh + Bh.                           % [N*144, 5]

%% THE LOSS IS A DEFINED FUNCTION. Objectness is a binary cross-entropy with
%% the few positive cells weighted ten times, or 142 empty cells a picture
%% would drown the two with someone in them; the box is a squared error on
%% the four sigmoids, counted only where there is a person, scaled by Scale
%% = 5 / Npos so the two terms are of a size.
wbce(P, Y, Wt) ::= - mean(Wt * (Y * log(P + 1.0e-7) + (1.0 - Y) * log(1.0 - P + 1.0e-7))).
loss(Out, Obj, Box, Wt, Scale) ::=
    wbce(sigmoid(cols(Out, 0, 1)), Obj, Wt) + sum(Obj * ((sigmoid(cols(Out, 1, 5)) - Box) ^ 2.0)) * Scale.

%% ---- training ---------------------------------------------------------------------

train :- ( ready -> exec(train) ; true ), !.
test :- ( ready -> exec(test) ; true ), !.

train -->
    seed(42),
    pictures(train, X, Boxes, N),
    { length(Boxes, NB), batch(B), passes(E),
      format("~w photographs, ~w people; a batch is ~w, straight and mirrored, ~w passes~n", [N, NB, B, E]) },
    constants(B, Cs),
    Perm = randperm(N), Pl = list(Perm),
    { findall(I, ( member(F, Pl), I is truncate(F) ), Ids), chunks(Ids, B, Groups0),
      findall(G, ( member(G, Groups0), length(G, B) ), Groups) },
    batches(Groups, X, Boxes, Batches),
    { length(Batches, NBt), parameters(Ps0), adam_init(Ps0, St0), Steps is E * NBt,
      format("   ~w steps~n", [Steps]),
      fit(Steps, Ps0, St0, Cs, Batches, NBt, Ps) },
    params_save(t42_detector, Ps),
    { write(saved), nl }.

%% batches(+Groups, +X, +Boxes, -Batches): each group of photographs as its
%% pixels gathered out of X and its targets, made once and kept for the run
%% -- and each group a second time MIRRORED, the one augmentation here: a
%% gather that reads pixel (y, 95 - x), and the boxes reflected to match.
%% A hundred and thirty-six photographs are few; three hundred passes over
%% them alone drove the loss to 0.01 and the held-out F1 down, not up.
batches([], _, _, []) --> [].
batches([Ids|Gs], X, Boxes, [b(XB, Obj, Box, Wt, Scale), b(XF, ObjF, BoxF, WtF, ScaleF)|Bs]) -->
    { side(S), SS is S * S, SS1 is SS - 1, S1 is S - 1,
      findall(V, ( member(I, Ids), between(0, SS1, P), V is float(I * SS + P) ), Rows),
      findall(V, ( member(I, Ids), between(0, SS1, P), Y is P // S, Xx is P mod S,
                   V is float(I * SS + Y * S + S1 - Xx) ), RowsF),
      targets(Ids, Boxes, ObjL, BoxL, Npos), Scale is 5.0 / max(1, Npos),
      findall(box(I, FX1, Y1, FX2, Y2), ( member(box(I, X1, Y1, X2, Y2), Boxes), FX1 is S - X2, FX2 is S - X1 ), BoxesF),
      targets(Ids, BoxesF, ObjLF, BoxLF, NposF), ScaleF is 5.0 / max(1, NposF) },
    XB = index_rows(X, Rows), Obj = ObjL, Box = BoxL, Wt = Obj * 9.0 + 1.0,
    XF = index_rows(X, RowsF), ObjF = ObjLF, BoxF = BoxLF, WtF = ObjF * 9.0 + 1.0,
    batches(Gs, X, Boxes, Bs).

%% THE FIT LOOP IS A PREDICATE: it steps an optimiser that frees the old
%% parameters itself. The gradient is asked BEFORE the loss is read, so
%% under the graph path a step is one call that answers both.
fit(0, Ps, _, _, _, _, Ps) :- !.
fit(K, Ps, St, Cs, Batches, NBt, PsF) :-
    J is K mod NBt, nth0(J, Batches, b(XB, Obj, Box, Wt, Scale)),
    exec(forward(Ps, Cs, XB, Out)),
    L := loss(Out, Obj, Box, Wt, Scale),
    Gs := grad(L, Ps),
    ( K mod 40 =:= 0 -> Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv]) ; true ),
    adam_step(Ps, Gs, St, 0.002, Ps2, St2),
    free_all([Out, L]),
    K1 is K - 1,
    fit(K1, Ps2, St2, Cs, Batches, NBt, PsF).

%% ---- from cells back to boxes -------------------------------------------------------
%% detect(+Ps, +Cs1, +X, +I, -Found): photograph I of X through the network
%% alone, its 144 cells decoded and the duplicates suppressed; Found is a
%% list of found(Score, X1, Y1, X2, Y2), best first.
detect(Ps, Cs1, X, I, Found) -->
    { side(S), SS is S * S, From is I * SS, To is From + SS },
    XI = rows(X, From, To),
    forward(Ps, Cs1, XI, Out),
    Cells = list(sigmoid(Out)),
    { decode(Cells, Cands), nms(Cands, 0.4, Found) }.

%% decode(+Cells, -Cands): a cell answers a box when its objectness passes
%% confidence/1 -- the centre is the cell's corner plus (dx, dy) cells, the
%% size is (w, h) of the picture.
decode(Cells, Cands) :-
    grid(G), side(S), C is S / G, confidence(Conf),
    findall(found(P, X1, Y1, X2, Y2),
            ( nth0(Q, Cells, [P, Dx, Dy, W, H]), P > Conf,
              Row is Q // G, Col is Q mod G,
              Cx is (Col + Dx) * C, Cy is (Row + Dy) * C, Bw is W * S, Bh is H * S,
              X1 is Cx - Bw / 2, Y1 is Cy - Bh / 2, X2 is Cx + Bw / 2, Y2 is Cy + Bh / 2 ), Cands), !.

%% nms(+Cands, +Thr, -Kept): non-maximum suppression -- take the best, drop
%% every candidate that overlaps it by more than Thr, repeat on the rest.
nms(Cands, Thr, Kept) :- sort(0, @>=, Cands, Sorted), nms_(Sorted, Thr, Kept), !.
nms_([], _, []).
nms_([F|Fs], Thr, [F|Ks]) :-
    exclude([G]>>( iou(F, G, V), V > Thr ), Fs, Rest),
    nms_(Rest, Thr, Ks).

%% iou(+A, +B, -V): intersection over union of two boxes, found/5 or box/5.
iou(A, B, V) :-
    corners(A, AX1, AY1, AX2, AY2), corners(B, BX1, BY1, BX2, BY2),
    IX is max(0.0, min(AX2, BX2) - max(AX1, BX1)), IY is max(0.0, min(AY2, BY2) - max(AY1, BY1)),
    Inter is IX * IY,
    Union is (AX2 - AX1) * (AY2 - AY1) + (BX2 - BX1) * (BY2 - BY1) - Inter,
    ( Union > 0 -> V is Inter / Union ; V = 0.0 ), !.
corners(found(_, X1, Y1, X2, Y2), X1, Y1, X2, Y2) :- !.
corners(box(_, X1, Y1, X2, Y2), X1, Y1, X2, Y2) :- !.

%% matches(+Found, +Truth, -Results, -Missed): each found box, best first,
%% takes the true box it overlaps most if that overlap reaches 0.5 and the
%% box is still free -- hit(IoU) -- and is a miss otherwise; Missed is what
%% no found box took.
matches([], Truth, [], Truth) :- !.
matches([F|Fs], Truth, [F-R|Rs], Missed) :-
    (   findall(V-T, ( member(T, Truth), iou(F, T, V) ), Ps), Ps \== [],
        sort(0, @>=, Ps, [V-T|_]), V >= 0.5
    ->  R = hit(V), select(T, Truth, Truth1)
    ;   R = miss, Truth1 = Truth
    ),
    matches(Fs, Truth1, Rs, Missed).

truth_of(I, Boxes, Truth) :- findall(B, ( member(B, Boxes), B = box(I, _, _, _, _) ), Truth), !.

%% ---- test: precision and recall over the held-out photographs -------------------------

test -->
    pictures(test, X, Boxes, N),
    constants(1, Cs1),
    params_load(t42_detector, Ps),
    { N1 is N - 1, evaluate(0, N1, Ps, Cs1, X, Boxes, 0, 0, 0, TP, FP, FN),
      length(Boxes, NB), NF is TP + FP,
      Prec is TP / max(1, NF), Rec is TP / max(1, TP + FN),
      F1 is 2 * Prec * Rec / max(1.0e-9, Prec + Rec),
      format("test: ~w people in ~w photographs; found ~w, ~w right, ~w missed: precision ~2f recall ~2f F1 ~2f~n",
             [NB, N, NF, TP, FN, Prec, Rec, F1]),
      ( F1 >= 0.5 -> write(ok), nl ; write('FAIL'), nl, halt(1) ) }.

%% evaluate/12 is a predicate that runs detect/5 through exec/1 one
%% photograph at a time, so each one's hundred-odd temporaries are freed
%% before the next: thirty-four forwards held at once would fill the
%% module's handle table.
evaluate(I, N1, _, _, _, _, TP, FP, FN, TP, FP, FN) :- I > N1, !.
evaluate(I, N1, Ps, Cs1, X, Boxes, TP0, FP0, FN0, TP, FP, FN) :-
    exec(detect(Ps, Cs1, X, I, Found)),
    truth_of(I, Boxes, Truth),
    matches(Found, Truth, Rs, Missed),
    findall(x, member(_-hit(_), Rs), Hs), length(Hs, H),
    findall(x, member(_-miss, Rs), Ms), length(Ms, M),
    length(Missed, L),
    TP1 is TP0 + H, FP1 is FP0 + M, FN1 is FN0 + L,
    I1 is I + 1,
    evaluate(I1, N1, Ps, Cs1, X, Boxes, TP1, FP1, FN1, TP, FP, FN), !.

%% ---- predict: the same photographs on both libraries --------------------------------
%% The first twelve held-out photographs, box by box, first on torch and then
%% on TensorFlow, each library loading the parameters and running the
%% procedure on its own; then the two answers side by side. Each backend runs
%% in its own exec/1, so the tensors one library made are freed before the
%% other is selected -- a handle belongs to the library that made it.

predict :-
    (   ready
    ->  exec(predict(torch, R1)),
        (   catch(tensor_execution(tensorflow, graph, cuda), _, fail)
        ->  exec(predict(tensorflow, R2)), agreement(R1, R2)
        ;   write('library(tensorflow) is not built here: torch only'), nl
        ),
        draw(R1)
    ;   true
    ), !.

%% draw(+Results): the three photographs the network did best on, with the
%% people in green and what it found in red, written beside this file
%% through library(opencv). A photograph's score is its hits (a found box
%% overlapping a person by 0.5 or more) less half a point per stray box and
%% a quarter per person missed; the best three are drawn, each shrunk to
%% 720 pixels a side at most, with a caption strip under it.
draw(R) :-
    (   catch(use_module(library(opencv)), _, fail)
    ->  data_dir(D),
        atom_concat(D, '/test-names.txt', NP), read_file_to_codes(NP, NC), lines(NC, NameLines),
        findall(N, ( member(L, NameLines), L \== [], atom_codes(N, L) ), Names),
        csv_path(test, boxes, BP), read_file_to_codes(BP, BC), lines(BC, BoxLines),
        findall(box(I, X1, Y1, X2, Y2),
                ( member(L, BoxLines), L \== [], atom_codes(A, L), atomic_list_concat(Fs, ',', A),
                  Fs = [If, X1a, Y1a, X2a, Y2a], atom_number(If, I),
                  atom_number(X1a, X1), atom_number(Y1a, Y1), atom_number(X2a, X2), atom_number(Y2a, Y2) ), Boxes),
        findall(Score-I,
                ( member(I-F, R), truth_of(I, Boxes, Truth),
                  findall(x, ( member(B, F), member(T, Truth), iou(B, T, V), V >= 0.5 ), Hs), length(Hs, Hits0),
                  length(F, NF), length(Truth, NT), Hits is min(Hits0, NF),
                  Score is Hits - 0.5 * (NF - Hits) - 0.25 * (NT - Hits) ), Scored),
        msort(Scored, Asc), reverse(Asc, Desc),
        findall(I, member(_-I, Desc), Ranked), take(3, Ranked, Best),
        nl,
        forall(nth1(N, Best, I), ( member(I-F, R), truth_of(I, Boxes, Truth), nth0(I, Names, Name),
                                   draw_one(D, N, Name, Truth, F) ))
    ;   write('library(opencv) is not built here: the pictures were not drawn'), nl
    ), !.

%% draw_one(+D, +N, +Name, +Truth, +Found): photograph Name as 42-detection-N.jpg.
draw_one(D, N, Name, Truth, Found) :-
    atomic_list_concat([D, '/PennFudanPed/PNGImages/', Name], Path),
    cv_imread(Path, Img), cv_shape(Img, [H, W, _]), side(S), Sx is W / S, Sy is H / S,
    forall(member(box(_, X1, Y1, X2, Y2), Truth),
           ( scaled(X1, Y1, X2, Y2, Sx, Sy, Rect), cv_rectangle(Img, Rect, [40, 200, 40], 3) )),
    forall(member(found(P, X1, Y1, X2, Y2), Found),
           ( scaled(X1, Y1, X2, Y2, Sx, Sy, Rect), cv_rectangle(Img, Rect, [40, 40, 235], 3),
             Rect = [Rx, Ry|_],
             %% the score inside the box, and inside the frame when the box is not
             Tx is max(Rx, 0) + 8, Ty is max(Ry, 0) + 22, format(atom(PA), '~2f', [P]),
             cv_put_text(Img, PA, [Tx, Ty], 0.6, [40, 40, 235], 2) )),
    Longest is max(W, H), ( Longest > 720 -> F is 720 / Longest, cv_resize(Img, F, area, Shown) ; cv_clone(Img, Shown) ),
    cv_shape(Shown, [SH, SW, _]),
    atom_concat(Stem, '.png', Name), length(Truth, NT), length(Found, NF),
    format(atom(Caption), 'cocolog 42, ~w: green the people, red the network', [Stem]),
    %% the caption at 0.45, or smaller when the photograph is narrower than it
    cv_text_size(Caption, 0.45, 1, [TW, _]), ( TW + 16 > SW -> Fs is 0.45 * (SW - 16) / TW ; Fs = 0.45 ),
    cv_new(26, SW, '8uc3', [20, 20, 20], Strip), cv_put_text(Strip, Caption, [8, 18], Fs, [240, 240, 240], 1),
    cv_vconcat([Shown, Strip], Page),
    format(atom(Out), 'tutorials/tensor/42-detection-~w.jpg', [N]), cv_imwrite(Out, Page),
    format("wrote ~w: ~w, ~w people, ~w boxes found~n", [Out, Name, NT, NF]),
    cv_free_all([Img, Shown, Strip, Page]), SH > 0, !.

scaled(X1, Y1, X2, Y2, Sx, Sy, [Rx, Ry, Rw, Rh]) :-
    Rx is round(X1 * Sx), Ry is round(Y1 * Sy), Rw is round((X2 - X1) * Sx), Rh is round((Y2 - Y1) * Sy), !.

take(0, _, []) :- !.
take(_, [], []) :- !.
take(N, [X|Xs], [X|Ys]) :- N1 is N - 1, take(N1, Xs, Ys), !.

lines([], []) :- !.
lines(Codes, [Line|Lines]) :- append(Line, [10|Rest], Codes), !, lines(Rest, Lines).
lines(Codes, [Codes]) :- !.

predict(Backend, Results) -->
    { tensor_execution(Backend, graph, cuda), predict_count(PC), PC1 is PC - 1,
      format("~n-- ~w photographs on ~w~n", [PC, Backend]) },
    pictures(test, X, Boxes, _),
    constants(1, Cs1),
    params_load(t42_detector, Ps),
    { findall(I-Found, ( between(0, PC1, I), exec(detect(Ps, Cs1, X, I, Found)), report(I, Boxes, Found) ), Results) }.

report(I, Boxes, Found) :-
    truth_of(I, Boxes, Truth), length(Truth, NT), length(Found, NF),
    matches(Found, Truth, Rs, Missed), length(Missed, NM),
    format("   photograph ~w: ~w people, found ~w, ~w missed~n", [I, NT, NF, NM]),
    forall(member(found(P, X1, Y1, X2, Y2)-R, Rs),
           ( ( R = hit(V) -> format(atom(RA), 'a person, overlap ~2f', [V]) ; RA = 'nobody there' ),
             format("      [~0f ~0f ~0f ~0f] at ~2f: ~w~n", [X1, Y1, X2, Y2, P, RA]) )),
    forall(member(box(_, X1, Y1, X2, Y2), Missed),
           format("      missed the person at [~0f ~0f ~0f ~0f]~n", [X1, Y1, X2, Y2])), !.

%% agreement(+R1, +R2): the two libraries' answers, photograph by photograph:
%% the same number of boxes, in the same order, each within two pixels and
%% its score within 0.05, counts as agreement -- two libraries' kernels, not
%% one, and a box near the 0.5 threshold can fall either side.
agreement(R1, R2) :-
    findall(I, ( member(I-F1, R1), member(I-F2, R2), same_boxes(F1, F2) ), Same),
    length(Same, NS), length(R1, N),
    format("~ntorch and tensorflow agree on ~w of ~w photographs: the same boxes within two pixels~n", [NS, N]),
    forall(( member(I-F1, R1), member(I-F2, R2), \+ same_boxes(F1, F2) ),
           ( length(F1, A), length(F2, B), format("   photograph ~w: torch found ~w, tensorflow ~w~n", [I, A, B]) )), !.
same_boxes([], []) :- !.
same_boxes([found(P, X1, Y1, X2, Y2)|As], [found(Q, U1, V1, U2, V2)|Bs]) :-
    abs(P - Q) =< 0.05, abs(X1 - U1) =< 2.0, abs(Y1 - V1) =< 2.0, abs(X2 - U2) =< 2.0, abs(Y2 - V2) =< 2.0,
    same_boxes(As, Bs), !.
