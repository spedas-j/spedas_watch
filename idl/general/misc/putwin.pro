;+
;PROCEDURE:   putwin
;PURPOSE:
;  Creates a window and places it in a specified monitor, with
;  offsets relative to the screen edges. This is a user-friendly
;  version of WINDOW that is designed for a multiple monitor setup.
;
;  This routine is hardware dependent and will not work properly until
;  it is configured for your monitor(s) and their arrangement, which
;  determine how IDL positions graphics windows.  See keyword CONFIG.
;
;  If no configuration is defined, putwin behaves exactly like window.
;  This allows the routine to be used in public code, where the user 
;  may not know about or does not want to use its functionality.
;
;USAGE:
;  putwin, wnum, [KEYWORD=value, ...]
;
;INPUTS:
;       wnum:      Window number.  Can be an integer from 0 to 31.
;                  Otherwise the next free widow number >= 32 is
;                  used.
;
;KEYWORDS:
;       Accepts all keywords for WINDOW.  In addition, the following
;       are defined:
;
;       CONFIG:    Can take one of three forms: integer, integer array,
;                  or string, corresponding to different methods of 
;                  determining the monitor configuration.
;
;                  Integer (pre-defined configurations):
;
;                    -1 = disabled: putwin acts like window (default)
;                     0 = 1440x878 only
;                     1 = 1440x878 (below), 5120x1440 (above)
;                     2 = 1440x878 (below), 2560x1440 (left, right)
;                     3 = 1440x878 (below), 2560x1440 (above)
;
;                  Integer Array (user-defined configuration):
;
;                     4 x N integer array for N monitors.  For each 
;                     monitor, specify the coordinates of the lower
;                     left corner (x0, y0) and the screen dimensions
;                     (xdim, ydim):
;
;                       cfg[0:3,i] = [x0, y0, xdim, ydim]
;
;                  String (automatically defined configuration):
;
;                     If set to 'automatic' (minimum matching), get
;                     the configuration using IDLsysMonitorInfo.
;                     (Not thoroughly tested.)
;
;                  In any case, the configuration is defined and stored in
;                  a common block, but no window is created.
;
;       STAT:      Output the current monitor configuration.
;
;       MONITOR:   Put window in this monitor.
;                  
;                  See keyword CONFIG.  Default is 1 if there is at
;                  least one external monitor and 0 otherwise.
;
;       DX:        Horizontal offset from CORNER (pixels).
;                  Replaces XPOS.  Default = 0.
;
;       DY:        Vertical offset from CORNER (pixels).
;                  Replaces YPOS.  Default = 0.
;
;                  The standard WINDOW procedure does not account for
;                  the window title bar width, so that widows placed
;                  along the bottom of a monitor are clipped.  This
;                  procedure fixes that issue.
;
;       CORNER:    DX and DY are measured from this corner of the
;                  specified monitor.
;
;                    0 = top left (default)
;                    1 = top right
;                    2 = bottom left
;                    3 = bottom right
;
;       SCALE:     Scale factor for setting the window size.  Only
;                  applies when XSIZE and/or YSIZE are set explicitly 
;                  (via keyword) or implictly (via swe_snap_layout).
;                  Default = 1.
;
;                  If the combination of XSIZE, YSIZE, SCALE, DX and
;                  DY cause the window to extend beyond the monitor,
;                  first DX and DY, then XSIZE and YSIZE are reduced
;                  until the window does fit.
;
;       FULL:      If set, make a full-screen window in MONITOR.
;                  (Ignore XSIZE, YSIZE, DX, DY, and CORNER.)
;
;       KEY:       A structure containing any of the above keywords
;                  plus XSIZE and YSIZE:
;
;                    {KEYWORD:value, KEYWORD:value, ...}
;
;                  Keywords set using this mechanism take precedence.
;                  All other keywords for WINDOW must be passed  
;                  separately in the usual way.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-07-18 14:50:15 -0700 (Sat, 18 Jul 2020) $
; $LastChangedRevision: 28909 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, wnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, _extra=extra

  common putwincom, windex, maxmon, mgeom

