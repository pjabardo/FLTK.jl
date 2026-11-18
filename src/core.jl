# Core machinery: widget handles, the pointer registry, C -> Julia hooks,
# and helpers for declaring properties.

"""
    AbstractWidget

Supertype of every FLTK widget handle. A handle wraps a pointer to a C++
`Fl_Widget`. FLTK owns the C++ object: a group deletes its children when it
is deleted. When the C++ object is destroyed, its handle is invalidated, and
using it afterwards raises an error instead of crashing.
"""
abstract type AbstractWidget end
abstract type AbstractGroup <: AbstractWidget end
abstract type AbstractWindow <: AbstractGroup end
abstract type AbstractButton <: AbstractWidget end
abstract type AbstractInput <: AbstractWidget end
abstract type AbstractValuator <: AbstractWidget end
abstract type AbstractMenu <: AbstractWidget end
abstract type AbstractBrowser <: AbstractWidget end

# ptr -> Julia handle, for every live widget created from Julia.
const _registry = Dict{Ptr{Cvoid},AbstractWidget}()

@inline function _ptr(w::AbstractWidget)
    p = getfield(w, :_ptr)
    p == C_NULL && throw(ArgumentError("$(nameof(typeof(w))) has been deleted"))
    return p
end

Base.isvalid(w::AbstractWidget) = getfield(w, :_ptr) != C_NULL

"""
    ForeignWidget

Handle to a widget that was created by FLTK itself (for example the
scrollbars inside an `Fl_Scroll`), not from Julia. It is not tracked, so it
must not be used after its owner is deleted, and it cannot take callbacks.
"""
mutable struct ForeignWidget <: AbstractWidget
    _ptr::Ptr{Cvoid}
end

function _wrap(p::Ptr{Cvoid})
    p == C_NULL && return nothing
    w = get(_registry, p, nothing)
    w === nothing ? ForeignWidget(p) : w
end

_str(p::Ptr{UInt8}) = p == C_NULL ? "" : unsafe_string(p)
_str_or_nothing(p::Ptr{UInt8}) = p == C_NULL ? nothing : unsafe_string(p)

function _report(e, bt, where)
    @error "Error in FLTK $where" exception = (e, bt)
end

# ---------------------------------------------------------------------------
# Hooks called from C++
# ---------------------------------------------------------------------------
function _on_delete(p::Ptr{Cvoid})::Cvoid
    w = pop!(_registry, p, nothing)
    if w !== nothing
        for id in get(getfield(w, :_refs), :menu_ids, Int[])
            delete!(_menu_callbacks, id)
        end
        setfield!(w, :_ptr, C_NULL)
    end
    return nothing
end

function _draw_hook(p::Ptr{Cvoid})::Cvoid
    w = get(_registry, p, nothing)
    if w === nothing || getfield(w, :_draw) === nothing
        @ccall libfltkjl.fljl_super_draw(p::Ptr{Cvoid})::Cvoid
        return nothing
    end
    try
        getfield(w, :_draw)(w)
    catch e
        _report(e, catch_backtrace(), "draw function")
    end
    return nothing
end

function _handle_hook(p::Ptr{Cvoid}, ev::Cint)::Cint
    w = get(_registry, p, nothing)
    if w !== nothing && getfield(w, :_handle) !== nothing
        try
            r = getfield(w, :_handle)(w, Int(ev))
            r === nothing || return Cint(r)
        catch e
            _report(e, catch_backtrace(), "handle function")
        end
    end
    return @ccall libfltkjl.fljl_super_handle(p::Ptr{Cvoid}, ev::Cint)::Cint
end

function _callback_hook(p::Ptr{Cvoid})::Cvoid
    w = get(_registry, p, nothing)
    (w === nothing || getfield(w, :_cb) === nothing) && return nothing
    try
        getfield(w, :_cb)(w)
    catch e
        _report(e, catch_backtrace(), "callback")
    end
    return nothing
end

const _menu_callbacks = Dict{Int,Any}()
const _next_menu_id = Ref(0)

function _menu_hook(p::Ptr{Cvoid}, id::Int)::Cvoid
    f = get(_menu_callbacks, id, nothing)
    f === nothing && return nothing
    w = get(_registry, p, nothing)
    try
        f(w)
    catch e
        _report(e, catch_backtrace(), "menu callback")
    end
    return nothing
