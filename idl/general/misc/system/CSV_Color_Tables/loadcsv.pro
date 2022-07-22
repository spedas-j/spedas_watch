;+
;PROCEDURE:   loadcsv
;PURPOSE:
;  This is a wrapper/translator for loadcsvcolorbar that loads a CSV color table.
;  It works the same way that 'loadct2' does.  Restrictions are imposed that make
;  this routine compatible with tplot:
;
;    (1) Only eight fixed colors are allowed.  These are loaded into the first
;        seven color indices plus the last, with black = 0 and white = 255 (same
;        as loadct2).  Missing are the gray25, gray50, gray75, brown, and pink.
;        With this change, it is not necessary to manage the top and bottom
;        colors.  Use 'get_qualcolors' to access the fixed color names and indices.
;
;    (2) To distinguish the CSV tables from the traditional loadct2 tables, 1000
;        is added to the CSV table number.  So 78 becomes 1078, etc.  When tplot 
;        sees a color table >= 1000, it knows it's a CSV table and uses this
;        routine instead of loadct2.
;
;    (3) Only table numbers are allowed.  See qualcolors documentation to find 
;        out how to define a new table.
;
;    (4) The qualcolors structure is now initialized by this routine and stored
;        in a common block, which 'loadcsvcolorbar2' uses.  The stand-alone config
;        file 'qualcolors' is ignored, so changes there will have no effect.
;        You can get a copy of the qualcolors structure with 'get_qualcolors'.
;
;    (5) !p.color and !p.background are no longer set by default.  Use keywords
;        BLACKBACK and WHITEBACK to choose a black or white background.  Also,
;        see 'revvid', which swaps the foreground and background colors.
;
;  Using 'loadcsv' has the following advantages:
;
;    (1) No need to manage qualcolors, paths, or system variables.  You simply
;        use 'loadcsv' the same way you use 'loadct2'.
;
;    (2) 'loadcsv' and 'loadct2' are aware of each other, so both can be used in
;        the same session whenever you like, and tplot does not get confused.
;
;    (3) The 'tplot' interface is greatly simplified.  No need to manage the top
;        and bottom colors when switching between CSV tables and the standard 
;        tplot tables.  Color tables can be specified on a panel-by-panel basis, 
;        with standard tables interspersed with CSV tables:
;
;          options, varname, 'color_table', N
;          options, varname, 'reverse_color_table', {0|1}
;
;        with N < 1000 for standard tables and N >= 1000 for CSV tables.  As usual,
;        varname can be an array of tplot variable names or indices to affect
;        multiple panels with one command.  Variable names can contain wildcards
;        for the same purpose.
;
;  If you are already using the original qualcolors and 'loadcsvcolortable', and
;  you're happy with how that works, you can keep doing things that way.  This
;  routine will not interfere.
;
;USAGE:
;  loadcsv, colortbl
;
;INPUTS:
;       colortbl:    CSV table number + 1000.  Don't forget to add 1000!
;                    If this input is missing, then keyword CATALOG is set.
;
;KEYWORDS:
;       RESET:       Reset the qualcolors structure and return.  Does not 
;                    load a color table.  To initialize the qualcolors 
;                    structure without doing anything else:
;
;                      loadcsv, 0, /reset
;
;       PREVIOUS_CT: Named variable to hold the previous color table number.
;                    Tplot needs this to swap color tables on the fly.
;
;       BLACKBACK:   Set !p.color = white ; !p.background = black
;                    Default is to leave these system variables unchanged.
;
;       WHITEBACK:   Set !p.color = black ; !p.backgorund = white
;                    Default is to leave these system variables unchanged.
;
;       CATALOG:     Display an image of the CSV color tables and return.
;                    Does not load a color table.
;
;       Also passes all keywords accepted by loadcsvcolorbar2.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-21 10:45:20 -0700 (Thu, 21 Jul 2022) $
; $LastChangedRevision: 30951 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/CSV_Color_Tables/loadcsv.pro $
;
;CSV color table code: Mike Chaffin
;Tplot-compatible version: David L. Mitchell
;-
pro loadcsv, colortbl, reset=reset, previous_ct=previous_ct, catalog=catalog, _EXTRA = ex

  @colors_com  ; allows loadcsv to communicate with loadct2
  common qualcolors_com, qualcolors

; Put up an image of the CSV color tables

  if (n_elements(colortbl) eq 0) then catalog = 1

  if keyword_set(catalog) then begin
    wnum = !d.window
    colortabledir = file_dirname(file_which('loadcsvcolorbar2.pro'))+"/"
    read_png, colortabledir + 'all_idl_tables_sm.png', img
    sz = size(img)
    win, /free, /sec, xsize=sz[2], ysize=sz[3], dx=10, dy=-10
    tv, img, /true
    wset, wnum
    return
  endif

; Define a tplot-compatible version of the qualcolors structure

  if ((size(qualcolors,/type) ne 8) or keyword_set(reset)) then begin
    qualcolors = {black      : 0, $
                  purple     : 1, $ 
                  blue       : 2, $
                  green      : 3, $ 
                  yellow     : 4, $
                  orange     : 5, $
                  red        : 6, $
                  white      : !d.table_size-1, $
                  nqual      : 8, $
                  bottom_c   : 7, $
                  top_c      : !d.table_size-2, $
                  colornames : ['black','purple','blue','green','yellow','orange','red','white'], $
                  qi         : [  0,   1,   2,   3,   4,   5,   6, !d.table_size-1 ], $ 
                  qr         : [  0, 152,  55,  77, 255, 255, 228, 255 ], $
                  qg         : [  0,  78, 126, 175, 255, 127,  26, 255 ], $
                  qb         : [  0, 163, 184,  74,  51,   0,  28, 255 ], $
                  colorindx  : -1, $
                  colortbl   : ''   }
    if keyword_set(reset) then return
  endif

; Make sure colortbl is reasonable

  csize = size(colortbl,/type)
  if ((csize lt 1) or (csize gt 5)) then begin
    print,"You must specify a CSV table number."
    return
  endif
  ctab = fix(colortbl[0])
  if (ctab lt 1000) then begin
    print,"You must add 1000 to the CSV table number."
    return
  endif

; Load the CSV table

  qualcolors.colorindx = ctab                ; external table number for tplot
  ctab -= 1000                               ; internal table number for loadcsvcolorbar2
  loadcsvcolorbar2, ctab, _EXTRA = ex
  qualcolors.colortbl = file_basename(ctab)  ; corresponding filename

; Tell tplot and loadct2 what happened

  ctab = qualcolors.colorindx
  if (n_elements(color_table) eq 0) then previous_ct = ctab else previous_ct = color_table
  color_table = ctab

end
