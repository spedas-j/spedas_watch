; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-01 07:52:04 -0800 (Sat, 01 Dec 2018) $
; $LastChangedRevision: 26217 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ssr_file_read.pro $
; 
; ;  This routine will read SSR files that (series of CCSDS packets)

pro spp_ssr_file_read,files,dwait=dwait,no_products=no_products,sort_flag=sort_flag,no_init=no_init
  
;  oldmethod =0
  dummy = {cdf_tools}
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  
  if n_elements(sort_flag) eq 0 then sort_flag=1
  if not keyword_set(no_init) then begin
    spp_swp_apdat_init  ,no_products=no_products
    spp_apdat_info,rt_flag=0,save_flag=1,/clear 
  endif
  
  info = {socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile


  for i=0,n_elements(files)-1 do begin
    info.input_sourcename = files[i] 
    spp_apdat_info,current_filename = info.input_sourcename 
    tplot_options,title=info.input_sourcename 
    file_open,'r',info.input_sourcename ,unit=lun,dlevel=3,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.input_sourcename )
 ;   filename = ulong(strmid(file_basename(files[i]),0,10)))
    filetime = spp_spc_met_to_unixtime(ulong(strmid(file_basename(files[i]),0,10)))
    dprint,dlevel=2,'Reading file: '+info.input_sourcename+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)+time_string(filetime,tformat='  YYYY-MM-DD/hh:mm:ss (DOY)')
    if lun eq 0 then continue
    spp_ssr_lun_read,lun,info=info
  

    fst = fstat(lun)
    dprint,dlevel=2,'File:',fst.name,' Compression: ',float(fst.cur_ptr)/fst.size
    free_lun,lun
    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
    endif
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
  if not keyword_set(no_clear) then del_data,'spp_*'  ; store_data,/clear,'*'

  spp_apdat_info,/finish,rt_flag=0,/all,sort_flag=sort_flag

  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
end


