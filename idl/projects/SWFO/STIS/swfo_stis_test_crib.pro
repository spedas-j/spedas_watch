;  sample crib sheet
;  
;  

;Loading data
;
swfo_stis_load,reader=rdr,file='cmblk',station='Ball',tr=24


; Plotting data
; 
swfo_stis_tplot,'sc'
swfo_stis_tplot,'tv',/add





; clear tplot variables:
swfo_apdat_info,/clear

