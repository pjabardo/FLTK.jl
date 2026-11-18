# Standard dialogs (fl_ask.H, file and color choosers) and images.

fl_message(msg::AbstractString) = @ccall libfltkjl.fljl_message(msg::Cstring)::Cvoid
fl_alert(msg::AbstractString) = @ccall libfltkjl.fljl_alert(msg::Cstring)::Cvoid
"""
    fl_choice(question, b0, b1 = nothing, b2 = nothing) -> 0, 1 or 2

Ask a question with up to three buttons; returns the index of the button
pressed. `b0` is the rightmost button and the one chosen by Escape.
"""
function fl_choice(q::AbstractString, b0::AbstractString, b1 = nothing, b2 = nothing)
    _c(x) = x === nothing ? Ptr{UInt8}(C_NULL) : pointer(x)
    GC.@preserve b0 b1 b2 begin
        Int(@ccall libfltkjl.fljl_choice(q::Cstring, b0::Cstring, _c(b1)::Ptr{UInt8}, _c(b2)::Ptr{UInt8})::Cint)
    end
end
"Ask for a line of text. Returns `nothing` if cancelled."
fl_input(label::AbstractString, default::AbstractString = "") =
    _str_or_nothing(@ccall libfltkjl.fljl_input_dialog(label::Cstring, default::Cstring)::Ptr{UInt8})
"Like `fl_input` but hides what is typed."
fl_password(label::AbstractString, default::AbstractString = "") =
    _str_or_nothing(@ccall libfltkjl.fljl_password_dialog(label::Cstring, default::Cstring)::Ptr{UInt8})
"Title of the next message box."
fl_message_title(t::AbstractString) = @ccall libfltkjl.fljl_message_title(t::Cstring)::Cvoid
fl_message_title_default(t::AbstractString) = @ccall libfltkjl.fljl_message_title_default(t::Cstring)::Cvoid
fl_beep(kind::Integer = 0) = @ccall libfltkjl.fljl_beep(kind::Cint)::Cvoid

"FLTK's own file chooser. `pattern` like `\"*.{jl,txt}\"`. Returns a path or `nothing`."
fl_file_chooser(message::AbstractString = "Choose a file", pattern::AbstractString = "*", fname::AbstractString = "";
                relative::Bool = false) =
    _str_or_nothing(@ccall libfltkjl.fljl_file_chooser(message::Cstring, pattern::Cstring, fname::Cstring, relative::Cint)::Ptr{UInt8})
fl_dir_chooser(message::AbstractString = "Choose a directory", fname::AbstractString = ""; relative::Bool = false) =
    _str_or_nothing(@ccall libfltkjl.fljl_dir_chooser(message::Cstring, fname::Cstring, relative::Cint)::Ptr{UInt8})

"Show FLTK's 256-color palette and return the color picked (or `c` if cancelled)."
fl_show_colormap(c::Integer) = @ccall libfltkjl.fljl_show_colormap(c::Cuint)::Cuint

"""
    fl_color_chooser(title = "Choose a color", (r, g, b) = (128, 128, 128)) -> (r, g, b) or nothing
"""
function fl_color_chooser(title::AbstractString = "Choose a color", rgb = (128, 128, 128); mode::Integer = -1)
    r, g, b = Ref{UInt8}(rgb[1]), Ref{UInt8}(rgb[2]), Ref{UInt8}(rgb[3])
    ok = @ccall libfltkjl.fljl_color_chooser(title::Cstring, r::Ref{UInt8}, g::Ref{UInt8}, b::Ref{UInt8}, mode::Cint)::Cint
    ok == 0 ? nothing : (Int(r[]), Int(g[]), Int(b[]))
end

"""
    native_file_chooser(; type = BROWSE_FILE, title = "", filter = "", directory = "",
                          preset_file = "", options = 0) -> Vector{String} or nothing

The platform's native file dialog. `type` is one of the `BROWSE_*`
constants, `filter` like `"Julia\\t*.jl\\nText\\t*.txt"`. Returns the chosen
paths, or `nothing` if cancelled.
"""
function native_file_chooser(; type::Integer = BROWSE_FILE, title::AbstractString = "", filter::AbstractString = "",
                             directory::AbstractString = "", preset_file::AbstractString = "", options::Integer = 0)
    c = @ccall libfltkjl.fljl_nfc_new(type::Cint)::Ptr{Cvoid}
    try
        isempty(title) || @ccall libfltkjl.fljl_nfc_title(c::Ptr{Cvoid}, title::Cstring)::Cvoid
        isempty(filter) || @ccall libfltkjl.fljl_nfc_filter(c::Ptr{Cvoid}, filter::Cstring)::Cvoid
        isempty(directory) || @ccall libfltkjl.fljl_nfc_directory(c::Ptr{Cvoid}, directory::Cstring)::Cvoid
        isempty(preset_file) || @ccall libfltkjl.fljl_nfc_preset_file(c::Ptr{Cvoid}, preset_file::Cstring)::Cvoid
        options == 0 || @ccall libfltkjl.fljl_nfc_options(c::Ptr{Cvoid}, options::Cint)::Cvoid
        r = @ccall libfltkjl.fljl_nfc_show(c::Ptr{Cvoid})::Cint
        r == -1 && error(_str(@ccall libfltkjl.fljl_nfc_errmsg(c::Ptr{Cvoid})::Ptr{UInt8}))
        r == 1 && return nothing
        n = @ccall libfltkjl.fljl_nfc_count(c::Ptr{Cvoid})::Cint
        return [_str(@ccall libfltkjl.fljl_nfc_filename(c::Ptr{Cvoid}, i::Cint)::Ptr{UInt8}) for i in 0:n-1]
    finally
        @ccall libfltkjl.fljl_nfc_delete(c::Ptr{Cvoid})::Cvoid
    end
