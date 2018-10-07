

;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************

function spp_swp_spe_param,reset=reset


common spp_swp_spe_param_com, spe_param_dict

  if keyword_set(reset) then begin
    obj_destroy,spe_param_dict
    spe_param_dict = !null
  endif
  
  if isa(spe_param_dict,'dictionary') eq 0 then begin
    etables = orderedhash()
    spe_param_dict = dictionary()

    spane=1
    ratios = [1.,.3,.1,.1,.001]
    
    etables[1] = spp_swp_spanx_tables([20.,20000.],spfac=ratios[0]   , emode=1, spane=spane)
    etables[2] = spp_swp_spanx_tables([10.,10000.],spfac=ratios[0]   , emode=2, spane=spane)
    etables[3] = spp_swp_spanx_tables([ 5., 5000.],spfac=ratios[0]   , emode=3, spane=spane)
    etables[4] = spp_swp_spanx_tables([ 5.,  500.],spfac=ratios[0]   , emode=4, spane=spane)

    etables[5] = spp_swp_spanx_tables([20.,20000.],spfac=ratios[1]   , emode=5, spane=spane)
    etables[6] = spp_swp_spanx_tables([10.,10000.],spfac=ratios[1]   , emode=6, spane=spane)
    etables[7] = spp_swp_spanx_tables([ 5., 5000.],spfac=ratios[1]   , emode=7, spane=spane)
    etables[8] = spp_swp_spanx_tables([ 5.,  500.],spfac=ratios[1]   , emode=8, spane=spane)

    etables[9] = spp_swp_spanx_tables([20.,20000.],spfac=ratios[2]   , emode=9, spane=spane)
    etables[10] = spp_swp_spanx_tables([10.,10000.],spfac=ratios[2]   , emode=10, spane=spane)
    etables[11] = spp_swp_spanx_tables([ 5., 5000.],spfac=ratios[2]   , emode=11, spane=spane)
    etables[12] = spp_swp_spanx_tables([ 5.,  500.],spfac=ratios[2]   , emode=12, spane=spane)

    etables[13] = spp_swp_spanx_tables([20.,20000.],spfac=ratios[3]   , emode=13, spane=spane)
    etables[14] = spp_swp_spanx_tables([10.,10000.],spfac=ratios[3]   , emode=14, spane=spane)
    etables[15] = spp_swp_spanx_tables([ 5., 5000.],spfac=ratios[3]   , emode=15, spane=spane)
    etables[16] = spp_swp_spanx_tables([ 5.,  500.],spfac=ratios[3]   , emode=16, spane=spane)

    etables[17] = spp_swp_spanx_tables([20.,20000.],spfac=ratios[4]   , emode=17, spane=spane)
    etables[18] = spp_swp_spanx_tables([10.,10000.],spfac=ratios[4]   , emode=18, spane=spane)
    etables[19] = spp_swp_spanx_tables([ 5., 5000.],spfac=ratios[4]   , emode=19, spane=spane)
    etables[20] = spp_swp_spanx_tables([ 5.,  500.],spfac=ratios[4]   , emode=20, spane=spane)

    etables[21] = spp_swp_spanx_tables([ 2., 2000.],spfac=ratios[3]   , emode=21, spane=spane)

    spe_param_dict.etables = etables
    
  endif
  
  return,spe_param_dict
     
END

