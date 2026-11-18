# Julia translation of FLTK's test/label.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

const img = load_image(joinpath(@__DIR__, "pixmaps", "blast.xpm"))

win = DoubleWindow(440, 495)
begin_group(win)

input = Input(70, 435, 350, 25, "Label:"; value = "The quick brown fox jumped over the lazy dog.",
              when = FL_WHEN_CHANGED, tooltip = "label text")
sizes = HorValueSlider(70, 350, 350, 25, "Size:"; align = FL_ALIGN_LEFT, range = (1, 64), step = 1, value = 14)
fonts = HorValueSlider(70, 325, 350, 25, "Font:"; align = FL_ALIGN_LEFT, range = (0, 15), step = 1, value = 0)
Box(0, 380, 70, 25, "Margins"; box = FL_FLAT_BOX, align = FL_ALIGN_RIGHT | FL_ALIGN_INSIDE)
h_margin = HorValueSlider(70 + 50, 380, 125, 25, "Hor:"; align = FL_ALIGN_LEFT, range = (-25, 25), step = 1, value = 0)
v_margin = HorValueSlider(70 + 175 + 50, 380, 125, 25, "Vert:"; align = FL_ALIGN_LEFT, range = (-25, 25), step = 1, value = 0)
img_spacing = HorValueSlider(70 + 50, 405, 125, 25, "Image:"; align = FL_ALIGN_LEFT, range = (0, 50), step = 1, value = 0)

# toggle buttons: label, tooltip, alignment flag (0 for the image button)
const toggles = Dict{String,ToggleButton}()
g = Group(70, 275, 350, 50) do g
    for (x, y, l, tip) in ((70, 275, "image", "show image"),
                           (120, 275, "T o I", "FL_ALIGN_TEXT_OVER_IMAGE"),
                           (170, 275, "I | T", "FL_ALIGN_IMAGE_NEXT_TO_TEXT"),
                           (220, 275, "back", "FL_ALIGN_IMAGE_BACKDROP"),
                           (70, 300, "left", "FL_ALIGN_LEFT"), (120, 300, "right", "FL_ALIGN_RIGHT"),
                           (170, 300, "top", "FL_ALIGN_TOP"), (220, 300, "bottom", "FL_ALIGN_BOTTOM"),
                           (270, 300, "inside", "FL_ALIGN_INSIDE"), (320, 300, "wrap", "FL_ALIGN_WRAP"),
                           (370, 300, "clip", "FL_ALIGN_CLIP"))
        toggles[l] = ToggleButton(x, y, 50, 25, l; tooltip = tip)
    end
    resizable!(g, toggles["inside"])
end

c = Choice(70, 250, 200, 25)
text = Box(120, 75, 200, 100, value(input); box = FL_FRAME_BOX, align = FL_ALIGN_CENTER)
resizable!(win, text)
end_group(win)

# ---- callbacks -----------------------------------------------------------------
const align_flags = ("T o I" => FL_ALIGN_TEXT_OVER_IMAGE, "I | T" => FL_ALIGN_IMAGE_NEXT_TO_TEXT,
                     "back" => FL_ALIGN_IMAGE_BACKDROP, "left" => FL_ALIGN_LEFT, "right" => FL_ALIGN_RIGHT,
                     "top" => FL_ALIGN_TOP, "bottom" => FL_ALIGN_BOTTOM, "inside" => FL_ALIGN_INSIDE,
                     "clip" => FL_ALIGN_CLIP, "wrap" => FL_ALIGN_WRAP)
function button_cb(_)
    text.align = reduce(|, (f for (l, f) in align_flags if value(toggles[l])); init = Cuint(0))
    redraw!(win)
end
for (l, _) in align_flags
    callback!(button_cb, toggles[l])
end
callback!(toggles["image"]) do b
    image!(text, value(b) ? img : nothing)
    redraw!(win)
end

# Each slider sets one property of the label box.
for (s, prop) in ((fonts, :labelfont), (sizes, :labelsize), (h_margin, :horizontal_label_margin),
                  (v_margin, :vertical_label_margin), (img_spacing, :label_image_spacing))
    callback!(s) do s
        setproperty!(text, prop, round(Int, value(s)))
        redraw!(win)
    end
end
callback!(input) do i
    label!(text, value(i))
    redraw!(win)
end

# label type menu (FL_SYMBOL_LABEL is the same value as FL_NORMAL_LABEL,
# but choosing it also puts a symbol into the label)
function set_labeltype(t; symbol = false)
    text.labeltype = t
    if symbol && !startswith(value(input), "@")
        value!(input, "@->")
        label!(text, "@->")
    end
    redraw!(win)
end
for (l, t) in (("FL_NORMAL_LABEL", FL_NORMAL_LABEL), ("FL_SYMBOL_LABEL", FL_SYMBOL_LABEL),
               ("FL_SHADOW_LABEL", FL_SHADOW_LABEL), ("FL_ENGRAVED_LABEL", FL_ENGRAVED_LABEL),
               ("FL_EMBOSSED_LABEL", FL_EMBOSSED_LABEL))
    add_item!(m -> set_labeltype(t; symbol = l == "FL_SYMBOL_LABEL"), c, l)
end

show!(win)
fl_run()
