# Julia translation of FLTK's test/curve.cxx.
# Original: Copyright 1998-2015 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const args = [20.0, 20, 50, 200, 100, 20, 200, 200, 0]
const names = ["X0", "Y0", "X1", "Y1", "X2", "Y2", "X3", "Y3", "rotate"]
const points = Ref(false)

function draw_curve(d)
    fl_push_clip(d.x, d.y, d.w, d.h)
    fl_color(FL_DARK3)
    fl_rectf(d.x, d.y, d.w, d.h)
    fl_push_matrix()
    if args[9] != 0
        fl_translate(d.x + d.w / 2, d.y + d.h / 2)
        fl_rotate(args[9])
        fl_translate(-(d.x + d.w / 2), -(d.y + d.h / 2))
    end
    fl_translate(d.x, d.y)
    if !points[]
        fl_color(FL_WHITE)
        fl_begin_complex_polygon()
        fl_curve(args[1:8]...)
        fl_end_complex_polygon()
    end
    fl_color(FL_BLACK)
    fl_begin_line()
    for i in 1:2:7
        fl_vertex(args[i], args[i+1])
    end
    fl_end_line()
    fl_color(points[] ? FL_WHITE : FL_RED)
    points[] ? fl_begin_points() : fl_begin_line()
    fl_curve(args[1:8]...)
    points[] ? fl_end_points() : fl_end_line()
    fl_pop_matrix()
    fl_pop_clip()
end

win = DoubleWindow(300, 555) do win
    drawing = Box(10, 10, 280, 280)
    draw!(draw_curve, drawing)
    y = 300
    for n in 1:9
        s = HorValueSlider(50, y, 240, 25, names[n]); y += 25
        range!(s, 0, n == 9 ? 360 : 280)
        s.step = 1
        s.value = args[n]
        s.align = FL_ALIGN_LEFT
        callback!(s) do s
            args[n] = value(s)
            redraw!(drawing)
        end
    end
    ToggleButton(50, y, 50, 25, "points") do b
        points[] = value(b)
        redraw!(drawing)
    end
end
show!(win)
fl_run()
