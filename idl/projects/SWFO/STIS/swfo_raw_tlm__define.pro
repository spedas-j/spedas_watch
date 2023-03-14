; $LastChangedBy:  $
; $LastChangedDate: 2022-05-01 12:57:34 -0700 (Sun, 01 May 2022) $
; $LastChangedRevision: 30793 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gsemsg_lun_read.pro $



function swfo_raw_tlm::raw_tlm_struct,buf
  ;printdat,buf
  gse_pkt = {time:0d,gap:0}
  return,gse_pkt

end


;function swfo_raw_tlm::read_nbytes,nb,source,pos=pos,output=output
;  buf = !null
;
;  if ~isa(pos) then pos=0ul
;  if isa(source,/array) then begin          ; source should be a an array of bytes
;    n = nb < (n_elements(source) - pos)
;    if n gt 0 then   buf = source[pos:pos+n-1]
;    pos = pos+n
;  endif else begin
;    if isa(source) then begin                ; source should be a file LUN
;      if file_poll_input(source,timeout=0) && ~eof(source) then begin
;        buf = bytarr(nb)
;        readu,source,buf,transfer_count=n
;        pos = pos+n
;      endif
;    endif
;  endelse
;  if keyword_set(output) && keyword_set(buf) then writeu,output,buf
;
;  return,buf
;end