; Silently act like window until CONFIG is set.

  if (size(windex,/type) eq 0) then windex = -1

; Output the current monitor configuration.

  if keyword_set(stat) then begin
    if (windex ge 0) then begin
      print,"Monitor configuration: ",strtrim(string(windex),2)
      for i=maxmon,0,-1 do print, i, mgeom[2:3,i], format='(2x,i2," :",1x,i5," x ",i5)'
      print,""
    endif else print,"Monitor configuration undefined -> putwin acts like window"
    return
  endif

; Alternate method of setting PUTWIN keywords.  Except for XSIZE and YSIZE,
; all keywords for WINDOW must be passed separately in the usual way.

  if (size(key,/type) eq 8) then begin
    str_element, key, 'CONFIG', value, success=ok
    if (ok) then config = value
    str_element, key, 'MONITOR', value, success=ok
    if (ok) then monitor = value
    str_element, key, 'DX', value, success=ok
    if (ok) then dx = value
    str_element, key, 'DY', value, success=ok
    if (ok) then dy = value
    str_element, key, 'CORNER', value, success=ok
    if (ok) then corner = value
    str_element, key, 'SCALE', value, success=ok
    if (ok) then scale = value
    str_element, key, 'FULL', value, success=ok
    if (ok) then full = value
    str_element, key, 'XSIZE', value, success=ok
    if (ok) then xsize = value
    str_element, key, 'YSIZE', value, success=ok
    if (ok) then ysize = value
  endif

; Define multiple monitor configuration

  sz = size(config)

  if ((sz[0] eq 2) and (sz[1] eq 4)) then begin
    mgeom = fix(config)
    maxmon = sz[2] - 1
    windex = 4
    swe_snap_layout, 0
    print,"Monitor configuration: user defined"
    for i=maxmon,0,-1 do print, i, mgeom[2:3,i], format='(2x,i2," :",1x,i5," x ",i5)'
    print,""
    return
  endif

  if (size(config,/type) eq 7) then begin
    if strmatch('automatic', config[0]+'*', /fold) then begin
      oInfo = obj_new('IDLsysMonitorInfo')
        numMons = oInfo->GetNumberOfMonitors()
        rects = oInfo->GetRectangles()
        primaryIndex = oInfo->GetPrimaryMonitorIndex()
      obj_destroy, oInfo

      mgeom = rects
      mgeom[1,*] = rects[3,primaryIndex] - rects[3,*] - rects[1,*]
      maxmon = numMons - 1

      windex = 5
      swe_snap_layout, 0
      print,"Monitor configuration: automatically generated"
      for i=maxmon,0,-1 do print, i, mgeom[2:3,i], format='(2x,i2," :",1x,i5," x ",i5)'
      print,""
    endif else print, "Monitor configuration not recognized: ", config[0]
    return
  endif

  if (size(config,/type) gt 0) then begin
    windex = fix(config[0])

    if ((windex lt -1) or (windex gt 3)) then begin
      print,"Configuration index must be one of:"
      print,"  -1 = disabled -> putwin acts like window"
      print,"   0 = 1440x878 only"
      print,"   1 = 1440x878 (below), 5120x1440 (above)"
      print,"   2 = 1440x878 (below), 2560x1440 (left, right)"
      print,"   3 = 1440x878 (below), 2560x1440 (above)"
      print,""
      windex = -1
      return
    endif

    mgeom = intarr(4,3)  ; [x0, y0, xdim, ydim] for up to 3 monitors (so far)

    case windex of
       0   : begin
               mgeom[*,0] = [   0,    0, 1440,  878]  ; laptop
               maxmon = 0
               swe_snap_layout, 0
             end
       1   : begin
               mgeom[*,0] = [1847, -900, 1440,  878]  ; laptop
               mgeom[*,1] = [   0,    0, 5120, 1440]  ; double-wide external above
               maxmon = 1
               swe_snap_layout, 1
             end
       2   : begin
               mgeom[*,0] = [1847, -900, 1440,  878]  ; laptop
               mgeom[*,1] = [   0,    0, 2560, 1440]  ; external left
               mgeom[*,2] = [2560,    0, 2560, 1440]  ; external right
               maxmon = 2
               swe_snap_layout, 2
             end
       3   : begin
               mgeom[*,0] = [1847, -900, 1440,  878]  ; laptop
               mgeom[*,1] = [   0,    0, 2560, 1440]  ; external above
               maxmon = 1
               swe_snap_layout, 3
             end
      else : swe_snap_layout = 0
    endcase

    print,"Monitor configuration: ",format='(a,$)'
    case windex of
     -1 : print,'disabled -> putwin acts like window'
      0 : print,'1440x878 only'
      1 : print,'1440x878 (below), 5120x1440 (above)'
      2 : print,'1440x878 (below), 2560x1440 (left, right)'
      3 : print,'1440x878 (below), 2560x1440 (above)'
    endcase
    print,""

    return
  endif

