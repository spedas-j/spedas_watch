; $LastChangedBy: ali $
; $LastChangedDate: 2020-04-01 23:43:46 -0700 (Wed, 01 Apr 2020) $
; $LastChangedRevision: 28477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_load.pro $
;
pro spp_swp_load,ssr=ssr,all=all,spe=spe,spi=spi,spc=spc,spxs=spxs,mag=mag,fld=fld,trange=trange,types=types,level=level,varformat=varformat,save=save

  t0 = systime(1)
  if keyword_set(all) then begin
    spe=1
    spi=1
    spc=1
    mag=1
    fld=1
  endif

  if keyword_set(spe) then spp_swp_spe_load,trange=trange,types=types,level=level,varformat=varformat
  if keyword_set(spi) then spp_swp_spi_load,trange=trange,types=types,level=level,varformat=varformat
  if keyword_set(spc) then spp_swp_spc_load,trange=trange,type=types,ltype=level,/nul
  if keyword_set(mag) then spp_swp_mag_load,trange=trange,type=types
  if keyword_set(fld) then spp_fld_load,trange=trange,type=types,level=level,varformat=varformat

  if keyword_set(ssr) then begin
    ssrfiles = spp_file_retrieve(/ssr,trange=trange)
    spp_ssr_file_read,ssrfiles
  endif

  if ~keyword_set(level) then level='L1'
  level=strupcase(level)
  if ~keyword_set(types) then types='all'
  if ~keyword_set(spxs) then spxs=['spa','spb','spi','swem']
  if ~keyword_set(varformat) then varformat='*'
  if varformat eq ' ' then varformat=[]

  if types[0] eq 'all' then begin
    types=['hkp','fhkp','tof','rates','events','ana_hkp','dig_hkp','crit_hkp']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1','2'] do foreach type3,['0','1','2','3','a'] do types=[types,type0+type1+type2+type3]
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1'] do types=[types,type0+type1+type2]
  endif
  if types[0] eq 'all_hkp' then types=['hkp','fhkp','ana_hkp','dig_hkp','crit_hkp']

  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/sweap/'

  tr=timerange(trange)
  foreach spx, spxs do begin
    foreach type,types do begin
      dir=spx+'/'+level+'/'+spx+'_'+type+'*/YYYY/MM/'
      fileformat=dir+'psp_swp_'+spx+'_'+type+'_'+level+'*_YYYYMMDD_v??.cdf'
      if type.substring(0,2) eq 'wrp' then begin ;wrapper file names don't include swem_*
        dir=spx+'/'+level+'/'+type+'/YYYY/MM/'
        fileformat=dir+'psp_swp_'+type+'_'+level+'*_YYYYMMDD_v??.cdf'
      endif
      dprint,fileformat,/phelp
      files=spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,/last_version,prefix=fileprefix,verbose=verbose)

      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        dummy=spp_data_product_hash(spx+'_'+type,vardata)
      endif

      ;; Do not load the files
      if keyword_set(no_load) then continue

      ;; Convert to TPLOT
      prefix='psp_swp_'+spx+'_'+type+'_'+level+'_'
      cdf2tplot,files,prefix=prefix,varformat=varformat,verbose=verbose
      spp_swp_qf,prefix=prefix
    endforeach
  endforeach

  dprint,'Finished in '+strtrim(systime(1)-t0,2)+' seconds on '+systime()
end
