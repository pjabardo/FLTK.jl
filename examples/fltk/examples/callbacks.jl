# Julia translation of FLTK's examples/callbacks.cxx.
# Original: Copyright 2023 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# The C++ version shows the macros in <FL/fl_callback_macros.H>, which bind
# extra arguments to a callback. In Julia a callback is any function, so a
# closure does the same job: it captures whatever values it needs.
using FLTK

hello_0_args_cb() = fl_message("Hello with 0 arguments")
hello_2_args_cb(text, number) = fl_message("Hello with 2 arguments,\n\"$text\" and '$number'")
hello_4_args_cb(a1, a2, a3, a4) = fl_message("Hello with 4 arguments:\n$a1 $a2 $a3 $a4")

# The C++ MyButton subclass stores an id and has a `hello` method. Here the
# id is simply captured by the closure.
function my_button(x, y, w, h, label, id, a, b, c)
    Button(x, y, w, h, label) do btn
        fl_message("MyButton has the id $id\nand was called with the custom parameters\n$a, $b, and $c.")
    end
end

# Each call creates a new closure, so every button keeps its own values.
function make_button(set)
    y_lut = (60, 90)
    label_lut = ("id 2 (5, 6, 7)", "id 3 (6, 7, 8)")
    my_button(200, y_lut[set+1], 180, 25, label_lut[set+1], set + 2, set + 5, set + 6, set + 7)
end

win = Window(580, 120) do win
    # Function callbacks with arguments
    Box(10, 5, 180, 25, "Function Callbacks:")
    Button(b -> hello_0_args_cb(), 10, 30, 180, 25, "0 args")
    Button(b -> hello_2_args_cb("FLTK", 2), 10, 60, 180, 25, "2 args")
    Button(b -> hello_4_args_cb(1, 2, 3, 4), 10, 90, 180, 25, "4 args")

    # "Method" callbacks: closures over per-button data
    Box(200, 5, 180, 25, "Method Callbacks:")
    my_button(200, 30, 180, 25, "id 1 (1, 2, 3)", 1, 1, 2, 3)
    make_button(0)
    make_button(1)

    # Inline callbacks
    Box(390, 5, 180, 25, "Inline Callbacks:")
    Button(390, 30, 180, 25, "0 args") do b
        fl_message("Inline callback with 0 args.")
    end
    let text = "FLTK", number = 2
        Button(390, 60, 180, 25, "2 args") do b
            fl_message("We received the message $text with $(number)!")
        end
    end
    # The values are captured when the callback is created, as in the C++ macro.
    let (x, y, w, h) = bounds(win)
        Button(390, 90, 180, 25, "4 args") do b
            fl_message("The main window was at\nx:$x, y:$y, w:$w, h:$h\n" *
                       "when the callback was created\n" *
                       "and is now at x:$(win.x), y:$(win.y)")
        end
    end
end
show!(win)
fl_run()
