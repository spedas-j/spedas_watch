; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2019-02-04 10:49:07 -0800 (Mon, 04 Feb 2019) $
; $LastChangedRevision: 26542 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro $
; Created by Davin Larson 2018


pro spp_swp_spe_load,spxs=spxs,types=types,varformat=varformat,trange=trange,no_load=no_load,verbose=verbose

  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if ~keyword_set(types) then types = ['sf1', 'sf0']  ;,'st1','st0']   ; add archive when available

  fileprefix = 'psp/data/sci/sweap/'
  
  loc = orderedhash()
  loc['sf1'] = 'SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_32E_YYYYMMDD_v??.cdf'
  loc['sf0'] = 'SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_*_YYYYMMDD_v??.cdf'
  loc['hkp'] = 'SP?/L1/YYYY/MM/SP?_hkp/spp_swp_SP?_hkp_L1_YYYYMMDD_v??.cdf'
  
  ;test='http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/spa/L1/2018/09/spa_hkp/spp_swp_spa_hkp_L1_20180924_v00.cdf
  ;test                                  ='psp/data/sci/sweap/spa/L1/2018/10/spa_hkp/spp_swp_spa_hkp_20181004_v??.cdf
  vars = orderedhash()
  vars['sf1'] = 'EFLUX EMODE'
  vars['sf0'] = 'EFLUX EMODE THETA PHI ENERGY'
  vars['hkp'] = '*TEMP* *_BITS *_FLAG*'
  
  tr = timerange(trange)
  foreach spx, spxs do begin
    foreach type,types do begin
      fileformat = str_sub(loc[type],'SP?', spx)              ; instrument string substitution
      fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
      dprint,fileformat,/phelp                                   
      files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
      if keyword_set(no_load) then continue
      prefix = 'psp_swp_'+spx+'_'+type+'_'
      if keyword_set(varformat) then vfm = varformat else vfm=vars[type]
      cdf2tplot,files,prefix=prefix,varformat=vfm,verbose=verbose
      if type eq 'hkp' then begin
        continue
      endif
      ylim,prefix+'EFLUX',1.,10000.,1,/default
      Zlim,prefix+'*EFLUX',100.,2000.,1,/default

    endforeach
  endforeach

   
   
   
   
;   format = 'psp/data/sci/sweap/spa/L2/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L2_*_YYYYMMDD_v??.cdf'
;   files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
;   cdf2tplot,spa_files,prefix = prefix,varformat='EFLUX EMODE'

end
