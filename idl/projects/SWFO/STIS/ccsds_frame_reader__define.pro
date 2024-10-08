; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-09-10 22:51:25 -0700 (Tue, 10 Sep 2024) $
; $LastChangedRevision: 32817 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/ccsds_reader__define.pro $



;+
;  PROCEDURE ccsds_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-






function ccsds_frame_reader::header_struct,header

  nsync = self.sync_size
  if nsync ne 0 then  sync = self.sync_pattern[0:nsync-1] else sync = !null

  if header[0] eq 0x3b then begin
     i=1;    printdat,/hex,self.sync_mask,sync,header     ; trap to detect replay packets for SWFO
  endif
  
  
  if n_elements(header) lt self.header_size then return, !null                    ; Not enough bytes in packet header
  if  (isa(sync) && (array_equal(sync,header[0:nsync-1] and self.sync_mask) eq 0)) then return,!null   ; Not a valid packet
  

  strct = {  time:!values.d_nan, scid:0u, vcid:0b,  psize: 0u , replay:0u, SEQN:0UL, sigfield:0b  , offset:0u, valid:0, gap:0}
  temp = (header[nsync+0] * 256U + header[nsync+1])
  strct.scid  = ishft(temp,6)  and 0xFF 
  strct.vcid  = temp and 0x3F
  strct.seqn = ((header[nsync+2] *256ul) +header[nsync+3]) *256ul + header[nsync+4]
  strct.sigfield = header[nsync+5]
  strct.offset = header[nsync+6]*256u + header[nsync+7]
  
  strct.psize = self.frame_size - self.header_size   ; size of payload  (6 bytes less than size of ccsds packet)

 ; if isa(sync) && header[0] eq 0x3b then begin    ; special case for SWFO
 ;   strct.apid = strct.apid or 0x8000         ; turn on highest order bit to segregate different apid
 ; endif


  return,strct

end







