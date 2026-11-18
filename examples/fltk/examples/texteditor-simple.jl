# Julia translation of FLTK's examples/texteditor-simple.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(640, 480, "Simple Fl_Text_Editor")
buff = TextBuffer()
edit = TextEditor(20, 20, 640 - 40, 480 - 40)
add!(win, edit)
buffer!(edit, buff)                  # attach the text buffer to our editor widget
resizable!(win, edit)
show!(win)
text!(buff, join(("line $i\n" for i in 0:23)))
fl_run()