; If no configuration is set, then just pass everything to window

  if (windex eq -1) then begin
    if (size(scale,/type) gt 0) then begin
      if (size(xsize,/type) gt 0) then xsize *= scale
      if (size(ysize,/type) gt 0) then ysize *= scale
    endif
    if (size(wnum,/type) gt 0) then window, wnum, xsize=xsize, ysize=ysize, _extra=extra $
                               else window, xsize=xsize, ysize=ysize, _extra=extra
    return
  endif

; Window geometry

  if (n_elements(wnum) eq 0) then wnum = -1 else wnum = fix(wnum[0])
  if (n_elements(monitor) eq 0) then monitor = 1 else monitor = fix(monitor[0])
  monitor = (monitor > 0) < maxmon
  if (n_elements(xsize) eq 0) then xsize = 800 else xsize = fix(xsize[0])
  if (n_elements(ysize) eq 0) then ysize = 500 else ysize = fix(ysize[0])
  if (n_elements(scale) eq 0) then scale = 1.
  xsize = fix(float(xsize)*scale)
  ysize = fix(float(ysize)*scale)
  if (n_elements(dx) eq 0) then dx = 0 else dx = fix(dx[0])
  if (n_elements(dy) eq 0) then dy = 0 else dy = fix(dy[0])
  if (n_elements(corner) eq 0) then corner = 0 else corner = fix(corner[0])
  corner = abs(corner) mod 4

  tbar = 22                         ; title bar width
  xoff = mgeom[0, monitor]          ; horizontal offset
  yoff = mgeom[1, monitor]          ; vertical offset
  xdim = mgeom[2, monitor]          ; horizontal dimension
  ydim = mgeom[3, monitor]          ; vertical dimension

; Make sure window will fit

  if keyword_set(full) then begin
    xsize = xdim
    ysize = ydim
    dx = 0
    dy = 0
    corner = 0
  endif

; First try to move the window

  dx = dx < ((xdim - xsize) > 0)
  dy = dy < ((ydim - tbar - ysize) > 0)

; If that's not enough, shrink the window as well

  xsize = xsize < (xdim - dx)
  ysize = ysize < (ydim - tbar - dy)

; Place window relative to corner

  case corner of
    0 : begin  ; top left
          x0 = xoff + dx
          y0 = yoff + (ydim - ysize) - dy
        end
    1 : begin  ; top right
          x0 = xoff + (xdim - xsize) - dx
          y0 = yoff + (ydim - ysize) - dy
        end
    2 : begin  ; bottom left
          x0 = xoff + dx
          y0 = yoff + tbar + dy
        end
    3 : begin  ; bottom right
          x0 = xoff + (xdim - xsize) - dx
          y0 = yoff + tbar + dy
        end
  endcase

  if ((wnum lt 0) or (wnum gt 31)) then begin
    window, /free, xpos=x0, ypos=y0, xsize=xsize, ysize=ysize, _extra=extra
    wnum = !d.window
  endif else begin
    window, wnum, xpos=x0, ypos=y0, xsize=xsize, ysize=ysize, _extra=extra
  endelse

  return

end
