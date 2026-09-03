%% OPENCV 18 -- object detection: cascades, HOG people, QR codes
%%
%%     ./cocolog run tutorials/opencv/18-object-detection.pl main
%%
%% OpenCV's "Cascade Classifier" lesson and the objdetect module around
%% it. A Haar cascade is a trained detector for one kind of thing (faces,
%% eyes, bodies) that OpenCV ships as XML files; cv_data_dir/1 says where.
%% The HOG people detector is the other classic, trained into OpenCV
%% itself. QR codes are detected AND decoded, and encoded too.
%%
%%     cv_cascade_load(+Path, -C)
%%     cv_detect(+C, +Img, -Rects)                       1.1, 3 neighbours, 30 pixels
%%     cv_detect(+C, +Img, +Scale, +MinNeighbors, +MinSize, -Rects)
%%     cv_hog_people(+Img, -Rects)
%%     cv_qr_encode(+Text, -Img)   cv_qr_detect(+Img, -Text, -Corners)   fails when there is none
%%     cv_paste(+Img, +Patch, +[X, Y])                   ON Img
%%
%% The photographs are the three pedestrian pictures the tensor lessons
%% use; detections are printed, not pinned to a count -- a detector's
%% output is not a fact about the language.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- a cascade from OpenCV's own data directory~n"),
    cv_data_dir(D), atom_concat(D, '/haarcascades/haarcascade_fullbody.xml', Body),
    ( exists_file(Body) -> Have = yes ; Have = no ),
    (   Have == yes
    ->  cv_cascade_load(Body, C), show('loaded', Body),
        forall(photo(K, P),
               (cv_imread(P, I), cv_detect(C, I, Rs), length(Rs, NR),
                cv_detect(C, I, 1.03, 1, 40, Rs2), length(Rs2, NR2),
                format("   photo ~w: ~w bodies at the defaults, ~w when told to look harder~n", [K, NR, NR2]),
                cv_free(I))),
        photo(1, P1), cv_imread(P1, I1), cv_detect(C, I1, 1.03, 1, 40, Found), length(Found, NFound),
        ( NFound >= 1 -> Any = at_least_one ; Any = NFound ), must('the first photo yields a detection when told to look harder', Any, at_least_one),
        forall(member(R, Found), cv_rectangle(I1, R, green, 2)),
        out('18-cascade.png', Path), cv_imwrite(Path, I1), show('written', Path),
        cv_free_all([C, I1])
    ;   format("   (no haarcascades beside this OpenCV: set OPENCV_DATA to a directory holding haarcascades/)~n")
    ),
    catch(cv_cascade_load('/no/such/cascade.xml', _), error(cocolog_error(Msg), _), true),
    show('a cascade that is not there', Msg),

    format("~n-- the HOG people detector~n"),
    forall(photo(K2, P2),
           (cv_imread(P2, I2), cv_hog_people(I2, People), length(People, NPeople),
            format("   photo ~w: ~w people~n", [K2, NPeople]), cv_free(I2))),

    format("~n-- QR codes: made here, read back, and found inside a bigger picture~n"),
    % Ubuntu 22.04's OpenCV 4.5.4 has no cv::QRCodeEncoder; there cv_qr_encode
    % says so, and the round trip below is skipped -- the detector still runs.
    ( catch(cv_qr_encode('https://github.com/saman-pasha/cocolog', Qr), error(cocolog_error(_), _), fail)
    ->
    cv_shape(Qr, [QS, QS, 1]), show('a QR code, pixels a side', QS),
    cv_resize(Qr, 4, nearest, QrBig), cv_make_border(QrBig, 16, 16, 16, 16, constant, 255, Padded),
    cv_qr_detect(Padded, Text, Corners),
    must('decoded', Text, 'https://github.com/saman-pasha/cocolog'),
    length(Corners, NC), must('with its four corners', NC, 4),
    format("   (the encoder answers the modules alone, one pixel each; a reader wants~n"),
    format("    them a few pixels wide and a white QUIET ZONE around them, which~n"),
    format("    cv_resize/4 with nearest and cv_make_border/8 supply -- and not too~n"),
    format("    wide: at eight pixels a module this detector gives up)~n"),
    ( cv_qr_detect(Qr, _, _) -> Raw = read ; Raw = failed ), must('the raw 33-pixel code is too small to read', Raw, failed),
    scene(Sc), cv_resize(Sc, [200, 200], Sc2), cv_cvt_color(Padded, gray2bgr, Qr3), cv_shape(Qr3, [QB, QB, 3]),
    cv_new(400, 400, '8uc3', [40, 40, 40], Big), cv_paste(Big, Sc2, [0, 0]), cv_paste(Big, Qr3, [220, 220]),
    cv_qr_detect(Big, Text2, [[CX, CY]|_]), must('found in the composite too', Text2, 'https://github.com/saman-pasha/cocolog'),
    ( CX >= 220, CY >= 220, CX =< 220 + QB, CY =< 220 + QB -> Where = where_it_was_pasted ; Where = [CX, CY] ),
    must('at the place it was pasted', Where, where_it_was_pasted),
    format("   (OpenCV's plain QR detector is particular about how much of the frame the~n"),
    format("    code fills; the Aruco-based one in newer builds is steadier. When a code~n"),
    format("    is not found, resize the picture and try again -- that is what apps do.)~n"),
    ( cv_qr_detect(Sc, _, _) -> NoQr = found_something ; NoQr = failed ), must('and cv_qr_detect fails on a picture with none', NoQr, failed),
    out('18-qr.png', Path2), cv_imwrite(Path2, Big), show('written', Path2),

    cv_free_all([Qr, QrBig, Padded, Sc, Sc2, Qr3, Big])
    ;
    format("   (this OpenCV was built without cv::QRCodeEncoder, as Ubuntu 22.04's~n"),
    format("    4.5.4 is; the round trip is skipped here. The detector is unaffected:)~n"),
    scene(Sc0), ( cv_qr_detect(Sc0, _, _) -> NoQr0 = found_something ; NoQr0 = failed ),
    must('cv_qr_detect fails on a picture with no code', NoQr0, failed), cv_free(Sc0)
    ),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

photo(1, 'tutorials/tensor/42-detection-1.jpg').
photo(2, 'tutorials/tensor/42-detection-2.jpg').
photo(3, 'tutorials/tensor/42-detection-3.jpg').

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

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
