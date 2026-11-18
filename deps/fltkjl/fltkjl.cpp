// fltkjl.cpp -- a flat C API over FLTK 1.4 for use from Julia via ccall.
//
// Design:
//  * Every widget created from Julia is a JlW<T>, a thin subclass of the FLTK
//    class T. It lets Julia override draw() and handle(), and it notifies
//    Julia from its destructor, so Julia handles never dangle.
//  * All widget callbacks go through one C trampoline that calls a single
//    Julia function pointer with the Fl_Widget*. Julia keeps a registry
//    Ptr -> Julia object and dispatches to the user's closure from there.
//  * Strings passed in are always copied (copy_label, copy_tooltip, ...),
//    so Julia never needs to keep string buffers alive.

#include <FL/Fl.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Gl_Window.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Radio_Button.H>
#include <FL/Fl_Radio_Round_Button.H>
#include <FL/Fl_Radio_Light_Button.H>
#include <FL/Fl_Toggle_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Valuator.H>
#include <FL/Fl_Slider.H>
#include <FL/Fl_Hor_Slider.H>
#include <FL/Fl_Nice_Slider.H>
#include <FL/Fl_Hor_Nice_Slider.H>
#include <FL/Fl_Fill_Slider.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/Fl_Hor_Value_Slider.H>
#include <FL/Fl_Scrollbar.H>
#include <FL/Fl_Dial.H>
#include <FL/Fl_Roller.H>
#include <FL/Fl_Counter.H>
#include <FL/Fl_Adjuster.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Value_Output.H>
#include <FL/Fl_Spinner.H>
#include <FL/Fl_Progress.H>
#include <FL/Fl_Menu_.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Browser.H>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Select_Browser.H>
#include <FL/Fl_Multi_Browser.H>
#include <FL/Fl_Check_Browser.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Tile.H>
#include <FL/Fl_Flex.H>
#include <FL/Fl_Grid.H>
#include <FL/Fl_Wizard.H>
#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <FL/Fl_Terminal.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Clock.H>
#include <FL/Fl_Round_Clock.H>
#include <FL/Fl_Scheme_Choice.H>
#include <FL/fl_show_colormap.H>
#include <FL/names.h>
#include <FL/Fl_Image.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_File_Chooser.H>
#include <FL/fl_ask.H>
#include <FL/filename.H>
#include <FL/fl_draw.H>

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#define API extern "C" __attribute__((visibility("default")))

typedef Fl_Widget W;

// ---------------------------------------------------------------------------
// Hooks into Julia (set once from Julia's __init__)
// ---------------------------------------------------------------------------
typedef void (*widget_fn)(W *);
typedef int (*handle_fn)(W *, int);
typedef void (*menu_fn)(W *, intptr_t);
typedef void (*id_fn)(intptr_t);

static widget_fn g_on_delete = nullptr;
static widget_fn g_draw = nullptr;
static handle_fn g_handle = nullptr;
static widget_fn g_callback = nullptr;
static menu_fn g_menu_cb = nullptr;
static id_fn g_timeout_cb = nullptr;

API void fljl_set_hooks(widget_fn on_delete, widget_fn draw, handle_fn handle,
                        widget_fn callback, menu_fn menu_cb, id_fn timeout_cb) {
  g_on_delete = on_delete;
  g_draw = draw;
  g_handle = handle;
  g_callback = callback;
  g_menu_cb = menu_cb;
  g_timeout_cb = timeout_cb;
}

// Many box/label types (FL_ROUND_UP_BOX, FL_GTK_UP_BOX, FL_SHADOW_LABEL, ...)
// are only registered with FLTK the first time their macro is evaluated.
// Julia uses their numeric values directly, so register them all up front.
API void fljl_init() {
  volatile int sink = 0;
  sink += FL_ROUND_UP_BOX + FL_SHADOW_BOX + FL_ROUNDED_BOX + FL_RFLAT_BOX + FL_RSHADOW_BOX;
  sink += FL_DIAMOND_UP_BOX + FL_OVAL_BOX + FL_PLASTIC_UP_BOX + FL_GTK_UP_BOX;
  sink += FL_GLEAM_UP_BOX + FL_OXY_UP_BOX;
  sink += FL_SHADOW_LABEL + FL_ENGRAVED_LABEL + FL_EMBOSSED_LABEL + FL_MULTI_LABEL + FL_ICON_LABEL + FL_IMAGE_LABEL;
  (void)sink;
  fl_register_images();
}

// ---------------------------------------------------------------------------
// The Julia-aware widget subclass
// ---------------------------------------------------------------------------
struct JlBase {
  bool jl_draw = false;
  bool jl_handle = false;
  std::string strbuf;        // storage for strings FLTK does not copy
  std::vector<int> colw;     // storage for Fl_Browser::column_widths
  virtual ~JlBase() {}
  virtual void super_draw() = 0;
  virtual int super_handle(int e) = 0;
};

template <class T> struct JlW : public T, public JlBase {
  template <class... A> JlW(A... a) : T(a...) {}
  ~JlW() override {
    if (g_on_delete) g_on_delete(static_cast<W *>(this));
  }
  void draw() override {
    if (jl_draw && g_draw) g_draw(static_cast<W *>(this));
    else T::draw();
  }
  int handle(int e) override {
    if (jl_handle && g_handle) return g_handle(static_cast<W *>(this), e);
    return T::handle(e);
  }
  void super_draw() override { T::draw(); }
  int super_handle(int e) override { return T::handle(e); }
};

static JlBase *jlb(W *w) { return w ? dynamic_cast<JlBase *>(w) : nullptr; }

API int fljl_is_julia_widget(W *w) { return jlb(w) != nullptr; }
API void fljl_enable_draw(W *w, int on) { if (auto b = jlb(w)) b->jl_draw = on; }
API void fljl_enable_handle(W *w, int on) { if (auto b = jlb(w)) b->jl_handle = on; }
API void fljl_super_draw(W *w) { if (auto b = jlb(w)) b->super_draw(); }
API int fljl_super_handle(W *w, int e) {
  if (auto b = jlb(w)) return b->super_handle(e);
  return w->handle(e);
}

static void cb_tramp(W *w, void *) { if (g_callback) g_callback(w); }
static void menu_tramp(W *w, void *d) { if (g_menu_cb) g_menu_cb(w, (intptr_t)d); }
static void timeout_tramp(void *d) { if (g_timeout_cb) g_timeout_cb((intptr_t)d); }

// ---------------------------------------------------------------------------
// Constructors
// ---------------------------------------------------------------------------
#define NEW(Name, Cls)                                                          \
  API W *fljl_new_##Name(int x, int y, int w, int h, const char *l) {          \
    auto *p = new JlW<Cls>(x, y, w, h, (const char *)nullptr);                 \
    if (l && *l) p->copy_label(l);                                             \
    return p;                                                                  \
  }

