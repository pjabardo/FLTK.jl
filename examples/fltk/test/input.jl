# Julia translation of FLTK's test/input.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const TERMINAL_HEIGHT = 120

get_system_colors()      # so that fl_contrast below gives good results

win = Window(400, 420 + TERMINAL_HEIGHT)
begin_group(win)
const tty = Terminal(0, 420, win.w, TERMINAL_HEIGHT)

cb(i) = println(tty, "Callback for ", label(i), " '", value(i), "'")

const inputs = [
    Input(70, 10, 300, 30, "Normal:"; tooltip = "Normal input field"),
    FloatInput(70, 45, 300, 30, "Float:";
               tooltip = "Input field for floating-point number (F1)", shortcut = FL_F + 1),
    IntInput(70, 80, 300, 30, "Int:";
             tooltip = "Input field for integer number (F2)", shortcut = FL_F + 2),
    SecretInput(70, 115, 300, 30, "&Secret:"; tooltip = "Input field for password (Alt-S)"),
    MultilineInput(70, 150, 300, 100, "&Multiline:";
                   tooltip = "Input field for short text with newlines (Alt-M)"),
]
y = 255
wrap!(inputs[5], true)
for i in inputs[1:4]
    when!(i, 0)
    callback!(cb, i)
end

const when_flags = Ref(0)
function toggle_cb(b, v)
    when_flags[] = value(b) ? when_flags[] | v : when_flags[] & ~v
    foreach(i -> when!(i, when_flags[]), inputs)
end

# print an input's value if it has changed, and the character at the cursor
function test(i)
    ischanged(i) || return
    changed!(i, false)
    println(tty, label(i), " '", value(i), "'")
    s, p = value(i), insert_position(i)
    println(tty, "Symbol at cursor position: ", p < ncodeunits(s) ? s[p+1] : "")
end

function color_cb(button, c)
    rgb = fl_color_chooser("", get_color(c))
    rgb === nothing && return
    set_color!(c, rgb...)
    fl_redraw()
    button.labelcolor = fl_contrast(FL_BLACK, c)
    redraw!(button)
end

y1 = y
for (l, flag, tip) in (("FL_WHEN_CHANGED", FL_WHEN_CHANGED, "Do callback each time the text changes"),
                       ("FL_WHEN_RELEASE", FL_WHEN_RELEASE, "Do callback when widget loses focus"),
                       ("FL_WHEN_ENTER_KEY", FL_WHEN_ENTER_KEY, "Do callback when user hits Enter key"),
                       ("FL_WHEN_NOT_CHANGED", FL_WHEN_NOT_CHANGED, "Do callback even if the text is not changed"))
    ToggleButton(b -> toggle_cb(b, flag), 10, y, 200, 25, l; tooltip = tip)
    global y += 25
end
y += 5
Button(b -> foreach(test, inputs), 10, y, 200, 25, "&print changed()";
       tooltip = "Print widgets that have changed() flag set")
y += 25
LightButton(b -> tab_nav!(inputs[5], value(b)), 10, y, 100, 25, " Tab Nav";
            tooltip = "Control tab navigation for the multiline input field",
            value = tab_nav(inputs[5]))
LightButton(b -> option!(OPTION_ARROW_FOCUS, value(b)), 110, y, 100, 25, " Arrow Nav";
            tooltip = "Control horizontal arrow key focus navigation behavior.\ne.g. Fl::OPTION_ARROW_FOCUS",
            value = option(OPTION_ARROW_FOCUS))
y += 25

Button(b -> color_cb(b, FL_BACKGROUND2_COLOR), 220, y1, 120, 25, "color";
       color = inputs[1].color, tooltip = "Color behind the text")
b = Button(b -> color_cb(b, FL_SELECTION_COLOR), 220, y1 + 25, 120, 25, "selection_color";
           color = inputs[1].selection_color, tooltip = "Color behind selected text")
b.labelcolor = fl_contrast(FL_BLACK, b.color)
b = Button(b -> color_cb(b, FL_FOREGROUND_COLOR), 220, y1 + 50, 120, 25, "textcolor";
           color = inputs[1].textcolor, tooltip = "Color of the text")
b.labelcolor = fl_contrast(FL_BLACK, b.color)

end_group(win)
resizable!(win, tty)
show!(win)
fl_run()
