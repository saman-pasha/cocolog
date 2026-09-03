%% OPENCV 04 -- colour spaces: BGR, grey, HSV, Lab, and picking a colour out
%%
%%     ./cocolog run tutorials/opencv/04-color-spaces.pl main
%%
%% OpenCV's "Changing Colorspaces" lesson, and the reason it is taught
%% early: segmenting by colour is hopeless in BGR, where a shadow changes
%% all three numbers, and nearly trivial in HSV, where it changes only V.
%%
%%     cv_cvt_color(+Img, +Code, -Out)
%%       bgr2gray gray2bgr bgr2rgb rgb2bgr bgr2hsv hsv2bgr bgr2lab lab2bgr
%%       bgr2ycrcb ycrcb2bgr bgr2hls hls2bgr bgr2luv luv2bgr bgr2xyz xyz2bgr
%%       bgr2bgra bgra2bgr rgb2gray gray2rgb
%%     cv_gray(+Img, -Gray)                       the shorthand for bgr2gray
%%     cv_in_range(+Img, +Lo, +Hi, -Mask)
%%
%% OpenCV's 8-bit HSV puts hue in 0..179 (degrees halved), so red is 0,
%% green 60, blue 120; saturation and value fill 0..255.

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    format("~n-- grey is a weighted sum, and the weights are the eye's~n"),
    cv_from_list([[[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 255]]], '8uc3', Prim),
    cv_gray(Prim, G), cv_to_list(G, GL),
    must('blue, green, red, white to grey: 0.114, 0.587, 0.299 of 255', GL, [[29, 150, 76, 255]]),
    cv_cvt_color(Prim, bgr2rgb, Rgb), cv_get(Rgb, 0, 0, Rv), must('bgr2rgb swaps the ends', Rv, [0, 0, 255]),
    cv_cvt_color(G, gray2bgr, Back), cv_shape(Back, BS), must('gray2bgr triples the channel', BS, [1, 4, 3]),

    format("~n-- HSV: hue names the colour, whatever the light does~n"),
    cv_cvt_color(Prim, bgr2hsv, Hsv), cv_to_list(Hsv, [[HB, HG, HR, HW]]),
    must('pure blue', HB, [120, 255, 255]),
    must('pure green', HG, [60, 255, 255]),
    must('pure red', HR, [0, 255, 255]),
    must('white: no saturation, full value, hue meaningless (0)', HW, [0, 0, 255]),
    cv_from_list([[[0, 0, 255], [0, 0, 120]]], '8uc3', Reds),
    cv_cvt_color(Reds, bgr2hsv, RedsH), cv_to_list(RedsH, [[Bright, Dark]]),
    Bright = [H1, S1, _], Dark = [H2, S2, _],
    must('a dark red keeps hue and saturation; only V drops', [H1, S1]-[H2, S2], [0, 255]-[0, 255]),

    format("~n-- Lab: perceptual, with white at the centre of a and b~n"),
    cv_cvt_color(Prim, bgr2lab, Lab), cv_to_list(Lab, [[_, _, _, LabW]]),
    must('white is L = 255, a = b = 128', LabW, [255, 128, 128]),

    format("~n-- segmenting the red disc of the scene by hue~n"),
    scene(Sc), cv_cvt_color(Sc, bgr2hsv, ScH),
    cv_in_range(ScH, [0, 120, 70], [10, 255, 255], Low),
    cv_in_range(ScH, [170, 120, 70], [180, 255, 255], High),
    cv_or(Low, High, RedMask),
    cv_count_nonzero(RedMask, Area),
    show('pixels the red mask keeps', Area),
    ( Area > 4700, Area < 5500 -> Disc = about_pi_r_squared ; Disc = Area ),
    must('a disc of radius 40 is about 5027 pixels', Disc, about_pi_r_squared),
    cv_in_range(ScH, [50, 120, 70], [70, 255, 255], GreenMask),
    cv_count_nonzero(GreenMask, GArea), must('and the green box is exactly 80 by 80', GArea, 6400),

    format("~n-- the mask cuts the disc out of the picture~n"),
    cv_cvt_color(RedMask, gray2bgr, M3), cv_and(Sc, M3, Cut),
    cv_hconcat([Sc, Cut], Side), out('04-red-mask.png', Path), cv_imwrite(Path, Side), show('written', Path),
    photo(P), cv_imread(P, Ph), cv_cvt_color(Ph, bgr2hsv, PhH), cv_split(PhH, [Hc, Sch, Vch]),
    cv_hconcat([Hc, Sch, Vch], Planes), out('04-hsv-planes.png', Path2), cv_imwrite(Path2, Planes),
    show('a photograph as its H, S and V planes', Path2),

    cv_free_all([Prim, G, Rgb, Back, Hsv, Reds, RedsH, Lab, Sc, ScH, Low, High, RedMask, GreenMask, M3, Cut, Side,
                 Ph, PhH, Hc, Sch, Vch, Planes]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

photo('tutorials/tensor/42-detection-3.jpg').
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
