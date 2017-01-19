;+
; PROCEDURE:
;       mms_feeps_remove_bad_data
;
; PURPOSE:
;       Removes bad eyes, bad lowest energy channels and corrects energy bin centers
;       based on data from Drew Turner, 1/17/2017
;
; NOTES:
;       This procedure should be called prior to any other routines that 
;       work on the FEEPS data
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-01-18 14:41:24 -0800 (Wed, 18 Jan 2017) $
; $LastChangedRevision: 22623 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_remove_bad_data.pro $
;-



pro mms_feeps_remove_bad_data

  ; electrons first, remove bad eyes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 1. BAD EYES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  First, here is a list of the EYES that are bad, we need to make sure these 
;  data are not usable (i.e., make all of the counts/rate/flux data from these eyes NAN). 
;  These are for all modes, burst and survey:

;  MMS1:
;  Top Eyes: None (all good)
;  Bottom Eyes: 1

  vars = tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_1')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_1')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_1')
  
;  MMS2:
;  Top Eyes: 5
;  Bottom Eyes: None (all good)
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_count_rate_sensorid_5')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_intensity_sensorid_5')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_counts_sensorid_5')
  
 
;  MMS3: 
;  Top Eyes: 2, 12
;  Bottom Eyes: 2, 5
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_count_rate_sensorid_2')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_intensity_sensorid_2')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_counts_sensorid_2')
  
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_count_rate_sensorid_12')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_intensity_sensorid_12')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_counts_sensorid_12')
  
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_2')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_2')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_2')

  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_5')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_5')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_5')

;  MMS4:
;  Top Eyes: 1, 2
;  Bottom Eyes: 2, 4, 5, 10, 11
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_count_rate_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_intensity_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_counts_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_count_rate_sensorid_2')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_intensity_sensorid_2')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_counts_sensorid_2')
  
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_2')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_2')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_2')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_4')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_4')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_4')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_5')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_5')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_5')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_10')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_10')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_10')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_11')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_11')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_11')

; now for ions,
;  MMS1:
;  Top Eyes: None (all good)
;  Bottom Eyes: None (all good)
;
;  MMS2:
;  Top Eyes: 7
;  Bottom Eyes: 7
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_top_count_rate_sensorid_7')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_top_intensity_sensorid_7')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_top_counts_sensorid_7')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_7')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_intensity_sensorid_7')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_counts_sensorid_7')
  
;  MMS3:
;  Top Eyes: None (all good)
;  Bottom Eyes: None (all good)
;  
;  MMS4:
;  Top Eyes: 7
;  Bottom Eyes: None (all good)
  append_array, vars, tnames('mms4_epd_feeps_*_l2_ion_top_count_rate_sensorid_7')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_ion_top_intensity_sensorid_7')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_ion_top_counts_sensorid_7')

  for var_idx=0, n_elements(vars)-1 do begin
    get_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*] = !values.d_nan
      store_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 2. BAD LOWEST E-CHANNELS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Next, these eyes have bad first channels (i.e., lowest energy channel, E-channel 0 in IDL indexing).  
; Again, these data (just the counts/rate/flux from the lowest energy channel ONLY!!!) 
; should be hardwired to be NAN for all modes (burst and both types of survey).  
; The eyes not listed here or above are ok though... so once we do this, we can actually start 
; showing the data down to the lowest levels (~33 keV), meaning we'll have to adjust the hard-coded 
; ylim settings in SPEDAS and the SITL software:
;   
;    MMS1:
;    Top Eyes: None (all good)
;    Bottom Eyes: 2, 3, 4, 5, 9, 11, 12
  vars = tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_2')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_2')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_2')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_3')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_3')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_3')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_4')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_4')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_4')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_5')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_5')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_5')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_9')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_9')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_9')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_11')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_11')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_11')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_12')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_intensity_sensorid_12')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_electron_bottom_counts_sensorid_12')
;    
;    MMS2: 
;    Top Eyes: 2, 12
;    Bottom Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12

  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_count_rate_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_intensity_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_counts_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_count_rate_sensorid_12')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_intensity_sensorid_12')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_top_counts_sensorid_12')
  
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_1')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_1')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_1')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_2')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_3')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_3')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_3')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_4')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_4')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_4')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_5')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_5')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_5')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_9')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_9')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_9')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_10')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_10')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_10')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_11')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_11')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_11')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_12')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_intensity_sensorid_12')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_electron_bottom_counts_sensorid_12')

