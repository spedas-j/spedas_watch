; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-06-12 01:49:56 -0700 (Wed, 12 Jun 2019) $
; $LastChangedRevision: 27333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,  trange=trange,type = type,files=files,no_load=no_load,save=save,load_labels=load_labels,nul_bad=nul_bad,ltype=ltype,rapidshare=rapidshare


   if keyword_set(rapidshare) then begin
    type = 'rapidshare'
    ltype = 'RAPIDSHARE'    
   endif
   
   if not keyword_set(type) then type = 'l3i'
  
   if not keyword_set(ltype) then ltype = 'L'+strmid(type,1,1)

   pathname = 'psp/data/sci/sweap/spc/'+Ltype+'/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   prefix = 'psp_swp_spc_'+type+'_'
   cdf2tplot,files,prefix = prefix,verbose=2,/all,load_labels=load_labels,tplotnames=tplotnames
     
   
;   if keyword_set(save) then begin
;    loadcdfstr,filenames=files,vardata,novardata,/time
;    dummy = spp_data_product_hash('SPC_'+type,vardata)
;   endif
   
   if type eq 'l2i' then begin
     ylim,prefix+'*charge_flux_density',100.,4000.,1,/default
     ylim,prefix+'*_current',100.,4000.,1, /default
     Zlim,prefix+'*charge_flux_density',1.,100.,1, /default
     zlim,prefix+'*_current',1.,100.,1    ,/default
   endif
   if type eq 'l3i' then begin
     ylim,prefix+'vp_moment_SC',-500,200,0    ,/default
     options,prefix+'vp_*_SC',colors='bgr'     ,/default
     options,prefix+'vp_*_RTN',colors='bgr'  ,/default
     options,prefix+'DQF',spec=1,zrange=[-3,2]
     if keyword_set(nul_bad) then begin
       get_data,prefix+'DQF',time,DQF
       w = where(DQF[*,0] ne 0,/null)
       for i= 0,n_elements(tplotnames)-1 do begin
          if tplotnames[i] eq prefix+'DQF' then continue
          get_data,tplotnames[i],ptr = ptr
           v = ptr.y
          ( *v )[w,*]  = !values.f_nan   ; Fill bad data with NANs
       endfor
       w = where(0)
     endif
   endif
end

