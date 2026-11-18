# Drawing functions (fl_draw.H). They work inside a `draw!` function, or
# after `make_current(window)`. Names follow the C++ API.

fl_color(c::Integer) = @ccall libfltkjl.fljl_draw_color(c::Cuint)::Cvoid
fl_color(r::Integer, g::Integer, b::Integer) = @ccall libfltkjl.fljl_draw_color_rgb(r::Cint, g::Cint, b::Cint)::Cvoid
fl_color() = @ccall libfltkjl.fljl_draw_get_color()::Cuint

fl_push_clip(x, y, w, h) = @ccall libfltkjl.fljl_push_clip(x::Cint, y::Cint, w::Cint, h::Cint)::Cvoid
fl_push_no_clip() = @ccall libfltkjl.fljl_push_no_clip()::Cvoid
fl_pop_clip() = @ccall libfltkjl.fljl_pop_clip()::Cvoid
"Run `f()` with drawing clipped to the rectangle."
function fl_clip(f, x, y, w, h)
    fl_push_clip(x, y, w, h)
    try
        f()
    finally
        fl_pop_clip()
    end
end
fl_not_clipped(x, y, w, h) = (@ccall libfltkjl.fljl_not_clipped(x::Cint, y::Cint, w::Cint, h::Cint)::Cint) != 0

"`style` combines `FL_SOLID`/`FL_DASH`/... with `FL_CAP_*` and `FL_JOIN_*`."
fl_line_style(style::Integer = FL_SOLID, width::Integer = 0) = @ccall libfltkjl.fljl_line_style(style::Cint, width::Cint)::Cvoid
fl_point(x, y) = @ccall libfltkjl.fljl_point(x::Cint, y::Cint)::Cvoid
fl_rect(x, y, w, h) = @ccall libfltkjl.fljl_rect(x::Cint, y::Cint, w::Cint, h::Cint)::Cvoid
fl_rectf(x, y, w, h) = @ccall libfltkjl.fljl_rectf(x::Cint, y::Cint, w::Cint, h::Cint)::Cvoid
fl_rectf(x, y, w, h, c::Integer) = (fl_color(c); fl_rectf(x, y, w, h))
fl_rounded_rect(x, y, w, h, r) = @ccall libfltkjl.fljl_rounded_rect(x::Cint, y::Cint, w::Cint, h::Cint, r::Cint)::Cvoid
fl_rounded_rectf(x, y, w, h, r) = @ccall libfltkjl.fljl_rounded_rectf(x::Cint, y::Cint, w::Cint, h::Cint, r::Cint)::Cvoid
fl_line(x, y, x1, y1) = @ccall libfltkjl.fljl_line(x::Cint, y::Cint, x1::Cint, y1::Cint)::Cvoid
fl_xyline(x, y, x1) = @ccall libfltkjl.fljl_xyline(x::Cint, y::Cint, x1::Cint)::Cvoid
fl_yxline(x, y, y1) = @ccall libfltkjl.fljl_yxline(x::Cint, y::Cint, y1::Cint)::Cvoid
fl_loop(x0, y0, x1, y1, x2, y2) = @ccall libfltkjl.fljl_loop3(x0::Cint, y0::Cint, x1::Cint, y1::Cint, x2::Cint, y2::Cint)::Cvoid
fl_polygon(x0, y0, x1, y1, x2, y2) = @ccall libfltkjl.fljl_polygon3(x0::Cint, y0::Cint, x1::Cint, y1::Cint, x2::Cint, y2::Cint)::Cvoid
"Outline of an ellipse arc in the box, angles in degrees counter-clockwise from 3 o'clock."
fl_arc(x::Integer, y::Integer, w::Integer, h::Integer, a1::Real, a2::Real) =
    @ccall libfltkjl.fljl_arc_i(x::Cint, y::Cint, w::Cint, h::Cint, a1::Cdouble, a2::Cdouble)::Cvoid
"Filled pie slice of an ellipse in the box."
fl_pie(x, y, w, h, a1, a2) = @ccall libfltkjl.fljl_pie(x::Cint, y::Cint, w::Cint, h::Cint, a1::Cdouble, a2::Cdouble)::Cvoid