pro ccsds_frame_reader::read_old,source   ;,source_dict=parent_dict

  ;dwait = 10.
  message,'Obsolete'
  
  dict = self.source_dict
  if dict.haskey('parent_dict') then parent_dict = dict.parent_dict


  if isa(parent_dict,'dictionary') &&  parent_dict.haskey('headerstr') then begin
    header = parent_dict.headerstr
    ;   dprint,dlevel=4,verbose=self.verbose,header.description,'  ',header.size
  endif else begin
    dprint,verbose=self.verbose,dlevel=4,'No headerstr'
    header = {time: !values.d_nan , gap:0 }
  endelse

  
  if ~dict.haskey('fifo') then begin
    dict.fifo = !null    ; this contains the unused bytes from a previous call
    dict.flag = 0
    ;self.verbose=3
  endif


  on_ioerror, nextfile
  time = systime(1)
  dict.time_received = time

  msg = '' ;time_string(dict.time_received,tformat='hh:mm:ss.fff -',local=localtime)

  nbytes = 0UL
  sync_errors =0ul
  total_bytes = 0L
  endofdata = 0
  while ~endofdata do begin

    if dict.fifo eq !null then begin
      dict.n2read = self.header_size
      dict.headerstr = !null
      dict.packet_is_valid = 0
    endif
    nb = dict.n2read

    buf= self.read_nbytes(nb,source,pos=nbytes)
    nbuf = n_elements(buf)

    if nbuf eq 0 then begin
      dprint,verbose=self.verbose,dlevel=4,'No more data'
      break
    endif

    bytes_missing = nb - nbuf   ; the number of missing bytes in the read

    dict.fifo = [dict.fifo,buf]
    nfifo = n_elements(dict.fifo)

    if bytes_missing ne 0 then begin
      dict.n2read = bytes_missing
      if ~isa(buf) then endofdata =1
      continue
    endif

    if ~isa(dict.headerstr) then begin
           
      dict.headerstr = self.header_struct(dict.fifo)
      if ~isa(dict.headerstr) then    begin     ; invalid structure: Skip a byte and try again      
        dict.fifo = dict.fifo[1:*]
        dict.n2read = 1
        nb = 1
        sync_errors += 1
        continue      ; read one byte at a time until sync is found
      endif
      dict.packet_is_valid = 0
    endif

    if ~dict.packet_is_valid then begin
      nb = dict.headerstr.psize
      if nb eq 0 then begin
        dprint,verbose = self.verbose,dlevel=2,self.name+'; Packet length with zero length'
        dict.fifo = !null
      endif else begin
        dict.packet_is_valid =1
        dict.n2read = nb
      endelse
      continue            ; continue to read the rest of the packet
    endif


    if sync_errors ne 0 then begin
      dprint,verbose=self.verbose,dlevel=2,sync_errors,' GSEMSG sync errors',dwait =4.
    endif

    ; if it reaches this point then a valid message header+payload has been read in

    self.handle,dict.fifo    ; process each packet

    if keyword_set(dict.flag) && debug(2,self.verbose,msg='status') then begin
      dprint,verbose=self.verbose,dlevel=3,header
      ;dprint,'gsehdr: ',n_elements(gsehdr)
      ;hexprint,gsehdr
      ;dprint,'payload: ',n_elements(payload)
      ;hexprint,payload
      dprint,'fifo: ', n_elements(dict.fifo)  ;,'   ',time_string(gsemsg.time)
      hexprint,dict.fifo
      dprint
    endif

    dict.fifo = !null

  endwhile

  if sync_errors ne 0 then begin
    dprint,verbose=self.verbose,dlevel=2,self.name+': '+strtrim(sync_errors,1)+' sync errors at "'+time_string(dict.time_received)+'"'
    ;printdat,source
    ;hexprint,source
  endif


  if 0 then begin
    nextfile:
    dprint,!error_state.msg
    dprint,'Skipping file'
  endif

  if nbytes ne 0 then msg += string(/print,nbytes,format='(i6 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,verbose=self.verbose,dlevel=3,msg
  dict.msg = msg

end



pro ccsds_frame_reader::handle,buffer

  if debug(4,self.verbose) then begin
    dprint,self.name
    hexprint,buffer
    dprint
  endif
  payload = buffer[self.header_size : -5]    ; skip header and leave off the last 4 bytes.  Not clear what they are.
  
  
  headerstr = self.source_dict.headerstr
  offset = headerstr.offset
  cpkt_rdr = self.ccsds_packet_reader
  if cpkt_rdr.source_dict.haskey('FIFO') then begin
    length_fifo  =  n_elements(cpkt_rdr.source_dict.fifo)  
    if isa(cpkt_rdr.source_dict.headerstr) then begin
      psize =  cpkt_rdr.source_dict.headerstr.psize
    endif
  endif else begin
    length_fifo = 0
  endelse
  
  
  if length_fifo eq 0  then begin   ; First time there won't be a pre-existing FIFO;  skip the beginning bytes and start at offset
    ;cpkt_rdr.read, payload[offset:*]
    start = offset
  endif else begin
    if offset eq 0x7ff then begin
      dprint,dlevel=3,verbose=self.verbose, 'No start packet'
      start = 0
    endif else begin
      if keyword_set(psize) && psize + 6 ne length_fifo+offset then begin
        dprint,dlevel=2,verbose=self.verbose, 'concatenate: ',psize+6,length_fifo,offset
        start = offset         ; start new sequence
        cpkt_rdr.source_dict.fifo=!null
        cpkt_rdr.source_dict.headerstr=!null
      endif else start = 0
    endelse    
  endelse

  cpkt_rdr.read,   payload[start:*]     
  
  
end





function ccsds_frame_reader::init,sync_pattern=sync_pattern,sync_mask=sync_mask,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if isa(mission,'string') && mission eq 'SWFO' then begin
    if ~isa(sync_pattern) then sync_pattern = ['1a'xb,  'cf'xb ,'fc'xb, '1d'xb ]
    ;decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  self.sync_size = n_elements(sync_pattern)
  self.maxsize = 1100
  self.minsize = 1000
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then begin
    self.sync_pattern = sync_pattern
    self.sync_mask = ['ff'xb,  'ff'xb ,'ff'xb, 'ff'xb ]
  endif
  if isa(sync_mask) then self.sync_mask = sync_mask
  self.header_size = self.sync_size + 8
  self.frame_size = 1024
  self.save_data = 1
  self.ccsds_packet_reader = ccsds_reader(mission=mission,/no_widget,sync_pattern=!null)

  return,1
end





PRO ccsds_frame_reader__define
  void = {ccsds_frame_reader, $
    inherits cmblk_reader, $    ; superclass
    frame_size: 0uL, $
    decom_procedure: '',  $
    ccsds_packet_reader: obj_new(),  $
    minsize: 0UL , $
    maxsize: 0UL  $
  }
END




