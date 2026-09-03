%% OPENCV 20 -- video: frames in and out, background subtraction, optical flow
%%
%%     ./cocolog run tutorials/opencv/20-video.pl main
%%
%% OpenCV's videoio and video lessons: "Video Input", "Creating a video",
%% "How to Use Background Subtraction Methods", "Optical Flow". A video
%% is a handle that answers one frame per cv_video_read/2 and FAILS at
%% the end, which makes the reading loop a recursion that stops on failure;
%% a writer takes frames of the size it was opened with. The moving
%% picture here is made in the file: a square sliding right.
%%
%%     cv_video_writer(+Path, +Fourcc, +Fps, +[W, H], -W)   cv_video_write(+W, +Img)
%%     cv_video_open(+Path, -V)   cv_video_read(+V, -Frame)   cv_video_prop(+V, +Prop, -Value)
%%     cv_video_close(+V)                                  the same as cv_free
%%     cv_bgsub_new(+Kind, -B)   cv_bgsub_apply(+B, +Frame, -Mask)     mog2 | knn
%%     cv_optical_flow(+Prev, +Next, -Flow)                Farneback, dense, 32fc2
%%     cv_flow_polar(+Flow, -Magnitude, -Angle)            degrees
%%     cv_optical_flow_lk(+Prev, +Next, +Pts, -Pts2, -Status)   sparse, Lucas-Kanade

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- writing twelve frames, reading them back~n"),
    out('20-square.avi', Path), cv_video_writer(Path, 'MJPG', 12.0, [160, 120], W),
    forall(between(0, 11, K), (frame(K, F), cv_video_write(W, F), cv_free(F))),
    cv_free(W),
    cv_video_open(Path, V),
    cv_video_prop(V, frames, NF), must('the count', NF, 12.0),
    cv_video_prop(V, fps, Fps), must('the rate', Fps, 12.0),
    cv_video_prop(V, width, Wd), cv_video_prop(V, height, Ht), must('the size', [Wd, Ht], [160.0, 120.0]),
    read_all(V, Shapes), length(Shapes, NRead),
    must('cv_video_read fails at the end, so a recursion reads them all: 12', NRead, 12),
    Shapes = [First|_], must('each a colour frame of the size written', First, [120, 160, 3]),
    ( cv_video_read(V, _) -> More = something ; More = failed ), must('and fails again after the end', More, failed),
    cv_video_close(V),

    format("~n-- background subtraction: the mover is what is left~n"),
    cv_bgsub_new(mog2, Bg),
    forall(between(0, 9, K2), (frame(K2, F2), cv_bgsub_apply(Bg, F2, M2), cv_free_all([F2, M2]))),
    frame(10, F10), cv_bgsub_apply(Bg, F10, Mask), cv_count_nonzero(Mask, NZ), show('foreground pixels on frame 10', NZ),
    ( NZ > 200, NZ < 3000 -> Some = about_the_square_edges ; Some = NZ ), must('the moving square shows, the static ground does not', Some, about_the_square_edges),
    cv_roi(Mask, [0, 0, 20, 120], LeftStrip), cv_count_nonzero(LeftStrip, NLeft), must('nothing where the square never was', NLeft, 0),
    cv_bgsub_new(knn, Bk), frame(0, F0), cv_bgsub_apply(Bk, F0, Mk), cv_shape(Mk, MkS), must('knn answers a mask of the frame size', MkS, [120, 160, 1]),

    format("~n-- dense optical flow: the square moves 4 pixels right per frame~n"),
    frame(5, A), frame(6, B), cv_optical_flow(A, B, Flow), cv_type(Flow, FT), must('the flow is 32fc2: dx, dy per pixel', FT, '32fc2'),
    cv_flow_polar(Flow, Mag, Ang),
    square_at(5, SX, SY), CX is SX + 15, CY is SY + 15,
    cv_get(Flow, CY, CX, [DX, DY]), show('flow at the centre of the square [dx, dy]', [DX, DY]),
    ( DX > 2.5, DX < 5.5, abs(DY) < 1.5 -> Right = about_4_right ; Right = [DX, DY] ), must('about (4, 0)', Right, about_4_right),
    cv_get(Ang, CY, CX, Deg), ( ( Deg < 20 ; Deg > 340 ) -> Dir = rightward ; Dir = Deg ), must('the angle says rightward', Dir, rightward),
    cv_get(Mag, 5, 5, Still), ( Still < 0.5 -> Calm = yes ; Calm = Still ), must('the far corner does not move', Calm, yes),

    format("~n-- sparse flow: tracking three points, one of them on nothing~n"),
    LX is SX + 3, LY is SY + 3, RX is SX + 27, RY is SY + 27,
    cv_optical_flow_lk(A, B, [[LX, LY], [RX, RY], [5, 5]], Pts2, Status),
    show('tracked to', Pts2),
    must('the two corners are found; the point on the flat ground is lost, there is nothing to track', Status, [1, 1, 0]),
    Pts2 = [[LX2, LY2], [RX2, RY2], _],
    ( abs(LX2 - LX - 4) < 1.5, abs(LY2 - LY) < 1.5 -> Moved = four_right ; Moved = [LX2, LY2] ), must('the top-left corner moved four right', Moved, four_right),
    ( abs(RX2 - RX - 4) < 1.5, abs(RY2 - RY) < 1.5 -> Moved2 = four_right ; Moved2 = [RX2, RY2] ), must('and so did the bottom-right', Moved2, four_right),

    format("~n-- the pictures~n"),
    cv_normalize(Mag, 0, 255, minmax, MagN), cv_convert(MagN, '8u', Mag8), cv_colormap(Mag8, jet, MagC),
    cv_cvt_color(Mask, gray2bgr, Mask3), cv_hconcat([F10, Mask3, MagC], Row), out('20-video.png', Path2), cv_imwrite(Path2, Row),
    show('written: a frame, its foreground mask, the flow magnitude', Path2), show('and the video', Path),

    cv_free_all([Bg, F10, Mask, LeftStrip, Bk, F0, Mk, A, B, Flow, Mag, Ang, MagN, Mag8, MagC, Mask3, Row]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% the reading loop: one frame per call, until the call fails. (Not a
%% findall: a C predicate answers once and leaves no choice point to
%% come back to, so the loop has to be a recursion.)
read_all(V, [S|Rest]) :- cv_video_read(V, F), !, cv_shape(F, S), cv_free(F), read_all(V, Rest).
read_all(_, []).

%% frame K: a grey ground with a fixed dark bar and a white square 4 pixels further right each frame
square_at(K, X, 45) :- X is 20 + 4 * K.
frame(K, F) :-
    cv_new(120, 160, '8uc3', [90, 90, 90], F),
    cv_rectangle(F, [0, 100, 160, 20], [50, 50, 50], -1),
    square_at(K, X, Y), cv_rectangle(F, [X, Y, 30, 30], white, -1),
    CX is X + 15, CY is Y + 15, cv_circle(F, [CX, CY], 6, [0, 0, 200], -1).

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
