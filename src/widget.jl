# Methods common to every widget (Fl_Widget), group (Fl_Group) and window.

const AW = AbstractWidget

# ---- geometry --------------------------------------------------------------
"""
    bounds(w) -> (x, y, w, h)

The widget's position and size. Coordinates are relative to its window.
"""
function bounds(w::AW)
    p = _ptr(w)
    (x = Int(@ccall libfltkjl.fljl_x(p::Ptr{Cvoid})::Cint),
     y = Int(@ccall libfltkjl.fljl_y(p::Ptr{Cvoid})::Cint),
     w = Int(@ccall libfltkjl.fljl_w(p::Ptr{Cvoid})::Cint),
     h = Int(@ccall libfltkjl.fljl_h(p::Ptr{Cvoid})::Cint))
end
getprop(w::AW, ::Val{:x}) = bounds(w).x
getprop(w::AW, ::Val{:y}) = bounds(w).y
getprop(w::AW, ::Val{:w}) = bounds(w).w
getprop(w::AW, ::Val{:h}) = bounds(w).h
@prop AW bounds get

"Move and/or resize a widget."
function Base.resize!(w::AW, x::Integer, y::Integer, ww::Integer, hh::Integer)
    @ccall libfltkjl.fljl_resize(_ptr(w)::Ptr{Cvoid}, x::Cint, y::Cint, ww::Cint, hh::Cint)::Cvoid
    return w
end
position!(w::AW, x::Integer, y::Integer) = (b = bounds(w); resize!(w, x, y, b.w, b.h))
size!(w::AW, ww::Integer, hh::Integer) = (b = bounds(w); resize!(w, b.x, b.y, ww, hh))

# ---- label & appearance ------------------------------------------------------
label(w::AW) = _str(@ccall libfltkjl.fljl_label(_ptr(w)::Ptr{Cvoid})::Ptr{UInt8})
function label!(w::AW, s::AbstractString)
    @ccall libfltkjl.fljl_set_label(_ptr(w)::Ptr{Cvoid}, s::Cstring)::Cvoid
    return w
end
@prop AW label

tooltip(w::AW) = _str(@ccall libfltkjl.fljl_tooltip(_ptr(w)::Ptr{Cvoid})::Ptr{UInt8})
function tooltip!(w::AW, s::AbstractString)
    @ccall libfltkjl.fljl_set_tooltip(_ptr(w)::Ptr{Cvoid}, s::Cstring)::Cvoid
    return w
end
@prop AW tooltip

@getset AW labelfont Cint fljl_labelfont fljl_set_labelfont
@getset AW labelsize Cint fljl_labelsize fljl_set_labelsize
@getset AW labelcolor Cuint fljl_labelcolor fljl_set_labelcolor
@getset AW labeltype Cint fljl_labeltype fljl_set_labeltype
@getset AW align Cuint fljl_align fljl_set_align
@getset AW box Cint fljl_box fljl_set_box
@getset AW color Cuint fljl_color fljl_set_color
@getset AW selection_color Cuint fljl_selection_color fljl_set_selection_color
@getset AW when Cint fljl_when fljl_set_when
@getset AW horizontal_label_margin Cint fljl_horizontal_label_margin fljl_set_horizontal_label_margin
@getset AW vertical_label_margin Cint fljl_vertical_label_margin fljl_set_vertical_label_margin
@getset AW label_image_spacing Cint fljl_label_image_spacing fljl_set_label_image_spacing

"The FLTK `type()` of a widget (e.g. `FL_HOR_SLIDER`). Also available as `w.type`."
widgettype(w::AW) = Int(@ccall libfltkjl.fljl_type(_ptr(w)::Ptr{Cvoid})::Cint)
function widgettype!(w::AW, t::Integer)
    @ccall libfltkjl.fljl_set_type(_ptr(w)::Ptr{Cvoid}, t::Cint)::Cvoid
    return w
end
getprop(w::AW, ::Val{:type}) = widgettype(w)
setprop!(w::AW, ::Val{:type}, v) = widgettype!(w, v)

# ---- state -----------------------------------------------------------------
for (jl, c) in ((:show!, :fljl_show), (:hide!, :fljl_hide), (:activate!, :fljl_activate),
                (:deactivate!, :fljl_deactivate), (:redraw!, :fljl_redraw),
                (:redraw_label!, :fljl_redraw_label))
    @eval function $jl(w::AW)
        ccall(($(QuoteNode(c)), libfltkjl), Cvoid, (Ptr{Cvoid},), _ptr(w))
        return w
    end
