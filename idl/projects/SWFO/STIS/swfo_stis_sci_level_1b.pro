; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-02-27 18:59:51 -0800 (Thu, 27 Feb 2025) $
; $LastChangedRevision: 33156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $

; Function that merges counts/fluxes/rates/efluxes from the small pixel
; and large pixel given the coefficients of each.

function swfo_stis_hdr, F_largepixel, F_smallpixel, eta_smallpixel=eta_smallpixel,$
    eta_largepixel=eta_largepixel
    ;, l1a_str$

    ; F_small eta_1 + F_big eta_2 / (eta2 + eta1)
    ; works for rates, fluxes, etc:

    A = (eta_smallpixel + eta_largepixel)
    hdr = (eta_smallpixel * F_smallpixel + eta_largepixel * F_largepixel)/A

    return,hdr

end


function swfo_stis_sci_level_1b,L1a_strcts,format=format,reset=reset,cal=cal, param=param

  ; if isa(param,'dictionary') then def_param = param
  ; if ~isa(def_param,'dictionary') then def_param=dictionary()
  if ~keyword_set(param) then param=dictionary()
  if ~param.haskey('range') then param.range = 30   ; interval in seconds

  output = !null
  nd = n_elements(L1a_strcts)

  ; pull map for first str
  str_0 = L1a_strcts[0]
  mapd = swfo_stis_adc_map(data_sample=str_0)
  cal = swfo_stis_cal_params(str_0,reset=reset)
  if ~isa(cal) then return,!null
  bins = cal.prot_resp
  elec_resp = cal.elec_resp
  geom = bins.geom  ; this is the same for elecs and protons
  energy = bins.energy

  w = where(bins.species eq 1,/null)
  ion_energy= energy[w]
  w = where(elec_resp.species eq 0,/null)
  elec_energy= energy[w]

  ; Indices of the ion (O) and electron (F) in small pixel AR1 (1)
  ; and big pixel AR2 (3)
  ; presumably ions
  small_O_bins = mapd.wh["o1"]
  mid_O_bins = mapd.wh["o2"]
  big_O_bins = mapd.wh["o3"]

  small_F_bins = mapd.wh["f1"]
  mid_F_bins = mapd.wh["f2"]
  big_F_bins = mapd.wh["f3"]

  for i=0l,nd-1 do begin
    str = L1a_strcts[i]

    n_energy = cal.n_energy
    duration = str.sci_duration

    period = cal.period   ; approximate period (in seconds) of Version 64 FPGA
    integration_time = duration * period
    srate  = str.sci_counts/integration_time          ; srate is the measured (actual)  count rate

    ; Determine deadtime correctons here
    ; rate14 = str.total14/ integration_time    ; this needs to be checked
    ; Exrate = reform(replicate(1,n_energy) # rate14,n_energy * 14)
    ; deadtime_correction = 1 / (1- exrate*cal.deadtime)
    ; w = where(deadtime_correction gt 10. or deadtime_correction lt .5,/null)
    ; deadtime_correction[w] = !values.f_nan

    tot_rate_O = total([srate[small_O_bins], srate[big_O_bins], srate[mid_O_bins]])
    tot_rate_F = total([srate[small_F_bins], srate[big_F_bins], srate[mid_F_bins]])

    deadtime_correction_O = 1 / (1- tot_rate_O*cal.deadtime)
    deadtime_correction_F = 1 / (1- tot_rate_F*cal.deadtime)

    ; Alternate: Taylor expand to avoid singularity:
    ; deadtime_correction = 1 + exrate * cal.deadtime
    ; if total(rate14) gt 1000 then stop
    ; print, deadtime_correction
    ; stop

    ; crate is the count rate corrected for deadtime
    crate_O  = srate * deadtime_correction_O    
    crate_F  = srate * deadtime_correction_F
    flux_O = crate_O / geom
    flux_F = crate_F / geom

    ; get the deadtime prefactor:
    ; eta2 = 0. > (1.8- deadtime_correction)*.4 < 1.

    ; formulation from gpa doc:
    ; This accepts the big pixel if the deadtime correction below 1.2
    ; and de-emphasizes it as deadtime correction exceeds 1.8.
    eta2_O = 0. > (1.8- deadtime_correction_O)*(1/(1.8-1.2)) < 1.
    eta2_F = 0. > (1.8- deadtime_correction_F)*(1/(1.8-1.2)) < 1.
    ; print, cal.deadtime * total(rate14), mean(eta2)

    ; bins = cal.elec_resp
    ; elec_flux = crate / bins.geom
    ; elec_energy = bins.energy
    ; w = where(bins.species eq 0,/null,nw)
    ; elec_flux = elec_flux[w]
    ; elec_energy= elec_energy[w]
    

    ion_rate_small = crate_O[small_O_bins]
    ion_rate_big = crate_O[big_O_bins]

    elec_rate_small = crate_F[small_F_bins]
    elec_rate_big = crate_F[big_F_bins]

    tot_N_ion = total(ion_rate_small)
    tot_N_elec = total(elec_rate_small)

    ; These are currently constant over energy
    ; original:
    ; eta1_ion =  0. > sqrt( total(ion_rate_small) * param.range  ) < 1.
    ; eta1_elec =  0. > sqrt( total(elec_rate_small) * param.range ) < 1.

    ; from GPA doc:
    ; sqrt(N) / 100 for total counts for param.range seconds.
    eta1_ion =  0. > sqrt( total(ion_rate_small) * param.range  )/100 < 1.
    eta1_elec =  0. > sqrt( total(elec_rate_small) * param.range  )/100 < 1.

    ; ; scaled poisson
    ; if tot_N_ion eq 0 then eta1_ion = 0. else  eta1_ion =  0. > sqrt( tot_N_ion  ) / tot_N_ion < 1.
    ; eta1_elec =  0. > sqrt( tot_N_elec ) / tot_N_elec < 1.

    ; stop

    hdr_ion_flux = swfo_stis_hdr(flux_O[big_O_bins], flux_O[small_O_bins], $
      eta_smallpixel=eta1_ion, eta_largepixel=eta2_O)
    hdr_elec_flux = swfo_stis_hdr(flux_F[big_F_bins], flux_F[small_F_bins], $
      eta_smallpixel=eta1_ion, eta_largepixel=eta2_F)

    ; Previous way:
    ion_flux = flux_O[big_O_bins]
    elec_flux = flux_F[big_F_bins]

    ; ion_energy = bins.energy
    ; w = where(bins.species eq 1,/null)
    ; ion_energy= ion_energy[w]
    ; bins = cal.elec_resp
    ; elec_flux = crate / bins.geom
    ; elec_energy = bins.energy
    ; w = where(bins.species eq 0,/null,nw)
    ; elec_energy= elec_energy[w]

    sci_ex = {  $
      integration_time : duration * period, $
      ; srate : srate , $
      ; crate : crate , $
      TID:  bins.tid,  $
      FTO:  bins.fto,  $
      geom:  bins.geom,  $
      ewidth: bins.ewidth,  $
      ion_energy: ion_energy,   $   ; midpoint energy
      ion_flux :   ion_flux,  $
      tiny_ion_flux :   flux_O[small_O_bins],  $
      hdr_ion_flux :   hdr_ion_flux,  $
      eta2_ion: eta2_O, $
      eta2_elec: eta2_F, $
      eta1_ion: eta1_ion, $
      eta1_elec: eta1_elec, $
      elec_energy:  elec_energy, $
      tiny_elec_flux :   flux_F[small_F_bins],  $
      elec_flux:  elec_flux, $
      hdr_elec_flux:  hdr_elec_flux, $
      lut_id: 0 }

    sci = create_struct(str,sci_ex)

    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci

  endfor

  return,output

end

