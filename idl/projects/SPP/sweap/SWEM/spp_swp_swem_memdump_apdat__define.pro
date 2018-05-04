
 
 
function spp_swp_swem_memdump_apdat::decom,ccsds,header

  ccsds_data = spp_swp_ccsds_data(ccsds)

  strct = {  $
    time:ccsds.time, $
    seqn:ccsds.seqn, $
    bsize: ccsds.pkt_size-14, $
    addr: 0ul, $
    memp: ptr_new(),  $
    gap: ccsds.gap  $
  }


  strct.bsize = ccsds.pkt_size -14

  mem = !null
  b = ccsds_data[10:*]
  strct.addr = ((b[0]*256uL+b[1])*256Ul+b[2])*256Ul+b[3]
  if ccsds.pkt_size gt 14 then   mem = b[4:*] else dprint,dlevel=1,'Mem dump with 0 size. Address:',strct.addr
  strct.memp = ptr_new(mem)
  if debug(self.dlevel+2) then begin
    dprint,strct.addr, n_elements(mem),format='(Z08, i)'
    hexprint,mem
  endif
  
  return,strct
end




 
PRO spp_swp_swem_memdump_apdat__define
void = {spp_swp_swem_memdump_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  temp1 : 0u, $
  buffer: ptr_new()   $
  }
END



