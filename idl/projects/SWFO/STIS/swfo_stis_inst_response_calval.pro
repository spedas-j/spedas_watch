; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-06-03 15:59:53 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33366 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_calval.pro $
; $Id: swfo_stis_inst_response_calval.pro 33366 2025-06-03 22:59:53Z rjolitz $



function swfo_stis_inst_response_calval,reset=reset

  common swfo_stis_inst_response_com, swfo_stis_inst_response_calval_dict, cal1, cal2

  if keyword_set(reset) then  obj_destroy,swfo_stis_inst_response_calval_dict
  
  if ~isa( swfo_stis_inst_response_calval_dict, 'dictionary') then begin
    calval = dictionary()
  endif else begin
    calval = swfo_stis_inst_response_calval_dict
  endelse

  if calval.isempty() then begin
    nan = !values.f_nan

    calval.instrument_name  = 'SWFO-STIS'
    ; Channel names / detector names:
    calval.channels = ['1', '2', '3', '4', '5', '6']
    calval.detectors = ['O1, O2', 'O3', 'F1', 'F2', 'F3']
    ; names_fto = strsplit('1 2 12 3 13 23 123',/extract)
    ; names_fto = reform( transpose( [['O-'+names_fto],['F-'+names_fto]]))

    ; Geometric factor needs verification:
    ; calval.geometric_factor = .13 * [nan, .01,  1 , .99]   * !pi
    ; calval.geometric_factor = .2  * [nan, .01,1,1,.01,1,1]
    calval.geometric_factor = 0.2 * [0.01, 1., 1., 0.01, 1., 1.]
    geom_raw = [nan, calval.geometric_factor]
    calval.coincidence =$
      ['O1', 'F1', 'O2', 'F2', 'O12', 'F12',$
       'O3', 'F3', 'O13', 'F13', 'O23', 'F23',$
       'O123', 'F123']
    calval.coincidence_index = indgen(14)
    calval.detector_index = [0, 1]
    calval.coincidence_map = dictionary()
    calval.coincidence_map.O123 = 12
    calval.coincidence_map.O23 = 10
    calval.coincidence_map.O13 = 8
    calval.coincidence_map.O12 = 4
    calval.coincidence_map.O3 = 6
    calval.coincidence_map.O2 = 2
    calval.coincidence_map.O1 = 0
    ; Elec indexL
    calval.coincidence_map.F123 = 13
    calval.coincidence_map.F23 = 11
    calval.coincidence_map.F13 = 9
    calval.coincidence_map.F12 = 5
    calval.coincidence_map.F3 = 7
    calval.coincidence_map.F2 = 3
    calval.coincidence_map.F1 = 1

    ; Calibration result: ADC values for the Americium-241 59.5 keV line 
    ; for detectors O1, O2, O3, F1, F2, F3:
    calibrated_adc_bins = [    234.06952     ,  228.35745    ,  231.78710     ,  232.06377      ,  232.78850      ,  231.65691    ]  
    ; calibrated_adc_bins = [234.1  , 228.4 , 232.4, 233.4, 232.7,  232.5]
    detector_keV_per_adc = 59.5 / calibrated_adc_bins   ; for conversion from nrg to adc units 
    calval.detector_keV_per_adc = detector_keV_per_adc
    det_adc_scales = 1/detector_keV_per_adc

    ; Deadtime:
    ; calval.deadtime_s = 1e-6
    calval.deadtime_s = 10e-6

    ; Criteria for deadtime correction:
    ; This accepts the big pixel if the deadtime correction below 1.2
    ; and de-emphasizes it as deadtime correction exceeds 1.8.
    calval.deadtime_correction_criteria = [1.2, 1.8]

    ; Criteria for Poisson statistics:
    ; This accepts the small pixel if the # counts above
    ; 100, only uses the big pixel if the # counts below/equal
    ; 1, weights by sqrt(N) between:
    calval.poisson_statistics_criteria = [1e2, 1e4]
    ; calval.poisson_statistics_criteria = [0, 1e4]
    calval.poisson_statistics_power_coefficient = 0.5

    dim = [3,2]


    det2fto = [0, 1, 2, 1, 3,  1, 3, 1   ]
    det2fto = [1, 2, 1, 3,  1, 3, 1   ]
    fto2detmap  = [ [1,4], [2,5],  [1,4],  [3,6],  [3,6], [3,6], [3,6]] 

    s = 1/ reform(det_adc_scales,dim)
    nrg_scales = fltarr(2,7)
    for i=0,1 do  $
      nrg_scales[i,*] = [ s[0,i]  , s[1,i] , average( s[[0,1],i] )  , s[2,i], average( s[[2,0],i] ),  average( s[[2,1],i] ), average( s[[0,1,2],i] )  ]
    
    
    calval.names_fto        = names_fto
    calval.geoms         = reform( geom_raw[[1,2,3,1,2,3]] , dim )
    calval.geoms_tid_fto = [1,1] #  geom_raw[det2fto] 
    calval.adc_scales  = reform( det_adc_scales ,dim)
    calval.adc_sigmas   = reform( [5.02   ,14.42  , 9.65  ,5.695,  13.88, 8.37 ]  ,dim)
    calval.nrg_scales  = nrg_scales
    calval.nrg_sigmas   = calval.adc_sigmas  / calval.adc_scales
    calval.nrg_thresholds  = calval.nrg_sigmas * 5
    calval.adc_offset  = replicate( 0., dim)
    calval.proton_O_dl  = 12.  ;  keV
    calval.proton_F_dl  = 300.  ; kev
    calval.electron_F_dl = 10.  ; keV
    
    calval.nse_threshold = [0.84, 1.4, 1.05, 0.84, 1.4, 1.05]
    calval.rate_threshold = [10e3, 10e3, 10e3, 10e3, 10e3, 10e3]
    calval.reaction_wheel_threshold = [2000, 2000, 2000, 2000]
    calval.dap_temperature_threshold = [-35., 50.]
    calval.sensor_1_temperature_threshold = [-50., 45.]
    calval.sensor_2_temperature_threshold = [-50., 45.]

    ; nonlut ADC corresponds to clog_17_6 (compressed log)
    calval.nonlut_adc_min  =$
      [   0,    1,    2,    3,$
          4,    5,    6,    7,$
          8,   10,   12,   14,$
         16,   20,   24,   28,$
         32,   40,   48,   56,$
         64,   80,   96,  112,$
        128,  160,  192,  224,$
        256,  320,  384,  448,$
        512,  640,  768,  896,$
       1024, 1280, 1536, 1792,$
       2048, 2560, 3072, 3584,$
       4096, 5120, 6144, 7168,$
       2L^13    ]

