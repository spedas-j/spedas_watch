;  sample crib sheet
;  
;  

;Loading data
;
defsysv,/test,'!stis',dictionary()


swfo_stis_load,reader=rdr,file='cmblk',station='Ball2',tr=24


; Plotting data
; 
swfo_stis_tplot,'wheels'
swfo_stis_tplot,'noise2',add=99


!stis.pngname = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/plot'



; clear tplot variables:
swfo_apdat_info,/clear

end
