# Custom drawing and event handling: a sine wave you can drag around,
# animated with a timer.
using FLTK

phase = Ref(0.0)
freq = Ref(2.0)
drag = Ref{Union{Nothing,Int}}(nothing)

win = DoubleWindow(600, 400, "FLTK.jl drawing") do win
    canvas = Box(10, 10, 580, 330; box = FL_DOWN_BOX)
    draw!(canvas) do c
        x0, y0, w, h = c.x, c.y, c.w, c.h
        fl_rectf(x0, y0, w, h, fl_rgb_color(20, 24, 32))
        fl_clip(x0, y0, w, h) do
            # grid
            fl_color(fl_rgb_color(50, 56, 70))
            for gx in x0:50:x0+w; fl_yxline(gx, y0, y0 + h); end
            for gy in y0:50:y0+h; fl_xyline(x0, gy, x0 + w); end
            # curve, drawn with the floating point vertex API
            fl_color(fl_rgb_color(90, 200, 255))
            fl_line_style(FL_SOLID | FL_CAP_ROUND, 3)
            xs = range(0, w; length = 400)
            ys = [y0 + h / 2 + 0.4h * sin(2π * freq[] * x / w + phase[]) for x in xs]
            fl_polyline(x0 .+ xs, ys)
            fl_line_style()   # reset
            # a filled circle following the curve
            fl_color(FL_YELLOW)
            fl_begin_polygon(); fl_circle(x0 + w / 2, y0 + h / 2 + 0.4h * sin(π * freq[] + phase[]), 8); fl_end_polygon()
            # text
            fl_color(FL_WHITE); fl_font(FL_COURIER, 14)
            fl_draw("drag horizontally to shift phase, wheel to change frequency", x0 + 10, y0 + 20)
            fl_draw("freq = $(round(freq[]; digits = 2))", x0 + 10, y0 + h - 10)
        end
    end
    handle!(canvas) do c, ev
        if ev == FL_PUSH
            drag[] = event_x()
            return true
        elseif ev == FL_DRAG && drag[] !== nothing
            phase[] += (event_x() - drag[]) / 50
            drag[] = event_x()
            redraw!(c)
            return true
        elseif ev == FL_RELEASE
            drag[] = nothing
            return true
        elseif ev == FL_MOUSEWHEEL
            freq[] = clamp(freq[] - 0.1 * event_dy(), 0.1, 20)
            redraw!(c)
            return true
        end
        return nothing   # default handling for everything else
    end

    anim = LightButton(10, 350, 120, 40, "Animate")
    local tid = 0
    callback!(anim) do b
        if value(b)
            tid = add_timeout(1 / 60; repeat = true) do
                phase[] += 0.05
                redraw!(canvas)
            end
        else
            remove_timeout(tid)
        end
    end
    HorValueSlider(200, 355, 390, 30; range = (0.1, 10), value = freq[],
                   callback = s -> (freq[] = value(s); redraw!(canvas)))
    resizable!(win, canvas)
end

show!(win)
fl_run()
