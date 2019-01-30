; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-01-29 16:17:12 -0800 (Tue, 29 Jan 2019) $
; $LastChangedRevision: 26514 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ssr_file_read.pro $
; 
; ;  This routine will read SSR files that (series of CCSDS packets)

pro spp_ssr_file_read,files,dwait=dwait,no_products=no_products,sort_flag=sort_flag,no_init=no_init
  
;  oldmethod =0
  dummy = {cdf_tools}
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)

  apdat_info = spp_apdat(/get_info)
  
  if n_elements(sort_flag) eq 0 then sort_flag=1
  spp_swp_apdat_init  ,no_products=no_products
  spp_apdat_info,save_flag=1,rt_flag=0
  if ~ keyword_set(no_init) then begin
    spp_apdat_info,/clear 
    apdat_info['file_hash_list'].remove,/all
  endif
  
  info = {socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile
  


  for i=0,n_elements(files)-1 do begin
    if apdat_info.haskey('break') then begin
      dprint,'Break point here',dlevel=3
      if apdat_info['break'] ne 0 then stop
    endif
    filename = files[i]
    basename = file_basename(filename)
    hashcode = basename.hashcode()
    filetime = spp_spc_met_to_unixtime(ulong(strmid(basename,0,10)))
    info.input_sourcename = filename 
    info.input_sourcehash = hashcode
    fi = file_info(info.input_sourcename )
    if apdat_info['file_hash_list'].haskey(hashcode)  then begin
      dprint,dlevel=1,'Warning: Skipping file '+filename+time_string(filetime,tformat='  YYYY-MM-DD/hh:mm:ss (DOY)')+' which has already been loaded.',verbose=verbose
      continue
    endif
    spp_apdat_info,current_filename = filename   ; info.input_sourcename
    file_open,'r',info.input_sourcename ,unit=lun,dlevel=3,compress=-1
    if lun eq 0 then begin
      dprint,'Bad file: '+filename
      continue
    endif
    dprint,dlevel=2,'Loading File: '+info.input_sourcename+' LUN:'+strtrim(lun,2)+' Size: '+strtrim(fi.size,2)+time_string(filetime,tformat='  YYYY-MM-DD/hh:mm:ss (DOY)')
    spp_ssr_lun_read,lun,info=info
  
    fst = fstat(lun)
    compression = float(fst.cur_ptr)/fst.size
    dprint,dlevel=3,'Loaded File:'+fst.name+' Compression: '+strtrim(float(fst.cur_ptr)/fst.size,2)
    free_lun,lun
    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file '+filename
    endif
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
  if not keyword_set(no_clear) then del_data,'spp_*'  ; store_data,/clear,'*'

  spp_apdat_info,/finish,rt_flag=0,/all,sort_flag=sort_flag

  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
end


