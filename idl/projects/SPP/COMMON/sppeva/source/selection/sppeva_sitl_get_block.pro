FUNCTION sppeva_sitl_get_block, START, STOP
  compile_opt idl2
  
  if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
    tnptr = !SPPEVA.COM.FIELDPTR
  endif else begin
    tnptr = !SPPEVA.COM.SWEAPPTR
  endelse
  
  ; PTR
  tn=tnames(tnptr,ct)
  if ct eq 1 then begin
    get_data,tnptr,data=DD
    
    ;--------------------
    ; PTR START
    ;--------------------
    result = min(DD.x-START,min_subscript,/abs)
    ptr_start = DD.y[min_subscript]
    if DD.x[min_subscript] gt START then ptr_start -= 1
    
    ;--------------------
    ; PTR START
    ;--------------------
    result = min(DD.x-STOP,min_subscript,/abs)
    ptr_stop = DD.y[min_subscript]
    if DD.x[min_subscript] lt STOP then ptr_stop += 1
    
    ;--------------------------------
    ; JUMP
    ;--------------------------------
    drv = abs(deriv(DD.x,DD.y))
    idx = where(drv gt 100.,ct)
    if(ct gt 0) then begin
      tjump = DD.x[idx]
    endif else begin
      tjump = !VALUES.F_NAN
    endelse
    
    PTR = {start:ptr_start, stop: ptr_stop, length: ptr_stop-ptr_start+1L, tjump:tjump}
  endif else begin
    ;message,tnptr+' not found (sppeva_sitl_get_block)'
  endelse
  return, PTR
END