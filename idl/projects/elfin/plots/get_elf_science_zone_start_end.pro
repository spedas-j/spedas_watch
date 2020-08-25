function get_elf_science_zone_start_end, trange=trange, probe=probe, instrument=instrument

   if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
   endif
   if ~undefined(trange) && n_elements(trange) eq 2 $
     then tr = timerange(trange) else tr = timerange()
   if not keyword_set(probe) then probe = 'a'
   if not keyword_set(instrument) then instrument='epd'

   elf_load_epd, probe=probe, trange=trange, datatype='pef', type='nflux'
   get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
 
   ; find plots by science zone
   if (size(pef_nflux, /type)) EQ 8 then begin
      tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
      idx = where(tdiff GT 90., ncnt)   ; note: 90 seconds is an arbitary time
      append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
      if ncnt EQ 0 then begin
        sz_starttimes=[pef_nflux.x[0]]
        sz_min_st=[0]
        sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
        sz_min_en=[n_elements(pef_nflux.x)-1]
        ts=time_struct(sz_starttimes[0])
        te=time_struct(sz_endtimes[0])
      endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = pef_nflux.x[0]
          sidx = 0
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          this_e = pef_nflux.x[idx[sz]]
        endelse
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor
    endelse
  endif
  
  if undefined(sz_starttimes) then sci_zones=-1 else $
    sci_zones={starts:sz_starttimes, ends:sz_endtimes}

  return, sci_zones 
   
end