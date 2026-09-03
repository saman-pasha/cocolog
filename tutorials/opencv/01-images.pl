%% OPENCV 01 -- images: what one is, how it gets in and out
%%
%%     ./cocolog run tutorials/opencv/01-images.pl main
%%
%% TIER 2: `use_module(library(opencv))', a `.so' from `modules/opencv'
%% (`sh modules/opencv/build.sh'; its header says where an OpenCV comes
%% from). Every file in this directory mirrors one lesson of OpenCV's own
%% tutorial index -- this one is "Mat, the basic image container" and
%% "reading, writing and encoding images" together -- written as cocolog.
%%
%% AN IMAGE IS A HANDLE: an integer naming a cv::Mat the module holds, as
%% a tensor is a handle in library(torch). Every predicate is one OpenCV
%% call on the images behind the handles and answers what OpenCV answered:
%% a new image as a new handle, numbers as numbers, points and rectangles
%% as lists. Nothing is mutated unless the header says ON Img (drawing,
%% cv_set/4, cv_flood_fill/3, cv_watershed/2). What is not freed stays,
%% and cv_handles/1 counts it -- the last claim of every file here is that
%% the count is back to zero.
%%
%% THE SURFACE THIS FILE WALKS:
%%
%%     cv_version/1  cv_data_dir/1  cv_handles/1
%%     cv_new(+Rows, +Cols, +Type, -Img)   cv_new(+Rows, +Cols, +Type, +Color, -Img)
%%     cv_shape/2  cv_type/2  cv_clone/2  cv_free/1  cv_free_all/1
%%     cv_to_list/2  cv_from_list/3  cv_get/4  cv_set/4  cv_roi/3
%%     cv_convert/3  cv_convert/5  cv_scale/3
%%     cv_imread/2  cv_imread/3  cv_imwrite/2  cv_encode/3  cv_decode/2
%%
%% A TYPE is the depth and the channels as one atom -- 8u, 8uc3, 16s,
%% 32f, 32fc2, 64f -- and a COLOR is [B, G, R] in OpenCV's order, one
%% number for grey, or a name cv_color/2 knows (red, green, blue, white,
%% black, yellow, cyan, magenta, gray, orange, purple).

:- use_module(library(opencv)).
:- use_module(library(process)).

main :-
    ensure_out,
    cv_version(V), show('OpenCV', V),
    cv_data_dir(D), show('its data directory (the haarcascades)', D),

    format("~n-- an image is rows by columns by channels, of a depth~n"),
    cv_new(4, 6, '8uc3', I),
    cv_shape(I, S), must('cv_shape/2 answers [Rows, Cols, Channels]', S, [4, 6, 3]),
    cv_type(I, T), must('cv_type/2 answers the type it was made with', T, '8uc3'),
    cv_get(I, 0, 0, P0), must('cv_new/4 makes zeros; a pixel is a list per channel', P0, [0, 0, 0]),
    cv_set(I, 1, 2, [255, 128, 0]),
    cv_get(I, 1, 2, P1), must('cv_set/4 writes ON the image, cv_get/4 reads back', P1, [255, 128, 0]),
    cv_new(2, 2, '8u', white, W),
    cv_get(W, 0, 0, PW), must('one channel: a pixel is one number', PW, 255),

    format("~n-- to_list and from_list: the whole image as terms~n"),
    cv_from_list([[1, 2, 3], [4, 5, 6]], '8u', M),
    cv_to_list(M, L), must('rows of values round-trip', L, [[1, 2, 3], [4, 5, 6]]),
    cv_from_list([[[1, 2, 3], [4, 5, 6]]], '8uc3', M3),
    cv_shape(M3, S3), must('rows of channel lists make a colour image', S3, [1, 2, 3]),
    cv_from_list([[1.5, 2.5]], '64f', F),
    cv_to_list(F, FL), must('a float depth keeps its floats', FL, [[1.5, 2.5]]),
    cv_to_list(M, IL), IL = [[X|_]|_],
    ( integer(X) -> IsInt = yes ; IsInt = no ),
    must('an integer depth answers integers', IsInt, yes),

    format("~n-- convert changes the depth; scale multiplies; saturation is the rule~n"),
    cv_convert(M, '32f', Mf), cv_type(Mf, Tf), must('cv_convert/3', Tf, '32f'),
    cv_scale(M, 100, Big), cv_to_list(Big, BL),
    must('cv_scale/3 saturates at 255 in 8u', BL, [[100, 200, 255], [255, 255, 255]]),
    cv_convert(M, '8u', 2, 10, Aff), cv_to_list(Aff, AL),
    must('cv_convert/5 is V * Alpha + Beta', AL, [[12, 14, 16], [18, 20, 22]]),

    format("~n-- a region is a copy; a clone is a copy of everything~n"),
    cv_roi(M, [1, 0, 2, 2], R), cv_to_list(R, RL),
    must('cv_roi/3 takes [X, Y, W, H], x before y', RL, [[2, 3], [5, 6]]),
    cv_clone(M, C), cv_set(C, 0, 0, 99), cv_get(M, 0, 0, Orig),
    must('writing on the clone leaves the original alone', Orig, 1),

    format("~n-- files: written by suffix, read by path~n"),
    scene(Sc),
    out('01-scene.png', Path), cv_imwrite(Path, Sc),
    cv_imread(Path, Back), cv_shape(Back, BS), must('cv_imread/2 reads what cv_imwrite/2 wrote', BS, [256, 256, 3]),
    cv_imread(Path, gray, G), cv_shape(G, GS), must('cv_imread/3 with gray gives one channel', GS, [256, 256, 1]),
    show('written', Path),
    photo(Ph), cv_imread(Ph, Photo), cv_shape(Photo, PS), PS = [PR, PC, 3],
    show('a real photograph, rows by cols', PR-PC),

    format("~n-- encode and decode: the file format as a list of bytes~n"),
    cv_encode('.png', M, Bytes), Bytes = [B0, B1, B2, B3|_],
    must('a PNG starts with its signature', [B0, B1, B2, B3], [137, 80, 78, 71]),
    cv_decode(Bytes, Dec), cv_to_list(Dec, DL), must('cv_decode/2 gives the image back', DL, [[1, 2, 3], [4, 5, 6]]),

    format("~n-- what a bad argument does: an error you can catch, in OpenCV's words~n"),
    catch(cv_shape(12345, _), error(cocolog_error(Msg), _), true),
    show('cv_shape on a dead handle', Msg),
    catch(cv_new(1, 1, '7u', _), error(cocolog_error(Msg2), _), true),
    show('an unknown type', Msg2),

    cv_free_all([I, W, M, M3, F, Mf, Big, Aff, R, C, Sc, Back, G, Photo, Dec]),
    cv_handles(N), must('every handle freed', N, 0),
    format("~ndone~n").

%% A synthetic scene every file here draws the same way: a grey ground, a
%% red disc, a green box, a blue triangle and a line -- enough structure
%% for edges, contours, histograms and features to find something.
scene(I) :-
    cv_new(256, 256, '8uc3', [40, 40, 40], I),
    cv_circle(I, [72, 80], 40, red, -1),
    cv_rectangle(I, [140, 40, 80, 80], green, -1),
    cv_fill_poly(I, [[60, 230], [128, 150], [196, 230]], blue),
    cv_line(I, [10, 245], [246, 245], white, 3),
    cv_put_text(I, cocolog, [150, 140], 0.6, yellow, 2).

photo('tutorials/tensor/42-detection-1.jpg').

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
