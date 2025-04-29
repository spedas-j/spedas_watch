; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-04-28 15:03:40 -0700 (Mon, 28 Apr 2025) $
; $LastChangedRevision: 33276 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1a.pro $


function swfo_stis_sci_level_1a,l0b_strcts , verbose=verbose ;,format=format,reset=reset,cal=cal

  output = !null
  nd = n_elements(l0b_strcts)  
  
  nan48=replicate(!values.f_nan,48)

  L1a = {swfo_stis_L1a,  $
    time:0d, $
    time_unix: 0d, $
    time_MET:  0d, $
    time_GR:  0d, $
    hash:   0UL, $
    ; noise columns:
    noise_res: 0u, $
    noise_total: replicate(0d,6),  $
    noise_baseline: replicate(!values.f_nan,6),  $
    noise_sigma: replicate(!values.f_nan,6),  $
    sci_duration: 0u , $
    sci_nbins:   0u,  $
    sci_counts : replicate(!values.f_nan,672),  $
    ; nse_noise_res: , $
;    sci_adc    : replicate(!values.f_nan,672),  $
;    sci_dadc    : replicate(!values.f_nan,672),  $
    total14:  fltarr(14) , $
    total6:   fltarr(6) , $
    geom_O1: nan48, rate_O1: nan48, SPEC_O1: nan48, spec_O1_nrg: nan48, spec_O1_dnrg: nan48, spec_O1_adc:  nan48, spec_O1_dadc:  nan48, $
    geom_O2: nan48, rate_O2: nan48, SPEC_O2: nan48, spec_O2_nrg: nan48, spec_O2_dnrg: nan48, spec_O2_adc:  nan48, spec_O2_dadc:  nan48, $
    geom_O3: nan48, rate_O3: nan48, SPEC_O3: nan48, spec_O3_nrg: nan48, spec_O3_dnrg: nan48, spec_O3_adc:  nan48, spec_O3_dadc:  nan48, $

    geom_O12: nan48, rate_O12: nan48, SPEC_O12: nan48, spec_O12_nrg: nan48, spec_O12_dnrg: nan48, spec_O12_adc:  nan48, spec_O12_dadc:  nan48, $
    geom_O13: nan48, rate_O13: nan48, SPEC_O13: nan48, spec_O13_nrg: nan48, spec_O13_dnrg: nan48, spec_O13_adc:  nan48, spec_O13_dadc:  nan48, $
    geom_O23: nan48, rate_O23: nan48, SPEC_O23: nan48, spec_O23_nrg: nan48, spec_O23_dnrg: nan48, spec_O23_adc:  nan48, spec_O23_dadc:  nan48, $
    geom_O123: nan48, rate_O123: nan48, SPEC_O123: nan48, spec_O123_nrg: nan48, spec_O123_dnrg: nan48, spec_O123_adc:  nan48, spec_O123_dadc:  nan48, $

    geom_F1: nan48, rate_F1: nan48, SPEC_F1: nan48, spec_F1_nrg: nan48, spec_F1_dnrg: nan48, spec_F1_adc:  nan48, spec_F1_dadc:  nan48, $
    geom_F2: nan48, rate_F2: nan48, SPEC_F2: nan48, spec_F2_nrg: nan48, spec_F2_dnrg: nan48, spec_F2_adc:  nan48, spec_F2_dadc:  nan48, $
    geom_F3: nan48, rate_F3: nan48, SPEC_F3: nan48, spec_F3_nrg: nan48, spec_F3_dnrg: nan48, spec_F3_adc:  nan48, spec_F3_dadc:  nan48, $

    geom_F12: nan48, rate_F12: nan48, SPEC_F12: nan48, spec_F12_nrg: nan48, spec_F12_dnrg: nan48, spec_F12_adc:  nan48, spec_F12_dadc:  nan48, $
    geom_F13: nan48, rate_F13: nan48, SPEC_F13: nan48, spec_F13_nrg: nan48, spec_F13_dnrg: nan48, spec_F13_adc:  nan48, spec_F13_dadc:  nan48, $
    geom_F23: nan48, rate_F23: nan48, SPEC_F23: nan48, spec_F23_nrg: nan48, spec_F23_dnrg: nan48, spec_F23_adc:  nan48, spec_F23_dadc:  nan48, $
    geom_F123: nan48, rate_F123: nan48, SPEC_F123: nan48, spec_F123_nrg: nan48, spec_F123_dnrg: nan48, spec_F123_adc:  nan48, spec_F123_dadc:  nan48, $

    fpga_rev: 0b, $
    quality_bits: 0UL, $
    sci_resolution: 0b, $
    sci_translate: 0u, $
    gap:0}
    

  ; Old: struct assign
  L1a_strcts = replicate({swfo_stis_l1a}, nd )
  struct_assign , l0b_strcts,  l1a_strcts, /nozero, verbose = verbose

  ; str_0 = l0b_strcts[0]
  ; mapd = swfo_stis_adc_map(data_sample=str_0)  
  ; nrg = mapd.nrg
  ; dnrg = mapd.dnrg
  ; adc = mapd.adc
  ; dadc = mapd.dadc
  ; geom = mapd.geom

  ; Ion fill in:
  index_O123 = 12
  index_O23 = 10
  index_O13 = 8
  index_O12 = 4
  index_O3 = 6
  index_O2 = 2
  index_O1 = 0
  ; Elec indexL
  index_F123 = 13
  index_F23 = 11
  index_F13 = 9
  index_F12 = 5
  index_F3 = 7
  index_F2 = 3
  index_F1 = 1

    ; print, nd

  for i=0l,nd-1 do begin
    L0b_str = l0b_strcts[i]
    L1a = L1a_strcts[i]
    
    mapd = swfo_stis_adc_map(data_sample=L0b_str)  
    nrg = mapd.nrg
    dnrg = mapd.dnrg
    adc = mapd.adc
    dadc = mapd.dadc
    geom = mapd.geom

    d = L0b_str.sci_counts
    d = reform(d,48,14)
    
    ; Moved from swfo_stis_sci_apdat__define
    ; when decimation active (e.g. high count rates)
    ; drops in sensitivity to allow resolution of higher fluxes
    dec = L0b_str.sci_decimation_factor_bits
    if dec ne 0 then begin
      ; Channels 2, 3, 5, and 6
      dec6 = [0,dec,ishft(dec,-2),0,ishft(dec,-4),ishft(dec,-6)]  and 3
      scale6 = 2. ^ dec6
      ;                      1     2    3      4     5      6      7
      ;                     C1    C2   C12    C3    C13    C23   C123
      scale14 = scale6[  [ 0,3,  1,4,  1,4,   2,5,   2,5,   2,5,   2,5    ]                       ]   ; Note :  still need to work on coincident decimation
      dprint,dlevel=3,'Decimation is on! ',scale6
      dprint,dlevel=3, scale14
      for ch = 0,13 do begin
        d[*,ch]  *= scale14[ch]
      endfor
    endif

    ; Noise value determination (copied from swfo_stis_nse_apdat::handler2)
    nse_level_1_str = swfo_stis_nse_level_1(L0b_str, /from_l0b)
    l1a.noise_res = nse_level_1_str.noise_res
    l1a.noise_total = nse_level_1_str.noise_total
    l1a.noise_baseline = nse_level_1_str.noise_baseline
    l1a.noise_sigma = nse_level_1_str.noise_sigma

    l1a.sci_translate = L0b_str.sci_translate
    l1a.sci_resolution = L0b_str.sci_resolution
    ; stop

    ; stop

    total14=total(d,1)
    total6 = fltarr(6)

    foreach tid,[0,1] do begin
      total6[0+tid*3]=total14[0+tid]+total14[4+tid]+total14[ 8+tid]+total14[12+tid]
      total6[1+tid*3]=total14[2+tid]+total14[4+tid]+total14[10+tid]+total14[12+tid]
      total6[2+tid*3]=total14[6+tid]+total14[8+tid]+total14[10+tid]+total14[12+tid]
    endforeach

    L1a.total14 = total14
    l1a.total6  = total6

  ;  cal = swfo_stis_cal_params(L0b_str,reset=reset)
    duration = L0b_str.sci_duration
    rate = d / duration  ; count rate (#/s)
    flux = rate / geom / dnrg ; flux (#/s/cm2/eV)

    ; Calls on each str?
    ; mapd = swfo_stis_adc_map(data_sample=L0b_str)
    ; nrg  = mapd.nrg
    ; dnrg = mapd.dnrg
    ; adc = mapd.adc
    ; dadc = mapd.dadc
    ; stop



    if 1 then begin

      ; Indices of the ion (O) and electron (F) in small pixel AR1 (1)
      ; and big pixel AR2 (3) for single coincidences (e.g. 1, 2, 3)
      ;Index:          0,        1,        2,        3,        4,         5,
      ;Channel #:      1,        4,        2,        5,      1-2,       4-5,
      ;Detector:      O1,       F1,      O2,       F2,      O12,       F12,
      ;Meaning:  Ion-AR1, Elec-AR1, Ion-AR3, Elec-AR3, Ion-AR13, Elec-AR13,
      ; -----------------------------
      ;      6,        7,        8,         9,       10,        11,      12,        13
      ;      3,        6,      1-3,       4-6,      2-3,       5-6,   1-2-3,     4-5-6
      ;     O3,       F3,      O13,       F13,      O23,       F56,    O123,      F123
      ;Ion-AR2, Elec-AR2, Ion-AR12, Elec-AR12, Ion-AR23, Elec-AR23, Ion-123, Elec-F123
      

      ; Fill in ion AKA O info
      l1a.geom_O1   = geom[*, index_O1]
      l1a.geom_O2   = geom[*, index_O2]
      l1a.geom_O12  = geom[*, index_O12]
      l1a.geom_O3   = geom[*, index_O3]
      l1a.geom_O13  = geom[*, index_O13]
      l1a.geom_O23  = geom[*, index_O23]
      l1a.geom_O123 = geom[*, index_O123]

      l1a.spec_O1   = flux[*, index_O1]
      l1a.spec_O2   = flux[*, index_O2]
      l1a.spec_O12  = flux[*, index_O12]
      l1a.spec_O3   = flux[*, index_O3]
      l1a.spec_O13  = flux[*, index_O13]
      l1a.spec_O23  = flux[*, index_O23]
      l1a.spec_O123 = flux[*, index_O123]

      l1a.rate_O1   = rate[*, index_O1]
      l1a.rate_O2   = rate[*, index_O2]
      l1a.rate_O12  = rate[*, index_O12]
      l1a.rate_O3   = rate[*, index_O3]
      l1a.rate_O13  = rate[*, index_O13]
      l1a.rate_O23  = rate[*, index_O23]
      l1a.rate_O123 = rate[*, index_O123]

      l1a.spec_O1_nrg   = nrg[*, index_O1]
      l1a.spec_O2_nrg   = nrg[*, index_O2]
      l1a.spec_O12_nrg  = nrg[*, index_O12]
      l1a.spec_O3_nrg   = nrg[*, index_O3]
      l1a.spec_O13_nrg  = nrg[*, index_O13]
      l1a.spec_O23_nrg  = nrg[*, index_O23]
      l1a.spec_O123_nrg = nrg[*, index_O123]

      l1a.spec_O1_dnrg   = dnrg[*, index_O1]
      l1a.spec_O2_dnrg   = dnrg[*, index_O2]
      l1a.spec_O12_dnrg  = dnrg[*, index_O12]
      l1a.spec_O3_dnrg   = dnrg[*, index_O3]
      l1a.spec_O13_dnrg  = dnrg[*, index_O13]
      l1a.spec_O23_dnrg  = dnrg[*, index_O23]
      l1a.spec_O123_dnrg = dnrg[*, index_O123]

      l1a.spec_O1_adc   = adc[*, index_O1]
      l1a.spec_O2_adc   = adc[*, index_O2]
      l1a.spec_O12_adc  = adc[*, index_O12]
      l1a.spec_O3_adc   = adc[*, index_O3]
      l1a.spec_O13_adc  = adc[*, index_O13]
      l1a.spec_O23_adc  = adc[*, index_O23]
      l1a.spec_O123_adc = adc[*, index_O123]

      l1a.spec_O1_dadc   = dadc[*, index_O1]
      l1a.spec_O2_dadc   = dadc[*, index_O2]
      l1a.spec_O12_dadc  = dadc[*, index_O12]
      l1a.spec_O3_dadc   = dadc[*, index_O3]
      l1a.spec_O13_dadc  = dadc[*, index_O13]
      l1a.spec_O23_dadc  = dadc[*, index_O23]
      l1a.spec_O123_dadc = dadc[*, index_O123]

      ; Fill in elec AKA F info
      l1a.geom_F1   = geom[*, index_F1]
      l1a.geom_F2   = geom[*, index_F2]
      l1a.geom_F12  = geom[*, index_F12]
      l1a.geom_F3   = geom[*, index_F3]
      l1a.geom_F13  = geom[*, index_F13]
      l1a.geom_F23  = geom[*, index_F23]
      l1a.geom_F123 = geom[*, index_F123]

      l1a.spec_F1   = flux[*, index_F1]
      l1a.spec_F2   = flux[*, index_F2]
      l1a.spec_F12  = flux[*, index_F12]
      l1a.spec_F3   = flux[*, index_F3]
      l1a.spec_F13  = flux[*, index_F13]
      l1a.spec_F23  = flux[*, index_F23]
      l1a.spec_F123 = flux[*, index_F123]

      l1a.rate_F1   = rate[*, index_F1]
      l1a.rate_F2   = rate[*, index_F2]
      l1a.rate_F12  = rate[*, index_F12]
      l1a.rate_F3   = rate[*, index_F3]
      l1a.rate_F13  = rate[*, index_F13]
      l1a.rate_F23  = rate[*, index_F23]
      l1a.rate_F123 = rate[*, index_F123]

      l1a.spec_F1_nrg   = nrg[*, index_F1]
      l1a.spec_F2_nrg   = nrg[*, index_F2]
      l1a.spec_F12_nrg  = nrg[*, index_F12]
      l1a.spec_F3_nrg   = nrg[*, index_F3]
      l1a.spec_F13_nrg  = nrg[*, index_F13]
      l1a.spec_F23_nrg  = nrg[*, index_F23]
      l1a.spec_F123_nrg = nrg[*, index_F123]

      l1a.spec_F1_dnrg   = dnrg[*, index_F1]
      l1a.spec_F2_dnrg   = dnrg[*, index_F2]
      l1a.spec_F12_dnrg  = dnrg[*, index_F12]
      l1a.spec_F3_dnrg   = dnrg[*, index_F3]
      l1a.spec_F13_dnrg  = dnrg[*, index_F13]
      l1a.spec_F23_dnrg  = dnrg[*, index_F23]
      l1a.spec_F123_dnrg = dnrg[*, index_F123]

      l1a.spec_F1_adc   = adc[*, index_F1]
      l1a.spec_F2_adc   = adc[*, index_F2]
      l1a.spec_F12_adc  = adc[*, index_F12]
      l1a.spec_F3_adc   = adc[*, index_F3]
      l1a.spec_F13_adc  = adc[*, index_F13]
      l1a.spec_F23_adc  = adc[*, index_F23]
      l1a.spec_F123_adc = adc[*, index_F123]

      l1a.spec_F1_dadc   = dadc[*, index_F1]
      l1a.spec_F2_dadc   = dadc[*, index_F2]
      l1a.spec_F12_dadc  = dadc[*, index_F12]
      l1a.spec_F3_dadc   = dadc[*, index_F3]
      l1a.spec_F13_dadc  = dadc[*, index_F13]
      l1a.spec_F23_dadc  = dadc[*, index_F23]
      l1a.spec_F123_dadc = dadc[*, index_F123]

    endif else begin
      if 0 then begin
        out = {time:L0b_str.time}
        str_element,/add,out,'hash',mapd.codes.hashcode()
        str_element,/add,out,'sci_duration',L0b_str.sci_duration
        str_element,/add,out,'sci_nbins',L0b_str.sci_nbins      
        str_element,/add,out,'gap',0
      endif else begin
        out = l1a
      endelse
      foreach w,mapd.wh,key do begin
  ;      str_element,/add,out,'cnts_'+key,counts[w]
  ;      str_element,/add,out,'rate_'+key,counts[w]/ L0b_str.sci_duration

        str_element,/add,out,'spec_'+key,flux[w]
        str_element,/add,out,'spec_'+key+'_nrg',nrg[w]
        str_element,/add,out,'spec_'+key+'_dnrg',dnrg[w]

    ;    str_element,/add,out,'spec_'+key+'_adc',adc[w]    
    ;    str_element,/add,out,'spec_'+key+'_dadc',dadc[w]
      endforeach
    endelse
    L1a_strcts[i] = l1a
    
;    if nd eq 1 then   return, out
;    if i  eq 0 then   output = replicate(out,nd) else output[i] = out

  endfor

  return,L1a_strcts

end

