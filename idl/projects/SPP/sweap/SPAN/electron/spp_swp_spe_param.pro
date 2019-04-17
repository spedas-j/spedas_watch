; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-16 01:27:24 -0700 (Tue, 16 Apr 2019) $
; $LastChangedRevision: 27022 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_param.pro $
;



;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************


;usage:
; rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,  ptable=spe.ptable)



;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)



; Usage:
; spe = spp_swp_spe_param(detname = 'SPA',emode = 21,pmode='ENERGY_32')
; fswp = spp_swp_span_sweeps(param = spe)


function spp_swp_spe_deflector_func, defangle   ; this is a temporary location for this function - It should be put in a calibration file
;this converts angles to deflector dacs.
;solve for all possible combinations of deflector DAC and just make a lookup table.
   common spp_swp_spe_deflector_com, par
   
   if ~keyword_set(par) then begin    
      par = polycurve2(coeff = [-1396.73d, 539.083d, 0.802293d, -0.04624d, -0.000163369d, 0.00000319759d],/invert )
   endif
   if  n_params() eq 0 then return, par
   return, func(defangle,p = par)

end

;;----------------------------------------------------------------------
;; Calculate all possible Angle values for each Deflector DAC difference
;; Return these in a structure
function spp_swp_spe_deflut_cal
  par = spp_swp_spe_deflector_func()
  anglerange = findgen(141,start = -70, increment = 1)
  anglerangedefs = spp_swp_spe_deflector_func(anglerange)
;  fit, anglerange, anglerangedefs, param = par, verbose = 1
  diffdefs = findgen('ffff'x * 2 + 1) - 'ffff'x
  guess = diffdefs * 0 + 0.5
  angles = solve(diffdefs, xguess = guess, param = par)
  deflookup = {defdac:  diffdefs, $
                theta:  angles}
  return, deflookup
end






function spp_swp_spe_param, detname = detname, $
                            emode = emode, $
                            pmode = pmode, $
                            param = param, $
                            data_struct = data_struct,  $
;                            status_bits = status_bits, $
                            reset = reset

  ;;------------------------------------------------------
  ;; COMMON BLOCK   - DO NOT CALL THIS COMMON BLOCK EXTERNAL TO THIS ROUTINE!!!!!!!
  common spp_swp_spe_param_com, spe_param_dict  

  if keyword_set(reset) then begin
    if isa(spe_param_dict, 'OBJREF') then  obj_destroy, spe_param_dict
    spe_param_dict = !null
  endif
  
  if ~isa(spe_param_dict, 'dictionary')  then begin
    spe_param_dict = dictionary()
  endif
  
  if ~isa(param,'dictionary') then param = dictionary()
  
  if isa(data_struct) then begin    
    detnum = (ishft(data_struct.apid,-4) and 'F'x) < 8
    detectors = ['?','?','?','?','SWEM','SPC','SPA','SPB','SPI']
    detname = detectors[detnum]

    targeted =  (data_struct.apid and 2 ) ne 0      ; targeted apids have the 2bit set
    emode = ishft(data_struct.mode2,-8) and 'ff'x

    pmodes = hash(16,'16A',32,'32E',4096,'16Ax8Dx32E')         ; product_size: product_name
    pmode = pmodes[data_struct.datasize]

    sweep_index = targeted ? data_struct.peak_bin : -1
  endif
  


  if isa(detname) then begin
    nan= !values.f_nan
    if ~spe_param_dict.haskey('CALS') then   spe_param_dict.cals  = dictionary()
    cals = spe_param_dict.cals
    if ~cals.haskey(strupcase(detname))  then begin
      dprint,dlevel=2,'Generating cal structure for ',detname
