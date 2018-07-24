;20180524 Ali
;20180527 Davin

pro spp_swp_ssr_makefile,names=names,sav_path=sav_path,ql_dir=ql_dir,init=init,trange=trange0,ptp_path=ptp_path,ssr_prefix=ssr_prefix

 ; @idl_startup
 
 output_prefix = 'spp/data/sci/sweap/prelaunch/test5/SSR/'

  if ~keyword_set(ssr_input_prefix) then ssr_input_prefix='spp/data/sci/MOC/SPP_IT/data_products/ssr_telemetry/'
  ssr_format = 'YYYY/DOY/*_?_EA'
  
  idlsav_format=output_prefix+'sav/YYYY/MM/spp_swp_L1_YYYYMMDD.sav'

  ql_dir = output_prefix+'ql/'
  
  make_cdf  =1

  if not keyword_set(trange0) then begin
    trange0 = ['2020-1-197','2020-1-204']
    ;    trange0 = [time_double('2018-3-7'),time_double('2018-3-10')] ;testing at goddard
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
    timespan,tr
    spp_swp_apdat_init,/reset
    
    savfile = spp_file_retrieve(idlsav_format,trange=tr,/daily_names)
    if  file_test( savfile ) && 0 then begin
      spp_apdat_info,file_restore=savfile
      spp_apdat_info,/finish
    endif else begin
      ssrfiles = spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_input_prefix)
      if ~keyword_set(ssrfiles) then continue
      store_data,'*',/del
      spp_ssr_file_read, ssrfiles
      if keyword_set(idlsav_format) then begin
        savfile=spp_file_retrieve(idlsav_format,trange=tr,/create_dir,/daily_names)
        spp_apdat_info,file_save=savfile,/compress
      endif
    endelse

    if keyword_set(ql_dir) then begin
      ;      timespan,tr
      tlimit,/full
      for it=0L,nt-1 do begin ;loop over tplots
        pngpath=ql_dir+names[it]+'/YYYY/MM/spp_ql_'+names[it]+'_YYYYMMDD'
        pngfile=spp_file_retrieve(pngpath,trange=tr,/create_dir,/daily_names)
        window,xsize=1200,ysize=800
        spp_swp_tplot,names[it],/setlim
        makepng,pngfile
      endfor
    endif

    
    if keyword_set(make_cdf) then begin
      if 1 then begin  ; make cdf files
;        cdf_pathformat = output_prefix+'cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_dig_hkp',cdf_pathname = output_prefix+'swem/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_ana_hkp',cdf_pathname = output_prefix+'swem/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_event_log',cdf_pathname = output_prefix+'swem/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_timing',cdf_pathname = output_prefix+'swem/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spa_hkp',cdf_pathname = output_prefix+'spanae/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spb_hkp',cdf_pathname = output_prefix+'spanbe/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spi_hkp',cdf_pathname = output_prefix+'spanai/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spi_tof',cdf_pathname = output_prefix+'spanai/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spi_rates',cdf_pathname = output_prefix+'spanai/cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        ;    spp_apdat_info,'sp?_sf1',cdf_pathname = cdf_pathformat

      endif
      spp_apdat_info,/make_cdf,/print
    endif
    
    
  endfor

end