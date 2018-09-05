;+
; PROGRAM: erg_crib_lepi
;   This is an example crib sheet that will load LEPI Level-2 data 
;   of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_lepi
;
; NOTE: See the rules of the road.
;      
;
; Written by: Y. Miyoshi, August 30, 2018
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;
;$LastChangedBy: c0004hori $ 
;$LastChangedDate: 2018-09-02 18:35:51 +0900 (Sun, 02 Sep 2018) $ 
;$LastChangedRevision: 582 $
;$URL: https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/examples/erg_crib_lepi.pro $ 
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-07-01'

; load Provisonal LEP-i data
erg_load_lepi_nml

; view the loaded data names
tplot_names

; Plot E-t diagram for H+, He+ and O+ ions
tplot,['erg_lepi_l2_omniflux_FPDO',$
       'erg_lepi_l2_omniflux_FHEDO',$
       'erg_lepi_l2_omniflux_FODO']

end