NEW(Window, Fl_Window)
NEW(DoubleWindow, Fl_Double_Window)
NEW(GlWindow, Fl_Gl_Window)
NEW(Group, Fl_Group)
NEW(Box, Fl_Box)
NEW(Button, Fl_Button)
NEW(LightButton, Fl_Light_Button)
NEW(CheckButton, Fl_Check_Button)
NEW(RoundButton, Fl_Round_Button)
NEW(RadioButton, Fl_Radio_Button)
NEW(RadioRoundButton, Fl_Radio_Round_Button)
NEW(RadioLightButton, Fl_Radio_Light_Button)
NEW(ToggleButton, Fl_Toggle_Button)
NEW(ReturnButton, Fl_Return_Button)
NEW(RepeatButton, Fl_Repeat_Button)
NEW(Input, Fl_Input)
NEW(IntInput, Fl_Int_Input)
NEW(FloatInput, Fl_Float_Input)
NEW(SecretInput, Fl_Secret_Input)
NEW(MultilineInput, Fl_Multiline_Input)
NEW(Output, Fl_Output)
NEW(MultilineOutput, Fl_Multiline_Output)
NEW(Slider, Fl_Slider)
NEW(HorSlider, Fl_Hor_Slider)
NEW(NiceSlider, Fl_Nice_Slider)
NEW(HorNiceSlider, Fl_Hor_Nice_Slider)
NEW(FillSlider, Fl_Fill_Slider)
NEW(ValueSlider, Fl_Value_Slider)
NEW(HorValueSlider, Fl_Hor_Value_Slider)
NEW(Scrollbar, Fl_Scrollbar)
NEW(Dial, Fl_Dial)
NEW(Roller, Fl_Roller)
NEW(Counter, Fl_Counter)
NEW(Adjuster, Fl_Adjuster)
NEW(ValueInput, Fl_Value_Input)
NEW(ValueOutput, Fl_Value_Output)
NEW(Spinner, Fl_Spinner)
NEW(Progress, Fl_Progress)
NEW(MenuBar, Fl_Menu_Bar)
NEW(MenuButton, Fl_Menu_Button)
NEW(Choice, Fl_Choice)
NEW(Browser, Fl_Browser)
NEW(HoldBrowser, Fl_Hold_Browser)
NEW(SelectBrowser, Fl_Select_Browser)
NEW(MultiBrowser, Fl_Multi_Browser)
NEW(CheckBrowser, Fl_Check_Browser)
NEW(Tabs, Fl_Tabs)
NEW(Scroll, Fl_Scroll)
NEW(Pack, Fl_Pack)
NEW(Tile, Fl_Tile)
NEW(Flex, Fl_Flex)
NEW(Grid, Fl_Grid)
NEW(Wizard, Fl_Wizard)
NEW(TextDisplay, Fl_Text_Display)
NEW(TextEditor, Fl_Text_Editor)
NEW(Terminal, Fl_Terminal)
NEW(Tree, Fl_Tree)
NEW(Clock, Fl_Clock)
NEW(RoundClock, Fl_Round_Clock)
NEW(SchemeChoice, Fl_Scheme_Choice)

// Windows placed by the window manager.
API W *fljl_new_window_wh(int w, int h, const char *l, int dbl) {
  Fl_Window *p = dbl ? (Fl_Window *)new JlW<Fl_Double_Window>(w, h, (const char *)nullptr)
                     : (Fl_Window *)new JlW<Fl_Window>(w, h, (const char *)nullptr);
  if (l && *l) p->copy_label(l);
  return p;
}

// Deferred, safe deletion (children are deleted with their parents).
API void fljl_delete_widget(W *w) { Fl::delete_widget(w); }

// ---------------------------------------------------------------------------
// Fl_Widget
// ---------------------------------------------------------------------------
API int fljl_x(W *w) { return w->x(); }
API int fljl_y(W *w) { return w->y(); }
API int fljl_w(W *w) { return w->w(); }
API int fljl_h(W *w) { return w->h(); }
API void fljl_resize(W *w, int x, int y, int ww, int hh) { w->resize(x, y, ww, hh); }
API const char *fljl_label(W *w) { return w->label(); }
API void fljl_set_label(W *w, const char *l) { w->copy_label(l); }
API int fljl_horizontal_label_margin(W *w) { return w->horizontal_label_margin(); }
API void fljl_set_horizontal_label_margin(W *w, int m) { w->horizontal_label_margin(m); }
API int fljl_vertical_label_margin(W *w) { return w->vertical_label_margin(); }
API void fljl_set_vertical_label_margin(W *w, int m) { w->vertical_label_margin(m); }
API int fljl_label_image_spacing(W *w) { return w->label_image_spacing(); }
API void fljl_set_label_image_spacing(W *w, int m) { w->label_image_spacing(m); }
API int fljl_labelfont(W *w) { return w->labelfont(); }
API void fljl_set_labelfont(W *w, int f) { w->labelfont(f); }
API int fljl_labelsize(W *w) { return w->labelsize(); }
API void fljl_set_labelsize(W *w, int s) { w->labelsize(s); }
API unsigned fljl_labelcolor(W *w) { return w->labelcolor(); }
API void fljl_set_labelcolor(W *w, unsigned c) { w->labelcolor(c); }
API int fljl_labeltype(W *w) { return w->labeltype(); }
API void fljl_set_labeltype(W *w, int t) { w->labeltype((Fl_Labeltype)t); }
API unsigned fljl_align(W *w) { return w->align(); }
API void fljl_set_align(W *w, unsigned a) { w->align(a); }
API int fljl_box(W *w) { return w->box(); }
API void fljl_set_box(W *w, int b) { w->box((Fl_Boxtype)b); }
API unsigned fljl_color(W *w) { return w->color(); }
API void fljl_set_color(W *w, unsigned c) { w->color(c); }
API unsigned fljl_selection_color(W *w) { return w->selection_color(); }
API void fljl_set_selection_color(W *w, unsigned c) { w->selection_color(c); }
API const char *fljl_tooltip(W *w) { return w->tooltip(); }
API void fljl_set_tooltip(W *w, const char *t) { w->copy_tooltip(t); }
API int fljl_type(W *w) { return w->type(); }
API void fljl_set_type(W *w, int t) { w->type((uchar)t); }
API int fljl_when(W *w) { return w->when(); }
API void fljl_set_when(W *w, int t) { w->when((uchar)t); }
API void fljl_show(W *w) { w->show(); }
API void fljl_hide(W *w) { w->hide(); }
API int fljl_visible(W *w) { return w->visible(); }
API int fljl_visible_r(W *w) { return w->visible_r(); }
API void fljl_activate(W *w) { w->activate(); }
API void fljl_deactivate(W *w) { w->deactivate(); }
API int fljl_active(W *w) { return w->active(); }
API int fljl_active_r(W *w) { return w->active_r(); }
API int fljl_take_focus(W *w) { return w->take_focus(); }
API void fljl_set_visible_focus(W *w, int on) { if (on) w->set_visible_focus(); else w->clear_visible_focus(); }
API void fljl_redraw(W *w) { w->redraw(); }
API void fljl_redraw_label(W *w) { w->redraw_label(); }
API int fljl_damage(W *w) { return w->damage(); }
API int fljl_changed(W *w) { return w->changed(); }
API void fljl_set_changed(W *w, int on) { if (on) w->set_changed(); else w->clear_changed(); }
API void fljl_set_julia_callback(W *w) { w->callback(cb_tramp); }
API void fljl_clear_callback(W *w) { w->callback((Fl_Callback *)nullptr); }
API void fljl_do_callback(W *w) { w->do_callback(); }
API int fljl_callback_reason(W *w) { return (int)Fl::callback_reason(); }
API W *fljl_parent(W *w) { return w->parent(); }
API W *fljl_window(W *w) { return w->window(); }
API W *fljl_top_window(W *w) { return w->top_window(); }
API int fljl_is_group(W *w) { return w->as_group() != nullptr; }
API int fljl_is_window(W *w) { return w->as_window() != nullptr; }
API void fljl_set_image(W *w, Fl_Image *i) { w->image(i); }
API void fljl_set_deimage(W *w, Fl_Image *i) { w->deimage(i); }
API void fljl_measure_label(W *w, int *ww, int *hh) { w->measure_label(*ww, *hh); }
API int fljl_contains(W *a, W *b) { return a->contains(b); }
API int fljl_inside(W *a, W *b) { return a->inside(b); }
API int fljl_shortcut_label(W *w) { return w->shortcut_label(); }

