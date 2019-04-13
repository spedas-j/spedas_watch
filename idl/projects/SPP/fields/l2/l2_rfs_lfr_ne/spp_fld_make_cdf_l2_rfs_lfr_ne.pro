pro spp_fld_make_cdf_l2_rfs_lfr_ne, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir, $
  downsample_cadence = downsample_cadence

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  if n_elements(trange) EQ 1 then trange = trange[0] + [0d, 86400d]

  ; MAGo only for now

  ; Read raw count data from the Level 1 TPLOT variables

  get_data, 'spp_fld_rfs_lfr_auto_averages_ch0_corrected_V1V2_ne', data = dat_ne

  get_data, 'spp_fld_rfs_lfr_auto_CCSDS_MET_Seconds', data = met
  get_data, 'spp_fld_rfs_lfr_auto_CCSDS_MET_SubSeconds', data = ssec


;  stop

;  return
;

  ; Calculate the UTC time for the MAG packets from the MET and subseconds
  ; values for each packet

  unix_time = time_double(psp_fld_met_to_utc(met.y, ssec.y))

  ; Calculate TT2000 time stamps

  tt2000_time = long64((add_tt2000_offset(unix_time)-time_double('2000-01-01/12:00:00'))*1.e9)

  ; Limit to fixed boundaries

  tt2000_min = long64((add_tt2000_offset(trange[0]) - time_double('2000-01-01/12:00:00'))*1e9)
  tt2000_max = long64((add_tt2000_offset(trange[1]) - time_double('2000-01-01/12:00:00'))*1e9)

  tt2000_valid = where((tt2000_time GE tt2000_min) and (tt2000_time LT tt2000_max), valid_count)

  if valid_count EQ 0 then return
  
  tt2000_time  = tt2000_time[tt2000_valid]
  
  
  
  ne_data = dat_ne.y[tt2000_valid]
  
  ; Write data to the L2 CDF buffer (see spp_fld_make_cdf_l2)

  *l2_cdf_buffer.Epoch.data         = tt2000_time

  *l2_cdf_buffer.psp_fld_l2_rfs_lfr_ne.data            = ne_data

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

  ; The write_data_to_cdf procedure doesn't allow for easy modification
  ; of global variables, so we do it here instead.

;  cdf_id = cdf_open(l2_cdf)
;
;  attexst = cdf_attexists(cdf_id,'l1_mago_survey_file')
;  if (attexst) then begin
;    attid = cdf_attnum(cdf_id, 'l1_mago_survey_file')
;    cdf_attput, cdf_id, attid, 0L, 'placeholder_for_input_filename'
;    dprint, dlevel = 3, 'Changed l1_mago_survey_file attribute to ','placeholder_for_input_filename'
;  endif
;
;  cdf_close, cdf_id

end