;    cal_functions = orderedhash()
    calval.nrglost_vs_nrgmeas = orderedhash()
    
    EINC    = [3.5572231, 9.5011850, 19.054607, 51.946412, 170.25940, 581.35906, 1791.9807, 6245.3324]
    ELOST   = [0.75692672, 5.0485519, 11.489006, 15.762845, 12.833813, 7.9859661, 3.8584909, 1.1063090]
    Emeas    = [1.3318166, 8.2329514, 26.984297, 67.781489, 196.48678, 1214.6312, 5194.6412, 69894.733]
    ELOST   = [3.8584909, 9.8085852, 13.671814, 14.796677, 11.672128, 4.9693458, 1.4024602, 0.23119755]
    calval.nrglost_vs_nrgmeas['Proton-O-3'] = spline_fit3(!null,emeas,elost,/xlog,/ylog)
    calval.nrglost_vs_nrgmeas['Proton-O-1'] = calval.nrglost_vs_nrgmeas['Proton-O-3']

    Emeas    = [2.4111388, 21.544347, 94.044485, 419.00791, 5873.3907, 44554.225]
    ELOST = [266.69694, 255.38404, 234.17752, 151.81073, 26.237311, 5.8814151]
    calval.nrglost_vs_nrgmeas['Proton-F-3'] =  spline_fit3(!null,emeas,ELOST,/xlog,/ylog)
    calval.nrglost_vs_nrgmeas['Proton-F-1'] =  calval.nrglost_vs_nrgmeas['Proton-F-3']
    
    NRGMEAS = [1.3048349, 4.4554224, 19.448624, 138.74656, 427.67229]
    NRGLOST = [19.218670, 12.035385, 4.2277243, 0.74616804, 0.13914896]
    calval.nrglost_vs_nrgmeas['Electron-F-3'] =  spline_fit3(!null,NRGMEAS,NRGLOST,/xlog,/ylog)
    calval.nrglost_vs_nrgmeas['Electron-F-1'] =  calval.nrglost_vs_nrgmeas['Electron-F-3']
    
    calval.responses = orderedhash()
    calval.rev_date = '$Id: swfo_stis_inst_response_calval.pro 33366 2025-06-03 22:59:53Z rjolitz $'
    swfo_stis_inst_response_calval_dict  = calval
    dprint,'Using Revision: '+calval.rev_date
  endif

  return, calval
end