end
for (jl, c) in ((:isvisible, :fljl_visible), (:isvisible_r, :fljl_visible_r),
                (:isactive, :fljl_active), (:isactive_r, :fljl_active_r),
                (:ischanged, :fljl_changed))
    @eval $jl(w::AW) = ccall(($(QuoteNode(c)), libfltkjl), Cint, (Ptr{Cvoid},), _ptr(w)) != 0
end
take_focus!(w::AW) = (@ccall libfltkjl.fljl_take_focus(_ptr(w)::Ptr{Cvoid})::Cint) != 0
visible_focus!(w::AW, on::Bool) = (@ccall libfltkjl.fljl_set_visible_focus(_ptr(w)::Ptr{Cvoid}, on::Cint)::Cvoid; w)
changed!(w::AW, on::Bool) = (@ccall libfltkjl.fljl_set_changed(_ptr(w)::Ptr{Cvoid}, on::Cint)::Cvoid; w)
damage(w::AW) = Int(@ccall libfltkjl.fljl_damage(_ptr(w)::Ptr{Cvoid})::Cint)

getprop(w::AW, ::Val{:visible}) = isvisible(w)
setprop!(w::AW, ::Val{:visible}, v) = v ? show!(w) : hide!(w)
getprop(w::AW, ::Val{:active}) = isactive(w)
setprop!(w::AW, ::Val{:active}, v) = v ? activate!(w) : deactivate!(w)

"""
    destroy!(w)

Delete the widget (and, for groups, all of its children). Deletion is
deferred to the next turn of the event loop, as `Fl::delete_widget` does.
"""
function destroy!(w::AW)
    isvalid(w) && @ccall libfltkjl.fljl_delete_widget(_ptr(w)::Ptr{Cvoid})::Cvoid
    return nothing
end

# ---- hierarchy ---------------------------------------------------------------
"Two handles are equal when they refer to the same C++ widget."
Base.:(==)(a::AW, b::AW) = getfield(a, :_ptr) == getfield(b, :_ptr)
Base.hash(w::AW, h::UInt) = hash(getfield(w, :_ptr), h)
Base.parent(w::AW) = _wrap(@ccall libfltkjl.fljl_parent(_ptr(w)::Ptr{Cvoid})::Ptr{Cvoid})
window(w::AW) = _wrap(@ccall libfltkjl.fljl_window(_ptr(w)::Ptr{Cvoid})::Ptr{Cvoid})
top_window(w::AW) = _wrap(@ccall libfltkjl.fljl_top_window(_ptr(w)::Ptr{Cvoid})::Ptr{Cvoid})
@prop AW parent get

# ---- callbacks, custom drawing and event handling ----------------------------
"""
    callback!(f, w)
    callback!(w, f)

Set the function called when the widget is activated (a button is pressed, a
slider moved, ...). `f` receives the widget. Use `when!(w, FL_WHEN_...)` to
choose when it fires. Pass `nothing` to remove it. Also `w.callback = f`.
"""
function callback!(w::AW, f)
    if f === nothing
        setfield!(w, :_cb, nothing)
        @ccall libfltkjl.fljl_clear_callback(_ptr(w)::Ptr{Cvoid})::Cvoid
    else
        w isa ForeignWidget && throw(ArgumentError("cannot set a callback on a ForeignWidget"))
        setfield!(w, :_cb, f)
        @ccall libfltkjl.fljl_set_julia_callback(_ptr(w)::Ptr{Cvoid})::Cvoid
    end
    return w
end
callback!(f::Function, w::AW) = callback!(w, f)
setprop!(w::AW, ::Val{:callback}, f) = callback!(w, f)
getprop(w::AW, ::Val{:callback}) = getfield(w, :_cb)

"Invoke the widget's callback as if the user had triggered it."
do_callback(w::AW) = (@ccall libfltkjl.fljl_do_callback(_ptr(w)::Ptr{Cvoid})::Cvoid; w)

"Why the current callback was called (`FL_REASON_*`)."
callback_reason() = Int(@ccall libfltkjl.fljl_callback_reason(C_NULL::Ptr{Cvoid})::Cint)

"""
    draw!(f, w)

Replace the widget's `draw()` with `f(w)`. Inside `f` use the `fl_*` drawing
functions, and `super_draw(w)` to run the widget's normal drawing.
Pass `nothing` to restore the default.
"""
function draw!(w::AW, f)
    w isa ForeignWidget && throw(ArgumentError("cannot override draw on a ForeignWidget"))
    setfield!(w, :_draw, f)
    @ccall libfltkjl.fljl_enable_draw(_ptr(w)::Ptr{Cvoid}, (f !== nothing)::Cint)::Cvoid
    redraw!(w)
