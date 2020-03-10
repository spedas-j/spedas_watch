pro spp_fld_rfs_burst_load_l1, file, prefix = prefix, varformat = varformat

  if n_elements(file) LT 1 or file[0] EQ '' then return

  lfr_flag = strpos(prefix, 'lfr') NE -1
  if lfr_flag then receiver_str = 'LFR' else receiver_str = 'HFR'

  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, 'spp_fld_rfs_burst_spec?_??', 'spec', 1
  options, 'spp_fld_rfs_burst_spec?_??', 'no_interp', 1

  get_data, 'spp_fld_rfs_burst_spec0_re', data = spec0_re
  get_data, 'spp_fld_rfs_burst_spec0_im', data = spec0_im
  get_data, 'spp_fld_rfs_burst_spec1_re', data = spec1_re
  get_data, 'spp_fld_rfs_burst_spec1_im', data = spec1_im

  t = spec0_re.x

  store_data, 'spp_fld_rfs_burst_spec0_auto', $
    data = {x:t, y:sqrt(spec0_re.y^2. + spec0_im.y^2.)}

  store_data, 'spp_fld_rfs_burst_spec1_auto', $
    data = {x:t, y:sqrt(spec1_re.y^2. + spec1_im.y^2.)}

  xspec = complex(spec0_re.y, spec0_im.y) * complex(spec1_re.y, -spec1_im.y)

  store_data, 'spp_fld_rfs_burst_xspec_re', $
    data = {x:t, y:real_part(xspec)}

  store_data, 'spp_fld_rfs_burst_xspec_im', $
    data = {x:t, y:imaginary(xspec)}

  store_data, 'spp_fld_rfs_burst_xspec_phase', $
    data = {x:t, y:atan(imaginary(xspec),real_part(xspec)) * 180d/!pi}

  options, 'spp_fld_rfs_burst_xspec*', 'spec', 1
  options, 'spp_fld_rfs_burst_xspec*', 'no_interp', 1

  options, 'spp_fld_rfs_burst_xspec_phase', 'zrange', [-180.,180.]
  options, 'spp_fld_rfs_burst_xspec_phase', 'zstyle', 1
  options, 'spp_fld_rfs_burst_xspec_phase', 'panel_size', 2

  options, 'spp_fld_rfs_burst_spec?_auto', 'spec', 1

  options, 'spp_fld_rfs_burst_spec?_auto', 'no_interp', 1
  options, 'spp_fld_rfs_burst_spec?_auto', 'zlog', 1

  options, 'spp_fld_rfs_burst_spec?_auto', 'panel_size', 2

  options, 'spp_fld_rfs_burst_spec0_auto', 'ytitle', 'RFS Burst!CCh0 Auto'
  options, 'spp_fld_rfs_burst_spec1_auto', 'ytitle', 'RFS Burst!CCh1 Auto'

  options, 'spp_fld_rfs_burst_xspec_phase', 'ytitle', 'RFS Burst!CCross Phase'


  if file_basename(getenv('IDL_CT_FILE')) EQ 'spp_fld_colors.tbl' then set_colors = 1 else set_colors = 0

  if set_colors then options, 'spp_fld_rfs_burst_xspec_phase', 'color_table', 78

  ;tplot, 'spp_fld_rfs_burst_spec*'
  ;stop

end