// ---------------------------------------------------------------------------
// Fl_Group
// ---------------------------------------------------------------------------
#define G(w) ((Fl_Group *)(w))
API void fljl_begin(W *w) { G(w)->begin(); }
API void fljl_end(W *w) { G(w)->end(); }
API W *fljl_current_group() { return Fl_Group::current(); }
API void fljl_set_current_group(W *g) { Fl_Group::current(g ? g->as_group() : nullptr); }
API void fljl_add(W *g, W *c) { G(g)->add(c); }
API void fljl_insert(W *g, W *c, int i) { G(g)->insert(*c, i); }
API void fljl_remove(W *g, W *c) { G(g)->remove(c); }
API void fljl_clear(W *g) { G(g)->clear(); }
API int fljl_children(W *g) { return G(g)->children(); }
API W *fljl_child(W *g, int i) { return G(g)->child(i); }
API int fljl_find(W *g, W *c) { return G(g)->find(c); }
API void fljl_set_resizable(W *g, W *c) { G(g)->resizable(c); }
API W *fljl_resizable(W *g) { return G(g)->resizable(); }
API void fljl_init_sizes(W *g) { G(g)->init_sizes(); }
API void fljl_clip_children(W *g, int c) { G(g)->clip_children(c); }

// ---------------------------------------------------------------------------
// Fl_Window
// ---------------------------------------------------------------------------
#define WIN(w) ((Fl_Window *)(w))
API void fljl_size_range(W *w, int a, int b, int c, int d) { WIN(w)->size_range(a, b, c, d); }
API void fljl_fullscreen(W *w, int on) { if (on) WIN(w)->fullscreen(); else WIN(w)->fullscreen_off(); }
API int fljl_fullscreen_active(W *w) { return WIN(w)->fullscreen_active(); }
API void fljl_set_modal(W *w, int m) {
  if (m == 1) WIN(w)->set_modal();
  else if (m == 2) WIN(w)->set_non_modal();
  else WIN(w)->clear_modal_states();
}
API int fljl_modal(W *w) { return WIN(w)->modal(); }
API void fljl_border(W *w, int b) { WIN(w)->border(b); }
API void fljl_xclass(W *w, const char *c) { WIN(w)->xclass(c); }
API void fljl_cursor(W *w, int c) { WIN(w)->cursor((Fl_Cursor)c); }
API int fljl_shown(W *w) { return WIN(w)->shown(); }
API void fljl_iconize(W *w) { WIN(w)->iconize(); }
API void fljl_hotspot(W *w, W *target) { WIN(w)->hotspot(target); }
API void fljl_free_position(W *w) { WIN(w)->free_position(); }
API void fljl_make_current(W *w) { WIN(w)->make_current(); }
API void fljl_window_icon(W *w, Fl_Image *i) { WIN(w)->icon((const Fl_RGB_Image *)i); }
API int fljl_decorated_w(W *w) { return WIN(w)->decorated_w(); }
API int fljl_decorated_h(W *w) { return WIN(w)->decorated_h(); }
API void fljl_wait_for_expose(W *w) { WIN(w)->wait_for_expose(); }

// Fl_Gl_Window
#define GL(w) ((Fl_Gl_Window *)(w))
API void fljl_gl_mode(W *w, int m) { GL(w)->mode(m); }
API int fljl_gl_valid(W *w) { return GL(w)->valid(); }
API void fljl_gl_invalidate(W *w) { GL(w)->invalidate(); }
API int fljl_gl_context_valid(W *w) { return GL(w)->context_valid(); }
API void fljl_gl_swap_buffers(W *w) { GL(w)->swap_buffers(); }
API int fljl_gl_pixel_w(W *w) { return GL(w)->pixel_w(); }
API int fljl_gl_pixel_h(W *w) { return GL(w)->pixel_h(); }
API void fljl_gl_make_current(W *w) { GL(w)->make_current(); }

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------
#define BTN(w) ((Fl_Button *)(w))
API int fljl_button_value(W *w) { return BTN(w)->value(); }
API void fljl_button_set_value(W *w, int v) { BTN(w)->value(v); }
API void fljl_button_setonly(W *w) { BTN(w)->setonly(); }
API int fljl_button_shortcut(W *w) { return BTN(w)->shortcut(); }
API void fljl_button_set_shortcut(W *w, int s) { BTN(w)->shortcut(s); }
API void fljl_button_set_down_box(W *w, int b) { BTN(w)->down_box((Fl_Boxtype)b); }
API int fljl_button_compact(W *w) { return BTN(w)->compact(); }
API void fljl_button_set_compact(W *w, int v) { BTN(w)->compact((uchar)v); }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------
#define INP(w) ((Fl_Input_ *)(w))
API const char *fljl_input_value(W *w) { return INP(w)->value(); }
API void fljl_input_set_value(W *w, const char *v) { INP(w)->value(v); }
API int fljl_input_size(W *w) { return INP(w)->size(); }
API int fljl_input_maximum_size(W *w) { return INP(w)->maximum_size(); }
API void fljl_input_set_maximum_size(W *w, int m) { INP(w)->maximum_size(m); }
API int fljl_input_insert_position(W *w) { return INP(w)->insert_position(); }
API int fljl_input_mark(W *w) { return INP(w)->mark(); }
API void fljl_input_set_position(W *w, int p, int m) { INP(w)->insert_position(p, m); }
API int fljl_input_insert(W *w, const char *t) { return INP(w)->insert(t); }
API int fljl_input_cut(W *w, int a, int b) { return INP(w)->cut(a, b); }
API int fljl_input_textfont(W *w) { return INP(w)->textfont(); }
API void fljl_input_set_textfont(W *w, int f) { INP(w)->textfont(f); }
API int fljl_input_textsize(W *w) { return INP(w)->textsize(); }
API void fljl_input_set_textsize(W *w, int s) { INP(w)->textsize(s); }
API unsigned fljl_input_textcolor(W *w) { return INP(w)->textcolor(); }
API void fljl_input_set_textcolor(W *w, unsigned c) { INP(w)->textcolor(c); }
API int fljl_input_readonly(W *w) { return INP(w)->readonly(); }
API void fljl_input_set_readonly(W *w, int r) { INP(w)->readonly(r); }
API void fljl_input_set_wrap(W *w, int r) { INP(w)->wrap(r); }
API int fljl_input_shortcut(W *w) { return INP(w)->shortcut(); }
API void fljl_input_set_shortcut(W *w, int s) { INP(w)->shortcut(s); }
API int fljl_input_tab_nav(W *w) { return INP(w)->tab_nav(); }
API void fljl_input_set_tab_nav(W *w, int v) { INP(w)->tab_nav(v); }

