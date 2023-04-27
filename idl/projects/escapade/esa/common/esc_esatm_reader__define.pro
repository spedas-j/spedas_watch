
FUNCTION esc_esatm_reader::esc_raw_header_struct,ptphdr


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


function esc_esatm_reader::esc_data_select, buff, loc, n
   return, swfo_data_select(buff, loc, n)
end



pro esc_esatm_reader::read, buffer, source_dict=parent_dict ; this routine needs a lot of work - but it will work for common block files


   if n_elements(buffer) eq 202 then begin   
      if 0 then begin
         esc_raw_pkt_handler, buffer, source_dict=parent_dict
      endif else begin
         dprint,dwait = 5,dlevel=3,verbose=self.verbose,n_elements(buffer)
      endelse
   endif else begin
      dprint,'Wrong size',dwait=10.
      return
   endelse
   
   self.decom_esctm,buffer,source_dict=parent_dict
end





pro esc_esatm_reader::decom_esctm, buffer, source_dict=parent_dict
   
   
   if isa(parent_dict,'dictionary') && parent_dict.haskey('cmbhdr') then time = parent_dict.cmbhdr.time  else time=0d
   
                                ;printdat,time_string(time)
                                ;return

   dat = {  $
         time:   0d, $
         sync: 0u ,$
         index :  0u  ,$
         tbd:     0b,  $
         boardid: 0b,  $
         fasthkp: 0b,  $
         ion_optional : 0b, $
         size: 0u , $
         eanode:  uintarr(16),$
         ianode0: uintarr(16), $
         ianode1: uintarr(16), $
         ianode2: uintarr(16), $
         ianode3: uintarr(16), $
         mass_hist: uintarr(16), $
         ahkp:    0, $
         dhkp:    0u,  $
         rates :  uintarr(18), $
         gap:  0   }
   
   

   index = self.esc_data_select(buffer,16+7, 9)
   
   if index eq 0 then begin
      time0 = time              ; Kludge until time is decommed
      self.source_dict.time0 = time
   endif 
   

   
   if ~self.source_dict.haskey('TIME0') then begin
