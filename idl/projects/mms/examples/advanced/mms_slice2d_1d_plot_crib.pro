;+
; PURPOSE:
;  Crib sheet demonstrating how to create 1D plots of 2D distribution slices created by spd_slice2d
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-14 14:59:52 -0700 (Wed, 14 Mar 2018) $
;$LastChangedRevision: 24886 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_slice2d_1d_plot_crib.pro $
;-

;======================================================================
; Basic setup for FPI / copy+pasted from mms_slice2d_fpi_crib
;======================================================================

probe='1'
level='l2'
species='i'
data_rate='brst'

name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate

trange=['2017-11-18/07:50', '2017-11-18/07:52'] ;time range to load
time = '2017-11-18/07:51' ;slice time

;load particle data into tplot
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
  probe=probe, trange=trange, min_version='2.2.0'

;reformat data from tplot variable into compatible 3D structures
dist = mms_get_dist(name, trange=trange)

;get single distribution
;  -3d/2d interpolation show smooth contours
;  -3d interpolates entire volume
;  -2d interpolates projection of a subset of data near the slice plane
;  -geometric interpolation is slow but shows bin boundaries
;---------------------------------------------
slice = spd_slice2d(dist, time=time) ;3D interpolation

;======================================================================
; Create the 1D plot from the slice
;======================================================================

; note: spd_slice1d_plot accepts most keywords the PLOT procedure accepts, e.g., title
; the input arguments are slice, direction ('x' or 'y'), value to create the plot at
spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0'
stop

;======================================================================
; Create the 1D plot from the slice with bulk velocity subtracted
;======================================================================

; load velocity data from the moments files
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', probe=probe, trange=trange
  
slice = spd_slice2d(dist, time=time, /subtract_bulk, vel_data='mms'+probe+'_d'+species+'s_bulkv_dbcs_brst')

spd_slice1d_plot, slice, 'x', 0.0, title='Vx at Vy=0 (bulk V frame)', xrange=[-400, 400]

stop
end