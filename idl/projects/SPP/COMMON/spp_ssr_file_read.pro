;  This routine will read SSR files that (series of CCSDS packets)

pro spp_ssr_file_read,files,dwait=dwait,no_products=no_products
  
;  oldmethod =0
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  
  spp_swp_apdat_init  ,no_products=no_products
  spp_apdat_info,rt_flag=0,save_flag=1,/clear 

  info = {socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile


  for i=0,n_elements(files)-1 do begin
    info.filename = files[i] 
    tplot_options,title=info.filename
    file_open,'r',info.filename,unit=lun,dlevel=3,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.filename)
    dprint,dlevel=1,'Reading file: '+info.filename+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
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

  spp_apdat_info,/finish,/rt_flag,/all

  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
end


