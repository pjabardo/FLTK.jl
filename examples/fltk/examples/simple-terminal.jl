# Julia translation of FLTK's examples/simple-terminal.cxx.
# Original: Copyright 2017 Greg Ercolano; Copyright 1998-2016 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const TERMINAL_HEIGHT = 120

win = DoubleWindow(500, 200 + TERMINAL_HEIGHT, "Your App") do win
    Box(0, 0, win.w, 200, "Your app GUI in this area.\n\nYour app's debugging output in tty below")
    # A simple terminal at the bottom of the window, for a scrolling history of
    # status messages. ANSI sequences such as "\e[32m" are on by default.
    global tty = Terminal(0, 200, win.w, TERMINAL_HEIGHT)
end
resizable!(win, win)
show!(win)

# Append a date/time message to the terminal every 2 seconds.
tick() = print(tty, "Timer tick: \e[32m", Libc.strftime("%a %b %e %H:%M:%S %Y", time()), "\e[0m\n\n")
add_timeout(0.5) do
    tick()
    add_timeout(tick, 2.0; repeat = true)
end
fl_run()
