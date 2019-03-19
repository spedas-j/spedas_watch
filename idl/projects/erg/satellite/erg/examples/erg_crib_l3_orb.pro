;+
; PROGRAM: erg_crib_l3_orb
;   This is an example crib sheet that will load orbit L3 data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;   IDL> .run erg_crib_l3_orb
;
; NOTE: See the rules of the road.
;
; Written by: Tzu-Fang Chang, Aug. 28, 2018
;             ERG Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; Initialize the user environmental variables for ERG
erg_init

; set the date and duration (in days)
timespan, '2017-04-04'

; load ERG orbit L3 data (using OP77Q model)
erg_load_orb,level='l3'

; view the loaded data names
tplot_names

; Plot Spacecraft positions mapped onto the magnetic equator &
; Magnetic filed at spacecraft position
tplot,['erg_orb_l3_pos_eq_op','erg_orb_l3_pos_blocal_op']

; Plot McIlwain L (Lm) parameter for different pitch angles &
; Roederer L (L-star) parameter for different pitch angles
tplot,['erg_orb_l3_pos_lmc_op','erg_orb_l3_pos_lstar_op']

end

