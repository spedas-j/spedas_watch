;+
; ELF FGM crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download data for 8/2/2015
date = '2019-01-05/00:00:00'
timespan,date,1,/day

;;    ===================================
;; 2) Select probe, datatype
;;    ===================================
probe = 'a'          ; currently on ELFIN A FGM data is available (B coming soon) 
datatype = 'fgs'    ; currently fgs (survey) data is the only type available
                     ; fast data will be added soon

elf_load_fgm, probes=probe, datatype=datatype
tplot, 'ela_fgs'
stop

; variables loaded so far
tplot_names
stop

; remove tplot variables created so far
del_data, 'el*'

end