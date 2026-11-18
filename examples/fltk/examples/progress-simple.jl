# Julia translation of FLTK's examples/progress-simple.cxx.
# Original: Copyright 2005,2012 Greg Ercolano; Copyright 1998-2017 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

function butt_cb(butt, w)
    deactivate!(butt)                    # prevent the button from being pressed again
    fl_check()                           # give FLTK some CPU to gray out the button
    # Make the progress bar
    begin_group(w)                       # add the progress bar to the window
    progress = Progress(10, 50, 200, 30; range = (0, 1),   # range 0.0 ~ 1.0
                        color = 0x88888800,                 # background color
                        selection_color = 0x4444ff00,       # progress bar color
                        labelcolor = FL_WHITE)              # percent text color
    end_group(w)
    # Computation loop
    for t in 1:500
        value!(progress, t / 500)        # update the progress bar with 0.0 ~ 1.0
        label!(progress, "$(round(Int, t / 500 * 100))%")
        fl_check()                       # give FLTK some CPU to update the screen
        Libc.systemsleep(0.001)          # 'your stuff' that's compute intensive
    end
    # Cleanup
    remove!(w, progress)                 # remove the progress bar from the window
    destroy!(progress)                   # and delete it
    activate!(butt)                      # reactivate the button
    redraw!(w)                           # redraw now that the progress bar is gone
end

win = Window(220, 90)
butt = Button(10, 10, 100, 25, "Press")
add!(win, butt)
callback!(b -> butt_cb(b, win), butt)
resizable!(win, win)
show!(win)
fl_run()
