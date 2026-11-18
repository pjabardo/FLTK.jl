# Concrete widget types and their type-specific methods.

# =============================================================================
# Windows and containers
# =============================================================================
@widget Window AbstractWindow
@widget DoubleWindow AbstractWindow
@widget GlWindow AbstractWindow

for (T, dbl) in ((:Window, 0), (:DoubleWindow, 1))
    @eval function $T(w::Integer, h::Integer, label::AbstractString = ""; kw...)
        p = @ccall libfltkjl.fljl_new_window_wh(w::Cint, h::Cint, label::Cstring, $dbl::Cint)::Ptr{Cvoid}
        _finish($T(p, nothing, nothing, nothing, Dict{Symbol,Any}()), kw)
    end
end

@widget Group AbstractGroup
@widget Tabs AbstractGroup
@widget Scroll AbstractGroup
@widget Pack AbstractGroup
@widget Tile AbstractGroup
@widget Flex AbstractGroup
@widget Grid AbstractGroup
@widget Wizard AbstractGroup

# ---- Tabs / Wizard: the visible child --------------------------------------------
value(t::Tabs) = _wrap(@ccall libfltkjl.fljl_tabs_value(_ptr(t)::Ptr{Cvoid})::Ptr{Cvoid})
value!(t::Tabs, c::AbstractWidget) = (@ccall libfltkjl.fljl_tabs_set_value(_ptr(t)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid})::Cvoid; t)
value(t::Wizard) = _wrap(@ccall libfltkjl.fljl_wizard_value(_ptr(t)::Ptr{Cvoid})::Ptr{Cvoid})
value!(t::Wizard, c::AbstractWidget) = (@ccall libfltkjl.fljl_wizard_set_value(_ptr(t)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid})::Cvoid; t)
next!(t::Wizard) = (@ccall libfltkjl.fljl_wizard_next(_ptr(t)::Ptr{Cvoid})::Cvoid; t)
prev!(t::Wizard) = (@ccall libfltkjl.fljl_wizard_prev(_ptr(t)::Ptr{Cvoid})::Cvoid; t)

# ---- Scroll ----------------------------------------------------------------
scroll_to!(s::Scroll, x::Integer, y::Integer) = (@ccall libfltkjl.fljl_scroll_to(_ptr(s)::Ptr{Cvoid}, x::Cint, y::Cint)::Cvoid; s)
xposition(s::Scroll) = Int(@ccall libfltkjl.fljl_scroll_xposition(_ptr(s)::Ptr{Cvoid})::Cint)
yposition(s::Scroll) = Int(@ccall libfltkjl.fljl_scroll_yposition(_ptr(s)::Ptr{Cvoid})::Cint)

# ---- Pack ------------------------------------------------------------------
spacing!(p::Pack, s::Integer) = (@ccall libfltkjl.fljl_pack_spacing(_ptr(p)::Ptr{Cvoid}, s::Cint)::Cvoid; p)
@prop Pack spacing set

# ---- Flex ------------------------------------------------------------------
"""
    Flex(x, y, w, h; direction = FLEX_COLUMN, margin = 0, gap = 0) do flex ... end

A row or column that sizes its children automatically. Use
`fixed!(flex, child, size)` to give a child a fixed size.
"""
Flex

direction!(f::Flex, d::Integer) = (@ccall libfltkjl.fljl_flex_set_type(_ptr(f)::Ptr{Cvoid}, d::Cint)::Cvoid; f)
@prop Flex direction set
"Give `child` a fixed width (row) or height (column) inside `flex`."
fixed!(f::Flex, c::AbstractWidget, size::Integer) =
    (@ccall libfltkjl.fljl_flex_fixed(_ptr(f)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid}, size::Cint)::Cvoid; f)
margin!(f::Flex, m::Integer) = margin!(f, m, m, m, m)
margin!(f::Flex, l::Integer, t::Integer, r::Integer, b::Integer) =
    (@ccall libfltkjl.fljl_flex_margin(_ptr(f)::Ptr{Cvoid}, l::Cint, t::Cint, r::Cint, b::Cint)::Cvoid; f)
gap!(f::Flex, g::Integer) = (@ccall libfltkjl.fljl_flex_gap(_ptr(f)::Ptr{Cvoid}, g::Cint)::Cvoid; f)
layout!(f::Flex) = (@ccall libfltkjl.fljl_flex_layout(_ptr(f)::Ptr{Cvoid})::Cvoid; f)
@prop Flex margin set
@prop Flex gap set
_postinit(f::Flex) = (end_group(f); nothing)
# Flex lays out again when closed so children placed in a do-block fit.
function (::Type{Flex})(f::Function, args...; kw...)
    g = Flex(args...; kw...)
    begin_group(g)
    try
        f(g)
    finally
        end_group(g)
    end
    layout!(g)
    return g
end
Flex(x::Integer, y::Integer, w::Integer, h::Integer, d::Integer; kw...) = Flex(x, y, w, h; direction = d, kw...)

# ---- Grid (rows and columns are 0-based, as in FLTK) ------------------------------
"""
    layout!(grid, rows, cols; margin = -1, gap = -1)

Define the grid's size. Then place children with `place!`.
"""
layout!(g::Grid, rows::Integer, cols::Integer; margin::Integer = -1, gap::Integer = -1) =
    (@ccall libfltkjl.fljl_grid_layout(_ptr(g)::Ptr{Cvoid}, rows::Cint, cols::Cint, margin::Cint, gap::Cint)::Cvoid; g)
layout!(g::Grid) = (@ccall libfltkjl.fljl_grid_relayout(_ptr(g)::Ptr{Cvoid})::Cvoid; g)
"""
    place!(grid, child, row, col; rowspan = 1, colspan = 1, align = FL_GRID_FILL)

Assign `child` to a grid cell (0-based row and column, as in FLTK).
"""
place!(g::Grid, c::AbstractWidget, row::Integer, col::Integer; rowspan::Integer = 1, colspan::Integer = 1,
       align::Integer = FL_GRID_FILL) =
    (@ccall libfltkjl.fljl_grid_widget(_ptr(g)::Ptr{Cvoid}, _ptr(c)::Ptr{Cvoid}, row::Cint, col::Cint,
                                       rowspan::Cint, colspan::Cint, align::Cint)::Cvoid; g)
