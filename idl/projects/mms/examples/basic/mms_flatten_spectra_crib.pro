;+
; flatten_spectra crib sheet
;
; This crib sheet shows how to create spectra plots (flux vs. energy) at certain times using flatten_spectra
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-08-30 15:29:33 -0700 (Thu, 30 Aug 2018) $
; $LastChangedRevision: 25711 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_flatten_spectra_crib.pro $
;-

mms_load_fpi, probe=1, data_rate='brst', datatype=['des-moms'], trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip

; plot one or more spectra variables
tplot, ['mms1_des_energyspectr_omni_brst', $
        'mms1_des_energyspectr_par_brst', $
        'mms1_des_energyspectr_anti_brst', $
        'mms1_des_energyspectr_perp_brst']

; select the time on the time varying energy spectra figure 
flatten_spectra, /xlog, /ylog
stop

; specify the time via keyword instead of the mouse
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07'
stop

; use the samples keyword to average over a number of samples
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', samples=10
stop

; use the trange keyword to average over a time range
flatten_spectra, /xlog, /ylog, trange=['2015-10-16/13:06:50', '2015-10-16/13:07']
stop

; save the figure as a PNG file
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', filename='spectra', /png
stop

; save the figure as a postscript file
flatten_spectra, /xlog, /ylog, time='2015-10-16/13:07', filename='spectra', /postscript
stop

end