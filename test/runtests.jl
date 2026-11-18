using FLTK, Test

# These tests open real windows briefly, so they need a display.
const HAS_DISPLAY = haskey(ENV, "DISPLAY") || haskey(ENV, "WAYLAND_DISPLAY")

pump(n = 20) = for _ in 1:n; fl_wait(0.01); end

@testset "constants" begin
    @test FL_PUSH isa Cint
    @test FL_RED isa Cuint
    @test FL_ROUND_UP_BOX > FL_BORDER_FRAME   # lazily-registered box types resolved
    @test FLTK.api_version() >= 10400
    @test fl_rgb_color(255, 0, 0) == 0xff000000
end

HAS_DISPLAY && @testset "widgets" begin
    clicks = Ref(0)
    local btn, sl, inp, ch, br, chk, tv
    win = DoubleWindow(420, 360, "FLTK.jl test") do win
        btn = Button(10, 10, 100, 30, "Press"; callback = b -> clicks[] += 1, tooltip = "tip")
        sl = HorValueSlider(10, 50, 200, 25; range = (0, 10))
        inp = Input(60, 85, 150, 25, "Name:")
        ch = Choice(60, 120, 150, 25, "Pick:"; items = ["one", "two", "three"])
        br = HoldBrowser(220, 10, 190, 120)
        chk = CheckButton(10, 150, 120, 25, "Check")
        tv = TextEditor(10, 190, 400, 160)
    end
    @test length(win) == 7
    @test win[1] === btn
    @test parent(btn) === win
    @test label(btn) == "Press" && btn.label == "Press"
    @test tooltip(btn) == "tip"
    btn.label = "Changed"
    @test btn.label == "Changed"
    @test bounds(btn) == (x = 10, y = 10, w = 100, h = 30)
    @test btn.w == 100

    show!(win); pump()
    @test isshown(win)

    do_callback(btn)
    @test clicks[] == 1
    btn.callback = nothing
    do_callback(btn)
    @test clicks[] == 1

    @test sl.range == (0.0, 10.0)
    sl.value = 3.5
    @test value(sl) == 3.5

    inp.value = "hello"
    @test value(inp) == "hello"
    @test length(inp) == 5

    @test text(ch, 1) == "two"
    ch.value = 2
    @test text(ch) == "three"

    add!(br, ["alpha", "beta", "gamma"])
    @test length(br) == 3 && br[2] == "beta"
    value!(br, 3)
    @test text(br) == "gamma"
    @test collect(br) == ["alpha", "beta", "gamma"]

    chk.value = true
    @test value(chk) === true

    tv.value = "line 1\nline 2"
    @test value(tv) == "line 1\nline 2"
    append!(tv, "\nline 3")
    @test search_forward(buffer(tv), "line 3") == 14

    # menus with per-item callbacks
    picked = String[]
    local mb
    mgroup = Group(0, 0, 420, 30) do g
        mb = MenuBar(0, 0, 420, 30)
    end
    add_item!(m -> push!(picked, item_path(m)), mb, "File/Open"; shortcut = FL_CTRL + Int('o'))
    idx = add_item!(mb, "File/Quit")
    @test find_index(mb, "File/Quit") == idx
    @test length(picked) == 0

    # custom draw + handle
    drawn = Ref(0)
    events = Int[]
    local box
    win2 = Window(200, 100, "draw") do w
        box = Box(0, 0, 200, 100)
    end
    draw!(box) do b
        drawn[] += 1
        fl_rectf(b.x, b.y, b.w, b.h, FL_DARK_BLUE)
        fl_color(FL_WHITE); fl_font(FL_HELVETICA, 14)
        fl_draw("custom", b.x, b.y, b.w, b.h, FL_ALIGN_CENTER)
    end
    handle!(box) do b, ev
        push!(events, ev)
        nothing   # fall through to default handling
    end
    show!(win2); pump()
    @test drawn[] >= 1
    @test !isempty(events)        # at least FL_SHOW
    @test FL_SHOW in events

    # errors in callbacks are reported, not fatal
    draw!(box, b -> error("boom"))
    redraw!(box)
    @test_logs (:error,) match_mode = :any pump()

    # timeouts
    ticks = Ref(0)
    id = add_timeout(0.01; repeat = true) do
        ticks[] += 1
    end
    for _ in 1:50
        fl_wait(0.01)
        ticks[] >= 3 && break
    end
    remove_timeout(id)
    @test ticks[] >= 3
    n = ticks[]; pump(5)
    @test ticks[] == n

    # images
    px = zeros(UInt8, 3, 16, 16); px[1, :, :] .= 0xff
    img = RGBImage(px)
    @test size(img) == (16, 16) && channels(img) == 3
    image!(btn, img)
    @test image(btn) === img

    # deletion invalidates the handle (children too)
    destroy!(win2); pump(3)
    @test !isvalid(win2) && !isvalid(box)
    @test_throws ArgumentError label(box)

    hide!(win); destroy!(win); destroy!(mgroup); pump(3)
    @test !isvalid(btn)
    @test isempty(FLTK._registry)
