;+
; PROGRAM: erg_crib_xep
;   This is an example crib sheet that will load XEP L2 data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_xep
;
; NOTE: See the rules of the road.
;      
;
; Written by: M. Teramoto, September 01, 2018
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedBy: c0004hori $
;   $LastChangedDate: 2018-09-02 18:35:51 +0900 (Sun, 02 Sep 2018) $
;   $LastChangedRevision: 582 $
;   $URL: https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/examples/erg_crib_xep.pro $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-06-01'

; load L2 XEP data
erg_load_xep
;and please enter uname and passwd

; view the loaded data names
tplot_names

;Change the OMNI flux range
zlim,'erg_xep_l2_FEDO_SSD',1e-1,1e4

; Plot E-t diagram
tplot,['erg_xep_l2_FEDO_SSD']


; Change line plot
options,'erg_xep_l2_FEDO_SSD',spec=0,ytitle='[/cm2-str-s-keV]'


;Change the Flux range
ylim,'erg_xep_l2_FEDO_SSD',1e-1,1e4
tplot,['erg_xep_l2_FEDO_SSD']

end
