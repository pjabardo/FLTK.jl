# Julia translation of FLTK's examples/browser-simple.cxx
# ("Simple Fl_Browser widget example", erco 07/26/2019).
# Original: Copyright 2019 Greg Ercolano; Copyright 1998-2016 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# Hold browser's callback: invoked whenever an item is clicked.
function hold_browser_callback(brow)
    line = value(brow)
    println("[hold browser] item $line picked: ", text(brow, line))
end

# Multi browser's callback: many items can be selected, so print them all.
function multi_browser_callback(brow)
    for t in 1:length(brow)
        isselected(brow, t) && println("[multi browser] item $t selected: ", text(brow, t))
    end
    println()
end

scheme!("gtk+")
win = DoubleWindow(250, 220, "Simple Browser") do win
    brow = HoldBrowser(10, 10, win.w - 20, 80, "Hold"; callback = hold_browser_callback)
    add!(brow, ["One", "Two", "Three", "Four"])
    select!(brow, 1)                     # preselect the first item, "One"

    brow = MultiBrowser(10, 120, win.w - 20, 80, "Multi"; callback = multi_browser_callback)
    add!(brow, ["Aaa", "Bbb", "Ccc", "Ddd"])
    select!(brow, 1)                     # preselect "Aaa" and "Bbb"
    select!(brow, 2)
end
resizable!(win, win)
show!(win)
fl_run()
