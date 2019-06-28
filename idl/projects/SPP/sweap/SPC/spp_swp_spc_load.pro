; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-06-27 10:21:16 -0700 (Thu, 27 Jun 2019) $
; $LastChangedRevision: 27386 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $


pro      spp_swp_spc_load_extra,prefix=prefix,nul_bad=nul_bad,extras=extras,name_array=name_array

  type = 'l3i'
  if not keyword_set(prefix) then prefix  = 'psp_swp_spc_'+type+'_'
 
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
    extras = 1
  endif
  extras = 1
  if keyword_set(extras) then begin
    mass = 1836.*511000./(299792.^2)
    rotmat_sc_spi = [[0.0000000, 0.0000000, 1.0000000],[ -0.93969262, 0.34202014, 0.0000000],[ -0.34202014, -0.93969262, 0.0000000]]

    get_data,prefix+'wp_fit'  ,time,ww
    store_data,prefix+'Tp_fit' ,time,mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'vp_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_p_fit = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'wp_fit Tp_fit np_fit')]
    options,spc_p_fit ,colors='b',/default


    get_data,prefix+'wp1_fit'  ,time,ww
    store_data,prefix+'Tp1_fit' ,time,mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'vp1_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_p1_fit = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'wp1_fit Tp1_fit np1_fit')]
    options,spc_p1_fit ,colors='m',/default


    get_data,prefix+'w3_fit'  ,time,ww
    store_data,prefix+'T3_fit' ,time,mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'v3_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_p3_fit = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'w3_fit T3_fit n3_fit')]
    options,spc_p3_fit ,colors='r',psym=3,/default


    get_data,prefix+'wa_fit'  ,time,ww
    store_data,prefix+'Ta_fit' ,time,4*mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'va_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_pa_fit = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'wa_fit Ta_fit na_fit')]
    options,spc_pa_fit ,colors='g',psym=3,/default


    get_data,prefix+'wp_moment'  ,time,ww
    store_data,prefix+'Tp_moment' ,time,mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'vp_moment_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_p_mom = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'wp_moment Tp_moment np_moment')]
    options,spc_p_mom ,colors='b',/default
    
    name_array = [[spc_p_fit],[spc_p1_fit],[spc_p3_fit],[spc_pa_fit],[spc_p_mom]]
    store_data,'Density',data = reform(name_array[5,*])
    store_data,'Vthermal',data= reform(name_array[3,*])
    store_data,'Temperature',data=reform(name_array[4,*])
    store_data,'Velocity_mag',data = reform(name_array[0,*])
    store_data,'Velocity_theta',data = reform(name_array[2,*])
    store_data,'Velocity_phi',data = reform(name_array[1,*])
    
    options,'Density',yrange=[.1,500],ylog=1,/ystyle
    options,'Temperature',yrange=[0,200],/ystyle
    options,'Vthermal',yrange=[0,200],/ystyle
    options,'Velocity_theta',yrange=[-50,50.],constant=0.,/ystyle
    options,'Velocity_phi',yrange=[150.,200.],constant=180.,/ystyle
    options,'Velocity_mag',yrange=[150.,1000.],/ylog,/ystyle
;
;
;
;
;    get_data,prefix+'wp1_fit'  ,time,ww
;    store_data,prefix+'Tp1_fit' ,time,mass*ww^2,dlimit={colors:'m'}
;    options,prefix+'wp1_fit',colors='m'
;    options,prefix+'np1_fit',colors='m'
;
;    get_data,prefix+'w3_fit'  ,time,ww
;    options,prefix+'w3_fit',colors='y'
;    store_data,prefix+'T3_fit' ,time,mass*ww^2,dlimit={colors:'y'}
;    get_data,prefix+'wp_moment'  ,time,ww
;    options,prefix+'wp_moment',colors='g'
;    store_data,prefix+'Tp_moment' ,time,mass*ww^2,dlimit={colors:'g'}
;    get_data,prefix+'wa_fit'  ,time,ww
;    options,prefix+'wa_fit',colors='c'
;    store_data,prefix+'Ta_fit' ,time,4*mass*ww^2,dlimit={colors:'c'}
;    store_data,prefix+'Temp',data=prefix+strsplit('T3_fit Ta_fit Tp_fit Tp1_fit Tp_moment',/extract),dlimit={yrange:[0,100.]}
;    store_data,prefix+'Tspeed',data=prefix+strsplit('w3_fit wa_fit wp_fit wp1_fit wp_moment',/extract),dlimit={yrange:[0,400.]}
;    store_data,prefix+'Density',data=prefix+strsplit(/extract,'n3_fit na_fit np_fit np1_fit np_moment'),dlimit={yrange:[.1,500.],ylog:1}
;    name = rotate_data(prefix+'va_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
;    xyz_to_polar,/ph_0_360,name
;    options,name+['_mag','_phi','_th'],colors='m'
;    name = rotate_data(prefix+'vp_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
;    xyz_to_polar,/ph_0_360,name
;    options,name+['_mag','_phi','_th'],colors='y'
;    name = rotate_data(prefix+'vp1_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
;    xyz_to_polar,/ph_0_360,name
;    options,name+['_mag','_phi','_th'],colors='g'
;    name = rotate_data(prefix+'vp_moment_SC',rotmat_sc_spi,name='SPI',repname='_SC')
;    xyz_to_polar,/ph_0_360,name
;    options,name+['_mag','_phi','_th'],colors='c'
  endif
end




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
     spp_swp_spc_load_extra,prefix=prefix,nul_bad=nul_bad,extras=extras
   endif
end

