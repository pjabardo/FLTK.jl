# FLTK.jl — notes for Claude

Julia bindings for FLTK 1.4 through a hand-written C shim called with `ccall`.
There is no CxxWrap and no BinaryBuilder/JLL yet.

## Layout

- `deps/fltkjl/fltkjl.cpp`: the C shim. All exported functions are
  `API` (`extern "C"`, visible) and are named `fljl_*`.
- `deps/fltkjl/gen_constants.cpp`: prints `src/constants.jl` from the real
  FLTK headers. **Never edit `src/constants.jl` by hand.** Add the name to the
  generator and run `make -C deps`.
- `deps/Makefile`: builds `deps/usr/lib/libfltkjl.so` (gitignored) and
  regenerates the constants. `FLTK_CONFIG` selects the FLTK; it defaults to
  `../../build/fltk-config` (the sibling FLTK build in the parent folder).
  It links only `-lfltk_images -lfltk_gl -lfltk` with an rpath, on purpose:
  `fltk-config --ldflags` lists static dependencies, e.g. `-lgtk-3`, whose dev
  packages are not installed here.
- `src/core.jl`: widget handles, the pointer registry, the C→Julia hooks,
  deferred freeing, and the `@widget`/`@prop`/`@getset` macros.
- `src/widget.jl`: methods common to `Fl_Widget`/`Fl_Group`/`Fl_Window`.
- `src/widgets.jl`: concrete widget types and type-specific methods,
  plus `TextBuffer`.
- `src/app.jl`: event loop, timeouts, events, screens, colors.
- `src/draw.jl`: `fl_*` drawing functions (C++ names kept).
- `src/dialogs.jl`: dialogs, native file chooser, `Image`.
- `examples/*.jl`: FLTK.jl's own examples.
- `examples/fltk/{examples,test}/`: Julia translations of the programs in
  FLTK's `examples/` and `test/` folders (see "Translating FLTK examples").

## Commands

```bash
make -C deps                                  # build shim + regenerate constants
julia --project=. test/runtests.jl            # tests (open real windows)
julia --project=. examples/widgets_tour.jl    # run an example
```

`Pkg.test()` fails on this machine with "expected package `Test` to be
registered". That comes from the local Julia setup, not the package. Run
`test/runtests.jl` directly instead.

CI (`.github/workflows/CI.yml`) builds FLTK 1.4.5 with the X11 backend only,
then on Julia 1.10 and the latest release:
- fails if the regenerated `src/constants.jl` differs from the committed one;
- runs `test/runtests.jl` under `xvfb-run`;
- smoke-tests every `examples/*.jl` and `examples/fltk/*/*.jl`: a repeating
  1 s timeout hides all windows (so a chain of dialogs also closes), and the
  step fails if the output contains "Error in FLTK" (exceptions in callbacks
  and timeouts are only logged, they don't change the exit code).

## Checking examples locally

The smoke test only shows the windows, so it misses errors inside callbacks.
To check those, run the example with a helper script that, after ~1 s,
walks `FLTK.windows()` recursively and:
- calls each widget's `getfield(w, :_cb)` (skip windows and Quit/Exit buttons);
- for menus, `pick!(m, i)` every item that isn't a submenu (skip Quit, Open...
  and anything that opens a browser or file chooser);
- with another repeating timeout, hides every window that is a
  `ForeignWidget`: dialogs are created by FLTK, so they come back as
  `ForeignWidget`, not `AbstractWindow`.

Qualify names in such a helper (`FLTK.text`, `FLTK.label`): it runs in `Main`,
where the example may define globals with the same names. `fl_show_colormap`
only returns on a click or Escape, hiding its window doesn't end it.

## Design rules

- **FLTK owns widgets.** Every Julia-created widget is a C++ `JlW<T>`. Its
  destructor calls `_on_delete`, which removes the handle from `_registry`
  and sets `_ptr = C_NULL`. Never add finalizers that delete widgets. Use
  `destroy!` (`Fl::delete_widget`).
- **Non-widget objects** (`Image`, `TextBuffer`) do have finalizers, but these
  only queue the pointer (`_queue_free`). The queue is drained on the main
  thread in `fl_run`/`fl_wait`/`fl_check`. Keep it that way: FLTK is not
  thread-safe.
- **Lifetimes:** widgets keep referenced Julia objects alive through
  `w._refs` (`:image`, `:buffer`, `:menu_ids`, ...).
- **One trampoline per hook kind:** the widget callback, draw, handle, menu
  item (id in `user_data`) and timeout (id). They are installed in `__init__`
  via `fljl_set_hooks`. Julia exceptions are caught and logged with
  `_report` and must never unwind through C++.
- **Strings are always copied** on the C++ side (`copy_label`,
  `copy_tooltip`, and `JlBase::strbuf`/`colw` for APIs that keep pointers,
  such as `Fl_Spinner::format` and `Fl_Browser::column_widths`).
- **The shim checks indices.** FLTK itself doesn't: e.g. `Fl_Menu_::mode(-1)`
  reads outside the menu. Guard wrappers that take an index (see
  `menu_ok` in `fltkjl.cpp`) and return an empty value, or let the Julia
  side throw `BoundsError`.
- Lazily-registered box/label types (`FL_ROUND_UP_BOX`, `FL_GTK_*`, ...) are
  registered in `fljl_init()`. Add new ones there.
- **Struct fields start with `_`.** Every other property name goes through
  `getprop`/`setprop!`, so `w.label = "x"` calls `label!(w, "x")`.

