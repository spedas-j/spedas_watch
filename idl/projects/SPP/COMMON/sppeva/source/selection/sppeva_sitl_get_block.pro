FUNCTION sppeva_sitl_get_block, START, STOP
  compile_opt idl2
  
  mode = strlowcase(!SPPEVA.COM.MODE)
  if strmatch(mode,'swp') then begin
    return, 0
  endif
  
  tp = 'spp_fld_f1_100bps_DCB_ARCWRPTR'
  
  ; PTR
  tn=tnames(tp,ct)
  if ct eq 1 then begin
    get_data,tp,data=DD
    result = min(DD.x-START,min_subscript,/abs)
    ptr_start = DD.y[min_subscript]
    if DD.x[min_subscript] gt START then ptr_start -= 1
    
    result = min(DD.x-STOP,min_subscript,/abs)
    ptr_stop = DD.y[min_subscript]
    if DD.x[min_subscript] lt STOP then ptr_stop += 1
    
    PTR = {start:ptr_start, stop: ptr_stop, length: ptr_stop-ptr_start+1L}
  endif else begin
    ;message,tp+' not found (sppeva_sitl_get_block)'
  endelse
  return, PTR
END