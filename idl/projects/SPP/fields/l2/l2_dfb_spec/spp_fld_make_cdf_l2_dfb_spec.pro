pro spp_fld_make_cdf_l2_dfb_spec, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir
       
  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  ; Read data from the TPLOT variables

;stop

  get_data, 'spp_fld_dfb_dc_spec_1_spec_converted', data = dc_spec1
  
  unix_time = dc_spec1.x
  
  n_full = n_elements(unix_time)

  met_time = unix_time - time_double('2010-01-01/00:00:00')

  tt2000_time = long64((add_tt2000_offset(unix_time) - $
    time_double('2000-01-01/12:00:00'))*1.e9)
  
  bins_56_dc = spp_get_fft_bins_04_dc(56)
  
  *l2_cdf_buffer.Epoch.data         = tt2000_time
  *l2_cdf_buffer.spec56_e12dc.data  = transpose(dc_spec1.y)

  *l2_cdf_buffer.spec56_fcenter.data = bins_56_dc.freq_avg

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

end