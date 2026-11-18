"""
    FLTK

Julia bindings for the FLTK 1.4 GUI toolkit.

```julia
using FLTK
win = Window(340, 180, "Hello") do win
    Button(120, 70, 100, 40, "Click me"; callback = b -> fl_message("Hello from Julia!"))
end
show!(win)
fl_run()
```
"""
module FLTK

const libfltkjl = joinpath(@__DIR__, "..", "deps", "usr", "lib", "libfltkjl.so")

include("constants.jl")
include("core.jl")
include("widget.jl")
include("dialogs.jl")
include("widgets.jl")
include("app.jl")
include("draw.jl")

function __init__()
    isfile(libfltkjl) || error("FLTK.jl: $libfltkjl not found. Build it with `import Pkg; Pkg.build(\"FLTK\")`.")
    @ccall libfltkjl.fljl_init()::Cvoid
    _install_hooks()
end

# Export everything public: constants, widget types and functions.
const _private = Set([:libfltkjl, :getprop, :setprop!, :eval, :include, :FLTK,
                      :AW, :AV, :AM, :AB, :ATD, :AWin])
for n in names(@__MODULE__; all = true)
    s = String(n)
    (startswith(s, '_') || startswith(s, '#') || startswith(s, '@') || n in _private) && continue
    isdefined(Base, n) && getfield(Base, n) === getfield(@__MODULE__, n) && continue
    @eval export $n
end
export @prop

end # module
