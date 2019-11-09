;+
; NAME: crib_fill_time_intv
; 
; PURPOSE:  Crib to demonstrate thte fill_time_intv option for tplot
;           You can run this crib by typing:
;           IDL>.compile crib_fill_time_intv
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot.pro  (basic tplot commands)
;           crib_tplot_layout.pro  (how to arrange plots within a window, and data within a plot)
;           crib_tplot_range.pro   (how to control the range and scaling of plots)
;           crib_tplot_export_print.pro (how to export images of plots into pngs and postscripts)
;           crib_tplot_annotation.pro  (how to control labels, titles, and colors of plots)
;
; NOTES:
;  1.  As a rule of thumb, "tplot_options" controls settings that are global to any tplot
;   "options" controls settings that are specific to a tplot variable
;   
;  2.  If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-11-08 11:30:39 -0800 (Fri, 08 Nov 2019) $
; $LastChangedRevision: 27994 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_fill_time_intv.pro $
;-

;Setup
;-------------------------------------------------

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2008-03-23'

;loading spectral data
st_swea_load, /all

;loading line plot data (stereo moments)
st_part_moments, probe='a', /get_mom

st_position_load, probe='a'

;set new color scheme (for aesthetics)
init_crib_colors

;make sure we're using window 0
tplot_options, window=0
window, 0, xsize=700, ysize=800

;increasing the xmargin so it is easier to see the labels
tplot_options, 'xmargin', [18,18] ;18 characters on left side, 12 on right
tplot_options, 'ymargin', [8,4]   ;8 characters on the bottom, 4 on the top

;-------------------------------------------------


;basic plot for comparision
tplot,['sta_SWEA_en','sta_SWEA_mom_flux']


print,'  This first plot is the default, for reference. '
print,'Type ".c" to continue crib examples.'
stop


;To create an interval with a different background color for a given
;time range, use the OPTIONS command, and set an option called
;'fill_time_intv', e.g.
print,'Add a solid background color, using options, for the flux variable'
options, 'sta_SWEA_mom_flux', 'fill_time_intv', $
         {time:['2008-03-23/02:00','2008-03-23/04:00'], color:2}

tplot
print,'Type ".c" to continue'
stop

;Multiple time intervals can be marked, using a 2Xntimes array input,
;multiple colors are optional:
print,'Add different intervals with different colors, using options, for the flux variable'
t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
c1 = 'rgb' ;you can use string color valuse in addition to absolute numbers 

options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t1, color:c1}

tplot
print,'Type ".c" to continue'
stop

;Some other options for the 'polyfill' routine can be used, including
;line_fill (parallel lines instead of solid colors), linestyle, thick,
;and orientation for the line_fill options. Here set the
;line_fill, and orientation for the energy spectrum. 
print, 'The POLYFILL solid color option does not work well for the energy '
print, 'spectrum, set {line_fill:1,orientation:45} to use angled '
print, 'parallel lines and not solid colors'
;2Xn_times intervals
t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
c1 = 'rgb' ;you can use string color values in addition to absolute numbers 

options, 'sta_SWEA_en', 'fill_time_intv', $
         {time:t1, color:c1, line_fill:1, orientation:45.0}

tplot
print,'Type ".c" to continue'
stop

; You can also pass in for different options for different
; intervals. Here set three intervals on the
; flux variable, three different line orientations, all
; slightly overlapped
print, 'You can also pass in an array of polyopt structures, for different'
print, 'options for different intervals. Here set three intervals on the'
print, 'flux variable, three different line orientations, all slightly overlapped'

t2 = '2008-03-23/'+[['02:00','06:00'],['05:00','09:00'],['8:24','12:00']]
c2 = [6, 2, 2]
l2 = 1 ;lines for all intervals
o2 = [0.0, 45.0, 135.0] ;3 different orientations
options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t2, color:c2, line_fill:l2, orientation:o2}

tplot
print,'Type ".c" to continue'
stop

print, 'set line_fill = 0 for the solid color, only special here this is not a POLYFILL default'
print, 'so now solid color for the first interval'
l2 = [0, 1, 1]
options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t2, color:c2, line_fill:l2, orientation:o2}

tplot
print,'Type ".c" to continue'
stop

print, 'Cross-hatch? use the same time interval, with different orientations, for the energy spectrum'
t3 = '2008-03-23/'+[['02:00','06:00'],['02:00','06:00']]
c3 = [3, 3]

;replicate will replicate the structures
options, 'sta_SWEA_en', 'fill_time_intv', {time:t3, color:c3, line_fill:1, orientation:[45.0, 135.0]}

tplot
print,'Type ".c" to continue'
stop

;For some reason, there is no "delete" keyword in options.pro, so to
;delete an option, pass in an undefine variable (no kidding)
print, 'For some reason, there is no "delete" keyword in options.pro, '
print, 'so delete the options, by passing in an undefined variable (no kidding)'

options, 'sta_SWEA_en', 'fill_time_intv', variable_not_defined
options, 'sta_SWEA_mom_flux', 'fill_time_intv', variable_not_defined
tplot

print, 'Done'

end
