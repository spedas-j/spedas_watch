FUNCTION eva_sitluplink_log, tai_FOMstr_mod, check=check, title=title
  compile_opt idl2

  fname = 'eva_uplink_log.sav'
  found = file_test(fname)
  if found then begin
    restore, fname
  endif else begin
    eva_uplink_log = ''
  endelse
  
  this_str = tai_FOMstr_mod.METADATAEVALTIME
  
  tn = tag_names(tai_FOMstr_mod)
  idx = where(strlowcase(tn) eq 'uplinkflag', ct)
  
  if(ct eq 0)then begin
    return,'uplink-log: no flag'  ; If no UPLINK flag, then it is okay to submit
  endif else begin
    if (tai_FOMstr_mod.UPLINKFLAG eq 0) then return, 'uplink-log: flag=0'; If UPLINK flag=0, then it is okay to submit
  endelse

  ; Otherwise, proceed to check or save

  if keyword_set(check) then begin
    idx = where(eva_uplink_log eq this_str, ct)
    if ct gt 0 then begin
      if undefined(title) then title = 'FOM Submission'
      msg=['This FOM structure has already been sent to SDC for uplink. ']
      msg=[msg, '(Clicking the UPLINK button multiple times is prohibited.)']
      msg=[msg,'This submission process is aborted.']
      rst = dialog_message(msg,/information,/center,title=title)
      return, 'uplink-log: abort'
    endif else begin
      return, 'uplink-log: passed'
    endelse
  endif else begin
    eva_uplink_log = [eva_uplink_log, this_str]
    save, eva_uplink_log, file=fname
    return, 'uplink-log: saved'
  endelse
  
END