end

# =============================================================================
# Images
# =============================================================================
"""
    Image

An FLTK image. Create one with `load_image(path)` (PNG, JPEG, GIF, BMP,
SVG, XPM, ...) or `RGBImage(pixels)`. Attach to widgets with `image!`, or
draw it with `draw(img, x, y)` inside a draw function.
"""
mutable struct Image
    _ptr::Ptr{Cvoid}
    function Image(p::Ptr{Cvoid})
        p == C_NULL && error("could not create image")
        finalizer(x -> _queue_free(:image, x), new(p))
    end
end
_imgptr(::Nothing) = C_NULL
function _imgptr(i::Image)
    p = getfield(i, :_ptr)
    p == C_NULL && throw(ArgumentError("Image has been freed"))
    p
end

"Load an image file. `w`/`h` > 0 request a specific size (useful for SVG)."
function load_image(path::AbstractString; w::Integer = 0, h::Integer = 0)
    isfile(path) || throw(ArgumentError("no such file: $path"))
    p = @ccall libfltkjl.fljl_shared_image_get(abspath(path)::Cstring, w::Cint, h::Cint)::Ptr{Cvoid}
    p == C_NULL && error("unsupported or corrupt image: $path")
    Image(p)
end

"""
    RGBImage(pixels::Array{UInt8,3})   # size (d, w, h), d = 1..4
    RGBImage(pixels::Matrix{UInt8})    # size (w, h), grayscale

An image from raw pixel data. The data is copied.
"""
function RGBImage(px::Array{UInt8,3})
    d, w, h = size(px)
    1 <= d <= 4 || throw(ArgumentError("first dimension (channels) must be 1 to 4"))
    Image(@ccall libfltkjl.fljl_rgb_image_new(px::Ptr{UInt8}, w::Cint, h::Cint, d::Cint)::Ptr{Cvoid})
end
RGBImage(px::Matrix{UInt8}) = RGBImage(reshape(px, 1, size(px)...))

Base.size(i::Image) = (Int(@ccall libfltkjl.fljl_image_w(_imgptr(i)::Ptr{Cvoid})::Cint),
                       Int(@ccall libfltkjl.fljl_image_h(_imgptr(i)::Ptr{Cvoid})::Cint))
"Number of channels (0 for bitmaps, 1 gray, 3 RGB, 4 RGBA)."
channels(i::Image) = Int(@ccall libfltkjl.fljl_image_d(_imgptr(i)::Ptr{Cvoid})::Cint)
"Draw at `(x, y)`, optionally cropped to `w × h` starting at `(cx, cy)` in the image."
draw(i::Image, x::Integer, y::Integer) = @ccall libfltkjl.fljl_image_draw(_imgptr(i)::Ptr{Cvoid}, x::Cint, y::Cint)::Cvoid
draw(i::Image, x::Integer, y::Integer, w::Integer, h::Integer, cx::Integer = 0, cy::Integer = 0) =
    @ccall libfltkjl.fljl_image_draw_box(_imgptr(i)::Ptr{Cvoid}, x::Cint, y::Cint, w::Cint, h::Cint, cx::Cint, cy::Cint)::Cvoid
"Set the drawing size without resampling the data (sharp on HiDPI)."
scale!(i::Image, w::Integer, h::Integer; proportional::Bool = true, can_expand::Bool = false) =
    (@ccall libfltkjl.fljl_image_scale(_imgptr(i)::Ptr{Cvoid}, w::Cint, h::Cint, proportional::Cint, can_expand::Cint)::Cvoid; i)
"A resampled copy of the image."
Base.copy(i::Image, w::Integer, h::Integer) = Image(@ccall libfltkjl.fljl_image_copy(_imgptr(i)::Ptr{Cvoid}, w::Cint, h::Cint)::Ptr{Cvoid})
Base.copy(i::Image) = copy(i, size(i)...)
Base.show(io::IO, i::Image) = getfield(i, :_ptr) == C_NULL ? print(io, "Image(<freed>)") :
    print(io, "Image(", join(size(i), "×"), ", ", channels(i), " channels)")

"Open a URI (`http://...`, `file://...`, `mailto:...`) with the system's default application."
fl_open_uri(uri::AbstractString) = (@ccall libfltkjl.fljl_open_uri(uri::Cstring)::Cint) != 0
