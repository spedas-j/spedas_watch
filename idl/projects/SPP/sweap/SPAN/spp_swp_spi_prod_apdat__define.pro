;+
; spp_swp_spi_prod_apdat
; $LastChangedBy: $
; $LastChangedDate:  $
; $LastChangedRevision: $
; $URL: $
;-



pro spp_swp_spi_prod_apdat::prod_16A, strct

  pname = '16A_'
  data = *strct.pdata
  strct2 = {time:strct.time, $
    SPEC:data,  $
    gap: strct.gap}
    
  self.prod_16A.append, strct2
  self.store_data, strct2, pname
  return
end




;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A -
pro spp_swp_spi_prod_apdat::prod_32Ex16A, strct
  pname = '32Ex16A_'
  data = *strct.pdata

  data = reform(data,32,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: strct.gap}

  self.prod_32Ex16A.append, strct2
  self.store_data, strct2, pname

end



;
;pro spp_swp_spi_prod_apdat::prod_16Ax32E, strct
;  message,'bad routine'
;  pname = '16Ax32E_'
;  strct = {time:header_str.time, $
;    cnts_Anode:data,  $
;    gap: 0}
;  if apdat.rt_flag && apdat.rt_tags then begin
;    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
;  endif
;end


pro spp_swp_spi_prod_apdat::prod_8Dx32Ex16A, strct   ; this function needs fixing

  data = *strct.pdata
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return
  endif
  pname = '8Dx32Ex16A_'
  spec1 = total(reform(data,16,8*32),2)   ; This is wrong
  spec2 = total( total(data,1) ,2 )      ;  This is wrong
  spec3 = total(reform(data,16*8,32),1)    ; This is wrong
  spec23 = total(reform(data,16,8*32),1)   ; this is wrong
  spec12 = total(reform(data,8*32,16),2)
  spec123 = reform(data,8*32*16)

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    spec12:spec12, $
    spec123:spec123, $
    gap: strct.gap}

  self.prod_8Dx32Ex16A.append, strct2
  self.store_data, strct2, pname
end



pro spp_swp_spi_prod_apdat::prod_32Ex16Ax4M, strct  ; this function needs fixing
  data = *strct.pdata
  if n_elements(data) ne 2048 then begin
    dprint,'bad size'
    return
  endif
  pname = '32Ex16Ax4M_'
  data = reform(data,32,16,4,/overwrite)
  spec1 = total(reform(data,32,16*4),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,32*16,4),1)
  spec23 = total(reform(data,32,16*4),1)

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: strct.gap}
    
  self.prod_32Ex16Ax4M.append, strct2
  self.store_data, strct2, pname
end



pro spp_swp_spi_prod_apdat::prod_8Dx32EX16Ax2M, strct   ; this function needs fixing
  data = *strct.pdata
  if n_elements(data) ne 8192 then begin
    dprint,'bad size'
    return
  endif
  pname = '8Dx32Ex16Ax2M_'
  data = reform(data,8,32,16,2,/overwrite)
  spec1 = total(reform(data,8,32*16*2),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(total(reform(data,8*32,16,2),1) ,2)
  spec23 = total(total(reform(data,8,32*16,2),1), 2)

  ;  printdat,spec1,spec2,spec2,spec23

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap:  strct.gap}
  self.prod_8Dx32Ex16Ax2M.append, strct2
  self.store_data, strct2, pname
end



pro spp_swp_spi_prod_apdat::prod_8Dx32Ex16Ax1M, strct   ; this function needs fixing
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return
  endif
  pname = '8Dx32Ex16Ax1M_'
  data = reform(data,8,32,16,/overwrite)
  spec1 = total(reform(data,8,32*16),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,8*32,16),1)
  spec23 = total(reform(data,8,32*16),1)

  strct2 = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap:  strct.gap}
  self.prod_8Dx32Ex16Ax2M.append, strct2
  self.store_data, strct2, pname
end


pro spp_swp_spi_prod_apdat::prod_16Ax16M, strct   ; this function needs fixing
  if n_elements(data) ne 256 then begin
    dprint,'bad size'
    return
  endif
  pname = '16Ax16M_'
  data = reform(data,16,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: strct.gap}
  self.prod_16Ax16M.append, strct2
  self.store_data, strct2, pname
end








function spp_swp_spi_prod_apdat::decom,ccsds,ptp_header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_swp_spi_prod_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

pksize = ccsds.pkt_size
if pksize le 20 then begin
  dprint,dlevel = 2, 'size error - no data'
  return, 0
endif

ccsds_data = spp_swp_ccsds_data(ccsds)
if pksize ne n_elements(ccsds_data) then begin
  dprint,dlevel=1,'Product size mismatch'
  return,0
endif

header    = ccsds_data[0:19]
ns = pksize - 20
log_flag  = header[12]
mode1 = header[13]
mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
status_flag = header[18]
peak_bin = header[19]

;  if ptr_valid(apdat.last_ccsds) && keyword_set(*apdat.last_ccsds) then  delta_t = ccsds.time - (*(apdat.last_ccsds)).time else delta_t = !values.f_nan

compression = (header[12] and 'a0'x) ne 0
bps =  ([4,1])[ compression ]

ndat = ns / bps

if ns gt 0 then begin
  data      = ccsds_data[20:*]
  ; data_size = n_elements(data)
  if compression then    cnts = spp_swp_log_decomp(data,0) $
  else    cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )
  tcnts = total(cnts)
