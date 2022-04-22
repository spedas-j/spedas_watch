; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $


function swfo_stis_sci_level_1b,strcts,format=format

  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]
    
    cal = swfo_stis_cal_params(str)

    duration = str.duration

    period = .87  ; approximate period (in seconds) of Version 64 FPGA ; this should be put in the calibration structure
    rate  = str.counts/(str.duration * period) 

;    str_element,/add,str,'integration_time',duration * period
;    str_element,/add,str,'rate',rate
;    str_element,/add,str,'TID',cal.tid
;    str_element,/add,str'FTO',cal.fto

    flux = rate / cal.geom / cal.ewidth
    sci_ex = {  $
      integration_time : duration * period, $
      rate : rate , $
      TID:  cal.tid,  $
      FTO:  cal.fto,  $
      geom:  cal.geom,  $
      ewidth: cal.ewidth,  $
      energy: cal.energy,   $   ; midpoint energy
      flux :   flux }
      
    sci = create_struct(str,sci_ex)
      
    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci 

  endfor

  return,output
    
end

