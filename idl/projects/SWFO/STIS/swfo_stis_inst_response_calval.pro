; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-16 11:15:41 -0800 (Sat, 16 Dec 2023) $
; $LastChangedRevision: 32295 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_calval.pro $
; $Id: swfo_stis_inst_response_calval.pro 32295 2023-12-16 19:15:41Z davin-mac $


;
;
;function swfo_stis_adc_calibration,sensornum
;  ;message,'obsolete.  Contained within swfo_stis_lut2map.pro'
;  adc_scale =  [[[ 43.77, 38.49, 41.13 ] ,  $  ;1A          O T F
;    [ 41.97, 40.29, 42.28 ]] ,  $  ;1B
;    [[ 40.25, 44.08, 43.90 ] ,  $  ;2A
;    [ 43.22, 43.97, 41.96 ]]]   ;  2B
;  adc_scale = adc_scale[*,*,sensornum] / 59.5
;  return,adc_scale
;end
;
;
;function swfo_stis_cal_adc2nrg,adc,tid,fto
;   adc_scales = 237./59.5
;   return, adc / adc_scales
;
;end
;

function swfo_stis_inst_response_calval,reset=reset

  common swfo_stis_inst_response_com, swfo_stis_inst_response_calval_dict, cal1, cal2

  if keyword_set(reset) then  obj_destroy,swfo_stis_inst_response_calval_dict
  
  if ~isa( swfo_stis_inst_response_calval_dict, 'dictionary') then begin
    calval = dictionary()
  endif else begin
    calval = swfo_stis_inst_response_calval_dict
  endelse
  
  if calval.isempty() then begin
    dim = [3,2]
    nan = !values.f_nan
    names_fto = strsplit('1 2 12 3 13 23 123',/extract)
    names_fto = reform( transpose( [['O-'+names_fto],['F-'+names_fto]]))
    geom_raw   = .13 * [nan, .01,  1 , .99]
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
    calval.rev_date = '$Id: swfo_stis_inst_response_calval.pro 32295 2023-12-16 19:15:41Z davin-mac $'
    swfo_stis_inst_response_calval_dict  = calval
    dprint,'Using Revision: '+calval.rev_date
  endif

  return, calval
end




