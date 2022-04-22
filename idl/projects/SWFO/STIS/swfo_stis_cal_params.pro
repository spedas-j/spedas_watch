; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $

;This routine should return a structure that contains calibration parameters.
; Currently only valid for the non LUT mode  ; this is a place holder for final cal routines

function swfo_stis_cal_params,strct

  common swfo_stis_cal_params_com, stis_master

  if ~isa(stis_master,'dictionary') then stis_master = dictionary()

  if strct.nbins ne 672 then begin
    dprint, 'Not working with  LUT mode yet'
    return,!null
  endif
  
  if ~stis_master.haskey('cal') then begin
    kev_per_adc = 1.6   ; kev  approx
    KEV_dead_layer = 10  ; kev  approx
    bins = indgen(672)
    FTO_ID = bins / 48
    TID = FTO and 1
    FTO = (FTO_ID /2 ) + 1
    LOG_ADC = bins mod 48
    ADC_min = swfo_stis_log_decomp(log_adc)
    ADC_max = swfo_stis_log_decomp(loag_adc+1)
    DEL_ADC = ADC_max - ADC_min
    del_energy = DEL_ADC * kev_per_adc
    energy = (ADC_max + Adc_min)/2. * kev_per_adc + kev_dead_layer
    cal.geom = .1  * del_energy
    bad = where(energy lt 25.,/null)
    cal.geom[bad] = !values.f_nan
    stis_master.cal  = cal
    
  endif
  
  
  
  return,stis_master.cal
    
end

