pro mms_check_fom_uplink, tai_fomstr, sroi_structure, error_flags, error_indices, error_msg, error_times

; Now we check whether the structure falls within a sub_roi
sroi_starts_tai = mms_unix2tai(time_double(sroi_structure.starts))
sroi_stops_tai = mms_unix2tai(time_double(sroi_structure.stops))

roi_check = -1 ; tells me which ROI index is bad
for i = 0, n_elements(sroi_starts_tai)-1 do begin
  if tai_fomstr.evalstarttime ge sroi_starts_tai[i] and tai_fomstr.evalstarttime le sroi_stops_tai[i] then begin
    roi_check += 1
  endif
endfor

; Finally, we check to make sure there are no selections after the designated close
real_stops = tai_fomstr.cyclestart + tai_fomstr.stop
oob_loc = where(real_stops ge tai_fomstr.evalstarttime, count_oob)

if count_oob gt 0 then begin
  oob_warning_times = strarr(count_oob)
  convert_time_stamp, tai_fomstr.cyclestart, tai_fomstr.start(oob_loc), oob_warning_times
endif else begin
  oob_warning_times = ''
endelse


;-----------------------------------------------------------------------------
; Define output arrays
;-----------------------------------------------------------------------------
 
error_flags = [roi_check ge 0, $
               count_oob gt 0]
               
error_indices = ptrarr(n_elements(error_flags), /allocate_heap)
error_times = ptrarr(n_elements(error_flags), /allocate_heap)
error_msg = strarr(n_elements(error_flags))

oob_times = tai_fomstr.start[oob_loc]

(*error_indices[0]) = !values.f_nan
(*error_indices[1]) = oob_times

(*error_times[0]) = 'Window-wide error, no times'
(*error_times[1]) = oob_warning_times

error_msg = ['Error, close time may not be within a sub-ROI', $
             'Error, selections at the following time stamps are after the close time, which is not allowed: ']

end