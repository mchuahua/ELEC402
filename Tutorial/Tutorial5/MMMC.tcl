# Pass in variables that where defined in the run.1.tcl script
global PDKDIR 
global SDC_FILE

create_library_set -name lsMax \
   -timing \
    [list  ADDRESS HERE slow_vdd1v0_basicCells.lib]

create_library_set -name lsMin \
   -timing \
    [list ADDRESS HERE fast_vdd1v0_basicCells.lib]

create_rc_corner -name rcWorst\
   -qx_tech_file /CMC/kits/AMSKIT616_GPDK/tech/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch \
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0

create_rc_corner -name rcBest\
   -qx_tech_file /CMC/kits/AMSKIT616_GPDK/tech/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch \
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0

create_delay_corner -name dc_lsMax_rcWorst\
   -library_set lsMax\
   -rc_corner   rcWorst
create_delay_corner -name dc_lsMin_rcBest\
   -library_set lsMin\
   -rc_corner   rcBest

#Change .SDC directory
create_constraint_mode -name cmFunc\
   -sdc_files\
    [list ADDRESS YOUR_mapped.sdc]


create_analysis_view -name av_lsMax_rcWorst_cmFunc -constraint_mode cmFunc -delay_corner dc_lsMax_rcWorst
create_analysis_view -name av_lsMin_rcBest_cmFunc  -constraint_mode cmFunc -delay_corner dc_lsMin_rcBest

set_analysis_view -setup [list av_lsMax_rcWorst_cmFunc] -hold [list av_lsMin_rcBest_cmFunc]