margin!(g::Grid, m::Integer) = margin!(g, m, m, m, m)
margin!(g::Grid, l::Integer, t::Integer, r::Integer, b::Integer) =
    (@ccall libfltkjl.fljl_grid_margin(_ptr(g)::Ptr{Cvoid}, l::Cint, t::Cint, r::Cint, b::Cint)::Cvoid; g)
gap!(g::Grid, rowgap::Integer, colgap::Integer = rowgap) =
    (@ccall libfltkjl.fljl_grid_gap(_ptr(g)::Ptr{Cvoid}, rowgap::Cint, colgap::Cint)::Cvoid; g)
for f in (:col_width, :col_weight, :col_gap, :row_height, :row_weight, :row_gap)
    jl = Symbol(f, "!")
    c = QuoteNode(Symbol("fljl_grid_", f))
    @eval $jl(g::Grid, i::Integer, v::Integer) = (ccall(($c, libfltkjl), Cvoid, (Ptr{Cvoid}, Cint, Cint), _ptr(g), i, v); g)
    @eval $jl(g::Grid, vs::AbstractVector{<:Integer}) = (for (i, v) in enumerate(vs); $jl(g, i - 1, v); end; g)
end
show_grid!(g::Grid, on::Bool = true) = (@ccall libfltkjl.fljl_grid_show_grid(_ptr(g)::Ptr{Cvoid}, on::Cint)::Cvoid; g)

