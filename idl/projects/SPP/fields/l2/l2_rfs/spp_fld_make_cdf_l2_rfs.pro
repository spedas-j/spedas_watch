function spp_fld_make_cdf_l2_rfs_valid_data, rfs_data_struct

  rfs_dat = rfs_data_struct.y

  fill_ind = where(abs(rfs_dat) EQ 0, fill_count)

  if fill_count GT 0 then rfs_dat[fill_ind] = -1.0d31

  return, rfs_dat

end

pro spp_fld_make_cdf_l2_rfs, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  ; Read data from the TPLOT variables

  get_data, 'spp_fld_rfs_lfr_auto_averages_ch0_converted', $
    data = lfr_auto_avg_ch0
  get_data, 'spp_fld_rfs_lfr_auto_averages_ch1_converted', $
    data = lfr_auto_avg_ch1

  lfr_auto_unix_time = lfr_auto_avg_ch0.x
  lfr_auto_met_time = lfr_auto_unix_time - time_double('2010-01-01/00:00:00')
  lfr_auto_tt2000_time = long64((add_tt2000_offset(lfr_auto_unix_time) - $
    time_double('2000-01-01/12:00:00'))*1.e9)

  lfr_auto_n = n_elements(lfr_auto_unix_time)

  lfr_auto_n_freq = n_elements(lfr_auto_avg_ch0.v)

  lfr_auto_frequencies = rebin(reform(lfr_auto_avg_ch0.v, 1, lfr_auto_n_freq),$
    lfr_auto_n, lfr_auto_n_freq)

  lfr_auto_avg_ch0_data = spp_fld_make_cdf_l2_rfs_valid_data(lfr_auto_avg_ch0)
  lfr_auto_avg_ch1_data = spp_fld_make_cdf_l2_rfs_valid_data(lfr_auto_avg_ch1)

  *l2_cdf_buffer.epoch_lfr_auto.data    = lfr_auto_tt2000_time
  *l2_cdf_buffer.frequencies_lfr.data   = transpose(lfr_auto_frequencies)
  *l2_cdf_buffer.lfr_auto_avg_ch0.data  = transpose(lfr_auto_avg_ch0_data)
  *l2_cdf_buffer.lfr_auto_avg_ch1.data  = transpose(lfr_auto_avg_ch1_data)

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

  ; The write_data_to_cdf procedure doesn't allow for easy modification
  ; of global variables, so we do it here instead.

end