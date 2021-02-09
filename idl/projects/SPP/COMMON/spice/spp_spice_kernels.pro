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
; $LastChangedBy: ali $
; $LastChangedDate: 2021-02-08 15:09:30 -0800 (Mon, 08 Feb 2021) $
; $LastChangedRevision: 29647 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spice/spp_spice_kernels.pro $
;-
function spp_spice_kernels,names,trange=trange,all=all,load=load,verbose=verbose,source=source,valid_only=valid_only,sck=sck,clear=clear  $
  ,mars=mars,jupiter=jupiter,saturn=saturn $
  ,reconstruct=reconstruct,no_update=no_update,no_server=no_server,no_download=no_download,last_version=last_version,predict=predict,attitude=attitude

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
  trange = timerange(trange)

  kernels=''
  pathname='psp/data/sci/sweap/sao/psp/data/moc_data_products/' ;SWEAP
  pathname='psp/data/sci/MOC/SPP/data_products/' ;FIELDS
  for i=0,n_elements(names)-1 do begin
    case strupcase(names[i]) of
      ;  "Standard" kernels
      'STD':append_array, kernels,spice_standard_kernels(source=source,no_update=no_update,mars=mars,jupiter=jupiter,saturn=saturn)
      ;Leap Second (TLS)
      'LSK':append_array,kernels,spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
        local_path = source.local_data_dir+'generic_kernels/lsk/', no_update = no_update, $
        last_version = 1, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
      ;file_retrieve(source.remote_data_dir+'generic_kernels/lsk/naif00??.tls',last=last,/valid_only)
      ;Spacecraft Clock (TSC)
      'SCK':append_array,kernels,spp_file_retrieve(pathname+'operations_sclk_kernel/spp_sclk_????.tsc',last=last,/valid_only)
      ;Frame kernels (TF)
      'FRM':begin
        append_array,kernels,spp_file_retrieve(pathname+'frame_kernel/spp_v???.tf',/last_version,/valid_only)
        append_array,kernels,spp_file_retrieve(pathname+'frame_kernel/spp_dyn_v???.tf',/last_version,/valid_only)
      end
      ;Spacecraft position (BSP)
      'SPK':begin
        if keyword_set(predict) then begin
          append_array,kernels,spp_file_retrieve(pathname+'ephemeris_predict/????/*.bsp')
        endif else begin
          ;append_array,kernels,spp_file_retrieve(pathname+'reconstructed_ephemeris/????/*.bsp') ;multiple files. single merged file is below:
          append_array,kernels,spp_file_retrieve('psp/data/sci/sweap/sao/psp/data/teams/psp_soc/soc_ephem/ephem_current/spp_recon_20180812_????????_merge.bsp',last=last,/valid_only)
        endelse
      end
      ; Spacecraft Attitude (BC)
      'CK': if keyword_set(attitude) then begin
        if keyword_set(predict) then begin
          append_array,kernels,spp_file_retrieve(pathname+'attitude_short_term_predict/spp_*.asp.bc',/valid_only)
        endif else append_array,kernels,spp_file_retrieve(pathname+'attitude_history/YYYY/spp_YYYY_DOY_??.ah.bc',trange=trange,last=last,/valid_only,/daily)
      endif

      ; Instrument Kernels (TI)
      'IK':
    endcase
  endfor

  if keyword_set(clear) then cspice_kclear
  if keyword_set(load) then spice_kernel_load, kernels

  dprint,dlevel=2,verbose=verbose,'Time to retrieve SPICE kernels: '+strtrim(systime(1)-retrievetime,2)+ ' seconds'
  return,kernels

end
