# Julia translation of FLTK's test/buttons.cxx.
# Original: Copyright 1998-2022 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

win = Window(420, 170) do win
    Button(10, 10, 130, 30, "Fl_Button"; tooltip = "Fl_Button")
    ReturnButton(150, 10, 160, 30, "Fl_Return_Button"; tooltip = "Fl_Return_Button")
    RepeatButton(10, 50, 130, 30, "Fl_Repeat_Button"; tooltip = "Fl_Repeat_Button")
    RoundButton(150, 50, 160, 30, "Fl_Round_Button"; tooltip = "Fl_Round_Button")
    LightButton(10, 90, 130, 30, "Fl_Light_Button"; tooltip = "Fl_Light_Button")
    CheckButton(150, 90, 160, 30, "Fl_Check_Button"; tooltip = "Fl_Check_Button")

    # a keypad of compact buttons
    Group(320, 10, 90, 120) do keypad
        for (x, y, w, l) in ((320, 10, 30, "7"), (350, 10, 30, "8"), (380, 10, 30, "9"),
                             (320, 40, 30, "4"), (350, 40, 30, "5"), (380, 40, 30, "6"),
                             (320, 70, 30, "1"), (350, 70, 30, "2"), (380, 70, 30, "3"),
                             (320, 100, 60, "0"), (380, 100, 30, "."))
            Button(x, y, w, 30, l; compact = true, selection_color = FL_SELECTION_COLOR)
        end
    end

    # A scheme choice widget for easier testing, at the right window border so
    # the menu popup doesn't cover the check boxes etc.
    SchemeChoice(180, 130, 130, 30, "Active FLTK Scheme:"; tooltip = "Fl_Scheme_Choice")
end
resizable!(win, win)
size_range!(win, 320, 130)
show!(win)
fl_run()
