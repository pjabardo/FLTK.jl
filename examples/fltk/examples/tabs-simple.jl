# Julia translation of FLTK's examples/tabs-simple.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# Simple tabs example
#      _____  _____
#   __/ Aaa \/ Bbb \______________________
#  |    _______                           |
#  |   |_______|                          |
#  |    _______                           |
#  |   |_______|                          |
#  |    _______                           |
#  |   |_______|                          |
#  |______________________________________|
using FLTK

scheme!("gtk+")
win = Window(500, 200, "Tabs Example") do win
    Tabs(10, 10, 500 - 20, 200 - 20) do tabs
        # The "Aaa" tab: a child group of the tabs widget.
        # The group's label is the label of the tab.
        Group(10, 35, 500 - 20, 200 - 45, "Aaa") do aaa
            # buttons shown when the tab is selected
            Button(50, 60, 90, 25, "Button A1"; color = 88 + 1)
            Button(50, 90, 90, 25, "Button A2"; color = 88 + 2)
            Button(50, 120, 90, 25, "Button A3"; color = 88 + 3)
        end
        # The "Bbb" tab: same details as above.
        Group(10, 35, 500 - 10, 200 - 35, "Bbb") do bbb
            Button(50, 60, 90, 25, "Button B1"; color = 88 + 1)
            Button(150, 60, 90, 25, "Button B2"; color = 88 + 3)
            Button(250, 60, 90, 25, "Button B3"; color = 88 + 5)
            Button(50, 90, 90, 25, "Button B4"; color = 88 + 2)
            Button(150, 90, 90, 25, "Button B5"; color = 88 + 4)
            Button(250, 90, 90, 25, "Button B6"; color = 88 + 6)
        end
    end
end
show!(win)
fl_run()
