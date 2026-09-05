# OpenCV: image processing, from clauses

*One of four tutorial categories — `../basics/` is the language, `../library/`
is what ships, `../tensor/` is the deep end of learning, and this is seeing.*

    ./cocolog run tutorials/opencv/01-images.pl main

Every file here is written in `library(opencv)` -- the module under
`modules/opencv`, one Cicili file over OpenCV 4's C++ -- and mirrors one
lesson of OpenCV's own tutorial index, in OpenCV's own order: the core,
imgproc, then features, objdetect, photo, video, calib3d and dnn. The
lessons are what a computer-vision course teaches; the point of writing
them in cocolog is what a course cannot show: that a contour is a Prolog
list, a shape classifier a three-clause predicate, a detection pipeline a
`findall` over rows, and every claim a goal that has to hold.

**An image is a handle**, an integer naming a `cv::Mat` the module owns,
as a tensor is in `library(torch)`. Every predicate is one OpenCV call on
what the handles name and answers what OpenCV answered: a new image as a
new handle, numbers as numbers, points, rectangles and matrices as lists.
Nothing is mutated except by the drawing predicates and the four that say
so in the module's header. What a file makes it frees, and its last claim
is `cv_handles(0)`.

**Vocabulary**, the same in every file: a POINT is `[X, Y]` (column, then
row); a RECT `[X, Y, W, H]`; a SIZE `[W, H]`; a COLOR `[B, G, R]` in
OpenCV's order, a grey level, or a name (`red`, `green`, `blue`, `white`,
`black`, `yellow`, `cyan`, `magenta`, `gray`, `orange`, `purple`); a TYPE
the depth and channels in one atom (`8u`, `8uc3`, `32f`, `32fc2`, `64f`);
a FLAG an atom (`otsu`, `linear`, `external`, `hamming`). A MATRIX is rows
of numbers, so a 2 by 3 affine is `[[A, B, C], [D, E, F]]`.

Each lesson writes what it made to `/tmp/cocolog-opencv/`, so the
pictures can be looked at; the three photographs are the pedestrian
pictures `../tensor/42-detection-*.jpg`, and everything else is drawn in
the file. The two dnn lessons need a model that is NOT in the repository:
each has a `download` goal that fetches it with curl into
`tutorials/opencv/models/` (ignored by git), and `main` says so and ends
when it is missing, so `cocolog -s test/tutorials.pl` stays green offline.

| file | OpenCV lesson | teaches |
|---|---|---|
| 01-images | Mat; reading and writing | handles, shape and type, `cv_get/4`, `cv_to_list/2`, files and byte encodings, errors in OpenCV's words |
| 02-drawing | Basic Drawing | the primitives that draw ON an image, and reading the pixels back |
| 03-arithmetic | Operations with images; blending | saturating arithmetic, blending, masks, statistics, rearranging |
| 04-color-spaces | Changing Colorspaces | grey as a weighted sum, HSV hue in 0..179, segmenting a colour with `cv_in_range/4` |
| 05-smoothing | Smoothing Images | box, Gaussian, median and bilateral, measured against the clean picture |
| 06-thresholding | Basic and adaptive thresholding | the five plain types, Otsu, and uneven light |
| 07-morphology | Eroding, dilating, and more | the two operations and the four composed from them, to the pixel |
| 08-edges | Sobel, Laplace, Canny | derivatives as signed 64f, and thin hysteresis edges |
| 09-contours | Contours, hulls, moments | shapes as point lists; area, perimeter, centroid, convexity, a corner-counting classifier |
| 10-hough | Hough lines and circles | voting: `[Rho, Theta]`, segments, circles, and the threshold that matters |
| 11-histograms | Calculation, comparison, equalization | counts as lists, correlation and distance, equalize and CLAHE, a chart drawn by hand |
| 12-template-matching | Template Matching | a score map, its extremum, and several copies by thresholding it |
| 13-geometric-transforms | Affine transforms; pyramids; borders; filter2D | resize, rotation about a centre, maps from point pairs, perspective, borders, your own kernel |
| 14-fourier | Discrete Fourier Transform | DC and frequency, the spectrum picture, what blurring removes |
| 15-segmentation | Distance transform and watershed; GrabCut | markers from distance peaks, the watershed, components, flood fill, GrabCut on a photograph |
| 16-kmeans | K-Means Clustering | points into K groups, an image into K colours |
| 17-features | Harris, Shi-Tomasi, detection, description, matching, homography | ORB / SIFT / AKAZE, the ratio test, RANSAC recovering a known warp |
| 18-object-detection | Cascade Classifier; objdetect | Haar cascades from OpenCV's data directory, HOG people, QR codes made and read |
| 19-photo | Denoising, inpainting, HDR, NPR | non-local means, a scratch painted over, exposure fusion, stylisation |
| 20-video | Video I/O; background subtraction; optical flow | a video written and read back, MOG2 and KNN, Farneback and Lucas-Kanade |
| 21-calibration | Camera calibration, the corner half | chessboard corners to sub-pixel precision, a view straightened by its homography |
| 22-dnn-classification | Load models; classification | SqueezeNet from ONNX, the blob, softmax in Prolog, the top five |
| 23-dnn-detection | YOLO DNNs | YOLOv4-tiny, boxes decoded in Prolog, `cv_dnn_nms/5` |

## How to read one

Open any file: a header says which OpenCV lesson it mirrors and lists the
predicates it walks; `main` walks them with `must/3`, so every line of
the lesson is a claim that fails loudly if the library changes underneath
it; the helpers are repeated at the bottom on purpose, so the file can be
copied anywhere and run. Detector outputs (cascades, HOG, YOLO) are
printed rather than pinned to a count -- a detector's answer is a fact
about the detector, not about the language -- except where the picture
plainly contains what is looked for.

## Adding one

The next lesson of OpenCV's index that is not here is the one to add:
remapping, back projection, meanshift/camshift tracking, stereo, and the
rest of calib3d. A predicate the lesson needs and the module lacks goes
into `modules/opencv/coco-opencv.cicili` as one row of the table and one
`cv-pred`, with the binding under Cicili's `lib/cpp/opencv/` declaring
whatever new OpenCV names it calls -- and the lesson lands in the same
commit, with its row in this table and a line in `test/tutorials.pl` if
it needs a skip.
