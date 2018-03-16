;+
; PROCEDURE:
;  spd_slice1d_plot
;
; PURPOSE:
;  Create 1D plot from a 2D particle slice
;
; EXAMPLE:
;  spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0'
;
; INPUT:
;  slice: slice returned by spd_slice2d
;  direction: axis to plot - 'x' or 'y'
;  value: if direction is 'x', this is the y-value to create a 1D plot at; 
;         can also be a range of values, e.g., [-1000, 1000] to sum over 
;         the y-values from -1000 to +1000 
;
; KEYWORDS:
;   accepts most keywords accepted by the PLOT procedure
;
; NOTES:
;   work in progress! please send bugs/problems/complaints/etc to egrimes@igpp.ucla.edu
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-15 14:38:42 -0700 (Thu, 15 Mar 2018) $
;$LastChangedRevision: 24894 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice1d_plot.pro $
;-

pro spd_slice1d_plot, slice, direction, value, _extra=ex

  if ~is_struct(slice) then begin
    dprint, dlevel = 0, 'Error, invalid slice'
    return
  endif
  
  if undefined(value) || (strlowcase(direction) ne 'x' && strlowcase(direction) ne 'y') then begin
    dprint, dlevel = 0, 'Error, invalid direction; valid options are: "x" or "y"'
    return
  endif
  
  if undefined(value) then begin
    dprint, dlevel = 0, 'Error, no value provided.'
    return
  end
  
  yunits = spd_units_string(strlowcase(slice.units))
  xunits = slice.XYUNITS
  
  ; multiple points, summed
  if n_elements(value) eq 2 then begin
    if direction eq 'x' then begin
      values_to_include = where(slice.ygrid ge value[0] and slice.ygrid le value[1], value_count)
      if value_count ne 0 then begin
        plot, slice.xgrid, total(/nan, slice.data[*, values_to_include], 2), xtitle=xunits, ytitle=yunits, xmargin=15, _extra=ex
      endif
    endif else if direction eq 'y' then begin
      values_to_include = where(slice.xgrid ge value[0] and slice.xgrid le value[1], value_count)
      if value_count ne 0 then begin
        plot, slice.ygrid, total(/nan, slice.data[values_to_include, *], 1), xtitle=xunits, ytitle=yunits, xmargin=15, _extra=ex
      endif
    endif
    return
  endif
  
  ; single point
  if direction eq 'x' then begin
    closest_at_this_value = find_nearest_neighbor(slice.ygrid, value)
    idx_at_this_value = where(slice.ygrid eq closest_at_this_value)
    plot, slice.xgrid, slice.data[*, idx_at_this_value], xtitle=xunits, ytitle=yunits, xmargin=15, _extra=ex
  endif else if direction eq 'y' then begin
    closest_at_this_value = find_nearest_neighbor(slice.xgrid, value)
    idx_at_this_value = where(slice.xgrid eq closest_at_this_value)
    plot, slice.ygrid, slice.data[idx_at_this_value, *], xtitle=xunits, ytitle=yunits, xmargin=15, _extra=ex
  endif

end