;    self.source_dict.time0 = time
      return
   endif else begin
      time0 = self.source_dict.time0
   endelse

   time = time0 + index * 8.d/512

                                ;dat_accum.time = time

                                ;dprint,index,tr,fh,dlevel = 3

   dat.time =  time             ;   source_dict.time
   dat.sync     =        self.esc_data_select(buffer,0,16)
   dat.tbd             = self.esc_data_select(buffer,16,   2)
   dat.boardid         = self.esc_data_select(buffer,16+2, 2)
   dat.fasthkp         = self.esc_data_select(buffer,16+4, 1)
   dat.ion_optional    = self.esc_data_select(buffer,16+5, 2) 
   dat.index           = index
   dat.size  = self.esc_data_select(buffer,32, 16)
   
   

                                ;print,dat.index

   data2 = uint(buffer,6,(dat.size-6)/2 )
   byteorder,data2,/swap_if_little_endian
   dat.eanode = data2[0:15]
   dat.ianode0 = data2[16:31]
   dat.ianode1 = data2[32:47]
   dat.ianode2 = data2[48:63]
   dat.ianode3  = data2[64:79]
   dat.mass_hist = data2[80:95]
   dat.ahkp     = fix(data2[96])
   dat.dhkp     = data2[97]
   if dat.size gt 202 then begin
      dprint,dwait=7.,'size = ',dat.size
   endif


   source_dict = self.source_dict



   ;; Analog Housekeeping   
   nan = !values.f_nan
   n_ahkp = 32
   if source_dict.haskey('dat_ahkp') then begin
      dat_ahkp=source_dict.dat_ahkp 
   endif else begin
      dat_ahkp = { $
                 time: 0d, $
                 ahkp_raw: replicate(nan,n_ahkp), $
                 gap: 0  }  
      
   endelse

   dat_ahkp.ahkp_raw[index mod n_ahkp] = dat.ahkp
   source_dict.dat_ahkp = dat_ahkp
   if (index mod n_ahkp) eq n_ahkp-1 then BEGIN
      dat_ahkp = self.decom_ahkp(dat_ahkp.ahkp_raw)
      dat_ahkp.time = time
      self.ahkp_da.append,  dat_ahkp
   endif
   
   
   
   ;; Digital Housekeeping
   nan = long(0) ;;!values.f_nan
   n_dhkp = 512
   if source_dict.haskey('dat_dhkp') then begin
     dat_dhkp=source_dict.dat_dhkp
   endif else begin
     dat_dhkp = { $
       time: 0d, $
       dhkp_raw: replicate(nan,n_dhkp), $
       gap: 0  }

   endelse

   dat_dhkp.dhkp_raw[index mod n_dhkp] = dat.dhkp
   source_dict.dat_dhkp = dat_dhkp
   if (index mod n_dhkp) eq n_dhkp-1 then BEGIN
     ;; Conver to bytearr
     ;;dat_dhkp_raw = byte(swap_endian(dat_dhkp.dhkp_raw,/swap_if_little_endian),0,1024)  
     ;dat_dhkp = self.decom_dhkp(dat_dhkp.dhkp_raw)
     dat_dhkp.time = time
     ;self.dhkp_da.append,  dat_dhkp
   endif



   nsamples = 64

   dat_accum = { $
               time: 0d,  $
               eanode:  uintarr(16,nsamples), $
               ianode0: uintarr(16,nsamples), $
               ianode1: uintarr(16,nsamples), $
               ianode2: uintarr(16,nsamples), $
               ianode3: uintarr(16,nsamples), $
               mass_hist: uintarr(16,nsamples), $
               ahkp:    intarr(nsamples), $
               dhkp:    uintarr(nsamples),  $
               rates :  uintarr(18,nsamples), $
               gap: 0  }


   
   if isa(self.dyndata,'dynamicarray') then self.dyndata.append, dat


   if dat.index eq -1 then begin
                                ;if 
      
   endif

   if debug(3,self.verbose) && dat.index eq 23 then begin
      printdat,source_dict
      printdat,dat
      hexprint,buffer
                                ;printdat,source_dict
      dprint
                                ;  store_data,'esc_raw_',data=dat,/append,tagnames='*',time_tag='time',verbose=2
                                ; printdat,source_dict.time
   endif
   
   if debug(4,self.verbose) then begin
      hexprint,buffer
   endif

end


FUNCTION esc_esatm_reader::decom_ahkp, int_arr

   ;; Relable
   wd = float(int_arr)
   
   ;; Check that int_arr is the correct size
   IF n_elements(int_arr) NE 32 THEN stop, 'Wrong ahkp packet size.' 
   
   ;; Analog Housekeeping
   str_ahkp = {imcpv:wd[0]      * 4*1000./(0.787+0.392)/4095.,  $
               idef1v:wd[1]     * 4*1001./4095.,                $
               emcpv:wd[2]      * 4*1001.33/1.33/4095.,         $
               edef1v:wd[3]     * 4*1001./4095.,                $ 
               imcpi:wd[4]      * 4/4095./0.0492,               $
               idef2v:wd[5]     * 4*1001./4095.,                $
               emcpi:wd[6]      * 4/4095.*25.,                  $
               edef2v:wd[7]     * 4*1001./4095.,                $
               irawv:wd[8]      * 4*1000.787/0.787/4095,        $
               ispoilerv:wd[9]  * 4*1052.3/52.3/4095,           $
               erawv:wd[10]     * 4*1000.787/0.787/4095,        $
               espoilerv:wd[11] * 4*1052.3/52.3/4095.,          $
               irawi:wd[12]     * 4/4095.*25,                   $      
               ihemiv:wd[13]    * 4*1001./4095,                 $
               erawi:wd[14]     * 4/4095.*25.,                  $
               ehemiv:wd[15]    * 4*500/4095.,                  $
               iaccelv:wd[16]   * 4*10000./(1.3+1.37)/4095.,    $
               p8v:wd[17]       * 4*3./4095.,                   $
               p1_5v:wd[18]     * 4/4095.,                      $ 
               p5vi:wd[19]      * 4/(4096*0.00801),             $
               iacceli:wd[20]   * 4./4095./0.13,                $
               p5v:wd[21]       * 4*2/4095.,                    $
               p1_5vi:wd[22]    * 4/(4095*0.001),               $
               n5vi:wd[23]      * 4/(4096*0.00801),             $
               ianalt:wd[24]    * (-0.15828),                   $
               n5v:wd[25]       * 4*2/4095.,                    $
               digitalt:wd[26]  * (-0.15828),                   $
               p8vi:wd[27]      * 4/(4095*0.005),               $
               eanalt:wd[28]    * (-0.15828),                   $
               n8v:wd[29]       * (4*20/6.8)/4095,              $
               eanodet:wd[30]   * (-0.15828),                   $
               n8vi:wd[31]      * 1.221,                         $ 
               time:0.D,$
               gap:0}

   return, str_ahkp