end

HAS_DISPLAY && @testset "layout" begin
    local a, b, c
    win = Window(300, 200, "flex") do win
        Flex(0, 0, 300, 200; direction = FLEX_ROW, margin = 5, gap = 5) do f
            a = Button(0, 0, 0, 0, "a")
            b = Button(0, 0, 0, 0, "b")
            fixed!(f, b, 50)
            c = Button(0, 0, 0, 0, "c")
        end
    end
    show!(win); pump()
    @test b.w == 50
    @test a.w == c.w
    @test a.x == 5
    destroy!(win); pump(3)

    local g1, g2
    win = Window(300, 200, "grid") do win
        g = Grid(0, 0, 300, 200) do g
            layout!(g, 2, 2; margin = 0, gap = 0)
            g1 = Box(0, 0, 0, 0, "1"); g2 = Box(0, 0, 0, 0, "2")
            place!(g, g1, 0, 0)
            place!(g, g2, 1, 0; colspan = 2)
        end
    end
    show!(win); pump()
    @test g2.w == 300
    @test g1.w == 150
    destroy!(win); pump(3)
end

@testset "misc" begin
    @test eventname(FL_PUSH) == "FL_PUSH"
    @test box_dx(FL_UP_BOX) > 0 && box_dw(FL_NO_BOX) == 0
    old = option(OPTION_ARROW_FOCUS)
    option!(OPTION_ARROW_FOCUS, !old); @test option(OPTION_ARROW_FOCUS) == !old
    option!(OPTION_ARROW_FOCUS, old)

    local b, inp, sc, s
    win = Window(300, 200, "misc") do win
        b = Button(10, 10, 50, 25, "b"; compact = true, horizontal_label_margin = 3)
        inp = MultilineInput(10, 40, 100, 40; shortcut = FL_F + 1)
        sc = SchemeChoice(120, 10, 100, 25)
        RoundClock(120, 40, 50, 50)
        s = Scroll(180, 100, 100, 90)
    end
    @test iscompact(b) && b.horizontal_label_margin == 3
    @test inp.shortcut == FL_F + 1
    tab_nav!(inp, false); @test !tab_nav(inp)
    @test sc isa AbstractMenu
    @test scrollbar(s) isa FLTK.ForeignWidget && hscrollbar(s) isa FLTK.ForeignWidget
    # handles compare by the widget they refer to
    @test win[1] == b && findfirst(==(inp), win) == 2
    @test parent(b) == win
    destroy!(win); pump(3)
end

@testset "menu pick" begin
    picked = String[]
    local m
    win = Window(200, 100, "menu") do win
        m = MenuBar(0, 0, 200, 25)
        add_item!(x -> push!(picked, "open"), m, "File/Open")
        add_item!(m, "Edit/Toggle"; flags = FL_MENU_TOGGLE)
    end
    pick!(m, find_index(m, "File/Open"))
    @test picked == ["open"]
    t = find_index(m, "Edit/Toggle")
    pick!(m, t); @test item_value(m, t)
    @test_throws BoundsError pick!(m, 100)
    @test mode(m, -1) == 0 && text(m, 100) === nothing
    destroy!(win); pump(3)
end
