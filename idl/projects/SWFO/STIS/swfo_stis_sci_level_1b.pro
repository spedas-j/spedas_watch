; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-06-03 15:59:53 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33366 $
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


function swfo_stis_sci_level_1b,L1a_strcts,format=format,reset=reset,cal=cal

  ; if isa(param,'dictionary') then def_param = param
  ; if ~isa(def_param,'dictionary') then def_param=dictionary()
  ; if ~keyword_set(param) then param=dictionary()
  ; if ~param.haskey('range') then param.range = 30   ; interval in seconds

  output = !null
  nd = n_elements(L1a_strcts)

  ; ; pull map for first str
  ; str_0 = L1a_strcts[0]
  ; cal = swfo_stis_cal_params(str_0,reset=reset)
  ; if ~isa(cal) then return,!null
  ; bins = cal.prot_resp
  ; elec_resp = cal.elec_resp
  ; geom = bins.geom  ; this is the same for elecs and protons
  ; Get the cal values if not defined:
  if ~isa(cal,'dictionary') then cal = swfo_stis_inst_response_calval()


  ; Get deadtime correction criteria:
  dtc = cal.deadtime_correction_criteria
  dtc_lower = dtc[0]
  dtc_upper = dtc[1]
  dtc_scaling = 1/(dtc_upper-dtc_lower)

  poisson = cal.poisson_statistics_criteria
  N_low = poisson[0]
  N_high = poisson[1]
  a = cal.poisson_statistics_power_coefficient

  for i=0l,nd-1 do begin
    str = L1a_strcts[i]
    ; stop

    ; approximate period (in seconds) of Version 64 FPGA
    integration_time = str.sci_duration ; * cal.period

    ; get the energies:
    ion_energy  = str.spec_O1_nrg
    elec_energy = str.spec_F1_nrg
    ion_denergy  = str.spec_O1_dnrg
    elec_denergy = str.spec_F1_dnrg

    ; Determine deadtime correctons here
    ; srate is the total count rate in each detector for deadtime
    ; (summed over coincidences):
    ; O1/F1 first (tiny pixel)
    srate_O1 = total(str.rate_O1 + str.rate_O12 + str.rate_O13 + str.rate_O123)
    srate_F1 = total(str.rate_F1 + str.rate_F12 + str.rate_F13 + str.rate_F123)
    ; O3/F3 next (big pixel)
    srate_O3 = total(str.rate_O3 + str.rate_O13 + str.rate_O23 + str.rate_O123)
    srate_F3 = total(str.rate_F3 + str.rate_F13 + str.rate_F23 + str.rate_F123)

    ; Nonparalyzable deadtime in O1/F1 (tiny pixel AKA AR1)
    deadtime_correction_O1 = 1 / (1- srate_O1*cal.deadtime_s)
    deadtime_correction_F1 = 1 / (1- srate_F1*cal.deadtime_s)
    ; Nonparalyzable deadtime in O3/F3 (big pixel AKA AR2)
    deadtime_correction_O3 = 1 / (1- srate_O3*cal.deadtime_s)
    deadtime_correction_F3 = 1 / (1- srate_F3*cal.deadtime_s)

    ; formulation from gpa doc:
    ; get the deadtime prefactor:
    ; This accepts the big pixel if the deadtime correction below 1.2
    ; and de-emphasizes it as deadtime correction exceeds 1.8.
    ; eta2 = 0. > (1.8- deadtime_correction)*.4 < 1.
    eta2_O = 0. > (dtc_upper - deadtime_correction_O3)*dtc_scaling < 1.
    eta2_F = 0. > (dtc_upper - deadtime_correction_F3)*dtc_scaling < 1.

    ; rate14 = str.total14/ integration_time    ; this needs to be checked
    ; Exrate = reform(replicate(1,cal.n_energy) # rate14,cal.n_energy * 14)
    ; deadtime_correction = 1 / (1- exrate*cal.deadtime)
    ; w = where(deadtime_correction gt 10. or deadtime_correction lt .5,/null)
    ; deadtime_correction[w] = !values.f_nan
    ; Alternate: Taylor expand to avoid singularity:
    ; deadtime_correction = 1 + exrate * cal.deadtime
    ; if total(rate14) gt 1000 then stop

    ; Apply deadtime correction to flux & rate:
    ; rate is the count rate corrected for deadtime
    ion_rate_small = str.rate_O1 * deadtime_correction_O1
    ion_rate_big = str.rate_O3 * deadtime_correction_O3
    ion_flux_small = str.spec_O1 * deadtime_correction_O1
    ion_flux_big = str.spec_O3 * deadtime_correction_O3

    elec_rate_small = str.rate_F1 * deadtime_correction_F1
    elec_rate_big = str.rate_F3 * deadtime_correction_F3
    elec_flux_small = str.spec_F1 * deadtime_correction_F1
    elec_flux_big = str.spec_F3 * deadtime_correction_F3

    ; total counts in entire energy channel:
    N_ion = total(ion_rate_small) * integration_time
    N_elec = total(elec_rate_small) * integration_time

    ; These are currently constant over energy
    ; original:
    ; eta1_ion =  0. > sqrt( total(ion_rate_small) * param.range  ) < 1.
    ; eta1_elec =  0. > sqrt( total(elec_rate_small) * param.range ) < 1.

    ; from GPA doc:
    ; sqrt(N) / 100 for total counts for param.range seconds.
    eta1_ion =  0. > sqrt( N_ion  )/100 < 1.
    eta1_elec =  0. > sqrt( N_elec  )/100 < 1.

    ; New approach:
    ; maximum control by calvals table:
    f_elec = (N_elec^a - N_low^a)/(N_high^a - N_low^a)
    eta1_elec = (N_elec gt N_high) + (N_elec lt N_high and N_elec gt N_low) * f_elec
    f_ion = (N_ion^a - N_low^a)/(N_high^a - N_low^a)
    eta1_ion = (N_ion gt N_high) + (N_ion lt N_high and N_ion gt N_low) * f_ion

    ; ; scaled poisson
    ; if tot_N_ion eq 0 then eta1_ion = 0. else  eta1_ion =  0. > sqrt( tot_N_ion  ) / tot_N_ion < 1.
    ; eta1_elec =  0. > sqrt( tot_N_elec ) / tot_N_elec < 1.

    ; stop

    hdr_ion_flux = swfo_stis_hdr(ion_flux_big, ion_flux_small, $
      eta_smallpixel=eta1_ion, eta_largepixel=eta2_O)
    hdr_elec_flux = swfo_stis_hdr(elec_flux_big, elec_flux_small, $
      eta_smallpixel=eta1_ion, eta_largepixel=eta2_F)

    ; ion_energy = bins.energy
    ; w = where(bins.species eq 1,/null)
    ; ion_energy= ion_energy[w]
    ; bins = cal.elec_resp
    ; elec_flux = crate / bins.geom
    ; elec_energy = bins.energy
    ; w = where(bins.species eq 0,/null,nw)
    ; elec_energy= elec_energy[w]

    sci_ex = {  $
      integration_time : integration_time, $
      ; srate : srate , $
      ; crate : crate , $
      ; TID:  bins.tid,  $
      ; FTO:  bins.fto,  $
      ; geom:  bins.geom,  $
      ewidth: ion_denergy,  $
      ion_energy: ion_energy,   $   ; midpoint energy
      Ch1_ion_flux :   ion_flux_small,  $
      Ch3_ion_flux :   ion_flux_big,  $
      hdr_ion_flux :   hdr_ion_flux,  $
      eta2_ion: eta2_O, $
      eta2_elec: eta2_F, $
      eta1_ion: eta1_ion, $
      eta1_elec: eta1_elec, $
      elec_energy:  elec_energy, $
      Ch1_elec_flux :   elec_flux_small,  $
      Ch3_elec_flux :   elec_flux_big,  $
      hdr_elec_flux:  hdr_elec_flux, $
      lut_id: 0 }

    sci = create_struct(str,sci_ex)

    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci

  endfor

  return,output

end

