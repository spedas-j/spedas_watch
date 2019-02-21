;+
;NAME:
;   icon_crib_mighti
;
;PURPOSE:
;   Example of loading and plotting ICON data for the MIGHTI instrument
;
;KEYWORDS:
;   step: (optional) selects the example to run, if 99 then it runs all of them
;   img_path: (optional) Directory where the plot files will be saved
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: $
;$LastChangedDate:$
;$LastChangedRevision:$
;$URL:$
;
;-------------------------------------------------------------------

pro icon_crib_mighti, step=step, img_path=img_path

  ; Specify a time range
  timeRange = ['2010-05-21/23:58:00', '2010-05-22/00:02:00']
  ; Specify a directory for images
  if ~keyword_set(img_path) then begin
    if (!D.NAME eq 'WIN') then img_path = 'C:\temp\icon\' else img_path = 'temp/icon/'
  endif

  if ~keyword_set(step) then step = 1

  cdf_leap_second_init

  if step eq 1 or step eq 99 then begin
    ;MIGHTI-A Level-1
    del_data, '*'
    instrument = 'mighti-a'
    datal1type = '*'
    datal2type = ''
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    tplot_options, 'title', 'ICON MIGHTI-A'

    ylim, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 24500D, 24800D
    options, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'psym', 4
    options, 'ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'ytitle', 'Temperature'

    tplot, ['ICON_L0_MIGHTI_A_Optics_Temperature_Aft']    

    makepng,img_path + 'ICON_MIGHTI_A_L1_Example'
    get_data, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness', data=d, dl=dl
    yyy = transpose(d.y)
    
    store_data, 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', data={x:d.x, y:yyy} 
    
    
    tplot, ['ICON_L0_MIGHTI_A_Optics_Temperature_Aft', 'ICON_L1_MIGHTI_A_Green_Relative_Brightness2', $
      'ICON_L1_MIGHTI_A_Red_Relative_Brightness','ICON_L1_MIGHTI_A_Red_Array_Altitudes']
    ;Time series:
    ;ICON_L0_MIGHTI_A_OPTICS_TEMPERATURE_AFT

    ;Spectrogram:
    ;ICON_L1_MIGHTI_A_GREEN_ARRAY_RELATIVE_BRIGHTNESS
    ;ICON_L1_MIGHTI_A_RED_ARRAY_RELATIVE_BRIGHTNESS
    ;ICON_L1_MIGHTI_A_RED_ARRAY_ALTITUDES

  endif
  
  if step eq 2 or step eq 99 then begin
    ;MIGHTI Level-2 Wind
    del_data, '*'
    
    timeRange = ['2010-05-21/00:00:00', '2010-05-21/23:59:59']
    instrument = 'mighti'
    datal1type = ''
    datal2type = '*'
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type    
    
    options, 'ICON_L2_MIGHTI_RED_ZONAL_WIND', 'ytitle', 'Red Zonal'    
    options, 'ICON_L2_MIGHTI_RED_MERIDIONAL_WIND', 'ytitle', 'Red Meridional'    
    options, 'ICON_L2_MIGHTI_GREEN_ZONAL_WIND', 'ytitle', 'Green Zonal'    
    options, 'ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND', 'ytitle', 'Green Meridional'

    tplot_options, 'title', 'ICON MIGHTI Wind (Level-2 Data)'

    makepng,img_path + 'ICON_MIGHTI_L2_Example'
    
    tplot, ['ICON_L2_MIGHTI_RED_ZONAL_WIND', 'ICON_L2_MIGHTI_RED_MERIDIONAL_WIND','ICON_L2_MIGHTI_GREEN_ZONAL_WIND',$
      'ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND']

    ;Spectrogram:
    ;ICON_L2_MIGHTI_RED_ZONAL_WIND
    ;ICON_L2_MIGHTI_RED_MERIDIONAL_WIND
    ;ICON_L2_MIGHTI_GREEN_ZONAL_WIND
    ;ICON_L2_MIGHTI_GREEN_MERIDIONAL_WIND

  endif  

  print, 'icon_crib_mighti finished'
end