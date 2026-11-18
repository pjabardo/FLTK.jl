# Julia translation of FLTK's test/tile.cxx.
# Original: Copyright 1998-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(300, 300; box = FL_NO_BOX)
resizable!(win, win)
begin_group(win)
tile = Tile(0, 0, 300, 300) do tile
    init_size_range!(tile, 30, 30)       # all children shall be at least 30x30

    box0 = Box(0, 0, 150, 150, "0"; box = FL_DOWN_BOX, color = 9, labelsize = 36, align = FL_ALIGN_CLIP)
    resizable!(tile, box0)

    global w1 = DoubleWindow(150, 0, 150, 150, "1"; box = FL_NO_BOX) do w1
        box1 = Box(0, 0, 150, 150, "1\nThis is a child window"; box = FL_DOWN_BOX, color = 19,
                   labelsize = 18, align = FL_ALIGN_CLIP | FL_ALIGN_INSIDE | FL_ALIGN_WRAP)
        resizable!(w1, box1)
    end

    for (x, y, w, h, l, c) in ((0, 150, 70, 150, "2a", 12), (70, 150, 80, 150, "2b", 13),
                               (150, 150, 150, 70, "3a", 12), (150, 150 + 70, 150, 80, "3b", 13))
        Box(x, y, w, h, l; box = FL_DOWN_BOX, color = c, labelsize = 36, align = FL_ALIGN_CLIP)
    end
end
end_group(win)
show!(w1)
size_range!(win, 90, 90)
show!(win)
fl_run()
