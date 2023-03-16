; $LastChangedBy:  $
; $LastChangedDate: 2022-05-01 12:57:34 -0700 (Sun, 01 May 2022) $
; $LastChangedRevision: 30793 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gsemsg_lun_read.pro $








;+
;  PROCEDURE SWFO_ccsds
;  This procedure is only specific to SWFO in the "sync bytes" found in the MSG header.  Otherwise it could be considered generic
;  It purpose is to read bytes from a previously opened MSG file OR stream.  It returns at the end of file (for files) or when
;  no more bytes are available for reading from a stream.
;  It should gracefully handle sync errors and find sync up on a MSG header.
;  When a complete MSG header and its enclosed CCSDS packet are read in, it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro ccsds_reader::read,source,source_dict=parent_dict

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
      dprint,verbose=self.verbose,'Invalid length of CCSDS header',dlevel=1
      hexprint,buf
      source_dict.remainder = buf
      break
    endif
    if debug(3,self.verbose,msg=strtrim(nb)) then begin
      dprint,nb,dlevel=3
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    sz = msg_buf[4]*256L + msg_buf[5]
    if (sz lt 10) || (sz gt 1100)  then  begin     ;; Lost sync - read one byte at a time
      remainder = msg_buf[1:*]
      nb = 1
      sync_errors += 1
      if debug(2) then begin
        dprint,verbose=self.verbose,dlevel=2,'Lost sync:' ,dwait=2
      endif
      continue
    endif

    source_dict.sync_pattern = sync_pattern
    pkt_size = sz +1
    buf = self.read_nbytes(pkt_size,source,pos=nbytes)
    ccsds_buf = [msg_buf,buf]

    if  self.run_proc then   swfo_ccsds_spkt_handler,ccsds_buf,source_dict=source_dict
    ;if n_elements(source_dict.sync_ccsds_buf) eq pkt_size+4 then source_dict.sync_ccsds_buf = !null $
    ;else    source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[pkt_size+4:*]


    if debug(3,self.verbose,msg=strtrim(n_elements(ccsds_buf))) then begin
      hexprint,dlevel=3,ccsds_buf    ;,nbytes=32
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

  if nbytes ne 0 then msg += string(/print,nbytes,format='(i6 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,verbose=self.verbose,dlevel=3,msg
  source_dict.msg = msg

  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end

;pro ccsds_reader::handle,buffer,source_dict=source_dict
;
;  dprint,dlevel=3,verbose=self.verbose,n_elements(buffer),' Bytes for Handler: "',self.name,'"'
;  self.nbytes += n_elements(buffer)
;  self.npkts  += 1
;
;  if self.run_proc then begin
;    self.raw_tlm_read,buffer,source_dict=source_dict
;
;    if debug(4,self.verbose,msg=self.name) then begin
;      hexprint,buffer
;    endif
;  endif
;
;end



PRO ccsds_reader__define
  void = {ccsds_reader, $
    inherits socket_reader, $    ; superclass
    decom_procedure_name: '',  $
    sync:  bytarr(4),  $
    nsync:  0  $
  }
END




