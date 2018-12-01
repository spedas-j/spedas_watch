; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-11-30 15:11:19 -0800 (Fri, 30 Nov 2018) $
; $LastChangedRevision: 26215 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_ssr_makefile.pro $
; $ID: $
;20180524 Ali
;20180527 Davin

pro spp_swp_ssr_makefile,trange=trange_full,restore=restore,no_load=no_load
  
  login_info = get_login_info()
  test = login_info.user_name eq 'davin'
 test=1
  
  make_ql=1
  make_sav=0
  make_cdf=1

  output_prefix = 'spp/data/sci/sweap/prelaunch/test7/'
  ssr_prefix='spp/data/sci/MOC/SPP/data_products/ssr_telemetry/'
  ssr_format = 'YYYY/DOY/*_?_E?'
  idlsav_format=output_prefix+'sav/YYYY/MM/spp_swp_L1_YYYYMMDD.sav'
  ql_dir = output_prefix+'ql/'

  ;if not keyword_set(trange_full) then trange_full = [time_double('2018-8-30'),systime(1)] else trange_full = timerange(trange_full)
  if not keyword_set(trange_full) then begin
    trange_full = [time_double('2018-8-30'),systime(1)] 
  endif else begin
    trange_full = timerange(trange_full)
  endelse
  res = 86400L
  daynum = round( timerange(trange_full) /res )
  nd = daynum[1]-daynum[0]
  trange = res* double( daynum  ) ; round to days
  names=strlowcase(['CMDCTR','SE','SE_HV','SA_SUM','SA_HV','SB_HV','SC_HV','SE_LV',$
    'SE_SPEC','SA_SPEC','SB_SPEC','SE_A_SPEC','SA_A_SPEC','SB_A_SPEC',$
    'SI_RATE','SI_RATE1','SI_HV2','SI_MON','SI_HV','MANIP','SI_GSE','SI','SI_SCAN','SC','ACT','SI_COVER','SA_COVER','SB_COVER',$
    'SWEM','SWEM2','TIMING','TEMP','TEMPS','CRIT'])
  nt=n_elements(names)


  if keyword_set(test) then begin     ; newer method
    make_ql=0
    output_prefix = 'spp/data/sci/sweap/prelaunch/test6/'
    ssr_prefix='spp/data/sci/MOC/SPP/data_products/ssr_telemetry/'
    ssr_format = 'YYYY/DOY/*_?_E?'
    idlsav_format = output_prefix+'sav/YYYY/MM/spp_swp_L1_YYYYMMDD_$ND$Days.sav'
    tr = timerange(trange_full)
    sav_file=spp_file_retrieve(idlsav_format,trange=tr[0],/create_dir,/daily_names)
    str_replace, sav_file,'$ND$',strtrim(nd,2)
       
    if ~keyword_set(no_load) then begin
      if file_test(sav_file) and 0 then begin
        if keyword_set(restore) then begin
          del_data,'*'
          spp_apdat_info,file_restore=sav_file,/finish
        endif
      endif else begin
        ssr_files = spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix)  ; load all data over many days (full orbit)
        ;      spp_swp_apdat_init,/reset
        spp_ssr_file_read,ssr_files,/sort_flag
        if keyword_set(make_sav) then begin
          spp_apdat_info,file_save=sav_file,/compress
          save,file=sav_file+'.code',/routines,/verbose
        endif
      endelse
      
    endif
    
    for day=daynum[0],daynum[1] do begin ;loop over days
      trdaily = double(day * res)
      trange = trdaily + [0,1]*res
      if 0 then begin
        ssr_info = file_info(ssr_files)
        sav_info = file_info(sav_file)
        ssr_timestamp=max([ssr_info.mtime,ssr_info.ctime])
        sav_timestamp=sav_info.mtime
        if ssr_timestamp lt sav_timestamp then continue    ; skip if sav does not need to be regenerated
        
      endif
