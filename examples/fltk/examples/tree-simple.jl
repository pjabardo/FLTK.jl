# Julia translation of FLTK's examples/tree-simple.cxx.
# Original: Copyright 2010 Greg Ercolano; Copyright 1998-2016 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

# Tree's callback: invoked whenever an item's state changes.
function tree_callback(tree)
    path = tree_item(tree)               # full path of the item, or nothing
    path === nothing && return
    reason = tree_reason(tree)
    if reason == FL_TREE_REASON_SELECTED
        # the item's own label is the last path component (slashes in it are escaped)
        lbl = replace(last(split(path, r"(?<!\\)/")), "\\/" => "/", "\\\\" => "\\")
        println(stderr, "TreeCallback: Item selected='$lbl', Full pathname='$path'")
    elseif reason == FL_TREE_REASON_DESELECTED
        # println(stderr, "TreeCallback: Item '$path' deselected")
    elseif reason == FL_TREE_REASON_OPENED
        # println(stderr, "TreeCallback: Item '$path' opened")
    elseif reason == FL_TREE_REASON_CLOSED
        # println(stderr, "TreeCallback: Item '$path' closed")
    end
end

scheme!("gtk+")
win = DoubleWindow(250, 400, "Simple Tree") do win
    tree = Tree(10, 10, win.w - 20, win.h - 20; callback = tree_callback)
    showroot!(tree, false)               # don't show the root of the tree
    for p in ("Flintstones/Fred", "Flintstones/Wilma", "Flintstones/Pebbles",
              "Simpsons/Homer", "Simpsons/Marge", "Simpsons/Bart", "Simpsons/Lisa",
              "Pathnames/\\/bin",                    # front slashes
              "Pathnames/\\/usr\\/sbin",
              "Pathnames/C:\\\\Program Files",       # backslashes
              "Pathnames/C:\\\\Documents and Settings")
        add!(tree, p)
    end
    # start with some items closed
    close!(tree, "Simpsons")
    close!(tree, "Pathnames")
end
resizable!(win, win)
show!(win)
fl_run()
