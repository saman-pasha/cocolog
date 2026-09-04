%% library(opencv): OpenCV as cocolog predicates, images as handles.
%%
%% WHAT IS BEING PINNED, in the order the module's header lists it:
%%
%%   AN IMAGE IS A HANDLE with a shape and a type; what goes in as rows
%%   comes out as the same rows; a pixel reads and writes; a region is a
%%   copy; a file written is a file read; a PNG encodes to its signature
%%   and decodes back.
%%
%%   ARITHMETIC SATURATES, colour conversion uses OpenCV's weights, a
%%   threshold is what the type says, a contour has the area and box of
%%   what was drawn, a template is found where it was cut, a QR code made
%%   here reads back, a homography from four exact pairs is exact.
%%
%%   A VIDEO WRITTEN IS A VIDEO READ, frame for frame, and reading fails
%%   at the end. A dnn forward pass runs when a model is beside the
%%   tutorials (tutorials/opencv/22-dnn-classification.pl download), and
%%   is a skipped line when it is not.
%%
%%   ERRORS ARE TERMS: a dead handle, a wrong type and a missing file each
%%   raise error(cocolog_error(Text), _) with OpenCV's words, catchable.
%%
%%   NOTHING LEAKS: every handle a section makes is freed, and cv_handles
%%   answers 0 at the end -- and in ONE process that is now a claim about
%%   the whole case, where each of the .sh's thirty-odd processes could
%%   only vouch for itself.
%%
%%     cocolog -s test/opencv.pl        from the checkout root
%%
%% SKIPs without library/opencv.so (sh modules/opencv/build.sh says what it
%% needs: an OpenCV 4 found through pkg-config).

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(opencv)), _, fail)
    ->  true
    ;   skip('(no library/opencv.so -- sh modules/opencv/build.sh)')
    ),
    (   catch(( cv_new(1, 1, '8u', I0), cv_free(I0) ), _, fail)
    ->  true
    ;   skip('(library(opencv) does not start: is the OpenCV it was built against still here?)')
    ),
    scratch(D),
    a_handle(D), arithmetic, resampling, shapes, video(D), dnn, errors, leaks,
    shl(['rm -rf ', D]),
    checks_done.

a_handle(D) :-
    section('an image is a handle'),
    written(( cv_new(4, 6, '8uc3', I1), cv_shape(I1, S1), cv_type(I1, T1), cv_free(I1) ), S1-T1, G1),
    check('cv_new: shape [Rows, Cols, Channels] and the type it was made with', G1, '[4,6,3]-8uc3'),
    written(( cv_from_list([[1,2,3],[4,5,6]], '8u', A2), cv_to_list(A2, L2),
              cv_from_list([[1.5]], '64f', B2), cv_to_list(B2, M2), cv_free_all([A2,B2]) ), L2-M2, G2),
    check('rows in, the same rows out; a float depth keeps floats', G2, '[[1,2,3],[4,5,6]]-[[1.5]]'),
    written(( cv_new(2, 2, '8uc3', I3), cv_set(I3, 1, 0, [7,8,9]), cv_get(I3, 1, 0, P3),
              cv_get(I3, 0, 0, Z3), cv_free(I3) ), P3-Z3, G3),
    check('cv_get and cv_set, a pixel per channel', G3, '[7,8,9]-[0,0,0]'),
    written(( cv_from_list([[1,2,3],[4,5,6]], '8u', A4), cv_roi(A4, [1,0,2,2], R4),
              cv_to_list(R4, L4), cv_free_all([A4,R4]) ), L4, G4),
    check('cv_roi copies [X, Y, W, H], x first', G4, '[[2,3],[5,6]]'),
    atom_concat(D, '/a.png', Png),
    written(( cv_new(3, 5, '8uc3', [10,20,30], I5), cv_imwrite(Png, I5), cv_imread(Png, J5),
              cv_imread(Png, gray, Gr5), cv_get(J5, 0, 0, P5), cv_shape(Gr5, S5),
              cv_free_all([I5,J5,Gr5]) ), P5-S5, G5),
    check('imwrite then imread, and gray on the way back', G5, '[10,20,30]-[3,5,1]'),
    %% (Sig0..Sig3, not B0..B3: B2 is the 64f handle four checks up, and a
    %% clause has one scope -- the byte would have been unified with a handle)
    written(( cv_from_list([[1,2],[3,4]], '8u', A6), cv_encode('.png', A6, [Sig0,Sig1,Sig2,Sig3|_]),
              cv_encode('.png', A6, Bs6), cv_decode(Bs6, D6), cv_to_list(D6, L6),
              cv_free_all([A6,D6]) ), [Sig0,Sig1,Sig2,Sig3]-L6, G6),
    check('a PNG starts with its signature and decodes back', G6, '[137,80,78,71]-[[1,2],[3,4]]').

