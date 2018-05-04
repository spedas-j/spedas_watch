pro spp_swp_wrapper_apdat::handler2,buffer,wrapper_header=wrapper_header
  

  if debug(self.dlevel+5,msg='handler2')  then begin  ;  wrapper_header[10] ne 0 && 
    dprint,'wrapper header:'
    hexprint,wrapper_header
    dprint,'header of inner packet:'    
    hexprint,buffer[0:19]
;    dprint,'data of inner packet:'    
;    hexprint,buffer[20:*]
  endif
  if wrapper_header[10] ne 0 then begin   ; compressed packet
    dprint,dlevel = self.dlevel+3, 'compressed packet'
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
  spp_ccsds_pkt_handler,buffer

end



 
pro spp_swp_wrapper_apdat::handler,ccsds,ptp_header

;self.increment_counters, ccsds

ccsds_data = spp_swp_ccsds_data(ccsds)

;self.dlevel=2

if keyword_set(self.buffer) eq 0 then self.buffer = ptr_new(!null)   ; Should be put in init routine

case ccsds.seq_group of 
  1: begin
    dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Start multi-packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
    if debug(self.dlevel+3) then begin
      printdat, /hex,*ccsds.pdata
    endif
    *self.buffer = ccsds_data[12:*]
  end
  0: begin
    printdat,ccsds
    dprint,dlevel=self.dlevel+2,'Never expect this!'
    if keyword_set(*self.buffer)  then begin
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Mid multi packet'
      *self.buffer = [*self.buffer,ccsds_data[12:*] ]  ; append final segment
    endif else dprint,dlevel=self.dlevel+2,'Error'
  end
  2: begin
    if ccsds.seqn_delta ne 1 then begin
      dprint,dlevel=self.dlevel+1,'Missing packets - aborting End of multi-packet'
    endif else begin
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' End multi-packet'
      if debug(self.dlevel+3) then begin
        printdat, /hex,*ccsds.pdata
      endif
      *self.buffer = [*self.buffer,ccsds_data[12:*] ]  ; append final segment
      self.handler2, *self.buffer, wrapper_header = ccsds_data[0:11]
    endelse
    *self.buffer = !null
  end
  3: begin
    dprint,dlevel=self.dlevel+4,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Single packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
    *self.buffer = ccsds_data[12:*]
    self.handler2,*self.buffer, wrapper_header = ccsds_data[0:11]
    *self.buffer = !null
  end
     
endcase

apid = ccsds.apid
strct = {time:ccsds.time, $
  apid:apid, $
  seqn:ccsds.seqn, $
  seqn_delta:ccsds.seqn_delta, $
  seq_group:ccsds.seq_group, $
  pkt_size:ccsds.pkt_size, $
  gap:0 }



if self.save_flag && keyword_set(strct) then begin
  dprint,self.name,dlevel=5,self.apid
  self.data.append,  strct
endif

if self.rt_flag && keyword_set(strct) then begin
  if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
  store_data,self.tname,data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP'
endif





end
 
 
 
 
PRO spp_swp_wrapper_apdat__define
void = {spp_swp_wrapper_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  active_apid : 0u, $
  buffer: ptr_new()   $
  }
END



