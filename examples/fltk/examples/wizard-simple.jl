# Julia translation of FLTK's examples/wizard-simple.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2021 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# Simple 'wizard' using FLTK's Fl_Wizard widget
function page(wiz, title, text; back = true, next = true)
    Group(0, 0, 400, 300) do g
        if next
            Button(b -> next!(wiz), 290, 265, 100, 25, "Next @->")
        else
            Button(b -> hide!(window(b)), 290, 265, 100, 25, "Finish")
        end
        back && Button(b -> prev!(wiz), 180, 265, 100, 25, "@<- Back")
        MultilineOutput(10, 30, 400 - 20, 300 - 80, title;
                        labelsize = 20, align = FL_ALIGN_TOP | FL_ALIGN_LEFT, value = text)
    end
end

win = Window(400, 300, "Example Wizard") do win
    Wizard(0, 0, 400, 300) do wiz
        page(wiz, "Welcome", "This is First page"; back = false)
        page(wiz, "Terms And Conditions", "This is the Second page")
        page(wiz, "Finish", "This is the Last page"; next = false)
    end
end
show!(win)
fl_run()