arithmetic :-
    section('arithmetic, colour, threshold'),
    written(( cv_from_list([[200,100,0]], '8u', A1), cv_from_list([[100,100,100]], '8u', B1),
              cv_add(A1, B1, S1), cv_sub(A1, B1, D1), cv_to_list(S1, SL1), cv_to_list(D1, DL1),
              cv_free_all([A1,B1,S1,D1]) ), SL1-DL1, G1),
    check('8u arithmetic saturates', G1, '[[255,200,100]]-[[100,0,0]]'),
    written(( cv_from_list([[[255,0,0],[0,255,0],[0,0,255],[255,255,255]]], '8uc3', P2),
              cv_gray(P2, Gr2), cv_to_list(Gr2, L2), cv_free_all([P2,Gr2]) ), L2, G2),
    check('blue, green, red, white to grey with OpenCV''s weights', G2, '[[29,150,76,255]]'),
    written(( cv_from_list([[[255,0,0],[0,255,0],[0,0,255]]], '8uc3', P3),
              cv_cvt_color(P3, bgr2hsv, H3), cv_to_list(H3, [[[HB|_],[HG|_],[HR|_]]]),
              cv_free_all([P3,H3]) ), [HR,HG,HB], G3),
    check('HSV hue: red 0, green 60, blue 120', G3, '[0,60,120]'),
    written(( cv_from_list([[0,50,100,150,200,250]], '8u', V4),
              findall(L4, ( member(T4, [binary,binary_inv,trunc,tozero,tozero_inv]),
                            cv_threshold(V4, 100, 255, T4, O4), cv_to_list(O4, [L4]), cv_free(O4) ), Ls4),
              cv_free(V4) ), Ls4, G4),
    check('the five threshold types at T = 100', G4,
          '[[0,0,0,255,255,255],[255,255,255,0,0,0],[0,50,100,100,100,100],[0,0,0,150,200,250],[0,50,100,0,0,0]]'),
    written(( cv_from_list([[5,1],[9,3]], '8u', Q5), cv_mean(Q5, M5),
              cv_minmax(Q5, Lo5, Hi5, LoAt5, HiAt5), cv_count_nonzero(Q5, N5), cv_free(Q5) ),
            M5-Lo5-Hi5-LoAt5-HiAt5-N5, G5),
    check('mean, minmax with locations, count_nonzero', G5, '[4.5]-1.0-9.0-[1,0]-[0,1]-4').

resampling :-
    section('resampling: Pillow''s filters, vendored; the numbers are Pillow 11.3.0''s own'),
    written(( cv_from_list([[0,0,255,255]], '8u', A1), cv_resample(A1, [2,1], box, B1),
              cv_to_list(B1, L1), cv_free_all([A1,B1]) ), L1, G1),
    check('box halves [0,0,255,255] to [0,255]', G1, '[[0,255]]'),
    written(( cv_from_list([[0,0,255,255]], '8u', A2),
              findall(V2, ( member(F2, [bilinear,hamming,bicubic,lanczos]),
                            cv_resample(A2, [2,1], F2, B2), cv_to_list(B2, [V2]), cv_free(B2) ), Vs2),
              cv_free(A2) ), Vs2, G2),
    check('bilinear, hamming, bicubic, lanczos on the same row', G2, '[[36,219],[10,245],[21,234],[18,237]]'),
    written(( cv_from_list([[0,16,32,48],[64,80,96,112],[128,144,160,176],[192,208,224,240]], '8u', A3),
              cv_resample(A3, [2,2], bilinear, B3), cv_to_list(B3, L3), cv_free_all([A3,B3]) ), L3, G3),
    check('bilinear on a 4x4 ramp to 2x2', G3, '[[57,83],[157,183]]'),
    written(( cv_from_list([[0,255]], '8u', A4), cv_resample(A4, [6,1], bilinear, B4),
              cv_to_list(B4, [L4]), cv_free_all([A4,B4]) ), L4, G4),
    check('bilinear upscales too: [0,255] to six', G4, '[0,0,85,170,255,255]'),
    written(( cv_from_list([[[0,255,0],[0,255,0],[255,0,255],[255,0,255]]], '8uc3', A5),
              cv_resample(A5, [2,1], bilinear, B5), cv_to_list(B5, L5), cv_free_all([A5,B5]) ), L5, G5),
    check('three channels are three bands, each resampled alone', G5, '[[[36,219,36],[219,36,219]]]'),
    written(( cv_from_list([[9,0,0,255,255,9]], '8u', A6), cv_roi(A6, [1,0,4,1], R6),
              cv_resample(R6, [2,1], bilinear, B6), cv_to_list(B6, L6), cv_free_all([A6,R6,B6]) ), L6, G6),
    check('a view of a bigger picture resamples as itself', G6, '[[36,219]]'),
    written(( cv_from_list([[1,2]], '8u', A7),
              catch(cv_resample(A7, [1,1], nearest, _), error(cocolog_error(M7), _), true),
              cv_free(A7) ), M7, G7),
    check('an unknown filter is a domain error', G7, 'opencv: unknown resampling filter: nearest').

