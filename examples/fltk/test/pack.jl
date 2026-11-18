# Julia translation of FLTK's test/pack.cxx (the default variant: Fl_Pack
# inside an Fl_Scroll).
# Original: Copyright 1998-2022 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

w = DoubleWindow(360, 370)
begin_group(w)
scroll = Scroll(10, 10, 340, 285) do scroll
    global pack = Pack(10, 10, 340, 285; box = FL_DOWN_FRAME) do pack
        # positions (xx, xx) are "fixed" by Fl_Pack
        for (i, xx) in enumerate(35:10:35+10*23)
            Button(xx, xx, 25, 25, "b$i")
        end
    end
end
resizable!(w, pack)

function type_cb(t)
    for o in pack
        resize!(o, 0, 0, 25, 25)
    end
    pack.type = t
    resize!(pack, scroll.x, scroll.y, scroll.w, scroll.h)
    redraw!(parent(pack))
    redraw!(pack)
end
LightButton(b -> type_cb(PACK_HORIZONTAL), 10, 305, 165, 25, "HORIZONTAL"; type = FL_RADIO_BUTTON)
LightButton(b -> type_cb(PACK_VERTICAL), 185, 305, 165, 25, "VERTICAL"; type = FL_RADIO_BUTTON, value = true)
ValueSlider(100, 335, 250, 25, "Spacing: "; align = FL_ALIGN_LEFT, type = FL_HORIZONTAL,
            range = (0, 30), step = 1) do s
    spacing!(pack, round(Int, value(s)))
    redraw!(parent(pack))
end
end_group(w)
size_range!(w, 300, 300)
show!(w)
fl_run()
