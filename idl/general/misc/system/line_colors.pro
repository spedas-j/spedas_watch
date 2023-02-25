;+
;PROCEDURE line_colors
;   Alters one or more of the fixed colors (indices 0-6 and 255) without changing
;   the color table.  This includes the line colors (1-6) and the background (0) 
;   and foreground (255) colors.
;
;INPUTS:
;   lines : Can take one of two forms:
;
;   (1) Integer array of 24 (3x8) RGB colors: [[R,G,B], [R,G,B], ...] that defines
;       the RGB values of the first 7 colors (0-6) and the last (255).
;
;   (2) Integer that selects a predefined color scheme:
;
;          0  : primary colors (black, magenta, blue, cyan, green, yellow, red, white)
;         1-4 : four different schemes suitable for colorblind vision
;          5  : primary colors, except orange replaces yellow
;          6  : Chaffin's CSV line colors, suitable for colorblind vision
;
;    To set custom line colors for any tplot panel:
;
;       options, varname, 'line_colors', lines
;
;    where the value of lines is one of the formats above.
;
;KEYWORDS:
;    COLOR_NAMES:  String array of 8 line color names.  You must use line color
;                  names recognized by spd_get_color().  RGB values for unrecognized
;                  color names are set to zero.  Not recommended, because named 
;                  colors are approximated by the nearest RGB neighbors in the 
;                  currently loaded color table.  This can work OK for rainbow color
;                  tables, but for tables that primarily encode intensity, the 
;                  actual colors can be quite different from the requested ones.
;                  Included for backward compatibility.
;
;    MYCOLORS:     A structure defining up to 8 custom colors.  These are fixed
;                  colors used to draw colored lines (1-6) and to define the
;                  background (0) and foreground (255) colors.
;
;                     { ind    : up to 8 integers (0-6 or 255)              , $
;                       rgb    : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;                  The indicies (ind) specified in MYCOLORS will replace one or
;                  more of the default colors.  You are not allowed to change
;                  color indices 7-254, because those are reserved for the
;                  color table.  Indices 0 and 255 allow you to define custom
;                  background and foreground colors.  For example, the following
;                  chooses color scheme 5, but sets the background color to light
;                  gray with a black foreground (pen) color:
;
;                     line_colors, 5, mycolors={ind:255, rgb:[211,211,211]}
;                     !p.color = 0
;                     !p.background = 255
;
;    GRAYBKG:      Set color index 255 to gray [211,211,211] instead of white.
;                  See keyword MYCOLORS for a general method of setting any line 
;                  color to any RGB value.  For example, GRAYBKG=1 is equivalent 
;                  to MYCOLORS={ind:255, rgb:[211,211,211]}.
;
;                  To actually use this color for the background, you must set 
;                  !p.background=255 (normally combined with !p.color=0).
;
;    PREVIOUS_LINES: Named variable to hold the previous line colors.
;                 Tplot needs this to swap line colors on the fly.
;
;SEE ALSO:
;    get_line_colors() : Works like this routine, but returns a 24 element array
;                  instead of asserting the new line colors.  Allows you to define
;                  a custom set of line colors in a format that you can use with
;                  tplot options.
;    initct :      Loads a color table without changing the line colors, except by
;                  keyword.
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-02-24 15:44:01 -0800 (Fri, 24 Feb 2023) $
; $LastChangedRevision: 31516 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/line_colors.pro $
;
;Created by David Mitchell;  February 2023
;-

pro line_colors, lines, color_names=color_names, mycolors=mycolors, graybkg=graybkg, $
                        previous_lines=previous_lines

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com

  case (size(lines,/type)) of
     0   : begin
             print,"You must specify one or more line colors."
             return
           end
     7   : color_names = lines
     8   : mycolors = lines
    else : line_clrs = lines
  endcase

  tvlct,r,g,b,/get

; Initialize with the current or default line colors

  indx = [indgen(7), 255]

  if (n_elements(line_colors) ne 24) then begin
    r[indx] = [0,1,0,0,0,1,1,1]*255
    g[indx] = [0,0,0,1,1,1,0,1]*255
    b[indx] = [0,1,1,1,0,0,0,1]*255
    line_colors = fix([[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0],[255,255,255]])
  endif else begin
    r[indx] = line_colors[0,*]
    g[indx] = line_colors[1,*]
    b[indx] = line_colors[2,*]
  endelse

  previous_lines = line_colors

; Assert the new line colors

  new_lines = get_line_colors(line_clrs, color_names=color_names, mycolors=mycolors, graybkg=graybkg)

  r[indx] = new_lines[0,*]
  g[indx] = new_lines[1,*]
  b[indx] = new_lines[2,*]

  lines = new_lines
  line_colors = new_lines

  tvlct,r,g,b

  r_curr = r  ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b

end