;    MMS3:
;    Top Eyes: 5, 10
;    Bottom Eyes: 1, 9, 10, 11
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_count_rate_sensorid_5')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_intensity_sensorid_5')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_counts_sensorid_5')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_count_rate_sensorid_10')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_intensity_sensorid_10')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_top_counts_sensorid_10')
  
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_1')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_1')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_1')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_9')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_9')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_9')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_10')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_10')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_10')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_11')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_intensity_sensorid_11')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_electron_bottom_counts_sensorid_11')

;    MMS4: 
;    Top Eyes: 3
;    Bottom Eyes: 1, 3, 9, 12
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_count_rate_sensorid_3')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_intensity_sensorid_3')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_top_counts_sensorid_3')
  
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_1')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_3')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_3')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_3')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_9')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_9')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_9')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_count_rate_sensorid_12')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_intensity_sensorid_12')
  append_array, vars, tnames('mms4_epd_feeps_*_l2_electron_bottom_counts_sensorid_12')


  ; and now ions:
;  Next, these eyes have bad first and some bad second channels (i.e., lowest energy channel, 
;  E-channel 0 in IDL indexing and possible E-channel 1).  Again, these data (just the 
;  counts/rate/flux from the lowest 1 to 2 energy channels ONLY) should be hardwired 
;  to be NAN for all modes (burst and both types of survey).  The eyes not listed here or 
;  above are ok though... so once we do this, we can actually start showing the data down to the 
;  lowest levels, meaning we'll have to adjust the hard-coded ylim settings in SPEDAS and the SITL software:
;  
;  MMS1:
;  Top Eyes: 6
;  Bottom Eyes: 7, 8
;  
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_top_count_rate_sensorid_6')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_top_intensity_sensorid_6')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_top_counts_sensorid_6')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_7')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_intensity_sensorid_7')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_counts_sensorid_7')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_8')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_intensity_sensorid_8')
  append_array, vars, tnames('mms1_epd_feeps_*_l2_ion_bottom_counts_sensorid_8')

;  MMS2: 
;  Top Eyes: 8 (For Eye T8, both channels 1 AND 2 are bad, 0 and 1 in IDL indexing!)
;  Bottom Eyes: 6, 8
  vars_bothchans = tnames('mms2_epd_feeps_*_l2_ion_top_count_rate_sensorid_8')
  append_array, vars_bothchans, tnames('mms2_epd_feeps_*_l2_ion_top_intensity_sensorid_8')
  append_array, vars_bothchans, tnames('mms2_epd_feeps_*_l2_ion_top_counts_sensorid_8')

  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_6')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_intensity_sensorid_6')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_counts_sensorid_6')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_8')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_intensity_sensorid_8')
  append_array, vars, tnames('mms2_epd_feeps_*_l2_ion_bottom_counts_sensorid_8')
  
  
;  
;  MMS3:
;  Top Eyes: 6, 7
;  Bottom Eyes: None (all good)
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_count_rate_sensorid_6')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_intensity_sensorid_6')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_counts_sensorid_6')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_count_rate_sensorid_7')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_intensity_sensorid_7')
  append_array, vars, tnames('mms3_epd_feeps_*_l2_ion_top_counts_sensorid_7')
