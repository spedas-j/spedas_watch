pro geopack_validate,cdf_filename=cdf_filename

; Load position data for field calculations
timespan,'2007-03-23'
thm_load_state,probe='a',coord='gsm',suffix='_gsm'

; Compute field model at s/c positions

; T89
tt89,'tha_state_pos_gsm',kp=2.0,/exact_tilt_times,newname='bt89',get_tilt='bt89_tilt'
tt89,'tha_state_pos_gsm',kp=2.0,/exact_tilt_times,/igrf_only,newname='bt89_igrf'


; T96
tt96,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,/exact_tilt_times,newname='bt96'

; T01
tt01,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,g1=6.0,g2=10.0,/exact_tilt_times,newname='bt01'

; TS04

tt04s,'tha_state_pos_gsm',pdyn=2.0,dsti=-30.0,yimf=0.0,zimf=-5.0,w1=8.0,w2=5.0,w3=9.5,w4=30.0,w5=18.5,w6=60.0,/exact_tilt_times,newname='bts04'

cdf_varlist=['tha_state_pos_gsm','bt89_tilt','bt89','bt89_igrf',$
  'bt96','bt01','bts04']
tplot2cdf,filename=cdf_filename,tvars=cdf_varlist,/default_cdf_structure
end