PRO sitl_report_latest_json, info, dir, ABS=ABS
  compile_opt idl2

  if !VERSION.RELEASE lt 8.2 then begin
    print,'JSON SERIALIZE not supported before IDL 8.2'
    return
  endif

  strct = {roi:info.str_win, sitl:info.str_sitl, buff:info.str_buff, $
    fname:info.fname, pname:info.pname, yyyy:info.yyyy, notes:info.str_notes,$
    orbit:info.str_orbit, select:info.select}

  ; Read existing json
  fjson  = spd_addslash(dir)+'sitl_report.json'
  openr,nf,fjson,/get_lun ; open as a file with the pointer at the end
  line = '' & readf, nf, line; first line
  jarr = line
  while ~ eof(nf) do begin
    readf, nf, line
    jarr = [jarr,line]
  endwhile
  free_lun, nf
  jmax = n_elements(jarr)


;  if(keyword_set(ABS))then begin
;    ; check if the same WINDOW exists in the list
;    idx = where(strpos(jarr,info.str_win) ge 0, ct, complement=c_idx, ncomplement=nc)
;    ; json_serialize (replace if the same WINDOW existed)
;    if (ct gt 0) then begin; if the same WINDOW existed...
;  
;      if(info.str_sitl eq 'ABS')then begin
;        jothers = jarr[c_idx]; remove entries with the same WINDOW
;        jarr = ['[', json_serialize(strct)+',',jothers[1:nc-1]]; remove j=0 because it is '['
;      endif else begin
;        jarr[idx[0]]=json_serialize(strct)
;      endelse
;  
;    endif else begin
;      jarr = ['[', json_serialize(strct)+',',jarr[1:jmax-1]]
;    endelse
;  endif else begin

  ; check if the same WINDOW exists in the list
  idx = where(strpos(jarr,info.str_win) ge 0, ct, complement=c_idx, ncomplement=nc)
  ; json_serialize (replace if the same WINDOW existed)
  if (ct gt 0) then begin; if the same WINDOW existed...
    if(~keyword_set(ABS))then begin
      jothers = jarr[c_idx]; remove entries with the same WINDOW
      jarr = ['[', json_serialize(strct)+',',jothers[1:nc-1]]; remove j=0 because it is '['
    endif
  endif else begin
    jarr = ['[', json_serialize(strct)+',',jarr[1:jmax-1]]
  endelse

  
  ; output
  print,'$$$$ output start $$$$$$$$$$$$$$$$$$$$$$'
    openw,mf,fjson,/get_lun ; open as a new file
  print,'nf,mf=',nf,mf
  print,'fjson=',fjson
  pmax = n_elements(jarr)
  for p=0,pmax-1 do begin
    printf, mf, jarr[p]
  endfor
  free_lun, mf
  print,'$$$$ output end $$$$$$$$$$$$$$$$$$$$$$'
END