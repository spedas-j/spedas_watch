pro spp_fld_make_cdf_l2_rfs_lfr, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  ; Read data from the TPLOT variables

  get_data, 'spp_fld_rfs_lfr_auto_averages_ch0_converted', $
    data = auto_avg_ch0
  get_data, 'spp_fld_rfs_lfr_auto_averages_ch1_converted', $
    data = auto_avg_ch1

  unix_time = auto_avg_ch0.x

  ; Generate 1 minute time cadence during time range

  n_full = n_elements(unix_time)

  met_time = unix_time - time_double('2010-01-01/00:00:00')
  tt2000_time = long64((add_tt2000_offset(unix_time) - $
    time_double('2000-01-01/12:00:00'))*1.e9)

  n_freq = n_elements(auto_avg_ch0.v)

  frequencies = rebin(reform(auto_avg_ch0.v,1,n_freq),n_full,n_freq)

  auto_ch0_data = auto_avg_ch0.y
  auto_ch0_data_fill_ind = where(auto_ch0_data LE 0, fill_count0)
  if fill_count0 GT 0 then auto_ch0_data[auto_ch0_data_fill_ind] = -1.0d31

  auto_ch1_data = auto_avg_ch1.y
  auto_ch1_data_fill_ind = where(auto_ch1_data LE 0, fill_count1)
  if fill_count1 GT 0 then auto_ch1_data[auto_ch1_data_fill_ind] = -1.0d31

  *l2_cdf_buffer.Epoch.data         = tt2000_time
  *l2_cdf_buffer.frequencies.data   = transpose(frequencies)
  *l2_cdf_buffer.auto_ch0.data      = transpose(auto_ch0_data)
  *l2_cdf_buffer.auto_ch1.data      = transpose(auto_ch1_data)

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

  ; The write_data_to_cdf procedure doesn't allow for easy modification
  ; of global variables, so we do it here instead.

end