## API conventions

- Constructor form: `T(x, y, w, h, label = ""; kw...)`. Keywords are applied
  as properties. Windows also accept `T(w, h, label)`.
- On a group, a do-block fills it with children. On any other widget, the
  do-block is its callback.
- Groups are closed (`end()`) after construction. `Flex` re-runs `layout!`
  after its do-block.
- Getter `foo(w)`, setter `foo!(w, v)`, property `w.foo`. Booleans use
  `isfoo`.
- Indices follow FLTK. Browser lines are 1-based. Menu items and Grid
  rows/columns are 0-based. `Group` children are 1-based in Julia
  (`g[i]`, `insert!`).
- Handles compare (`==`, `hash`) by the C++ widget they refer to, so a
  `ForeignWidget` and a registered handle for the same widget are equal.
  Groups support `keys`, so `findfirst(==(w), group)` works.
- Widgets made by FLTK itself (`scrollbar(scroll)`, dialog windows, ...) are
  `ForeignWidget`s: no callbacks or overrides, and not tracked.
- Some FLTK constants are aliases, e.g. `FL_SYMBOL_LABEL == FL_NORMAL_LABEL`;
  don't tell them apart by value.
- Avoid clashes with names exported by Base: extend Base instead
  (`Base.parent`, `Base.minimum!`, `Base.mark`, `Base.isvalid`, ...), or rename.
  `Fl_Text_Display` is `TextView` because of `Base.TextDisplay`. All
  non-underscore names are exported automatically at the end of
  `src/FLTK.jl`. After adding names, re-check for clashes with:
  `[n for n in names(FLTK) if isdefined(Base,n) && Base.isexported(Base,n) && getfield(Base,n) !== getfield(FLTK,n)]`.

## Adding a widget

1. Add `#include` and `NEW(Name, Fl_Class)` to `fltkjl.cpp`, plus `fljl_*`
   wrappers for its methods.
2. Add `@widget Name AbstractXxx` to `src/widgets.jl`, plus methods and
   `@prop`s. Pick the abstract type by behaviour. Only real user containers
   are `AbstractGroup`: their constructor ends the group automatically.
3. Run `make -C deps`, add tests, and update the README's "What's wrapped"
   table.

## Translating FLTK examples

The C++ sources are in `../fltk-1.4.5/examples` and `../fltk-1.4.5/test`.
Conventions for `examples/fltk/`:
- Same file name as the C++ program, `.jl` instead of `.cxx`.
- Header: `# Julia translation of FLTK's test/foo.cxx.`, then the original
  copyright lines (`grep -i copyright foo.cxx`), then
  `# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php`.
  Note anything left out right below the header.
- A C++ subclass that overrides `draw()`/`handle()` becomes a plain widget
  with `draw!`/`handle!`; per-instance state lives in the closure (see
  `draggable-group.jl`). Callback user data becomes a closure.
- Don't name globals after FLTK exports (`window`, `text`, ...): assigning
  them in `Main` fails or shadows the function. Use `win`, `win1`, ...
- Data files (e.g. the XPM in `test/pixmaps/`) are copied next to the
  translation and loaded with `joinpath(@__DIR__, ...)`.
- Interpolation pitfall: `"$name!"` reads the variable `name!`; write
  `"$(name)!"`.
- After adding one, update the list in the README's "FLTK's own examples, in
  Julia" section.

Done: 16 programs from `examples/` and 22 from `test/` (see the README).
Not yet translated:
- `test/resize-example1..5c` (use `test/resize-arrows.cxx`; only need what is
  already wrapped);
- big demos: `sudoku`, `blocks`, `checkers`, `mandelbrot` (simplify: no
  overlay/printing), `fonts`, `grid_alignment`, `ask`;
- programs that need something from "Not yet wrapped": all `table-*`,
  `tree-of-tables`, `howto-menu-with-images`, `chart-simple`, `input_choice`,
  `howto-drag-and-drop`, `clipboard`, `textdisplay-with-colors`, `offscreen`,
  `threads`, `help_dialog`, `shapedwindow`, the OpenGL programs.

## Environment

- FLTK 1.4.5 source is in `../fltk-1.4.5` and its build in `../build`
  (shared libs, X11 + Wayland). The desktop session is Wayland. To take
  screenshots, run with `FLTK_BACKEND=x11` and, from an `add_timeout` in a
  helper script, `import -window "<title>" out.png` (ImageMagick), then hide
  the windows. Windows without a title can't be found by name: get the id
  from `xwininfo -root -tree`, matching the size times `screen_scale(0)`
  (the display runs at 125%). `import -window root` does not work here.
- Put temporary scripts and screenshots in the session's scratchpad, not in
  the repository.
- Pushing to GitHub (pjabardo/FLTK.jl) has to be done by the user from their
  own terminal: Claude's sessions have no GitHub credentials and no `gh`.

## Not yet wrapped (candidate work)

`Fl_Table` (most useful next: it unlocks ~10 FLTK examples), offscreen
drawing / image surfaces, printing, `Fl_Multi_Label` (images in menu items),
cursors from images, `Fl_Chart`, `Fl_Input_Choice`, `Fl_Help_View`,
`Fl::add_fd`, window shapes, `Fl_Preferences`,
`Fl::paste`/drag and drop, text styling in `Fl_Text_Display`, Julia-side use
of `Fl::lock`/`Fl::awake`. `fl_run()` gives other Julia tasks a turn only
every ~10 ms; this could be improved.
