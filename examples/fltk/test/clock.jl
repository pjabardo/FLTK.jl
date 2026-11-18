# Julia translation of FLTK's test/clock.cxx.
# Original: Copyright 1998-2017 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# close all windows when the user closes one of them
function close_cb(_)
    while (w = first_window()) !== nothing
        hide!(w)
    end
end

win1 = DoubleWindow(220, 220, "Fl_Clock"; callback = close_cb) do win
    c1 = Clock(0, 0, 220, 220)
    resizable!(win, c1)
end
win2 = DoubleWindow(220, 220, "Fl_Round_Clock"; callback = close_cb) do win
    c2 = RoundClock(0, 0, 220, 220)
    resizable!(win, c2)
end
# don't pick up X resources meant for other programs called "clock"
xclass!(win1, "Fl_Clock")
xclass!(win2, "Fl_Clock")
show!(win1)
show!(win2)
fl_run()
