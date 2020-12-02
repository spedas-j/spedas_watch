;+
;NAME: SPP_SWP_SPICE
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of SPP SPICE ROUTINES
;
;  Author:  Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-01 12:23:05 -0800 (Tue, 01 Dec 2020) $
; $LastChangedRevision: 29411 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spice/spp_swp_spice.pro $
;-

pro spp_swp_spice,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose,predict=predict,scale=scale,$
  quaternion=quaternion,no_download=no_download,res=res,load=load,position=position,angle_error=angle_error,att_frame=att_frame,ref_frame=ref_frame,test=test
  
  common spp_spice_kernels_com, last_load_time,last_trange
  if ~keyword_set(ref_frame) then ref_frame ='J2000'
  if ~keyword_set(att_frame) then att_frame ='SPP_RTN'
  
  if ~keyword_set(res) then res=60d ;1min resolution
  if ~keyword_set(angle_error) then angle_error=3. ;error in degrees
  trange=timerange(trange) ;get default trange
  
  current_time=systime(1)
  if n_elements(load) eq 0 then begin
    if ~keyword_set(last_load_time) || current_time gt (last_load_time + 24*3600.) then load_anyway=1
    if ~keyword_set(last_trange) || trange[0] lt last_trange[0] || trange[1] gt last_trange[1] then load_anyway=1
  endif

  if keyword_set(load) || keyword_set(load_anyway) then begin
    kernels=spp_spice_kernels(/all,/clear,/load,trange=trange,verbose=verbose,no_download=no_download,predict=predict,attitude=quaternion)
    last_load_time=systime(1)
    last_trange=trange
  endif
  
  if keyword_set(download_only) then return

  if keyword_set(position) then begin
    if ~keyword_set(scale) then scale='r'
    if scale eq 'km' then begin
      scale1=1e6
      scale2=1e3
      ysub1='(Million km)'
      ysub2='(1000 km)'
    endif
    if scale eq 'r' then begin
      scale1=695700
      scale2=6051.8
      ysub1='(Rsun)'
      ysub2='(Rvenus)'
    endif
    spice_position_to_tplot,'SPP','SUN',frame=ref_frame,res=res,scale=scale1,name=n1,trange=trange,/force_objects ;million km
    spice_position_to_tplot,'SPP','Venus',frame=ref_frame,res=res,scale=scale2,name=n2,trange=trange,/force_objects ; 1000 km
    xyz_to_polar,[n1,n2],/ph_0_360
    options,'SPP_POS_(SUN-'+ref_frame+')_mag',ysubtitle=ysub1
    options,'SPP_POS_(Venus-'+ref_frame+')_mag',ysubtitle=ysub2
    options,'SPP_VEL_(*-'+ref_frame+')_mag',ysubtitle='(km/s)'
  endif
  if keyword_set(quaternion) then begin
    spice_qrot_to_tplot,'SPP_SPACECRAFT',att_frame,get_omega=3,res=res,names=tn,trange=trange,check_obj=['SPP_SPACECRAFT','SPP','SUN'],/force_objects,error=angle_error*!pi/180.

    get_data,'SPP_SPACECRAFT_QROT_SPP_RTN',dat=dat
    qtime = dat.x
    quat_SC_to_RTN = dat.y
    quat_SC2_to_SC = [.5d,.5d,.5d,-.5d]
    quat_SC_to_SC2 = [.5d,-.5d,-.5d,.5d]
        
    quat_SC2_to_RTN = qmult(quat_SC_to_RTN, replicate(1,n_elements(qtime)) # quat_SC2_to_SC)
    store_data,'spp_QROT_SC2>RTN',qtime,quat_SC2_to_RTN,dlim={SPICE_FRAME:'SPP_SC2',colors:'dbgr',constant:0.,labels:['Q_W','Q_X','Q_Y','Q_Z'],labflag:-1}
    store_data,'spp_QROT_SC2>RTN_Euler_angles',qtime, 180/!pi*quaternion_to_euler_angles(quat_SC2_to_RTN),dlimit={colors:'bgr',constant:0.,labels:['Roll','Pitch','Yaw'],labflag:-1,spice_frame:'SPP_SPACECRAFT'}
    store_data,'spp_QROT_RTN>SC2_Euler_angles',qtime, 180/!pi*quaternion_to_euler_angles(qconj(quat_SC2_to_RTN)),dlimit={colors:'bgr',constant:0.,labels:['Roll','Pitch','Yaw'],labflag:-1,spice_frame:'SPP_SPACECRAFT'}
    ;tplot

    if keyword_set(test) then begin   ; test routines
      copy_data,'SPP_SPACECRAFT_QROT_SPP_RTN','spp_QROT_SC>RTN'
      if 1 then begin
        dprint,'Select a time interval to test...'
        ctime,tr
        spp_fld_load,trange=tr,type='mag_SC'
        copy_data,'psp_fld_l2_mag_SC','psp_mag_SC'
        spp_fld_load,trange=tr,type='mag_RTN'

        store_data,'spp_QROT_SC>SC2',tr,replicate(1,n_elements(tr)) # quat_sc_to_sc2   ; this rotation is a constant
        tplot_quaternion_rotate,'psp_mag_SC','spp_QROT_SC>SC2'
        tplot_quaternion_rotate,'psp_mag_SC2','spp_QROT_SC2>RTN',newname='psp_mag_test_RTN'
        tplot_quaternion_rotate,'psp_mag_SC','spp_QROT_SC>RTN',name=name
        printdat,name
        
        dif_data,'psp_fld_l2_mag_RTN','psp_mag_test_RTN'
        dif_data,'psp_fld_l2_mag_RTN','psp_mag_RTN'
        
        options,'psp_mag_SC',spice_frame='SPP_SPACECRAFT', /default
        spice_vector_rotate_tplot,'psp_mag_SC','SPP_RTN' ;,check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN'];,/force_objects

        
        
      endif else begin
        dprint,'Select a time interval to test...'
        ctime,tr
        spp_fld_load,trange=tr,type='mag_SC_4_Sa_per_Cyc'
        copy_data,'psp_fld_l2_mag_SC_4_Sa_per_Cyc','psp_mag_4NYHz_SC'
        spp_fld_load,trange=tr,type='mag_RTN_4_Sa_per_Cyc'
        ;copy_data,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc','psp_mag_4NYHz_RTN'

        store_data,'spp_QROT_SC>SC2',tr,replicate(1,n_elements(tr)) # quat_sc_to_sc2   ; this rotation is a constant
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC','spp_QROT_SC>SC2'
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC2','spp_QROT_SC2>RTN',newname='psp_mag_4NYHz_test_RTN'
        tplot_quaternion_rotate,'psp_mag_4NYHz_SC','spp_QROT_SC>RTN',name=name
        printdat,name
        
      endelse

    endif
 
    if 0 then begin
      store_data,'spp_swp_sc_x',dat.x,replicate(1.,n_elements(dat.x))#[1.,0.,0.],dlim={SPICE_FRAME:'SPP_SPACECRAFT',colors:'bgr',labels:['SC_X','SC_Y','SC_Z'],labflag:-1}
      store_data,'spp_swp_sc_z',dat.x,replicate(1.,n_elements(dat.x))#[0.,0.,1.],dlim={SPICE_FRAME:'SPP_SPACECRAFT',colors:'bgr',labels:['SC_X','SC_Y','SC_Z'],labflag:-1}
      spice_vector_rotate_tplot,'spp_swp_sc_x','SPP_RTN',check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN'];,/force_objects
      spice_vector_rotate_tplot,'spp_swp_sc_z','SPP_RTN',check_obj=['SPP_SPACECRAFT','SPP','SPP_RTN']
      get_data,'spp_swp_sc_x_SPP_RTN',dat=datx
      get_data,'spp_swp_sc_z_SPP_RTN',dat=datz
      store_data,'spp_swp_sc_angle_(degrees)',dat.x,!radeg*[[atan(datx.y[*,2],datx.y[*,1])],[acos(-datz.y[*,0])]],dlim={constant:0.,colors:'br',labels:['SC_X_TN','SC_Z_SUN'],labflag:-1}      
    endif
  endif

end
