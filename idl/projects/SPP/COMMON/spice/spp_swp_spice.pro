;+
;NAME: SPP_SWP_SPICE
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of SPP SPICE ROUTINES
;
;  Author:  Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-18 18:37:05 -0700 (Tue, 18 Aug 2020) $
; $LastChangedRevision: 29046 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spice/spp_swp_spice.pro $
;-

pro spp_swp_spice,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose,predict=predict,scale=scale,$
  quaternion=quaternion,no_download=no_download,res=res,load=load,position=position,angle_error=angle_error,att_frame=att_frame,ref_frame=ref_frame
  
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
    options,'SPP_POS_(SUN-J2000)_mag',ysubtitle=ysub1,ystyle=3
    options,'SPP_POS_(Venus-J2000)_mag',ysubtitle=ysub2,ystyle=3
  endif
  if keyword_set(quaternion) then spice_qrot_to_tplot,'SPP_SPACECRAFT',att_frame,get_omega=3,res=res,names=tn,trange=trange,check_obj=['SPP_SPACECRAFT','SPP','SUN'],/force_objects,error=angle_error*!pi/180.

end
