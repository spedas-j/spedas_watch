; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-20 17:44:34 -0800 (Mon, 20 Nov 2023) $
; $LastChangedRevision: 32254 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/ccsds_reader__define.pro $



;+
;  PROCEDURE ccsds_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-






function ccsds_reader::header_struct,header

  nsync = self.sync_size
  if nsync ne 0 then  sync = self.sync_pattern[0:nsync-1] else sync = !null
  
  if n_elements(header) lt self.header_size then return, !null                    ; Not enough bytes in packet header
  if  (isa(sync) && array_equal(sync,header[0:nsync-1]) eq 0) then return,!null   ; Not a valid packet

  strct = {  time:!values.d_nan, apid:0u,  psize: 0u , type:0u ,valid:0, gap:0}
  strct.apid  = (header[nsync+0] * 256U + header[nsync+1]) and 0x3FFF 
  strct.psize = header[nsync+4] * 256u + header[nsync+5] + 1   ; size of payload  (6 bytes less than size of ccsds packet)

  return,strct

end







pro ccsds_reader::read_old,source   ;,source_dict=parent_dict

  ;dwait = 10.
  
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



pro ccsds_reader::handle,buffer

  if debug(3,self.verbose) then begin
    dprint,self.name
    hexprint,buffer
    dprint
  endif

  swfo_ccsds_spkt_handler,buffer[self.sync_size:*],source_dict=self.source_dict         ; Process the complete packet

end





function ccsds_reader::init,sync_pattern=sync_pattern,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if isa(mission,'string') && mission eq 'SWFO' then begin
    if ~isa(sync_pattern) then sync_pattern = ['1a'xb,  'cf'xb ,'fc'xb, '1d'xb ]
    decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  self.sync_size = n_elements(sync_pattern)
  self.maxsize = 4100
  self.minsize = 10
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then self.sync_pattern = sync_pattern 
  self.header_size = self.sync_size + 6

  return,1
end





PRO ccsds_reader__define
  void = {ccsds_reader, $
    inherits cmblk_reader, $    ; superclass
    decom_procedure: '',  $
    minsize: 0UL , $
    maxsize: 0UL  $
  }
END




