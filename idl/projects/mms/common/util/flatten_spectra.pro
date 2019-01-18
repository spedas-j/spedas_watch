;+
; PROCEDURE:
;         flatten_spectra
;
; PURPOSE:
;         Create quick plots of spectra at a certain time (i.e., energy vs. eflux, PA vs. eflux, etc)
;         
; KEYWORDS:
;       [XY]LOG:   [XY] axis in log format
;       [XY]RANGE: 2 element vector that sets [XY] axis range
;       NOLEGEND:  Disable legend display
;       COLORS:    n element vector that sets the colors of the line in order that they are in tplot_vars.options.varnames
;                  n is number of tplot variables in tplot_vars.options.varnames
;             
;       PNG:         save png from the displayed windows (cannot be used with /POSTRSCRIPT keyword)
;       POSTRSCRIPT: create postscript files instead of displaying the plot
;       PREFIX:      filename prefix
;       FILENAME:    custorm filename, including folder. 
;                    By default the folder is !mms.local_data_dir and filename includes tplot names and selected time (or center time)      
;       
;       TIME_IN:     if the keyword is specified the time is determined from the variable, not from the cursor pick.
;       TRANGE:      Two-element time range over which data will be averaged. 
;       SAMPLES:     Number of nearest samples to time to average. Override trange.      
;       WINDOW:      Length in seconds over which data will be averaged. Override trange.
;       CENTER_TIME: Flag denoting that time should be midpoint for window instead of beginning.
;                    If TRANGE is specify, the the time center point is computed.
;       RANGETITLE:  If keyword is set, display range of the averagind time instead of the center time
;                    Does not affect deafult name of the png or postscript file 
;       TO_KEV:      Converts the x-axis to keV from eV (checks units in ysubtitle)
;       TO_FLUX: Converts the y-axis to units of flux, i.e., '1/(cm^2 s sr keV)', as with TO_KEV, 
;                     this keyword uses the units string in the ztitle
;
; EXAMPLE:
;     To create line plots of FPI electron energy spectra for all MMS spacecraft:
;     
;       MMS> mms_load_fpi, datatype='des-moms', trange=['2015-12-15', '2015-12-16'], probes=[1, 2, 3, 4]
;       MMS> tplot, 'mms?_des_energyspectr_omni_fast'
;       MMS> flatten_spectra, /xlog, /ylog
;       
;       --> then click the tplot window at the time you want to create the line plots at
;
; NOTES:
;     work in progress; suggestions, comments, complaints, etc: egrimes@igpp.ucla.edu
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-01-17 12:26:24 -0800 (Thu, 17 Jan 2019) $
;$LastChangedRevision: 26478 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra.pro $
;-

pro fs_warning, str
  compile_opt idl2, hidden
  ; print warning message 
  dprint, dlevel=0, '########################### WARNING #############################'  
  dprint, dlevel=0,  str
  dprint, dlevel=0, '#################################################################'
end

function fs_get_unit_string, unit_array, disable_warning=disable_warning
  compile_opt idl2, hidden
  ; prepare string of units from the given array. If there is more that one unit in the array, print the warning 
  if ~undefined(unit_array) then begin
    if N_ELEMENTS(unit_array) gt 1 then begin
      if undefined(disable_warning) then fs_warning, 'Units of the tplot variables are different!'
      return, STRJOIN(unit_array, ', ')             
    endif else RETURN, unit_array[0]
  endif else return, ''
end

pro fs_get_unit_array, metadata, field, arr=arr
  compile_opt idl2, hidden
  ; extract unique units from metadata 
  str_element, metadata,field, SUCCESS=S, VALUE=V
  V = S ? V : '[]' ; Test if we sucsesfully return the value
  if undefined(arr) then begin
    append_array, arr, V      
  endif else begin
    if total(strcmp(arr, V)) lt 1 then append_array, arr, V       
  endelse
end