end

const _timeouts = Dict{Int,Tuple{Any,Float64,Bool}}()   # id => (f, secs, repeat)
const _next_timeout_id = Ref(0)

function _timeout_hook(id::Int)::Cvoid
    t = get(_timeouts, id, nothing)
    t === nothing && return nothing
    f, secs, rep = t
    if rep
        @ccall libfltkjl.fljl_repeat_timeout(secs::Cdouble, id::Int)::Cvoid
    else
        delete!(_timeouts, id)
    end
    try
        f()
    catch e
        _report(e, catch_backtrace(), "timeout")
    end
    return nothing
end

function _install_hooks()
    @ccall libfltkjl.fljl_set_hooks(
        @cfunction(_on_delete, Cvoid, (Ptr{Cvoid},))::Ptr{Cvoid},
        @cfunction(_draw_hook, Cvoid, (Ptr{Cvoid},))::Ptr{Cvoid},
        @cfunction(_handle_hook, Cint, (Ptr{Cvoid}, Cint))::Ptr{Cvoid},
        @cfunction(_callback_hook, Cvoid, (Ptr{Cvoid},))::Ptr{Cvoid},
        @cfunction(_menu_hook, Cvoid, (Ptr{Cvoid}, Int))::Ptr{Cvoid},
        @cfunction(_timeout_hook, Cvoid, (Int,))::Ptr{Cvoid},
    )::Cvoid
end

# ---------------------------------------------------------------------------
# Deferred freeing of non-widget objects (images, text buffers).
# Finalizers can run on any thread at any time, but FLTK is single
# threaded, so finalizers only queue the pointer. The queue is drained from
# the event loop on the main thread.
# ---------------------------------------------------------------------------
const _free_queue = Tuple{Symbol,Ptr{Cvoid}}[]
const _free_lock = Threads.SpinLock()

function _queue_free(kind::Symbol, obj)
    p = getfield(obj, :_ptr)
    p == C_NULL && return
    if !trylock(_free_lock)
        finalizer(o -> _queue_free(kind, o), obj)   # retry later
        return
    end
    try
        push!(_free_queue, (kind, p))
        setfield!(obj, :_ptr, C_NULL)
    finally
        unlock(_free_lock)
    end
end

function _drain_free_queue()
    isempty(_free_queue) && return
    items = lock(_free_lock) do
        v = copy(_free_queue); empty!(_free_queue); v
    end
    for (kind, p) in items
        if kind === :image
            @ccall libfltkjl.fljl_image_delete(p::Ptr{Cvoid})::Cvoid
        elseif kind === :textbuffer
            @ccall libfltkjl.fljl_textbuffer_delete(p::Ptr{Cvoid})::Cvoid
        end
    end
end

# ---------------------------------------------------------------------------
# Properties: `w.label = "x"` is sugar for `label!(w, "x")`.
# Internal struct fields all start with an underscore.
# ---------------------------------------------------------------------------
function getprop end
function setprop! end

getprop(w, ::Val{s}) where {s} =
    throw(ArgumentError("$(nameof(typeof(w))) has no readable property `$s`"))
setprop!(w, ::Val{s}, v) where {s} =
    throw(ArgumentError("$(nameof(typeof(w))) has no writable property `$s`"))

@inline _isfield(s::Symbol) = first(String(s)) == '_'

Base.getproperty(w::AbstractWidget, s::Symbol) = _isfield(s) ? getfield(w, s) : getprop(w, Val(s))
function Base.setproperty!(w::AbstractWidget, s::Symbol, v)
    _isfield(s) ? setfield!(w, s, v) : setprop!(w, Val(s), v)
    return v
end

"""
    @prop T name

Make `w.name` call `name(w)` and `w.name = v` call `name!(w, v)` for `w::T`.
Use `@prop T name get` or `@prop T name set` for one direction only.
"""
macro prop(T, name, dir = :both)
    q = QuoteNode(name)
    ex = quote end
    if dir in (:both, :get)
        push!(ex.args, :($(esc(:getprop))(w::$(esc(T)), ::Val{$q}) = $(esc(name))(w)))
    end
    if dir in (:both, :set)
        setter = Symbol(name, "!")
        push!(ex.args, :($(esc(:setprop!))(w::$(esc(T)), ::Val{$q}, v) = $(esc(setter))(w, v)))
    end
    ex
