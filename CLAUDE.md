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
then runs the tests and smoke-tests every example under `xvfb-run`, on Julia
1.10 and the latest release. It also fails if the regenerated
`src/constants.jl` differs from the committed one.

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

## Environment

- FLTK 1.4.5 source is in `../fltk-1.4.5` and its build in `../build`
  (shared libs, X11 + Wayland). The desktop session is Wayland. To take
  screenshots, run with `FLTK_BACKEND=x11` and use ImageMagick
  `import -window "<title>" out.png`.
- Pushing to GitHub (pjabardo/FLTK.jl) has to be done by the user from their
  own terminal: Claude's sessions have no GitHub credentials and no `gh`.

## Not yet wrapped (candidate work)

`Fl_Table`, offscreen drawing / image surfaces, printing, `Fl_Preferences`,
`Fl::paste`/drag and drop, text styling in `Fl_Text_Display`, Julia-side use
of `Fl::lock`/`Fl::awake`. `fl_run()` gives other Julia tasks a turn only
every ~10 ms; this could be improved.
