; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-01-03 22:37:44 -0800 (Wed, 03 Jan 2024) $
; $LastChangedRevision: 32333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_calval.pro $
; $Id: swfo_stis_inst_response_calval.pro 32333 2024-01-04 06:37:44Z davin-mac $



function swfo_stis_inst_response_calval,reset=reset

  common swfo_stis_inst_response_com, swfo_stis_inst_response_calval_dict, cal1, cal2

  if keyword_set(reset) then  obj_destroy,swfo_stis_inst_response_calval_dict
  
  if ~isa( swfo_stis_inst_response_calval_dict, 'dictionary') then begin
    calval = dictionary()
  endif else begin
    calval = swfo_stis_inst_response_calval_dict
  endelse
  
  if calval.isempty() then begin
    calval.instrument_name  = 'SWFO-STIS'
    dim = [3,2]
    nan = !values.f_nan
    names_fto = strsplit('1 2 12 3 13 23 123',/extract)
    names_fto = reform( transpose( [['O-'+names_fto],['F-'+names_fto]]))
    geom_raw   = .13 * [nan, .01,  1 , .99]   * !pi
    det_adc_scales = [234.1  , 228.4 , 232.4, 233.4, 232.7,  232.5]/ 59.5    ; for conversion from nrg to adc units 
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
    calval.rev_date = '$Id: swfo_stis_inst_response_calval.pro 32333 2024-01-04 06:37:44Z davin-mac $'
    swfo_stis_inst_response_calval_dict  = calval
    dprint,'Using Revision: '+calval.rev_date
  endif

  return, calval
end




