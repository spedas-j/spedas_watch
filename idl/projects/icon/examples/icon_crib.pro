;+
;NAME:
;   icon_crib
;
;PURPOSE:
;   Examples of loading and plotting ICON data
;   If step = 99 then it runs all steps
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-10 10:41:33 -0700 (Thu, 10 May 2018) $
;$LastChangedRevision: 25192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib.pro $
;
;-------------------------------------------------------------------

pro icon_crib, step=step

  if ~keyword_set(step) then step = 1

  ; Specify a time range
  timeRange = ['2010-05-23/00:00', '2010-05-24/12:00']

  if step eq 1 or step eq 99 then begin
    del_data, '*'
    ; Specify an instrument
    instrument = 'fuv'
    ; Specify a data type to load
    datal1type = 'lwp'
    ; Load ICON data
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    ; Print the names of loaded tplot variables
    tplot_names
    ; Specify plot options
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'yrange', [45.6, 46.2]
    options, 'ICON_L1_FUVB_Board_TEMP', 'yrange', [27.2, 28.0]
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'ytitle', 'HV PHOS !C'
    options, 'ICON_L1_FUVB_Board_TEMP', 'ytitle', 'Board TEMP !C'
    options, 'ICON_L1_FUVB_LWP_Raw_P0', 'ytitle', 'Raw P0 !C'
    options, 'ICON_L1_FUVB_LWP_PROF_P0_Error', 'ytitle', 'PROF P0 Error !C'
    tplot_options, 'title', 'ICON FUV LWP (2010-05-23)'
    ; Plot data
    tplot, ['ICON_L1_FUVB_LWP_HV_PHOS', 'ICON_L1_FUVB_Board_TEMP','ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error']
    ; Save png file
    makepng,'c:/temp/icon/ICON_L1_FUVB_LWP'
    ; Print time limits
    get_data,'ICON_L1_FUVB_LWP_HV_PHOS',data=d, dlimits = dl
    print, time_string(d.x[0]), time_string(d.x[n_elements(d.x)-1])
  endif

  if step eq 2 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'swp'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'yrange', [19.4, 19.7]
    options, 'ICON_L1_FUVA_CCD_TEMP', 'yrange', [18.5,20.0]
    tplot, ['ICON_L1_FUVA_SWP_HV_MCP', 'ICON_L1_FUVA_CCD_TEMP','ICON_L1_FUVA_SWP_Raw_M3','ICON_L1_FUVA_SWP_PROF_M3_Error']
    makepng,'c:/temp/icon/ICON_L1_FUVA_SWP'
  endif

  if step eq 3 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'sli'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L1_FUVA_Limb_Raw', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Limb_Raw1', data={x:d.x, y:d.y[*,*,95], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L1_FUVA_Limb_Raw1', 'yrange', [-1.0, 1.0]
    get_data, 'ICON_L1_FUVA_Limb_IMG', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Limb_IMG1', data={x:d.x, y:d.y[*,*,95], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L1_FUVA_Limb_IMG1', 'yrange', [-1.0, 1.0]

    tplot, ['ICON_L1_FUVA_SWI_Chain_ID', 'ICON_L1_FUV_OPT_TEMP','ICON_L1_FUVA_Limb_Raw1','ICON_L1_FUVA_Limb_IMG1']
    makepng,'c:/temp/icon/ICON_L1_FUVA_SLI'
    ;Spectrograms: ICON_L1_FUVA_LIMB_RAW[95,*,*] and ICON_L1_FUVA_LIMB_IMG[95,*,*]
  endif

  if step eq 4 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'ssi'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L1_FUVA_Sublimb_Raw', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Sublimb_Raw1', data={x:d.x, y:d.y[*,*,80], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L1_FUVA_Sublimb_Raw1', 'yrange', [-1.0, 1.0]
    get_data, 'ICON_L1_FUVA_Sublimb_IMG', data=d, dlimits=dlimits
    store_data, 'ICON_L1_FUVA_Sublimb_IMG1', data={x:d.x, y:d.y[*,*,80], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L1_FUVA_Sublimb_IMG1', 'yrange', [-1.0, 1.0]

    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'yrange', [11.0, 14.0]
    tplot, ['ICON_L1_FUVA_SWI_Integration_Time', 'ICON_L1_FUV_IMG_TEMP','ICON_L1_FUVA_Sublimb_Raw1','ICON_L1_FUVA_Sublimb_IMG1']
    makepng,'c:/temp/icon/ICON_L1_FUVA_SSI'
    ;Spectrograms: ICON_L1_FUVA_SUBLIMB_RAW[80,*,*] and ICON_L1_FUVA_SUBLIMB_IMG[80,*,*]
  endif

  if step eq 5 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal2type = 'O-nighttime'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names

    get_data, 'ICON_L2_FUVA_TANGENT_LAT', data=d, dlimits=dlimits
    store_data, 'ICON_L2_FUVA_TANGENT_LAT1', data={x:d.x, y:d.y[*,*,3], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L2_FUVA_TANGENT_LAT1', 'yrange', [-1.0, 1.0]
    get_data, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE', data=d, dlimits=dlimits
    store_data, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', data={x:d.x, y:d.y[*,*,3], v1:d.v1, v2:d.v2}, dlimits=dlimits
    options, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', 'yrange', [-1.0, 1.0]

    options, 'ICON_L2_ORBIT_NUMBER', 'yrange', [1480, 1580]
    tplot, ['ICON_L2_FUV_SC_LAT', 'ICON_L2_ORBIT_NUMBER','ICON_L2_FUVA_TANGENT_LAT1','ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1']
    makepng,'c:/temp/icon/ICON_L2_nighttime'
    ;Spectrograms: ICON_L2_FUVA_TANGENT_LAT[3,*,*] and ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE[3,*,*]
  endif

  if step eq 6 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal2type = 'O-daytime'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    tplot, ['icon_l2_FUV_daytime_ON2_retrieval_f107', 'icon_l2_FUV_daytime_ON2_retrieval_latitude','icon_l2_FUV_daytime_ON2_original_data','icon_l2_FUV_daytime_ON2_model_altitudes']
    makepng,'c:/temp/icon/ICON_L2_daytime'
    ;Time series: ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_F107 and ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_LATITUDE
    ;Spectrograms: ICON_L2_FUV_DAYTIME_ON2_ORIGINAL_DATA and ICON_L2_FUV_DAYTIME_ON2_MODEL_ALTITUDES
  endif

  if step eq 7 or step eq 99 then begin
    del_data, '*'
    instrument = 'ivm'
    datal1type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    tplot, ['ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ICON_L1_IVM_A_SC_MLT','ICON_L1_IVM_A_RPA_currents','ICON_L1_IVM_A_LLA_i']
    makepng,'c:/temp/icon/ICON_L1_IVM'
    ;Time series: ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X and ICON_L1_IVM_A_SC_MLT
    ;Spectrograms: ICON_L1_IVM_A_RPA_CURRENTS and ICON_L1_IVM_A_LLA_I
  endif

  if step eq 8 or step eq 99 then begin
    del_data, '*'
    instrument = 'ivm'
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    tplot, ['ICON_L2_IVM_A_LONGITUDE', 'ICON_L2_IVM_A_AP_POT']
    makepng,'c:/temp/icon/ICON_L2_IVM'
    ;Time series: ICON_L2_IVM_A_LONGITUDE and ICON_L2_IVM_A_AP_POT
    ;Spectrograms: there are no 2D data in those files
  endif

  print, 'icon_crib2 finished'
end
