# Julia translation of FLTK's test/button.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = Window(320, 65) do win
    Button(b -> fl_beep(), 20, 20, 80, 25, "&Beep")
    Button(120, 20, 80, 25, "&no op")
    Button(b -> exit(0), 220, 20, 80, 25, "E&xit")
end
show!(win)
fl_run()
