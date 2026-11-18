# Julia translation of FLTK's examples/howto-text-over-image-button.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# The C++ version stores the gradient as an XPM pixmap. Here the same
# gradient (light gray to darker gray, diagonally) is computed into a
# Julia array and turned into an image with `RGBImage`.
using FLTK

const W, H = 135, 20
# pixel (x, y) gets a gray level that falls off along x + 3y,
# from 0xe0 in the top-left corner to 0x90 in the bottom-right one
gray(x, y) = round(UInt8, 0xe0 - (0xe0 - 0x90) * (x + 3y) / (W - 1 + 3(H - 1)))
pixels = [gray(x, y) for x in 0:W-1, y in 0:H-1]     # Matrix (w, h): grayscale
gradient = RGBImage(pixels)

win = Window(160, 75, "test") do win
    but1 = Button(10, 10, 140, 25, "Button 1")       # regular button
    image!(but1, gradient)                           # assign it an image
    but1.align = FL_ALIGN_IMAGE_BACKDROP | but1.align # use the image as a 'backdrop'
    but2 = Button(10, 40, 140, 25, "Button 2")       # second button
    image!(but2, gradient)                           # same image
    but2.align = FL_ALIGN_IMAGE_BACKDROP | but2.align
end
show!(win)
fl_run()