end
draw!(f::Function, w::AW) = draw!(w, f)
setprop!(w::AW, ::Val{:draw}, f) = draw!(w, f)

"""
    handle!(f, w)

Replace the widget's `handle(event)` with `f(w, event)`. Return `true` (or
1) if the event was used, `false` (0) if not, or `nothing` to fall back to
the widget's normal handling. `super_handle(w, event)` runs the default
explicitly. Pass `nothing` to restore the default.
"""
function handle!(w::AW, f)
    w isa ForeignWidget && throw(ArgumentError("cannot override handle on a ForeignWidget"))
    setfield!(w, :_handle, f)
    @ccall libfltkjl.fljl_enable_handle(_ptr(w)::Ptr{Cvoid}, (f !== nothing)::Cint)::Cvoid
    return w
end
handle!(f::Function, w::AW) = handle!(w, f)
setprop!(w::AW, ::Val{:handle}, f) = handle!(w, f)

"Run the widget class's own `draw()` (from inside a custom draw function)."
super_draw(w::AW) = (@ccall libfltkjl.fljl_super_draw(_ptr(w)::Ptr{Cvoid})::Cvoid; nothing)
"Run the widget class's own `handle(event)` (from inside a custom handle function)."
super_handle(w::AW, ev::Integer) = Int(@ccall libfltkjl.fljl_super_handle(_ptr(w)::Ptr{Cvoid}, ev::Cint)::Cint)

# ---- images ---------------------------------------------------------------------
"Set the image shown with the widget's label (`nothing` to remove it)."
function image!(w::AW, img)
    getfield(w, :_refs)[:image] = img
    @ccall libfltkjl.fljl_set_image(_ptr(w)::Ptr{Cvoid}, _imgptr(img)::Ptr{Cvoid})::Cvoid
    return w
end
"Set the image shown when the widget is inactive."
function deimage!(w::AW, img)
    getfield(w, :_refs)[:deimage] = img
    @ccall libfltkjl.fljl_set_deimage(_ptr(w)::Ptr{Cvoid}, _imgptr(img)::Ptr{Cvoid})::Cvoid
    return w
end
image(w::AW) = get(getfield(w, :_refs), :image, nothing)
@prop AW image

"Size `(w, h)` needed to draw the label with the current font."
function measure_label(w::AW)
    ww, hh = Ref{Cint}(0), Ref{Cint}(0)
    @ccall libfltkjl.fljl_measure_label(_ptr(w)::Ptr{Cvoid}, ww::Ref{Cint}, hh::Ref{Cint})::Cvoid
    return (Int(ww[]), Int(hh[]))
end

# =============================================================================
# Groups
# =============================================================================
"Make `g` the current group: widgets created next are added to it."
begin_group(g::AbstractGroup) = (@ccall libfltkjl.fljl_begin(_ptr(g)::Ptr{Cvoid})::Cvoid; g)
"Stop adding widgets to `g`; its parent becomes the current group."
end_group(g::AbstractGroup) = (@ccall libfltkjl.fljl_end(_ptr(g)::Ptr{Cvoid})::Cvoid; g)
current_group() = _wrap(@ccall libfltkjl.fljl_current_group()::Ptr{Cvoid})
current_group!(g::Union{Nothing,AbstractGroup}) =
    @ccall libfltkjl.fljl_set_current_group((g === nothing ? C_NULL : _ptr(g))::Ptr{Cvoid})::Cvoid

"Add `child` to group `g` (removing it from its previous parent)."
add!(g::AbstractGroup, c::AW) = (@ccall libfltkjl.fljl_add(_ptr(g)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid})::Cvoid; g)
"Insert `child` into `g` at position `i` (1-based)."
Base.insert!(g::AbstractGroup, i::Integer, c::AW) =
    (@ccall libfltkjl.fljl_insert(_ptr(g)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid}, (i - 1)::Cint)::Cvoid; g)
"Remove `child` from `g` without deleting it."
remove!(g::AbstractGroup, c::AW) = (@ccall libfltkjl.fljl_remove(_ptr(g)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid})::Cvoid; g)
"Delete all children of `g`."
clear!(g::AbstractGroup) = (@ccall libfltkjl.fljl_clear(_ptr(g)::Ptr{Cvoid})::Cvoid; g)

Base.length(g::AbstractGroup) = Int(@ccall libfltkjl.fljl_children(_ptr(g)::Ptr{Cvoid})::Cint)
function Base.getindex(g::AbstractGroup, i::Integer)
    1 <= i <= length(g) || throw(BoundsError(g, i))
    _wrap(@ccall libfltkjl.fljl_child(_ptr(g)::Ptr{Cvoid}, (i - 1)::Cint)::Ptr{Cvoid})
