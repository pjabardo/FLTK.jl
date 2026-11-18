# Julia translation of FLTK's test/flex_login.cxx.
# Original: Copyright 2020 by Karsten Pedersen; Copyright 2022-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

create_button(caption) = Button(0, 0, 100, 25, caption; color = fl_rgb_color(225, 225, 225))
# a Flex created with zero size is placed by its parent Flex
row(f) = Flex(f, 0, 0, 0, 0, FLEX_ROW)
column(f) = Flex(f, 0, 0, 0, 0, FLEX_COLUMN)
spacer() = Box(0, 0, 0, 0)

function buttons_panel(parent)
    spacer()
    title = Box(0, 0, 0, 0, "Welcome to Fl_Flex"; align = FL_ALIGN_CENTER,
                labelfont = FL_BOLD + FL_ITALIC, labelsize = 16)
    urow = row() do urow
        Box(0, 0, 0, 0, "Username:"; align = FL_ALIGN_INSIDE | FL_ALIGN_RIGHT)
        fixed!(urow, Input(0, 0, 0, 0), 180)
    end
    prow = row() do prow
        Box(0, 0, 0, 0, "Password:"; align = FL_ALIGN_INSIDE | FL_ALIGN_RIGHT)
        fixed!(prow, Input(0, 0, 0, 0), 180)
    end
    pad = spacer()
    brow = row() do brow
        spacer()
        fixed!(brow, create_button("Register"), 80)
        fixed!(brow, create_button("Login"), 80)
        gap!(brow, 20)
    end
    b = spacer()
    fixed!(parent, title, 60)
    fixed!(parent, urow, 30)
    fixed!(parent, prow, 30)
    fixed!(parent, pad, 1)
    fixed!(parent, brow, 30)
    fixed!(parent, b, 30)
end

function middle_panel(parent)
    spacer()
    box = Box(0, 0, 0, 0, "Image"; box = FL_BORDER_BOX, color = fl_rgb_color(0, 200, 0))
    sp = spacer()
    bp = column(buttons_panel)
    spacer()
    fixed!(parent, box, 150)
    fixed!(parent, sp, 10)
    fixed!(parent, bp, 300)
end

function main_panel(parent)
    spacer()                                  # flexible separator
    mp = row(middle_panel)
    spacer()                                  # flexible separator
    fixed!(parent, mp, 200)
end

win = DoubleWindow(100, 100, "Fl_Flex \"Login\" Layout"; color = fl_rgb_color(250, 250, 250)) do win
    col = Flex(main_panel, 5, 5, 90, 90, FLEX_COLUMN)
    resizable!(win, col)
end
resize!(win, 0, 0, 600, 300)                  # same size as grid_login
size_range!(win, 550, 250)
show!(win)
fl_run()