pro flatten_spectra, xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, nolegend=nolegend, colors=colors,$
   png=png, postscript=postscript, prefix=prefix, filename=filename, $   
   time=time_in, trange=trange_in, window_time=window_time, center_time=center_time, samples=samples, rangetitle=rangetitle, $
   charsize=charsize, replot=replot, to_kev=to_kev, legend_left=legend_left, bar=bar, to_flux=to_flux, _extra=_extra
   
  @tplot_com.pro
  
  ;
  ; Time selection
  ;
  
  if keyword_set(replot) then begin
    get_data, 'flatten_spectra_time', data=spec_time
    if ~is_struct(spec_time) then begin
      dprint, dlevel=0, 'Error, replot keyword specified, but no previous time found'
      return
    endif
    time_in = spec_time.X
  endif
  
  if undefined(time_in) and undefined(trange_in) then begin ; use cursor or the input variable
    ctime,t,npoints=1,prompt="Use cursor to select a time to plot the spectra", /silent 
      ;hours=hours,minutes=minutes,seconds=seconds,days=days  
    if undefined(t) || t eq 0 then return ; exit on the right click or if t isn't defined for some reason
  endif else begin    
    if undefined(trange_in) then t = time_double(time_in) ; if user set time_in, but not trange
    if ~undefined(trange_in) then begin ; if user set trange for the averaging
      trange = minmax(time_double(trange_in))
      t = trange[0] + (trange[1] - trange[0]) / 2.  
    endif
  endelse
  
  ; set the averaging time window
  if ~undefined(window_time) then begin
    if KEYWORD_SET(center_time) then begin
      trange = [t - window_time/2. , t + window_time/2.]
    endif else begin
      trange = [t , t + window_time]
    endelse    
  endif
  
  if undefined(charsize) then charsize = 2.0
    
  dprint, dlevel=1, 'time selected: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
  store_data, 'flatten_spectra_time', data={x: t, y: 1}
  vars_to_plot = tplot_vars.options.varnames
   
  ; 
  ; Get the supporting information
  ;
  fname = '' ; filename for if we save png of postscript  
  if UNDEFINED(prefix) THEN prefix = ''  
  
  ; loop to get supporting information
  for v_idx=0, n_elements(vars_to_plot)-1 do begin  
    get_data, vars_to_plot[v_idx], data=vardata, alimits=metadata
    m = spd_extract_tvar_metadata(vars_to_plot[v_idx])

    if ~is_struct(vardata) or ~is_struct(metadata) then begin
      dprint, dlevel=0, 'Could not plot: ' + vars_to_plot[v_idx]
      continue
    endif

    ; check that this variable is actually a spectra, to allow for line plots on the same figure
    str_element, metadata, 'spec', success=spec_exists
    if ~spec_exists || metadata.spec eq 0 then begin
      dprint, dlevel=1, 'Not including: ' + vars_to_plot[v_idx]
      continue
    endif
    
    ; determine units: get fields for metadata and add the the array if any 
    fs_get_unit_array, metadata, 'ysubtitle', arr=xunits
    fs_get_unit_array, metadata, 'ztitle', arr=yunits
    
    ; determine max and min  
    if N_ELEMENTS(xrange) ne 2 or N_ELEMENTS(yrange) ne 2 then begin 
      tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
      
      if dimen2(vardata.v) eq 1 then data_x = vardata.v else data_x = vardata.v[idx_to_plot, *]
      data_y = vardata.Y[idx_to_plot, *]
            
      if keyword_set(to_kev) && (tag_exist(metadata, 'ysubtitle') && metadata.ysubtitle ne '') || (tag_exist(metadata, 'yunits') && metadata.yunits ne '') then begin
        if tag_exist(metadata, 'ysubtitle') && (metadata.ysubtitle eq 'eV' || metadata.ysubtitle eq '[eV]' || metadata.ysubtitle eq '(eV)') then begin
          data_x = data_x/1000d
        endif else if tag_exist(metadata, 'yunits') && (metadata.yunits eq 'eV' || metadata.yunits eq '[eV]' || metadata.yunits eq '(eV)') then begin
          data_x = data_x/1000d
        endif
      endif
      if keyword_set(to_flux) && m.units ne '' then begin
        ztitle = string(m.units)
        ztitle = ztitle.replace('!U', '')
        ztitle = ztitle.replace('!N', '')
        ztitle = ztitle.replace('^', '')
        ztitle = ztitle.replace('-', ' ')
        if ztitle eq 'keV/(cm2 sr s keV)' || ztitle eq '[keV/(cm2 sr s keV)]' || ztitle eq 'keV/(cm2 s sr keV)' || ztitle eq '[keV/(cm2 s sr keV)]' then begin
          data_y = data_y/data_x
        endif else if ztitle eq 'eV/(cm2 sr s eV)' || ztitle eq '[eV/(cm2 sr s eV)]' || ztitle eq 'eV/(cm2 s sr eV)' || ztitle eq '[eV/(cm2 s sr eV)]' then begin
          data_y = data_y*1000d/data_x
        endif else if ztitle eq '1/(cm2 sr s eV)' || ztitle eq '[1/(cm2 sr s eV)]' || ztitle eq '1/(cm2 s sr eV)' || ztitle eq '[1/(cm2 s sr eV)]' then begin
          data_y = data_y*1000d
        endif
      endif
      append_array,yr,reform(data_y)
      append_array,xr,reform(data_x)     
    endif      
    
    ; filename if we need to save file
    fname += vars_to_plot[v_idx] + '_'      
  endfor
  
  ; select [xy] range
  if N_ELEMENTS(xrange) ne 2 then xrange = KEYWORD_SET(xlog) ? [min(xr(where(xr>0))), max(xr(where(xr>0)))] : [min(xr), max(xr)]
  if N_ELEMENTS(yrange) ne 2 then yrange = KEYWORD_SET(ylog) ? [min(yr(where(yr>0))), max(yr(where(yr>0)))] : [min(yr), max(yr)]

  ; user defined colors indexes
  if ~KEYWORD_SET(colors) or (N_ELEMENTS(colors) lt n_elements(vars_to_plot)) then begin
    colors = indgen(n_elements(vars_to_plot),start=0,increment=2)
  endif 
  
  ; units string
  xunit_str = fs_get_unit_string(xunits, disable_warning=to_kev)
  yunit_str = fs_get_unit_string(yunits, disable_warning=to_flux)
   
  ; position for the legend
  if keyword_set(legend_left) then leg_x = 0.04 else leg_x = 0.60
  leg_y = 0.04
  leg_dy = 0.04

  ; finalizing filename
  fname += time_string(t, tformat='YYYYMMDD_hhmmss')
  fname = prefix + fname  
  if ~UNDEFINED(filename) THEN fname = filename


  ;
  ; Plot or save to the file
  ;

  ; Device = postscript or window
  if KEYWORD_SET(postscript) then popen, fname, /landscape else window, 1
  
  ; loop plot
  for v_idx=0, n_elements(vars_to_plot)-1 do begin

      get_data, vars_to_plot[v_idx], data=vardata, alimits=vardl
      m = spd_extract_tvar_metadata(vars_to_plot[v_idx])

      if ~is_struct(vardata) or ~is_struct(vardl) then begin
        dprint, dlevel=0, 'Could not plot: ' + vars_to_plot[v_idx]
        continue
      endif
      
      ; check that this variable is actually a spectra, to allow for line plots on the same figure
      str_element, vardl, 'spec', success=spec_exists
      if ~spec_exists || vardl.spec eq 0 then begin
        dprint, dlevel=1, 'Not including: ' + vars_to_plot[v_idx]
        continue
      endif
      
      ; work with averaging      
      tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
      
      ; Process samles keyword
      if ~undefined(samples) then begin
        if KEYWORD_SET(center_time) then begin
          pm_idx = ceil(samples/2.)
          t_idx  = [idx_to_plot - pm_idx, idx_to_plot+pm_idx]
        endif else begin
          t_idx  = [idx_to_plot , idx_to_plot+samples]
        endelse
        t_idx[0] = t_idx[0] lt 0 ? 0 : t_idx[0]
        t_idx[1] = t_idx[1] gt N_ELEMENTS(vardata.X)-1 ? N_ELEMENTS(vardata.X)-1 : t_idx[1] 
        trange  = [vardata.X[t_idx[0]] , vardata.X[t_idx[1]]]
      endif     
            
      if ~undefined(trange) then begin
        ; fix boundaries
        trange[0] = trange[0] lt vardata.X[0]  ? vardata.X[0] : trange[0]
        trange[1] = trange[1] gt vardata.X[-1] ? vardata.X[-1] : trange[1]
        ; find indexes that correspond to trange
        tmp = min(vardata.X - trange[0], /ABSOLUTE, t_idx_min)
        tmp = min(vardata.X - trange[1], /ABSOLUTE, t_idx_max)
        t_idx  = [t_idx_min , t_idx_max] 
      endif          
      
      ; t_idx is defined if we do averagind       
     if ~undefined(t_idx) then begin
        data_to_plot = mean(vardata.Y[t_idx[0]:t_idx[1], *],dimension=1) ; creates vector
        data_to_plot = reform(data_to_plot,[1,n_elements(data_to_plot)]) ; fix dimentions to [1,n]
      endif else begin        
        data_to_plot = vardata.Y[idx_to_plot, *]        
      endelse
        
      if dimen2(vardata.v) eq 1 then x_data = vardata.v else x_data = vardata.v[idx_to_plot, *]
      y_data = data_to_plot
      
      if keyword_set(to_kev) && (tag_exist(vardl, 'ysubtitle') && vardl.ysubtitle ne '') || (tag_exist(vardl, 'yunits') && vardl.yunits ne '') then begin
        if tag_exist(vardl, 'ysubtitle') && (vardl.ysubtitle eq 'eV' || vardl.ysubtitle eq '[eV]' || vardl.ysubtitle eq '(eV)') then begin
          xunit_str = '[keV]'
          x_data /= 1000d
        endif else if tag_exist(vardl, 'yunits') && (vardl.yunits eq 'eV' || vardl.yunits eq '[eV]' || vardl.yunits eq '(eV)') then begin
          xunit_str = '[keV]'
          x_data /= 1000d
        endif
      endif
      
      if keyword_set(to_flux) && m.units ne '' then begin
        ztitle = string(m.units)
        ztitle = ztitle.replace('!U', '')
        ztitle = ztitle.replace('!N', '')
        ztitle = ztitle.replace('^', '')
        ztitle = ztitle.replace('-', ' ')
        if ztitle eq 'keV/(cm2 sr s keV)' || ztitle eq '[keV/(cm2 sr s keV)]' || ztitle eq 'keV/(cm2 s sr keV)' || ztitle eq '[keV/(cm2 s sr keV)]' then begin
          yunit_str = '1/(cm!U2!N sr s keV)'
          y_data = y_data/x_data
        endif else if ztitle eq 'eV/(cm2 sr s eV)' || ztitle eq '[eV/(cm2 sr s eV)]' || ztitle eq 'eV/(cm2 s sr eV)' || ztitle eq '[eV/(cm2 s sr eV)]' then begin
          yunit_str = '1/(cm!U2!N sr s keV)'
          y_data = y_data*1000d/x_data
        endif else if ztitle eq '1/(cm2 sr s eV)' || ztitle eq '[1/(cm2 sr s eV)]' || ztitle eq '1/(cm2 s sr eV)' || ztitle eq '[1/(cm2 s sr eV)]' then begin
          yunit_str = '1/(cm!U2!N sr s keV)'
          y_data = y_data*1000d
        endif
      endif

      if v_idx eq 0 then begin
      
        title_format = 'YYYY-MM-DD/hh:mm:ss.fff'
        title_str = (KEYWORD_SET(rangetitle) and ~undefined(trange)) ? $
          strjoin(time_string(trange, tformat=title_format),' - ') : $
          time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
 
        plot, x_data, y_data, $
          xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, $
          xtitle=xunit_str, ytitle=yunit_str, $
          charsize=charsize, title=title_str, color=colors[v_idx], _extra=_extra
          
          if ~keyword_set(nolegend) then begin
            if keyword_set(legend_left) then leg_x += !x.WINDOW[0]
            leg_y = !y.WINDOW[1] - leg_y
          endif            
      endif else begin
        oplot, x_data, y_data, color=colors[v_idx], _extra=_extra
      endelse      
      
      if ~keyword_set(nolegend) then begin
        leg_y -= leg_dy
        XYOUTS, leg_x, leg_y, vars_to_plot[v_idx], /normal, color=colors[v_idx], charsize=1.5
      endif
        
  endfor
  
  if keyword_set(bar) then timebar, t
  
  ; save to file
  if KEYWORD_SET(png) and ~KEYWORD_SET(postscript) then makepng, fname
  if KEYWORD_SET(postscript) then pclose
end