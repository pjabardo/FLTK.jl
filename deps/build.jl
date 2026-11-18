# Run by `Pkg.build("FLTK")`: compiles the C shim against FLTK 1.4.
# Set ENV["FLTK_CONFIG"] to the fltk-config of the FLTK build you want.
cd(@__DIR__) do
    args = ["make", "-j"]
    haskey(ENV, "FLTK_CONFIG") && push!(args, "FLTK_CONFIG=$(ENV["FLTK_CONFIG"])")
    run(Cmd(args))
end