shapes :-
    section('shapes'),
    written(( cv_new(100, 100, '8u', 0, I1), cv_rectangle(I1, [20,20,40,30], 255, -1),
              cv_find_contours(I1, external, simple, [C1]), cv_contour_area(C1, A1),
              cv_bounding_rect(C1, R1), cv_free(I1) ), A1-R1, G1),
    check('a filled 40 by 30 rectangle: one contour, its box, its pixel-polygon area', G1, '1131.0-[20,20,40,30]'),
    written(( cv_new(30, 30, '8u', 0, S2), cv_rectangle(S2, [10,10,10,10], 255, -1),
              cv_erode(S2, 3, E2), cv_dilate(S2, 3, D2), cv_count_nonzero(E2, NE2),
              cv_count_nonzero(D2, ND2), cv_free_all([S2,E2,D2]) ), NE2-ND2, G2),
    check('erode and dilate a 10 by 10 square by a 3 by 3', G2, '64-144'),
    written(( cv_new(64, 64, '8uc3', [40,40,40], I3), cv_circle(I3, [30,30], 10, red, -1),
              cv_roi(I3, [20,20,20,20], T3), cv_match_template(I3, T3, ccoeff_normed, R3),
              cv_minmax(R3, _, _, _, At3), cv_free_all([I3,T3,R3]) ), At3, G3),
    check('a template is found where it was cut', G3, '[20,20]'),
    written(cv_affine_transform([[0,0],[10,0],[0,10]], [[5,3],[15,3],[5,13]], M4), M4, G4),
    check('an affine map from three pairs is exact', G4, '[[1.0,0.0,5.0],[0.0,1.0,3.0]]'),
    written(( cv_perspective_transform([[0,0],[100,0],[100,100],[0,100]], [[0,0],[200,0],[200,200],[0,200]], M5),
              cv_transform_points([[10,20]], M5, P5) ), P5, G5),
    check('a homography from a doubling doubles a point', G5, '[[20.0,40.0]]'),
    %% Ubuntu 22.04's OpenCV 4.5.4 has no cv::QRCodeEncoder; the module then
    %% says so from cv_qr_encode, and the round trip is a skipped line, not a
    %% red.
    (   catch(cv_qr_encode(x, Q6), error(cocolog_error(_), _), fail)
    ->  cv_free(Q6),
        written(( cv_qr_encode('cocolog', Q6b), cv_resize(Q6b, 6, nearest, B6),
                  cv_qr_detect(B6, T6, Ps6), length(Ps6, N6), cv_free_all([Q6b,B6]) ), T6-N6, G6),
        check('a QR code made here reads back, with four corners', G6, 'cocolog-4')
    ;   format("     (skipped: the QR round trip -- this OpenCV was built without cv::QRCodeEncoder)~n", [])
    ),
    written(( cv_new(128, 128, '8uc3', [40,40,40], I7), cv_rectangle(I7, [30,30,40,50], white, -1),
              cv_circle(I7, [90,80], 20, red, -1), cv_put_text(I7, abc, [10,120], 0.8, yellow, 2),
              cv_features(orb, I7, _, D7), cv_shape(D7, [_,32,1]),
              cv_match(D7, D7, hamming, [[Q7,T7,Dist7]|_]),
              ( integer(Q7), integer(T7), Dist7 =:= 0 -> R7 = self_match ; R7 = [Q7,T7,Dist7] ),
              cv_free_all([I7,D7]) ), R7, G7),
    check('ORB descriptors: 32 bytes per keypoint, matches index them as integers', G7, self_match).

