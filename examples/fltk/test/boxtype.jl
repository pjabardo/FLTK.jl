# Julia translation of FLTK's test/boxtype.cxx.
# Original: Copyright 1998-2015 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const W, H, ROWS = 200, 50, 14
const N = Ref(0)

# a button showing box type `name` at the next position in a 4-column grid
function bt(name; square = false)
    x, y = N[] % 4, N[] ÷ 4
    N[] += 1
    t = getfield(FLTK, Symbol(name))
    b = Button(x * W + 10, y * H + 10, square ? H - 20 : W - 20, H - 20, name; box = t, labelsize = 11)
    square && (b.align = FL_ALIGN_RIGHT)
end

get_system_colors()
win = DoubleWindow(4 * W, ROWS * H; box = FL_FLAT_BOX,
                   color = fl_rgb_color(51, 173, 255))   # light blue, shows box vs. frame types
s = scheme()
label!(win, "FLTK boxtypes: scheme = '$(s === nothing ? "none" : s)'")
begin_group(win)
Group(0, 0, win.w, win.h) do bg
    bt("FL_NO_BOX"); bt("FL_FLAT_BOX")
    N[] += 2                           # start of the next row, to line up boxes and frames
    for name in ("FL_UP_BOX", "FL_DOWN_BOX", "FL_UP_FRAME", "FL_DOWN_FRAME",
                 "FL_THIN_UP_BOX", "FL_THIN_DOWN_BOX", "FL_THIN_UP_FRAME", "FL_THIN_DOWN_FRAME",
                 "FL_ENGRAVED_BOX", "FL_EMBOSSED_BOX", "FL_ENGRAVED_FRAME", "FL_EMBOSSED_FRAME",
                 "FL_BORDER_BOX", "FL_SHADOW_BOX", "FL_BORDER_FRAME", "FL_SHADOW_FRAME",
                 "FL_ROUNDED_BOX", "FL_RSHADOW_BOX", "FL_ROUNDED_FRAME", "FL_RFLAT_BOX",
                 "FL_OVAL_BOX", "FL_OSHADOW_BOX", "FL_OVAL_FRAME", "FL_OFLAT_BOX",
                 "FL_ROUND_UP_BOX", "FL_ROUND_DOWN_BOX", "FL_DIAMOND_UP_BOX", "FL_DIAMOND_DOWN_BOX",
                 "FL_PLASTIC_UP_BOX", "FL_PLASTIC_DOWN_BOX", "FL_PLASTIC_UP_FRAME", "FL_PLASTIC_DOWN_FRAME",
                 "FL_PLASTIC_THIN_UP_BOX", "FL_PLASTIC_THIN_DOWN_BOX")
        bt(name)
    end
    N[] += 2
    bt("FL_PLASTIC_ROUND_UP_BOX"); bt("FL_PLASTIC_ROUND_DOWN_BOX")
    N[] += 2
    for name in ("FL_GTK_UP_BOX", "FL_GTK_DOWN_BOX", "FL_GTK_UP_FRAME", "FL_GTK_DOWN_FRAME",
                 "FL_GTK_THIN_UP_BOX", "FL_GTK_THIN_DOWN_BOX", "FL_GTK_THIN_UP_FRAME", "FL_GTK_THIN_DOWN_FRAME",
                 "FL_GTK_ROUND_UP_BOX", "FL_GTK_ROUND_DOWN_BOX")
        bt(name)
    end
end
resizable!(win, win)
SchemeChoice(610, 10, 150, 30, "Scheme:")
end_group(win)
show!(win)
fl_run()
