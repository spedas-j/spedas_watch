pro spp_fld_rfs_burst_load_l1, file, prefix = prefix, varformat = varformat

  if n_elements(file) LT 1 or file[0] EQ '' then return

  lfr_flag = strpos(prefix, 'lfr') NE -1
  if lfr_flag then receiver_str = 'LFR' else receiver_str = 'HFR'

  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, 'spp_fld_rfs_burst_spec?_??', 'spec', 1
  options, 'spp_fld_rfs_burst_spec?_??', 'no_interp', 1
  
  tplot, 'spp_fld_rfs_burst_spec?_??'

end