// ---------------------------------------------------------------------------
// Valuators (sliders, dials, counters, rollers, value input/output ...)
// ---------------------------------------------------------------------------
#define VAL(w) ((Fl_Valuator *)(w))
API double fljl_valuator_value(W *w) { return VAL(w)->value(); }
API int fljl_valuator_set_value(W *w, double v) { return VAL(w)->value(v); }
API double fljl_valuator_minimum(W *w) { return VAL(w)->minimum(); }
API void fljl_valuator_set_minimum(W *w, double v) { VAL(w)->minimum(v); }
API double fljl_valuator_maximum(W *w) { return VAL(w)->maximum(); }
API void fljl_valuator_set_maximum(W *w, double v) { VAL(w)->maximum(v); }
API double fljl_valuator_step(W *w) { return VAL(w)->step(); }
API void fljl_valuator_set_step(W *w, double v) { VAL(w)->step(v); }
API void fljl_valuator_precision(W *w, int p) { VAL(w)->precision(p); }
API double fljl_valuator_round(W *w, double v) { return VAL(w)->round(v); }
API double fljl_valuator_clamp(W *w, double v) { return VAL(w)->clamp(v); }
API void fljl_valuator_format(W *w, char *buf) { VAL(w)->format(buf); }
API void fljl_slider_size(W *w, double v) { ((Fl_Slider *)w)->slider_size(v); }
API void fljl_slider_set_box(W *w, int b) { ((Fl_Slider *)w)->slider((Fl_Boxtype)b); }
API void fljl_value_slider_textsize(W *w, int s) { ((Fl_Value_Slider *)w)->textsize(s); }
API void fljl_counter_lstep(W *w, double s) { ((Fl_Counter *)w)->lstep(s); }
API void fljl_dial_angles(W *w, int a, int b) { ((Fl_Dial *)w)->angles(a, b); }
API void fljl_scrollbar_linesize(W *w, int s) { ((Fl_Scrollbar *)w)->linesize(s); }

// Fl_Spinner (an Fl_Group, not an Fl_Valuator)
#define SPN(w) ((Fl_Spinner *)(w))
API double fljl_spinner_value(W *w) { return SPN(w)->value(); }
API void fljl_spinner_set_value(W *w, double v) { SPN(w)->value(v); }
API double fljl_spinner_minimum(W *w) { return SPN(w)->minimum(); }
API void fljl_spinner_set_minimum(W *w, double v) { SPN(w)->minimum(v); }
API double fljl_spinner_maximum(W *w) { return SPN(w)->maximum(); }
API void fljl_spinner_set_maximum(W *w, double v) { SPN(w)->maximum(v); }
API double fljl_spinner_step(W *w) { return SPN(w)->step(); }
API void fljl_spinner_set_step(W *w, double v) { SPN(w)->step(v); }
API void fljl_spinner_set_type(W *w, int t) { SPN(w)->type((uchar)t); }
API void fljl_spinner_set_format(W *w, const char *f) {
  if (auto b = jlb(w)) { b->strbuf = f; SPN(w)->format(b->strbuf.c_str()); }
}
API void fljl_spinner_textsize(W *w, int s) { SPN(w)->textsize(s); }

// Fl_Progress
#define PRG(w) ((Fl_Progress *)(w))
API double fljl_progress_value(W *w) { return PRG(w)->value(); }
API void fljl_progress_set_value(W *w, double v) { PRG(w)->value((float)v); }
API double fljl_progress_minimum(W *w) { return PRG(w)->minimum(); }
API void fljl_progress_set_minimum(W *w, double v) { PRG(w)->minimum((float)v); }
API double fljl_progress_maximum(W *w) { return PRG(w)->maximum(); }
API void fljl_progress_set_maximum(W *w, double v) { PRG(w)->maximum((float)v); }

// ---------------------------------------------------------------------------
// Menus (Fl_Menu_Bar, Fl_Menu_Button, Fl_Choice)
// ---------------------------------------------------------------------------
#define MNU(w) ((Fl_Menu_ *)(w))
// id == 0 means "no per-item callback": the widget's own callback runs instead.
API int fljl_menu_add(W *w, const char *label, int shortcut, intptr_t id, int flags) {
  return MNU(w)->add(label, shortcut, id ? menu_tramp : nullptr, (void *)id, flags);
}
API int fljl_menu_insert(W *w, int idx, const char *label, int shortcut, intptr_t id, int flags) {
  return MNU(w)->insert(idx, label, shortcut, id ? menu_tramp : nullptr, (void *)id, flags);
}
API int fljl_menu_value(W *w) { return MNU(w)->value(); }
API int fljl_menu_set_value(W *w, int i) { return MNU(w)->value(i); }
API const char *fljl_menu_text(W *w) { return MNU(w)->text(); }
// valid item index (FLTK does not check indices itself)
static bool menu_ok(W *w, int i) { return MNU(w)->menu() && i >= 0 && i < MNU(w)->size() - 1; }
API const char *fljl_menu_text_at(W *w, int i) { return menu_ok(w, i) ? MNU(w)->text(i) : nullptr; }
API int fljl_menu_size(W *w) { return MNU(w)->size(); }
API void fljl_menu_clear(W *w) { MNU(w)->clear(); }
API void fljl_menu_remove(W *w, int i) { if (menu_ok(w, i)) MNU(w)->remove(i); }
API void fljl_menu_replace(W *w, int i, const char *t) { if (menu_ok(w, i)) MNU(w)->replace(i, t); }
API int fljl_menu_find_index(W *w, const char *path) { return MNU(w)->find_index(path); }
API int fljl_menu_mode(W *w, int i) { return menu_ok(w, i) ? MNU(w)->mode(i) : 0; }
API void fljl_menu_set_mode(W *w, int i, int f) { if (menu_ok(w, i)) MNU(w)->mode(i, f); }
API int fljl_menu_picked(W *w, int i) {
  if (!menu_ok(w, i)) return 0;
  MNU(w)->picked(&MNU(w)->menu()[i]);
  return 1;
}
API int fljl_menu_item_value(W *w, int i) {
  const Fl_Menu_Item *m = MNU(w)->menu();
  return (m && i >= 0 && i < MNU(w)->size()) ? m[i].value() : 0;
}
API void fljl_menu_item_set_value(W *w, int i, int v) {
  const Fl_Menu_Item *m = MNU(w)->menu();
  if (!m || i < 0 || i >= MNU(w)->size()) return;
  Fl_Menu_Item *it = (Fl_Menu_Item *)&m[i];
  if (v) it->set(); else it->clear();
}
API int fljl_menu_mvalue_index(W *w) {
  const Fl_Menu_Item *mv = MNU(w)->mvalue();
  const Fl_Menu_Item *m = MNU(w)->menu();
  return (mv && m) ? (int)(mv - m) : -1;
}
API int fljl_menu_item_pathname(W *w, char *buf, int n, int i) {
  const Fl_Menu_Item *m = MNU(w)->menu();
  if (!m || i < 0 || i >= MNU(w)->size()) return -1;
  return MNU(w)->item_pathname(buf, n, &m[i]);
}
API void fljl_menu_textsize(W *w, int s) { MNU(w)->textsize(s); }
API void fljl_menu_textfont(W *w, int f) { MNU(w)->textfont(f); }
API void fljl_menu_down_box(W *w, int b) { MNU(w)->down_box((Fl_Boxtype)b); }
API int fljl_menu_button_popup(W *w) {
  const Fl_Menu_Item *it = ((Fl_Menu_Button *)w)->popup();
  const Fl_Menu_Item *m = MNU(w)->menu();
  return (it && m) ? (int)(it - m) : -1;
}

