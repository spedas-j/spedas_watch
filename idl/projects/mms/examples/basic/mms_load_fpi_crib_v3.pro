;+
; MMS FPI crib sheet
; mms_load_fpi_crib.pro
; 
; 
;  This version is meant to work with v3.0.0+ of the FPI CDFs
;  
;  
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-26 13:22:43 -0700 (Fri, 26 Aug 2016) $
; $LastChangedRevision: 21749 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fpi_crib_v3.pro $
;-

timespan, '2015-10-16', 1, /day
probe = '1'
datatype = ['des-moms', 'dis-moms'] ; DES/DIS moments file (contains moments, as well as spectra and pitch angle distributions)
level = 'l1b'
data_rate = 'fast'

mms_load_fpi, probes = probe, datatype = datatype, level = level, data_rate = data_rate, min_version='2.2.0'

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_dis_energyspectr_omni_fast', /add

; add the ion density
tplot, prefix+'_dis_numberdensity_fast', /add

; add the errorflag bars for ion data
tplot, prefix+'_dis_errorflags_fast_moms_flagbars', /add
;tplot, prefix+'_dis_errorflags_fast_moms_flagbars_full', /add

; and the electron density...
tplot, prefix+'_des_numberdensity_fast', /add

; add the errorflag bars for electron data
tplot, prefix+'_des_errorflags_fast_moms_flagbars', /add
;tplot, prefix+'_des_errorflags_fast_moms_flagbars_full', /add

stop

end
