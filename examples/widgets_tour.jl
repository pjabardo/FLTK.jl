# A tour of common widgets: menus, tabs, buttons, inputs, valuators,
# browsers, progress bars and timers.
using FLTK

scheme!("gtk+")

status = Ref{Any}(nothing)
say(msg) = (status[].label = msg)

win = DoubleWindow(560, 420, "FLTK.jl widget tour") do win
    menu = MenuBar(0, 0, 560, 28)
    add_item!(menu, "&File/&Open..."; shortcut = FL_CTRL + Int('o')) do m
        files = native_file_chooser(; title = "Open a file")
        say(files === nothing ? "Cancelled" : "Chose $(first(files))")
    end
    add_item!(menu, "&File/&Quit"; shortcut = FL_CTRL + Int('q')) do m
        hide!(win)
    end
    add_item!(menu, "&Options/Dark background"; flags = FL_MENU_TOGGLE) do m
        dark = item_value(m, value(m))
        dark ? background!(50, 50, 55) : background!(212, 208, 200)
        dark ? foreground!(230, 230, 230) : foreground!(0, 0, 0)
        fl_redraw()
    end
    add_item!(menu, "&Help/&About") do m
        fl_message("FLTK.jl\nFLTK API version $(FLTK.api_version())")
    end

    Tabs(10, 38, 540, 340) do tabs
        Group(10, 63, 540, 315, "Buttons") do g
            Button(30, 90, 120, 30, "Button"; callback = b -> say("Button pressed"))
            ReturnButton(30, 130, 120, 30, "Return"; callback = b -> say("Return pressed"))
            RepeatButton(30, 170, 120, 30, "Repeat"; callback = b -> say("Repeat $(time())"))
            LightButton(170, 90, 120, 30, "Light"; callback = b -> say("Light: $(value(b))"))
            CheckButton(170, 130, 120, 30, "Check"; callback = b -> say("Check: $(value(b))"))
            ToggleButton(170, 170, 120, 30, "Toggle"; callback = b -> say("Toggle: $(value(b))"))
            Group(310, 90, 200, 110; box = FL_ENGRAVED_BOX) do rg
                for (i, name) in enumerate(("Red", "Green", "Blue"))
                    RadioRoundButton(320, 60 + 35i, 150, 30, name; callback = b -> say("Radio: $name"))
                end
            end
        end
        Group(10, 63, 540, 315, "Inputs") do g
            name = Input(110, 90, 200, 28, "Name:"; when = FL_WHEN_CHANGED,
                         callback = i -> say("Hello, $(value(i))"))
            IntInput(110, 125, 100, 28, "Integer:")
            FloatInput(110, 160, 100, 28, "Float:")
            SecretInput(110, 195, 200, 28, "Password:")
            Choice(110, 230, 150, 28, "Choice:"; items = ["Apples", "Oranges", "Pears"],
                   callback = c -> say("Picked $(text(c))"))
            Spinner(110, 265, 80, 28, "Spinner:"; callback = s -> say("Spinner = $(value(s))"))
            MultilineInput(330, 90, 200, 160, "Notes")
        end
        Group(10, 63, 540, 315, "Valuators") do g
            readout = ValueOutput(380, 90, 120, 28, "Value:")
            show_value = v -> (value!(readout, value(v)); say("$(nameof(typeof(v))) = $(round(value(v); digits = 2))"))
            HorValueSlider(30, 90, 250, 25, "HorValueSlider"; range = (0, 100), step = 1, callback = show_value)
            HorNiceSlider(30, 145, 250, 25, "HorNiceSlider"; callback = show_value)
            Dial(30, 200, 80, 80, "Dial"; callback = show_value)
            Roller(140, 200, 25, 100, "Roller"; callback = show_value)
            Counter(200, 210, 150, 25, "Counter"; step = 0.1, callback = show_value)
            Slider(470, 140, 25, 200, "Slider"; callback = show_value)
            ValueInput(380, 300, 80, 28, "ValueInput"; callback = show_value)
        end
        Group(10, 63, 540, 315, "Browsers") do g
            b = HoldBrowser(30, 90, 230, 270; callback = b -> say("Selected: $(text(b))"))
            add!(b, ["@bBold line", "@iItalic line", "@C1Red line", "Plain line"])
            for i in 1:30
                add!(b, "Item $i\tcolumn 2")
            end
            column_widths!(b, [120, 80])
            cb = CheckBrowser(280, 90, 250, 200; callback = c -> say("Checked: $(join(checked_items(c), ", "))"))
            add!(cb, ["Milk", "Eggs", "Bread", "Coffee"])
            t = Tree(280, 300, 250, 60; callback = t -> say("Tree: $(tree_item(t))"))
            add!(t, "Fruit/Apple"); add!(t, "Fruit/Pear"); add!(t, "Veg/Carrot")
            showroot!(t, false)
        end
        Group(10, 63, 540, 315, "Progress") do g
            p = Progress(30, 100, 480, 30, "0%"; selection_color = FL_DARK_GREEN)
            range!(p, 0, 100)
            local timer_id = 0
            Button(30, 160, 100, 30, "Start") do b
                remove_timeout(timer_id)
                value!(p, 0)
                timer_id = add_timeout(0.05; repeat = true) do
                    v = value(p) + 1
                    value!(p, v); label!(p, "$(round(Int, v))%")
                    v >= 100 && remove_timeout(timer_id)
                end
            end
            Clock(380, 160, 130, 130)
        end
    end
    status[] = Box(10, 385, 540, 28, "Ready"; box = FL_DOWN_BOX, align = FL_ALIGN_LEFT | FL_ALIGN_INSIDE)
end

resizable!(win, win[2])
show!(win)
fl_run()
