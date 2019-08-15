pro spp_fld_dcb_events_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_events_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  dcb_event_names = tnames(prefix + '*')

  if dcb_event_names[0] NE '' then begin

    for i = 0, n_elements(dcb_event_names)-1 do begin

      name = dcb_event_names[i]

      options, name, 'ynozero', 1
      ;options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', 'DCB Event!C' + name.Remove(0, prefix.Strlen()-1)

      options, name, 'ysubtitle', ''

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endfor

  endif

  burst_types = ['DFB_BURST','TDS_BURST']

  t0_ur8 = time_double('1982-01-01')

  foreach b, burst_types do begin

    pre = prefix + b

    get_data, pre + '_TIME_MET', dat = t_met
    get_data, pre + '_TIME_UR8', dat = t_ur8

    if size(/type, t_ur8) EQ 8 and size(/type, t_met) EQ 8 then begin

      finite_ind = where(finite(t_ur8.y), finite_count)

      if finite_count GT 0 then begin

        t_unix = t0_ur8 + t_ur8.y[finite_ind] * 24d * 60d * 60d

        store_data, pre + '_TIME_COLLECT_TO_WRITE', $
          dat = {x:t_unix, y:(t_ur8.x[finite_ind] - t_unix)/60d}

        options, pre + '_TIME_COLLECT_TO_WRITE', 'ytitle', b + '!CCOLLECT!CTO WRITE'
        options, pre + '_TIME_COLLECT_TO_WRITE', 'ysubtitle', '[Min]'
        options, pre + '_TIME_COLLECT_TO_WRITE', 'psym', 4
        options, pre + '_TIME_COLLECT_TO_WRITE', 'symsize', 0.5
        options, pre + '_TIME_COLLECT_TO_WRITE', 'colors', 6
        options, pre + '_TIME_COLLECT_TO_WRITE', 'ylog', 1

      end

    end

  end

  ;  tu2=tu + u*24*60*60.


end