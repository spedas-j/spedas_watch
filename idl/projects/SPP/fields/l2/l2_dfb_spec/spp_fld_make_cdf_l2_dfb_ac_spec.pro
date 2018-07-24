pro spp_fld_make_cdf_l2_dfb_ac_spec, $
  l2_master_cdf, l2_cdf

  spp_fld_make_cdf_l2_dfb_spec, l2_master_cdf, l2_cdf, 'ac'

end

;if n_elements(l2_master_cdf) EQ 0 or n_elements(l2_cdf) EQ 0 then begin
;
;  dprint, dlevel = 1, 'L2 master CDF or L2 CDF not specified'
;  return
;
;endif
;
;l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)
;
;; Read data from the TPLOT variables
;
;dfb_spec_names = tnames('spp_fld_dfb_?c_spec_?_spec_converted')
;
;get_data, 'spp_fld_dfb_dc_spec_1_spec_converted', data = dc_spec1
;get_data, 'spp_fld_dfb_dc_spec_2_spec_converted', data = dc_spec2
;get_data, 'spp_fld_dfb_dc_spec_3_spec_converted', data = dc_spec3
;get_data, 'spp_fld_dfb_dc_spec_4_spec_converted', data = dc_spec4
;
;unix_time = dc_spec1.x
;
;n_full = n_elements(unix_time)
;
;met_time = unix_time - time_double('2010-01-01/00:00:00')
;
;tt2000_time = long64((add_tt2000_offset(unix_time) - $
;  time_double('2000-01-01/12:00:00'))*1.e9)
;
;spp_fld_dfb_frequencies
;
;bins_56_dc = spp_get_fft_bins_04_dc(56)
;
;*l2_cdf_buffer.Epoch.data         = tt2000_time
;
;; TODO: Hard coded association of spec to data type should actually use
;; the metadata in the L1 file
;
;*l2_cdf_buffer.spec56_e12.data  = transpose(dc_spec1.y)
;*l2_cdf_buffer.spec56_scmx_hg.data  = transpose(dc_spec2.y)
;*l2_cdf_buffer.spec56_scmy_hg.data  = transpose(dc_spec3.y)
;*l2_cdf_buffer.spec56_scmz_hg.data  = transpose(dc_spec4.y)
;
;*l2_cdf_buffer.spec56_fcenter.data = bins_56_dc.freq_avg
;*l2_cdf_buffer.spec56_fbandwidth.data = bins_56_dc.freq_hi - bins_56_dc.freq_lo
;
;l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)
;
;end