pro spp_fld_make_cdf_l2_dfb_spec, $
  l2_master_cdf, l2_cdf, ac_dc

  ac_dc = strlowcase(ac_dc)

  if ac_dc NE 'ac' and ac_dc NE 'dc' then begin

    dprint, dlevel = 1, 'Must specify AC or DC when calling SPP_FLD_MAKE_CDF_L2_DFB_SPEC'

    return

  endif

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  if n_elements(l2_master_cdf) EQ 0 or n_elements(l2_cdf) EQ 0 then begin

    dprint, dlevel = 1, 'L2 master CDF or L2 CDF not specified'
    return

  endif

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  ; Read data from the TPLOT variables

  get_data, 'spp_fld_dfb_' + ac_dc + '_spec_1_spec_converted', data = spec1
  get_data, 'spp_fld_dfb_' + ac_dc + '_spec_2_spec_converted', data = spec2
  get_data, 'spp_fld_dfb_' + ac_dc + '_spec_3_spec_converted', data = spec3
  get_data, 'spp_fld_dfb_' + ac_dc + '_spec_4_spec_converted', data = spec4

  unix_time = spec1.x

  n_full = n_elements(unix_time)

  met_time = unix_time - time_double('2010-01-01/00:00:00')

  tt2000_time = long64((add_tt2000_offset(unix_time) - $
    time_double('2000-01-01/12:00:00'))*1.e9)

  spp_fld_dfb_frequencies

  ; TODO: 96 frequency bins in addition to 56

  if ac_dc EQ 'dc' then begin
    bins_56 = spp_get_fft_bins_04_dc(56)
  endif else begin
    bins_56 = spp_get_fft_bins_04_ac(56)
  endelse

  *l2_cdf_buffer.Epoch.data         = tt2000_time

  ; TODO: Hard coded association of spec to data type should actually use
  ; the metadata in the L1 file

  *l2_cdf_buffer.spec56_e12.data  = transpose(spec1.y)
  *l2_cdf_buffer.spec56_scmx_hg.data  = transpose(spec2.y)
  *l2_cdf_buffer.spec56_scmy_hg.data  = transpose(spec3.y)
  *l2_cdf_buffer.spec56_scmz_hg.data  = transpose(spec4.y)

  *l2_cdf_buffer.spec56_fcenter.data = bins_56.freq_avg
  *l2_cdf_buffer.spec56_fbandwidth.data = bins_56.freq_hi - bins_56.freq_lo

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)



end