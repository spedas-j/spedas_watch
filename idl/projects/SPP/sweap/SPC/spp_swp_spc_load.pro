; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-02-05 16:17:41 -0800 (Tue, 05 Feb 2019) $
; $LastChangedRevision: 26558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,files,  trange=trange, type = type


   if not keyword_set(type) then type = 'l2i'
   
   Ltype = 'L'+strmid(type,1,1)

   pathname = 'psp/data/sci/sweap/spc/'+Ltype+'/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   prefix = 'psp_swp_spc_'+type+'_'
   cdf2tplot,files,prefix = prefix,verbose=1
   
   if type eq 'l2i' then begin
     ylim,prefix+'*charge_flux_density',100.,4000.,1,/default
     ylim,prefix+'*_current',100.,4000.,1, /default
     Zlim,prefix+'*charge_flux_density',1.,100.,1, /default
     zlim,prefix+'*_current',1.,100.,1    ,/default
   endif
   if type eq 'l3i' then begin
     
   endif
end
