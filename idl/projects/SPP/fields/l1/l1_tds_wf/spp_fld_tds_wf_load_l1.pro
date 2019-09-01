pro spp_fld_tds_wf_load_l1, file, prefix = prefix, varformat = varformat

  ;if not keyword_set(prefix) then prefix = 'spp_fld_tds_wf_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

end