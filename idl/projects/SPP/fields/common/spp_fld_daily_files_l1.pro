pro spp_fld_daily_files_l1, start_day, n_days, $
  make_cdf = make_cdf, $
  ql_plot = ql_plot, $
  plot_types = plot_types, $
  file_types = file_types, $
  ephem = ephem, $
  local = local

  if (n_elements(make_cdf) EQ 0 and $
    n_elements(file_types) EQ 0) then make_cdf = 0 else make_cdf = 1
  if (n_elements(ql_plot) EQ 0 and $
    n_elements(plot_types) EQ 0) then ql_plot = 0 else ql_plot = 1

  if not keyword_set(start_day) then start_day = ['2018-08-13']

  if not keyword_set(n_days) then n_days = 1

  days = time_string(time_double(start_day) + dindgen(n_days) * 86400d)

  foreach day, days do begin

    timespan, day

    get_timespan, ts

    if keyword_set(make_cdf) then begin

      if n_elements(file_types) EQ 0 then $
        file_types = [$
        'f1_100bps', $
        'rfs_hfr_auto', $
        'rfs_hfr_cross', $
        'rfs_lfr_auto', $
        'rfs_lfr_hires', $
        'rfs_hfr_cross', $
        'dfb_dc_spec_1', $
        'dfb_dc_spec_2', $
        'dfb_dc_spec_3', $
        'dfb_dc_spec_4', $
        'dfb_ac_spec_1', $
        'dfb_ac_spec_2', $
        'dfb_ac_spec_3', $
        'dfb_ac_spec_4', $
        'dfb_dc_xspec_1', $
        'dfb_dc_xspec_2', $
        'dfb_dc_xspec_3', $
        'dfb_dc_xspec_4', $
        'dfb_dc_xspec_1', $
        'dfb_dc_xspec_2', $
        'dfb_dc_xspec_3', $
        'dfb_dc_xspec_4', $
        'dfb_ac_xspec_1', $
        'dfb_ac_xspec_2', $
        'dfb_ac_xspec_3', $
        'dfb_ac_xspec_4', $
        'dfb_ac_xspec_1', $
        'dfb_ac_xspec_2', $
        'dfb_ac_xspec_3', $
        'dfb_ac_xspec_4', $
        'dfb_dc_bpf_1', $
        'dfb_dc_bpf_2', $
        'dfb_dc_bpf_3', $
        'dfb_dc_bpf_4', $
        'dfb_ac_bpf_1', $
        'dfb_ac_bpf_2', $
        'dfb_ac_bpf_3', $
        'dfb_ac_bpf_4', $
        'dfb_wf_01', $
        'dfb_wf_02', $
        'dfb_wf_03', $
        'dfb_wf_04', $
        'dfb_wf_05', $
        'dfb_wf_06', $
        'dfb_wf_07', $
        'dfb_wf_08', $
        'dfb_wf_09', $
        'dfb_wf_10', $
        'dfb_wf_11', $
        'dfb_wf_12', $
        'dfb_dbm_1', $
        'dfb_dbm_2', $
        'dfb_dbm_3', $
        'dfb_dbm_4', $
        'dfb_dbm_5', $
        'dfb_dbm_6', $
        'dfb_cbs_status', $
        'dfb_sc_potential', $
        'mago_survey', $
        'mago_hk', $
        'magi_survey', $
        'magi_hk', $
        'dcb_analog_hk', $
        'dcb_events', $
        'dcb_ssr_telemetry', $
        'aeb1_hk', $
        'aeb2_hk', $
        'sc_hk_191', $
        'sc_hk_high', $
        'sc_hk_med', $
        'sc_fsw_rec_alloc']

      if file_types[0] EQ 'ephem_all' and n_elements(file_types) EQ 1 then $
        file_types = [$
        'ephem_J2000', $
        'ephem_ECLIPJ2000', $
        'ephem_EARTH_FIXED', $
        'ephem_SPP_ECLIPDATE', $
        'ephem_SPP_GSE', $
        'ephem_SPP_MSO', $
        'ephem_SPP_VSO', $
        'ephem_SPP_HG', $
        'ephem_SPP_HCI', $
        'ephem_SPP_HEE', $
        'ephem_SPP_HEEQ', $
        'ephem_SPP_RTN', $
        'ephem_SPP_HERTN', $
        'ephem_SPP_HGI', $
        'ephem_SPP_HGDOPP', $
        'ephem_SPP_HGMAG', $
        'ephem_SPP_HGSPEC']

      spp_fld_tmlib_init, server = 'spffmdb.ssl.berkeley.edu', /daily

      foreach file_type, file_types do begin

        spp_fld_make_cdf_l1, file_type, /daily

      endforeach
    endif

    if n_elements(plot_types) EQ 0 then $
      plot_types = ['F1_100BPS', 'RFS_HFR', 'RFS_LFR', 'DFB_AC_SPEC', $
      'DFB_DC_SPEC','DFB_AC_BPF', $
      'DFB_DC_BPF', 'DFB_WF_E_B', 'DFB_WF_V', 'MAGO', 'MAGI', $
      'SC_HK', 'DCB_HK', 'DCB_EVENTS', 'DCB_SSR','AEB_HK','TEMPS','EPHEM', $
      'EPHEM_ALL']

    if plot_types[0] EQ 'EPHEM_ALL' and n_elements(plot_types) EQ 1 then $
      plot_types = [$
      'EPHEM_J2000', $
      'EPHEM_ECLIPJ2000', $
      'EPHEM_EARTH_FIXED', $
      'EPHEM_SPP_ECLIPDATE', $
      'EPHEM_SPP_GSE', $
      'EPHEM_SPP_MSO', $
      'EPHEM_SPP_VSO', $
      'EPHEM_SPP_HG', $
      'EPHEM_SPP_HCI', $
      'EPHEM_SPP_HEE', $
      'EPHEM_SPP_HEEQ', $
      'EPHEM_SPP_RTN', $
      'EPHEM_SPP_HERTN', $
      'EPHEM_SPP_HGI', $
      'EPHEM_SPP_HGDOPP', $
      'EPHEM_SPP_HGMAG', $
      'EPHEM_SPP_HGSPEC']


    if keyword_set(ql_plot) then begin

      store_data, '*', /del

      spp_fld_tmlib_init, server = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/l1/'

      state = dictionary()
      state.server = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/l1/'
      state.timespan = ts
      state.save_directory = test_cdf_dir ;'~/temp2/'
      state.title_annotation = ''

      if keyword_set(local) then $
        state.server = getenv('SPP_FLD_DAILY_DIR') + 'fields/l1/'

      foreach plot_type, plot_types do begin

        ql_dir = getenv('SPP_FLD_DAILY_DIR') + 'fields/ql_plot/' + plot_type + '/'

        ql_subdir = time_string(ts[0], tformat = 'YYYY/MM/')

        ql_fname = 'psp_fld_' + plot_type + time_string(ts[0], tformat = '_YYYYMMDD')

        print, ql_dir + ql_subdir + ql_fname

        spp_fld_load_test_data, load_select = plot_type, state = state;, /plot_only

        file_mkdir, ql_dir + ql_subdir

        spp_fld_tplot_eps, ql_dir + ql_subdir + ql_fname, $
          font = -1, xmargin = [18,18], ymargin = [6,8], $
          /delete_eps

        ;wait, 1

      endforeach

    endif


  end
end