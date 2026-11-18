# Julia translation of FLTK's examples/menubar-add.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# Invoked whenever the user clicks an item in the menu bar.
function my_menu_callback(bar)
    i = value(bar)                                 # index of the item that was picked
    lbl = text(bar)                                # its label
    print(stderr, "callback: You picked '$lbl'")
    print(stderr, ", item_pathname() is '$(item_path(bar))'")
    if mode(bar, i) & (FL_MENU_RADIO | FL_MENU_TOGGLE) != 0   # toggle or radio item?
        print(stderr, ", value is ", item_value(bar, i) ? "on" : "off")
    end
    println(stderr)
    lbl == "Google" && fl_open_uri("http://google.com/")
    lbl == "&Quit" && exit(0)
end

ctrl(c) = FL_CTRL + Int(c)

scheme!("gtk+")
win = Window(400, 200, "menubar-simple") do win
    menu = MenuBar(0, 0, 400, 25)
    for (path, key, flags) in (("&File/&Open", ctrl('o'), 0),
                               ("&File/&Save", ctrl('s'), FL_MENU_DIVIDER),
                               ("&File/&Quit", ctrl('q'), 0),
                               ("&Edit/&Copy", ctrl('c'), 0),
                               ("&Edit/&Paste", ctrl('v'), FL_MENU_DIVIDER),
                               ("&Edit/Radio 1", 0, FL_MENU_RADIO),
                               ("&Edit/Radio 2", 0, FL_MENU_RADIO | FL_MENU_DIVIDER),
                               ("&Edit/Toggle 1", 0, FL_MENU_TOGGLE),                  # default: off
                               ("&Edit/Toggle 2", 0, FL_MENU_TOGGLE),                  # default: off
                               ("&Edit/Toggle 3", 0, FL_MENU_TOGGLE | FL_MENU_VALUE),  # default: on
                               ("&Help/Google", 0, 0))
        add_item!(my_menu_callback, menu, path; shortcut = key, flags = flags)
    end
    # Dynamically change the state of item 'Toggle 2' (turn it on).
    i = find_index(menu, "&Edit/Toggle 2")
    i >= 0 ? item_value!(menu, i, true) : println(stderr, "'Toggle 2' item not found?!")
end
show!(win)
fl_run()
