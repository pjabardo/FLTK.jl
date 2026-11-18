# Julia translation of FLTK's test/cursor.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# Not translated: the "custom cursor" menu entry, which builds a cursor from
# an image (Fl_Window::cursor(Fl_RGB_Image*, ...) is not wrapped yet).
using FLTK

const cursors = ("FL_CURSOR_DEFAULT", "FL_CURSOR_ARROW", "FL_CURSOR_CROSS", "FL_CURSOR_WAIT",
                 "FL_CURSOR_INSERT", "FL_CURSOR_HAND", "FL_CURSOR_HELP", "FL_CURSOR_MOVE",
                 "FL_CURSOR_NS", "FL_CURSOR_WE", "FL_CURSOR_NWSE", "FL_CURSOR_NESW",
                 "FL_CURSOR_N", "FL_CURSOR_NE", "FL_CURSOR_E", "FL_CURSOR_SE", "FL_CURSOR_S",
                 "FL_CURSOR_SW", "FL_CURSOR_W", "FL_CURSOR_NW", "FL_CURSOR_NONE")

win = DoubleWindow(400, 300)
begin_group(win)
choice = Choice(80, 100, 200, 25, "Cursor:"; when = FL_WHEN_RELEASE | FL_WHEN_NOT_CHANGED)
cursor_slider = HorValueSlider(80, 180, 310, 30, "Cursor:"; align = FL_ALIGN_LEFT, step = 1,
                               precision = 0, range = (0, 255), value = 0)
end_group(win)

for name in cursors
    c = getfield(FLTK, Symbol(name))
    add_item!(choice, name) do _
        cursor_slider.value = c
        cursor!(win, c)
    end
end
callback!(s -> cursor!(win, round(Int, value(s))), cursor_slider)

resizable!(win, win)
show!(win)
fl_run()
