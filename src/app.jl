# Event loop, timers, events, screens, colors and global options.

# =============================================================================
# Event loop
# =============================================================================
"""
    fl_run(; poll = 0.01)

Run the event loop until all windows are closed. Between FLTK events, other
Julia tasks get time to run, so `@async` work, `Timer`s and `Channel`s keep
working. `poll` is the longest time (in seconds) FLTK may block.
"""
function fl_run(; poll::Real = 0.01)
    while (@ccall libfltkjl.fljl_first_window()::Ptr{Cvoid}) != C_NULL
        @ccall libfltkjl.fljl_wait(poll::Cdouble)::Cint
        _drain_free_queue()
        yield()
    end
    _drain_free_queue()
    return nothing
end

"""
    fl_run_blocking()

Run `Fl::run()`, the plain C++ event loop. Uses no CPU while idle, but other
Julia tasks do not run until all windows are closed.
"""
fl_run_blocking() = (r = @ccall libfltkjl.fljl_run()::Cint; _drain_free_queue(); Int(r))

"Wait up to `t` seconds for events and handle them. Returns > 0 if windows remain."
fl_wait(t::Real = 1e20) = (r = @ccall libfltkjl.fljl_wait(t::Cdouble)::Cint; _drain_free_queue(); Int(r))
"Handle all pending events without waiting."
fl_check() = (r = @ccall libfltkjl.fljl_check()::Cint; _drain_free_queue(); Int(r))
fl_ready() = (@ccall libfltkjl.fljl_ready()::Cint) != 0
"Redraw everything that needs it now."
fl_flush() = @ccall libfltkjl.fljl_flush()::Cvoid
fl_redraw() = @ccall libfltkjl.fljl_redraw_all()::Cvoid

const _repl_timer = Ref{Union{Nothing,Timer}}(nothing)

"""
    start_eventloop(; interval = 0.01)

Process FLTK events in the background from a Julia `Timer`, so windows stay
responsive while you keep using the REPL. Stop with `stop_eventloop()`.
"""
function start_eventloop(; interval::Real = 0.01)
    stop_eventloop()
    _repl_timer[] = Timer(0; interval) do _
        try
            fl_check()
        catch e
            _report(e, catch_backtrace(), "event loop")
        end
    end
    return nothing
end
function stop_eventloop()
    t = _repl_timer[]
    t === nothing || close(t)
    _repl_timer[] = nothing
    return nothing
end

first_window() = _wrap(@ccall libfltkjl.fljl_first_window()::Ptr{Cvoid})
next_window(w::AbstractWindow) = _wrap(@ccall libfltkjl.fljl_next_window(_ptr(w)::Ptr{Cvoid})::Ptr{Cvoid})
"All windows currently shown."
function windows()
    out = AbstractWidget[]
    w = first_window()
    while w !== nothing
        push!(out, w)
        w = _wrap(@ccall libfltkjl.fljl_next_window(_ptr(w)::Ptr{Cvoid})::Ptr{Cvoid})
    end
    out
end
modal_window() = _wrap(@ccall libfltkjl.fljl_modal_window()::Ptr{Cvoid})

"Set the look: `\"base\"`, `\"plastic\"`, `\"gtk+\"`, `\"gleam\"` or `\"oxy\"`."
scheme!(s::AbstractString) = @ccall libfltkjl.fljl_scheme(s::Cstring)::Cvoid
scheme() = _str_or_nothing(@ccall libfltkjl.fljl_get_scheme()::Ptr{UInt8})
visual!(mode::Integer) = (@ccall libfltkjl.fljl_visual(mode::Cint)::Cint) != 0
api_version() = Int(@ccall libfltkjl.fljl_api_version()::Cint)
abi_version() = Int(@ccall libfltkjl.fljl_abi_version()::Cint)

# =============================================================================
# Timers
# =============================================================================
"""
    add_timeout(f, seconds; repeat = false) -> id

Call `f()` after `seconds`, from the FLTK event loop. With `repeat = true`
it is called every `seconds` until `remove_timeout(id)`.
"""
function add_timeout(f, secs::Real; repeat::Bool = false)
    id = (_next_timeout_id[] += 1)
    _timeouts[id] = (f, Float64(secs), repeat)
    @ccall libfltkjl.fljl_add_timeout(secs::Cdouble, id::Int)::Cvoid
    return id
end
function remove_timeout(id::Integer)
    delete!(_timeouts, id)
    @ccall libfltkjl.fljl_remove_timeout(id::Int)::Cvoid
    return nothing
end
has_timeout(id::Integer) = haskey(_timeouts, id)

