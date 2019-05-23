PRO sppeva_sitl_tplot2csv, var, filename=filename, msg=msg, error=error, auto=auto
  compile_opt idl2

  if undefined(var) then var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  if undefined(filename) then filename = var+'.csv'
  if undefined(msg) then msg = ''
  if undefined(error) then error = 0; No error by default
  
  ;------------------------------------------
  ; Check the existence of the tplot variable
  ;------------------------------------------
  tn=tnames()
  idx = where(strmatch(tn,var) eq 1,ct)
  if ct eq 0 then begin
    error = 1L
    msg = ' EVA: '+ var + ' not found.'
    print, msg
    return
  endif
  
  ;------------------------------------------
  ; Get Data
  ;------------------------------------------
  get_data,var,data=D,dl=dl,lim=lim
  s=dl.FOMstr
  if s.Nsegs eq 0 then begin
    ; This is not an error for "sppeva_sitl_save,/auto". Hence "error" remains 0.
    msg = ' EVA: No segment found; CSV file not created.'
    if not keyword_set(auto) then print, msg
    return
  endif
  
  strBLstart = strarr(s.Nsegs)
  strBLlen   = strarr(s.Nsegs)
  strFOM     = strarr(s.Nsegs)
  for n=0,s.Nsegs-1 do begin
    PTR = sppeva_sitl_get_block(s.START[n], s.STOP[n],/quiet)
    if n_tags(PTR) eq 0 then begin
      strBLstart[n] = '0'
      strBLlen[n] = '0'
    endif else begin
      strBLstart[n] = strtrim(string(PTR.START),2)
      strBLlen[n]   = strtrim(string(PTR.LENGTH),2)
    endelse
    strFOM[n]     = string(s.FOM[n], format='(F4.1)')
  endfor
  
  
  ;------------------------------------------
  ; HEADER
  ;------------------------------------------
  date = time_string(systime(/seconds,/utc))
  header = [' Start UT            ',' End UT              ','FOM   ', 'Tohban','Start Block',$
    'Length in Blocks','Comments']
  instr = strmatch(var,'*_fld_*') ? 'FIELDS' : 'SWEAP'
  instr2= strmatch(var,'*_fld_*') ? 'FIELDS' : 'SWEM'
  l1 = strmid(date,0,10)+' '+instr +' Selected Events from Archive Data'
  l2 = 'This file contains a prioritized list of data to select from the '+instr2+' to downlink.'
  l3 = 'Chosen by '+!SPPEVA.USER.FULLNAME
  l4 = 'EMAIL: '+!SPPEVA.USER.EMAIL
  l5 = 'Team:  '+!SPPEVA.USER.TEAM
  
  ;------------------------------------------
  ; WRITE
  ;------------------------------------------
  write_csv, filename, time_string(s.START), time_string(s.STOP), strFOM, s.SOURCEID, $
    strBLstart, strBLlen, s.DISCUSSION, header=header, table_header = [l1,l2,l3,l4,l5,'']
END
