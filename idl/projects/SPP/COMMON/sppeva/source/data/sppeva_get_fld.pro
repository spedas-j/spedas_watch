PRO sppeva_get_fld, apid_name
  compile_opt idl2


  if undefined(apid_name) then apid_name = 'f1_100bps'

  ;remote_site = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/l1/'
  remote_site = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/staging/l1/'
  
  if strmid(apid_name, 0, 3) EQ 'dfb' then begin
    final_underscore = strpos(apid_name, '_', /reverse_search)
    apid_name = strmid(apid_name, 0, final_underscore) + $
      strmid(apid_name, final_underscore + 1)
  endif

  if apid_name EQ 'dcb_ssr_telemetry' then apid_name = 'dcb_s\sr_telemetry'
  if apid_name EQ 'rfs_hfr_cross' then apid_name = 'rfs_hfr_cros\s'

  files = file_retrieve(apid_name + '/YYYY/MM/spp_fld_l1_' + apid_name + '_YYYYMMDD_v00.cdf', $
    local_data_dir = !SPPEVA.FILD.FLD_LOCAL_DATA_DIR,$
    remote_data_dir = remote_site, $
    trange = time_string(timerange(), tformat = 'YYYY-MM-DD/hh:mm:ss'), $
    user_pass = !SPPEVA.FILD.SPPFLDSOC_ID+':'+!SPPEVA.FILD.SPPFLDSOC_PW)

  valid_files = where(file_test(files) EQ 1, valid_count)

  if valid_count GT 0 then begin
    spp_fld_load_l1, files[valid_files]
  end
  
  trange = timerange()
  tp = 'spp_fld_f1_100bps_DFB_SCM_PEAK_converted'
  if spd_data_exists(tp, trange[0], trange[1]) then begin
    options, tp, zlog=1 
  endif
  tp = 'spp_fld_f1_100bps_DFB_V34AC_PEAK_converted'
  if spd_data_exists(tp, trange[0], trange[1]) then begin
    options, tp, zlog=1
  endif 

END