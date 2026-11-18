# Julia translation of FLTK's test/adjuster.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# show the adjuster's value, formatted, in the box's label
adjcb(a, b) = (label!(b, format(a)); redraw!(b))

win = DoubleWindow(320, 100, PROGRAM_FILE) do win
    b1 = Box(20, 30, 80, 25; box = FL_DOWN_BOX, color = FL_WHITE)
    a1 = Adjuster(20 + 80, 30, 3 * 25, 25; callback = a -> adjcb(a, b1))
    adjcb(a1, b1)

    b2 = Box(20 + 80 + 4 * 25, 30, 80, 25; box = FL_DOWN_BOX, color = FL_WHITE)
    a2 = Adjuster(b2.x + b2.w, 10, 25, 3 * 25; callback = a -> adjcb(a, b2))
    adjcb(a2, b2)
end
resizable!(win, win)
show!(win)
fl_run()
