; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-10-28 14:04:41 -0700 (Wed, 28 Oct 2020) $
; $LastChangedRevision: 29306 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $


pro      spp_swp_spc_load_extra,prefix=prefix,nul_bad=nul_bad,extras=extras,name_array=name_array

  type = 'l3i'
  if not keyword_set(prefix) then prefix  = 'psp_swp_spc_'+type+'_'
 
  extras = 1
  if keyword_set(extras) then begin
    mass = 1836.*511000./(299792.^2)
    rotmat_sc_spi = [[0.0000000, 0.0000000, 1.0000000],[ -0.93969262, 0.34202014, 0.0000000],[ -0.34202014, -0.93969262, 0.0000000]]

    get_data,prefix+'wp_fit'  ,time,ww
    store_data,prefix+'Tp_fit' ,time,mass*ww^2   ;,dlimit={colors:'b'}
    vname = rotate_data(prefix+'vp_fit_SC',rotmat_sc_spi,name='SPI',repname='_SC')
    xyz_to_polar,/ph_0_360,vname
    spc_p_fit = [vname+['_mag','_phi','_th'],prefix+strsplit(/extract,'wp_fit Tp_fit np_fit')]
    options,spc_p_fit ,colors='c',/default


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
    
    name_array = [[spc_p_fit],[spc_p1_fit],[spc_p_mom],[spc_pa_fit],[spc_p3_fit]]
    store_data,'Density',data = reform(name_array[5,*])
    store_data,'Velocity_mag',data = reform(name_array[0,*])
    store_data,'Velocity_theta',data = reform(name_array[2,*])
    store_data,'Velocity_phi',data = reform(name_array[1,*])
    store_data,'Vthermal',data= reform(name_array[3,*])
    store_data,'Temperature',data=reform(name_array[4,*])
    
    options,'Density',yrange=[1,2000],ylog=1,/ystyle
    options,'Velocity_theta',yrange=[-50,50.],constant=0.,/ystyle
    options,'Velocity_phi',yrange=[150.,200.],constant=180.,/ystyle
    options,'Velocity_mag',yrange=[150.,1000.],/ylog,/ystyle
    options,'Vthermal',yrange=[0,200],/ystyle
    options,'Temperature',yrange=[0,200],/ystyle
  endif
end




pro spp_swp_spc_load,  trange=trange,type=type,files=files,no_load=no_load,save=save,load_labels=load_labels  $
  ,nul_bad=nul_bad,mask=mask,prefix=prefix,ltype=ltype,rapidshare=rapidshare,extras=extras,version=version,correct_time=correct_time


   if keyword_set(rapidshare) then begin
    type = 'rapidshare'
    ltype = 'RAPIDSHARE'    
   endif
   
   if not keyword_set(type) then type = 'l3i'
  
   if not keyword_set(ltype) then ltype = 'L'+strmid(type,1,1)

   pathname = 'psp/data/sci/sweap/spc/'+Ltype+'/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
   
   if type EQ 'l2e' then pathname = str_sub(pathname,'psp_swp_spc_','spp_swp_spc_')
   
   if keyword_set(version) then pathname = str_sub(pathname,'_v??','_'+version)
   
   files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names,verbose=2)
   if ~isa(prefix,/string) then  prefix = 'psp_swp_spc_'+type+'_'
   
   if  keyword_set(no_load) then return
   cdf2tplot,files,prefix = prefix,verbose=2,/all,load_labels=load_labels,tplotnames=tplotnames
   
   
   if keyword_set(correct_time) then begin
     ;     time_error = 2.28   ;  encounter 2 - crude estimate to account for timing error
     ;     time_error = -1.   ;  encounter 3 - crude estimate to account for timing error between FIELDS and SPC
     dprint,'Warning! making time correction!  Remove this code when corrected'
     dates  = time_double( ['2010-1-1','2018-8-1','2018-10-1','2018-11-30','2019-3-1','2019-5-1','2019-8-1','2019-12-1'])
     tshift= [  0.      ,    0.     ,     0.   ,    0       ,   -2.28   ,   -2.28   ,   1.    ,   1.            ]
     pointers = []
     for i = 0,n_elements(tplotnames)-1 do begin
       get_data,tplotnames[i],ptr=p
       pointers=[pointers,p.x]
     endfor
     pointers = pointers[uniq(pointers,sort(pointers))]
 ;    printdat,pointers
     dt = []
     for i=0,n_elements(pointers)-1 do begin
       p =pointers[i]
       delta_time = interp(tshift,dates,*p,/no_extrapolate)
       dt = minmax([dt,delta_time])
       *p += delta_time
     endfor
     dprint,'delta times: ',dt
   endif
     
   
   if keyword_set(save) then begin
     if 1 then begin
       cdf =cdf_tools(files)
       cdf.add_time
       cdf.fill_nan
       vardata = cdf.get_var_struct()
       novardata = !null
     endif else begin
       loadcdfstr,filenames=files,vardata,novardata  ;,/time      
     endelse
     dummy = spp_data_product_hash('SPC_'+type,vardata)
     dummy.dict['novardata'] = novardata
   endif
   
  if type eq 'l2i' then begin
    ylim,prefix+'*charge_flux_density',100.,6000.,1,/default
    ylim,prefix+'*_current',100.,6000.,1, /default
    Zlim,prefix+'*charge_flux_density',1.,100.,1, /default
    zlim,prefix+'*_current',1.,100.,1    ,/default
  endif
   
  if type eq 'l3i' then begin
    get_data,prefix+'DQF',ptr=ptr
    if ~ptr_valid(ptr) then begin
      dprint,dlevel=1,'No SPC data in specified range.'
      return
    endif
    DQF = *ptr.y
    nt  = n_elements(*ptr.x)
    DQF_vals = indgen(32)
    vptr = 0
    str_element,ptr,'v',vptr
    if  keyword_set(vptr) && ~array_equal(*vptr,DQF_vals) then begin
      dprint,'Fixing DQF values'
      *ptr.v = DQF_vals
    endif
    DQF_bits = total(/preserve,(replicate(1,nt) # (2UL ^ DQF_vals)) * (DQF gt 0),2)
    store_data,prefix+'DQF_bits',data={x:ptr.x,Y:dqf_bits}, dlimit={tplot_routine:'bitplot',yrange:[-1,18]}
    if ~isa(mask,/integer) then mask = 1UL
    if keyword_set(nul_bad) then begin
      w = where((DQF_bits and mask) ne 0,/null)
      for i= 0,n_elements(tplotnames)-1 do begin
        get_data,tplotnames[i],ptr = ptr
        if tplotnames[i] eq prefix+'DQF' then begin
          continue
        endif
        v = ptr.y
        ( *v )[w,*]  = !values.f_nan   ; Fill bad data with NANs
        if nul_bad eq 2 and isa(w) then (*v )[w+1,*] = !values.f_nan  ; nul out one point to the right as well
      endfor
      ;       extras = 1
    endif

    ylim,prefix+'vp_moment_SC',-800,200,0    ,/default
    options,prefix+'vp_*_SC',colors='bgr'     ,/default
    options,prefix+'vp_*_RTN',colors='bgr'  ,/default
    options,prefix+'DQF',spec=1,zrange=[-3,2],yrange=[-1,18],/ystyle
    if keyword_set(extras) then      spp_swp_spc_load_extra,prefix=prefix,nul_bad=nul_bad,extras=extras
  endif
end

