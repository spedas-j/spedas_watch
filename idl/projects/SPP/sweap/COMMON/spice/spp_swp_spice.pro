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
  quaternion=quaternion,no_download=no_download,res=res,load=load,position=position


  if keyword_set(load) then kernels=spp_spice_kernels(/all,/clear,/load,trange=trange,verbose=verbose,no_download=no_download)
  if keyword_set(download_only) then return

  if ~keyword_set(res) then res=300d  ;5min resolution

  if keyword_set(position) then begin
    spice_position_to_tplot,'SPP','SUN',frame='J2000',res=res,scale=1e6,name=n1,trange=trange,/force_objects ;million km
    xyz_to_polar,n1
  endif

  if keyword_set(quaternion) then spice_qrot_to_tplot,'SPP_SPACECRAFT','J2000',get_omega=3,res=res,names=tn,check_obj=['SPP_SPACECRAFT','J2000'],/force_objects,error=3. *!pi/180. ;3 degree error

end
