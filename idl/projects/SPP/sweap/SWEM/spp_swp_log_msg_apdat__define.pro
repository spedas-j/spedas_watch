function spp_swp_log_msg_apdat::decom,ccsds, ptp_header=ptp_header   ;, apdat=apdat,dlevel=dlevel

  ;printdat,ccsds
  ;time=ccsds.time
  ;printdat,ptp_header
  ;hexprint,ccsds.data

  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

;  dprint,ptp_header.ptp_time - ccsds.time,'  '+time_string(ptp_header.ptp_time),dlevel=4
  if keyword_set(ptp_header) then ccsds.time = ptp_header.ptp_time   ; Correct the time
  
  
  
 ; time = ptp_header.ptp_time
  time=ccsds.time
  ccsds_data = spp_swp_ccsds_data(ccsds)  
 ; printdat,self
  if debug(self.dlevel+4) then begin
     printdat,ccsds
     hexprint,ccsds_data
  endif
  bstr = ccsds_data[10:*]
  if 1 then begin
    w = where(bstr gt  16,/null)
    bstr = bstr[w]
  endif
  msg = string(bstr)
  dprint,dlevel=self.dlevel+2,time_string(time)+  ' "'+msg+'"'
  str={time:time,seqn:ccsds.seqn,size:ccsds.pkt_size,msg:msg}
  return,str

end



PRO spp_swp_log_msg_apdat__define

  void = {spp_swp_log_msg_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    filename : '', $
    fileunit : 0,   $
    flag: 0 $
  }
END


