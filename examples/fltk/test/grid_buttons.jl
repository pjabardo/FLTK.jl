# Julia translation of FLTK's test/grid_buttons.cxx.
# Original: Copyright 2021 by Albrecht Schlosser; Copyright 2022-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(460, 200, "Fl_Grid Row with 5 Buttons") do win
    Grid(0, 0, win.w, 50) do grid
        layout!(grid, 1, 7; margin = 10, gap = 10)
        b0 = Button(0, 0, 80, 30, "New")
        b1 = Button(0, 0, 80, 30, "Options")
        b3 = Button(0, 0, 80, 30, "About")
        b4 = Button(0, 0, 80, 30, "Help")
        b6 = Button(0, 0, 80, 30, "Quit")
        place!(grid, b0, 0, 0)
        place!(grid, b1, 0, 1); col_gap!(grid, 1, 0)
        place!(grid, b3, 0, 3)
        place!(grid, b4, 0, 4); col_gap!(grid, 4, 0)
        place!(grid, b6, 0, 6)
        col_weight!(grid, [0, 0, 50, 0, 0, 50, 0])
    end
    g1 = Group(0, 50, win.w, win.h - 50)
    resizable!(win, g1)
end
size_range!(win, win.w, 100)
show!(win)
fl_run()
