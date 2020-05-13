;+
; das2dlm_cassini_crib_mag.pro
;
; :Description:
; A crib sheet containing basic examples to demonstrate the loading
; and plotting Cassini data  
;
;-

;; Load the mag data and display the loaded tplot variable
das2dlm_load_cassini_mag_mag, trange=['2013-01-01', '2013-01-02']
tplot_names

stop

;; Plot as mag data 
tplot, 'cassini_mag_B_mag_01'

end