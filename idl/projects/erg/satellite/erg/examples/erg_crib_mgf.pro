;+
; PROGRAM: erg_crib_mgf
;   This is an example crib sheet that will load ERG MGF magnetic field data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_mgf

; NOTE: See the rules of the road.
;       For more information, see http://ergsc.isee.nagoya-u.ac.jp/
;
; Written by: Y. Miyashita, Feb 10, 2017
;             ERG Science Center, ISEE, Nagoya University
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedBy: c0004hori $
;   $LastChangedDate: 2018-09-02 18:35:51 +0900 (Sun, 02 Sep 2018) $
;   $LastChangedRevision: 582 $
;   $URL: https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/examples/erg_crib_mgf.pro $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-03-27'

; load Level-2 8-s resolution data
erg_load_mgf, datatype='8sec'

; view the loaded data names
tplot_names

; plot Bx, By, and Bz in sm coordinate system
tplot, ['erg_mgf_l2_mag_8sec_sm']

; split vector data into each component
split_vec,'erg_mgf_l2_mag_8sec_sm'

tplot,['erg_mgf_l2_mag_8sec_sm','erg_mgf_l2_mag_8sec_sm_x','erg_mgf_l2_mag_8sec_sm_y','erg_mgf_l2_mag_8sec_sm_z'] 


end
