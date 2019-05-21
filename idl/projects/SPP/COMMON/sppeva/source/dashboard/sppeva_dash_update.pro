PRO sppeva_dash_update, activate
  compile_opt idl2
  common com_dash, com_dash

  widget_control, com_dash.drDash, GET_VALUE=mywindow
  ;======================================================
  
  ;--------------
  ; Current Time
  ;--------------
  cst = time_string(systime(/seconds,/utc));................. current time
  css = ' current time: '+strmid(cst, 5,2)+'/'+strmid(cst, 8,2)+' '+strmid(cst, 11,5) + ' UTC'
  com_dash.oTime ->SetProperty,STRING=css
  
  ;--------------
  ; FOMstr
  ;--------------
  strHH = '0'
  strMM = '0'
  strBL = '0'
  strGb = '0'
  var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  get_data,var,data=D,dl=dl,lim=lim
  if n_tags(dl) gt 0 then begin
    s=dl.FOMstr
    if s.Nsegs eq 0 then begin
      strHH = '0'
      strMM = '0'
      strBL = '0'
    endif else begin
      ; HH and MM
      dt = total(s.STOP - s.START)/60.d0; seconds --> minutes
      hh = floor(dt/60.d0)
      mm = floor(dt - hh*60.d0)
      strHH = strtrim(string(hh),2)
      strMM = strtrim(string(mm),2)
      ; BL
      BL = 0
      if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
        tn=tnames('spp_fld_f1_100bps_DCB_ARCWRPTR',ct)
        if ct eq 1 then begin
          get_data,'spp_fld_f1_100bps_DCB_ARCWRPTR',data=DD
          ;mmax = n_elements(DD.x)
          ;lst = lonarr(mmax)
          mmax = max(DD.y,/nan)
          lst = lonarr(mmax)
          for n=0,s.Nsegs-1 do begin
            
            result = min(DD.x-s.START[n],min_subscript,/abs)
            ptr_start = DD.y[min_subscript]
            if DD.x[min_subscript] gt s.START[n] then ptr_start -= 1
            ;if ptr_start lt 0 then ptr_start = 0
            
            result = min(DD.x-s.STOP[n],min_subscript,/abs)
            ptr_stop = DD.y[min_subscript]
            if DD.x[min_subscript] lt s.STOP[n] then ptr_stop += 1

            lst[ptr_start:ptr_stop] = 1L
          endfor
          BL = total(lst)
        endif
      endif
      strBL = strtrim(string(floor(BL)),2)
      strGb = string(BL/512.2,format='(F6.3)')
      print,'$$$$$$$$$$$$$$$$$'
      print, BL/512.,'Gbits'
    endelse
  endif
  
  ;-------------------
  ; Background Color
  ;-------------------
  if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
    com_dash.myview ->SetProperty,COLOR=com_dash.color.lightblue
    com_dash.oMode -> SetProperty,STRING=' FIELDS'
  endif else begin
    com_dash.myview ->SetProperty,COLOR=com_dash.color.lightred
    com_dash.oMode -> SetProperty,STRING=' SWEAP'
  endelse
  com_dash.oHH -> SetProperty,STRING=' '+strHH+' hrs'
  com_dash.oMM -> SetProperty,STRING=' '+strMM+' min'
  com_dash.oBL -> SetProperty,STRING=' '+strBL+' blocks'
  com_dash.oGb -> SetProperty,STRING=' '+strGb+' Gbit'
  
  ;======================================================
  mywindow->Draw, com_dash.myview
END
