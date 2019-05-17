;+
;NAME: SPP_SPICE_KERNELS
;PURPOSE:
; Provides spp spice kernel filename of specified type
;
;Typical CALLING SEQUENCE: kernels=spp_spice_kernel()
;
;KEYWORDS:
; LOAD:   Set keyword to also load file
; TRANGE:  Set keyword to UT timerange to provide range of needed files.
; RECONSTRUCT: If set, then only kernels with reconstructed data (no predicts) are returned.
;
;OUTPUT: fully qualified kernel filename(s)
;
;WARNING: Be very careful using this routine with the /LOAD keyword.
;It will change the loaded SPICE kernels that users typically assume are not being changed.
;PLEASE DO NOT USE this routine within general "LOAD" routines using the LOAD keyword.
;"LOAD" routines should assume that SPICE kernels are already loaded.
;
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-05-16 13:19:38 -0700 (Thu, 16 May 2019) $
; $LastChangedRevision: 27249 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spice/spp_spice_kernels.pro $
;-
function spp_spice_kernels,names,trange=trange,all=all,load=load,verbose=verbose,source=source,valid_only=valid_only,sck=sck,clear=clear  $
  ,reconstruct=reconstruct,no_update=no_update,no_server=no_server,no_download=no_download,last_version=last_version

  if spice_test() eq 0 then return,''
  retrievetime = systime(1)
  if n_elements(last_version) eq 0 then last=1

  tb = scope_traceback(/structure)
  this_dir = file_dirname(tb[n_elements(tb)-1].filename)+'/'   ; the directory this file resides in (determined at run time)

  naif = spice_file_source(valid_only=valid_only,verbose=verbose,last=last)
  if keyword_set(sck) then names = ['STD','SCK']
  if keyword_set(all) or not keyword_set(names) then names=['STD','SCK','FRM','IK','SPK','CK']
  if keyword_set(no_download) or keyword_set(no_server) then source.no_server = 1
  if ~keyword_set(source) then source = naif
  if ~keyword_set(trange) then trange = timerange()

  kernels=''
  pathname='spp/data/sci/MOC/SPP/data_products/'
  for i=0,n_elements(names)-1 do begin
    case strupcase(names[i]) of
      ;  "Standard" kernels
      'STD':append_array, kernels,spice_standard_kernels(source=source,no_update=no_update)
      ;Leap Second (TLS)
      'LSK':append_array,kernels,file_retrieve(source.remote_data_dir+'generic_kernels/lsk/naif00??.tls',last=last,/valid_only)
      ;Spacecraft Clock (TSC)
      'SCK':append_array,kernels,spp_file_retrieve(pathname+'operations_sclk_kernel/spp_sclk_????.tsc',last=last,/valid_only)
      ;Frame kernels (TF)
      'FRM':begin
        append_array,kernels,spp_file_retrieve(pathname+'frame_kernel/spp_v100.tf',last=last,/valid_only)
        append_array,kernels,spp_file_retrieve(pathname+'frame_kernel/spp_dyn_v20?.tf',last=last,/valid_only)
      end
      ;Spacecraft position (BSP)
      'SPK':begin
        append_array,kernels,spp_file_retrieve(pathname+'reconstructed_ephemeris/2018/*')
        append_array,kernels,spp_file_retrieve(pathname+'reconstructed_ephemeris/2019/*')
      end
      ; Spacecraft Attitude (BC)
      'CK': append_array,kernels,spp_file_retrieve(pathname+'attitude_history/YYYY/spp_YYYY_DOY_??.ah.bc',trange=trange,last=last,/valid_only,/daily)
      ; Instrument Kernels (TI)
      'IK':
    endcase
  endfor

  if keyword_set(clear) then cspice_kclear
  if keyword_set(load) then spice_kernel_load, kernels

  dprint,dlevel=2,verbose=verbose,'Time to retrieve SPICE kernels: '+strtrim(systime(1)-retrievetime,2)+ ' seconds'
  return,kernels

end
