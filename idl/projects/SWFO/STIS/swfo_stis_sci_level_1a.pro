; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $


function swfo_stis_sci_level_1a,strcts,format=format,reset=reset,cal=cal

  output = !null
  nd = n_elements(strcts)  
  
  nan48=replicate(!values.f_nan,48)
  output = {time:0d, $
    SPEC_O1:  nan48, $
    SPEC_O2:  nan48, $
    SPEC_O3:  nan48, $
    SPEC_F1:  nan48, $
    SPEC_F2:  nan48, $
    SPEC_F3:  nan48, $
    spec_o1_nrg:  nan48, $
    spec_o2_nrg:  nan48, $
    spec_o3_nrg:  nan48, $
    spec_f1_nrg:  nan48, $
    spec_f2_nrg:  nan48, $
    spec_f3_nrg:  nan48, $
    gap:0}
  
  for i=0l,nd-1 do begin
    str = strcts[i]

    mapd = swfo_stis_adc_map(data_sample=str)
    cal = swfo_stis_cal_params(str,reset=reset)
    counts = str.counts
    nrg  = mapd.nrg
    dnrg = mapd.dnrg
    out = {time:str.time}
    foreach w,mapd.wh,key do begin
      str_element,/add,out,'spec_'+key,counts[w] / dnrg[w]
      str_element,/add,out,'spec_'+key+'_nrg',nrg[w]
      
    endforeach
    

    if 0 then begin
      
    
    n_energy = cal.n_energy
    duration = str.duration

    period = cal.period   ; approximate period (in seconds) of Version 64 FPGA
    integration_time = str.duration * period
    srate  = str.counts/integration_time          ; srate is the measured (actual) count rate

    ; Determine deadtime correctons here
    rate14 = str.total14/ integration_time    ; this needs to be checked
    Exrate = reform(replicate(1,n_energy) # rate14,n_energy * 14)
    deadtime_correction = 1 / (1- exrate*cal.deadtime)
    w = where(deadtime_correction gt 10. or deadtime_correction lt .5,/null)
    deadtime_correction[w] = !values.f_nan
    crate  = srate * deadtime_correction       ; crate is the count rate corrected for deadtime

    bins = cal.prot_resp
    ion_flux = crate / bins.geom
    ion_energy = bins.energy
    w = where(bins.species eq 1,/null)
    ion_flux = ion_flux[w]
    ion_energy= ion_energy[w]

    bins = cal.elec_resp
    elec_flux = crate / bins.geom
    elec_energy = bins.energy
    w = where(bins.species eq 0,/null,nw)
    elec_flux = elec_flux[w]
    elec_energy= elec_energy[w]

    sci_ex = {  $
      integration_time : duration * period, $
      srate : srate , $
      crate : crate , $
      TID:  bins.tid,  $
      FTO:  bins.fto,  $
      geom:  bins.geom,  $
      ewidth: bins.ewidth,  $
      ion_energy: ion_energy,   $   ; midpoint energy
      ion_flux :   ion_flux,  $
      elec_energy:  elec_energy, $
      elec_flux:  elec_flux, $
      lut_id: 0 }

    sci = create_struct(str,sci_ex)
    endif
    
    if nd eq 1 then   return, out
    if i  eq 0 then   output = replicate(out,nd) else output[i] = out

  endfor

  return,output

end

