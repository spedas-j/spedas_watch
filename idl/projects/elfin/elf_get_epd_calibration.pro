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
      epde_gf = 0.15 ; 21deg x 21deg (in SA) by 1 cm^2
      epde_overaccumulation_factors = indgen(16)*0.+1.
      epde_overaccumulation_factors[15] = 1.15
      epde_thresh_factors = indgen(16)*0.+1.
      epde_thresh_factors[0] = 1./2 ; change me to match the threshold curves
      epde_thresh_factors[1] = 1.6
      epde_thresh_factors[2] = 1.2
      epde_ch_efficiencies = [0.74, 0.8, 0.85, 0.86, 0.87, 0.87, 0.87, 0.87, 0.82, 0.8, 0.75, 0.6, 0.5, 0.45, 0.25, 0.05]
      epde_cal_ch_factors = 1./epde_gf*(epde_thresh_factors^(-1.))*(epde_ch_efficiencies^(-1.))
      epde_ebins = [50., 80., 120., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3350., 4150., 5800.] ; in keV based on Jiang Liu's Geant4 code 2019-3-5      
      epde_ebin_lbls = ['50-80', '80-120', '120-160', '160-210', '210-270', '270-345', '345-430', '430-630', $
        '630-900', '900-1300', '1300-1800', '1800-2500', '2500-3350', '3350-4150', '4150-5800', '5800+'] 
      epd_calibration_data = { epd_gf:epde_gf, $
        epd_overaccumulation_factors:epde_overaccumulation_factors, $
        epd_thresh_factors:epde_thresh_factors, $
        epd_ch_efficiencies:epde_ch_efficiencies, $
        epd_cal_ch_factors:epde_cal_ch_factors, $
        epd_ebins:epde_ebins, $
        epd_ebin_lbls:epde_ebin_lbls }
    endif
    if instrument EQ 'epdi' then begin
      epdi_gf = 0.01 ; 21deg x 21deg (in SA) by 1 cm^2
      epdi_overaccumulation_factors = indgen(16)*0.+1.
      epdi_overaccumulation_factors[15] = 1./2
      epdi_thresh_factors = indgen(16)*0.+1.
      epdi_thresh_factors[0] = 1./2 ; change me to match the threshold curves
      epdi_thresh_factors[1] = 1.6
      epdi_thresh_factors[2] = 1.2
      epdi_ch_efficiencies = [0.74, 0.8, 0.85, 0.86, 0.87, 0.87, 0.87, 0.87, 0.82, 0.8, 0.75, 0.6, 0.5, 0.45, 0.25, 0.05]
      epdi_cal_ch_factors = 1./epdi_gf*(epdi_thresh_factors^(-1.))*(epdi_ch_efficiencies^(-1.))
      epdi_ebins = [50., 80., 120., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3350., 4150., 5800.] ; in keV based on Jiang Liu's Geant4 code 2019-3-5
      epdi_ebin_lbls = ['50-80', '80-120', '120-160', '160-210', '210-270', '270-345', '345-430', '430-630', $
        '630-900', '900-1300', '1300-1800', '1800-2500', '2500-3350', '3350-4150', '4150-5800', '5800+']
      epd_calibration_data = { epd_gf:epdi_gf, $
        epd_overaccumulation_factors:epdi_overaccumulation_factors, $
        epd_thresh_factors:epdi_thresh_factors, $
        epd_ch_efficiencies:epdi_ch_efficiencies, $
        epd_cal_ch_factors:epdi_cal_ch_factors, $
        epd_ebins:epdi_ebins, $
        epd_ebin_lbls:epdi_ebin_lbls }
    endif
  endif
  
  if probe EQ 'b' then begin
    if instrument EQ 'epde' then begin
      ; factors for ELF-B EPD-E *copied* from ELF-A as a temporary plotting solution; not actually valid!!
      epde_gf = 0.02 ; 21deg x 21deg (in SA) by 1 cm^2
      epde_overaccumulation_factors = indgen(16)*0.+1.
      epde_overaccumulation_factors[15] = 1.15
      epde_thresh_factors = indgen(16)*0.+1.
      epde_thresh_factors[0] = 1./2 ; change me to match the threshold curves
      epde_thresh_factors[1] = 1.6
      epde_thresh_factors[2] = 1.2
      epde_ch_efficiencies = [0.74, 0.8, 0.85, 0.86, 0.87, 0.87, 0.87, 0.87, 0.82, 0.8, 0.75, 0.6, 0.5, 0.45, 0.25, 0.05]
      epde_cal_ch_factors = 1./epde_gf*(epde_thresh_factors^(-1.))*(epde_ch_efficiencies^(-1.))
      epde_ebins = [50., 80., 120., 160., 210., 270., 345., 430., 630., 900., 1300., 1800., 2500., 3350., 4150., 5800.] ; in keV based on Jiang Liu's Geant4 code 2019-3-5
      epde_ebin_lbls = ['50-80', '80-120', '120-160', '160-210', '210-270', '270-345', '345-430', '430-630', $
        '630-900', '900-1300', '1300-1800', '1800-2500', '2500-3350', '3350-4150', '4150-5800', '5800+']
      epd_calibration_data = { epd_gf:epde_gf, $
        epd_overaccumulation_factors:epde_overaccumulation_factors, $
        epd_thresh_factors:epde_thresh_factors, $
        epd_ch_efficiencies:epde_ch_efficiencies, $
        epd_cal_ch_factors:epde_cal_ch_factors, $
        epd_ebins:epde_ebins, $
        epd_ebin_lbls:epde_ebin_lbls }       
    endif
    if instrument EQ 'epdi' then begin
      dprint, dlevel = 1, 'ELFIN B EPDI calibration is not yet available.'
      return, -1      
    endif
  endif


  return, epd_calibration_data
  
end