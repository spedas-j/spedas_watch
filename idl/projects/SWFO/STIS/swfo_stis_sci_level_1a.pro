; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-12-01 21:14:54 -0800 (Sun, 01 Dec 2024) $
; $LastChangedRevision: 32978 $
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
    sci_duration: 0u , $
    sci_nbins:   0u,  $
    sci_counts : replicate(!values.f_nan,672),  $
;    sci_adc    : replicate(!values.f_nan,672),  $
;    sci_dadc    : replicate(!values.f_nan,672),  $
    total14:  fltarr(14) , $
    total6:   fltarr(6) , $
    SPEC_O1:  nan48, $
    SPEC_O2:  nan48, $
    SPEC_O3:  nan48, $
    SPEC_F1:  nan48, $
    SPEC_F2:  nan48, $
    SPEC_F3:  nan48, $
    spec_O1_nrg:  nan48, $
    spec_O2_nrg:  nan48, $
    spec_O3_nrg:  nan48, $
    spec_F1_nrg:  nan48, $
    spec_F2_nrg:  nan48, $
    spec_F3_nrg:  nan48, $
    fpga_rev: 0b, $
    quality_bits: 0ULL, $
    gap:0}
    
  L1a_strcts = replicate({swfo_stis_l1a}, nd )
  struct_assign , l0b_strcts,  l1a_strcts, /nozero, verbose = verbose
    
  
  for i=0l,nd-1 do begin
    L0b_str = l0b_strcts[i]
    L1a = L1a_strcts[i]
    
    d = L0b_str.sci_counts
    d = reform(d,48,14)
    
    total14=total(d,1)
    total6 = fltarr(6)

    foreach tid,[0,1] do begin
      total6[0+tid*3]=total14[0+tid]+total14[4+tid]+total14[ 8+tid]+total14[12+tid]
      total6[1+tid*3]=total14[2+tid]+total14[4+tid]+total14[10+tid]+total14[12+tid]
      total6[2+tid*3]=total14[6+tid]+total14[8+tid]+total14[10+tid]+total14[12+tid]
    endforeach

    L1a.total14 = total14
    l1a.total6  = total6

    mapd = swfo_stis_adc_map(data_sample=L0b_str)
  ;  cal = swfo_stis_cal_params(L0b_str,reset=reset)
    counts = L0b_str.sci_counts
    nrg  = mapd.nrg
    dnrg = mapd.dnrg
    dadc = mapd.dadc
    
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
      str_element,/add,out,'spec_'+key,counts[w] / dnrg[w] / mapd.geom[w] / L0b_str.sci_duration
      str_element,/add,out,'spec_'+key+'_nrg',nrg[w]
 ;     str_element,/add,out,'spec_'+key+'_dnrg',dnrg[w]
 ;     str_element,/add,out,'spec_'+key+'_adc',mapd.adc[w]    
 ;     str_element,/add,out,'spec_'+key+'_dadc',mapd.dadc[w]
    endforeach
    L1a_strcts[i] = out
    
;    if nd eq 1 then   return, out
;    if i  eq 0 then   output = replicate(out,nd) else output[i] = out

  endfor

  return,L1a_strcts

end

