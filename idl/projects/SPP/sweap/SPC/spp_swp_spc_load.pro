; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-02-04 10:35:37 -0800 (Mon, 04 Feb 2019) $
; $LastChangedRevision: 26541 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,files, L2=L2, trange=trange, type = type


   if not keyword_set(type) then type = 'l2i'
   
   Ltype = 'L'+strmid(type,1,1)

   pathname = 'psp/data/sci/sweap/spc/'+Ltype+'/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   prefix = 'psp_swp_spc_'+type+'_'
   cdf2tplot,files,prefix = prefix,verbose=1
   ylim,prefix+'*charge_flux_density',100.,4000.,1
   ylim,prefix+'*_current',100.,4000.,1
   Zlim,prefix+'*charge_flux_density',1.,100.,1
   zlim,prefix+'*_current',1.,100.,1
end
