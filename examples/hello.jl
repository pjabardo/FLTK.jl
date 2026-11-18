# The smallest FLTK.jl program.
using FLTK

win = Window(340, 180, "Hello FLTK.jl") do win
    Box(20, 20, 300, 60, "Hello, World!"; box = FL_UP_BOX, labelsize = 28,
        labelfont = FL_HELVETICA_BOLD_ITALIC, labeltype = FL_SHADOW_LABEL)
    # For a non-group widget, the do-block is its callback.
    Button(120, 110, 100, 40, "Click me") do b
        fl_message("Hello from Julia $(VERSION)!")
    end
end

show!(win)
fl_run()
