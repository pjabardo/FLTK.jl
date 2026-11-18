# Julia translation of FLTK's test/message.cxx.
# Original: Copyright 1998-2010 by Bill Spitzak and others.
# FLTK is distributed under the LGPL with exceptions, see https://www.fltk.org/COPYING.php
#
# The fl_* dialogs take a plain string; use Julia interpolation (or
# Printf.@sprintf) instead of the printf-style arguments of the C++ functions.
using FLTK

get_system_colors()

fl_message("Spelling check sucessful, 1002 errors found with $(100 * (15 / 77.0))% confidence")
fl_alert("""Quantum fluctuations in the space-time continuum detected,
         you have 10 seconds to comply.

         "In physics, spacetime is any mathematical model that combines
         space and time into a single construct called the space-time
         continuum. Spacetime is usually interpreted with space being
         three-dimensional and time playing the role of the
         fourth dimension." - Wikipedia""")

println("fl_choice returned ", fl_choice("Do you really want to continue?", "No", "Yes"))
println("fl_choice returned ", fl_choice("Choose one of the following:", "choice0", "choice1", "choice2"))

r = fl_input("Please enter a string for 'testing':", "this is the default value")
println("fl_input returned ", r === nothing ? "NULL" : repr(r))
r = fl_password("Enter somebody's password:")
println("fl_password returned ", r === nothing ? "NULL" : repr(r))