# ---- transformed (floating point) drawing --------------------------------------
fl_push_matrix() = @ccall libfltkjl.fljl_push_matrix()::Cvoid
fl_pop_matrix() = @ccall libfltkjl.fljl_pop_matrix()::Cvoid
fl_scale(x, y = x) = @ccall libfltkjl.fljl_scale(x::Cdouble, y::Cdouble)::Cvoid
fl_translate(x, y) = @ccall libfltkjl.fljl_translate(x::Cdouble, y::Cdouble)::Cvoid
fl_rotate(deg) = @ccall libfltkjl.fljl_rotate(deg::Cdouble)::Cvoid
fl_begin_points() = @ccall libfltkjl.fljl_begin_points()::Cvoid
fl_begin_line() = @ccall libfltkjl.fljl_begin_line()::Cvoid
fl_begin_loop() = @ccall libfltkjl.fljl_begin_loop()::Cvoid
fl_begin_polygon() = @ccall libfltkjl.fljl_begin_polygon()::Cvoid
fl_begin_complex_polygon() = @ccall libfltkjl.fljl_begin_complex_polygon()::Cvoid
fl_gap() = @ccall libfltkjl.fljl_gap()::Cvoid
fl_vertex(x, y) = @ccall libfltkjl.fljl_vertex(x::Cdouble, y::Cdouble)::Cvoid
fl_curve(x0, y0, x1, y1, x2, y2, x3, y3) =
    @ccall libfltkjl.fljl_curve(x0::Cdouble, y0::Cdouble, x1::Cdouble, y1::Cdouble, x2::Cdouble, y2::Cdouble, x3::Cdouble, y3::Cdouble)::Cvoid
"Arc of a circle (in a `fl_begin_*`/`fl_end_*` block)."
fl_arc(x::Real, y::Real, r::Real, start::Real, stop::Real) =
    @ccall libfltkjl.fljl_arc_d(x::Cdouble, y::Cdouble, r::Cdouble, start::Cdouble, stop::Cdouble)::Cvoid
"Circle centered at `(x, y)`: filled inside `fl_begin_polygon`, outlined otherwise."
fl_circle(x, y, r) = @ccall libfltkjl.fljl_circle(x::Cdouble, y::Cdouble, r::Cdouble)::Cvoid
fl_end_points() = @ccall libfltkjl.fljl_end_points()::Cvoid
fl_end_line() = @ccall libfltkjl.fljl_end_line()::Cvoid
fl_end_loop() = @ccall libfltkjl.fljl_end_loop()::Cvoid
fl_end_polygon() = @ccall libfltkjl.fljl_end_polygon()::Cvoid
fl_end_complex_polygon() = @ccall libfltkjl.fljl_end_complex_polygon()::Cvoid

"""
    fl_polyline(xs, ys; kind = :line)

Draw a connected path through the points (in the current transform).
`kind` is `:line`, `:loop`, `:polygon` (filled) or `:points`.
"""
function fl_polyline(xs::AbstractVector{<:Real}, ys::AbstractVector{<:Real}; kind::Symbol = :line)
    length(xs) == length(ys) || throw(DimensionMismatch("xs and ys differ in length"))
    xy = Vector{Cdouble}(undef, 2 * length(xs))
    @inbounds for i in eachindex(xs, ys)
        xy[2i-1] = xs[i]; xy[2i] = ys[i]
    end
    kind === :line ? fl_begin_line() : kind === :loop ? fl_begin_loop() :
        kind === :polygon ? fl_begin_polygon() : kind === :points ? fl_begin_points() :
        throw(ArgumentError("kind must be :line, :loop, :polygon or :points"))
    @ccall libfltkjl.fljl_vertices(xy::Ptr{Cdouble}, length(xs)::Cint)::Cvoid
    kind === :line ? fl_end_line() : kind === :loop ? fl_end_loop() :
        kind === :polygon ? fl_end_polygon() : fl_end_points()
end

