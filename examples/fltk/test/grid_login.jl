# Julia translation of FLTK's test/grid_login.cxx.
# Original: Copyright 2021 by Albrecht Schlosser; Copyright 2022-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(480, 200, "Fl_Grid \"Login\" Layout"; color = fl_rgb_color(250, 250, 250)) do win
    grid = Grid(5, 5, 470, 190; color = fl_rgb_color(250, 250, 250)) do grid
        layout!(grid, 6, 6; margin = 2, gap = 2)       # 6 rows, 6 columns

        ibox = Box(0, 0, 150, 200, "Image"; box = FL_BORDER_BOX, color = fl_rgb_color(0, 200, 0))
        place!(grid, ibox, 1, 1; rowspan = 4, colspan = 1, align = FL_GRID_CENTER)

        title = Box(0, 0, 200, 60, "Welcome to Fl_Grid"; align = FL_ALIGN_CENTER,
                    labelfont = FL_BOLD + FL_ITALIC, labelsize = 16)
        place!(grid, title, 1, 3; colspan = 2, align = FL_GRID_HORIZONTAL | FL_GRID_CENTER)

        col_width!(grid, 2, 90)                         # placeholder for the labels

        place!(grid, Input(0, 0, 150, 30, "Username:"), 2, 3; colspan = 2, align = FL_GRID_HORIZONTAL)
        row_gap!(grid, 2, 10)                           # gap below username
        place!(grid, Input(0, 0, 150, 30, "Password:"), 3, 3; colspan = 2, align = FL_GRID_HORIZONTAL)
        row_gap!(grid, 3, 10)                           # gap below password
        place!(grid, Button(0, 0, 80, 30, "Register"), 4, 3; align = FL_GRID_HORIZONTAL)
        col_gap!(grid, 3, 20)                           # gap right of the register button
        place!(grid, Button(0, 0, 80, 30, "Login"), 4, 4; align = FL_GRID_HORIZONTAL)

        col_weight!(grid, [20, 0, 0, 10, 10, 20])
        row_weight!(grid, [10, 0, 0, 0, 0, 10])
    end
    layout!(grid)
    resizable!(win, grid)
end
resize!(win, 0, 0, 600, 300)                         # same size as flex_login
size_range!(win, 550, 250)
show!(win)
fl_run()
