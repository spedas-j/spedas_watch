pro elf_epd_l1_postproc, tplotnames, trange=trange, type=type, suffix=suffix, $
    my_nspinsinsum=my_nspinsinsum, unit=unit, no_spec=no_spec, no_download=no_download

  ; Post processing - calibration and fix meta data
  ; first calibrate spinper to turn it to seconds
  fgmsamplespersec = 80.
  for i=0,n_elements(tplotnames)-1 do begin
    if strpos(tplotnames[i], 'spinper') NE -1 then begin
      get_data, tplotnames[i], data=d, dlimits=dl, limits=l
      if size(d, /type) EQ 8 then begin
        d.y=d.y/fgmsamplespersec
        store_data, tplotnames[i], data=d, dlimits=dl, limits=l
      endif
    endif
  endfor
  ;
  for i=0,n_elements(tplotnames)-1 do begin

    if strpos(tplotnames[i], 'energies') NE -1 then begin
      del_data, tplotnames[i]
      continue
    endif
    if strpos(tplotnames[i], 'sectnum') NE -1 then begin
      tplotnames[i]=tplotnames[i]+suffix
      continue
    endif
    if strpos(tplotnames[i], 'spinper') NE -1 then begin
      tplotnames[i]=tplotnames[i]+suffix
      continue
    endif
    if strpos(tplotnames[i], 'nspinsinsum') NE -1 then begin
      tplotnames[i]=tplotnames[i]+suffix
      continue
    endif
    if strpos(tplotnames[i], 'nsectors') NE -1 then begin
      tplotnames[i]=tplotnames[i]+suffix
      continue
    endif

    ; add type of end of tplotnames
    if ~keyword_set(no_suffix) then begin
      if suffix eq '' then begin
        tplot_rename, tplotnames[i], tplotnames[i]+'_'+type
        tplotnames[i]=tplotnames[i]+'_'+type
      endif else begin
        newname=strmid(tplotnames[i],0,7)+'_'+type+suffix
        tplot_rename, tplotnames[i], newname
        tplotnames[i]=newname
      endelse
    endif

    if ~keyword_set(my_nspinsinsum) then begin
      tn=tnames('*nspinsinsum*')
      get_data, tn[0], data=nspin
      if is_struct(nspin) then my_nspinsinsum=nspin.y else my_nspinsinsum=1
    endif
    if undefined(my_nspinsinsum) then my_nspinsinsum=1
    ; calibrate data
    elf_cal_epd, tplotname=tplotnames[i], trange=trange, type=type, no_download=no_download, $
      nspinsinsum=my_nspinsinsum
    get_data, tplotnames[i], data=d, dlimits=dl, limits=l
    if size(d, /type) EQ 8 then begin
      dl.ysubtitle=unit
      if undefined(d.v) then v=findgen(16)
      if n_elements(tag_names(d)) EQ 2 then begin
        v=findgen(16)
        store_data, tplotnames[i], data={x:d.x, y:d.y, v:v}, dlimits=dl, limits=l
      endif else begin
        store_data, tplotnames[i], data={x:d.x, y:d.y, v:d.v}, dlimits=dl, limits=l
      endelse

      options, tplotnames[i], ylog=1
      if keyword_set(no_spec) then options, tplotnames[i], spec=0 else options, tplotnames[i], spec=1
      options, tplotnames[i], labflag=1
    endif

  endfor

end
