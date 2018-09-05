;+
; PROGRAM: erg_crib_lepe
;   This is an example crib sheet that will load LEP-e L2 omniflux data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;   IDL> .run erg_crib_lepe
;
; NOTE: See the rules of the road.
;
; Written by: Tzu-Fang Chang, Aug. 28, 2018
;             ERG Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedBy: c0084chang $
;   $LastChangedDate: 2018-09-02 23:46:02 +0900 (Sun, 02 Sep 2018) $
;   $LastChangedRevision: 583 $
;   $URL: https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/examples/erg_crib_lepe.pro $
;-

; Initialize the user environmental variables for ERG
erg_init

; set the date and duration (in days)
timespan, '2017-04-04'

; load LEP-e L2 omniflux data
erg_load_lepe

; view the loaded data names
tplot_names

; Plot E-t diagram
tplot,['erg_lepe_l2_omniflux_FEDO']

end

