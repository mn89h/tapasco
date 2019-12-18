set script_path [ file dirname [ file normalize [ info script ] ] ]

source $script_path/noc_arke_arch_ifc/build_arch_ifc.tcl -notrace
source $script_path/noc_arke_mem_ifc/build_mem_ifc.tcl -notrace
source $script_path/noc_arke_pe_ifc/build_pe_ifc.tcl -notrace
source $script_path/noc_arke_router/build_router.tcl -notrace

BuildArchIfc::build
BuildMemIfc::build
BuildPEIfc::build
BuildRouter::build
