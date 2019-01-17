pro spp_fld_make_or_retrieve_cdf, $
  apid_name, $
  make = make, $
  load = load, $
  filenames = filenames

  if keyword_set(make) then begin

    spp_fld_make_cdf_l1, apid_name, load = load

  endif else begin

    remote_site = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/staging/l1/'

    get_timespan, ts

    if strmid(apid_name, 0, 3) EQ 'dfb' then begin

      final_underscore = strpos(apid_name, '_', /reverse_search)

      apid_name = strmid(apid_name, 0, final_underscore) + $
        strmid(apid_name, final_underscore + 1)

    endif
    
    if apid_name EQ 'dcb_ssr_telemetry' then apid_name = 'dcb_s\sr_telemetry'
    if apid_name EQ 'rfs_hfr_cross' then apid_name = 'rfs_hfr_cros\s'

    files = file_retrieve(apid_name + '/YYYY/MM/spp_fld_l1_' + apid_name + '_YYYYMMDD_v00.cdf', $
      local_data_dir = getenv('PSP_STAGING_DIR'), $
      remote_data_dir = remote_site, no_update = 0, $
      trange = time_string(ts, tformat = 'YYYY-MM-DD/hh:mm:ss'), $
      user_pass = getenv('USER') + ':' + getenv('PSP_STAGING_PW'))

    valid_files = where(file_test(files) EQ 1, valid_count)

    if valid_count GT 0 then filenames = files[valid_files]

    if keyword_set(load) then begin

      if valid_count GT 0 then begin

        spp_fld_load_l1, files[valid_files]

      end

    endif

  endelse

end
