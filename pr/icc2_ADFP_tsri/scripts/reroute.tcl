get_net -of [get_selection]

remove_routes -detail_route -nets u_DCT_L2_tposemem_Bisted_RF_2P_ADV64x16_RF_2P_ADV64x16_u0_AA_n[5]

#create_routing_blockage -layers M7 -boundary {{{2292.915 382.500} {2296.555 390.900}}} -name_prefix RB_M7

route_eco -nets u_DCT_L2_tposemem_Bisted_RF_2P_ADV64x16_RF_2P_ADV64x16_u0_AA_n[5]

#source ../scripts/create_stdcell_fillers_MVT.tcl

check_routes

#remove_routing_blockages RB_M7*