END



FUNCTION esc_esatm_reader::decom_dhkp, int_arr

  ;; Relable
  wd = int_arr

  ;; Check that int_arr is the correct size
  IF n_elements(int_arr) NE 512 THEN stop, 'Wrong dhkp packet size.'
    
  ;; Digital Housekeeping
  str_dhkp = {cmds_received:  wd[0], $
              cmd_errors:     self.esc_data_select(wd[1],0,8),  $
              cmd_unknown:    self.esc_data_select(wd[1],8,8), $
              fgpa_rev:       wd[2], $
              mode_id:        wd[3], $
              i_hv_mode:      self.esc_data_select(wd[4],0,4),   $
              e_hv_mode:      self.esc_data_select(wd[4],4,4),   $
              hv_key_enabled: self.esc_data_select(wd[4],8,1),   $
              hv_enabled:     self.esc_data_select(wd[4],9,1),   $
              board_id:       wd[5], $
              time:           0.D,   $
              gap:0}

  return, str_dhkp

END





PRO esc_esatm_reader::esc_raw_lun_read, buffer, source_dict=source_dict

   ;; Size of RAW EESA_FRAMES
   header_size = 6

   ;; Initial buffer to search for SYNC
   buf = bytarr(header_size)

   ;;dwait = 10.
   ;;printdat,info
;  IF isa(source_dict,'DICTIONARY') EQ 0 THEN begin
;    dprint,dlevel=3,'Creating source_dict'
;    ;printdat,info
;    source_dict = dictionary()
;  ENDIF

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
      tr    = self.esc_data_select(raw_buf,16+25, 2) ; probably not correct
      fh    = self.esc_data_select(raw_buf,16+27, 1) ; probably not correct
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

      ;; Original version
      ;;esc_raw_data_decom, [raw_buf, dat_buf], source_dict=source_dict

      ;; Kludged new version
      stop
      esc_raw_pkt_handler, [raw_buf, dat_buf]

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



function esc_esatm_reader::init,_extra=ex,tplot_tagnames=tplot_tagnames
   void = self.socket_reader::init(_extra=ex)
   if ~isa(tplot_tagnames,'string') then tplot_tagnames='*'
   self.ahkp_da   = dynamicarray(name='esc_ahkp',tplot_tagnames=tplot_tagnames)
   self.dhkp_da   = dynamicarray(name='esc_dhkp',tplot_tagnames=tplot_tagnames)
   self.espec_da  = dynamicarray(name='esc_espec',tplot_tagnames=tplot_tagnames)
   self.thspec_da = dynamicarray(name='esc_thspec',tplot_tagnames=tplot_tagnames)
   return,1
end



pro esc_esatm_reader__define
   void = {esc_esatm_reader, $
           inherits socket_reader, $ ; superclass
           ahkp_da: obj_new(),  $    ; dynamicarray for analog HKP
           dhkp_da: obj_new(),  $    ; dynamicarray for digital HKP
           espec_da: obj_new(),  $
           thspec_da: obj_new(),  $
           flag: 0  $
          }
end

