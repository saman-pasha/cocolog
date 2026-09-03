#!/bin/sh
# Build library(opencv): OpenCV as cocolog predicates, as a LOADABLE module.
#
#   sh modules/opencv/build.sh
#
# It wants an OpenCV 4 with core, imgproc, imgcodecs, dnn, objdetect,
# features2d, photo, video, videoio and calib3d, found through pkg-config
# as `opencv4'. Where that is:
#
#   export OPENCV_ROOT=/where/it/is        # a prefix holding lib/pkgconfig/opencv4.pc
#   ~/opencv4                              # a source build into home (what this
#                                          #   repository's Mac carries: Homebrew
#                                          #   has no bottle for opencv on it)
#   brew --prefix opencv@4 | opencv        # Homebrew, where a bottle exists
#   libopencv-dev / opencv-devel           # Debian, Ubuntu / Fedora
#
#   CICILI   a Cicili checkout   (default $HOME/cicili)
#   OUT      where the .so lands (default ../../library, the default path)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CICILI=${CICILI:-$HOME/cicili}
. "$ROOT/tools/cc/env.sh"
OUT=${OUT:-$ROOT/library}

PCP="${PKG_CONFIG_PATH:-}"
for p in "${OPENCV_ROOT:-}" "$HOME/opencv4" "$(brew --prefix opencv@4 2>/dev/null)" "$(brew --prefix opencv 2>/dev/null)" /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/lib/aarch64-linux-gnu /usr/local; do
  [ -n "$p" ] || continue
  for d in "$p/lib/pkgconfig" "$p/lib64/pkgconfig" "$p/pkgconfig"; do
    [ -f "$d/opencv4.pc" ] && PCP="$PCP${PCP:+:}$d"
  done
done
export PKG_CONFIG_PATH="$PCP"
if ! pkg-config --exists opencv4 2>/dev/null; then
  echo "opencv: SKIPPED -- no opencv4.pc for pkg-config (set OPENCV_ROOT, or: apt-get install libopencv-dev / dnf install opencv-devel; on a Mac without a bottle, a source build into ~/opencv4)" >&2
  exit 1
fi
CV_VERSION=$(pkg-config --modversion opencv4)
case "$CV_VERSION" in
  4.*) ;;
  *) echo "opencv: SKIPPED -- opencv4.pc says $CV_VERSION; this module is written against 4.x" >&2; exit 1 ;;
esac
CV_CFLAGS=$(pkg-config --cflags opencv4)
CV_LIBS=$(pkg-config --libs opencv4)
CV_PREFIX=$(pkg-config --variable=prefix opencv4)
CV_LIBDIR=$(pkg-config --variable=libdir opencv4)
for m in dnn objdetect features2d photo video videoio calib3d; do
  case "$CV_LIBS" in
    *"-lopencv_$m"*) ;;
    *) echo "opencv: SKIPPED -- this OpenCV has no $m module (opencv4.pc lists no -lopencv_$m)" >&2; exit 1 ;;
  esac
done
# cv::QRCodeEncoder is missing from some 4.x headers (Ubuntu 22.04's 4.5.4);
# the module compiles cv_qr_encode in only where objdetect.hpp declares it.
CV_QRENC=""
for f in $CV_CFLAGS; do
  case "$f" in
    -I*) d=${f#-I}
         if [ -f "$d/opencv2/objdetect.hpp" ] && grep -q "class.*QRCodeEncoder" "$d/opencv2/objdetect.hpp"; then CV_QRENC="-DCOCO_CV_QRENCODER"; fi ;;
  esac
done
CV_DATA=""
for d in "$CV_PREFIX/share/opencv4" "$CV_PREFIX/share/OpenCV" /usr/share/opencv4 /usr/share/opencv; do
  [ -d "$d/haarcascades" ] && { CV_DATA="$d"; break; }
done

# The SDK is symlinked in rather than named by a path, so coco-opencv.cicili
# carries none -- the same trick every build.sh here uses.
ln -sfn "$ROOT/lib/sdk.cicili" "$HERE/sdk.cicili"

mkdir -p "$OUT"
( cd "$CICILI" && sbcl --script cicili.lisp --release "$HERE/coco-opencv.cicili" )

# Pillow's resampler, vendored: pil/Resample.c is Pillow 11.3.0's file unchanged
# (LICENSE beside it), pil/Imaging.h the shim of what it reads, pil/pil-resample.c
# the allocation and the entry cv_resample calls. Compiled as C, linked in.
: "${CC:=cc}"
for c in Resample pil-resample; do
  "$CC" -c -O2 -fPIC -o "$HERE/pil/$c.o" "$HERE/pil/$c.c" || exit 1
done

# One Cicili :cpp target, one emitted C++ file, the vendored C, one link against OpenCV.
# The data directory is compiled in so cv_data_dir/1 can name the
# haarcascades without a search; OPENCV_DATA in the environment overrides it.
"$CXX" -shared -fPIC -O2 -std=c++17 -Wno-deprecated-declarations -Wno-unused-function \
    $CV_CFLAGS $CV_QRENC -DCOCO_CV_DATA="\"$CV_DATA\"" \
    -o "$OUT/opencv.so" "$HERE/coco-opencv.cpp" "$HERE/pil/Resample.o" "$HERE/pil/pil-resample.o" \
    $CV_LIBS -Wl,-rpath,"$CV_LIBDIR"
echo "built $OUT/opencv.so against OpenCV $CV_VERSION at $CV_PREFIX${CV_DATA:+ (data: $CV_DATA)}"
