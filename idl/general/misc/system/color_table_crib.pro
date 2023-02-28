;+
;CRIB for managing color tables and line colors and taking control of colors in tplot
;
;ROUTINES:
;   initct : Wrapper for loadct2 and loadcsv.  Works the same way as loadct2 and loadcsv,
;            but provides access to both sets of color tables (more than 160 in all!).
;            Provides keywords for setting line colors.  The previous routines still exist
;            and can still be called as before, so there's no need to rewrite any code
;            unless you want to.
;   showct : Display the current color table or any color table with any line color scheme.
;   revvid : swaps the values of !p.background and !p.color
;   line_colors : Choose one of ten predefined line color schemes, or define a completely
;                 custom scheme.
;   get_line_colors : Returns a 3x8 array of the current line colors [[R,G,B],[R,G,B], ...].
;                     Can also return the 3x8 array for any line color scheme.
;
;   See the headers of these routines for more details.
;
;   The CSV catalog has table numbers from 0 to 118.  This range overlaps the legacy color
;   table range, so we need some way to separate them.  I chose to add 1000 to the CSV table
;   numbers, so CSV table 78 becomes 1078, etc.
;
;   Tplot has been modified to use initct and line_colors, so you can set custom color tables
;   and line color schemes for individual tplot variables using options.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-02-26 18:36:44 -0800 (Sun, 26 Feb 2023) $
; $LastChangedRevision: 31536 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/color_table_crib.pro $
;
; Created by David Mitchell;  February 2023
;-

pro color_table_crib

  print, "This crib is not intended as a procedure.  Read the contents instead."
  return

; Place the following lines in your idl_startup.pro to initialize your device and color
; table.  Of course, you can choose any of >100 color tables (reversed if desired), any of
; ten predefined line color schemes, or completely custom line colors.  This example
; sets a dark background, but many people prefer a light background.

device,decompose=0,retain=2   ; specific to MacOS (settings for other OS's might be different)
initct,1074,line=5,/rev,/sup  ; define color table and fixed line colors (suppress error message)
!p.background = 0             ; use tplot fixed color for background (0 = black by default)
!p.color = 255                ; use tplot fixed color for foreground (255 = white by default)

; Set a new color table and line colors at the command line.

initct, 43, line=5

; Change line colors without otherwise modifying the color table.

line_colors, 6

; Swap !p.background and !p.color

revvid

; Use gray instead of white for the background, which looks better in some situations.

revvid, /white  ; if needed
line_colors, 5, /graybkg

; Use a custom gray level for the background.

revvid, /white  ; if needed
line_colors, 5, mycolors={ind:255, rgb:[198,198,198]}

; Poke arbitrary RGB colors into indices 1 and 4 of the current line color scheme.

line_colors, mycolors={ind:[1,4], rgb:[[198,83,44],[18,211,61]]}

; Use a fancy rainbow-like CSV color table with line colors suitable for color blind people
; CSV color tables encode intensity first and color second, which is closer to how humans
; perceive colors.  Reverse the table, so that blue is low and red is high.

initct, 1074, /reverse, line=8

; See a catalog of the many CSV color tables (Note: loadcsv is not usually called directly.)
; Remember that you have to add 1000 to CSV color table numbers.

loadcsv, /catalog

; Display the current color table with an intensity plot.

showct, /i

; Display any color table with custom line colors -- DOES NOT modify the current color table.

showct, 1078, /i, line=8

; Set a custom color table and custom line colors for any tplot variable.  This allows you
; to use multiple color tables and/or line color schemes within a single multi-panel plot.

options, varname1, 'color_table', 1074
options, varname1, 'reverse_color_table', 1
options, varname1, 'line_colors', 10

options, varname2, 'color_table', 1078
options, varname2, 'reverse_color_table', 0
options, varname2, 'line_colors', 5

; Set a custom line color scheme for a tplot variable.

mylines = get_line_colors(5, /graybkg, mycolors={ind:3, rgb:[211,0,211]})
options, varname1, 'line_colors', mylines

; Disable custom color tables and line colors for a tplot variable.

options, varname1, 'color_table', -1
options, varname1, 'line_colors', -1

end ; of crib
