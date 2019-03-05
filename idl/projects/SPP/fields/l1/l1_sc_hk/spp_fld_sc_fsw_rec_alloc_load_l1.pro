pro spp_fld_sc_fsw_rec_alloc_load_l1, file, prefix = prefix

  clusters_per_gbit = 3890d

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_fsw_rec_alloc_'

  cdf2tplot, /get_support_data, file, prefix = prefix

  instruments = ['epihi','epilo','fields', 'sweap', 'wispr']
  inst_abb = ['   EH','     EL','F',' S','  W']
  inst_colors = [1,3,2,4,6]

  sc_fsw_rec_alloc_names = tnames(prefix + '*')

  if sc_fsw_rec_alloc_names[0] NE '' then begin

    for i = 0, n_elements(sc_fsw_rec_alloc_names) - 1 do begin

      name = sc_fsw_rec_alloc_names[i]

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      ;options, name, 'colors', [2]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      ;options, name, 'psym', 4
      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.75
      options, name, 'datagap', 3600d

      if strpos(name, 'alloc_alloc') NE -1 or $
        strpos(name, 'alloc_used') NE -1 and $
        strpos(name, 'Gbit') EQ -1 then begin

        get_data, name, dat = d

        store_data, name + '_Gbit', data = {x:d.x, y:d.y/clusters_per_gbit}

      end

    endfor

  endif

  for i = 0, n_elements(instruments) - 1 do begin

    inst = instruments[i]

    inst_names = tnames(prefix + '*' + inst + '*')

    for j = 0, n_elements(inst_names) -1 do begin

      name = inst_names[j]

      options, name, 'colors', [inst_colors[i]]
      options, name, 'labels', inst_abb[i]

    endfor

  endfor

  store_data, prefix + 'instrument_alloc', $
    data = tnames('*alloc_alloc*' + instruments + '*Gbit')

  options, prefix + 'instrument_alloc', 'ytitle', 'Inst DCP!CAllocations'
  options, prefix + 'instrument_alloc', 'ysubtitle', 'Gbits'

  store_data, prefix + 'instrument_used', $
    data = tnames('*alloc_used*' + instruments + '*Gbit')

  options, prefix + 'instrument_used', 'ytitle', 'Inst DCP!CUsed'
  options, prefix + 'instrument_used', 'ysubtitle', 'Gbits'


  ;options, prefix + 'percent_used_fields', 'ytitle', 'PCT!CUSED!CFIELDS'

end