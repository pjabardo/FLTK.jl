# Julia translation of FLTK's test/color_chooser.cxx.
# Original: Copyright 1998-2018 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# Not translated: the command line options for choosing an X visual.
using FLTK

const width, height = 100, 100
const fullcolor_cell = FL_FREE_COLOR
const c = Ref{UInt32}(FL_GRAY)

# red in the upper-left, green in the lower-left, blue in the lower-right corner
function make_image()
    img = zeros(UInt8, 3, width, height)
    for y in 0:height-1, x in 0:width-1
        X, Y = x / (width - 1), y / (height - 1)
        img[:, x+1, y+1] = [floor(UInt8, 255 * (1 - X) * (1 - Y)),
                            floor(UInt8, 255 * (1 - X) * Y),
                            floor(UInt8, 255 * X * Y)]
    end
    RGBImage(img)
end

function set_background(box, hint, col)
    c[] = col
    box.color = col
    hint.labelcolor = fl_contrast(FL_BLACK, col)
    redraw!(parent(box))
end

set_color!(fullcolor_cell, 145, 159, 170)
win = Window(400, 400) do win
    box = Box(30, 30, 340, 340; box = FL_THIN_DOWN_BOX, color = fullcolor_cell)
    c[] = fullcolor_cell
    hint = Box(40, 40, 320, 30, "Pick background color with buttons:"; align = FL_ALIGN_INSIDE)
    Button(120, 80, 180, 30, "fl_show_colormap()") do b
        set_background(box, hint, fl_show_colormap(c[]))
    end
    Button(120, 120, 180, 30, "fl_color_chooser()") do b
        rgb = fl_color_chooser("New color:", get_color(c[]); mode = 3)
        rgb === nothing && return
        set_color!(fullcolor_cell, rgb...)
        set_background(box, hint, fullcolor_cell)
    end
    image_box = Box(160, 190, width, height)
    image!(image_box, make_image())
    Box(160, 310, 120, 30, "Example of fl_draw_image()")
    # "pens": the gray ramp, one color per line
    pens = Box(60, 180, 3 * 8, 120, "lines"; align = FL_ALIGN_TOP)
    draw!(pens) do p
        for i in 0:3*8-1
            fl_color(FL_GRAY_RAMP + i)
            fl_line(p.x + i, p.y, p.x + i, p.y + p.h)
        end
    end
end
show!(win)
fl_run()
