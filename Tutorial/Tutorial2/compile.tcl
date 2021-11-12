# Include TCL utility scripts
include load_etc.tcl

# Timestamp
date

# Print status
puts "\n\n> Setting up Synthesis Environment . . ."

# Top level design name variable
set DESIGN up_counter

# Set synthesis, mapping, and working directory
set SYN_EFF medium
set MAP_EFF medium
set SYN_PATH "."

# Set PDK Library
set PDKDIR /ubc/ece/data/cmc2/kits/ncsu_pdk/FreePDK15/
set_attribute lib_search_path /ubc/ece/data/cmc2/kits/ncsu_pdk/FreePDK15/NanGate_15nm_OCL_v0.1_2014_06_Apache.A/front_end/timing_power_noise/CCS
set_attribute library {NanGate_15nm_OCL_worst_low_conditional_ccs.lib}

# Read in user Verilog files (add -sv flag for SystemVerilog files)
read_hdl -sv ./in/up_counter.sv

# Elaboration validates the syntax (elaborate top-level model)
elaborate $DESIGN

# Status update
puts "> Reading HDL complete."
puts "> Runtime and memory stats:"
timestat Elaboration

# Show any problems
puts "\n\n> Checking design . . ."
check_design -unresolved

# Read timing constraint and clock definitions
puts "\n\n> Reading timing constraints . . ."
read_sdc ./in/timing.sdc

# Synthesize generic cell
puts "\n\n> Synthesizing to generic cell . . ."
synthesize -to_generic -eff $SYN_EFF
puts "> Done. Runtime and memory stats:"
timestat GENERIC

# Synthesize to gates
puts "\n\n> Synthesizing to gates . . ."
synthesize -to_mapped -eff $MAP_EFF -no_incr
puts "> Done. Runtime and memory stats:"
timestat MAPPED

# Incremental synthesis
puts "\n\n> Running incremental synthesis . . ."
synthesize -to_mapped -eff $MAP_EFF -incr
puts "\n\n> Inserting Tie Hi and Tie Low cells . . ." 
insert_tiehilo_cells
puts "> Done. Runtime and memory stats:"
timestat INCREMENTAL

# Generate report to files
puts "\n\n> Generating reports . . ."
report area > ./out/${DESIGN}_area.rpt
report gates > ./out/${DESIGN}_gates.rpt
report timing > ./out/${DESIGN}_timing.rpt
report power > ./out/${DESIGN}_power.rpt

# Generate output verilog file to be used in Encounter and ModelSim
puts "\n\n> Generating mapped Verilog files . . ."
write_hdl -mapped > ./out/${DESIGN}_map.v

# Generate constraints file to be used in Encounter
puts "\n\n> Generating constraints file . . ."
write_sdc > ./out/${DESIGN}_map.sdc

# Generate delay file to be used in ModelSim
puts "\n\n> Generating delay file . . ."
write_sdf > ./out/${DESIGN}_map.sdf

# Status update
puts "> Synthesize complete. Final runtime and memory:"
timestat FINAL

# Done
puts "\n\n> Exiting . . ."
quit
