# Julia translation of FLTK's examples/howto-flex-simple.cxx.
# Original: Copyright 2022 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# The 'Exit' button callback closes the window and terminates the program.
function exit_cb(w)
    fl_message("The '$(label(w))' button closes the window\nand terminates the program.")
    hide!(window(w))
end

# Common callback for all other buttons.
button_cb(w) = fl_message("The '$(label(w))' button does nothing.")

win = DoubleWindow(410, 40, "Simple Fl_Flex Demo") do win
    flex = Flex(5, 5, win.w - 10, win.h - 10, FLEX_ROW) do flex
        Button(0, 0, 0, 0, "File"; callback = button_cb)
        Button(0, 0, 0, 0, "New"; callback = button_cb)
        Button(0, 0, 0, 0, "Save"; callback = button_cb)
        bx = Box(0, 0, 0, 0)                 # empty space
        Button(0, 0, 0, 0, "Exit"; callback = exit_cb)
        # gap between adjacent buttons and extra spacing (invisible box size)
        gap!(flex, 10)
        fixed!(flex, bx, 30)                 # total 50: 2 * gap + 30
    end
    resizable!(win, flex)
end
size_range!(win, 300, 30)
show!(win)
fl_run()
