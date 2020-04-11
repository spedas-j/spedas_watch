FUNCTION eva_sitluplink_validateFOM, unix_fomstr
  compile_opt idl2
  
  ;---------------------
  ; Validation by Rick
  ;---------------------

  transtart = time_string(unix_fomstr.timestamps[0])
  transtop = time_string(unix_fomstr.timestamps[n_elements(unix_fomstr.timestamps)-1])
  sROIs = mms_get_srois(trange = [transtart, transtop])

  mms_convert_fom_unix2tai, unix_fomstr, tai_fomstr
  mms_check_fom_uplink, tai_fomstr, srois, error_flags, error_indices, error_msg, error_times

  print, '------------'

  loc_error = where(error_flags ne 0, count_error)
  print, 'Errors: '+strtrim(string(count_error),2)
  errmsg = ''
  for i = 0, count_error-1 do begin
    print, error_msg[loc_error[i]]
    errmsg = [errmsg,error_msg[loc_error[i]]]
  endfor
  if error_flags[1] eq 1 then begin
    print, *error_times[1]
  endif
  print, '------------'
  if count_error gt 0 then result = dialog_message(errmsg,/center)

  ptr_free, error_indices
  ptr_free, error_times
  
  return, count_error
END