// ---------------------------------------------------------------------------
// Browsers
// ---------------------------------------------------------------------------
#define BRW(w) ((Fl_Browser *)(w))
API void fljl_browser_add(W *w, const char *t) { BRW(w)->add(t); }
API void fljl_browser_insert(W *w, int line, const char *t) { BRW(w)->insert(line, t); }
API void fljl_browser_remove(W *w, int line) { BRW(w)->remove(line); }
API void fljl_browser_clear(W *w) { BRW(w)->clear(); }
API int fljl_browser_size(W *w) { return BRW(w)->size(); }
API int fljl_browser_value(W *w) { return BRW(w)->value(); }
API void fljl_browser_set_value(W *w, int v) { BRW(w)->value(v); }
API const char *fljl_browser_text(W *w, int line) { return BRW(w)->text(line); }
API void fljl_browser_set_text(W *w, int line, const char *t) { BRW(w)->text(line, t); }
API int fljl_browser_select(W *w, int line, int v) { return BRW(w)->select(line, v); }
API int fljl_browser_selected(W *w, int line) { return BRW(w)->selected(line); }
API void fljl_browser_topline(W *w, int line) { BRW(w)->topline(line); }
API void fljl_browser_bottomline(W *w, int line) { BRW(w)->bottomline(line); }
API void fljl_browser_column_char(W *w, char c) { BRW(w)->column_char(c); }
API void fljl_browser_format_char(W *w, char c) { BRW(w)->format_char(c); }
API void fljl_browser_column_widths(W *w, const int *ws, int n) {
  if (auto b = jlb(w)) {
    b->colw.assign(ws, ws + n);
    b->colw.push_back(0);
    BRW(w)->column_widths(b->colw.data());
  }
}
API int fljl_browser_load(W *w, const char *f) { return BRW(w)->load(f); }
API void fljl_browser_textsize(W *w, int s) { BRW(w)->textsize(s); }
API void fljl_browser_textfont(W *w, int f) { BRW(w)->textfont(f); }

#define CBR(w) ((Fl_Check_Browser *)(w))
API int fljl_check_browser_add(W *w, const char *t, int on) { return CBR(w)->add(t, on); }
API int fljl_check_browser_nitems(W *w) { return CBR(w)->nitems(); }
API int fljl_check_browser_nchecked(W *w) { return CBR(w)->nchecked(); }
API int fljl_check_browser_checked(W *w, int i) { return CBR(w)->checked(i); }
API void fljl_check_browser_set_checked(W *w, int i, int v) { CBR(w)->checked(i, v); }
API void fljl_check_browser_check_all(W *w, int on) { if (on) CBR(w)->check_all(); else CBR(w)->check_none(); }
API void fljl_check_browser_clear(W *w) { CBR(w)->clear(); }
API const char *fljl_check_browser_text(W *w, int i) { return CBR(w)->text(i); }
API int fljl_check_browser_value(W *w) { return CBR(w)->value(); }

// ---------------------------------------------------------------------------
// Containers
// ---------------------------------------------------------------------------
API W *fljl_tabs_value(W *w) { return ((Fl_Tabs *)w)->value(); }
API void fljl_tabs_set_value(W *w, W *c) { ((Fl_Tabs *)w)->value(c); }
API W *fljl_wizard_value(W *w) { return ((Fl_Wizard *)w)->value(); }
API void fljl_wizard_set_value(W *w, W *c) { ((Fl_Wizard *)w)->value(c); }
API void fljl_wizard_next(W *w) { ((Fl_Wizard *)w)->next(); }
API void fljl_wizard_prev(W *w) { ((Fl_Wizard *)w)->prev(); }
API void fljl_scroll_to(W *w, int x, int y) { ((Fl_Scroll *)w)->scroll_to(x, y); }
API W *fljl_scroll_scrollbar(W *w) { return &((Fl_Scroll *)w)->scrollbar; }
API W *fljl_scroll_hscrollbar(W *w) { return &((Fl_Scroll *)w)->hscrollbar; }
API void fljl_tile_init_size_range(W *w, int minw, int minh) { ((Fl_Tile *)w)->init_size_range(minw, minh); }
API void fljl_tile_size_range(W *w, W *c, int minw, int minh, int maxw, int maxh) {
  ((Fl_Tile *)w)->size_range(c, minw, minh, maxw, maxh);
}
API int fljl_scroll_xposition(W *w) { return ((Fl_Scroll *)w)->xposition(); }
API int fljl_scroll_yposition(W *w) { return ((Fl_Scroll *)w)->yposition(); }
API void fljl_pack_spacing(W *w, int s) { ((Fl_Pack *)w)->spacing(s); }
API void fljl_flex_set_type(W *w, int t) { ((Fl_Flex *)w)->type(t); }
API void fljl_flex_fixed(W *w, W *c, int s) { ((Fl_Flex *)w)->fixed(c, s); }
API void fljl_flex_margin(W *w, int l, int t, int r, int b) { ((Fl_Flex *)w)->margin(l, t, r, b); }
API void fljl_flex_gap(W *w, int g) { ((Fl_Flex *)w)->gap(g); }
API void fljl_flex_layout(W *w) { ((Fl_Flex *)w)->layout(); }
#define GRD(w) ((Fl_Grid *)(w))
API void fljl_grid_layout(W *w, int rows, int cols, int margin, int gap) { GRD(w)->layout(rows, cols, margin, gap); }
API void fljl_grid_relayout(W *w) { GRD(w)->layout(); }
API void fljl_grid_widget(W *w, W *c, int r, int col, int rs, int cs, int align) {
  GRD(w)->widget(c, r, col, rs, cs, (Fl_Grid_Align)align);
}
API void fljl_grid_margin(W *w, int l, int t, int r, int b) { GRD(w)->margin(l, t, r, b); }
API void fljl_grid_gap(W *w, int rg, int cg) { GRD(w)->gap(rg, cg); }
API void fljl_grid_col_width(W *w, int c, int v) { GRD(w)->col_width(c, v); }
API void fljl_grid_col_weight(W *w, int c, int v) { GRD(w)->col_weight(c, v); }
API void fljl_grid_col_gap(W *w, int c, int v) { GRD(w)->col_gap(c, v); }
API void fljl_grid_row_height(W *w, int r, int v) { GRD(w)->row_height(r, v); }
API void fljl_grid_row_weight(W *w, int r, int v) { GRD(w)->row_weight(r, v); }
API void fljl_grid_row_gap(W *w, int r, int v) { GRD(w)->row_gap(r, v); }
API void fljl_grid_show_grid(W *w, int on) { GRD(w)->show_grid(on); }

