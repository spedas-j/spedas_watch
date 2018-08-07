;+
;
; This crib sheet shows how to save MMS data loaded into tplot variables to a CDF file
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-08-06 11:34:01 -0700 (Mon, 06 Aug 2018) $
; $LastChangedRevision: 25587 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2cdf_crib.pro $
;-

trange = ['2015-10-16', '2015-10-17']

; load MMS data and get electron fluxes and pitch angles distributions 
mms_load_feeps, trange=trange, probe=1, datatype='electron', level='l2', /tt2000
mms_load_fgm, trange=trange, /tt2000

; /default keyword is required
; /tt2000 saves the TT2000 timestamps (note: this keyword is also required on the load routine calls)
tplot2cdf, /tt2000, /default, filename='cdf_file_with_tt2000_times', $
  tvars=['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', 'mms1_fgm_b_gsm_srvy_l2_bvec']

end