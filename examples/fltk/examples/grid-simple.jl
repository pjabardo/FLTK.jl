# Julia translation of FLTK's examples/grid-simple.cxx.
# Original: Copyright 2021-2022 by Albrecht Schlosser; Copyright 2022-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(320, 180, "3x3 Fl_Grid with Buttons")
grid = Grid(0, 0, win.w, win.h; color = FL_WHITE) do grid
    layout!(grid, 3, 3; margin = 10, gap = 10)
    b0 = Button(0, 0, 0, 0, "New")
    b1 = Button(0, 0, 0, 0, "Options")
    b3 = Button(0, 0, 0, 0, "About")
    b4 = Button(0, 0, 0, 0, "Help")
    b6 = Button(0, 0, 0, 0, "Quit")
    # assign buttons to grid positions (0-based, as in FLTK)
    place!(grid, b0, 0, 0)
    place!(grid, b1, 0, 2)
    place!(grid, b3, 1, 1)
    place!(grid, b4, 2, 0)
    place!(grid, b6, 2, 2)
    # show_grid!(grid)      # enable to display grid helper lines
end
add!(win, grid)
resizable!(win, grid)
size_range!(win, 300, 100)
show!(win)
fl_run()
