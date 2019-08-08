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
;; 2) Select probe, datatype=electron
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


;;    ===================================
;; 3) Select probe, datatype=ion
;;    ===================================
timespan, '2018-12-22'
tr = timerange()
elf_load_epd, probes='a', datatype='pif', trange=tr
tplot, 'ela_pif'
stop


;;    ===================================
;; 4) Select probe, datatype=pef and pif
;;    ===================================
timespan, '2019-07-26'
tr = timerange()
elf_load_epd, probes='a', datatype=['pef','pif'], trange=tr
tplot, ['ela_pef', 'ela_pif']
stop


;;    ===================================
;; 5) Select probe, type raw
;;    ===================================
elf_load_epd, probes=['a','b'], datatype='pef', trange=tr, type='raw', suffix='_raw'
options, 'ela_pef_raw', labflag=1
tplot, 'ela_pef_raw'
stop


;;    ===================================
;; 6) Select probe, type calibrated (default)
;;    ===================================
timespan, '2019-01-05'
tr = timerange()
elf_load_epd, probes='a', datatype='pef', trange=tr, type='calibrated', suffix='_cal'
tplot, 'ela_pef_cal'
stop

;;    ===================================
;; 7) Select both probes and datatypes
;;    ===================================
timespan, '2019-07-26'
tr = timerange()
elf_load_epd, probes=['a','b'], datatype=['pef' ,'pif'], trange=tr
tplot, ['ela_pef','ela_pif']
stop

;;    ===================================
;; 7) Use no_download keyword
;;    ===================================
timespan, '2019-07-26'
tr = timerange()
elf_load_epd, probes=['a','b'], datatype=['pef' ,'pif'], trange=tr, /no_download
tplot, ['ela_pef','ela_pif']
stop


; remove tplot variables created so far
del_data, 'ela_p*f'

end