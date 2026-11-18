# Julia translation of FLTK's test/scroll.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# white box with a pattern of lines between 20 points on a circle
function draw_lines(d)
    fl_draw_box(FL_FLAT_BOX, d.x, d.y, d.w, d.h, d.color)
    fl_push_matrix()
    fl_translate(d.x + d.w ÷ 2, d.y + d.h ÷ 2)
    fl_scale(d.w ÷ 2, d.h ÷ 2)
    fl_color(FL_BLACK)
    for i in 0:19, j in i+1:19
        fl_begin_line()
        fl_vertex(cos(π * i / 10 + 0.1), sin(π * i / 10 + 0.1))
        fl_vertex(cos(π * j / 10 + 0.1), sin(π * j / 10 + 0.1))
        fl_end_line()
    end
    fl_pop_matrix()
end

win = Window(5 * 75, 400; box = FL_NO_BOX)
begin_group(win)
thescroll = Scroll(0, 0, 5 * 75, 300) do scroll
    n = 0
    for y in 0:15, x in 0:4
        n += 1
        Button(x * 75, y * 25 + (y >= 8 ? 5 * 75 : 0), 75, 25, string(n - 1); color = n, labelcolor = FL_WHITE)
    end
    drawing = Box(0, 8 * 25, 5 * 75, 5 * 75; align = FL_ALIGN_TOP, box = FL_FLAT_BOX, color = FL_WHITE)
    draw!(draw_lines, drawing)
end
resizable!(win, thescroll)
Box(0, 300, 5 * 75, win.h - 300; box = FL_FLAT_BOX)     # gray area below the scroll

LightButton(150, 310, 200, 25, "box") do b
    thescroll.box = value(b) ? FL_DOWN_FRAME : FL_NO_BOX
    redraw!(thescroll)
end
choice = Choice(150, 335, 200, 25, "type():")
for (l, t) in (("0", 0), ("HORIZONTAL", SCROLL_HORIZONTAL), ("VERTICAL", SCROLL_VERTICAL),
               ("BOTH", SCROLL_BOTH), ("HORIZONTAL_ALWAYS", SCROLL_HORIZONTAL_ALWAYS),
               ("VERTICAL_ALWAYS", SCROLL_VERTICAL_ALWAYS), ("BOTH_ALWAYS", SCROLL_BOTH_ALWAYS))
    add_item!(m -> (thescroll.type = t; redraw!(thescroll)), choice, l)
end
value!(choice, 3)
achoice = Choice(150, 360, 200, 25, "scrollbar.align():")
for (l, a) in (("left+top", FL_ALIGN_LEFT + FL_ALIGN_TOP), ("left+bottom", FL_ALIGN_LEFT + FL_ALIGN_BOTTOM),
               ("right+top", FL_ALIGN_RIGHT + FL_ALIGN_TOP), ("right+bottom", FL_ALIGN_RIGHT + FL_ALIGN_BOTTOM))
    add_item!(m -> (scrollbar(thescroll).align = a; redraw!(thescroll)), achoice, l)
end
value!(achoice, 3)
end_group(win)
show!(win)
fl_run()
