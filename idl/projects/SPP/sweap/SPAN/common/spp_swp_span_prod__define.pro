;+
; spp_swp_span_prod
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-24 11:18:02 -0700 (Wed, 24 Apr 2019) $
; $LastChangedRevision: 27080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_span_prod__define.pro $
;-


function spp_swp_span_prod::fill,ccsds

message,'Not working yet'
return,str
end





 
PRO spp_swp_span_prod__define ,productstr, ccsds

  productstr = !null

  if not keyword_set(ccsds) then begin
    dummybuf = byte([11, 68, 192, 190, 0, 13, 16, 120, 39, 204, 16, 120, 39, 203, 2, 20, 0, 0, 0, 1])
    ccsds = spp_swp_ccsds_decom(dummybuf)
  endif

  pksize = ccsds.pkt_size
;  if pksize le 20 then begin
;    dprint,dlevel = 2, 'size error - no data'
;    return, !null
;  endif

;  if ccsds.aggregate ne 0 then begin
;    return, self.decom_aggregate(ccsds,source_dict=source_dict)
;  endif

  ccsds_data = spp_swp_ccsds_data(ccsds)


  if pksize ne n_elements(ccsds_data) then begin
    dprint,dlevel=1,'Product size mismatch'
    return
  endif

  header    = ccsds_data[0:19]

  apid = byte(ccsds.apid)
;  detnum = (ishft(apid,-4) and 'F'x) < 8
;  detectors = ['?','?','?','?','SWEM','SPC','SPA','SPB','SPI']
;  detname = detectors[detnum]

  if (apid and 'E0'x) eq '60'x then begin   ;  span - electron packets
    product_type = ishft( ((apid and 'ff'xb) - '60'xb ) and '6'xb , 3)
    product_type or= ishft( (apid and '10'xb) , 2)    ; set detector num (spa or spb)
    product_type or= ishft( (apid and '1'xb)  , 2)    ; set product number 
  endif

  if (apid and '80'x) ne 0  then begin   ;  span - ion packets
    tmp = (apid and 'ff'xb) -'80'xb 
    product_type =  ishft(  tmp / 12b, 4 ) 
    product_type or=  tmp mod 12b
    product_type or=  '80'xb
  endif

  ion       =  (product_type and '80'xb  ) ne 0
  det       =  (product_type and '40'xb  ) ne 0
  survey    =  (product_type and '20'xb ) ne 0 
  targeted  =  (product_type and '10'xb   ) ne 0  
  prodnum   =  product_type and '0f'xb 

  ns = pksize - 20
  ; L = 1 = Log Compress on ON
  ; CC = Meaningless
  ; S = 1 if Arch is Sampling
  ; S = 0 if Arch is Summing
  ; NNNN = the number of accumulation periods (1/4 NYS) for Archive.
  log_flag = header[12]
  smp_flag = (ishft(header[12],-4) AND 1)
  srvy_accum = (header[12] AND 15)
  ; Format here is 000SNNNN
  ; S = 1 if Arch is Sampling
  ; S = 0 if Arch is Summing
  ; NNNN = the number of accumulation periods (1/4 NYS) for Archive.
  arch_sum  = header[13] ; leftover from old code, leave to not break things [plw'18]
  mode1 = header[13]
  arch_smp_flag = ishft(header[13],-4) ; shift four bits to get 5th bit.
  arch_accum = (header[13] AND 15) ; remove the lower 4 bits.
  tot_accum_prd = 2 ^ (arch_accum + srvy_accum) ; in 1/4 NYS accumulation periods.
  ; Hold up folks! : look at the awesome use of the xor function below to invert the sum/sample bit! [plw'18]
  num_accum = 2 ^ (((arch_smp_flag xor 1) * arch_accum) + ((smp_flag xor 1) * srvy_accum)) 
  mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
  if ion then begin
    tmode = mode2 and 'f'x
    emode = ishft(mode2,-4) and 'f'x
    ;   emode = emode_ori
    pmode = ishft(mode2,-8) and 'f'x
    mmode = ishft(mode2,-12) and 'f'x
  endif else begin
    tmode = header[13]
    emode = header[14]    
  endelse
  f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
  status_bits = header[18]
  peak_bin = header[19]


  compression = (log_flag and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]

  ndat = ns / bps

  if ns gt 0 then begin
    data      = ccsds_data[20:*]
    ; data_size = n_elements(data)
    if compression then    cnts = float( spp_swp_log_decomp(data,0) ) $
    else    cnts = float(swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian ))
    tcnts = total(cnts)
  endif else begin
    tcnts = -1.
    cnts = 0.
  endelse





productstr = {spp_swp_span_prod, $
  time:        ccsds.time, $
;  Epoch:      0LL,  $
  MET:         ccsds.met,  $
  apid:        ccsds.apid, $
  time_delta:  ccsds.time_delta, $
  seqn:        ccsds.seqn,  $
  seqn_delta:  ccsds.seqn_delta,  $
  seq_group:   ccsds.seq_group,  $
  pkt_size :   ccsds.pkt_size,  $
  ndat:        ndat, $
  datasize:    ns, $
  log_flag:    log_flag, $
  smp_flag:    smp_flag, $
  mode1:       mode1,  $
  arch_sum:    arch_sum, $
  arch_smp_flag:  arch_smp_flag, $
  tot_accum_prd:  tot_accum_prd, $
  num_accum:   num_accum, $
  mode2_ori:   mode2,  $
  mode2:       mode2,  $
 ; tmode:       tmode, $
 ; emode:       emode, $
  product_type:   product_type,  $
  f0:          f0,$
  status_bits: status_bits,$
  peak_bin:    peak_bin, $
  cnts:        tcnts,  $
  ano_spec:    fltarr(16),  $
  nrg_spec:    fltarr(32),  $
  def_spec:    fltarr(8) ,  $
  mas_spec:    fltarr(16),  $
  ;  full_spec:   fltarr(256), $
  pdata:       ptr_new(cnts), $
  gap:         ccsds.gap  }

  
end


