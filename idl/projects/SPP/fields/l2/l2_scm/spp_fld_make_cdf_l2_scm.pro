pro spp_fld_make_cdf_l2_scm, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir
       
  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  ; Read data from the TPLOT variables

  get_data, 'spp_fld_dfb_wf_03_wav_data_v', data = scm_bx
  get_data, 'spp_fld_dfb_wf_04_wav_data_v', data = scm_by
  get_data, 'spp_fld_dfb_wf_05_wav_data_v', data = scm_bz
  
  unix_time = scm_bx.x
  
  n_full = n_elements(unix_time)

  met_time = unix_time - time_double('2010-01-01/00:00:00')

  tt2000_time = long64((add_tt2000_offset(unix_time) - $
    time_double('2000-01-01/12:00:00'))*1.e9)

  scm_data = transpose([[scm_bx.y], [scm_by.y], [scm_bz.y]])
  
  *l2_cdf_buffer.Epoch.data         = tt2000_time
  *l2_cdf_buffer.B_SCM.data         = scm_data

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

end