# Julia translation of FLTK's test/flex_demo.cxx.
# Original: Copyright 2020 by Karsten Pedersen; Copyright 2022 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
using FLTK

create_button(caption) = Button(0, 0, 120, 30, caption; color = fl_rgb_color(225, 225, 225))

const box3 = Ref{Any}(nothing)

# hide or show the OK button (and the box next to it) in the second row, and
# add or delete a box in the first row
function toggle_cb(w, o)
    flex = parent(o)
    if isvisible(o)
        hide!(o); label!(w, "show OK button"); hide!(flex[2])   # also the box
    else
        show!(o); label!(w, "hide OK button"); show!(flex[2])
    end
    layout!(flex)
    flex = parent(flex)[1]
    current_group!(nothing)
    if box3[] === nothing
        box3[] = Box(0, 0, 0, 0, "Box3")
        insert!(flex, length(flex), box3[])      # before the last child
    else
        destroy!(box3[])
        box3[] = nothing
    end
    layout!(flex)
end

function create_row()
    row = Flex(0, 0, 0, 0, FLEX_ROW; box = FL_DOWN_BOX, color = FL_GREEN) do row
        toggle = create_button("hide OK button")
        toggle.tooltip = "hide() or show() OK button"
        box2 = Box(0, 0, 120, 10, "Box2")
        okay = create_button("OK")
        Input(0, 0, 120, 10)
        callback!(t -> toggle_cb(t, okay), toggle)
        col2 = Flex(0, 0, 0, 0, FLEX_COLUMN; box = FL_FLAT_BOX, color = fl_rgb_color(255, 128, 128)) do col2
            create_button("Top2")
            create_button("Bottom2")
        end
        margin!(col2, 0); gap!(col2, 5)          # C++: col2->margin(0, 5) sets margin and gap
        fixed!(row, box2, 50)
        fixed!(row, col2, 100)
    end
end

win = DoubleWindow(100, 100, "Simple GUI Example"; color = fl_rgb_color(160, 180, 240), box = FL_FLAT_BOX) do win
    col = Flex(5, 5, 90, 90, FLEX_COLUMN) do col
        Flex(0, 0, 0, 0, FLEX_ROW; color = FL_YELLOW, box = FL_FLAT_BOX) do row1
            create_button("Cancel")
            Box(0, 0, 120, 10, "Box1")
            create_button("OK")
            Input(0, 0, 120, 10)
            col1 = Flex(0, 0, 0, 0, FLEX_COLUMN; box = FL_FLAT_BOX, color = fl_rgb_color(255, 128, 128)) do col1
                create_button("Top1")
                create_button("Bottom1")
            end
            margin!(col1, 5); gap!(col1, 5)
        end
        fixed!(col, create_row(), 90)          # height of the (anonymous) row #2
        create_button("Something1")            # "row" #3
        row4 = Flex(0, 0, 0, 0, FLEX_ROW) do row4
            fixed!(row4, create_button("Cancel"), 100)
            fixed!(row4, create_button("OK"), 100)
            Input(0, 0, 120, 10)
        end
        create_button("Something2")            # "row" #5
        fixed!(col, row4, 30)
        margin!(col, 6, 10, 6, 10)
        gap!(col, 6)
    end
    resizable!(win, col)
end
size_range!(win, 550, 330)
resize!(win, 0, 0, 640, 480)
show!(win)
fl_run()
