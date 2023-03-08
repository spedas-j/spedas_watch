
FUNCTION esc_esatm::esc_raw_header_struct,ptphdr


  raw_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
  ptp_code = ptphdr[2]
  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))

  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
  utime = (days-4383L) * 86400L + ms/1000d

  ;; Correct for error in pre 2015-3-1 files
  IF utime LT 1425168000 then utime += us/1d4
  ;; if keyword_set(time) then dt = utime-time  else dt = 0
  source = ptphdr[13]
  spare  = ptphdr[14]
  path   = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  return,ptp_header

END


function esc_esatm::esc_data_select, buff, loc, n
  return, swfo_data_select(buff, loc, n)
end



pro esc_esatm::read, buffer, source_dict=source_dict

  dat = {  $
    time:   0d, $
    sync: 0u ,$
    index :  0u  ,$
    tr:      0b  ,$
    fh:      0b  ,$
    size: 0u , $
    eanode:  uintarr(16),$
    ianodeL: uintarr(16), $
    ianodeH: uintarr(16), $
    imh:     uintarr(16), $
    ahkp:    0, $
    dhkp:    0u,  $
    tofraw:  uintarr(8), $
    gap:  0   }
    
    
  nsamples = 64
    
  dat_accum = { $   
    time: 0d,  $  
    eanode:  uintarr(16,nsamples), $
    ianodeL: uintarr(16,nsamples), $
    ianodeH: uintarr(16,nsamples), $
    imh:     uintarr(16,nsamples), $
    ahkp:    intarr(nsamples), $
    dhkp:    uintarr(nsamples),  $
    tofraw:  uintarr(8,nsamples), $
    gap: 0  }
    


  ;dprint,index,tr,fh,dlevel = 3

  ;  dat.time = source_dict.time
  dat.sync = self.esc_data_select(buf,0,16)
  dat.index = self.esc_data_select(buf,16+7, 9)
  dat.tr    = self.esc_data_select(buf,16+6, 1)
  dat.fh    = self.esc_data_select(buf,16+5, 1)  ; possibly not correct
  dat.size  = self.esc_data_select(buf,32, 16)
  dat.size  = dat.size < n_elements(buf)

   ;print,dat.index

  data2 = uint(buf,6,(dat.size-6)/2 )
  byteorder,data2,/swap_if_little_endian
  dat.eanode = data2[0:15]
  dat.ianodel = data2[16:31]
  dat.ianodeh = data2[32:47]
  dat.imh     = data2[48:63]
  dat.ahkp    = fix(data2[64])
  dat.dhkp    = data2[65]
  dat.tofraw  = fix(data2[66:66+8-1])

  ; dat.size  = esc_data_select(buf,8 * 2,16)   ;; Packet Size
  ; dat.eanode  = esc_data_select(buf,8*3 + 16*indgen(16),16)
  ; dat.ianodel  = esc_data_select(buf,8*3 + 1*16*8 + 16*indgen(16),16)
  ; dat.ianodeh  = esc_data_select(buf,8*3 + 2*16*8 * 16*indgen(16),16)
  ;     dat.eanode = esc_data_select(buf,

 ; store_data,'esc_raw_',data=dat,/append,tagnames='*',time_tag='time',verbose=0

  if dat.index eq -1 then begin
    ;if 
    
  endif

  if dat.index eq 1000 then begin
    printdat,dat
    hexprint,buf
    ;printdat,source_dict
    dprint
  ;  store_data,'esc_raw_',data=dat,/append,tagnames='*',time_tag='time',verbose=2
    ; printdat,source_dict.time
  endif

end




PRO esc_esatm::esc_raw_lun_read, in_lun, out_lun, info=info, source_dict=source_dict

  ;; Size of RAW EESA_FRAMES
  header_size = 6

  ;; Initial buffer to search for SYNC
  buf = bytarr(header_size)

  ;;dwait = 10.
  ;;printdat,info
  IF isa(source_dict,'DICTIONARY') EQ 0 THEN begin
    dprint,dlevel=3,'Creating source_dict'
    ;printdat,info
    source_dict = dictionary()
  ENDIF

  on_ioerror, nextfile
  time = systime(1)
  info.time_received = time
  msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
  ;;in_lun = info.hfp
  out_lun = info.dfp
  remainder = !null
  nbytes = 0UL
  run_proc = struct_value(info,'run_proc',default=1)
  fst = fstat(in_lun)
  ; esc_apdat_info,current_filename= fst.name
  source_dict.source_info = info

  WHILE file_poll_input(in_lun,timeout=0) && ~eof(in_lun) DO BEGIN

    readu,in_lun,buf,transfer_count=nb
    nbytes += nb
    raw_buf = [remainder,buf]

    ;; Lost Sync
    ;; Read one byte at a time
    IF (raw_buf[0] NE '54'x) || (raw_buf[1] NE '4D'x) THEN BEGIN
      remainder = raw_buf[1:*]
      dprint, 'sync error',dlevel=2,dwait = 5.
      CONTINUE
    ENDIF


    ;; Message ID Contents
    index = self.esc_data_select(raw_buf,16+7, 9)
    tr    = self.esc_data_select(raw_buf,16+25, 2)  ; probably not correct
    fh    = self.esc_data_select(raw_buf,16+27, 1)  ; probably not correct
    dprint,index,tr,fh,dlevel = 3

    ; print,index

    ;; Packet Size
    size  = self.esc_data_select(raw_buf,32,16)

    ;; Raw Header Structure
    raw_header = {index:index, tr:tr, fh:fh, size:size}
    source_dict.raw_header = raw_header

    ;; Read in Data
    dat_buf = bytarr(size - header_size)
    readu, in_lun, dat_buf,transfer_count=nb
    nbytes += nb

    esc_raw_data_decom, [raw_buf, dat_buf], source_dict=source_dict



    ;; Debugging
    ;; fst = fstat(in_lun)
    ;; IF debug(2) && fst.cur_ptr NE 0 && fst.size NE 0 then begin
    ;;    dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,$
    ;;           (fst.cur_ptr*100.)/fst.size
    ;; ENDIF

    ;; Check whether binary block was read correctly
    IF nb NE size-header_size THEN BEGIN
      fst = fstat(in_lun)
      dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
      BREAK
    ENDIF

    ;; Debugging
    ;; IF debug(5) THEN BEGIN
    ;;    hexprint,dlevel=3,ccsds_buf,nbytes=32
    ;; ENDIF

    ;; Load packet into apdat object
    ;esc_raw_pkt_handler, dat_buf, source_dict=source_dict
    ;printdat,source_dict

    ;hexprint,dat_buf


    ;; Reset buffer to header size
    buf = bytarr(header_size)
    remainder=!null

  ENDWHILE

  flush,out_lun

  if 1 then begin
    
    if nbytes ne 0 then msg += string(/print,nbytes,([raw_buf])[0:(nbytes < n_elements(raw_buf))-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
    else msg+= ' No data available'

    dprint,dlevel=3,msg
    info.msg = msg
  endif

  dprint,info,dlevel=3,phelp=2

  IF 0 THEN BEGIN
    nextfile:
    dprint,!error_state.msg
    dprint,'Skipping file'
  ENDIF

  ;;IF ~keyword_set(no_sum) THEN BEGIN
  ;;   if keyword_set(info.last_time) then begin
  ;;      dt = time - info.last_time
  ;;      info.total_bytes += nbytes
  ;;      if dt gt .1 then begin
  ;;         rate = info.total_bytes/dt
  ;;         store_data,'PTP_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
  ;;         info.total_bytes =0
  ;;         info.last_time = time
  ;;      endif
  ;;   endif else begin
  ;;      info.last_time = time
  ;;      info.total_bytes = 0
  ;;   endelse
  ;;endif


  ;;if nbytes ne 0 then msg += string(/print,nbytes,([ptp_buf,ccsds_buf])[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
  ;;else msg+= ' No data available'

  ;;dprint,dlevel=5,msg
  ;;info.msg = msg

  ;;dprint,dlevel=2,'Compression: ',float(fp)/fi.size

END

pro esc_esatm__define
  void = {esc_esatm, $
    inherits socket_reader, $    ; superclass
    flag: 0  $
  }
end

