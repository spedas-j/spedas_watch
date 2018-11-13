FUNCTION sppeva_load_spp, param, perror
  compile_opt idl2

  ;-------------
  ; CATCH ERROR
  ;-------------
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    ;catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    if ~keyword_set(no_gui) then begin
      ok = dialog_message(msg,/center,/error)
    endif
    message, /reset; Clear !ERROR_STATE
    return, pcode
  endif
  
  
  ;------------
  ; FOMstr
  ;------------
  pcode=0
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_fomstr') and (cp eq 0))then begin
    fomstr = {Nsegs:0L}
    tr = time_double(!SPPEVA.COM.STRTR)
    store_data, param, data = {x:tr, y:[0.,0.]}, dl={fomstr:fomstr}
    ylim,param,0,25,0
    options,param,ystyle=1,constant=[5,10,15,20]
  endif

  ;------------
  ; Commissioning
  ;------------
;  pcode=1
;  ip=where(perror eq pcode,cp)
;  if(strmatch(param,'*_f1_100bps_*') and (cp eq 0))then begin
;    pfx = 'spp_fld_f1_100bps_'
;    sppeva_get_fld_f1_100bps, filename=filename
;    spp_fld_load_l1, filename
;    store_data,pfx+'B',data=pfx+['BX','BY','BZ']
;  endif
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_f1_100bps_*') and (cp eq 0))then begin
    sppeva_get_fld,'f1_100bps'
    
  endif
  return, -1
END