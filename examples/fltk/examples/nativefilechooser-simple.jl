# Julia translation of FLTK's examples/nativefilechooser-simple.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# The file the chooser starts with; updated after each choice.
preset = Ref("nativefilechooser-simple.jl")

function open_chooser(_)
    # This blocks while the chooser is open.
    files = native_file_chooser(type = BROWSE_FILE,                  # only picks files that exist
                                title = "Pick a file please..",      # custom title
                                filter = "Julia\t*.jl\n",
                                directory = ".",                     # directory to start browsing in
                                preset_file = preset[])
    files === nothing && return                                       # cancelled
    preset[] = files[1]
    fl_message("You chose: $(files[1])")
end

scheme!("gtk+")
win = Window(640, 480, "Test Native File Chooser"; tooltip = "Use right-click for popup menu..") do win
    # right-click menu for the window
    menu = MenuButton(0, 20, 640, 480, "Popup Menu"; type = POPUP3)
    add_item!(open_chooser, menu, "Open File Chooser..")
    add_item!(m -> exit(0), menu, "Quit")
end
show!(win)
fl_run()