;+
;  PROCEDURE SWFO_GSEMSG_Buffer_READ
;  This procedure is only specific to SWFO in the "sync bytes" found in the MSG header.  Otherwise it could be considered generic
;  It purpose is to read bytes from a previously opened MSG file OR stream.  It returns at the end of file (for files) or when
;  no more bytes are available for reading from a stream.
;  It should gracefully handle sync errors and find sync up on a MSG header.
;  When a complete MSG header and its enclosed CCSDS packet are read in, it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro swfo_raw_tlm::raw_tlm_read,source,source_dict=parent_dict

  dwait = 10.

  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('cmbhdr') then begin
    header = parent_dict.cmbhdr
    ;   dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
  endif else begin
    dprint,verbose=self.verbose,dlevel=4,'No cmbhdr'
    header = {time: !values.d_nan , gap:0 }
  endelse

  ;  endelse

  source_dict = self.source_dict

  if ~source_dict.haskey('sync_ccsds_buf') then source_dict.sync_ccsds_buf = !null   ; this contains the contents of the buffer from the last call
  run_proc=1

  on_ioerror, nextfile
  time = systime(1)
  source_dict.time_received = time

  msg = time_string(source_dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  remainder = !null
  nbytes = 0UL
  sync_errors =0ul
  nb = 6
  while isa( (buf= self.read_nbytes(nb,source,pos=nbytes) ) ) do begin
    if n_elements(buf) ne nb then begin
      dprint,verbose=self.verbose,'Invalid length of GSE MSG header',dlevel=1
      hexprint,buf
      source_dict.remainder = buf
      break
    endif
    if debug(4,self.verbose,msg=strtrim(nb)) then begin
      dprint,nb,dlevel=3
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    sz = msg_buf[4]*256L + msg_buf[5]
    if (sz lt 4) || (msg_buf[0] ne 'A8'x) || (msg_buf[1] ne '29'x) || (msg_buf[2] ne '00'x) then  begin     ;; Lost sync - read one byte at a time
      remainder = msg_buf[1:*]
      nb = 1
      sync_errors += 1
      if debug(2) then begin
        dprint,verbose=self.verbose,dlevel=3,'Lost sync:' ,dwait=2
      endif
      continue
    endif
    case msg_buf[3] of
      'c1'x: begin
        if sz ne 'c'x then begin
          dprint,'Invalid GSE message. word size: ',sz
          message,'Error',/cont
        endif
        nb2 = sz * 2
        buf= self.read_nbytes(nb2,source,pos=nbytes)

        if debug(3,self.verbose,msg='c1 packet') then begin
          ;dprint,nb,dlevel=3
          hexprint,buf
        endif
        raw_tlm_header = self.raw_tlm_struct(buf)
        source_dict.gse_header  = raw_tlm_header
      end
      'c3'x: begin
        sync_pattern = ['1a'x,  'cf'x ,'fc'x, '1d'x ]
        source_dict.sync_pattern = sync_pattern
        ;buf = bytarr(sz*2)
        ;readu,in_lun,buf,transfer_count=nb
        ;nbytes += nb
        buf = self.read_nbytes(sz*2,source,pos=nbytes)
        if debug(4) then begin
          dprint,sz*2,dlevel=3
          hexprint,buf
        endif
        source_dict.sync_ccsds_buf = [source_dict.sync_ccsds_buf, buf]
        while 1 do begin ; start processing packet stream
          nbuf = n_elements(source_dict.sync_ccsds_buf)
          skipped = 0UL
          while (nbuf ge 4) && (array_equal(source_dict.sync_ccsds_buf[0:3] ,sync_pattern) eq 0) do begin
            dprint,dlevel=4, 'searching for sync pattern: ',nbuf
            source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[1:*]    ; increment one byte at a time looking for sync pattern
            nbuf = n_elements(source_dict.sync_ccsds_buf)
            skipped++
          endwhile
          if skipped ne 0 then dprint,verbose=self.verbose,dlevel=2,'Skipped ',skipped,' bytes to find sync word'
          nbuf = n_elements(source_dict.sync_ccsds_buf)
          if nbuf lt 10 then begin
            dprint,verbose=self.verbose,dlevel=4,'Incomplete packet header - wait for later'
            ;         source_dict.sync_ccsds_buf = sync_ccsds_buf
            break
          endif
          pkt_size = source_dict.sync_ccsds_buf[4+4] * 256u + source_dict.sync_ccsds_buf[5+4] + 7
          ;dprint,dlevel=2,'pkt_size: ',pkt_size
          if nbuf lt pkt_size + 4 then begin
            dprint,verbose=self.verbose,dlevel=4,'Incomplete packet - wait for later'
            ;      source_dict.sync_ccsds_buf = sync_ccsds_buf
            break
          endif
          ccsds_buf = source_dict.sync_ccsds_buf[4:pkt_size+4-1]  ; not robust!!!
          if self.run_proc then   swfo_ccsds_spkt_handler,ccsds_buf,source_dict=source_dict
          if n_elements(source_dict.sync_ccsds_buf) eq pkt_size+4 then source_dict.sync_ccsds_buf = !null $
          else    source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[pkt_size+4:*]
        endwhile
      end
      else:    message,'GSE raw_tlm error - unknown code'
    endcase

    ;    if ~isa(source,/array) then begin     ; source is a file pointer
    ;      fst = fstat(source)
    ;      if debug(3) && fst.cur_ptr ne 0 && fst.size ne 0 then begin
    ;        dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,(fst.cur_ptr*100.)/fst.size
    ;      endif
    ;      if n_elements(buf) ne  sz*2 then begin
    ;        fst = fstat(source)
    ;        dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
    ;        break
    ;      endif
    ;    endif

    if debug(5) then begin
      hexprint,dlevel=3,ccsds_buf,nbytes=32
    endif
    nb = 6     ; initialize for next gse message
  endwhile

  if sync_errors then begin
    dprint,dlevel=2,sync_errors,' sync errors at "'+time_string(source_dict.time_received)+'"'
    ;printdat,source
    ;hexprint,source
  endif

  if isa(output_lun) then  flush,output_lun

  if 0 then begin
    nextfile:
    dprint,!error_state.msg
    dprint,'Skipping file'
  endif
  ;
  ;  if ~keyword_set(no_sum) then begin
  ;    if keyword_set(info.last_time) then begin
  ;      dt = time - info.last_time
  ;      info.total_bytes += nbytes
  ;      if dt gt .1 then begin
  ;        rate = info.total_bytes/dt
  ;        store_data,'GSE_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
  ;        info.total_bytes =0
  ;        info.last_time = time
  ;      endif
  ;    endif else begin
  ;      info.last_time = time
  ;      info.total_bytes = 0
  ;    endelse
  ;  endif
  ;
  ;  ddata = buf
  ;  nb = n_elements(buf)
  ;  ; if nb ne 0 then msg += string(/print,nb,(ddata)[0:(nb < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
  if nbytes ne 0 then msg += string(/print,nbytes,format='(i6 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,verbose=self.verbose,dlevel=3,msg
  source_dict.msg = msg

  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end



pro swfo_raw_tlm::read,buffer,source_dict=source_dict


  
   self.raw_tlm_read,buffer,source_dict=source_dict


end



pro swfo_raw_tlm::handle,buffer,source_dict=source_dict

  dprint,dlevel=3,verbose=self.verbose,n_elements(buffer),' Bytes for Handler: "',self.name,'"'
  self.nbytes += n_elements(buffer)
  self.npkts  += 1

  if self.run_proc then begin
    self.raw_tlm_read,buffer,source_dict=source_dict

    if debug(4,self.verbose,msg=self.name) then begin
      hexprint,buffer
    endif
  endif

end



PRO swfo_raw_tlm__define
  void = {swfo_raw_tlm, $
    inherits socket_reader, $    ; superclass
    data:   obj_new() $         ; user definable object  not used
  }
END




