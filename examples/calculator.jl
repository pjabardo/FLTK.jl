# A calculator laid out with Fl_Flex and Fl_Grid.
using FLTK

expr = Ref("")
display = Ref{Any}(nothing)

# Evaluate only arithmetic made from the calculator's own keys.
function calc(s)
    all(c -> c in "0123456789.+-*/() ", s) || return "error"
    try
        string(Base.eval(Module(), Meta.parse(s)))
    catch
        "error"
    end
end

win = Window(300, 400, "Calculator") do win
    Flex(0, 0, 300, 400; direction = FLEX_COLUMN, margin = 8, gap = 8) do col
        display[] = Output(0, 0, 0, 0; textsize = 26, textfont = FL_COURIER_BOLD)
        fixed!(col, display[], 50)
        Grid(0, 0, 0, 0) do g
            layout!(g, 5, 4; margin = 0, gap = 6)
            keys = ["C", "(", ")", "/",
                    "7", "8", "9", "*",
                    "4", "5", "6", "-",
                    "1", "2", "3", "+",
                    "0", ".", "="]
            for (i, k) in enumerate(keys)
                r, c = divrem(i - 1, 4)
                b = Button(0, 0, 0, 0, k; labelsize = 20) do b
                    expr[] = k == "C" ? "" : k == "=" ? calc(expr[]) : expr[] * k
                    value!(display[], expr[])
                end
                if k == "="
                    place!(g, b, r, c; colspan = 2)
                    b.color = FL_DARK_GREEN
                    b.labelcolor = FL_WHITE
                else
                    place!(g, b, r, c)
                end
            end
        end
    end
end

resizable!(win, win[1])
show!(win)
fl_run()
