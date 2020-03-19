; 'trange' and 'sc_id' are optional
;
PRO eva_sitl_sroi_bar,trange=trange,sc_id=sc_id,colors=colors
  compile_opt idl2

  ;-----------------
  ; LOAD DATA
  ;-----------------
  if undefined(trange) then begin
    trange = timerange(/current)
  endif else begin
    trange = time_double(trange)
  endelse
  str_trange = time_string(trange)
  sROIs = mms_get_srois(trange = str_trange, sc_id=sc_id)
  
  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y = !VALUES.F_NAN
  imax = 1

  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nan = !VALUES.F_NAN
  nan4 = [!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN,!VALUES.F_NAN]
  nROIs = n_elements(sROIs.starts)
  for n=0,nROIs-1 do begin; for each ROI
    ss = time_double(sROIs.starts[n])
    se = time_double(sROIs.stops[n])
    imax += 4
    bar_x = [bar_x, ss, ss, se, se]
    bar_y = [bar_y, nan, 0.,0., nan]
  endfor
    
  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  if undefined(colors) then colors = [1]
  if undefined(include_labels) then begin
    panel_size= 0.01 
    labels = ''
  endif else begin
    panel_size=0.09
    labels=['Status']
  endelse

  store_data,'mms_sroi',data={x:bar_x, y:bar_y, v:[0]}
  options,'mms_sroi',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=colors, labels=labels, charsize=2.
END