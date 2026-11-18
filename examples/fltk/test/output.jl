# Julia translation of FLTK's test/output.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = DoubleWindow(400, 400) do win
    global input = Input(50, 375, 350, 25; value = "The quick brown fox\njumped over\nthe lazy dog.",
                         when = FL_WHEN_CHANGED)
    global sizes = HorValueSlider(50, 350, 350, 25, "Size"; align = FL_ALIGN_LEFT,
                                  range = (1, 64), step = 1, value = 14)
    global fonts = HorValueSlider(50, 325, 350, 25, "Font"; align = FL_ALIGN_LEFT,
                                  range = (0, 15), step = 1, value = 0)
    global text2 = MultilineOutput(100, 150, 200, 100, "Fl_Multiline_Output"; value = value(input),
                                   align = FL_ALIGN_BOTTOM, tooltip = "This is an Fl_Multiline_Output widget.")
    resizable!(win, text2)
    global text = Output(100, 90, 200, 30, "Fl_Output"; value = value(input),
                         align = FL_ALIGN_BOTTOM, tooltip = "This is an Fl_Output widget.")
end

callback!(fonts) do f
    for t in (text, text2)
        textfont!(t, round(Int, value(f))); redraw!(t)
    end
end
callback!(sizes) do s
    for t in (text, text2)
        textsize!(t, round(Int, value(s))); redraw!(t)
    end
end
callback!(input) do i
    value!(text, value(i))
    value!(text2, value(i))
end
show!(win)
fl_run()