end
Base.iterate(g::AbstractGroup, i = 1) = i > length(g) ? nothing : (g[i], i + 1)
Base.eltype(::Type{<:AbstractGroup}) = AbstractWidget
Base.keys(g::AbstractGroup) = 1:length(g)
children(g::AbstractGroup) = collect(AbstractWidget, g)

"Choose which child absorbs size changes when `g` is resized (`g` itself for all)."
resizable!(g::AbstractGroup, c::Union{Nothing,AW}) =
    (@ccall libfltkjl.fljl_set_resizable(_ptr(g)::Ptr{Cvoid}, (c === nothing ? C_NULL : _ptr(c))::Ptr{Cvoid})::Cvoid; g)
resizable(g::AbstractGroup) = _wrap(@ccall libfltkjl.fljl_resizable(_ptr(g)::Ptr{Cvoid})::Ptr{Cvoid})
@prop AbstractGroup resizable
init_sizes!(g::AbstractGroup) = (@ccall libfltkjl.fljl_init_sizes(_ptr(g)::Ptr{Cvoid})::Cvoid; g)
clip_children!(g::AbstractGroup, on::Bool) = (@ccall libfltkjl.fljl_clip_children(_ptr(g)::Ptr{Cvoid}, on::Cint)::Cvoid; g)

# =============================================================================
# Windows
# =============================================================================
const AWin = AbstractWindow

size_range!(w::AWin, minw, minh, maxw = 0, maxh = 0) =
    (@ccall libfltkjl.fljl_size_range(_ptr(w)::Ptr{Cvoid}, minw::Cint, minh::Cint, maxw::Cint, maxh::Cint)::Cvoid; w)
fullscreen!(w::AWin, on::Bool = true) = (@ccall libfltkjl.fljl_fullscreen(_ptr(w)::Ptr{Cvoid}, on::Cint)::Cvoid; w)
isfullscreen(w::AWin) = (@ccall libfltkjl.fljl_fullscreen_active(_ptr(w)::Ptr{Cvoid})::Cint) != 0
"Make the window modal (blocks other windows while shown)."
modal!(w::AWin) = (@ccall libfltkjl.fljl_set_modal(_ptr(w)::Ptr{Cvoid}, 1::Cint)::Cvoid; w)
"Keep the window above others without blocking them."
non_modal!(w::AWin) = (@ccall libfltkjl.fljl_set_modal(_ptr(w)::Ptr{Cvoid}, 2::Cint)::Cvoid; w)
ismodal(w::AWin) = (@ccall libfltkjl.fljl_modal(_ptr(w)::Ptr{Cvoid})::Cint) != 0
border!(w::AWin, on::Bool) = (@ccall libfltkjl.fljl_border(_ptr(w)::Ptr{Cvoid}, on::Cint)::Cvoid; w)
xclass!(w::AWin, s::AbstractString) = (@ccall libfltkjl.fljl_xclass(_ptr(w)::Ptr{Cvoid}, s::Cstring)::Cvoid; w)
cursor!(w::AWin, c::Integer) = (@ccall libfltkjl.fljl_cursor(_ptr(w)::Ptr{Cvoid}, c::Cint)::Cvoid; w)
"Index (0-based) of the screen the window is on."
screen_num(w::AWin) = Int(@ccall libfltkjl.fljl_window_screen_num(_ptr(w)::Ptr{Cvoid})::Cint)
isshown(w::AWin) = (@ccall libfltkjl.fljl_shown(_ptr(w)::Ptr{Cvoid})::Cint) != 0
iconize!(w::AWin) = (@ccall libfltkjl.fljl_iconize(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
"Position the window so that `target` is under the mouse."
hotspot!(w::AWin, target::AW) = (@ccall libfltkjl.fljl_hotspot(_ptr(w)::Ptr{Cvoid}, _ptr(target)::Ptr{Cvoid})::Cvoid; w)
free_position!(w::AWin) = (@ccall libfltkjl.fljl_free_position(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
"Make the window the target of `fl_*` drawing outside of a draw function."
make_current(w::AWin) = (@ccall libfltkjl.fljl_make_current(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
wait_for_expose(w::AWin) = (@ccall libfltkjl.fljl_wait_for_expose(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
"Set the window icon from an `RGBImage`."
function icon!(w::AWin, img)
    getfield(w, :_refs)[:icon] = img
    @ccall libfltkjl.fljl_window_icon(_ptr(w)::Ptr{Cvoid}, _imgptr(img)::Ptr{Cvoid})::Cvoid
    return w
end
