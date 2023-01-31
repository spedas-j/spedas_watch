;+
;
; Written by:
;
;    Davin Larson
;    Roberto Livi
;    Original: spp_raw_file_read.pro
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-01-30 10:59:48 -0800 (Mon, 30 Jan 2023) $
; $LastChangedRevision: 31442 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_raw_file_read.pro $
;
; PROGRAM:  
; PURPOSE:  
; INPUT:
;
; TYPICAL USAGE:
;
; KEYWORDS:
;
;-


PRO esc_raw_file_read, files, dwait=dwait, no_products=no_products, no_clear=no_clear

   IF NOT keyword_set(dwait) THEN dwait = 10
   t0 = systime(1)
   esc_apdat_init
   esc_apdat_info, rt_flag=0, save_flag=1, /clear
   info = { socket_recorder }
   info.run_proc = 1
   on_ioerror, nextfile

   FOR i=0,n_elements(files)-1 DO BEGIN
      
      info.input_sourcename = files[i]
      info.input_sourcehash = info.input_sourcename.hashcode()
      esc_apdat_info,current_filename = info.input_sourcename
      tplot_options,title=info.input_sourcename
      file_open,'r',info.input_sourcename,unit=lun,dlevel=3 ;;,compress=-1
      sizebuf = bytarr(2)
      fi = file_info(info.input_sourcename)
      dprint,dlevel=1,'Reading '+file_info_string(info.input_sourcename)+' LUN:'+strtrim(lun,2)
      if lun eq 0 then CONTINUE
      esc_raw_lun_read,lun,info=info
      stop
      fst = fstat(lun)
      dprint,dlevel=2,'Compression: ',float(fst.cur_ptr)/fst.size
      free_lun,lun
      if 0 then begin
         nextfile:
         dprint,!error_state.msg
         dprint,'Skipping file'
      endif
   endfor
   dt = systime(1)-t0
   dprint,format='("Finished loading in ",f0.1," seconds")',dt

   if not keyword_set(no_clear) then del_data,'esc_*' ; store_data,/clear,'*'

   esc_apdat_info,current_filename=''
   esc_apdat_info,/finish,/rt_flag,/all

   dt = systime(1)-t0
   dprint,format='("Finished loading in ",f0.1," seconds")',dt

end

