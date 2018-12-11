; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-09 21:25:16 -0800 (Sun, 09 Dec 2018) $
; $LastChangedRevision: 26303 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,files, L2=L2, trange=trange, type = type

   l2=1
   if not keyword_set(type) then type = 'l2i'
   pathname = 'psp/data/sci/sweap/spc/L2/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   prefix = 'psp_swp_spc_'+type+'_'
   cdf2tplot,files,prefix = prefix,verbose=1
   ylim,prefix+'*charge_flux_density',100.,4000.,1
   ylim,prefix+'*_current',100.,4000.,1
   Zlim,prefix+'*charge_flux_density',1.,100.,1
   zlim,prefix+'*_current',1.,100.,1
end
