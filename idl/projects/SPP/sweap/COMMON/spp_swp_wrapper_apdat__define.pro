


pro spp_swp_wrapper_apdat::handler2,buffer,wrapper_header=wrapper_header, wrapper_apid= wrapper_apid
  
  if debug(self.dlevel+5,msg='handler2')  then begin  ;  wrapper_header[10] ne 0 && 
    dprint,'wrapper header:'
    hexprint,wrapper_header
    dprint,'header of inner packet:'    
    hexprint,buffer[0:19]
;    dprint,'data of inner packet:'    
;    hexprint,buffer[20:*]
  endif
  if wrapper_header[10] ne 0 then begin
    dprint,dlevel=self.dlevel+3,wrapper_header    
  endif
  ;hexprint,wrapper_header
  if (wrapper_header[10] and '80'x) ne 0 then begin   ; compressed packet
    dprint,dlevel = self.dlevel+3, 'compressed packet ',wrapper_header[10] 
    buffer = spp_swp_swem_part_decompress_data(buffer,decomp_size =  decomp_size, /stuff_size )
    dprint,dlevel = self.dlevel+3,decomp_size     
  endif
  if debug(self.dlevel+5) then begin
    dprint,'header of packet:'
    hexprint,buffer[0:19]
    data = buffer[20:*]
    if 0 then begin
      dprint,'data of decomp packet:'
      hexprint,data
    endif
    dprint,'data signature:'
    w = where(data)
    dprint,fix(w)
    dprint,fix(data[w])
  endif
  if debug(self.dlevel+5) then printdat,buffer,/hex
  spp_ccsds_pkt_handler,buffer, wrapper_apid = self.apid,original_size=original_size   ; recursively handle the inner packet

end



 
function spp_swp_wrapper_apdat::decom,ccsds,ptp_header


dnan = !values.d_nan
wrap_ccsds = create_struct( ccsds,  $
  {  $
  content_time_diff: dnan , $   ; difference in time between wrapper met and content met
  content_apid: 0u    , $          ; will replace content_id
  content_compressed:  0b  $
  } )


; struct_assign,ccsds,wrap_ccsds,/no_zero


ccsds_data = spp_swp_ccsds_data(ccsds)

*wrap_ccsds.pdata  = !null  ; Not sure if it is useful to keep this info


if ccsds.pkt_size le 22 then begin
  dprint,'Wrapper packet error - APID:',ccsds.apid,ccsds.pkt_size,dlevel=1,dwait = 10.
  ;printdat,ccsds
  return, wrap_ccsds
endif

content_met = spp_swp_data_select(ccsds_data,8*18,32)  ; extract MET from inner packet
wrap_ccsds.content_time_diff = ccsds.met - content_met

;self.dlevel=2
if debug(self.dlevel+5,msg='wrapper') then begin
  hexprint,ccsds_data
endif


if keyword_set(self.buffer) eq 0 then self.buffer = ptr_new(!null)   ; Should be put in init routine

case ccsds.seq_group of 
  1: begin
    self.cummulative_size = ccsds.pkt_size
    self.active_apid = spp_swp_data_select(ccsds_data,8*12+5,11)   ;  apid of wrapped packet
    wrap_ccsds.content_apid = self.active_apid
    dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Start multi-packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
    if debug(self.dlevel+3) then begin
      printdat, /hex,*ccsds.pdata
    endif
    *self.buffer = ccsds_data[12:*]
  end
  0: begin
    self.cummulative_size += ccsds.pkt_size
    wrap_ccsds.content_apid = self.active_apid
    dprint,dlevel=self.dlevel+1,'Never expect this on SPP! except for really big packets'
    ;printdat,ccsds
    if keyword_set(*self.buffer)  then begin
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Mid multi packet'
      *self.buffer = [*self.buffer,ccsds_data[12:*] ]  ; append final segment
    endif else dprint,dlevel=self.dlevel+1,'Error'
  end
  2: begin
    self.cummulative_size += ccsds.pkt_size
    wrap_ccsds.content_apid = self.active_apid
    if ccsds.seqn_delta ne 1 then begin
      dprint,dlevel=self.dlevel+1,'Missing packets - aborting End of multi-packet'
    endif else begin
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' End multi-packet'
      if debug(self.dlevel+3) then begin
        printdat, /hex,*ccsds.pdata
      endif
      *self.buffer = [*self.buffer,ccsds_data[12:*] ]  ; append final segment
      self.handler2, *self.buffer, wrapper_header = ccsds_data[0:11], wrapper_apid = ccsds.apid
    endelse
    *self.buffer = !null
;    self.active_apid = 0
  end
  3: begin
    self.cummulative_size = ccsds.pkt_size
    self.active_apid = spp_swp_data_select(ccsds_data,8*12+5,11)   ;  apid of wrapped packet
    wrap_ccsds.content_apid = self.active_apid
;    print,self.active_apid,self.apid
    dprint,dlevel=self.dlevel+4,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Single packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
    *self.buffer = ccsds_data[12:*]
    self.handler2,*self.buffer, wrapper_header = ccsds_data[0:11], wrapper_apid = ccsds.apid
    *self.buffer = !null
 ;   self.active_apid = 0
  end
     
endcase


;if 0 then begin
;  if self.save_flag && keyword_set(strct) then begin
;    dprint,self.name,dlevel=5,self.apid
;    self.data.append,  strct
;  endif
;  
;  *self.last_data_p = strct
;  
;  if self.rt_flag && keyword_set(strct) then begin
;    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
;    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP'
;  endif
;endif

return, wrap_ccsds


end
 
 
 
 
PRO spp_swp_wrapper_apdat__define
void = {spp_swp_wrapper_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  active_apid : 0u, $
  cummulative_size : 0U, $
  buffer: ptr_new()   $
  }
END



