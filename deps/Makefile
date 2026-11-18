# Builds the C shim (libfltkjl.so) and regenerates src/constants.jl.
# Override FLTK_CONFIG to point at another FLTK 1.4 build or install, e.g.
#   make FLTK_CONFIG=/usr/local/bin/fltk-config
FLTK_CONFIG ?= ../../build/fltk-config
CXX ?= g++

CXXFLAGS := -std=c++17 -O2 -fPIC -fvisibility=hidden -Wall $(shell $(FLTK_CONFIG) --use-images --use-gl --cxxflags)
# Link only against the shared FLTK libraries; they carry their own deps.
FLTK_LIBDIR := $(patsubst -L%,%,$(firstword $(filter -L%,$(shell $(FLTK_CONFIG) --ldflags))))
LDFLAGS  := -L$(FLTK_LIBDIR) -lfltk_images -lfltk_gl -lfltk -Wl,-rpath,$(abspath $(FLTK_LIBDIR))

LIB := usr/lib/libfltkjl.so
GEN := usr/bin/gen_constants
CONSTANTS := ../src/constants.jl

all: $(LIB) $(CONSTANTS)

$(LIB): fltkjl/fltkjl.cpp
	@mkdir -p usr/lib
	$(CXX) $(CXXFLAGS) -shared -o $@ $< $(LDFLAGS)

$(GEN): fltkjl/gen_constants.cpp
	@mkdir -p usr/bin
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

$(CONSTANTS): $(GEN)
	./$(GEN) > $@

clean:
	rm -rf usr

.PHONY: all clean
