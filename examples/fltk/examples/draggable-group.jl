# Julia translation of FLTK's examples/draggable-group.cxx
# (DraggableGroup contributed by K Dmitrij on fltk.general, 2017).
# Original: Copyright 2017 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# A group whose direct children can be dragged with the right mouse button
# inside the group's borders. In C++ this is a subclass of Fl_Group that
# overrides handle(); here a plain `Group` gets a `handle!` function, and the
# per-group drag state lives in the closure.
using FLTK

function draggable_group(x, y, w, h, label = ""; kw...)
    g = Group(x, y, w, h, label; box = FL_UP_BOX, kw...)
    xoff = yoff = 0             # start offsets while dragging
    drag_index = 0              # index of the dragged child
    drag_widget = nothing       # the dragged child
    handle!(g) do g, e
        if e == FL_PUSH
            bm = belowmouse()
            if event_button() == FL_RIGHT_MOUSE && bm !== nothing && parent(bm) == g
                drag_widget = bm
                # pointer offsets relative to the widget's x/y position
                xoff = event_x() - bm.x
                yoff = event_y() - bm.y
                # raise to the top (last child) for visible feedback,
                # remembering where it was
                drag_index = findfirst(==(bm), g)
                add!(g, bm)
                redraw!(g)
                return true
            end
        elseif e == FL_DRAG && drag_widget !== nothing
            nx = event_x() - xoff               # new x coordinate
            ny = event_y() - yoff               # new y coordinate
            bbx, bby = box_dx(g.box), box_dy(g.box)   # border widths
            # keep the widget inside its parent's borders
            nx = clamp(nx, g.x + bbx, g.x + g.w - drag_widget.w - bbx)
            ny = clamp(ny, g.y + bby, g.y + g.h - drag_widget.h - bby)
            position!(drag_widget, nx, ny)
            redraw!(g)
            return true
        elseif e == FL_RELEASE && drag_widget !== nothing && event_button() == FL_RIGHT_MOUSE
            # Optional: restore the original widget order in the group.
            insert!(g, drag_index, drag_widget)
            init_sizes!(g)                      # save positions for later resizing
            drag_widget = nothing
            redraw!(g)
            parent(g) === nothing || redraw!(parent(g))
            return true
        end
        return nothing                          # everything else: Fl_Group::handle()
    end
    return g
end

# clear the status message box after a timeout
const clear_id = Ref(0)
function button_cb(w, status)
    label!(status, "button_cb: '$(label(w))'.")
    redraw!(status)
    remove_timeout(clear_id[])                  # remove any pending timeout
    clear_id[] = add_timeout(2.0) do
        label!(status, ""); redraw!(status)
    end
end

const tt_drag = "Drag this DraggableGroup and/or its child groups and squares. " *
                "Use the right mouse button (MB3) to drag objects."
const tt_group = "You can drag this Fl_Group, but not its children (squares)."
const tt_button = "You can drag this button with the right mouse button " *
                  "and you can click it with the left mouse button."

square(x, y, s, c) = Box(x, y, s, s; color = c, box = FL_FLAT_BOX)

win = DoubleWindow(500, 500, "Drag children within their parent group") do win
    area = draggable_group(0, 0, 500, 400, "Use the right mouse button (MB3)\nto drag objects";
                           align = FL_ALIGN_INSIDE, tooltip = tt_drag)
    begin_group(area)
    # draggable group inside the draggable area
    dobj = draggable_group(5, 5, 140, 140, "DraggableGroup"; align = FL_ALIGN_INSIDE, tooltip = tt_drag)
    begin_group(dobj)
    square(25, 25, 20, FL_RED)
    square(105, 105, 20, FL_GREEN)
    end_group(dobj)
    # regular group inside the draggable area
    Group(5, 280, 110, 110, "Fl_Group"; box = FL_DOWN_BOX, align = FL_ALIGN_INSIDE, tooltip = tt_group) do g
        square(15, 290, 20, FL_BLUE)
        square(85, 360, 20, FL_YELLOW)
    end
    # draggable group inside the draggable area ...
    dobj3 = draggable_group(245, 5, 150, 150, "DraggableGroup"; align = FL_ALIGN_INSIDE, tooltip = tt_drag)
    begin_group(dobj3)
    # ... with a nested draggable group
    dobj4 = draggable_group(250, 10, 50, 50; tooltip = tt_drag)
    begin_group(dobj4)
    square(255, 15, 15, FL_BLACK)
    square(275, 30, 15, FL_WHITE)
    end_group(dobj4)
    end_group(dobj3)
    global button1 = Button(200, 350, 180, 40, "Fl_Button inside DraggableGroup";
                            align = FL_ALIGN_INSIDE | FL_ALIGN_WRAP, tooltip = tt_button)
    end_group(area)
    global button2 = Button(200, 410, 180, 40, "Fl_Button outside DraggableGroup";
                            align = FL_ALIGN_INSIDE | FL_ALIGN_WRAP,
                            tooltip = "This is a normal button and can't be dragged.")
    global status = Box(0, 460, win.w, 40, "Messages ..."; box = FL_DOWN_BOX)
end
callback!(b -> button_cb(b, status), button1)
callback!(b -> button_cb(b, status), button2)
resizable!(win, win)
show!(win)
fl_run()
