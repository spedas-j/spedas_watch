;+
; spp_swp_span_prod
; $LastChangedBy: ali $
; $LastChangedDate: 2020-01-06 15:02:41 -0800 (Mon, 06 Jan 2020) $
; $LastChangedRevision: 28166 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_span_prod__define.pro $
;-



; SPP_SWP_SPI_PROD_APDAT
;
; APID: 0x380-0x3AF
; Descritpion: SPAN-Ai Science Packet
; Size: Vairable
;
;----------------------------------------------
; Byte  |   Bits   |        Data Value
;----------------------------------------------
;   0   | 00001aaa | ApID Upper Byte
;   1   | aaaaaaaa | ApID Lower Byte
;   2   | 11cccccc | Sequence Count Upper Byte
;   3   | cccccccc | Sequence Count Lower Byte
;   4   | LLLLLLLL | Message Length Upper Byte
;   5   | LLLLLLLL | Message Length Lower Byte
;   6   | MMMMMMMM | MET Byte 5
;   7   | MMMMMMMM | MET Byte 4
;   8   | MMMMMMMM | MET Byte 3
;   9   | MMMMMMMM | MET Byte 2
;  10   | ssssssss | MET Byte 1 [subseconds]
;  11   | ssssssss | s = MET subseconds
;       |          | x = Cycle Count LSBs
;       |          |     (sub NYS Indicator)
;  12   | LTCSNNNN | L = Log Compressed
;       |          | T = No Targeted Sweep
;       |          | C = Compress/Truncate TOF
;       |          | S = Summing
;       |          | N = 2^N Sum/Sample Period
;  13   | QQQQQQQQ | Spare
;  14   | mmmmmmmm | Mode ID Upper Byte
;  15   | mmmmmmmm | Mode ID Lower Byte
;  16   | FFFFFFFF | F0 Counter Upper Byte
;  17   | FFFFFFFF | F0 Counter Lower Byte
;  18   | AAtHDDDD | A = Attenuator State
;       |          | t = Test Pulser
;       |          | H = HV Enable
;       |          | D = HV Mode
;  19   | XXXXXXXX | X = Peak Count Step
;
; 20 - ???
; --------
; Science Product Data
;






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
  product_bits=0b
  if (apid and 'E0'x) eq '60'x then begin   ;  span - electron packets
    product_bits or= ishft( ((apid and 'ff'xb) - '60'xb ) and '6'xb , 3)
    product_bits or= ishft( (apid and '10'xb) , 2)    ; set detector num (spa or spb)
    product_bits or= ishft( (apid and '1'xb)  , 2)    ; set product number 
  endif

  if (apid and '80'x) ne 0  then begin   ;  span - ion packets
    tmp = (apid and 'ff'xb) -'80'xb 
    product_bits or=  ishft(  tmp / 12b, 4 ) 
    product_bits or=  tmp mod 12b
    product_bits or=  '80'xb
  endif
  
  ion       =  (product_bits and '80'xb  ) ne 0
  det       =  (product_bits and '40'xb  ) ne 0
  survey    =  (product_bits and '20'xb ) ne 0 
  targeted  =  (product_bits and '10'xb   ) ne 0  
  prodnum   =  product_bits and '0f'xb 

  ns = pksize - 20
  ; L = 1 = Log Compress on ON
  ; CC = Meaningless
  ; S = 1 if Arch is Sampling
  ; S = 0 if Arch is Summing
  ; NNNN = the number of accumulation periods (1/4 NYS) for Archive.
  log_flag = header[12]
  LTCSNNNN_bits = header[12]
  smp_bits = header[12]
  smp_flag = (ishft(header[12],-4) AND 1)
  smp_accum = (header[12] AND 15)
  ; Format here is 000SNNNN
  ; S = 1 if Arch is Sampling
  ; S = 0 if Arch is Summing
  ; NNNN = the number of accumulation periods (1/4 NYS) for Archive.
  arch_sum  = header[13] ; leftover from old code, leave to not break things [plw'18]
  mode1 = header[13]
  arch_bits = header[13]
  arch_smp_flag = ishft(header[13],-4)  AND 1  ; shift four bits to get 5th bit.
  arch_accum = (header[13] AND 15) ; remove the lower 4 bits.
  if 0 then begin
    tot_accum_prd = 2ul ^ (arch_accum + smp_accum) ; in 1/4 NYS accumulation periods.
    ; Hold up folks! : look at the awesome use of the xor function below to invert the sum/sample bit! [plw'18]
    if survey then begin
      num_accum = 2ul ^ (((arch_smp_flag xor 1) * arch_accum) + ((smp_flag xor 1) * smp_accum))
    endif else begin
      num_accum = 2ul ^ ((smp_flag xor 1) * smp_accum)
    endelse    
  endif else begin
    
    if survey then begin
      tot_accum_prd = 2ul ^ (arch_accum + smp_accum) ; in 1/4 NYS accumulation periods.
      num_accum = 2ul ^ (((arch_smp_flag ne 0) * arch_accum) + ((smp_flag ne 0) * smp_accum))
    endif else begin
      tot_accum_prd = 2ul ^  smp_accum ; in 1/4 NYS accumulation periods.
      num_accum = 2ul ^ ((smp_flag ne 0) * smp_accum)
    endelse    
  endelse
  
  mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
  if ion then begin
    tmode = mode2 and 'f'x
    emode = ishft(mode2,-4) and 'f'xb
    pmode = ishft(mode2,-8) and 'f'xb
    mmode = ishft(mode2,-12) and 'f'xb
  endif else begin
    tmode = header[13]
    emode = header[14]  
    pmode = header[13]
    mmode = 0b  
  endelse
  f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
  status_bits = header[18]
  peak_bin = header[19]


  compression = (log_flag and '80'x) ne 0
  if compression eq 0 then dprint,'Log Compression is NOT on!',dlevel=3
  
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
;  time_delta:  ccsds.time_delta, $
  seqn:        ccsds.seqn,  $
  seqn_delta:  ccsds.seqn_delta,  $
  seq_group:   ccsds.seq_group,  $
  pkt_size :   ccsds.pkt_size,  $
  source   :   ccsds.source,  $
  source_hash:  ccsds.source_hash,  $
  compr_ratio:  ccsds.compr_ratio,  $
  ndat:        ndat, $
  datasize:    ns, $
;  log_flag:    log_flag, $
  smp_bits:    smp_flag, $
  LTCSNNNN_bits : LTCSNNNN_bits, $
  arch_bits : arch_bits, $              ; byte 12
  mode1:       mode1,  $
  arch_sum:    arch_sum, $
  arch_smp_flag:  arch_smp_flag, $
  tot_accum_period:  tot_accum_prd, $
  num_accum:   num_accum, $
  mode2_ori:   mode2,  $
  mode2:       mode2,  $
;  tmode:       byte(tmode), $
;  emode:       byte(emode), $
;  pmode:       byte(pmode), $
;  mmode:       byte(mmode), $
  f0:          f0,   $
  status_bits: status_bits,$
  peak_bin:    peak_bin, $
  product_bits:   product_bits,  $
  cnts:        tcnts,  $
  ano_spec:    fltarr(16),  $
  nrg_spec:    fltarr(32),  $
  def_spec:    fltarr(8) ,  $
  mas_spec:    fltarr(16),  $
  ;  full_spec:   fltarr(256), $
  pdata:       ptr_new(cnts), $
  gap:         ccsds.gap  }

  
end