# =============================================================================
# Events (valid inside callbacks and handle functions)
# =============================================================================
for f in (:event, :event_x, :event_y, :event_x_root, :event_y_root, :event_dx, :event_dy,
          :event_key, :event_button, :event_clicks, :event_state, :event_length)
    c = QuoteNode(Symbol("fljl_", f))
    @eval $f() = Int(ccall(($c, libfltkjl), Cint, ()))
end
@doc "The current event (`FL_PUSH`, `FL_KEYDOWN`, ...)." event
@doc "Mouse x position relative to the window." event_x
@doc "Mouse y position relative to the window." event_y
@doc "Key of the last key event (`Int('a')`, `FL_Enter`, ...)." event_key
@doc "Mouse button of the last click (`FL_LEFT_MOUSE`, ...)." event_button
@doc "Modifier and button state bits (`FL_SHIFT`, `FL_CTRL`, `FL_BUTTON1`, ...)." event_state
"Name of an event number, e.g. `\"FL_PUSH\"`."
eventname(ev::Integer) = _str(@ccall libfltkjl.fljl_eventname(ev::Cint)::Ptr{UInt8})
"Mouse buttons held down: bits 1 = left, 2 = middle, 4 = right."
event_buttons() = (event_state() >> 24) & 0x7f
"Text of the last key event or paste."
event_text() = _str(@ccall libfltkjl.fljl_event_text()::Ptr{UInt8})
event_is_click() = (@ccall libfltkjl.fljl_event_is_click()::Cint) != 0
"Whether the event modifier `mask` (e.g. `FL_CTRL`) is held."
event_state(mask::Integer) = (event_state() & mask) != 0
event_inside(x::Integer, y::Integer, w::Integer, h::Integer) =
    (@ccall libfltkjl.fljl_event_inside(x::Cint, y::Cint, w::Cint, h::Cint)::Cint) != 0
event_inside(w::AbstractWidget) = (@ccall libfltkjl.fljl_event_inside_widget(_ptr(w)::Ptr{Cvoid})::Cint) != 0
"Whether a key is held down right now."
get_key(k::Integer) = (@ccall libfltkjl.fljl_get_key(k::Cint)::Cint) != 0
get_key(c::Char) = get_key(Int(c))
"Mouse position on the screen."
function get_mouse()
    x, y = Ref{Cint}(0), Ref{Cint}(0)
    @ccall libfltkjl.fljl_get_mouse(x::Ref{Cint}, y::Ref{Cint})::Cvoid
    (Int(x[]), Int(y[]))