# ---- OpenGL window ------------------------------------------------------------
gl_mode!(w::GlWindow, m::Integer) = (@ccall libfltkjl.fljl_gl_mode(_ptr(w)::Ptr{Cvoid}, m::Cint)::Cvoid; w)
gl_valid(w::GlWindow) = (@ccall libfltkjl.fljl_gl_valid(_ptr(w)::Ptr{Cvoid})::Cint) != 0
gl_invalidate!(w::GlWindow) = (@ccall libfltkjl.fljl_gl_invalidate(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
gl_context_valid(w::GlWindow) = (@ccall libfltkjl.fljl_gl_context_valid(_ptr(w)::Ptr{Cvoid})::Cint) != 0
swap_buffers(w::GlWindow) = (@ccall libfltkjl.fljl_gl_swap_buffers(_ptr(w)::Ptr{Cvoid})::Cvoid; w)
pixel_size(w::GlWindow) = (Int(@ccall libfltkjl.fljl_gl_pixel_w(_ptr(w)::Ptr{Cvoid})::Cint),
                           Int(@ccall libfltkjl.fljl_gl_pixel_h(_ptr(w)::Ptr{Cvoid})::Cint))
make_current(w::GlWindow) = (@ccall libfltkjl.fljl_gl_make_current(_ptr(w)::Ptr{Cvoid})::Cvoid; w)

# =============================================================================
# Simple widgets
# =============================================================================
@widget Box AbstractWidget
@widget Clock AbstractWidget

# =============================================================================
# Buttons
# =============================================================================
@widget Button AbstractButton
@widget LightButton AbstractButton
@widget CheckButton AbstractButton
@widget RoundButton AbstractButton
@widget RadioButton AbstractButton
@widget RadioRoundButton AbstractButton
@widget RadioLightButton AbstractButton
@widget ToggleButton AbstractButton
@widget ReturnButton AbstractButton
@widget RepeatButton AbstractButton

"For buttons: whether the button is on (pressed, checked, selected)."
value(b::AbstractButton) = (@ccall libfltkjl.fljl_button_value(_ptr(b)::Ptr{Cvoid})::Cint) != 0
value!(b::AbstractButton, v::Bool) = (@ccall libfltkjl.fljl_button_set_value(_ptr(b)::Ptr{Cvoid}, v::Cint)::Cvoid; b)
value!(b::AbstractButton, v::Integer) = value!(b, v != 0)
"Turn on this radio button and turn off the others in its group."
setonly!(b::AbstractButton) = (@ccall libfltkjl.fljl_button_setonly(_ptr(b)::Ptr{Cvoid})::Cvoid; b)
@getset AbstractButton shortcut Cint fljl_button_shortcut fljl_button_set_shortcut
down_box!(b::AbstractButton, bx::Integer) = (@ccall libfltkjl.fljl_button_set_down_box(_ptr(b)::Ptr{Cvoid}, bx::Cint)::Cvoid; b)
@prop AbstractButton down_box set

# =============================================================================
# Text input
# =============================================================================
@widget Input AbstractInput
@widget IntInput AbstractInput
@widget FloatInput AbstractInput
@widget SecretInput AbstractInput
@widget MultilineInput AbstractInput
@widget Output AbstractInput
@widget MultilineOutput AbstractInput

value(i::AbstractInput) = _str(@ccall libfltkjl.fljl_input_value(_ptr(i)::Ptr{Cvoid})::Ptr{UInt8})
value!(i::AbstractInput, s::AbstractString) = (@ccall libfltkjl.fljl_input_set_value(_ptr(i)::Ptr{Cvoid}, s::Cstring)::Cvoid; i)
value!(i::AbstractInput, x) = value!(i, string(x))
Base.length(i::AbstractInput) = Int(@ccall libfltkjl.fljl_input_size(_ptr(i)::Ptr{Cvoid})::Cint)
@getset AbstractInput maximum_size Cint fljl_input_maximum_size fljl_input_set_maximum_size
@getset AbstractInput textfont Cint fljl_input_textfont fljl_input_set_textfont
@getset AbstractInput textsize Cint fljl_input_textsize fljl_input_set_textsize
@getset AbstractInput textcolor Cuint fljl_input_textcolor fljl_input_set_textcolor
readonly(i::AbstractInput) = (@ccall libfltkjl.fljl_input_readonly(_ptr(i)::Ptr{Cvoid})::Cint) != 0
readonly!(i::AbstractInput, on::Bool) = (@ccall libfltkjl.fljl_input_set_readonly(_ptr(i)::Ptr{Cvoid}, on::Cint)::Cvoid; i)
@prop AbstractInput readonly
wrap!(i::AbstractInput, on::Bool) = (@ccall libfltkjl.fljl_input_set_wrap(_ptr(i)::Ptr{Cvoid}, on::Cint)::Cvoid; i)
"Cursor position (0-based byte offset, as in FLTK)."
insert_position(i::AbstractInput) = Int(@ccall libfltkjl.fljl_input_insert_position(_ptr(i)::Ptr{Cvoid})::Cint)
Base.mark(i::AbstractInput) = Int(@ccall libfltkjl.fljl_input_mark(_ptr(i)::Ptr{Cvoid})::Cint)
insert_position!(i::AbstractInput, p::Integer, m::Integer = p) =
    (@ccall libfltkjl.fljl_input_set_position(_ptr(i)::Ptr{Cvoid}, p::Cint, m::Cint)::Cvoid; i)
"Insert text at the cursor, replacing the selection."
insert_text!(i::AbstractInput, s::AbstractString) = (@ccall libfltkjl.fljl_input_insert(_ptr(i)::Ptr{Cvoid}, s::Cstring)::Cint; i)
"Delete bytes `a` to `b` (0-based)."
cut!(i::AbstractInput, a::Integer, b::Integer) = (@ccall libfltkjl.fljl_input_cut(_ptr(i)::Ptr{Cvoid}, a::Cint, b::Cint)::Cint; i)

# =============================================================================
# Valuators
# =============================================================================
@widget Slider AbstractValuator
@widget HorSlider AbstractValuator
@widget NiceSlider AbstractValuator
@widget HorNiceSlider AbstractValuator
@widget FillSlider AbstractValuator
@widget ValueSlider AbstractValuator
@widget HorValueSlider AbstractValuator
@widget Scrollbar AbstractValuator
@widget Dial AbstractValuator
@widget Roller AbstractValuator
@widget Counter AbstractValuator
@widget Adjuster AbstractValuator
@widget ValueInput AbstractValuator
@widget ValueOutput AbstractValuator

const AV = AbstractValuator
value(v::AV) = @ccall libfltkjl.fljl_valuator_value(_ptr(v)::Ptr{Cvoid})::Cdouble
value!(v::AV, x::Real) = (@ccall libfltkjl.fljl_valuator_set_value(_ptr(v)::Ptr{Cvoid}, x::Cdouble)::Cint; v)
Base.minimum(v::AV) = @ccall libfltkjl.fljl_valuator_minimum(_ptr(v)::Ptr{Cvoid})::Cdouble
Base.maximum(v::AV) = @ccall libfltkjl.fljl_valuator_maximum(_ptr(v)::Ptr{Cvoid})::Cdouble
Base.step(v::AV) = @ccall libfltkjl.fljl_valuator_step(_ptr(v)::Ptr{Cvoid})::Cdouble
Base.minimum!(v::AV, x::Real) = (@ccall libfltkjl.fljl_valuator_set_minimum(_ptr(v)::Ptr{Cvoid}, x::Cdouble)::Cvoid; v)
Base.maximum!(v::AV, x::Real) = (@ccall libfltkjl.fljl_valuator_set_maximum(_ptr(v)::Ptr{Cvoid}, x::Cdouble)::Cvoid; v)
step!(v::AV, x::Real) = (@ccall libfltkjl.fljl_valuator_set_step(_ptr(v)::Ptr{Cvoid}, x::Cdouble)::Cvoid; v)
"Set minimum and maximum at once."
range!(v::AV, lo::Real, hi::Real) = (minimum!(v, lo); maximum!(v, hi))
range!(v::AV, r::AbstractRange) = (range!(v, first(r), last(r)); step!(v, step(r)))
"Show/round values to `digits` decimal places."
precision!(v::AV, digits::Integer) = (@ccall libfltkjl.fljl_valuator_precision(_ptr(v)::Ptr{Cvoid}, digits::Cint)::Cvoid; v)
"The value as text, formatted the way the widget displays it."
function format(v::AV)
    buf = zeros(UInt8, 128)
    @ccall libfltkjl.fljl_valuator_format(_ptr(v)::Ptr{Cvoid}, buf::Ptr{UInt8})::Cvoid
    unsafe_string(pointer(buf))
end
slider_size!(v::AV, f::Real) = (@ccall libfltkjl.fljl_slider_size(_ptr(v)::Ptr{Cvoid}, f::Cdouble)::Cvoid; v)
slider_box!(v::AV, b::Integer) = (@ccall libfltkjl.fljl_slider_set_box(_ptr(v)::Ptr{Cvoid}, b::Cint)::Cvoid; v)
textsize!(v::Union{ValueSlider,HorValueSlider}, s::Integer) =
    (@ccall libfltkjl.fljl_value_slider_textsize(_ptr(v)::Ptr{Cvoid}, s::Cint)::Cvoid; v)
"Step used by the large (double-arrow) buttons of a `Counter`."
lstep!(c::Counter, s::Real) = (@ccall libfltkjl.fljl_counter_lstep(_ptr(c)::Ptr{Cvoid}, s::Cdouble)::Cvoid; c)
angles!(d::Dial, a::Integer, b::Integer) = (@ccall libfltkjl.fljl_dial_angles(_ptr(d)::Ptr{Cvoid}, a::Cint, b::Cint)::Cvoid; d)
linesize!(s::Scrollbar, n::Integer) = (@ccall libfltkjl.fljl_scrollbar_linesize(_ptr(s)::Ptr{Cvoid}, n::Cint)::Cvoid; s)

# ---- Spinner and Progress are not Fl_Valuators but share the interface ----------
@widget Spinner AbstractWidget
@widget Progress AbstractWidget

value(s::Spinner) = @ccall libfltkjl.fljl_spinner_value(_ptr(s)::Ptr{Cvoid})::Cdouble
value!(s::Spinner, x::Real) = (@ccall libfltkjl.fljl_spinner_set_value(_ptr(s)::Ptr{Cvoid}, x::Cdouble)::Cvoid; s)
Base.minimum(s::Spinner) = @ccall libfltkjl.fljl_spinner_minimum(_ptr(s)::Ptr{Cvoid})::Cdouble
Base.maximum(s::Spinner) = @ccall libfltkjl.fljl_spinner_maximum(_ptr(s)::Ptr{Cvoid})::Cdouble
Base.step(s::Spinner) = @ccall libfltkjl.fljl_spinner_step(_ptr(s)::Ptr{Cvoid})::Cdouble
Base.minimum!(s::Spinner, x::Real) = (@ccall libfltkjl.fljl_spinner_set_minimum(_ptr(s)::Ptr{Cvoid}, x::Cdouble)::Cvoid; s)
Base.maximum!(s::Spinner, x::Real) = (@ccall libfltkjl.fljl_spinner_set_maximum(_ptr(s)::Ptr{Cvoid}, x::Cdouble)::Cvoid; s)
step!(s::Spinner, x::Real) = (@ccall libfltkjl.fljl_spinner_set_step(_ptr(s)::Ptr{Cvoid}, x::Cdouble)::Cvoid; s)
range!(s::Spinner, lo::Real, hi::Real) = (minimum!(s, lo); maximum!(s, hi))
"Printf-style format of the displayed value, e.g. `\"%.2f\"`."
format!(s::Spinner, f::AbstractString) = (@ccall libfltkjl.fljl_spinner_set_format(_ptr(s)::Ptr{Cvoid}, f::Cstring)::Cvoid; s)
textsize!(s::Spinner, n::Integer) = (@ccall libfltkjl.fljl_spinner_textsize(_ptr(s)::Ptr{Cvoid}, n::Cint)::Cvoid; s)
# Fl_Spinner::type() must be FL_INT_INPUT or FL_FLOAT_INPUT and goes through its own setter.
widgettype!(s::Spinner, t::Integer) = (@ccall libfltkjl.fljl_spinner_set_type(_ptr(s)::Ptr{Cvoid}, t::Cint)::Cvoid; s)

value(p::Progress) = @ccall libfltkjl.fljl_progress_value(_ptr(p)::Ptr{Cvoid})::Cdouble
value!(p::Progress, x::Real) = (@ccall libfltkjl.fljl_progress_set_value(_ptr(p)::Ptr{Cvoid}, x::Cdouble)::Cvoid; p)
Base.minimum(p::Progress) = @ccall libfltkjl.fljl_progress_minimum(_ptr(p)::Ptr{Cvoid})::Cdouble
Base.maximum(p::Progress) = @ccall libfltkjl.fljl_progress_maximum(_ptr(p)::Ptr{Cvoid})::Cdouble
Base.minimum!(p::Progress, x::Real) = (@ccall libfltkjl.fljl_progress_set_minimum(_ptr(p)::Ptr{Cvoid}, x::Cdouble)::Cvoid; p)
Base.maximum!(p::Progress, x::Real) = (@ccall libfltkjl.fljl_progress_set_maximum(_ptr(p)::Ptr{Cvoid}, x::Cdouble)::Cvoid; p)
range!(p::Progress, lo::Real, hi::Real) = (minimum!(p, lo); maximum!(p, hi))

const _Ranged = Union{AV,Spinner,Progress}
@prop _Ranged minimum
@prop _Ranged maximum
@prop Union{AV,Spinner} step
@prop Union{AV} precision set
getprop(v::_Ranged, ::Val{:range}) = (minimum(v), maximum(v))
setprop!(v::_Ranged, ::Val{:range}, r) = range!(v, r...)
setprop!(v::AV, ::Val{:range}, r::AbstractRange) = range!(v, r)

# =============================================================================
# Menus (indices are 0-based, as in FLTK)
# =============================================================================
@widget MenuBar AbstractMenu
@widget MenuButton AbstractMenu
@widget Choice AbstractMenu

const AM = AbstractMenu

"""
    add_item!(menu, label; shortcut = 0, flags = 0, callback = nothing) -> index

Add an item. `label` may be a path such as `"File/Open..."` to create
submenus. `shortcut` is e.g. `FL_CTRL + Int('o')`. `flags` combines
`FL_MENU_*` values. If `callback` is `nothing`, the menu widget's own
callback runs when the item is chosen. Returns the item's 0-based index.
"""
function add_item!(m::AM, label::AbstractString; shortcut::Integer = 0, flags::Integer = 0, callback = nothing)
    id = _menu_callback_id(m, callback)
    Int(@ccall libfltkjl.fljl_menu_add(_ptr(m)::Ptr{Cvoid}, label::Cstring, shortcut::Cint, id::Int, flags::Cint)::Cint)
end
add_item!(f::Function, m::AM, label::AbstractString; kw...) = add_item!(m, label; callback = f, kw...)

"Insert an item at 0-based index `i`. Same keywords as `add_item!`."
function insert_item!(m::AM, i::Integer, label::AbstractString; shortcut::Integer = 0, flags::Integer = 0, callback = nothing)
    id = _menu_callback_id(m, callback)
    Int(@ccall libfltkjl.fljl_menu_insert(_ptr(m)::Ptr{Cvoid}, i::Cint, label::Cstring, shortcut::Cint, id::Int, flags::Cint)::Cint)
end

function _menu_callback_id(m::AM, f)
    f === nothing && return 0
    id = (_next_menu_id[] += 1)
    _menu_callbacks[id] = f
    push!(get!(Vector{Int}, getfield(m, :_refs), :menu_ids), id)
    return id
end

"Add several plain items (convenient for `Choice`)."
add_items!(m::AM, labels) = (foreach(l -> add_item!(m, l), labels); m)
setprop!(m::AM, ::Val{:items}, labels) = (clear!(m); add_items!(m, labels))

"Index of the selected/last chosen item, or -1."
value(m::AM) = Int(@ccall libfltkjl.fljl_menu_value(_ptr(m)::Ptr{Cvoid})::Cint)
value!(m::AM, i::Integer) = (@ccall libfltkjl.fljl_menu_set_value(_ptr(m)::Ptr{Cvoid}, i::Cint)::Cint; m)
"Label of the chosen item (`nothing` if none)."
text(m::AM) = _str_or_nothing(@ccall libfltkjl.fljl_menu_text(_ptr(m)::Ptr{Cvoid})::Ptr{UInt8})
"Label of the item at index `i`."
text(m::AM, i::Integer) = _str_or_nothing(@ccall libfltkjl.fljl_menu_text_at(_ptr(m)::Ptr{Cvoid}, i::Cint)::Ptr{UInt8})
"Full path (e.g. `\"File/Open\"`) of item `i`, default the chosen one."
function item_path(m::AM, i::Integer = Int(@ccall libfltkjl.fljl_menu_mvalue_index(_ptr(m)::Ptr{Cvoid})::Cint))
    buf = zeros(UInt8, 1024)
    r = @ccall libfltkjl.fljl_menu_item_pathname(_ptr(m)::Ptr{Cvoid}, buf::Ptr{UInt8}, 1024::Cint, i::Cint)::Cint
    r == 0 ? unsafe_string(pointer(buf)) : nothing
end
"Number of menu entries, including the hidden submenu terminators."
Base.length(m::AM) = Int(@ccall libfltkjl.fljl_menu_size(_ptr(m)::Ptr{Cvoid})::Cint)
clear!(m::AM) = (@ccall libfltkjl.fljl_menu_clear(_ptr(m)::Ptr{Cvoid})::Cvoid; m)
remove_item!(m::AM, i::Integer) = (@ccall libfltkjl.fljl_menu_remove(_ptr(m)::Ptr{Cvoid}, i::Cint)::Cvoid; m)
replace_item!(m::AM, i::Integer, s::AbstractString) = (@ccall libfltkjl.fljl_menu_replace(_ptr(m)::Ptr{Cvoid}, i::Cint, s::Cstring)::Cvoid; m)
"Index of the item with the given path (e.g. `\"File/Quit\"`), or -1."
find_index(m::AM, path::AbstractString) = Int(@ccall libfltkjl.fljl_menu_find_index(_ptr(m)::Ptr{Cvoid}, path::Cstring)::Cint)
"`FL_MENU_*` flags of item `i`."
mode(m::AM, i::Integer) = Int(@ccall libfltkjl.fljl_menu_mode(_ptr(m)::Ptr{Cvoid}, i::Cint)::Cint)
mode!(m::AM, i::Integer, f::Integer) = (@ccall libfltkjl.fljl_menu_set_mode(_ptr(m)::Ptr{Cvoid}, i::Cint, f::Cint)::Cvoid; m)
"On/off state of a toggle or radio item."
item_value(m::AM, i::Integer) = (@ccall libfltkjl.fljl_menu_item_value(_ptr(m)::Ptr{Cvoid}, i::Cint)::Cint) != 0
item_value!(m::AM, i::Integer, v::Bool) = (@ccall libfltkjl.fljl_menu_item_set_value(_ptr(m)::Ptr{Cvoid}, i::Cint, v::Cint)::Cvoid; m)
textsize!(m::AM, s::Integer) = (@ccall libfltkjl.fljl_menu_textsize(_ptr(m)::Ptr{Cvoid}, s::Cint)::Cvoid; m)
textfont!(m::AM, f::Integer) = (@ccall libfltkjl.fljl_menu_textfont(_ptr(m)::Ptr{Cvoid}, f::Cint)::Cvoid; m)
down_box!(m::AM, b::Integer) = (@ccall libfltkjl.fljl_menu_down_box(_ptr(m)::Ptr{Cvoid}, b::Cint)::Cvoid; m)
"Pop up the menu at the mouse; returns the chosen index or -1."
popup(m::MenuButton) = Int(@ccall libfltkjl.fljl_menu_button_popup(_ptr(m)::Ptr{Cvoid})::Cint)

# =============================================================================
# Browsers (lines are 1-based, as in FLTK)
# =============================================================================
@widget Browser AbstractBrowser
@widget HoldBrowser AbstractBrowser
@widget SelectBrowser AbstractBrowser
@widget MultiBrowser AbstractBrowser

const AB = AbstractBrowser
"Append a line of text."
add!(b::AB, s::AbstractString) = (@ccall libfltkjl.fljl_browser_add(_ptr(b)::Ptr{Cvoid}, s::Cstring)::Cvoid; b)
add!(b::AB, lines::AbstractVector{<:AbstractString}) = (foreach(l -> add!(b, l), lines); b)
Base.insert!(b::AB, line::Integer, s::AbstractString) =
    (@ccall libfltkjl.fljl_browser_insert(_ptr(b)::Ptr{Cvoid}, line::Cint, s::Cstring)::Cvoid; b)
Base.deleteat!(b::AB, line::Integer) = (@ccall libfltkjl.fljl_browser_remove(_ptr(b)::Ptr{Cvoid}, line::Cint)::Cvoid; b)
clear!(b::AB) = (@ccall libfltkjl.fljl_browser_clear(_ptr(b)::Ptr{Cvoid})::Cvoid; b)
Base.length(b::AB) = Int(@ccall libfltkjl.fljl_browser_size(_ptr(b)::Ptr{Cvoid})::Cint)
"Selected line (1-based), or 0 if none."
value(b::AB) = Int(@ccall libfltkjl.fljl_browser_value(_ptr(b)::Ptr{Cvoid})::Cint)
value!(b::AB, line::Integer) = (@ccall libfltkjl.fljl_browser_set_value(_ptr(b)::Ptr{Cvoid}, line::Cint)::Cvoid; b)
text(b::AB, line::Integer) = _str_or_nothing(@ccall libfltkjl.fljl_browser_text(_ptr(b)::Ptr{Cvoid}, line::Cint)::Ptr{UInt8})
text!(b::AB, line::Integer, s::AbstractString) = (@ccall libfltkjl.fljl_browser_set_text(_ptr(b)::Ptr{Cvoid}, line::Cint, s::Cstring)::Cvoid; b)
"Text of the selected line, or `nothing`."
text(b::AB) = (v = value(b); v == 0 ? nothing : text(b, v))
Base.getindex(b::AB, line::Integer) = (1 <= line <= length(b) || throw(BoundsError(b, line)); text(b, line))
Base.setindex!(b::AB, s::AbstractString, line::Integer) = text!(b, line, s)
Base.iterate(b::AB, i = 1) = i > length(b) ? nothing : (text(b, i), i + 1)
Base.eltype(::Type{<:AB}) = String
select!(b::AB, line::Integer, on::Bool = true) = (@ccall libfltkjl.fljl_browser_select(_ptr(b)::Ptr{Cvoid}, line::Cint, on::Cint)::Cint; b)
isselected(b::AB, line::Integer) = (@ccall libfltkjl.fljl_browser_selected(_ptr(b)::Ptr{Cvoid}, line::Cint)::Cint) != 0
"All selected line numbers (useful for `MultiBrowser`)."
selected_lines(b::AB) = [i for i in 1:length(b) if isselected(b, i)]
topline!(b::AB, line::Integer) = (@ccall libfltkjl.fljl_browser_topline(_ptr(b)::Ptr{Cvoid}, line::Cint)::Cvoid; b)
bottomline!(b::AB, line::Integer) = (@ccall libfltkjl.fljl_browser_bottomline(_ptr(b)::Ptr{Cvoid}, line::Cint)::Cvoid; b)
"Character that separates columns in a line (default tab)."
column_char!(b::AB, c::Char) = (@ccall libfltkjl.fljl_browser_column_char(_ptr(b)::Ptr{Cvoid}, UInt8(c)::UInt8)::Cvoid; b)
"Character that starts `@` formatting codes; `'\\0'` disables them."
format_char!(b::AB, c::Char) = (@ccall libfltkjl.fljl_browser_format_char(_ptr(b)::Ptr{Cvoid}, UInt8(c)::UInt8)::Cvoid; b)
function column_widths!(b::AB, ws::AbstractVector{<:Integer})
    v = Cint.(ws)
    @ccall libfltkjl.fljl_browser_column_widths(_ptr(b)::Ptr{Cvoid}, v::Ptr{Cint}, length(v)::Cint)::Cvoid
    return b
end
"Replace the contents with the lines of a file."
load!(b::AB, file::AbstractString) = ((@ccall libfltkjl.fljl_browser_load(_ptr(b)::Ptr{Cvoid}, file::Cstring)::Cint) != 0 ||
                                        error("could not load $file"); b)
textsize!(b::AB, s::Integer) = (@ccall libfltkjl.fljl_browser_textsize(_ptr(b)::Ptr{Cvoid}, s::Cint)::Cvoid; b)
textfont!(b::AB, f::Integer) = (@ccall libfltkjl.fljl_browser_textfont(_ptr(b)::Ptr{Cvoid}, f::Cint)::Cvoid; b)
setprop!(b::AB, ::Val{:items}, lines) = (clear!(b); add!(b, collect(lines)))

# ---- CheckBrowser (items are 1-based) -------------------------------------------
@widget CheckBrowser AbstractWidget
add!(b::CheckBrowser, s::AbstractString, checked::Bool = false) =
    (@ccall libfltkjl.fljl_check_browser_add(_ptr(b)::Ptr{Cvoid}, s::Cstring, checked::Cint)::Cint; b)
add!(b::CheckBrowser, lines::AbstractVector{<:AbstractString}) = (foreach(l -> add!(b, l), lines); b)
Base.length(b::CheckBrowser) = Int(@ccall libfltkjl.fljl_check_browser_nitems(_ptr(b)::Ptr{Cvoid})::Cint)
nchecked(b::CheckBrowser) = Int(@ccall libfltkjl.fljl_check_browser_nchecked(_ptr(b)::Ptr{Cvoid})::Cint)
ischecked(b::CheckBrowser, i::Integer) = (@ccall libfltkjl.fljl_check_browser_checked(_ptr(b)::Ptr{Cvoid}, i::Cint)::Cint) != 0
checked!(b::CheckBrowser, i::Integer, on::Bool) = (@ccall libfltkjl.fljl_check_browser_set_checked(_ptr(b)::Ptr{Cvoid}, i::Cint, on::Cint)::Cvoid; b)
check_all!(b::CheckBrowser) = (@ccall libfltkjl.fljl_check_browser_check_all(_ptr(b)::Ptr{Cvoid}, 1::Cint)::Cvoid; b)
check_none!(b::CheckBrowser) = (@ccall libfltkjl.fljl_check_browser_check_all(_ptr(b)::Ptr{Cvoid}, 0::Cint)::Cvoid; b)
clear!(b::CheckBrowser) = (@ccall libfltkjl.fljl_check_browser_clear(_ptr(b)::Ptr{Cvoid})::Cvoid; b)
text(b::CheckBrowser, i::Integer) = _str_or_nothing(@ccall libfltkjl.fljl_check_browser_text(_ptr(b)::Ptr{Cvoid}, i::Cint)::Ptr{UInt8})
value(b::CheckBrowser) = Int(@ccall libfltkjl.fljl_check_browser_value(_ptr(b)::Ptr{Cvoid})::Cint)
"Texts of all checked items."
checked_items(b::CheckBrowser) = [text(b, i) for i in 1:length(b) if ischecked(b, i)]

# =============================================================================
# Text editing
# =============================================================================
"""
    TextBuffer(text = "")

Text storage shown by `TextView` and `TextEditor`. Positions are 0-based
byte offsets, as in FLTK.
"""
mutable struct TextBuffer
    _ptr::Ptr{Cvoid}
    function TextBuffer(s::AbstractString = "")
        b = new(@ccall libfltkjl.fljl_textbuffer_new()::Ptr{Cvoid})
        isempty(s) || text!(b, s)
        finalizer(x -> _queue_free(:textbuffer, x), b)
    end
end
_bptr(b::TextBuffer) = (p = getfield(b, :_ptr); p == C_NULL && throw(ArgumentError("TextBuffer has been freed")); p)
function text(b::TextBuffer)
    p = @ccall libfltkjl.fljl_textbuffer_text(_bptr(b)::Ptr{Cvoid})::Ptr{UInt8}
    s = unsafe_string(p)
    @ccall libfltkjl.fljl_free(p::Ptr{UInt8})::Cvoid
    return s
end
text!(b::TextBuffer, s::AbstractString) = (@ccall libfltkjl.fljl_textbuffer_set_text(_bptr(b)::Ptr{Cvoid}, s::Cstring)::Cvoid; b)
Base.append!(b::TextBuffer, s::AbstractString) = (@ccall libfltkjl.fljl_textbuffer_append(_bptr(b)::Ptr{Cvoid}, s::Cstring)::Cvoid; b)
Base.insert!(b::TextBuffer, pos::Integer, s::AbstractString) =
    (@ccall libfltkjl.fljl_textbuffer_insert(_bptr(b)::Ptr{Cvoid}, pos::Cint, s::Cstring)::Cvoid; b)
"Delete text from byte `start` to `stop` (0-based, end-exclusive)."
remove_text!(b::TextBuffer, start::Integer, stop::Integer) =
    (@ccall libfltkjl.fljl_textbuffer_remove(_bptr(b)::Ptr{Cvoid}, start::Cint, stop::Cint)::Cvoid; b)
Base.length(b::TextBuffer) = Int(@ccall libfltkjl.fljl_textbuffer_length(_bptr(b)::Ptr{Cvoid})::Cint)
Base.empty!(b::TextBuffer) = text!(b, "")
loadfile!(b::TextBuffer, f::AbstractString) =
    ((@ccall libfltkjl.fljl_textbuffer_loadfile(_bptr(b)::Ptr{Cvoid}, f::Cstring)::Cint) == 0 || error("could not load $f"); b)
savefile(b::TextBuffer, f::AbstractString) =
    ((@ccall libfltkjl.fljl_textbuffer_savefile(_bptr(b)::Ptr{Cvoid}, f::Cstring)::Cint) == 0 || error("could not save $f"); b)
select!(b::TextBuffer, start::Integer, stop::Integer) =
    (@ccall libfltkjl.fljl_textbuffer_select(_bptr(b)::Ptr{Cvoid}, start::Cint, stop::Cint)::Cvoid; b)
hasselection(b::TextBuffer) = (@ccall libfltkjl.fljl_textbuffer_selected(_bptr(b)::Ptr{Cvoid})::Cint) != 0
function selection_text(b::TextBuffer)
    p = @ccall libfltkjl.fljl_textbuffer_selection_text(_bptr(b)::Ptr{Cvoid})::Ptr{UInt8}
    s = unsafe_string(p)
    @ccall libfltkjl.fljl_free(p::Ptr{UInt8})::Cvoid
    return s
end
"Byte offset of the next match of `s` at or after `start`, or -1."
search_forward(b::TextBuffer, s::AbstractString, start::Integer = 0; matchcase::Bool = true) =
    Int(@ccall libfltkjl.fljl_textbuffer_search_forward(_bptr(b)::Ptr{Cvoid}, start::Cint, s::Cstring, matchcase::Cint)::Cint)
undo!(b::TextBuffer) = (@ccall libfltkjl.fljl_textbuffer_undo(_bptr(b)::Ptr{Cvoid})::Cvoid; b)
Base.show(io::IO, b::TextBuffer) = print(io, "TextBuffer(", getfield(b, :_ptr) == C_NULL ? "<freed>" : "$(length(b)) bytes", ")")

@widget TextView AbstractWidget TextDisplay
@widget TextEditor AbstractWidget
const ATD = Union{TextView,TextEditor}

# Each display gets its own buffer on creation; replace it with `buffer!`.
_postinit(t::ATD) = (buffer!(t, TextBuffer()); nothing)
buffer(t::ATD) = getfield(t, :_refs)[:buffer]::TextBuffer
function buffer!(t::ATD, b::TextBuffer)
    getfield(t, :_refs)[:buffer] = b
    @ccall libfltkjl.fljl_textdisplay_buffer(_ptr(t)::Ptr{Cvoid}, _bptr(b)::Ptr{Cvoid})::Cvoid
    return t
end
@prop ATD buffer
"Whole text of the display's buffer."
value(t::ATD) = text(buffer(t))
value!(t::ATD, s::AbstractString) = (text!(buffer(t), s); t)
Base.append!(t::ATD, s::AbstractString) = (append!(buffer(t), s); t)
textfont!(t::ATD, f::Integer) = (@ccall libfltkjl.fljl_textdisplay_textfont(_ptr(t)::Ptr{Cvoid}, f::Cint)::Cvoid; t)
textsize!(t::ATD, s::Integer) = (@ccall libfltkjl.fljl_textdisplay_textsize(_ptr(t)::Ptr{Cvoid}, s::Cint)::Cvoid; t)
textcolor!(t::ATD, c::Integer) = (@ccall libfltkjl.fljl_textdisplay_textcolor(_ptr(t)::Ptr{Cvoid}, c::Cuint)::Cvoid; t)
"`WRAP_NONE`, `WRAP_AT_COLUMN`, `WRAP_AT_PIXEL` or `WRAP_AT_BOUNDS`."
wrap_mode!(t::ATD, mode::Integer, margin::Integer = 0) =
    (@ccall libfltkjl.fljl_textdisplay_wrap_mode(_ptr(t)::Ptr{Cvoid}, mode::Cint, margin::Cint)::Cvoid; t)
linenumber_width!(t::ATD, w::Integer) = (@ccall libfltkjl.fljl_textdisplay_linenumber_width(_ptr(t)::Ptr{Cvoid}, w::Cint)::Cvoid; t)
insert_position(t::ATD) = Int(@ccall libfltkjl.fljl_textdisplay_insert_position(_ptr(t)::Ptr{Cvoid})::Cint)
insert_position!(t::ATD, p::Integer) = (@ccall libfltkjl.fljl_textdisplay_set_insert_position(_ptr(t)::Ptr{Cvoid}, p::Cint)::Cvoid; t)
show_insert_position!(t::ATD) = (@ccall libfltkjl.fljl_textdisplay_show_insert_position(_ptr(t)::Ptr{Cvoid})::Cvoid; t)
scroll!(t::ATD, line::Integer, col::Integer = 0) = (@ccall libfltkjl.fljl_textdisplay_scroll(_ptr(t)::Ptr{Cvoid}, line::Cint, col::Cint)::Cvoid; t)
insert_text!(t::ATD, s::AbstractString) = (@ccall libfltkjl.fljl_textdisplay_insert(_ptr(t)::Ptr{Cvoid}, s::Cstring)::Cvoid; t)
@prop ATD textfont set
@prop ATD textsize set
@prop ATD textcolor set
@prop ATD value

# ---- Terminal ----------------------------------------------------------------
@widget Terminal AbstractWidget
"Append text (ANSI escape sequences are interpreted)."
Base.append!(t::Terminal, s::AbstractString) = (@ccall libfltkjl.fljl_terminal_append(_ptr(t)::Ptr{Cvoid}, s::Cstring)::Cvoid; t)
Base.print(t::Terminal, xs...) = append!(t, string(xs...))
Base.println(t::Terminal, xs...) = append!(t, string(xs..., "\n"))
clear!(t::Terminal) = (@ccall libfltkjl.fljl_terminal_clear(_ptr(t)::Ptr{Cvoid})::Cvoid; t)
textsize!(t::Terminal, s::Integer) = (@ccall libfltkjl.fljl_terminal_textsize(_ptr(t)::Ptr{Cvoid}, s::Cint)::Cvoid; t)
textfgcolor!(t::Terminal, c::Integer) = (@ccall libfltkjl.fljl_terminal_textfgcolor(_ptr(t)::Ptr{Cvoid}, c::Cuint)::Cvoid; t)
textbgcolor!(t::Terminal, c::Integer) = (@ccall libfltkjl.fljl_terminal_textbgcolor(_ptr(t)::Ptr{Cvoid}, c::Cuint)::Cvoid; t)

# ---- Tree (items addressed by "a/b/c" paths) ------------------------------------
@widget Tree AbstractWidget
add!(t::Tree, path::AbstractString) = ((@ccall libfltkjl.fljl_tree_add(_ptr(t)::Ptr{Cvoid}, path::Cstring)::Cint); t)
remove!(t::Tree, path::AbstractString) = ((@ccall libfltkjl.fljl_tree_remove(_ptr(t)::Ptr{Cvoid}, path::Cstring)::Cint); t)
clear!(t::Tree) = (@ccall libfltkjl.fljl_tree_clear(_ptr(t)::Ptr{Cvoid})::Cvoid; t)
showroot!(t::Tree, on::Bool) = (@ccall libfltkjl.fljl_tree_showroot(_ptr(t)::Ptr{Cvoid}, on::Cint)::Cvoid; t)
root_label!(t::Tree, s::AbstractString) = (@ccall libfltkjl.fljl_tree_root_label(_ptr(t)::Ptr{Cvoid}, s::Cstring)::Cvoid; t)
open!(t::Tree, path::AbstractString) = (@ccall libfltkjl.fljl_tree_open(_ptr(t)::Ptr{Cvoid}, path::Cstring, 1::Cint)::Cint; t)
close!(t::Tree, path::AbstractString) = (@ccall libfltkjl.fljl_tree_open(_ptr(t)::Ptr{Cvoid}, path::Cstring, 0::Cint)::Cint; t)
select!(t::Tree, path::AbstractString, on::Bool = true) =
    (@ccall libfltkjl.fljl_tree_select(_ptr(t)::Ptr{Cvoid}, path::Cstring, on::Cint)::Cint; t)
"Inside a Tree callback: the reason (`FL_TREE_REASON_*`)."
tree_reason(t::Tree) = Int(@ccall libfltkjl.fljl_tree_callback_reason(_ptr(t)::Ptr{Cvoid})::Cint)
function _tree_item_path(t::Tree, it::Ptr{Cvoid})
    it == C_NULL && return nothing
    buf = zeros(UInt8, 1024)
    r = @ccall libfltkjl.fljl_tree_item_pathname(_ptr(t)::Ptr{Cvoid}, it::Ptr{Cvoid}, buf::Ptr{UInt8}, 1024::Cint)::Cint
    r == 0 ? unsafe_string(pointer(buf)) : nothing
end
"Inside a Tree callback: path of the item that triggered it."
tree_item(t::Tree) = _tree_item_path(t, @ccall libfltkjl.fljl_tree_callback_item(_ptr(t)::Ptr{Cvoid})::Ptr{Cvoid})
"Paths of all selected items."
function selected_items(t::Tree)
    out = String[]
    it = @ccall libfltkjl.fljl_tree_first_selected(_ptr(t)::Ptr{Cvoid})::Ptr{Cvoid}
    while it != C_NULL
        p = _tree_item_path(t, it)
        p === nothing || push!(out, p)
        it = @ccall libfltkjl.fljl_tree_next_selected(_ptr(t)::Ptr{Cvoid}, it::Ptr{Cvoid})::Ptr{Cvoid}
    end
    return out
end

# ---- generic `value` property ---------------------------------------------------
const _HasValue = Union{AbstractButton,AbstractInput,AbstractValuator,Spinner,Progress,AbstractMenu,
                        AbstractBrowser,Tabs,Wizard}
@prop _HasValue value
