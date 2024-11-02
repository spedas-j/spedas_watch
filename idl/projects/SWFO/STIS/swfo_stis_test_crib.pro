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
  metric_max = max(metric,dimen=1)
  store_data,'swfo_stis_nse_METRIC_max' ,dat.time,metric_max,dlim = lim
end

if ~keyword_set(init) then begin
  
trange = ['2024 9 14 0','2024 9 21 6']
;trange = ['2024 9 20 8','2024 9 21 6']  ; 1 atmos test after TVAC

defsysv,/test,'!stis',dictionary()


;swfo_stis_load,reader=rdr,file='cmblk',station='Ball2',tr=24
swfo_stis_load,reader=rdr,file='cmblk',station='Ball2',trange=trange,/no_widget
init = 1
; Plotting data
;
swfo_apdat_info,/sort
swfo_stis_tplot,'wheels'
swfo_stis_tplot,'noise2',add=99
swfo_stis_nse_metric
tplot,'swfo_stis_nse_METRIC',add=1

endif




!stis.pngname = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/plot'


if 1 then begin
    get_data,'swfo_sc_xxx_IRU_BITS'
    
    ntimes = dimen2(ttimes)
    for i=0,ntimes-1 do begin
      tt = ttimes[*,i]
;      get_data,'swfo_sc_xxx_IRU_BITS',data = iru
       iru = tsample('swfo_sc_110xxx_IRU_BITS',tt)
       
       wheelspeed = tsample('swfo_sc_ WHEEL_RPM',tt,/average)
       wheeltemp  = tsample('swfo_sc_ TEMP',tt,/average)
       stis_metric = tsample('swfo_stis_nse_metric',tt,/average)
    endfor
  
endif



; clear tplot variables:
;swfo_apdat_info,/clear

end
