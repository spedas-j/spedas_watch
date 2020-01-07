; $LastChangedBy: ali $
; $LastChangedDate: 2020-01-06 16:23:26 -0800 (Mon, 06 Jan 2020) $
; $LastChangedRevision: 28170 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_ssr_makefile.pro $
; $ID: $
;20180524 Ali
;20180527 Davin

pro spp_swp_ssr_makefile,trange=trange_full,all=all,type=type,  $
  make_cdf=make_cdf,make_ql=make_ql,make_sav=make_sav,load_sav=load_sav,verbose=verbose,reset=reset,sc_files=sc_files,    $
  ssr_format=ssr_format, mtime_range=mtime_range,no_load=no_load,make_tplotvar=make_tplotvar

  if keyword_set(all) then trange_full = [time_double('2018-10-3'),systime(1)] else trange_full = timerange(trange_full)

  res = 86400L
  daynum = round(timerange(trange_full)/res)
  nd = daynum[1]-daynum[0]
  trange = res* double(daynum) ; round to days

  output_prefix = 'psp/data/sci/sweap/'
  ssr_prefix='psp/data/sci/MOC/SPP/data_products/ssr_telemetry/'
  ssr_prefix= 'psp/data/sci/sweap/raw/SSR/'
  linkname = output_prefix + '.hidden/.htaccess'
  if ~ isa(ssr_format,/string) then ssr_format = 'YYYY/DOY/*_?_E?'
  idlsav_format = output_prefix+'sav/YYYY/MM/spp_swp_L1_YYYYMMDD_$ND$Days.sav'
  idlsav_format = output_prefix+'sav/YYYY/DOY/*_?_??.sav'
  ql_dir = output_prefix+'swem/ql/'
  if keyword_set(sc_files) then ssr_format = 'YYYY/DOY/*_?_FP'

  tr = timerange(trange_full)
  if ~keyword_set(no_load) then begin
    ssr_files = spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix)  ; load all data over many days (full orbit)
    if keyword_set(mtime_range) then begin
      fi = file_info(ssr_files)
      mtrge = time_double(mtime_range)
      w= where(fi.mtime ge mtrge[0],/null)
      fi=fi[w]
      if n_elements(mtrge) ge 2 then begin
        w = where(fi.mtime lt mtrge[1],/null)
        fi=fi[w]
      endif
      ssr_files = fi.name
    endif

    if keyword_set(load_sav) then begin
      sav_files=spp_file_retrieve(idlsav_format,trange=tr,/daily_names,/valid_only)
      for i=0,n_elements(sav_files)-1 do spp_apdat_info,append_file=sav_files[i]
      spp_apdat_info,/finish,/all,/sort_flag
      return
    endif

    if keyword_set(make_sav) then begin
      for i=0,n_elements(ssr_files)-1 do begin
        spp_ssr_file_read,ssr_files[i]
        idlsav_format=output_prefix+'sav/'+(ssr_files[i]).substring(-24)+'.sav'
        savfile=spp_file_retrieve(idlsav_format,/create_dir)
        spp_apdat_info,file_save=savfile,/compress
      endfor
      ;save,file=sav_file+'.code',/routines,/verbose
    endif else begin
      spp_ssr_file_read,ssr_files,/sort_flag,/finish,no_init = ~keyword_set(reset)
    endelse
  endif

  if keyword_set(make_tplotvar) then spp_swp_tplot,setlim=2

  if keyword_set(make_cdf) then begin ;make cdf files
    cdf_suffix='/L1/$NAME$/YYYY/MM/psp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
    spp_apdat_info,'swem_*',cdf_pathname = output_prefix+'swem'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spa_*',cdf_pathname = output_prefix+'spa'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spb_*',cdf_pathname = output_prefix+'spb'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spi_*',cdf_pathname = output_prefix+'spi'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'spc_*',cdf_pathname = output_prefix+'spc2'+cdf_suffix,cdf_linkname= linkname
    spp_apdat_info,'wrp_*',cdf_pathname = output_prefix+'swem'+cdf_suffix,cdf_linkname= linkname

    for day=daynum[0],daynum[1] do begin ;loop over days
      trdaily = double(day * res)
      trange = trdaily + [0,1]*res
      dprint,dlevel=2,verbose=verbose,'Time: '+strjoin("'"+time_string(trange)+"'",' to ')

      if keyword_set(type) then aps=spp_apdat(type) else aps = [spp_apdat('sp[abi]_*'),spp_apdat('swem_*'),spp_apdat('wrp_*'),spp_apdat('spc_*')]
      foreach a,aps do a.cdf_makefile,trange=trange
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

end
