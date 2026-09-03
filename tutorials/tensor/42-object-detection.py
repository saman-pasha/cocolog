#!/usr/bin/env python3
"""Penn-Fudan -> the CSVs tutorial 42 reads, and the pictures it draws. Run
by the tutorial's `download' and `predict' goals, never by hand:

    python3 tutorials/tensor/42-object-detection.py DIR/PennFudanPed DIR
    python3 tutorials/tensor/42-object-detection.py draw DIR OUTDIR 'k:x1,y1,x2,y2,p|...;k2:...'

The pictures come as PNG and cocolog reads no image format, so this is the
one step that is not Prolog: each photograph resized to 96 by 96, RGB in
0..1, written as PIXELS AS ROWS -- 9216 lines of three numbers per
picture, the layout conv2d/3 takes -- and each pedestrian's box, read off
its instance mask and scaled to the same 96 by 96, as one line of
`picture, x1, y1, x2, y2'. Every fifth photograph is held out: 34 to test
on, 136 to train on, the same split every time.

The draw mode takes what the network found on the held-out photographs,
one argument, picks the three it did best on, and writes each original
photograph with the people in green and the network's boxes in red.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SIDE = 96


def convert(src, dst, split, names):
    px = open(os.path.join(dst, f'{split}-pixels.csv'), 'w')
    bx = open(os.path.join(dst, f'{split}-boxes.csv'), 'w')
    people = 0
    for k, name in enumerate(names):
        image = Image.open(os.path.join(src, 'PNGImages', name)).convert('RGB')
        width, height = image.size
        pixels = np.asarray(image.resize((SIDE, SIDE), Image.BILINEAR), dtype=np.float32) / 255.0
        np.savetxt(px, pixels.reshape(-1, 3), fmt='%.4f', delimiter=',')
        mask = np.asarray(Image.open(os.path.join(src, 'PedMasks', name.replace('.png', '_mask.png'))))
        for instance in np.unique(mask)[1:]:
            ys, xs = np.where(mask == instance)
            bx.write('%d,%.2f,%.2f,%.2f,%.2f\n' % (k, xs.min() * SIDE / width, ys.min() * SIDE / height,
                                                   (xs.max() + 1) * SIDE / width, (ys.max() + 1) * SIDE / height))
            people += 1
    px.close()
    bx.close()
    print(f'{split}: {len(names)} photographs, {people} people')


def iou(a, b):
    ix = max(0.0, min(a[2], b[2]) - max(a[0], b[0]))
    iy = max(0.0, min(a[3], b[3]) - max(a[1], b[1]))
    inter = ix * iy
    union = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter
    return inter / union if union > 0 else 0.0


def draw(dirn, out, spec):
    names = open(os.path.join(dirn, 'test-names.txt')).read().split()
    truth = {}
    for line in open(os.path.join(dirn, 'test-boxes.csv')):
        k, x1, y1, x2, y2 = line.strip().split(',')
        truth.setdefault(int(k), []).append(tuple(float(v) for v in (x1, y1, x2, y2)))
    found = {}
    for part in spec.split(';'):
        if not part:
            continue
        k, boxes = part.split(':')
        found[int(k)] = [tuple(float(v) for v in b.split(',')) for b in boxes.split('|') if b]
    ranked = []
    for k, boxes in found.items():
        hits = sum(1 for b in boxes if any(iou(b, t) >= 0.5 for t in truth.get(k, [])))
        ranked.append((hits - 0.5 * (len(boxes) - hits) - 0.25 * (len(truth.get(k, [])) - hits), -k, k))
    ranked.sort(reverse=True)
    try:
        font = ImageFont.load_default(size=18)
        small = ImageFont.load_default(size=14)
    except TypeError:
        font = small = ImageFont.load_default()
    for n, (_, _, k) in enumerate(ranked[:3], 1):
        image = Image.open(os.path.join(dirn, 'PennFudanPed', 'PNGImages', names[k])).convert('RGB')
        width, height = image.size
        sx, sy = width / SIDE, height / SIDE
        canvas = ImageDraw.Draw(image)
        for x1, y1, x2, y2 in truth.get(k, []):
            canvas.rectangle([x1 * sx, y1 * sy, x2 * sx, y2 * sy], outline=(40, 200, 40), width=3)
        for x1, y1, x2, y2, p in found[k]:
            canvas.rectangle([x1 * sx, y1 * sy, x2 * sx, y2 * sy], outline=(235, 40, 40), width=3)
            canvas.text((x1 * sx + 5, y1 * sy + 4), f'{p:.2f}', fill=(235, 40, 40), font=font)
        image.thumbnail((720, 720))
        width, height = image.size
        caption = f'cocolog 42, {names[k][:-4]}: green the people, red the network'
        strip = Image.new('RGB', (width, 26), (20, 20, 20))
        ImageDraw.Draw(strip).text((8, 4), caption, fill=(240, 240, 240), font=small)
        page = Image.new('RGB', (width, height + 26))
        page.paste(image, (0, 0))
        page.paste(strip, (0, height))
        path = os.path.join(out, f'42-detection-{n}.jpg')
        page.save(path, quality=88)
        print(f'wrote {path}: {names[k]}, {len(truth.get(k, []))} people, {len(found[k])} boxes found')


def main():
    if sys.argv[1] == 'draw':
        draw(sys.argv[2], sys.argv[3], sys.argv[4])
        return
    src, dst = sys.argv[1], sys.argv[2]
    names = sorted(n for n in os.listdir(os.path.join(src, 'PNGImages')) if n.endswith('.png'))
    test = [n for i, n in enumerate(names) if i % 5 == 0]
    train = [n for i, n in enumerate(names) if i % 5 != 0]
    convert(src, dst, 'train', train)
    convert(src, dst, 'test', test)
    with open(os.path.join(dst, 'test-names.txt'), 'w') as f:
        f.write('\n'.join(test) + '\n')


if __name__ == '__main__':
    main()