// ---------------------------------------------------------------------------
// Text buffer / display / editor
// ---------------------------------------------------------------------------
API Fl_Text_Buffer *fljl_textbuffer_new() { return new Fl_Text_Buffer(); }
API void fljl_textbuffer_delete(Fl_Text_Buffer *b) { delete b; }
API char *fljl_textbuffer_text(Fl_Text_Buffer *b) { return b->text(); }  // free with fljl_free
API void fljl_textbuffer_set_text(Fl_Text_Buffer *b, const char *t) { b->text(t); }
API void fljl_textbuffer_append(Fl_Text_Buffer *b, const char *t) { b->append(t); }
API void fljl_textbuffer_insert(Fl_Text_Buffer *b, int p, const char *t) { b->insert(p, t); }
API void fljl_textbuffer_remove(Fl_Text_Buffer *b, int s, int e) { b->remove(s, e); }
API int fljl_textbuffer_length(Fl_Text_Buffer *b) { return b->length(); }
API int fljl_textbuffer_loadfile(Fl_Text_Buffer *b, const char *f) { return b->loadfile(f); }
API int fljl_textbuffer_savefile(Fl_Text_Buffer *b, const char *f) { return b->savefile(f); }
API void fljl_textbuffer_select(Fl_Text_Buffer *b, int s, int e) { b->select(s, e); }
API int fljl_textbuffer_selected(Fl_Text_Buffer *b) { return b->selected(); }
API char *fljl_textbuffer_selection_text(Fl_Text_Buffer *b) { return b->selection_text(); }
API int fljl_textbuffer_search_forward(Fl_Text_Buffer *b, int start, const char *s, int matchcase) {
  int found = -1;
  return b->search_forward(start, s, &found, matchcase) ? found : -1;
}
API int fljl_textbuffer_count_lines(Fl_Text_Buffer *b, int s, int e) { return b->count_lines(s, e); }
API void fljl_textbuffer_undo(Fl_Text_Buffer *b) { int p; b->undo(&p); }
API void fljl_free(void *p) { free(p); }

#define TXD(w) ((Fl_Text_Display *)(w))
API void fljl_textdisplay_buffer(W *w, Fl_Text_Buffer *b) { TXD(w)->buffer(b); }
API void fljl_textdisplay_textfont(W *w, int f) { TXD(w)->textfont(f); }
API void fljl_textdisplay_textsize(W *w, int s) { TXD(w)->textsize(s); }
API void fljl_textdisplay_textcolor(W *w, unsigned c) { TXD(w)->textcolor(c); }
API void fljl_textdisplay_wrap_mode(W *w, int m, int margin) { TXD(w)->wrap_mode(m, margin); }
API void fljl_textdisplay_linenumber_width(W *w, int n) { TXD(w)->linenumber_width(n); }
API int fljl_textdisplay_insert_position(W *w) { return TXD(w)->insert_position(); }
API void fljl_textdisplay_set_insert_position(W *w, int p) { TXD(w)->insert_position(p); }
API void fljl_textdisplay_show_insert_position(W *w) { TXD(w)->show_insert_position(); }
API void fljl_textdisplay_scroll(W *w, int line, int col) { TXD(w)->scroll(line, col); }
API void fljl_textdisplay_insert(W *w, const char *t) { TXD(w)->insert(t); }

// Fl_Terminal
API void fljl_terminal_append(W *w, const char *t) { ((Fl_Terminal *)w)->append(t); }
API void fljl_terminal_clear(W *w) { ((Fl_Terminal *)w)->clear(); }
API void fljl_terminal_textsize(W *w, int s) { ((Fl_Terminal *)w)->textsize(s); }
API void fljl_terminal_textfgcolor(W *w, unsigned c) { ((Fl_Terminal *)w)->textfgcolor(c); }
API void fljl_terminal_textbgcolor(W *w, unsigned c) { ((Fl_Terminal *)w)->textbgcolor(c); }

// Fl_Tree (path-based API)
#define TRE(w) ((Fl_Tree *)(w))
API int fljl_tree_add(W *w, const char *p) { return TRE(w)->add(p) != nullptr; }
API int fljl_tree_remove(W *w, const char *p) {
  Fl_Tree_Item *it = TRE(w)->find_item(p);
  return it ? TRE(w)->remove(it) : -1;
}
API void fljl_tree_clear(W *w) { TRE(w)->clear(); }
API void fljl_tree_showroot(W *w, int on) { TRE(w)->showroot(on); }
API void fljl_tree_root_label(W *w, const char *l) { TRE(w)->root_label(l); }
API int fljl_tree_open(W *w, const char *p, int open) { return open ? TRE(w)->open(p, 0) : TRE(w)->close(p, 0); }
API int fljl_tree_select(W *w, const char *p, int sel) { return sel ? TRE(w)->select(p, 0) : TRE(w)->deselect(p, 0); }
API int fljl_tree_callback_reason(W *w) { return TRE(w)->callback_reason(); }
API void *fljl_tree_callback_item(W *w) { return TRE(w)->callback_item(); }
API void *fljl_tree_first_selected(W *w) { return TRE(w)->first_selected_item(); }
API void *fljl_tree_next_selected(W *w, void *it) { return TRE(w)->next_selected_item((Fl_Tree_Item *)it); }
API int fljl_tree_item_pathname(W *w, void *it, char *buf, int n) {
  return it ? TRE(w)->item_pathname(buf, n, (Fl_Tree_Item *)it) : -1;
}
API const char *fljl_tree_item_label(void *it) { return it ? ((Fl_Tree_Item *)it)->label() : nullptr; }

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------
API void fljl_register_images() { fl_register_images(); }
API Fl_Image *fljl_shared_image_get(const char *f, int w, int h) {
  Fl_Shared_Image *i = Fl_Shared_Image::get(f, w, h);
  if (i && i->fail()) { i->release(); return nullptr; }
  return i;
}
API Fl_Image *fljl_rgb_image_new(const unsigned char *data, int w, int h, int d) {
  size_t n = (size_t)w * h * d;
  unsigned char *copy = new unsigned char[n];
  memcpy(copy, data, n);
  Fl_RGB_Image *img = new Fl_RGB_Image(copy, w, h, d);
  img->alloc_array = 1;
  return img;
}
API void fljl_image_delete(Fl_Image *i) {
  if (!i) return;
  if (auto s = dynamic_cast<Fl_Shared_Image *>(i)) s->release();
  else delete i;
}
API int fljl_image_w(Fl_Image *i) { return i->w(); }
API int fljl_image_h(Fl_Image *i) { return i->h(); }
API int fljl_image_d(Fl_Image *i) { return i->d(); }
API void fljl_image_draw(Fl_Image *i, int x, int y) { i->draw(x, y); }
API void fljl_image_draw_box(Fl_Image *i, int x, int y, int w, int h, int cx, int cy) { i->draw(x, y, w, h, cx, cy); }
API void fljl_image_scale(Fl_Image *i, int w, int h, int prop, int expand) { i->scale(w, h, prop, expand); }
API Fl_Image *fljl_image_copy(Fl_Image *i, int w, int h) { return i->copy(w, h); }