end
focus() = _wrap(@ccall libfltkjl.fljl_focus()::Ptr{Cvoid})
focus!(w::AbstractWidget) = (@ccall libfltkjl.fljl_set_focus(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
belowmouse() = _wrap(@ccall libfltkjl.fljl_belowmouse()::Ptr{Cvoid})
pushed() = _wrap(@ccall libfltkjl.fljl_pushed()::Ptr{Cvoid})
"Copy text to the clipboard (`clipboard=true`) or the selection buffer."
copy_to_clipboard(s::AbstractString; clipboard::Bool = true) =
    @ccall libfltkjl.fljl_copy(s::Cstring, ncodeunits(s)::Cint, clipboard::Cint)::Cvoid

# =============================================================================
# Screens
# =============================================================================
screen_count() = Int(@ccall libfltkjl.fljl_screen_count()::Cint)
"Work area `(x, y, w, h)` of screen `n` (0-based)."
function screen_xywh(n::Integer = 0)
    x, y, w, h = Ref{Cint}(0), Ref{Cint}(0), Ref{Cint}(0), Ref{Cint}(0)
    @ccall libfltkjl.fljl_screen_xywh(x::Ref{Cint}, y::Ref{Cint}, w::Ref{Cint}, h::Ref{Cint}, n::Cint)::Cvoid
    (x = Int(x[]), y = Int(y[]), w = Int(w[]), h = Int(h[]))
end
screen_size() = (Int(@ccall libfltkjl.fljl_screen_w()::Cint), Int(@ccall libfltkjl.fljl_screen_h()::Cint))
screen_scale(n::Integer = 0) = @ccall libfltkjl.fljl_screen_scale(n::Cint)::Cdouble
screen_scale!(n::Integer, f::Real) = @ccall libfltkjl.fljl_set_screen_scale(n::Cint, f::Cdouble)::Cvoid

# =============================================================================
# Colors and fonts
# =============================================================================
"An `Fl_Color` for an RGB value (each 0-255)."
fl_rgb_color(r::Integer, g::Integer, b::Integer) = (UInt32(r & 0xff) << 24) | (UInt32(g & 0xff) << 16) | (UInt32(b & 0xff) << 8)
"A gray `Fl_Color` (0-255)."
fl_rgb_color(g::Integer) = fl_rgb_color(g, g, g)
fl_gray_ramp(i::Integer) = UInt32(FL_GRAY_RAMP + i)
fl_color_cube(r::Integer, g::Integer, b::Integer) = UInt32(FL_COLOR_CUBE + (b * 5 + r) * 8 + g)
fl_color_average(a::Integer, b::Integer, weight::Real) = @ccall libfltkjl.fljl_color_average(a::Cuint, b::Cuint, weight::Cdouble)::Cuint
fl_lighter(c::Integer) = @ccall libfltkjl.fljl_lighter(c::Cuint)::Cuint
fl_darker(c::Integer) = @ccall libfltkjl.fljl_darker(c::Cuint)::Cuint
fl_contrast(fg::Integer, bg::Integer) = @ccall libfltkjl.fljl_contrast(fg::Cuint, bg::Cuint)::Cuint
fl_inactive(c::Integer) = @ccall libfltkjl.fljl_inactive(c::Cuint)::Cuint

"Redefine the RGB value of palette entry `i`."
set_color!(i::Integer, r::Integer, g::Integer, b::Integer) = @ccall libfltkjl.fljl_set_color_rgb(i::Cuint, r::Cint, g::Cint, b::Cint)::Cvoid
"RGB value `(r, g, b)` of a color."
function get_color(i::Integer)
    r, g, b = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
    @ccall libfltkjl.fljl_get_color_rgb(i::Cuint, r::Ref{UInt8}, g::Ref{UInt8}, b::Ref{UInt8})::Cvoid
    (Int(r[]), Int(g[]), Int(b[]))
end
"Set the default widget background color."
background!(r::Integer, g::Integer, b::Integer) = @ccall libfltkjl.fljl_background(r::Cint, g::Cint, b::Cint)::Cvoid
"Set the background color of text fields and browsers."
background2!(r::Integer, g::Integer, b::Integer) = @ccall libfltkjl.fljl_background2(r::Cint, g::Cint, b::Cint)::Cvoid
"Set the default label/text color."
foreground!(r::Integer, g::Integer, b::Integer) = @ccall libfltkjl.fljl_foreground(r::Cint, g::Cint, b::Cint)::Cvoid
get_system_colors() = @ccall libfltkjl.fljl_get_system_colors()::Cvoid

"Assign a system font (e.g. `\"DejaVu Sans Mono\"`) to font number `i`."
set_font!(i::Integer, name::AbstractString) = @ccall libfltkjl.fljl_set_font(i::Cint, name::Cstring)::Cvoid
"Load all system fonts; returns the number of fonts now available."
set_fonts() = Int(@ccall libfltkjl.fljl_set_fonts(C_NULL::Ptr{UInt8})::Cint)
font_name(i::Integer) = _str(@ccall libfltkjl.fljl_get_font_name(i::Cint)::Ptr{UInt8})

"Get a global `Fl::option` (`OPTION_*`)."
option(o::Integer) = (@ccall libfltkjl.fljl_get_option(o::Cint)::Cint) != 0
"Set a global `Fl::option` (`OPTION_*`)."
option!(o::Integer, on::Bool) = @ccall libfltkjl.fljl_option(o::Cint, on::Cint)::Cvoid
"Border widths of a box type: left (`box_dx`), top (`box_dy`), total horizontal (`box_dw`) and vertical (`box_dh`)."
box_dx(b::Integer) = Int(@ccall libfltkjl.fljl_box_dx(b::Cint)::Cint)
box_dy(b::Integer) = Int(@ccall libfltkjl.fljl_box_dy(b::Cint)::Cint)
box_dw(b::Integer) = Int(@ccall libfltkjl.fljl_box_dw(b::Cint)::Cint)
box_dh(b::Integer) = Int(@ccall libfltkjl.fljl_box_dh(b::Cint)::Cint)
scrollbar_size() = Int(@ccall libfltkjl.fljl_scrollbar_size()::Cint)
scrollbar_size!(s::Integer) = @ccall libfltkjl.fljl_set_scrollbar_size(s::Cint)::Cvoid
"Whether keyboard focus is drawn on widgets."
visible_focus!(on::Bool) = @ccall libfltkjl.fljl_visible_focus(on::Cint)::Cvoid
"Default label/text size (`FL_NORMAL_SIZE`, initially 14)."
normal_size() = Int(@ccall libfltkjl.fljl_normal_size()::Cint)
normal_size!(s::Integer) = @ccall libfltkjl.fljl_set_normal_size(s::Cint)::Cvoid
