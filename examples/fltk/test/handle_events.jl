# Julia translation of FLTK's test/handle_events.cxx.
# Original: Copyright 1998-2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# Prints every event the window receives. C++ subclasses the window and
# overrides handle(); here the window gets a `handle!` function.
using FLTK, Printf

const eventnum = Ref(0)

function print_event(win, ev)
    eventnum[] += 1
    n = screen_num(win)
    scale = round(Int, screen_scale(n) * 100)
    @printf(stderr, "[%3d, win(%d,%d,%d,%d), screen %d, scale %3d%%] %-18.18s at (%4d, %4d)",
            eventnum[], win.x, win.y, win.w, win.h, n, scale, eventname(ev), event_x(), event_y())
    eventnum[] %= 999
end

win = DoubleWindow(10, 10, 240, 240) do win
    Button(90, 100, 60, 40, "Quit"; box = FL_THIN_UP_BOX) do b
        hide!(window(b))
    end
end
handle!(win) do win, ev
    print_event(win, ev)                       # common for all events
    res = super_handle(win, ev)
    buttons = event_buttons()                  # bits: 1 = left, 2 = middle, 4 = right button
    if ev == FL_PUSH
        @printf(stderr, ", button %d down, buttons = 0x%x", event_button(), buttons)
        res = 1
    elseif ev == FL_RELEASE
        @printf(stderr, ", button %d up,   buttons = 0x%x", event_button(), buttons)
        res = 1
    elseif ev == FL_MOUSEWHEEL
        @printf(stderr, ", dx = %d, dy = %d", event_dx(), event_dy())
        res = 1
    elseif ev in (FL_ENTER, FL_LEAVE, FL_KEYUP, FL_FOCUS, FL_UNFOCUS)
        res = 1
    elseif ev in (FL_MOVE, FL_DRAG)
        @printf(stderr, ",          mouse buttons = 0x%x", buttons)
        res = 1
    elseif ev == FL_KEYBOARD
        t = event_text()
        if !isempty(t) && 'a' <= t[1] <= 'z'
            print(stderr, ", Text = '", t, "'")
            res = 1
        else                                   # "ignore" everything else
            print(stderr, ", ignored '", t, "'")
        end
    end
    println(stderr)
    return res
end
resizable!(win, win)
show!(win)
fl_run()
