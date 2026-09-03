%% LIBRARY 41 -- library(opencv): images as handles, OpenCV as predicates
%%
%%     ./cocolog run tutorials/library/41-opencv.pl main
%%
%% TIER 2: `use_module(library(opencv))', a `.so' from `modules/opencv'.
%% It needs an OpenCV 4 with its dnn, objdetect, features2d, photo, video,
%% videoio and calib3d modules: `sh modules/opencv/build.sh' (its header
%% says where one comes from -- the distribution's package on Linux, a
%% source build into ~/opencv4 on a Mac without a bottle).
%%
%% WHAT THE MODULE IS. An image is a HANDLE -- an integer naming a
%% cv::Mat in the module's table, as a tensor is in library(torch) -- and
%% every predicate is one OpenCV call on the images behind the handles,
%% answering what OpenCV answered: an image as a new handle, numbers as
%% numbers, points, rectangles and matrices as lists. Nothing is mutated
%% except by the drawing predicates and the few that say ON Img. The
%% module is ONE Cicili `:cpp #t' file: the C++ calls are Cicili clauses
%% over the declaration binding in cicili/lib/cpp/opencv, which is the
%% standard shape for a C++ library here.
%%
%% THIS LESSON IS THE DOORWAY. The course is tutorials/opencv/ -- twenty-
%% three files mirroring OpenCV's own tutorial index, from reading an
%% image to running YOLO -- and this file shows the shape of the surface
%% once, on a picture it draws itself, so the doorway is a test too.
%%
%%     cv_imread/2 cv_imwrite/2 cv_new/4 cv_shape/2 cv_type/2 cv_get/4 cv_to_list/2
%%     cv_gray/2 cv_threshold/5 cv_find_contours/4 cv_contour_area/2
%%     cv_bounding_rect/2 cv_rectangle/4 cv_put_text/6 cv_free/1 cv_handles/1

:- use_module(library(opencv)).

main :-
    cv_version(V), show('OpenCV', V),

    format("~n-- an image is a handle; its shape is [Rows, Cols, Channels]~n"),
    cv_new(120, 160, '8uc3', [40, 40, 40], I),
    cv_shape(I, S), must('cv_shape/2', S, [120, 160, 3]),
    cv_type(I, T), must('cv_type/2: depth and channels in one atom', T, '8uc3'),
    cv_circle(I, [50, 60], 30, red, -1),
    cv_rectangle(I, [100, 30, 40, 60], green, -1),
    cv_get(I, 60, 50, P), must('a pixel is [B, G, R]', P, [0, 0, 255]),

    format("~n-- a pipeline is a conjunction: grey, threshold, contours~n"),
    cv_gray(I, G), cv_threshold(G, 60, 255, binary, E),
    cv_find_contours(E, external, simple, Cs), length(Cs, NC),
    must('two shapes, two outer contours', NC, 2),
    findall(A-R, (member(C, Cs), cv_contour_area(C, A0), A is round(A0), cv_bounding_rect(C, R)), Found), msort(Found, Sorted),
    show('area and bounding box of each', Sorted),
    ( member(_-[100, 30, 40, 60], Found) -> Box = found ; Box = Found ), must('the rectangle where it was drawn', Box, found),
    ( member(_-[Rx, Ry, Rw, Rh], Found), Rx < 30, Ry < 40, Rw > 55, Rh > 55 -> Disc = found ; Disc = Found ),
    must('and the disc, 60 across', Disc, found),
    forall(member(_-Rc, Found), cv_rectangle(I, Rc, yellow, 1)),
    cv_put_text(I, 'library(opencv)', [5, 110], 0.5, white, 1),
    cv_imwrite('/tmp/cocolog-library-41.png', I), show('written', '/tmp/cocolog-library-41.png'),

    format("~n-- an error is an error term in OpenCV's words~n"),
    catch(cv_gray(999, _), error(cocolog_error(Msg), _), true), show('caught', Msg),

    cv_free_all([I, G, E]),
    cv_handles(N), must('everything freed', N, 0),
    format("~n   The course: tutorials/opencv/01-images.pl and on, twenty-three lessons.~n"),
    format("~ndone~n").

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
