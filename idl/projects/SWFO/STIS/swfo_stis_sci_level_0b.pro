; $LastChangedBy: dav $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $


function swfo_stis_sci_level_0b,sci_dat,nse_dat,hkp_dat  ;,format=format,reset=reset,cal=cal

  output = !null
  nan = !values.f_nan
  dnan = !values.d_nan

  nd = n_elements(sci_dat)

  if n_params() eq 0 then return,l0b

  if ~isa(sci_dat) || ~isa(nse_dat) || ~isa(hkp_dat) then begin
    dprint,'bad data in L0b'
    return,!null  ; l0b
  endif

  if nd gt 1 then begin
    output = replicate(l0b,nd)
    for i=0l,nd-1 do begin
      output[i] = swfo_stis_sci_level_0b(sci_dat[i],nse_dat[i],hkp_dat[i])
    endfor
    return, output
  endif


  ; l0b = { swfo_stis_l0b, $
  ;   time:0.d  ,$
  ;   time_met: 0d, $
  ;   time_gr:  0d, $
  ;   time_unix:  0d, $
  ;   sci_delaytime: nan, $
  ;   hkp_delaytime: nan, $
  ;   nse_delaytime: nan, $
  ;   sci_seqn:      0u,  $
  ;   sci_seqn_delta:  0u,  $
  ;   nse_seqn:      0u,  $
  ;   nse_seqn_delta:  0u,  $
  ;   hkp_seqn:      0u,  $
  ;   hkp_seqn_delta:  0u,  $
  ;   packet_size:  0u,  $
  ;   sci_duration:  0u, $
  ;   sci_nbins:      0u,   $
  ;   sci_counts: replicate(nan,672) ,$
  ;   nse_raw:    replicate(0u,60)  , $
  ;   nse_histogram:   replicate(0u,60)  , $
  ;   nse_sigma: replicate(0.d, 6), $
  ;   nse_baseline: replicate(0.d, 6), $
  ;   nse_total6: replicate(0.d, 6), $
  ;   lut_map: 0b,  $
  ;   sci_nonlut_mode:  0b,  $
  ;   sci_decimate:    0b, $
  ;   sci_translate:   0b,  $
  ;   sci_resolution:   0b,  $
  ;   fpga_rev:   0b,  $
  ;   quality_bits:    0ull,  $
  ;   gap:  0b  }

    ; stop
    l0b = merge_struct(hkp_dat, nse_dat, ['hkp', 'nse'])
    l0b = merge_struct(l0b, sci_dat, ['', 'sci'])

    ; since stacked according to science packet,
    ; set the science packet time to the main time:
    str_element, l0b, 'time', l0b.sci_time, /add

    ; quality flag place holder
    str_element, l0b, 'quality_flag', 0b, /add
    ; l0b.quality_flag = 0b

  output = l0b
  ; output.time       = sci_dat.time
  ; output.time_met   = sci_dat.met
  ; output.time_gr  = sci_dat.grtime
  ; output.time_unix= sci_dat.time
  ; output.sci_delaytime = sci_dat.grtime - sci_dat.time
  ; output.hkp_delaytime = sci_dat.time - hkp_dat.time
  ; output.nse_delaytime = sci_dat.time - nse_dat.time
  ; output.sci_seqn   = sci_dat.seqn
  ; output.sci_seqn_delta  = sci_dat.seqn_delta
  ; output.nse_seqn     = nse_dat.seqn
  ; output.nse_sigma = nse_dat.sigma
  ; output.nse_baseline = nse_dat.baseline
  ; output.nse_total6 = nse_dat.total6
  ; output.nse_seqn_delta = nse_dat.seqn_delta
  ; output.hkp_seqn  = hkp_dat.seqn
  ; output.hkp_seqn_delta = hkp_dat.seqn_delta
  ; output.packet_size = sci_dat.packet_size
  ; output.fpga_rev = sci_dat.fpga_rev
  ; output.sci_duration = sci_dat.duration
  ; output.sci_nbins  = sci_dat.nbins
  ; output.sci_counts= sci_dat.counts
  ; ;  output.nse_raw= nse_dat.raw
  ; output.nse_histogram =  nse_dat.histogram
  ; output.lut_map  = sci_dat.lut_map
  ; output.sci_nonlut_mode = sci_dat.sci_nonlut_mode
  ; output.sci_decimate = sci_dat.sci_decimate
  ; output.sci_translate = sci_dat.sci_translate
  ; output.sci_resolution = sci_dat.sci_resolution
  ; output.quality_bits  = 0


  return,output

end

