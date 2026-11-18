# Julia translation of FLTK's test/arc.cxx.
# Original: Copyright 1998-2015 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const args = [140.0, 140, 50, 0, 360, 0]
const names = ["X", "Y", "R", "start", "end", "rotate"]

function draw_arc(d)
    fl_push_clip(d.x, d.y, d.w, d.h)
    fl_color(FL_DARK3)
    fl_rectf(d.x, d.y, d.w, d.h)
    fl_push_matrix()
    if args[6] != 0
        fl_translate(d.x + d.w / 2, d.y + d.h / 2)
        fl_rotate(args[6])
        fl_translate(-(d.x + d.w / 2), -(d.y + d.h / 2))
    end
    fl_color(FL_WHITE)
    fl_translate(d.x, d.y)
    fl_begin_complex_polygon()
    fl_arc(args[1], args[2], args[3], args[4], args[5])
    fl_gap()
    fl_arc(140.0, 140.0, 20.0, 0.0, -360.0)
    fl_end_complex_polygon()
    fl_color(FL_RED)
    fl_begin_line()
    fl_arc(args[1], args[2], args[3], args[4], args[5])
    fl_end_line()
    fl_pop_matrix()
    fl_pop_clip()
end

win = DoubleWindow(300, 500) do win
    drawing = Box(10, 10, 280, 280)
    draw!(draw_arc, drawing)
    y = 300
    for n in 1:6
        s = HorValueSlider(50, y, 240, 25, names[n]); y += 25
        range!(s, (n <= 3 ? (0, 300) : n == 6 ? (0, 360) : (-360, 360))...)
        s.step = 1
        s.value = args[n]
        s.align = FL_ALIGN_LEFT
        callback!(s) do s
            args[n] = value(s)
            redraw!(drawing)
        end
    end
end
show!(win)
fl_run()