# ---- text --------------------------------------------------------------------
fl_font(face::Integer, size::Integer) = @ccall libfltkjl.fljl_font(face::Cint, size::Cint)::Cvoid
fl_font() = Int(@ccall libfltkjl.fljl_get_font()::Cint)
fl_size() = Int(@ccall libfltkjl.fljl_size()::Cint)
fl_height() = Int(@ccall libfltkjl.fljl_height()::Cint)
fl_descent() = Int(@ccall libfltkjl.fljl_descent()::Cint)
"Width of `s` in the current font."
fl_width(s::AbstractString) = @ccall libfltkjl.fljl_width(s::Cstring)::Cdouble
"Ink extents `(dx, dy, w, h)` of `s` in the current font."
function fl_text_extents(s::AbstractString)
    r = (Ref{Cint}(0), Ref{Cint}(0), Ref{Cint}(0), Ref{Cint}(0))
    @ccall libfltkjl.fljl_text_extents(s::Cstring, r[1]::Ref{Cint}, r[2]::Ref{Cint}, r[3]::Ref{Cint}, r[4]::Ref{Cint})::Cvoid
    map(x -> Int(x[]), r)
end
"Draw `s` with its baseline starting at `(x, y)`."
fl_draw(s::AbstractString, x::Integer, y::Integer) = @ccall libfltkjl.fljl_draw_text(s::Cstring, x::Cint, y::Cint)::Cvoid
"Draw `s` rotated by `angle` degrees."
fl_draw(angle::Integer, s::AbstractString, x::Integer, y::Integer) =
    @ccall libfltkjl.fljl_draw_text_angle(angle::Cint, s::Cstring, x::Cint, y::Cint)::Cvoid
"Draw `s` aligned in a box (`align` is `FL_ALIGN_*`); handles newlines and `@` symbols."
fl_draw(s::AbstractString, x::Integer, y::Integer, w::Integer, h::Integer, align::Integer = FL_ALIGN_CENTER) =
    @ccall libfltkjl.fljl_draw_text_box(s::Cstring, x::Cint, y::Cint, w::Cint, h::Cint, align::Cuint)::Cvoid
"Size `(w, h)` that `fl_draw(s, x, y, w, h, align)` would use. `w > 0` sets the wrap width."
function fl_measure(s::AbstractString, w::Integer = 0; symbols::Bool = true)
    ww, hh = Ref{Cint}(w), Ref{Cint}(0)
    @ccall libfltkjl.fljl_measure(s::Cstring, ww::Ref{Cint}, hh::Ref{Cint}, symbols::Cint)::Cvoid
    (Int(ww[]), Int(hh[]))
end

# ---- boxes, symbols, images ------------------------------------------------------
"Draw a box of type `FL_*_BOX` with the given color."
fl_draw_box(box::Integer, x, y, w, h, c::Integer) =
    @ccall libfltkjl.fljl_draw_box(box::Cint, x::Cint, y::Cint, w::Cint, h::Cint, c::Cuint)::Cvoid
"Draw an FLTK symbol such as `\"@->\"` or `\"@circle\"`."
fl_draw_symbol(s::AbstractString, x, y, w, h, c::Integer) =
    (@ccall libfltkjl.fljl_draw_symbol(s::Cstring, x::Cint, y::Cint, w::Cint, h::Cint, c::Cuint)::Cint) != 0

"""
    fl_draw_image(pixels, x, y)

Draw raw pixels. `pixels` is an `Array{UInt8,3}` of size `(d, w, h)` with
`d` = 3 (RGB) or 4 (RGBA), or a `Matrix{UInt8}` of size `(w, h)` for
grayscale. This memory layout matches FLTK's, so nothing is copied.
"""
function fl_draw_image(px::Array{UInt8,3}, x::Integer, y::Integer)
    d, w, h = size(px)
    @ccall libfltkjl.fljl_draw_image(px::Ptr{UInt8}, x::Cint, y::Cint, w::Cint, h::Cint, d::Cint, 0::Cint)::Cvoid
end
function fl_draw_image(px::Matrix{UInt8}, x::Integer, y::Integer)
    w, h = size(px)
    @ccall libfltkjl.fljl_draw_image_mono(px::Ptr{UInt8}, x::Cint, y::Cint, w::Cint, h::Cint, 1::Cint, 0::Cint)::Cvoid
end
