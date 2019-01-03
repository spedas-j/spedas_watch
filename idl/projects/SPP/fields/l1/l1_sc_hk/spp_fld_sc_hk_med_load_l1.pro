pro spp_fld_sc_hk_med_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_med_'

  cdf2tplot, file, prefix = prefix

  sc_hk_med_names = tnames(prefix + '*')

  if sc_hk_med_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_med_names) - 1 do begin

      name = sc_hk_med_names[i]
      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle
      ;options, name, 'psym', 4
      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.75
      options, name, 'datagap', 600d

    endfor

  endif

  store_data, prefix + 'F_CURR', data = tnames(prefix + 'F?_CURR')

  options, prefix + 'F1_CURR', 'labels', '1'
  options, prefix + 'F2_CURR', 'labels', '  2'

  options, prefix + 'F1_CURR', 'colors', 2 ; blue
  options, prefix + 'F2_CURR', 'colors', 6 ; red

  options, prefix + 'F_CURR', 'yrange', [0,0.5]
  options, prefix + 'F_CURR', 'ytitle', 'F_CURR'


  store_data, prefix + 'F_PRE_SRV_HTR_CURR', $
    data = tnames(prefix + 'F?_PRE_SRV_HTR_CURR')

  options, prefix + 'F1_PRE_SRV_HTR_CURR', 'labels', '1'
  options, prefix + 'F2_PRE_SRV_HTR_CURR', 'labels', '  2'

  options, prefix + 'F1_PRE_SRV_HTR_CURR', 'colors', 2 ; blue
  options, prefix + 'F2_PRE_SRV_HTR_CURR', 'colors', 6 ; red

  ;options, prefix + 'F_PRE_SRV_HTR_CURR', 'yrange', [0,0.5]
  options, prefix + 'F_PRE_SRV_HTR_CURR', 'ytitle', 'PRE_SRV!CHTR_CURR'


  store_data, prefix + 'F_MAG_SRV_HTR_CURR', $
    data = tnames(prefix + 'F?_MAG_SRV_HTR_CURR')

  options, prefix + 'F1_MAG_SRV_HTR_CURR', 'labels', '1'
  options, prefix + 'F2_MAG_SRV_HTR_CURR', 'labels', '  2'

  options, prefix + 'F1_MAG_SRV_HTR_CURR', 'colors', 2 ; blue
  options, prefix + 'F2_MAG_SRV_HTR_CURR', 'colors', 6 ; red

  options, prefix + 'F_MAG_SRV_HTR_CURR', 'ytitle', 'MAG_SRV!CHTR_CURR'


end