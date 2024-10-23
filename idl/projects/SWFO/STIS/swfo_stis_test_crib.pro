;  sample crib sheet
;  
;  

;Loading data
;


pro swfo_stis_nse_metric
  get_data,'swfo_stis_nse_SIGMA',ptr=dd,dlim=lim
  dat = dd.ddata.array
  ndat = n_elements(dat.time)
  raw_hist = reform(dat.histogram,10,6,ndat)
  metric = fltarr(6,ndat)
  for det=0,5 do begin
    h = reform( raw_hist[*,det,*] )
    metric[det,*] = ( h[0,*] + h[9,*] ) / total(h, 1)
  endfor

  store_data,'swfo_stis_nse_METRIC' ,dat.time,transpose(metric),dlim = lim
end



defsysv,/test,'!stis',dictionary()


;swfo_stis_load,reader=rdr,file='cmblk',station='Ball2',tr=24
swfo_stis_load,reader=rdr,file='cmblk',station='Ball2',trange=['2024 9 14 0','2024 9 16']


; Plotting data
; 
swfo_stis_tplot,'wheels'
swfo_stis_tplot,'noise2',add=99


!stis.pngname = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/plot'






; clear tplot variables:
;swfo_apdat_info,/clear

end
