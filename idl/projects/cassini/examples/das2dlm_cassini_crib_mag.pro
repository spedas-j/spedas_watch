;+
; PRO:  das2dlm_cassini_crib_mag
;
; Description:
;   A crib sheet demonstrates how to load and plot Cassini data
;   Note, it requres das2dlm library
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-01 17:26:54 -0700 (Mon, 01 Jun 2020) $
; $Revision: 28752 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/examples/das2dlm_cassini_crib_mag.pro $
;-

;; Load the mag data and display the loaded tplot variable
das2dlm_load_cassini_mag_mag, trange=['2013-01-01', '2013-01-02']

;tplot_names
;stop

; Plot mag data 
tplot, 'cassini_mag_B_mag_01'

end