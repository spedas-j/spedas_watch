
 
function spp_swp_moments_apdat::decom,ccsds,source_dict=source_dict
 
; this routine is a place holder...
   
  ccsds_data = spp_swp_ccsds_data(ccsds)

  strct = {  $
     time:ccsds.time, $
     seqn:ccsds.seqn, $
     pkt_size: ccsds.pkt_size, $
     sci_header: bytarr(20),  $    ;sci_header
     moms : dblarr(13), $
     gap: ccsds.gap  $
  }

  pkt_header = ccsds_data[0:9]
  strct.sci_header = ccsds_data[10:29]
  if ccsds.pkt_size eq 134 then begin
     byte_data = ccsds_data[30:133]
     i64_data = long64(byte_data,0,13)
     byteorder,i64_data,/swap_if_little_endian,/l64
     strct.moms = i64_data / (2d^16)                      ; This conversion is a guess only!
  endif
  
  dprint,dlevel=self.dlevel+3, phelp=2,strct
  if debug(self.dlevel+3) then begin
     hexprint,byte_data
     hexprint,i64_data
     print,i64_data/ 2d^16
  endif
  
  return,strct
end


 
 
 
PRO spp_swp_moments_apdat__define
void = {spp_swp_moments_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  temp1 : 0u, $
  buffer: ptr_new()   $
  }
END



