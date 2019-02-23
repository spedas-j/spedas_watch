;+
; ELF EPD crib sheet
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
date = '2018-12-23/00:00:00'
timespan,date,1,/day
tr = timerange()

;;    ===================================
;; 2) Select probe, datatype
;;    ===================================
probe = 'a'          ; currently on ELFIN, only A data is available for EPD (B coming soon)
datatype = 'pef'    ; currently pef (electron fast mode) data is the only type available, pif coming soon
elf_load_epd, probes=probe, datatype=datatype, level='l1', trange=tr
tplot, 'ela_pef'
stop

timespan, '2019-01-05'
tr = timerange()
elf_load_epd, probes='a', datatype='pef', trange=tr
tplot, 'ela_pef'
stop

; remove tplot variables created so far
del_data, 'ela_pef'

end