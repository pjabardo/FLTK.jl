# Julia translation of FLTK's test/hello.cxx.
# Original: Copyright 1998-2021 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = Window(340, 180) do win
    Box(20, 40, 300, 100, "Hello, World!"; box = FL_UP_BOX, labelfont = FL_BOLD + FL_ITALIC,
        labelsize = 36, labeltype = FL_SHADOW_LABEL)
end
show!(win)
fl_run()
