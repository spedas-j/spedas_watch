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
; $LastChangedDate: 2019-11-04 16:24:36 -0800 (Mon, 04 Nov 2019) $
; $LastChangedRevision: 27974 $
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

;Some other options for the 'polyfill' routine can be used also, by
;setting polyopt in the structure passed into options, here set the
;line_fill, and orientation for the energy spectrum. 
print, 'The POLYFILL solid color option does not work well for the energy '
print, 'spectrum, set polyopt:{line_fill:1,orientation:45} to use angled '
print, 'parallel lines and not solid colors'
;2Xn_times intervals
t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
c1 = 'rgb' ;you can use string color values in addition to absolute numbers 

options, 'sta_SWEA_en', 'fill_time_intv', $
         {time:t1, color:c1, polyopt:{line_fill:1,orientation:45.0}}

tplot
print,'Type ".c" to continue'
stop

; You can also pass in an array of polyopt structures, for different
; options for different intervals. Here set three intervals on the
; flux variable, three different line orientations, all
; slightly overlapped
print, 'You can also pass in an array of polyopt structures, for different'
print, 'options for different intervals. Here set three intervals on the'
print, 'flux variable, three different line orientations, all slightly overlapped'

t2 = '2008-03-23/'+[['02:00','06:00'],['05:00','09:00'],['8:24','12:00']]
c2 = [6, 2, 2]
;replicate will replicate the structures
polyopt2 = replicate({line_fill:0b,orientation:0.0}, 3) ;flat red lines

polyopt2[1].line_fill = 1 & polyopt2[1].orientation = 45.0 ;lines at 45 for 2nd interval
polyopt2[2].line_fill = 1 & polyopt2[2].orientation = 135.0 ;lines at 135 for 3rd interval

options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t2, color:c2, polyopt:polyopt2}

tplot
print,'Type ".c" to continue'
stop

;set line_fill = 255 for the solid color, only special here this is not a POLYFILL default'
print, 'set line_fill = 255 for the solid color, only special here this is not a POLYFILL default'
print, 'so now solid color for the first interval'
polyopt2[0].line_fill = 255 
options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t2, color:c2, polyopt:polyopt2}

tplot
print,'Type ".c" to continue'
stop

print, 'Cross-hatch? use the same time interval, with different orientations, for the energy spectrum'
t3 = '2008-03-23/'+[['02:00','06:00'],['02:00','06:00']]
c3 = [3, 3]

;replicate will replicate the structures
polyopt3 = replicate({line_fill:0b,orientation:0.0}, 2)
polyopt3[0].line_fill = 1 & polyopt3[0].orientation = 45.0 ;lines at 45
polyopt3[1].line_fill = 1 & polyopt3[1].orientation = 135.0 ;lines at 135
options, 'sta_SWEA_en', 'fill_time_intv', {time:t3, color:c3, polyopt:polyopt3}

tplot
print, 'Done'

end