;      store_data,/delete,'*'
;      spp_swp_apdat_init,/reset
;      spp_ssr_file_read,ssr_files,/sort_flag


      if 0 then spp_apdat_info,file_restore=sav_file,/finish

      if keyword_set(make_ql) then begin
        wi,size=[1200,800]
        tplot,'APID'
        tlimit,trange
        for it=0L,nt-1 do begin ;loop over tplots
          pngpath=ql_dir+names[it]+'/YYYY/MM/spp_ql_'+names[it]+'_YYYYMMDD'
          pngfile=spp_file_retrieve(pngpath,trange=trdaily,/create_dir,/daily_names)
          spp_swp_tplot,names[it],/setlim
          makepng,pngfile
        endfor
      endif

      if keyword_set(make_cdf) then begin ;make cdf files
        cdf_pathformat = output_prefix+'cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_*',cdf_pathname = output_prefix+'swem/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        ;      spp_apdat_info,'swem_ana_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'swem_event_log',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'swem_timing',cdf_pathname = cdf_pathformat
        spp_apdat_info,'spa_*',cdf_pathname = output_prefix+'spa/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spb_*',cdf_pathname = output_prefix+'spb/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spi_*',cdf_pathname = output_prefix+'spi/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        ;      spp_apdat_info,'spa_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spb_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_tof',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_rates',cdf_pathname = cdf_pathformat
        ;    spp_apdat_info,'sp?_sf1',cdf_pathname = cdf_pathformat
        timespan,tr ;for cdf pathnames to work!
        
        dummy = {cdf_tools}   ; dummy statement to force compile of routine
        aps = spp_apdat('spa_s??')
        foreach a,aps do begin
          a.print
          a.makecdf,trange=trange   
        endforeach
;        spp_apdat_info,make_cdf=make_cdf,/print
      endif

    endfor
        
  endif else begin    ; Old method
    for i=0L,nd-1 do begin ;loop over days
      tr = trange[0] + [i,i+1] * res
      ssr_files = spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix)
      if total(file_test(/regular,ssr_files)) eq 0 then begin
        dprint,dlevel=2,'No ssr files found for '+time_string(tr[0])
        continue
      endif

      sav_file=spp_file_retrieve(idlsav_format,trange=tr,/create_dir,/daily_names)

      ssr_info = file_info(ssr_files)
      sav_info = file_info(sav_file)
      ssr_timestamp=max([ssr_info.mtime,ssr_info.ctime])
      sav_timestamp=sav_info.mtime
      if ssr_timestamp lt sav_timestamp then continue    ; skip if sav does not need to be regenerated

      store_data,/delete,'*'
      spp_swp_apdat_init,/reset
      spp_ssr_file_read,ssr_files,/sort_flag

      if keyword_set(make_sav) then spp_apdat_info,file_save=sav_file,/compress

      if 0 then spp_apdat_info,file_restore=sav_file,/finish

      if keyword_set(make_ql) then begin
        window,xsize=1200,ysize=800
        tplot,'APID'
        tlimit,0,0
        for it=0L,nt-1 do begin ;loop over tplots
          pngpath=ql_dir+names[it]+'/YYYY/MM/spp_ql_'+names[it]+'_YYYYMMDD'
          pngfile=spp_file_retrieve(pngpath,trange=tr,/create_dir,/daily_names)
          spp_swp_tplot,names[it],/setlim
          makepng,pngfile
        endfor
      endif

      if keyword_set(make_cdf) then begin ;make cdf files
        cdf_pathformat = output_prefix+'cdf/YYYY/MM/DD/spp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'swem_*',cdf_pathname = output_prefix+'swem/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        ;      spp_apdat_info,'swem_ana_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'swem_event_log',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'swem_timing',cdf_pathname = cdf_pathformat
        spp_apdat_info,'spa_*',cdf_pathname = output_prefix+'spa/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spb_*',cdf_pathname = output_prefix+'spb/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        spp_apdat_info,'spi_*',cdf_pathname = output_prefix+'spi/L1/YYYY/MM/$NAME$/spp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
        ;      spp_apdat_info,'spa_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spb_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_hkp',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_tof',cdf_pathname = cdf_pathformat
        ;      spp_apdat_info,'spi_rates',cdf_pathname = cdf_pathformat
        ;    spp_apdat_info,'sp?_sf1',cdf_pathname = cdf_pathformat
        timespan,tr ;for cdf pathnames to work!
        spp_apdat_info,make_cdf=make_cdf,/print
      endif

    endfor
    
  endelse


end