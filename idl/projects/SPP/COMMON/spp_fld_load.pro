;+
;
;  Author: Davin Larson December 2018
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-04-03 17:12:19 -0700 (Fri, 03 Apr 2020) $
; $LastChangedRevision: 28493 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_fld_load.pro $
;
;-

pro spp_fld_load, trange=trange, type = type, files=files, $
  fileprefix=fileprefix,$
  tname_prefix=tname_prefix, pathformat=pathformat,$
  no_load=no_load,varformat=varformat, $
  no_server = no_server, $
  longterm_ephem = longterm_ephem, $
  level = level, get_support = get_support, downsample = downsample, $
  no_staging = no_staging

  if not keyword_set(type) then begin
    dprint,'Choices for type include: mag_SC mag_RTN rfs_lfr rfs_hfr mag_SC_4_Sa_per_Cyc'
    dprint,'See the directories at: "http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/" for other valid entries'
    type = 'mag_SC'
    dprint,'Default is: ', type
  endif
  

  if not keyword_set(level) then level = 2

  ; TODO: remove this line once we have Level 2 ephemeris files

  l1_types = ['rfs_lfr_auto', 'rfs_hfr_auto', 'rfs_burst']

  dummy = where(l1_types EQ type, l1_type_flag)
  
  if (strpos(type, 'ephem') EQ 0) or (l1_type_flag NE 0) then level = 1

  if type EQ 'dfb_dc_spec' or type EQ 'dfb_ac_spec' or $
    type EQ 'dfb_dc_xspec' or type EQ 'dfb_ac_xspec' then begin

    if level EQ 1 then begin
      spec_types = ['1','2','3','4']
    endif else begin

      if type EQ 'dfb_dc_spec' or type EQ 'dfb_ac_spec' then begin
        spec_types = ['dV12hg','dV34hg','dV12lg','dV34lg',$
          'SCMulfhg','SCMvlfhg','SCMwlfhg', $
          'SCMulflg','SCMvlflg','SCMwlflg', $
          'SCMdlfhg','SCMelfhg','SCMflfhg', $
          'SCMdlflg','SCMelflg','SCMflflg', $
          'SCMmf', 'V5hg']
      endif else begin
        spec_types = ['SCMdlfhg_SCMelfhg','SCMdlfhg_SCMflfhg','SCMelfhg_SCMflfhg', $
          'dV12hg_dV34hg']

      endelse


    endelse


    all_files = []

    foreach spec_type, spec_types do begin

      spp_fld_load, trange=trange, type = type + '_' + spec_type, files=files, $
        fileprefix=fileprefix,$
        tname_prefix=tname_prefix, pathformat=pathformat,$
        no_load=no_load,varformat=varformat, $
        level = level, get_support = get_support, downsample = downsample

      all_files = [all_files, files]

      pathformat = !null
      files = !null

      if (tnames('psp_fld_l2_dfb_?c_*spec*_' + spec_type))[0] NE '' then begin
        options, 'psp_fld_l2_dfb_?c_xspec_power*', $
          'no_interp', 1
        options, 'psp_fld_l2_dfb_?c_*spec*_' + spec_type, $
          'no_interp', 1
      end
      ;stop

    end

    if max(strlen(all_files)) GT 0 then $
      files = all_files[where(strlen(all_files) GT 0)] else files = !null

    return

  endif

  ; Get all of the available bandpass files on a given day

  if type EQ 'dfb_dc_bpf' or type EQ 'dfb_ac_bpf' then begin

    spec_types = ['dV12hg','dV34hg',$
      'SCMulfhg','SCMvlfhg','SCMwlfhg', $
      'SCMulflg','SCMvlflg','SCMwlflg', $
      'SCMumfhg', 'V5hg']

    all_files = []

    foreach spec_type, spec_types do begin

      spp_fld_load, trange=trange, type = type + '_' + spec_type, files=files, $
        fileprefix=fileprefix,$
        tname_prefix=tname_prefix, pathformat=pathformat,$
        no_load=no_load,varformat=varformat, $
        level = level, get_support = get_support, downsample = downsample

      all_files = [all_files, files]

      pathformat = !null
      files = !null

      if (tnames('psp_fld_l2_dfb_?c_bpf_' + spec_type + '_avg'))[0] NE '' then begin
        options, 'psp_fld_l2_dfb_?c_bpf_' + spec_type + ['_avg','_peak'], $
          'no_interp', 1
      end

    end

    if max(strlen(all_files)) GT 0 then $
      files = all_files[where(strlen(all_files) GT 0)] else files = !null

    return

  endif

  daily_names = 1

  if not keyword_set(fileprefix) then begin
    if level EQ 2 then fileprefix = 'psp/data/sci/fields/staging/l2/' else $
      fileprefix = 'psp/data/sci/fields/staging/l1/'
  endif

  if n_elements(no_staging) GT 0 then $
    fileprefix = str_sub(fileprefix, '/staging/', '/')


  if not keyword_set(pathformat) then begin
    if level EQ 2 then begin
      pathformat =  'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDD_v??.cdf'
      if type EQ 'mag_SC' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_dbm_dvac' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
        re_order = 1
      endif
      if type EQ 'mag_RTN' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'mag_VSO' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_wf_dvdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_wf_vdc' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_wf_scm' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_dbm_dvac' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_dbm_scm' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDDhh_v??.cdf'
        resolution = 3600l * 6l ; hours
        daily_names = 0
      endif
      if type EQ 'dfb_dc_spec' then begin
        pathformat = 'TYPE/YYYY/MM/psp_fld_l2_TYPE_*_YYYYMMDD_v??.cdf'
      endif
    endif else begin
      pathformat = 'TYPE/YYYY/MM/spp_fld_l1_TYPE_YYYYMMDD_v??.cdf'
    endelse
  endif

  ; The DFB spectra and bandpass files are organized in folders which allow
  ; more than one type of file in the folder--for example, in the first encounter
  ; the DC spectra folder for 2018/11 contains dV12hg, SCMdlfhg, SCMdlfhg,
  ; and SCMelfhg files.  The below string substitution makes sure the load
  ; routine is addressing this correctly.

  if (strmid(type, 0, 12) EQ 'dfb_dc_xspec') or (strmid(type, 0, 12) EQ 'dfb_ac_xspec') and level EQ 2 then begin

    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 12))

  endif

  if (strmid(type, 0, 10) EQ 'dfb_dc_bpf') or (strmid(type, 0, 10) EQ 'dfb_ac_bpf') and level EQ 2 then begin

    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 10))

  endif

  if (strmid(type, 0, 11) EQ 'dfb_dc_spec') or (strmid(type, 0, 11) EQ 'dfb_ac_spec') and level EQ 2 then begin

    pathformat = 'DIR' + pathformat

    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 11))

  endif

  pathformat = str_sub(pathformat,'TYPE',type)
  pathformat = fileprefix+pathformat


  ;  example location: http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/mag_RTN/2019/04/psp_fld_l2_mag_RTN_20190401_v00.cdf
  pathformat = str_sub(pathformat,'ss', 's\s' )    ; replace ss with escape so that ss will not be converted to seconds

  if level EQ 1.5 then pathformat = str_sub(pathformat,'/l1/', '/l1b/' )
  if level EQ 1.5 then pathformat = str_sub(pathformat,'_l1_', '_l1b_' )

  ; Special case for loading longterm ephemeris files

  if n_elements(longterm_ephem) GT 0 then begin

    pathformat = str_sub(pathformat, 'YYYY/MM/', 'full_mis\sion/')
    
    pathformat = str_sub(pathformat, 'YYYYMMDD', $
      '20180812_090000_20250831_090000')

    ;stop

  endif


  files = spp_file_retrieve(key='FIELDS',pathformat,trange=trange,source=src,$
    /last_version,daily_names=daily_names,/valid_only,$
    resolution = resolution, shiftres = 0, no_server = no_server)

  if files[0] EQ '' then begin

    dprint, 'No valid files found'
    return

  end

  if not keyword_set(no_load) then begin
    if level EQ 1 then begin

      spp_fld_load_l1, files, varformat = varformat, downsample = downsample

    endif else begin

      if strmatch(type,'rfs_?fr') then begin

        psp_fld_rfs_load_l2, files

      endif else begin

        if n_elements(varformat) GT 0 then begin
          cdf2tplot,files,varformat=varformat,prefix=tname_prefix,/load_labels
        endif else begin
          cdf2tplot,files,prefix=tname_prefix,/all, /load_labels
        endelse

      endelse

      ;      if strmatch(type,'rfs_?fr') then begin
      ;        dprint,'Modifying limits'
      ;        zlim,'*psp_fld_l2_rfs_?fr_*_V?V?',1e-16,1e-14,1 , /default
      ;        ylim,'*psp_fld_l2_rfs_hfr_*_V?V?',1.1e6,22e6,1   , /default
      ;        ylim,'*psp_fld_l2_rfs_lfr_*_V?V?',1e4,2e6,1   , /default
      ;      endif

      if strmatch(type,'mag_*') then begin

        if tnames('psp_fld_l2_mag_RTN_1min') NE '' then begin
          options,'psp_fld_l2_mag_RTN_1min', 'ytitle', 'MAG RTN'
          options,'psp_fld_l2_mag_RTN_1min',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_RTN_1min',labels=['R','T','N'] ,/default
          options,'psp_fld_l2_mag_RTN_1min','max_points',10000
          options,'psp_fld_l2_mag_RTN_1min','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_SC_1min') NE '' then begin
          options,'psp_fld_l2_mag_SC_1min', 'ytitle', 'MAG SC'
          options,'psp_fld_l2_mag_SC_1min',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_SC_1min',labels=['X','Y','Z'] ,/default
          options,'psp_fld_l2_mag_SC_1min','max_points',10000
          options,'psp_fld_l2_mag_SC_1min','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_RTN_4_Sa_per_Cyc') NE '' then begin
          options,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc', 'ytitle', 'MAG RTN'
          options,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc',labels=['R','T','N'] ,/default
          options,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc','max_points',10000
          options,'psp_fld_l2_mag_RTN_4_Sa_per_Cyc','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_SC_4_Sa_per_Cyc') NE '' then begin
          options,'psp_fld_l2_mag_SC_4_Sa_per_Cyc', 'ytitle', 'MAG SC'
          options,'psp_fld_l2_mag_SC_4_Sa_per_Cyc',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_SC_4_Sa_per_Cyc',labels=['X','Y','Z'] ,/default
          options,'psp_fld_l2_mag_SC_4_Sa_per_Cyc','max_points',10000
          options,'psp_fld_l2_mag_SC_4_Sa_per_Cyc','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_RTN') NE '' then begin
          options,'psp_fld_l2_mag_RTN', 'ytitle', 'MAG RTN'
          options,'psp_fld_l2_mag_RTN',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_RTN',labels=['R','T','N'] ,/default
          options,'psp_fld_l2_mag_RTN','max_points',10000
          options,'psp_fld_l2_mag_RTN','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_VSO') NE '' then begin
          options,'psp_fld_l2_mag_VSO', 'ytitle', 'MAG VSO'
          options,'psp_fld_l2_mag_VSO',colors='bgr' ,/default
          options,'psp_fld_l2_mag_VSO','max_points',10000
          options,'psp_fld_l2_mag_VSO','psym_lim',300
        endif

        if tnames('psp_fld_l2_mag_SC') NE '' then begin
          options,'psp_fld_l2_mag_SC', 'ytitle', 'MAG SC'
          options,'psp_fld_l2_mag_SC',colors='bgr' ,/default
          ;options,'psp_fld_l2_mag_SC',labels=['X','Y','Z'] ,/default
          options,'psp_fld_l2_mag_SC','max_points',10000
          options,'psp_fld_l2_mag_SC','psym_lim',300
        endif

      endif

      if strmatch(type, 'dfb_wf_*') then begin

        if tnames('psp_fld_l2_dfb_wf_dVdc_sensor') NE '' then begin
          options,'psp_fld_l2_dfb_wf_dVdc_sensor', 'ytitle', 'DFB WF dV_DC'
          options,'psp_fld_l2_dfb_wf_dVdc_sensor',colors='br' ,/default
          options,'psp_fld_l2_dfb_wf_dVdc_sensor','max_points',10000
          options,'psp_fld_l2_dfb_wf_dVdc_sensor','psym_lim',300
        endif

        if tnames('psp_fld_l2_dfb_wf_dVdc_sc') NE '' then begin
          options,'psp_fld_l2_dfb_wf_dVdc_sc', 'ytitle', 'DFB WF dV_DC'
          options,'psp_fld_l2_dfb_wf_dVdc_sc',colors='br' ,/default
          options,'psp_fld_l2_dfb_wf_dVdc_sc','max_points',10000
          options,'psp_fld_l2_dfb_wf_dVdc_sc','psym_lim',300
        endif

        if tnames('psp_fld_l2_dfb_wf_V1dc') NE '' then begin
          options,'psp_fld_l2_dfb_wf_V1dc', 'ytitle', 'DFB WF V1_DC'
          options,'psp_fld_l2_dfb_wf_V2dc', 'ytitle', 'DFB WF V2_DC'
          options,'psp_fld_l2_dfb_wf_V3dc', 'ytitle', 'DFB WF V3_DC'
          options,'psp_fld_l2_dfb_wf_V4dc', 'ytitle', 'DFB WF V4_DC'
          options,'psp_fld_l2_dfb_wf_V5dc', 'ytitle', 'DFB WF V5_DC'

          options,'psp_fld_l2_dfb_wf_V?dc','max_points',10000
          options,'psp_fld_l2_dfb_wf_V?dc','psym_lim',300
        endif

        if tnames('psp_fld_l2_dfb_wf_scm_hg_sc') NE '' or $
          tnames('psp_fld_l2_dfb_wf_scm_lg_sc') NE '' then begin
          options,'psp_fld_l2_dfb_wf_scm_hg_s*', 'ytitle', 'DFB WF SCM'
          options,'psp_fld_l2_dfb_wf_scm_?g_s*', colors = 'bgr', /default
          options,'psp_fld_l2_dfb_wf_scm_?g_s*','max_points',10000
          options,'psp_fld_l2_dfb_wf_scm_?g_s*','psym_lim',300
        endif



      endif

      if tnames('psp_fld_l2_quality_flags') NE '' then begin

        options, 'psp_fld_l2_quality_flags', 'tplot_routine', 'bitplot'

        options, 'psp_fld_l2_quality_flags', 'numbits', 8
        options, 'psp_fld_l2_quality_flags', 'yticks', 9 ; numbits + 1

        options, 'psp_fld_l2_quality_flags', 'psyms', [2]


        qf_labels = $
          ['BIAS_SWP','THRUSTER','SCM_CAL',$
          'MAG_ROLL','MAG_CAL','SPC_EMODE','SLS_CAL','OFF_UMBRA']

        options, 'psp_fld_l2_quality_flags', 'labels', $
          qf_labels

        options, 'psp_fld_l2_quality_flags', 'ytitle', $
          'Quality Flags'


        options, 'psp_fld_l2_quality_flags', 'colors', $
          [0,1,2,6]

        options, 'psp_fld_l2_quality_flags', 'yticklen', 1
        options, 'psp_fld_l2_quality_flags', 'ygridstyle', 1

        options, 'psp_fld_l2_quality_flags', 'yminor', 1


      endif

    endelse

  endif


end
