;+
;NAME:
;   icon_crib
;
;PURPOSE:
;   Examples of loading and plotting ICON data
;   If step = 99 then it runs all steps
;   Saves png plots in the directory specified by img_path
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-23 11:07:45 -0700 (Wed, 23 May 2018) $
;$LastChangedRevision: 25248 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib.pro $
;
;-------------------------------------------------------------------

pro icon_crib, step=step

  ; Specify a time range
  timeRange = ['2010-05-23/00:00', '2010-05-23/23:59:59']
  ; Specify a directory for images
  img_path = 'c:/temp/icon/'

  if ~keyword_set(step) then step = 1

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
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'ytitle', 'HV PHOS !C'
    options, 'ICON_L1_FUVB_LWP_HV_PHOS', 'psym', 3

    options, 'ICON_L1_FUVB_Board_TEMP', 'yrange', [27.2, 28.0]
    options, 'ICON_L1_FUVB_Board_TEMP', 'ytitle', 'Board TEMP !C'
    options, 'ICON_L1_FUVB_Board_TEMP', 'psym', 3

    options, 'ICON_L1_FUVB_LWP_Raw_P0', 'ytitle', 'Raw P0 !C'

    options, 'ICON_L1_FUVB_LWP_PROF_P0_Error', 'ytitle', 'PROF P0 Error !C'

    ; Fill gaps with NaN
    tdegap, ['ICON_L1_FUVB_LWP_HV_PHOS', 'ICON_L1_FUVB_Board_TEMP'], overwrite=1
    tdegap, ['ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error'], overwrite=1, /twonanpergap

    ; Title for the plot
    tplot_options, 'title', 'ICON FUV L1 LWP'

    ; Plot data
    tplot, ['ICON_L1_FUVB_LWP_HV_PHOS', 'ICON_L1_FUVB_Board_TEMP','ICON_L1_FUVB_LWP_Raw_P0','ICON_L1_FUVB_LWP_PROF_P0_Error']
    ; Save png file
    makepng,img_path + '1_ICON_FUV_L1_LWP'
    ; Print time limits
    get_data,'ICON_L1_FUVB_LWP_HV_PHOS',data=d, dlimits = dl
    print, time_string(d.x[0]), time_string(d.x[n_elements(d.x)-1])
  endif

  if step eq 2 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal1type = 'swp'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'yrange', [19.4, 19.7]
    options, 'ICON_L1_FUVA_CCD_TEMP', 'yrange', [18.0,20.0]

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'ytitle', 'HV MCP !C'
    options, 'ICON_L1_FUVA_CCD_TEMP', 'ytitle', 'CCD TEMP !C'
    options, 'ICON_L1_FUVA_SWP_Raw_M3', 'ytitle', 'SWP Raw M3 !C'
    options, 'ICON_L1_FUVA_SWP_PROF_M3_Error', 'ytitle', 'PROF M3 Error !C'

    options, 'ICON_L1_FUVA_SWP_HV_MCP', 'psym', 3
    options, 'ICON_L1_FUVA_CCD_TEMP', 'psym', 3

    tplot_options, 'title', 'ICON FUV L1 SWP'
    tdegap, ['ICON_L1_FUVA_SWP_HV_MCP', 'ICON_L1_FUVA_CCD_TEMP'], overwrite=1
    tdegap, ['ICON_L1_FUVA_SWP_Raw_M3','ICON_L1_FUVA_SWP_PROF_M3_Error'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWP_HV_MCP', 'ICON_L1_FUVA_CCD_TEMP','ICON_L1_FUVA_SWP_Raw_M3','ICON_L1_FUVA_SWP_PROF_M3_Error']

    makepng,img_path + '2_ICON_FUV_L1_SWP'
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
        
    options, 'ICON_L1_FUVA_SWI_Chain_ID', 'psym', 3
    options, 'ICON_L1_FUV_OPT_TEMP', 'psym', 3

    options, 'ICON_L1_FUVA_SWI_Chain_ID', 'ytitle', 'SWI Chain ID !C'
    options, 'ICON_L1_FUV_OPT_TEMP', 'ytitle', 'OPT TEMP !C'
    options, 'ICON_L1_FUVA_Limb_Raw1', 'ytitle', 'Limb Raw 95 !C'
    options, 'ICON_L1_FUVA_Limb_IMG1', 'ytitle', 'Limb IMG 95 !C'

    tplot_options, 'title', 'ICON FUV L1 SLI'
    tdegap, ['ICON_L1_FUVA_SWI_Chain_ID', 'ICON_L1_FUV_OPT_TEMP'], overwrite=1
    tdegap, ['ICON_L1_FUVA_Limb_Raw1','ICON_L1_FUVA_Limb_IMG1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWI_Chain_ID', 'ICON_L1_FUV_OPT_TEMP','ICON_L1_FUVA_Limb_Raw1','ICON_L1_FUVA_Limb_IMG1']
    makepng,img_path + '3_ICON_FUV_L1_SLI'
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
    
    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'psym', 3
    options, 'ICON_L1_FUV_IMG_TEMP', 'psym', 3
    
    options, 'ICON_L1_FUVA_SWI_Integration_Time', 'ytitle', 'SWI Integration Time !C'
    options, 'ICON_L1_FUV_IMG_TEMP', 'ytitle', 'IMG TEMP !C'
    options, 'ICON_L1_FUVA_Sublimb_Raw1', 'ytitle', 'Sublimb Raw 80 !C'
    options, 'ICON_L1_FUVA_Sublimb_IMG1', 'ytitle', 'Sublimb IMG 80 !C' 
    
    tplot_options, 'title', 'ICON FUV L1 SSI'
    tdegap, ['ICON_L1_FUVA_SWI_Integration_Time', 'ICON_L1_FUV_IMG_TEMP'], overwrite=1
    tdegap, ['ICON_L1_FUVA_Sublimb_Raw1','ICON_L1_FUVA_Sublimb_IMG1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L1_FUVA_SWI_Integration_Time', 'ICON_L1_FUV_IMG_TEMP','ICON_L1_FUVA_Sublimb_Raw1','ICON_L1_FUVA_Sublimb_IMG1']
    makepng,img_path + '4_ICON_FUV_L1_SSI'
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

    options, 'ICON_L2_FUV_SC_LAT', 'psym', 3
    options, 'ICON_L2_ORBIT_NUMBER', 'psym', 3

    options, 'ICON_L2_FUV_SC_LAT', 'ytitle', 'SC LAT !C'
    options, 'ICON_L2_ORBIT_NUMBER', 'ytitle', 'ORBIT NUMBER !C'
    options, 'ICON_L2_FUVA_TANGENT_LAT1', 'ytitle', 'TANGENT LAT 3 !C'
    options, 'ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1', 'ytitle', 'ALTITUDE PROFILE 3 !C'

    options, 'ICON_L2_ORBIT_NUMBER', 'yrange', [1480, 1580]
    
    tplot_options, 'title', 'ICON FUV L2 O-nighttime'
    tdegap, ['ICON_L2_FUV_SC_LAT', 'ICON_L2_ORBIT_NUMBER'], overwrite=1
    tdegap, ['ICON_L2_FUVA_TANGENT_LAT1','ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1'], overwrite=1, /twonanpergap
    tplot, ['ICON_L2_FUV_SC_LAT', 'ICON_L2_ORBIT_NUMBER','ICON_L2_FUVA_TANGENT_LAT1','ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE1']
    makepng,img_path + '5_ICON_FUV_L2_nighttime'
    ;Spectrograms: ICON_L2_FUVA_TANGENT_LAT[3,*,*] and ICON_L2_FUVA_SWP_VER_ALTITUDE_PROFILE[3,*,*]
  endif

  if step eq 6 or step eq 99 then begin
    del_data, '*'
    instrument = 'fuv'
    datal2type = 'O-daytime'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    
    options, 'icon_l2_FUV_daytime_ON2_retrieval_f107', 'psym', 3
    options, 'icon_l2_FUV_daytime_ON2_retrieval_latitude', 'psym', 3

    options, 'icon_l2_FUV_daytime_ON2_retrieval_f107', 'ytitle', 'retrieval f107 !C'
    options, 'icon_l2_FUV_daytime_ON2_retrieval_latitude', 'ytitle', 'retrieval latitude !C'
    options, 'icon_l2_FUV_daytime_ON2_original_data', 'ytitle', 'original data !C'
    options, 'icon_l2_FUV_daytime_ON2_model_altitudes', 'ytitle', 'model altitudes !C'
    
    tplot_options, 'title', 'ICON FUV L2 O-daytime'
    tdegap, ['icon_l2_FUV_daytime_ON2_retrieval_f107', 'icon_l2_FUV_daytime_ON2_retrieval_latitude'], overwrite=1
    tdegap, ['icon_l2_FUV_daytime_ON2_original_data','icon_l2_FUV_daytime_ON2_model_altitudes'], overwrite=1, /twonanpergap
    tplot, ['icon_l2_FUV_daytime_ON2_retrieval_f107', 'icon_l2_FUV_daytime_ON2_retrieval_latitude','icon_l2_FUV_daytime_ON2_original_data','icon_l2_FUV_daytime_ON2_model_altitudes']
    makepng,img_path + '6_ICON_FUV_L2_daytime'
    ;Time series: ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_F107 and ICON_L2_FUV_DAYTIME_ON2_RETRIEVAL_LATITUDE
    ;Spectrograms: ICON_L2_FUV_DAYTIME_ON2_ORIGINAL_DATA and ICON_L2_FUV_DAYTIME_ON2_MODEL_ALTITUDES
  endif

  if step eq 7 or step eq 99 then begin
    del_data, '*'
    instrument = 'ivm'
    datal1type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names
    
    options, 'ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'psym', 3
    options, 'ICON_L1_IVM_A_SC_MLT', 'psym', 3

    options, 'ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ytitle', 'NORTH FOOTPOINT !C FA ECEF X !C'
    options, 'ICON_L1_IVM_A_SC_MLT', 'ytitle', 'SC MLT !C'
    options, 'ICON_L1_IVM_A_RPA_currents', 'ytitle', 'RPA currents!C'
    options, 'ICON_L1_IVM_A_LLA_i', 'ytitle', 'LLA i !C'    
    
    tplot_options, 'title', 'ICON IVM L1'
    tdegap, ['ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ICON_L1_IVM_A_SC_MLT'], overwrite=1
    tdegap, ['ICON_L1_IVM_A_RPA_currents','ICON_L1_IVM_A_LLA_i'], overwrite=1, /twonanpergap
      
    tplot, ['ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X', 'ICON_L1_IVM_A_SC_MLT','ICON_L1_IVM_A_RPA_currents','ICON_L1_IVM_A_LLA_i']
    makepng,img_path + '7_ICON_IVM_L1'
    ;Time series: ICON_L1_IVM_A_NORTH_FOOTPOINT_FA_ECEF_X and ICON_L1_IVM_A_SC_MLT
    ;Spectrograms: ICON_L1_IVM_A_RPA_CURRENTS and ICON_L1_IVM_A_LLA_I
  endif

  if step eq 8 or step eq 99 then begin
    del_data, '*'
    instrument = 'ivm'
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type
    tplot_names   
    
    options, 'ICON_L2_IVM_A_LONGITUDE', 'psym', 3
    options, 'ICON_L2_IVM_A_AP_POT', 'psym', 3

    options, 'ICON_L2_IVM_A_LONGITUDE', 'ytitle', 'LONGITUDE !C'
    options, 'ICON_L2_IVM_A_AP_POT', 'ytitle', 'AP POT !C'
    
    tplot_options, 'title', 'ICON IVM L2'
    tdegap, ['ICON_L2_IVM_A_LONGITUDE', 'ICON_L2_IVM_A_AP_POT'], overwrite=1    
    
    tplot, ['ICON_L2_IVM_A_LONGITUDE', 'ICON_L2_IVM_A_AP_POT']
    makepng,img_path + '8_ICON_IVM_L2'
    ;Time series: ICON_L2_IVM_A_LONGITUDE and ICON_L2_IVM_A_AP_POT
    ;Spectrograms: there are no 2D data in those files
  endif

  print, 'icon_crib finished'
end
