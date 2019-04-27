; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-26 15:38:42 -0700 (Fri, 26 Apr 2019) $
; $LastChangedRevision: 27104 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,files,  trange=trange, type = type,save=save


   if not keyword_set(type) then type = 'l3i'
   
   Ltype = 'L'+strmid(type,1,1)

   pathname = 'psp/data/sci/sweap/spc/'+Ltype+'/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   prefix = 'psp_swp_spc_'+type+'_'
   cdf2tplot,files,prefix = prefix,verbose=2
   
   if keyword_set(save) then begin
    loadcdfstr,filenames=files,vardata,novardata
    dummy = spp_data_product_hash('SPC_'+type,vardata)
   endif
   
   if type eq 'l2i' then begin
     ylim,prefix+'*charge_flux_density',100.,4000.,1,/default
     ylim,prefix+'*_current',100.,4000.,1, /default
     Zlim,prefix+'*charge_flux_density',1.,100.,1, /default
     zlim,prefix+'*_current',1.,100.,1    ,/default
   endif
   if type eq 'l3i' then begin
     
   endif
end

