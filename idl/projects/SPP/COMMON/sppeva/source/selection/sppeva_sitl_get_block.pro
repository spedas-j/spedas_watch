FUNCTION sppeva_sitl_get_block, START, STOP
  compile_opt idl2
  
  tp = 'spp_fld_f1_100bps_DCB_ARCWRPTR'
  ; BL
  BL = 0
  tn=tnames(tp,ct)
  if ct gt 0 then begin
    get_data,tp,data=DD
    result = min(DD.x-START,min_subscript,/abs)
    ptr_start = DD.y[min_subscript]
    result = min(DD.x-STOP,min_subscript,/abs)
    ptr_stop = DD.y[min_subscript]
    BL += (ptr_stop - ptr_start)
  endif else begin
    message,tp+' not found (sppeva_sitl_get_block)'
  endelse
  return, BL
END