;+
; PROGRAM: erg_crib_xep_pre
;   This is an example crib sheet that will load Provisonal XEP data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_xep_pre
;
; NOTE: See the rules of the road.
;      
;
; Written by: M. Teramoto, August 25, 2017
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
;   $LastChangedRevision: 25628 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/xep/erg_crib_xep_pre.pro $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-04-01'

; load Provisonal XEP data
erg_load_xep_pre
;and please enter uname and passwd

; view the loaded data names
tplot_names

;Change the COUNT range
zlim,'erg_xepe_pre_COUNT',1e-1,1e4

; Plot E-t diagram
tplot,['erg_xep_pre_COUNT']


; Change line plot
options,'erg_xep_pre_COUNT',spec=0,ytitle='COUNT [count/s]'
;Change the COUNT range
ylim,'erg_xep_pre_COUNT',1e-1,1e4
tplot,['erg_xep_pre_COUNT']

end