;20180524 Ali

pro spp_swp_makefile,names=names,sav_path=sav_path,ql_dir=ql_dir,init=init,trange=trange0,ptp_path=ptp_path

  @idl_startup

  if ~keyword_set(ptp_path) then ptp_path='spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/swem/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'

  if keyword_set(init) then begin
    trange0 = [time_double('2018-1-1'),systime(1)]
    ;    trange0 = [time_double('2018-3-7'),time_double('2018-3-10')] ;testing at goddard
    if init lt 0 then trange0 = systime(1) + [init,0 ]*24L*3600
  endif else trange0 = timerange(trange0)

  res = 86400L
  daynum = round( timerange(trange0) /res )
  nd = daynum[1]-daynum[0]
  trange = res* double( daynum  ) ; round to days

  if ~keyword_set(names) then names=strlowcase(['CMDCTR','SE','SE_HV','SA_SUM','SA_HV','SB_HV','SC_HV','SE_LV',$
    ;      'SE_SPEC','SA_SPEC','SB_SPEC','SE_A_SPEC','SA_A_SPEC','SB_A_SPEC',$
    ;      'SI_RATE','SI_RATE1','SI_HV2','SI_MON','SI_HV','MANIP','SI_GSE','SI','SI_SCAN','SC','ACT','SI_COVER','SA_COVER','SB_COVER',$
    'SWEM','SWEM2','TIMING','TEMP','TEMPS','CRIT'])
  nt=n_elements(names)

  for i=0L,nd-1 do begin ;loop over days
    tr = trange[0] + [i,i+1] * res
    ptpfiles = spp_file_retrieve(ptp_path,trange=tr,/hourly_names,/valid_only)
    if ~keyword_set(ptpfiles) then continue
    store_data,'*',/del
    spp_ptp_file_read, ptpfiles

    if keyword_set(sav_path) then begin
      if sav_path eq 1 then sav_path='spp/data/sci/sweap/prelaunch/test/cal/sav/YYYY/MM/spp_socket_YYYYMMDD.sav'
      savfile=spp_file_retrieve(sav_path,trange=tr,/create_dir,/daily_names)
      spp_apdat_info,file_save=savfile,/compress
    endif

    if keyword_set(ql_dir) then begin
      if ql_dir eq 1 then ql_dir='spp/data/sci/sweap/prelaunch/test/cal/ql/'
      ;      timespan,tr
      for it=0L,nt-1 do begin ;loop over tplots
        pngpath=ql_dir+names[it]+'/YYYY/MM/spp_ql_'+names[it]+'_YYYYMMDD'
        pngfile=spp_file_retrieve(pngpath,trange=tr,/create_dir,/daily_names)
        window,xsize=1200,ysize=800
        spp_swp_tplot,names[it],/setlim
        tlimit,0,0
        makepng,pngfile
      endfor
    endif
  endfor

end