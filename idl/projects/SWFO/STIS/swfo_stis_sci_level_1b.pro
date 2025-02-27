; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-02-27 14:57:42 -0800 (Thu, 27 Feb 2025) $
; $LastChangedRevision: 33155 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $


function swfo_stis_sci_level_1b,L1a_strcts,format=format,reset=reset,cal=cal

  output = !null
  nd = n_elements(L1a_strcts)
  for i=0l,nd-1 do begin
    str = L1a_strcts[i]

    cal = swfo_stis_cal_params(str,reset=reset)
    if ~isa(cal) then return,!null

    n_energy = cal.n_energy
    duration = str.sci_duration

    period = cal.period   ; approximate period (in seconds) of Version 64 FPGA
    integration_time = duration * period
    srate  = str.sci_counts/integration_time          ; srate is the measured (actual)  count rate

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
    
    if 1 then begin
      
      names='SPEC_' + ['O1','O2','O3','F1','F2','F3']
      nans = replicate(!values.f_nan,48)
      format = {name:'',color:0,linestye:0,psym:-4,linethick:2,geomfactor:1.,x:nans,y:nans,dx:nans,dy:nans,xunits:'',yunits:'',lim:obj_new()}
      channels = replicate(format,n_elements(names))
      channels.name = names
      channels.color = [2,4,6,1,3,0]
      
      swfo_stis_plot,param=param   ; temporary access to test variables
      
      
      
      j1 = channels[0].y
      j2 = channels[2].y
      jconv =   param.jconv   ; temporary
      dtrate = param.dtrate
      rate1 = total(j1) * jconv
      rate2 = total(j2) * jconv * 100
      dtcor2 = 1/(1-rate2/30e4)
      dtcor2 = 1 + rate2/dtrate
      eta1 =  0. > sqrt( rate1 * param.range  ) < 1.
      eta2 =  0. >     (1.8- dtcor2)*.4    < 1.
      j_hdr = (eta1 * j1 + eta2 *j2)/ (eta1 + eta2)
      ch_cor = channels[0]
      ch_cor.color = 0
      ch_cor.y = j_hdr
      ;oplot,ch_cor.x,ch_cor.y ,color=5,psym=ch.psym,thick=3
      ion_flux = ch_cor.y
      ion_energy = ch_cor.x
      
      j1 = channels[3].y
      j2 = channels[5].y
      jconv =   param.jconv   ; temporary
      dtrate = param.dtrate
      rate1 = total(j1) * jconv
      rate2 = total(j2) * jconv * 100
      dtcor2 = 1/(1-rate2/30e4)
      dtcor2 = 1 + rate2/dtrate
      eta1 =  0. > sqrt( rate1 * param.range  ) < 1.
      eta2 =  0. >     (1.8- dtcor2)*.4    < 1.
      j_hdr = (eta1 * j1 + eta2 *j2)/ (eta1 + eta2)
      ch_cor = channels[0]
      ch_cor.color = 0
      ch_cor.y = j_hdr
      ELEC_flux = ch_cor.y
      elec_energy = ch_cor.x
      
    endif

    

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

    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci

  endfor

  return,output

end

