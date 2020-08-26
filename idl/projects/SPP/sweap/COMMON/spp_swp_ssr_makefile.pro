; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-24 21:48:37 -0700 (Mon, 24 Aug 2020) $
; $LastChangedRevision: 29073 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_ssr_makefile.pro $
; $ID: $
;20180524 Ali
;20180527 Davin

pro spp_swp_ssr_makefile,trange=trange_full,all=all,type=type,finish=finish,load_ssr=load_ssr, $
  make_cdf=make_cdf,make_ql=make_ql,make_sav=make_sav,load_sav=load_sav,verbose=verbose,reset=reset,sc_files=sc_files, $
  ssr_format=ssr_format,mtime_range=mtime_range,make_tplotvar=make_tplotvar,ssr_prefix=ssr_prefix

  if keyword_set(all) then trange_full = [time_double('2018-10-3'),systime(1)] else trange_full = timerange(trange_full)

  t0=systime(1)
  res = 86400L
  daynum = round(timerange(trange_full)/res)
  nd = daynum[1]-daynum[0]
  trange = res* double(daynum) ; round to days
  output_prefix ='psp/data/sci/sweap/'
  sav_format=output_prefix+'.sav/apids/$NAME$/YYYY/MM/DD/psp_swp_$NAME$_YYYYMMDD_'
  ql_dir=output_prefix+'swem/ql/'
  linkname=output_prefix+'.hidden/.htaccess'
  if ~keyword_set(ssr_prefix) then begin
    ssr_prefix='psp/data/sci/MOC/SPP/data_products/ssr_telemetry/'
    ssr_prefix='psp/data/sci/sweap/raw/SSR/'
  endif
  if ~isa(ssr_format,/string) then ssr_format = 'YYYY/DOY/*_?_E?'
  if keyword_set(sc_files) then ssr_format = 'YYYY/DOY/*_?_FP'
  if ~isa(make_sav) then make_sav=0
  tr = timerange(trange_full)

  if keyword_set(load_ssr) || make_sav eq 1 then begin
    ssr_files=spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix,verbose=verbose)
    if keyword_set(mtime_range) then begin
      fi=file_info(ssr_files)
      mtrge=time_double(mtime_range)
      w=where(fi.mtime ge mtrge[0],/null)
      fi=fi[w]
      if n_elements(mtrge) ge 2 then begin
        w=where(fi.mtime lt mtrge[1],/null)
        fi=fi[w]
      endif
      ssr_files=fi.name
    endif
    if keyword_set(load_ssr) then spp_ssr_file_read,ssr_files,/sort_flag,/finish,no_init = ~keyword_set(reset)
  endif

  if keyword_set(load_sav) then begin ;loads sav files 
    sav_files=spp_file_retrieve(ssr_format+'.sav',trange=tr,/daily_names,prefix=output_prefix+'.sav/ssr/',/valid_only,verbose=verbose)
    if ~keyword_set(sav_files) then dprint,'No .sav files found!'
    if make_sav eq 2 then begin ;make apid specific daily sav files
      foreach sav_file,sav_files do begin
        spp_apdat_info,/reset
        spp_apdat_info,file_restore=sav_file
        spp_swp_apdat_init,/reset
        if keyword_set(type) then aps=spp_apdat(type) else aps = [spp_apdat('sp[abi]_*'),spp_apdat('swem_*'),spp_apdat('wrp_*'),spp_apdat('spc_*')]
        foreach a,aps do a.sav_makefile,sav_format=sav_format+file_basename(sav_file)
      endforeach
    endif else begin
      foreach sav_file,sav_files do spp_apdat_info,file_restore=sav_file
      del_data,'spp_*'
      spp_swp_apdat_init,/reset
      spp_apdat_info,finish=finish,/all,/sort_flag
    endelse
  endif

  if make_sav eq 1 then begin ;creates sav files with one-to-one correspondence with ssr files
    foreach ssr_file,ssr_files do begin
      sav_file=root_data_dir()+output_prefix+'.sav/ssr/'+(ssr_file).substring(-24)+'.sav' ;substring is preferred here. strsub may fail b/c ssr_prefix can change!
      if (file_info(ssr_file)).mtime le (file_info(sav_file)).mtime then continue
      file_mkdir2,file_dirname(sav_file)
      spp_apdat_info,/reset
      spp_swp_apdat_init,/reset
      spp_ssr_file_read,ssr_file
      spp_apdat_info,file_save=sav_file,/compress
      if keyword_set(type) then aps=spp_apdat(type) else aps = [spp_apdat('sp[abi]_*'),spp_apdat('swem_*'),spp_apdat('wrp_*'),spp_apdat('spc_*')]
      foreach a,aps do a.sav_makefile,sav_format=sav_format+file_basename(sav_file)
    endforeach
    ;save,file=sav_file+'.code',/routines,/verbose
  endif

  if keyword_set(make_tplotvar) then spp_swp_tplot,setlim=2

  if keyword_set(make_cdf) then begin ;make cdf files
    cdf_suffix='/L1/$NAME$/YYYY/MM/psp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
    spp_swp_apdat_init,/reset
    spp_apdat_info,'swem_*',cdf_pathname = output_prefix+'swem'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'sp[ab]_*',cdf_pathname = output_prefix+'spe'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spi_*',cdf_pathname = output_prefix+'spi'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spc_*',cdf_pathname = output_prefix+'spc2'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'wrp_*',cdf_pathname = output_prefix+'swem'+cdf_suffix,cdf_linkname= linkname
    if keyword_set(type) then aps=spp_apdat(type) else aps = [spp_apdat('sp[abi]_*'),spp_apdat('swem_*'),spp_apdat('wrp_*'),spp_apdat('spc_*')]
    for day=daynum[0],daynum[1] do begin ;loop over days
      trdaily = double(day * res)
      trange = trdaily + [0,1]*res
      dprint,dlevel=2,verbose=verbose,'Time: '+strjoin("'"+time_string(trange)+"'",' to ')
      if make_cdf eq 2 then foreach a,aps do a.cdf_makefile,trange=trange ;makes cdf after loading all_apdat from ssr or sav files
      if make_cdf eq 1 then begin ;makes cdf from apid specific daily sav files
        foreach a,aps do begin
          sav_files=str_sub(sav_format+'*_?_E?.sav','$NAME$',a.name)
          sav_files=spp_file_retrieve(sav_files,trange=trange,/daily_names,/valid_only,verbose=verbose)
          cdf_file=time_string(trange[0],tformat=a.cdf_pathname)
          cdf_file=root_data_dir()+str_sub(cdf_file,'$NAME$',a.name)
          if max((file_info(sav_files)).mtime) le (file_info(cdf_file)).mtime then continue
          cdf=!null
          foreach sav_file,sav_files do begin
            dprint,'Restoring file: '+sav_file+' Size: '+strtrim((file_info(sav_file)).size/1e3,2)+' KB'
            restore,sav_file,verbose=verbose,/relax,/skip
            if obj_valid(cdf) then cdf.append,self else cdf=self
          endforeach
          cdf.sort
          cdf.cdf_linkname=linkname
          cdf.cdf_makefile,filename=cdf_file
        endforeach
      endif
    endfor
  endif

  if keyword_set(make_ql) then begin
    ql_names=['SWEM2','SE_SUM1','SI_SUM1']
    wi,size=[1200,800]
    nt = n_elements(ql_names)
    tlimit,trange
    for it=0L,nt-1 do begin ;loop over tplots
      pngpath=ql_dir+ql_names[it]+'/YYYY/MM/spp_ql_'+ql_names[it]+'_YYYYMMDD'
      pngfile=spp_file_retrieve(pngpath,trange=trdaily,/create_dir,/daily_names)
      spp_swp_tplot,ql_names[it],/setlim
      makepng,pngfile
    endfor
  endif
  dprint,'Finished in '+strtrim(systime(1)-t0,2)+' seconds on '+systime()

end
