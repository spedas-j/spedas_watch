;+
;  cmblk_reader
;  This basic object is the entry point for defining and obtaining all data from common block files
; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gen_apdat__define.pro $
;-
COMPILE_OPT IDL2


FUNCTION cmblk_reader::Init,name,_EXTRA=ex
  ; Call our superclass Initialization method.
  if ~keyword_set(name) then name = 'CmBlk'
  void = self->socket_reader::Init(name,_EXTRA = ex)
  ;self.dlevel = 2
  ;self.verbose = 2
  self.name  =name
  self.handlers = orderedhash()
  self.sync  = 'CMB1'
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel,verbose=self.verbose
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  
  self.add_handler, 'raw_tlm',  swfo_raw_tlm('SWFO_raw_telem',/no_widget)
  self.add_handler, 'KEYSIGHTPS' ,  cmblk_keysight('Keysight',/no_widget)

  
  RETURN, 1
END




PRO cmblk_reader::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  dprint,"killing object:", self.name
  self->socket_reader::Cleanup
END


function cmblk_reader::header_struct,buf

  cmb = {  $
    sync: 0ul, $
    size: 0ul, $
    time: 0d,  $
    seqn: 0u,  $
    user: 0u,  $
    source: 0u,$   ; byte stored as uint
    type: 0u,  $   ; byte stored as uint
    ;   desc_array: bytarr(10) ,     $
    description:'', $
    gap:0}

  cmb.sync  = swap_endian(/swap_if_little_endian, ulong(buf,0,1) )
  cmb.size  = swap_endian(/swap_if_little_endian, ulong(buf,4,1) )
  cmb.time  = swap_endian(/swap_if_little_endian, double(buf,8,1) )
  cmb.seqn  = swap_endian(/swap_if_little_endian, uint(buf,16,1) )
  cmb.user  = swap_endian(/swap_if_little_endian, uint(buf,18,1) )
  cmb.source=   buf[20]    ; byte stored as a uint
  cmb.type  =   buf[21]    ; byte stored as a uint
  desc_array = buf[22:31]
  ;swap_endian_inplace,cmb,/swap_if_little_endian
  w = where(desc_array gt 48b,/null)
  payload_key = desc_array[w]
  if isa(payload_key ) then  cmb.description = string(payload_key)
  return,cmb
end


pro cmblk_reader::lun_read    ;,nbytes

  dwait = 10.
  sync = swap_endian(ulong(byte('CMB1'),0,1),/swap_if_little_endian)

  ; on_ioerror, nextfile
  time = systime(1)
  last_time = self.time_received
  if last_time eq 0 then last_time=!values.d_nan
  self.time_received = time
  self.msg = time_string(time,tformat='hh:mm:ss - ',local=localtime)
  remainder = !null
  nbytes = 0UL
  npkts  = 0UL
  sync_errors = 0UL
  eofile = 0

  nb = 32   ; number of bytes to be read to get the full header

  while isa( (buf = self.read_nbytes(nb,pos=nbytes) )   ) do begin
    ;readu,in_lun,buf,transfer_count=nb
    if debug(4,self.verbose,msg='cmbhdr: ') then begin
      ;dprint,nb,dlevel=4
      hexprint,buf
    endif
    msg_buf = [remainder,buf]
    cmbhdr = self.header_struct(msg_buf)
    if debug(3,self.verbose) then begin
      dprint,'CMB: ',time_string(cmbhdr.time,prec=3),' ',cmbhdr.seqn,cmbhdr.size,'  ',cmbhdr.description
    endif
    if cmbhdr.sync ne sync || cmbhdr.size gt 30000 then begin
      remainder = msg_buf[1:*]
      nb = 1             ; advance one byte at a time looking for the sync
      ;if debug(2) then begin
      dprint,verbose=self.verbose,dlevel=1,'Lost sync:',dwait=dwait
      sync_errors++
      ;endif
      continue
    endif

    ;  read .skipthe payload bytes
    payload_buf = self.read_nbytes(cmbhdr.size,pos=nbytes)
    npkts++

    ; decomutate data here!
    self.source_dict.cmbhdr = cmbhdr
    self.handle, payload_buf, source_dict=self.source_dict  ;, cmbhdr=cmbhdr

  endwhile
  if sync_errors then begin
    dprint,verbose=self.verbose,dlevel=0,'Encountered '+strtrim(sync_errors,2)+' Errors'
  endif
  delta_time = time - last_time
  self.nbytes += nbytes
  self.npkts  += npkts
  self.nreads += 1
  ;self.brate = nbytes / delta_time
  ;self.prate = npkts / delta_time
  self.msg += strtrim(nbytes,2)+ ' bytes'

  if 0 then begin
    nextfile:
    dprint,verbose=self.verbose,dlevel=0,'File error? '
    self.help
  endif

  if 0 then begin
    data_str = {  $
      time:cmblk.time, $
      time_delta: 0., $
      seqn:     0u ,   $
      seqn_delta:  0u, $
      size:  cmblk.size, $
      gap:0  $
    }

  endif


  dprint,verbose=self.verbose,dlevel=3,self.msg

end




pro cmblk_reader::handle,payload, source_dict=source_dict   ; , cmbhdr= cmbhdr

  ; Decommutate data
  cmbhdr = source_dict.cmbhdr
  descr_key = cmbhdr.description
  handlers = self.handlers
  if handlers.haskey( descr_key ) eq 0  then begin        ; establish new ones if not already defined
    dprint,verbose=self.verbose,dlevel=1,'Found new description key: "', descr_key,'"'
    new_obj =  socket_reader(descr_key,title=descr_key,/no_widget,verbose=self.verbose)
    handlers[descr_key] = new_obj
  endif

  if self.run_proc then begin
    d = self.source_dict
    d.cmbhdr = cmbhdr
    handler =  handlers[descr_key]                     ; Get the proper handler object
    if obj_valid(handler) then begin
      handler.handle, payload, source_dict=d         ; execute handler
    endif else begin
      dprint,verbose=self.verbose,dlevel=1,'Invalid handle object for cmblk_key: "',descr_key,'"'
    endelse
  endif
end







pro cmblk_reader::add_handler,key,object
  ;help,hds,object
  if isa(key,'HASH') then begin
    self.handlers += key
  endif else begin
    self.handlers[key]= object
  endelse
  dprint,'Added new handler: ',key,verbose=self.verbose,dlevel=1
  ;help,self.handlers
end


function cmblk_reader::get_handlers, key
  retval = !null
  handlers = self.handlers
  if obj_valid(handlers) then begin
    if  isa(key,/string) then begin
      if handlers.haskey(key) then retval = handlers[key]
    endif else  retval = handlers
  endif
  return,retval
end



PRO cmblk_reader__define
  void = {cmblk_reader, $
    inherits socket_reader, $    ; superclass
    handlers:     obj_new(),  $
    sync:  'CMB1'     $         ;
  }
END


