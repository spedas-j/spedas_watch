pro elf_get_att, start_time=start_time, probes=probes

  if undefined(probes) then probes='a'

  timespan, start_time
  tr=timerange()
  day_count = 0

  for i = 0, n_elements(probes) do begin
    
    sc='el'+probes[i]
    ; remove any other att data
    del_data, sc+'_att_gei'
    del_data, sc+'_att_last_solution'
    
    while (day_count LT 50) do begin
      elf_load_state, probe=probe, trange=tr
      if tnames(sc+'_att_gei') eq sc+'_att_gei' then break
      tr=tr-86400.
      day_count = day_count + 1
    endwhile
  
    ; fix time stamp if not on same day
    ; create att last solution var
    if tnames(sc+'_att_gei') ne sc+'_att_gei' then begin
      print, 'Unable to retrieve attitude data within 50 days of start time.' 
    endif else begin
      midtr=time_double(start_time)+(86400./2.)
      get_data, sc+'_att_gei', data=d, dlimits=dl, limits=l
      last_solution = d.x[0]
      d.x[0] = midtr
      store_data, sc+'_att_gei', data=d, dlimits=dl, limits=l
      store_data, sc+'_att_last_solution', data={x:last_solution}    
    endelse
    
  endfor

end