// ---------------------------------------------------------------------------
// Application / event loop
// ---------------------------------------------------------------------------
API int fljl_run() { return Fl::run(); }
API int fljl_wait(double t) { return (int)Fl::wait(t); }
API int fljl_check() { return Fl::check(); }
API int fljl_ready() { return Fl::ready(); }
API void fljl_flush() { Fl::flush(); }
API void fljl_redraw_all() { Fl::redraw(); }
API W *fljl_first_window() { return Fl::first_window(); }
API W *fljl_next_window(W *w) { return Fl::next_window(WIN(w)); }
API W *fljl_modal_window() { return Fl::modal(); }
API void fljl_scheme(const char *s) { Fl::scheme(s); }
API const char *fljl_get_scheme() { return Fl::scheme(); }
API int fljl_visual(int m) { return Fl::visual(m); }
API void fljl_add_timeout(double t, intptr_t id) { Fl::add_timeout(t, timeout_tramp, (void *)id); }
API void fljl_repeat_timeout(double t, intptr_t id) { Fl::repeat_timeout(t, timeout_tramp, (void *)id); }
API void fljl_remove_timeout(intptr_t id) { Fl::remove_timeout(timeout_tramp, (void *)id); }
API int fljl_has_timeout(intptr_t id) { return Fl::has_timeout(timeout_tramp, (void *)id); }
API int fljl_api_version() { return Fl::api_version(); }
API int fljl_abi_version() { return Fl::abi_version(); }
API void fljl_lock() { Fl::lock(); }
API void fljl_unlock() { Fl::unlock(); }
API void fljl_awake() { Fl::awake(); }

// Events
API int fljl_event() { return Fl::event(); }
API int fljl_event_x() { return Fl::event_x(); }
API int fljl_event_y() { return Fl::event_y(); }
API int fljl_event_x_root() { return Fl::event_x_root(); }
API int fljl_event_y_root() { return Fl::event_y_root(); }
API int fljl_event_dx() { return Fl::event_dx(); }
API int fljl_event_dy() { return Fl::event_dy(); }
API int fljl_event_key() { return Fl::event_key(); }
API int fljl_event_button() { return Fl::event_button(); }
API int fljl_event_clicks() { return Fl::event_clicks(); }
API int fljl_event_is_click() { return Fl::event_is_click(); }
API int fljl_event_state() { return Fl::event_state(); }
API const char *fljl_event_text() { return Fl::event_text(); }
API int fljl_event_length() { return Fl::event_length(); }
API int fljl_event_inside(int x, int y, int w, int h) { return Fl::event_inside(x, y, w, h); }
API int fljl_event_inside_widget(W *w) { return Fl::event_inside(w); }
API int fljl_get_key(int k) { return Fl::get_key(k); }
API void fljl_get_mouse(int *x, int *y) { Fl::get_mouse(*x, *y); }
API W *fljl_focus() { return Fl::focus(); }
API void fljl_set_focus(W *w) { Fl::focus(w); }
API W *fljl_belowmouse() { return Fl::belowmouse(); }
API W *fljl_pushed() { return Fl::pushed(); }
API void fljl_copy(const char *t, int len, int dest) { Fl::copy(t, len, dest); }

// Screens
API int fljl_screen_count() { return Fl::screen_count(); }
API void fljl_screen_xywh(int *x, int *y, int *w, int *h, int n) { Fl::screen_xywh(*x, *y, *w, *h, n); }
API double fljl_screen_scale(int n) { return Fl::screen_scale(n); }
API int fljl_window_screen_num(W *w) { return ((Fl_Window *)w)->screen_num(); }
API const char *fljl_eventname(int e) { return (e >= 0 && e < (int)(sizeof(fl_eventnames) / sizeof(*fl_eventnames))) ? fl_eventnames[e] : "?"; }
API int fljl_box_dx(int b) { return Fl::box_dx((Fl_Boxtype)b); }
API int fljl_box_dy(int b) { return Fl::box_dy((Fl_Boxtype)b); }
API int fljl_box_dw(int b) { return Fl::box_dw((Fl_Boxtype)b); }
API int fljl_box_dh(int b) { return Fl::box_dh((Fl_Boxtype)b); }
API void fljl_set_screen_scale(int n, double f) { Fl::screen_scale(n, (float)f); }
API int fljl_screen_w() { return Fl::w(); }
API int fljl_screen_h() { return Fl::h(); }

// Colors / fonts / global options
API void fljl_set_color_rgb(unsigned i, int r, int g, int b) { Fl::set_color(i, r, g, b); }
API void fljl_get_color_rgb(unsigned i, unsigned char *r, unsigned char *g, unsigned char *b) { Fl::get_color(i, *r, *g, *b); }
API void fljl_background(int r, int g, int b) { Fl::background(r, g, b); }
API void fljl_background2(int r, int g, int b) { Fl::background2(r, g, b); }
API void fljl_foreground(int r, int g, int b) { Fl::foreground(r, g, b); }
API void fljl_get_system_colors() { Fl::get_system_colors(); }
API unsigned fljl_color_average(unsigned a, unsigned b, double w) { return fl_color_average(a, b, (float)w); }
API unsigned fljl_lighter(unsigned c) { return fl_lighter(c); }
API unsigned fljl_darker(unsigned c) { return fl_darker(c); }
API unsigned fljl_contrast(unsigned a, unsigned b) { return fl_contrast(a, b); }
API unsigned fljl_inactive(unsigned c) { return fl_inactive(c); }
API void fljl_set_font(int i, const char *name) { Fl::set_font((Fl_Font)i, strdup(name)); }
API int fljl_set_fonts(const char *xstarname) { return Fl::set_fonts(xstarname); }
API const char *fljl_get_font_name(int i) { return Fl::get_font_name((Fl_Font)i); }
API int fljl_scrollbar_size() { return Fl::scrollbar_size(); }
API void fljl_set_scrollbar_size(int s) { Fl::scrollbar_size(s); }
API void fljl_visible_focus(int on) { Fl::visible_focus(on); }
API void fljl_option(int opt, int val) { Fl::option((Fl::Fl_Option)opt, val != 0); }
API int fljl_get_option(int opt) { return Fl::option((Fl::Fl_Option)opt); }
API int fljl_normal_size() { return FL_NORMAL_SIZE; }
API void fljl_set_normal_size(int s) { FL_NORMAL_SIZE = s; }