;      deflut = spp_swp_spe_deflut_cal()
      case strupcase(detname) of
        'SPA' : begin
          dphi =  [1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4] * 240./40. ;width
          ;phi = total(/cum,dphi)- dphi/2 + 6.
          phi = [9.,15.,21.,27.,33.,39.,45.,51.,66.,90.,114.,138.,162.,186.,210.,234.]
          ;phi  = total(dphi,/cumulative) -3 ; +180
          phi = phi - 180               ; rotate by 180 to account for travel directions instead of look direction
          quaternion = [0.58030356d, 0.40403933d, 0.40403933d, 0.58030356d]
        end
        'SPB' : begin
          dphi =  [4,4,4,4,1,1,1,1,1,1,1,1,4,4,4,4] * 240./40. ;width
          phi = [-108.,-84.,-60.,-36.,-21.,-15.,-9.,-3.,3.,9.,15.,21.,36.,60.,84.,108.]
          ;phi = total(dphi,/cumulative) - 120 -12; +180
          phi = phi + 180      ; rotate by 180 to account for travel directions instead of look direction
          quaternion = [0.25882519d, 0d,0d, 0.96592418d]
        end
      endcase
      n_anodes  = 16
      eff = replicate(1.,n_anodes)
      cal  = {   $
        name: detname,  $
        n_anodes: n_anodes, $
        phi: phi, $
        dphi: dphi,  $
        eff:  eff,   $
        geomfactor_full: .00152,  $     ; cm2-ster-eV/eV  - does not account for grids or efficiency !!
        defl_scale: .0028d,  $  ; conversion from dac to angle  - This is not quite appropriate - works for now
        ;        deflut_dac: deflut.defdac, $
        ;        deflut_ang: deflut.theta * (-1.), $
        hem_scale:    500.d  , $
        spoil_scale:  80./2.^16   ,  $  ; Needs correction
        k_anal:  replicate(16.7,n_anodes) ,  $
        k_defl:  replicate(1.,n_anodes), $
        mech_attnxs: [nan,1.,10.,nan]   , $   ; 0:undefined,  1:atten_out,   2: atten_in,   3: undefined
        quaternion : quaternion,  $
        defl_cal:    polycurve2(coeff = [-1396.73d, 539.083d, 0.802293d, -0.04624d, -0.000163369d, 0.00000319759d],/invert )  $
      }
      cals[strupcase(detname)] = cal
    endif

    param.cal = cals[strupcase(detname)]
  endif




  if isa(emode) then begin
    if ~spe_param_dict.haskey('ETABLES') then spe_param_dict.etables = orderedhash()
    etables = spe_param_dict.etables
    if ~etables.haskey(emode) then begin
      ratios = [1.,.3,.1,.1,.001]
      spane_params = {  $
        hvgain : 500., $
        fixgain : 13. * 2 $
      }
      dprint,dlevel=2,'Generating Energy table - emode: '+strtrim(fix(emode),2)
      case emode  of
        1:  etables[1] = spp_swp_spanx_sweep_tables([20.,20000.], spfac = ratios[0], emode = emode, _extra = spane_params)
        2:  etables[2] = spp_swp_spanx_sweep_tables([10.,10000.], spfac = ratios[0], emode = emode, _extra = spane_params)
        3:  etables[3] = spp_swp_spanx_sweep_tables([ 5., 5000.], spfac = ratios[0], emode = emode, _extra = spane_params)
        4:  etables[4] = spp_swp_spanx_sweep_tables([ 5.,  500.], spfac = ratios[0], emode = emode, _extra = spane_params)
        5:  etables[5] = spp_swp_spanx_sweep_tables([20.,20000.], spfac = ratios[1], emode = emode, _extra = spane_params)
        6:  etables[6] = spp_swp_spanx_sweep_tables([10.,10000.], spfac = ratios[1], emode = emode, _extra = spane_params)
        7:  etables[7] = spp_swp_spanx_sweep_tables([ 5., 5000.], spfac = ratios[1], emode = emode, _extra = spane_params)
        8:  etables[8] = spp_swp_spanx_sweep_tables([ 5.,  500.], spfac = ratios[1], emode = emode, _extra = spane_params)
        9:  etables[9] = spp_swp_spanx_sweep_tables([20.,20000.], spfac = ratios[2], emode = 9, _extra = spane_params)
        10: etables[10] = spp_swp_spanx_sweep_tables([10.,10000.], spfac = ratios[2], emode = 10, _extra = spane_params)
        11: etables[11] = spp_swp_spanx_sweep_tables([ 5., 5000.], spfac = ratios[2], emode = 11, _extra = spane_params)
        12: etables[12] = spp_swp_spanx_sweep_tables([ 5.,  500.], spfac = ratios[2], emode = 12, _extra = spane_params)
        13: etables[13] = spp_swp_spanx_sweep_tables([20.,20000.], spfac = ratios[3], emode = 13, _extra = spane_params)
        14: etables[14] = spp_swp_spanx_sweep_tables([10.,10000.], spfac = ratios[3], emode = 14, _extra = spane_params)
        15: etables[15] = spp_swp_spanx_sweep_tables([ 5., 5000.], spfac = ratios[3], emode = 15, _extra = spane_params)
        16: etables[16] = spp_swp_spanx_sweep_tables([ 5.,  500.], spfac = ratios[3], emode = 16, _extra = spane_params)
        17: etables[17] = spp_swp_spanx_sweep_tables([2.,2000.],    spfac = ratios[4], emode = 17, _extra = spane_params)
        18: etables[18] = spp_swp_spanx_sweep_tables([10.,10000.], spfac = ratios[4], emode = 18, _extra = spane_params)
        19: etables[19] = spp_swp_spanx_sweep_tables([ 5., 5000.], spfac = ratios[4], emode = 19, _extra = spane_params)
        20: etables[20] = spp_swp_spanx_sweep_tables([ 5.,  500.], spfac = ratios[4], emode = 20, _extra = spane_params)
        21: etables[21] = spp_swp_spanx_sweep_tables([ 2., 2000.], spfac = ratios[3], emode = 21, _extra = spane_params)
        else: begin
          etables[emode] = 'Invalid'
          printdat,'Unknown etable encountered'
        end
      endcase    
    endif    
    param.etable = etables[emode]
    
    ;def5coeff = [-1396.73, 539.083, 0.802293, -0.0462400, -0.000163369, 0.00000319759]

  endif
  
  
  
  if isa(pmode) then begin
    if ~spe_param_dict.haskey('ptables') then spe_param_dict.ptables = orderedhash()
    ptables = spe_param_dict.ptables
    if ~ptables.haskey(pmode) then begin
      dprint, 'Generating new product table ', pmode, dlevel=1
      case pmode of
        '16Ax8Dx32E'  : binmap = indgen(16,8,32)   ; 4096 samples; full resolution
        '32E'  : binmap = reform( replicate(1,16*8) # indgen(32) , 16,8,32 )    ; 32 sample energy spectra
        '16A'   : binmap = reform( indgen(16) # replicate(1,8*32) , 16,8,32)      ; 16 sample anode spectra
        else:   binmap = !null
      endcase
      ptable = dictionary()
      ptable.pmode = pmode
      if isa(binmap) then begin
        hist = histogram(binmap,locations=loc,omin=omin,omax=omax,reverse_ind=ri)
        ptable.binmap = binmap
        ptable.hist = hist
        ptable.reverse_ind = ri
      endif else dprint,dlevel=1,'Unknown pmode: "',pmode,'"'
      ptables[pmode] = ptable
    endif
    param.ptable  = ptables[pmode]
  endif
  
;  if isa(status_bits) then begin
;    message,'Old code'
;    if ~spe_param_dict.haskey('status') then spe_param_dict.status = orderedhash()
;    status = spe_param_dict.status
;    if ~status.haskey(strupcase(status_bits))  then begin
;      if (fix(status_bits) and 128) eq 128 then mech_attn = 1 ; in 
;      if (fix(status_bits) and 64) eq 64 then mech_attn = 0 ; out
;      if ~((fix(status_bits) and 128) eq 128) and ~((fix(status_bits) and 64) eq 64) then mech_attn = 'f'x ; illegal state
;      hv_sweep = 'f'x and fix(status_bits)
;      stat  = {   $
;        mech_attn: mech_attn, $ ; 0 is out, 1 is in
;        ;test_pulser: , $
;        ;hv_enable: , $
;        hv_sweep: hv_sweep $
;      }
;      status[strupcase(status_bits)] = stat
;    endif
;    param.stat = status[strupcase(status_bits)]
;  endif
  
;  if n_elements(param) eq 0 then param = spe_param_dict
  
  return,param
     
END

