# Julia translation of FLTK's examples/howto-draw-an-x.cxx.
# Original: Copyright 2005 by Greg Ercolano; Copyright 1998-2017 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# C++ subclasses Fl_Widget and overrides draw(). In Julia any widget's
# drawing can be replaced with `draw!`.
using FLTK

win = DoubleWindow(200, 200, "Draw X")
# put our widget 10 pixels within the window edges
draw_x = Box(10, 10, win.w - 20, win.h - 20; color = FL_WHITE)
draw!(draw_x) do d
    # background: a white filled rectangle
    fl_color(FL_WHITE); fl_rectf(d.x, d.y, d.w, d.h)
    # black 'X' over the background
    fl_color(FL_BLACK)
    x1, y1 = d.x, d.y
    x2, y2 = d.x + d.w - 1, d.y + d.h - 1
    fl_line(x1, y1, x2, y2)
    fl_line(x1, y2, x2, y1)
end
add!(win, draw_x)
resizable!(win, draw_x)
show!(win)
fl_run()