endif else begin
  tcnts = -1.
  cnts = 0
endelse

str = { $
  time:        ccsds.time, $
  apid:        ccsds.apid, $
  time_delta:  ccsds.time_delta, $
  seqn:        ccsds.seqn,  $
  seqn_delta:  ccsds.seqn_delta,  $
  seq_group:   ccsds.seq_group,  $
  pkt_size :   ccsds.pkt_size,  $
  ndat:        ndat, $
  datasize:    ns, $
  log_flag:    log_flag, $
  mode1:        mode1,  $
  mode2:        mode2,  $
  f0:           f0,$
  status_flag: status_flag,$
  peak_bin:    peak_bin, $
  cnts_total:  tcnts,  $
  pdata:        ptr_new(data), $
  gap:         ccsds.gap  }

return,str
end




pro spp_swp_spi_prod_apdat::handler,ccsds,ptp_header

;  self.increment_counters,ccsds,ptp_header

  strct = self.decom(ccsds)
  
  if self.save_flag && keyword_set(strct) then begin
    dprint,self.name,dlevel=5,self.apid
    self.data.append,  strct
  endif

  ns=1
  if  ns gt 0 then begin
    case strct.ndat  of
      16:   self.prod_16a,  strct
      256:  self.prod_16Ax16M, strct
      512:  self.prod_32Ex16A, strct
      2048: self.prod_32Ex16Ax4M, strct
      4096: self.prod_8Dx32Ex16A, strct
      8192: self.prod_8Dx32EX16Ax2M, strct
      else:  dprint,dlevel=2,'Size not recognized: ',ndat
    endcase
  endif


  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
    store_data,self.tname,data=strct, tagnames=self.rt_tags , append = 1
  endif
end
 
 
 

 
 
; 
;PRO spp_swp_spi_prod_apdat::GetProperty, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, nsamples=nsamples,strct=strct,ccsds_last=ccsds_last ;,counter=counter
;COMPILE_OPT IDL2
;;IF (ARG_PRESENT(counter)) THEN counter = self.counter
;IF (ARG_PRESENT(name)) THEN name = self.name
;IF (ARG_PRESENT(apid)) THEN apid = self.apid
;IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
;IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
;IF (ARG_PRESENT(array)) THEN array = self.data.array
;IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
;IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data_array)
;if (arg_present(strct) ) then begin
;  strct = {spp_swp_spi_prod_apdat}
;  struct_assign , self, strct
;endif
;END
; 
 


FUNCTION spp_swp_spi_prod_apdat::Init,apid,name,_EXTRA=ex
  void = self->spp_gen_apdat::Init(apid,name)   ; Call our superclass Initialization method.
  self.prod_16A     = obj_new('dynamicarray',name='prod_16A')
  self.prod_32Ex16A = obj_new('dynamicarray',name='prod_32Ex16A')
  self.prod_8Dx32Ex16A=  obj_new('dynamicarray',name='prod_8Dx32Ex16A')
  self.prod_32Ex16Ax4M=  obj_new('dynamicarray',name='prod_32Ex16Ax4M')
  self.prod_8Dx32EX16Ax1M=  obj_new('dynamicarray',name='prod_8Dx32EX16Ax1M')
  self.prod_8Dx32EX16Ax2M=  obj_new('dynamicarray',name='prod_8Dx32EX16Ax2M') 
  RETURN, 1
END



PRO spp_swp_spi_prod_apdat::Clear
  self->spp_gen_apdat::Clear
  self.prod_16A.array     = !null
  self.prod_32Ex16A.array = !null
  self.prod_8Dx32Ex16A.array = !null
  self.prod_32Ex16Ax4M.array = !null
  self.prod_8Dx32EX16Ax1M.array = !null
  self.prod_8Dx32EX16Ax2M.array = !null
END




pro spp_swp_spi_prod_apdat::finish

;  dprint,dlevel=3,'Finishing ',self.name,self.apid
  ;  das = [self.data,self.
  store_data,self.tname,data=self.data.array, tagnames=self.save_tags,gap_tag='GAP',verbose=0

;  store_data, self.data.array , self.data.name
;  self.store_data, self.prod_16A.array , self.prod_16A.name
;  self.store_data, self.prod_32Ex16A.array , self.prod_32Ex16A.name
;  self.store_data, self.prod_8Dx32Ex16A.array , self.prod_8Dx32Ex16A.name
;  self.store_data, self.prod_32Ex16Ax4M.array , self.prod_32Ex16Ax4M.name
;  self.store_data, self.prod_8Dx32EX16Ax1M.array , self.prod_8Dx32EX16Ax1M.name
;  self.store_data, self.prod_8Dx32EX16Ax2M.array , self.prod_8Dx32EX16Ax2M.name
;  self.store_data,self.tname+'',data=self.data.array, tagnames=self.save_tags
;  store_data,self.tname+'_2',data= self.data2.array,  tagnames = '*'
end

 
PRO spp_swp_spi_prod_apdat__define
void = {spp_swp_spi_prod_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  prod_16A     : obj_new(), $
  prod_32Ex16A : obj_new(), $
  prod_8Dx32Ex16A:  obj_new(), $
  prod_32Ex16Ax4M:  obj_new(), $
  prod_8Dx32EX16Ax1M:  obj_new(), $
  prod_8Dx32EX16Ax2M:  obj_new() $
  }
END