end

"""
    @getset T name CT cget cset [conv]

Define `name(w::T)` with C getter `cget` and `name!(w::T, v)` with C setter
`cset`, both using the C type `CT`, and make `name` a property.
"""
macro getset(T, name, CT, cget, cset, conv = nothing)
    setter = Symbol(name, "!")
    conv = conv === nothing ? (CT === :Cint ? :Int : CT === :Cdouble ? :Float64 : :identity) : conv
    quote
        $(esc(name))(w::$(esc(T))) =
            $(esc(conv))(ccall(($(QuoteNode(cget)), libfltkjl), $(esc(CT)), (Ptr{Cvoid},), _ptr(w)))
        function $(esc(setter))(w::$(esc(T)), v)
            ccall(($(QuoteNode(cset)), libfltkjl), Cvoid, (Ptr{Cvoid}, $(esc(CT))), _ptr(w), v)
            return w
        end
        $(esc(:getprop))(w::$(esc(T)), ::Val{$(QuoteNode(name))}) = $(esc(name))(w)
        $(esc(:setprop!))(w::$(esc(T)), ::Val{$(QuoteNode(name))}, v) = $(esc(setter))(w, v)
    end
end

# Declares a concrete widget type plus its constructor.
#   @widget Button AbstractButton
# defines `mutable struct Button <: AbstractButton` and
# `Button(x, y, w, h, label=""; kw...)`, which calls C `fljl_new_Button`.
macro widget(name, super, cname = name)
    cfun = QuoteNode(Symbol("fljl_new_", cname))
    N = esc(name)
    quote
        mutable struct $N <: $(esc(super))
            _ptr::Ptr{Cvoid}
            _cb::Any
            _draw::Any
            _handle::Any
            _refs::Dict{Symbol,Any}
            $N(p::Ptr{Cvoid}, cb, d, h, r::Dict{Symbol,Any}) = new(p, cb, d, h, r)
        end
        function $N(x::Integer, y::Integer, w::Integer, h::Integer, label::AbstractString = ""; kw...)
            p = ccall(($cfun, libfltkjl), Ptr{Cvoid}, (Cint, Cint, Cint, Cint, Cstring), x, y, w, h, label)
            _finish($N(p, nothing, nothing, nothing, Dict{Symbol,Any}()), kw)
        end
    end
end

function _finish(w::AbstractWidget, kw)
    _registry[getfield(w, :_ptr)] = w
    _postinit(w)
    for (k, v) in kw
        setproperty!(w, k, v)
    end
    return w
end

# Groups are closed right after construction (so later widgets do not
# silently land inside them). Use the do-block form to fill them.
_postinit(w::AbstractWidget) = nothing
_postinit(g::AbstractGroup) = end_group(g)

"""
    T(args...; kw...) do g ... end

For any group or window type `T`: create it, run the block with the new
group current (so widgets created inside it become its children), and
close it again.

```julia
win = Window(300, 200, "Hello") do win
    Button(100, 80, 100, 30, "Click"; callback = b -> println("clicked"))
end
```
"""
function (::Type{T})(f::Function, args...; kw...) where {T<:AbstractGroup}
    g = T(args...; kw...)
    begin_group(g)
    try
        f(g)
    finally
        end_group(g)
    end
    return g
end

"""
    T(args...; kw...) do w ... end

For widgets that are not groups, the do-block becomes the callback:

```julia
Button(10, 10, 100, 30, "Quit") do b
    hide!(top_window(b))
end
```
"""
(::Type{T})(f::Function, args...; kw...) where {T<:AbstractWidget} = T(args...; callback = f, kw...)

function Base.show(io::IO, w::AbstractWidget)
    print(io, nameof(typeof(w)))
    if !isvalid(w)
        print(io, "(<deleted>)")
    else
        l = _str(@ccall libfltkjl.fljl_label(_ptr(w)::Ptr{Cvoid})::Ptr{UInt8})
        x, y, ww, hh = bounds(w)
        print(io, "(", x, ", ", y, ", ", ww, ", ", hh)
        isempty(l) || print(io, ", ", repr(l))
        print(io, ")")
    end
end
