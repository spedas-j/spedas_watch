;+
; spp_swp_span_prod
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-10-01 14:52:34 -0700 (Mon, 01 Oct 2018) $
; $LastChangedRevision: 25880 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spe_prod_apdat__define.pro $
;-


function spp_swp_span_prod::fill,ccsds


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
  ns = pksize - 20
  log_flag  = header[12]
  mode1 = header[13]
  mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
  tmode = header[13]
  emode = header[14]
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

  product_type = 0




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
  mode1:        mode1,  $
  mode2:        mode2,  $
  tmode:       tmode, $
  emode:       emode, $
  product_type: product_type,  $
  f0:           f0,$
  status_bits: status_bits,$
  peak_bin:    peak_bin, $
  cnts:  tcnts,  $
  anode_spec:  fltarr(16),  $
  nrg_spec:    fltarr(32),  $
  def_spec:    fltarr(8) ,  $
  ;  full_spec:   fltarr(256), $
  pdata:        ptr_new(cnts), $
  gap:         ccsds.gap  }

  
end


