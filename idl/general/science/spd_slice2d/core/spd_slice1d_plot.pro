;+
; PROCEDURE:
;  spd_slice1d_plot
;
; PURPOSE:
;  Create plots for 2D particle slices.
;
; EXAMPLE:
;  spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0'
;
; INPUT:
;  slice: 2D array of values to plot
;  direction: axis to plot - 'x' or 'y'
;  value: if direction is 'x', this is the y-value to create a 1D plot at
;
; KEYWORDS:
;   accepts most keywords accepted by the PLOT procedure
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-14 14:57:18 -0700 (Wed, 14 Mar 2018) $
;$LastChangedRevision: 24884 $
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