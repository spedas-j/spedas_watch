function elf_get_epd_calibration, probe=probe, instrument=instrument, trange=trange

  if ~keyword_set(probe) then probe='a'
  if ~keyword_set(instrument) then instrument='epde'
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  
  if probe EQ 'a' then begin 
    if instrument EQ 'epde' then begin
      epde_gf = 0.02 ; 21deg x 21deg (in SA) by 1 cm^2
      epd_overaccumulation_factors = indgen(16)*0.+1.
      epd_overaccumulation_factors[15] = 1.15
      epde_thresh_factors = indgen(16)*0.+1.
      epde_thresh_factors[0] = 1./2 ; change me to match the threshold curves
      epde_thresh_factors[1] = 1.6
      epde_thresh_factors[2] = 1.2
      epde_ch_efficiencies = [0.461, 0.4, 0.286, 0.27, 0.25, 0.244, 0.219, 0.378, 0.353, 0.364, 0.323, 0.326, 0.291, 0.213, 0.332, 1.]
      epde_cal_ch_factors = 1./epde_gf*(epde_thresh_factors^(-1.))*(epde_ch_efficiencies^(-1.))
      epde_ebins = [50., 80., 120., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3350., 4150., 5800.] ; in keV based on Jiang Liu's Geant4 code 2019-3-5
      
      elf_calibration_data = { epde_gf:epde_gf, $
        epd_overaccumulation_factors:epd_overaccumulation_factors, $
        epde_thresh_factors:epde_thresh_factors, $
        epde_ch_efficiencies:epde_ch_efficiencies, $
        epde_cal_ch_factors:epde_cal_ch_factors, $
        epde_ebins:epde_ebins }
    endif
  endif
  
  return, elf_calibration_data
  
end