video(D) :-
    section('video'),
    atom_concat(D, '/v.avi', Avi),
    written(( cv_video_writer(Avi, 'MJPG', 10.0, [64,48], W1),
              forall(between(1, 12, K1), ( cv_new(48, 64, '8uc3', [K1,K1,K1], F1), cv_video_write(W1, F1), cv_free(F1) )),
              cv_free(W1), cv_video_open(Avi, V1), cv_video_prop(V1, frames, NF1),
              forall(between(1, 12, _), ( cv_video_read(V1, Fr1), cv_free(Fr1) )),
              ( cv_video_read(V1, _) -> E1 = more ; E1 = ended ), cv_free(V1) ), NF1-E1, G1),
    check('twelve frames written are twelve frames read, and then reading fails', G1, '12.0-ended'),
    written(( cv_bgsub_new(mog2, B2),
              forall(between(0, 9, K2), ( cv_new(60, 80, '8uc3', [90,90,90], F2), X2 is 10 + 4 * K2,
                                          cv_rectangle(F2, [X2,20,16,16], white, -1),
                                          cv_bgsub_apply(B2, F2, M2), cv_free_all([F2,M2]) )),
              cv_new(60, 80, '8uc3', [90,90,90], Gd2), cv_rectangle(Gd2, [50,20,16,16], white, -1),
              cv_bgsub_apply(B2, Gd2, Mk2), cv_roi(Mk2, [0,0,8,60], L2), cv_count_nonzero(Mk2, N2),
              cv_count_nonzero(L2, NL2), cv_free_all([B2,Gd2,Mk2,L2]),
              ( N2 > 50, NL2 =:= 0 -> R2 = mover_only ; R2 = N2-NL2 ) ), R2, G2),
    check('background subtraction sees a mover and not the ground', G2, mover_only).

dnn :-
    section('dnn'),
    Model = 'tutorials/opencv/models/squeezenet1.1-7.onnx',
    (   exists_file(Model)
    ->  %% the class index belongs to the CURRENT 42-detection-1.jpg -- tutorial 42's
        %% predict redraws the photographs, and a new picture is a new class (602,
        %% 480, 843 so far)
        written(( cv_dnn_read(Model, N1), cv_imread('tutorials/tensor/42-detection-1.jpg', I1),
                  cv_dnn_blob(I1, 0.017353, [224,224], [123.675,116.28,103.53], true, true, B1),
                  cv_dnn_input(N1, B1), cv_dnn_forward(N1, O1), cv_shape(O1, S1), cv_dnn_top(O1, C1, _),
                  cv_free_all([N1,I1,B1,O1]) ), S1-C1, G1),
        check('SqueezeNet forward: 1 by 1000, and the class it names for the walkers', G1, '[1,1000,1]-843')
    ;   format("     (skipped: dnn -- no ~w; ./cocolog run tutorials/opencv/22-dnn-classification.pl download)~n", [Model])
    ).

errors :-
    section('errors are terms'),
    written(catch(cv_shape(12345, _), error(cocolog_error(M1), _), true), M1, G1),
    check('a dead handle', G1, 'opencv: not a live handle: 12345'),
    written(catch(cv_new(1, 1, '7u', _), error(cocolog_error(M2), _), true), M2, G2),
    check('an unknown type names the argument''s fault', G2, 'opencv: unknown image type: 7u'),
    written(catch(cv_imread('/no/such.png', _), error(cocolog_error(M3), _), true), M3, G3),
    check('a missing file, in OpenCV''s words', G3, 'opencv: cannot read image: /no/such.png'),
    written(catch(cv_shape(_, _), error(cocolog_error(M4), _), true), M4, G4),
    check('an unbound argument', G4, 'opencv: argument 1 must be bound').

leaks :-
    section('nothing leaks'),
    written(( cv_new(2, 2, '8uc3', A1), cv_gray(A1, Gr1), cv_split(A1, Cs1), cv_free_all([A1, Gr1|Cs1]),
              ( catch(cv_qr_encode(x, Q1), _, fail) -> cv_free(Q1) ; true ),
              cv_handles(N1) ), N1, G1),
    check('cv_handles is 0 after a case that made and freed', G1, '0').
