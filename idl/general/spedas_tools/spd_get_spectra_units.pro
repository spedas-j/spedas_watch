;+
; FUNCTION:
;     spd_get_spectra_units
;     
; PROCEDURE:
;     Returns the y-axis and z-axis units from a spectra variable's CDF metadata
; 
; INPUT:
;     var: spectra variable
; 
; OUTPUT:
;     structure containing 'yunits' and 'zunits' tags
;     
;     -1 if no CDF metadata found
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-03-17 15:24:54 -0700 (Wed, 17 Mar 2021) $
; $LastChangedRevision: 29767 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_get_spectra_units.pro $
;-

function spd_get_spectra_units, var

  get_data, var, dlimits=dl
  if ~is_struct(dl) then begin
    dprint, dlevel=1, 'No CDF metadata found: ' + var
    return, -1
  endif

  str_element, dl, 'cdf', success=s
  if ~s then begin
    dprint, dlevel=1, 'No CDF metadata found: ' + var
    return, -1
  endif
  
  str_element, dl.cdf, 'vatt', success=s
  if ~s then begin
    dprint, dlevel=1, 'No CDF variable attributes found: ' + var
    return, -1
  endif
  
  str_element, dl.cdf.vatt, 'units', success=s
  if ~s then begin
    dprint, dlevel=1, 'No units found in variable attributes: ' + var
    return, -1
  endif

  ; spectra variables should always have depend_1 set in their CDF variable atts
  get_data, dl.cdf.vatt.depend_1, dlimits=yaxis_metadata
  
  if ~is_struct(yaxis_metadata) then return, -1
  
  return, {yunits: yaxis_metadata.cdf.vatt.units, zunits: dl.cdf.vatt.units}
end