;  
;  MMS4: 
;  Top Eyes: None (6 and 8 good)
;  Bottom Eyes: 6 (For Eye B6, both channels 1 AND 2 are bad, 0 and 1 in IDL indexing!)
  append_array, vars_bothchans, tnames('mms4_epd_feeps_*_l2_ion_bottom_count_rate_sensorid_6')
  append_array, vars_bothchans, tnames('mms4_epd_feeps_*_l2_ion_bottom_intensity_sensorid_6')
  append_array, vars_bothchans, tnames('mms4_epd_feeps_*_l2_ion_bottom_counts_sensorid_6')

  ; the following sets the first energy channel to NaN
  for var_idx=0, n_elements(vars)-1 do begin
    get_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*, 0] = !values.d_nan ; remove the first energy channel
      store_data, vars[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  
  ; the following sets the first and second energy channels to NaNs
  for var_idx=0, n_elements(vars_bothchans)-1 do begin
    get_data, vars_bothchans[var_idx], data=bad, dlimits=dl, limits=l
    if is_struct(bad) then begin
      bad.Y[*, 0] = !values.d_nan ; remove the first energy channel
      bad.Y[*, 1] = !values.d_nan ; remove the second energy channel
      store_data, vars_bothchans[var_idx], data=bad, dlimits=dl, limits=l
    endif
  endfor
  

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 3. CORRECTED E-CHANNEL EQUIVALENT ENERGIES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Last, here are the energy shifts that we need to apply to the current ELECTRON 
  ; energies listed in the CDF files.  These shifts should be applied to the energy 
  ; bin centers for ALL ELECTRON EYES on each spacecraft.  
  ; These are positive shifts (i.e., Enew = Eold + Ecorr) if Ecorr listed is positive; 
  ; they are negative shifts (i.e., Enew = Eold - Ecorr) if Ecorr listed is negative.  
  ; For those equations, Eold is the original energy array (E0, E1, E2...E14) in units of
  ; keV and Enew is the corrected version of the arrays in keV using the factors listed below.


  ; old values, taken from intensity spectra for 12/15/15 L2 electron data downloaded on 1/18/17
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
                  200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d, 575.80000d]
;  MMS1:
;  Ecorr = +14 keV
  mms1_energies = mms_energies+14d
  mms1_vars = tnames('mms1_epd_feeps_*_l2_electron_*_count_rate_sensorid_*')
  append_array, mms1_vars, tnames('mms1_epd_feeps_*_l2_electron_*_counts_sensorid_*')
  append_array, mms1_vars, tnames('mms1_epd_feeps_*_l2_electron_*_intensity_sensorid_*')
  
  for var_idx=0, n_elements(mms1_vars)-1 do begin
    get_data, mms1_vars[var_idx], data=d, dlimits=dl, limits=l
    if is_struct(d) then store_data, mms1_vars[var_idx], data={x: d.X, y: d.Y, v: mms1_energies}, dlimits=dl, limits=l
  endfor

;  MMS2:
;  Ecorr = -1 keV
  mms2_energies = mms_energies-1d
  mms2_vars = tnames('mms2_epd_feeps_*_l2_electron_*_count_rate_sensorid_*')
  append_array, mms2_vars, tnames('mms2_epd_feeps_*_l2_electron_*_counts_sensorid_*')
  append_array, mms2_vars, tnames('mms2_epd_feeps_*_l2_electron_*_intensity_sensorid_*')
  
  for var_idx=0, n_elements(mms2_vars)-1 do begin
    get_data, mms2_vars[var_idx], data=d, dlimits=dl, limits=l
    if is_struct(d) then store_data, mms2_vars[var_idx], data={x: d.X, y: d.Y, v: mms2_energies}, dlimits=dl, limits=l
  endfor
  
;  MMS3: 
;  Ecorr = -3 keV
  mms3_energies = mms_energies-3d
  mms3_vars = tnames('mms3_epd_feeps_*_l2_electron_*_count_rate_sensorid_*')
  append_array, mms3_vars, tnames('mms3_epd_feeps_*_l2_electron_*_counts_sensorid_*')
  append_array, mms3_vars, tnames('mms3_epd_feeps_*_l2_electron_*_intensity_sensorid_*')
  
  for var_idx=0, n_elements(mms3_vars)-1 do begin
    get_data, mms3_vars[var_idx], data=d, dlimits=dl, limits=l
    if is_struct(d) then store_data, mms3_vars[var_idx], data={x: d.X, y: d.Y, v: mms3_energies}, dlimits=dl, limits=l
  endfor

;  MMS4:
;  Ecorr = -3 keV
  mms4_energies = mms_energies-3d
  mms4_vars = tnames('mms4_epd_feeps_*_l2_electron_*_count_rate_sensorid_*')
  append_array, mms4_vars, tnames('mms4_epd_feeps_*_l2_electron_*_counts_sensorid_*')
  append_array, mms4_vars, tnames('mms4_epd_feeps_*_l2_electron_*_intensity_sensorid_*')
  
  for var_idx=0, n_elements(mms4_vars)-1 do begin
    get_data, mms4_vars[var_idx], data=d, dlimits=dl, limits=l
    if is_struct(d) then store_data, mms4_vars[var_idx], data={x: d.X, y: d.Y, v: mms4_energies}, dlimits=dl, limits=l
  endfor


end