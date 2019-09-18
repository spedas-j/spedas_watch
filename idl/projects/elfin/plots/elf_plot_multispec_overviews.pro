pro elf_plot_multispec_overviews, date, probe=probe, no_download=no_download

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if undefined(date) then begin
    dprint, level=1, 'Please supply a date (e.g. 2019-04-30).'
    return 
  endif
  
  timespan,date,88200.,/sec
  tr=timerange()

  if undefined(probe) then probe='a'
  
  ; load state and attitude data
  elf_load_state, probes=probe
  ; load epd data
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux' ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
  get_data, 'el'+probe+'_pef_nflux', data=epdef

  ; setup for 1.5 hour interval plots
  ; 1 24 hour plot and 24 1.5 hour plots
  hr_arr = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_ststr = string(hr_arr, format='(i2.2)')
  ; Strings for labels, filenames
  ; Use smaller array if they are not the same
  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60.
    idx=where(epdef.x GE this_s AND epdef.x LT this_e, ncnt)
    if ncnt GT 1 then begin
      append_array, min_st, idx[0]
      append_array, min_en, idx[n_elements(idx)-1]
      this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
      append_array, starttimes, this_s
      append_array, stoptimes, this_e
    endif
  endfor
  nplots = n_elements(min_st)   
 
  for pidx=0, nplots-1 do begin  
    EPDE_plot_wIGRF_multispec_overviews, trange=[starttimes[pidx],stoptimes[pidx]], $
      probe=probe, no_download=no_download, file_label=file_lbl[pidx], $
      plot_label=plot_lbl[pidx]
  endfor 
  
end