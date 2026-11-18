# A small text editor: TextEditor, menus with shortcuts and native file dialogs.
using FLTK

local menu, ed
win = DoubleWindow(640, 480, "Untitled - FLTK.jl editor") do win
    global menu = MenuBar(0, 0, 640, 28)
    global ed = TextEditor(0, 28, 640, 452; textfont = FL_COURIER, textsize = 14)
    resizable!(win, ed)
end
linenumber_width!(ed, 40)
filename = Ref{Union{Nothing,String}}(nothing)

settitle() = label!(win, (filename[] === nothing ? "Untitled" : basename(filename[])) * " - FLTK.jl editor")

add_item!(menu, "&File/&New"; shortcut = FL_CTRL + Int('n')) do m
    value!(ed, ""); filename[] = nothing; settitle()
end
add_item!(menu, "&File/&Open..."; shortcut = FL_CTRL + Int('o')) do m
    f = native_file_chooser(; title = "Open")
    f === nothing && return
    loadfile!(buffer(ed), f[1]); filename[] = f[1]; settitle()
end
add_item!(menu, "&File/&Save As..."; shortcut = FL_CTRL + FL_SHIFT + Int('s'), flags = FL_MENU_DIVIDER) do m
    f = native_file_chooser(; type = BROWSE_SAVE_FILE, title = "Save as", options = NFC_SAVEAS_CONFIRM)
    f === nothing && return
    savefile(buffer(ed), f[1]); filename[] = f[1]; settitle()
end
add_item!(menu, "&File/&Quit"; shortcut = FL_CTRL + Int('q')) do m
    hide!(win)
end
add_item!(menu, "&Edit/&Find..."; shortcut = FL_CTRL + Int('f')) do m
    s = fl_input("Find:")
    (s === nothing || isempty(s)) && return
    pos = search_forward(buffer(ed), s, insert_position(ed))
    pos < 0 && return fl_alert("\"$s\" not found")
    select!(buffer(ed), pos, pos + ncodeunits(s))
    insert_position!(ed, pos + ncodeunits(s)); show_insert_position!(ed)
end
add_item!(menu, "&View/&Word wrap"; flags = FL_MENU_TOGGLE) do m
    wrap_mode!(ed, item_value(m, value(m)) ? WRAP_AT_BOUNDS : WRAP_NONE)
end

value!(ed, "# Type here.\n\nusing FLTK\n")
show!(win)
fl_run()
