PRO sppeva_load_spp_wrap, str, ylog=ylog
  compile_opt idl2
  if undefined(ylog) then ylog=0
  tpv=tnames(str,cmax)
  if cmax gt 0 then begin
    for c=0,cmax-1 do begin
      tpv_split = STRSPLIT(tpv[c],'_', /EXTRACT)
      kmax = n_elements(tpv_split)
      tpv_temp = ''
      for k=1,kmax-1 do begin
        pattern = (k mod 2) ? '!C': '_'
        tpv_temp += (pattern + tpv_split[k])
      endfor
      options, tpv[c], ylog=ylog, ytitle=tpv_temp
    endfor
  endif
END

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
    options,param,ystyle=1,constant=[5,10,15,20]; Don't just add yrange; Look at the 'fom_vax_value' parameter of eva_sitl_FOMedit
    sppeva_load_spp_wrap, '*_fomstr', ylog=0
  endif

  ;------------
  ; FIELDS
  ;------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_f1_100bps_*') and (cp eq 0))then begin
    sppeva_get_fld,'f1_100bps'
  endif
  
  ;----------------------
  ; FIELDS RFS Level 1
  ;----------------------
  pcode=1
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_rfs_hfr_auto_*') and (cp eq 0))then begin
    sppeva_get_fld,'rfs_hfr_auto'
  endif  
  if(strmatch(param,'*_rfs_lfr_auto_*') and (cp eq 0))then begin
    sppeva_get_fld,'rfs_lfr_auto'
  endif

  ;---------------------
  ; SWEAP SPC Level 2
  ;---------------------
  pcode=2
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_spc_l2i_*') and (cp eq 0))then begin
    spp_swp_spc_load, type='l2i'
    sppeva_load_spp_wrap, '*_spc_l2i_*'
  endif
  
  ;---------------------
  ; SWEAP SPC Level 3
  ;---------------------
  pcode=2
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'*_spc_l3i_*') and (cp eq 0))then begin
    spp_swp_spc_load, type='l3i'
    sppeva_load_spp_wrap, '*_spc_l3i_*'
    options,'psp_swp_spc_l3i_np_*',ylog=1
    options,'psp_swp_spc_l3i_vp_*',colors=[2,4,6];,labflag=-1,labels=['V!Bx','V!By','V!Bz']
  endif
  
  ;---------------------
  ; SWEAP SPAN electrons
  ;---------------------
  pcode=3
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'psp_swp_sp?_sf*') and (cp eq 0))then begin
    spp_swp_spe_load
    sppeva_load_spp_wrap, '*_psp_swp_sp?_sf*'
  endif
  
  return, -1
END