// ---------------------------------------------------------------------------
// Drawing (valid inside draw callbacks, or after window->make_current())
// ---------------------------------------------------------------------------
API void fljl_draw_color(unsigned c) { fl_color(c); }
API void fljl_draw_color_rgb(int r, int g, int b) { fl_color((uchar)r, (uchar)g, (uchar)b); }
API unsigned fljl_draw_get_color() { return fl_color(); }
API void fljl_push_clip(int x, int y, int w, int h) { fl_push_clip(x, y, w, h); }
API void fljl_push_no_clip() { fl_push_no_clip(); }
API void fljl_pop_clip() { fl_pop_clip(); }
API int fljl_not_clipped(int x, int y, int w, int h) { return fl_not_clipped(x, y, w, h); }
API void fljl_point(int x, int y) { fl_point(x, y); }
API void fljl_line_style(int s, int w) { fl_line_style(s, w); }
API void fljl_rect(int x, int y, int w, int h) { fl_rect(x, y, w, h); }
API void fljl_rectf(int x, int y, int w, int h) { fl_rectf(x, y, w, h); }
API void fljl_rounded_rect(int x, int y, int w, int h, int r) { fl_rounded_rect(x, y, w, h, r); }
API void fljl_rounded_rectf(int x, int y, int w, int h, int r) { fl_rounded_rectf(x, y, w, h, r); }
API void fljl_line(int x, int y, int x1, int y1) { fl_line(x, y, x1, y1); }
API void fljl_xyline(int x, int y, int x1) { fl_xyline(x, y, x1); }
API void fljl_yxline(int x, int y, int y1) { fl_yxline(x, y, y1); }
API void fljl_loop3(int a, int b, int c, int d, int e, int f) { fl_loop(a, b, c, d, e, f); }
API void fljl_polygon3(int a, int b, int c, int d, int e, int f) { fl_polygon(a, b, c, d, e, f); }
API void fljl_arc_i(int x, int y, int w, int h, double a1, double a2) { fl_arc(x, y, w, h, a1, a2); }
API void fljl_pie(int x, int y, int w, int h, double a1, double a2) { fl_pie(x, y, w, h, a1, a2); }
API void fljl_push_matrix() { fl_push_matrix(); }
API void fljl_pop_matrix() { fl_pop_matrix(); }
API void fljl_scale(double x, double y) { fl_scale(x, y); }
API void fljl_translate(double x, double y) { fl_translate(x, y); }
API void fljl_rotate(double d) { fl_rotate(d); }
API void fljl_begin_points() { fl_begin_points(); }
API void fljl_begin_line() { fl_begin_line(); }
API void fljl_begin_loop() { fl_begin_loop(); }
API void fljl_begin_polygon() { fl_begin_polygon(); }
API void fljl_begin_complex_polygon() { fl_begin_complex_polygon(); }
API void fljl_gap() { fl_gap(); }
API void fljl_vertex(double x, double y) { fl_vertex(x, y); }
API void fljl_vertices(const double *xy, int n) { for (int i = 0; i < n; i++) fl_vertex(xy[2 * i], xy[2 * i + 1]); }
API void fljl_curve(double a, double b, double c, double d, double e, double f, double g, double h) { fl_curve(a, b, c, d, e, f, g, h); }
API void fljl_arc_d(double x, double y, double r, double s, double e) { fl_arc(x, y, r, s, e); }
API void fljl_circle(double x, double y, double r) { fl_circle(x, y, r); }
API void fljl_end_points() { fl_end_points(); }
API void fljl_end_line() { fl_end_line(); }
API void fljl_end_loop() { fl_end_loop(); }
API void fljl_end_polygon() { fl_end_polygon(); }
API void fljl_end_complex_polygon() { fl_end_complex_polygon(); }
API void fljl_font(int f, int s) { fl_font((Fl_Font)f, (Fl_Fontsize)s); }
API int fljl_get_font() { return fl_font(); }
API int fljl_size() { return fl_size(); }
API int fljl_height() { return fl_height(); }
API int fljl_descent() { return fl_descent(); }
API double fljl_width(const char *s) { return fl_width(s); }
API void fljl_text_extents(const char *s, int *dx, int *dy, int *w, int *h) { fl_text_extents(s, *dx, *dy, *w, *h); }
API void fljl_draw_text(const char *s, int x, int y) { fl_draw(s, x, y); }
API void fljl_draw_text_angle(int angle, const char *s, int x, int y) { fl_draw(angle, s, x, y); }
API void fljl_draw_text_box(const char *s, int x, int y, int w, int h, unsigned align) { fl_draw(s, x, y, w, h, (Fl_Align)align); }
API void fljl_measure(const char *s, int *w, int *h, int sym) { fl_measure(s, *w, *h, sym); }
API void fljl_draw_box(int b, int x, int y, int w, int h, unsigned c) { fl_draw_box((Fl_Boxtype)b, x, y, w, h, c); }
API int fljl_draw_symbol(const char *s, int x, int y, int w, int h, unsigned c) { return fl_draw_symbol(s, x, y, w, h, c); }
API void fljl_draw_image(const unsigned char *buf, int x, int y, int w, int h, int d, int ld) { fl_draw_image(buf, x, y, w, h, d, ld); }
API void fljl_draw_image_mono(const unsigned char *buf, int x, int y, int w, int h, int d, int ld) { fl_draw_image_mono(buf, x, y, w, h, d, ld); }

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------
API void fljl_message(const char *m) { fl_message("%s", m); }
API void fljl_alert(const char *m) { fl_alert("%s", m); }
API int fljl_choice(const char *q, const char *b0, const char *b1, const char *b2) { return fl_choice("%s", b0, b1, b2, q); }
API const char *fljl_input_dialog(const char *l, const char *def) { return fl_input("%s", def, l); }
API const char *fljl_password_dialog(const char *l, const char *def) { return fl_password("%s", def, l); }
API void fljl_message_title(const char *t) { fl_message_title(t); }
API void fljl_message_title_default(const char *t) { fl_message_title_default(t); }
API void fljl_beep(int t) { fl_beep(t); }
API int fljl_open_uri(const char *u) { return fl_open_uri(u); }
API const char *fljl_file_chooser(const char *msg, const char *pat, const char *fname, int rel) { return fl_file_chooser(msg, pat, fname, rel); }
API const char *fljl_dir_chooser(const char *msg, const char *fname, int rel) { return fl_dir_chooser(msg, fname, rel); }
API unsigned fljl_show_colormap(unsigned c) { return fl_show_colormap((Fl_Color)c); }
API int fljl_color_chooser(const char *name, unsigned char *r, unsigned char *g, unsigned char *b, int mode) {
  return fl_color_chooser(name, *r, *g, *b, mode);
}

API Fl_Native_File_Chooser *fljl_nfc_new(int type) { return new Fl_Native_File_Chooser(type); }
API void fljl_nfc_delete(Fl_Native_File_Chooser *c) { delete c; }
API void fljl_nfc_title(Fl_Native_File_Chooser *c, const char *t) { c->title(t); }
API void fljl_nfc_filter(Fl_Native_File_Chooser *c, const char *t) { c->filter(t); }
API void fljl_nfc_directory(Fl_Native_File_Chooser *c, const char *t) { c->directory(t); }
API void fljl_nfc_preset_file(Fl_Native_File_Chooser *c, const char *t) { c->preset_file(t); }
API void fljl_nfc_options(Fl_Native_File_Chooser *c, int o) { c->options(o); }
API int fljl_nfc_show(Fl_Native_File_Chooser *c) { return c->show(); }
API int fljl_nfc_count(Fl_Native_File_Chooser *c) { return c->count(); }
API const char *fljl_nfc_filename(Fl_Native_File_Chooser *c, int i) { return c->filename(i); }
API const char *fljl_nfc_errmsg(Fl_Native_File_Chooser *c) { return c->errmsg(); }
