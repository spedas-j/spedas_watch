 
 
pro spp_swp_wrapper_apdat::handler,ccsds,ptp_header

;self.increment_counters, ccsds

ccsds_data = spp_swp_ccsds_data(ccsds)

;self.dlevel=2

if keyword_set(self.buffer) eq 0 then self.buffer = ptr_new(!null)   ; Should be put in init routine

case ccsds.seq_group of 
  1: begin
    dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Start multi-packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel+2,'Warning: New Multipacket started without finishing previous group'
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
      dprint,dlevel=self.dlevel+2,'Missing packets - aborting End of multi-packet'
    endif else begin
      dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' End multi-packet'
      *self.buffer = [*self.buffer,ccsds_data[12:*] ]  ; append final segment
      spp_ccsds_pkt_handler, *self.buffer
    endelse
    *self.buffer = !null
  end
  3: begin
    dprint,dlevel=self.dlevel+3,ccsds.apid,ccsds.seqn,ccsds.seqn_delta,ccsds.seq_group,' Single packet'
    if keyword_set(*self.buffer) then dprint,dlevel=self.dlevel,'Warning: New Multipacket started without finishing previous group'
    *self.buffer = ccsds_data[12:*]
    spp_ccsds_pkt_handler,*self.buffer  
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



