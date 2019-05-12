;+
;NAME: SPP_SWP_SPICE
;PURPOSE:
; LOADS SPICE kernels and creates a few tplot variables
; Demonstrates usage of SPP SPICE ROUTINES
;
;  Author:  Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:01:02 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/general/mvn_file_source.pro $
;-

pro spp_swp_spice,trange=trange,kernels=kernels,download_only=download_only,verbose=verbose,$
  quaternion=quaternion,no_download=no_download,res=res,load=load,position=position,angle_error,att_frame = att_frame,ref_frame=ref_frame
  
  common spp_spice_kernels_com, last_check_time
  if ~keyword_set(ref_frame) then ref_frame = 'J2000'
  if ~keyword_set(att_frame) then att_frame = 'SPP_RTN'
  
  if ~keyword_set(res) then res=300d  ;5min resolution
  if ~keyword_set(angle_error) then angle_error = 1.   ;  error in degrees
  
  retrievetime = systime(1)
 ; if keyword_set(last_check_time) && retrievetime -last_time lt 3600. then 

  if keyword_set(load) then kernels=spp_spice_kernels(/all,/clear,/load,trange=trange,verbose=verbose,no_download=no_download)
 
  if keyword_set(download_only) then return


  if keyword_set(position) then begin
    spice_position_to_tplot,'SPP','SUN',frame=ref_frame,res=res,scale=1e6,name=n1,trange=trange,/force_objects ;million km
    xyz_to_polar,n1,/ph_0_360
  endif
  if keyword_set(quaternion) then spice_qrot_to_tplot,'SPP_SPACECRAFT',att_frame,get_omega=3,res=res,names=tn,check_obj=['SPP_SPACECRAFT'],/force_objects,error=angle_error *!pi/180.

end
