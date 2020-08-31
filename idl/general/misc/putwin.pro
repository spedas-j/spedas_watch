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
;  putwin [, wnum [, monitor]] [,KEYWORD=value, ...]
;
;INPUTS:
;       wnum:      Window number.  Can be an integer from 0 to 31.
;                  Default: next free widow number > 31.
;
;       monitor:   Monitor number.  Can also be set by keyword (see
;                  below), but this method takes precedence.  Only the
;                  second input will be interpreted as a monitor number.
;                  If there's only one input, it's interpreted as the 
;                  window number.
;
;                  If there is more than one monitor, IDL identifies a
;                  "primary monitor", where graphics windows appear by
;                  default.  This routine also defaults to the primary
;                  monitor.
;
;KEYWORDS:
;       Accepts all keywords for WINDOW.  In addition, the following
;       are defined:
;
;       CONFIG:    Can take one of two forms: integer or integer array.
;
;                  Integer (automatic configuration):
;
;                     0 = disabled: putwin acts like window (default)
;                     1 = automatic
;                     2 = automatic with double-wide (5K) external
;                         merged into a single logical monitor
;                         (only guaranteed to work for the author)
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
;                  This routine automatically detects the primary
;                  primary monitor for both forms of CONFIG.
;
;                  In either case, the configuration is defined and stored
;                  in a common block, but no window is created.
;
;       TBAR:      Title bar width in pixels.  Default = 22.
;
;                  The standard WINDOW procedure does not account for
;                  the window title bar width, so that widows placed
;                  along the bottom of a monitor are clipped.  This
;                  procedure fixes that issue.
;
;                  Window positioning will not be precise unless this
;                  is set properly.  IDL does not have access to this
;                  piece of information, so you'll have to figure it
;                  out.  This value is persistent for subsequent calls 
;                  to putwin, so you only need to set it once.
;
;       STAT:      Output the current monitor configuration.  When 
;                  this keyword is set, CONFIG will return the current 
;                  monitor array, the primary monitor index, and the 
;                  title bar width.
;
;       SHOW:      Same as STAT, except in addition a small window is
;                  placed in each monitor for 2 sec to identify
;                  the monitor numbers.
;
;       MONITOR:   Put window in this monitor.
;
;                  Default is the primary monitor (see CONFIG).
;
;       DX:        Horizontal offset from CORNER (pixels).
;                  Replaces XPOS.  Default = 0.
;
;       DY:        Vertical offset from CORNER (pixels).
;                  Replaces YPOS.  Default = 0.
;
;                  Note: XPOS and YPOS only work if CONFIG = 0.  They
;                  refer to position on a rectangular "super monitor"
;                  that encompasses all physical monitors.  This super
;                  monitor will typically have regions that are out of
;                  the bounds of the physical monitors, so windows can
;                  be placed in regions that cannot be seen.
;
;       CORNER:    DX and DY are measured from this corner:
;
;                    0 = top left (default)
;                    1 = top right
;                    2 = bottom left
;                    3 = bottom right
;
;       NORM:      Measure DX and DY in normalized coordinates (0-1)
;                  instead of pixels.
;
;       XCENTER:   Center the window in X.
;
;       YCENTER:   Center the window in Y.
;
;       CENTER:    Center the window in both X and Y.
;
;       SCALE:     Scale factor for setting the window size.  Only
;                  applies when XSIZE and/or YSIZE are set explicitly 
;                  (via keyword) or implictly (via swe_snap_layout).
;                  Default = 1.
;
;       NOFIT:     If the combination of XSIZE, YSIZE, SCALE, DX and
;                  DY cause the window to extend beyond the monitor,
;                  first DX and DY, then XSIZE and YSIZE are reduced
;                  until the window does fit.  Set NOFIT to disable
;                  this behavior and create the window as requested.
;
;       XFULL:     Make the window full-screen in X.
;                  (Ignore, XSIZE and DX.)
;
;       YFULL:     Make the window full-screen in Y.
;                  (Ignore, YSIZE and DY.)
;
;       FULL:      If set, make a full-screen window in MONITOR.
;                  (Ignore XSIZE, YSIZE, DX, DY.)
;
;       ASPECT:    Aspect ratio: XSIZE/YSIZE.  If one dimension is
;                  set with XSIZE, YSIZE, XFULL, or YFULL, this
;                  keyword sets the other dimension.
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
; $LastChangedDate: 2020-08-30 17:08:25 -0700 (Sun, 30 Aug 2020) $
; $LastChangedRevision: 29094 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, wnum, mnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, _extra=extra

  @putwin_common

; Silently act like window until CONFIG is set.

  if (size(windex,/type) eq 0) then windex = -1

; Output the current monitor configuration.

  if (keyword_set(stat) or keyword_set(show)) then begin
    if (windex ge 0) then begin
      print,"Monitor configuration:"
      j = sort(mgeom[1,0:maxmon])
      for i=maxmon,0,-1 do begin
        print, j[i], mgeom[2:3,j[i]], format='(2x,i2," : ",i4," x ",i4,$)'
        if (i eq primarymon) then print," (primary)" else print,""
      endfor
      print,""

      if keyword_set(show) then begin
        j = -1
        for i=0,maxmon do begin
          putwin, 32, i, xsize=100, ysize=100, /center
          xyouts,0.5,0.35,strtrim(string(i),2),/norm,align=0.5,charsize=4,charthick=3,color=6
          if (i eq primarymon) then $
            xyouts,0.5,0.1,"(primary)",/norm,align=0.5,charsize=1.5,charthick=1,color=6
          j = [j, !d.window]
        endfor
        j = j[1:*]
        wait, 2
        for i=0,maxmon do wdelete, j[i]
      endif

      config = {config:mgeom, primarymon:primarymon, tbar:tbar}
    endif else print,"Monitor configuration undefined -> putwin acts like window"
    return
  endif

; Window title bar width from keyword

  if (size(tbar2,/type) gt 0) then tbar = fix(tbar2[0])

; Alternate method of setting PUTWIN keywords.  Except for XSIZE and YSIZE,
; all keywords for WINDOW must be passed separately in the usual way.

  if (size(key,/type) eq 8) then begin
    str_element, key, 'CONFIG', value, success=ok
    if (ok) then config = value
    str_element, key, 'STAT', value, success=ok
    if (ok) then stat = value
    str_element, key, 'MONITOR', value, success=ok
    if (ok) then monitor = value
    str_element, key, 'DX', value, success=ok
    if (ok) then dx = value
    str_element, key, 'DY', value, success=ok
    if (ok) then dy = value
    str_element, key, 'NORM', value, success=ok
    if (ok) then norm = value
    str_element, key, 'CENTER', value, success=ok
    if (ok) then center = value
    str_element, key, 'XCENTER', value, success=ok
    if (ok) then xcenter = value
    str_element, key, 'YCENTER', value, success=ok
    if (ok) then ycenter = value
    str_element, key, 'CORNER', value, success=ok
    if (ok) then corner = value
    str_element, key, 'SCALE', value, success=ok
    if (ok) then scale = value
    str_element, key, 'FULL', value, success=ok
    if (ok) then full = value
    str_element, key, 'XFULL', value, success=ok
    if (ok) then xfull = value
    str_element, key, 'YFULL', value, success=ok
    if (ok) then yfull = value
    str_element, key, 'ASPECT', value, success=ok
    if (ok) then aspect = value
    str_element, key, 'XSIZE', value, success=ok
    if (ok) then xsize = value
    str_element, key, 'YSIZE', value, success=ok
    if (ok) then ysize = value
    str_element, key, 'NOFIT', value, success=ok
    if (ok) then nofit = value
    str_element, key, 'TBAR', value, success=ok
    if (ok) then tbar = value
  endif

  if (size(tbar,/type) eq 0) then tbar = 22
  if (size(mnum,/type) gt 0) then monitor = fix(mnum[0])

; Define multiple monitor configuration

  oInfo = obj_new('IDLsysMonitorInfo')
    numMons = oInfo->GetNumberOfMonitors()
    rects = oInfo->GetRectangles()
    primon = oInfo->GetPrimaryMonitorIndex()
  obj_destroy, oInfo

  sz = size(config)

  if ((sz[0] eq 2) and (sz[1] eq 4)) then begin
    mgeom = fix(config)
    maxmon = sz[2] - 1
    windex = 4  ; user-defined
    swe_snap_layout, 0
    primarymon = primon
    putwin, /stat
    return
  endif

  if (max(sz) gt 0) then begin
    cfg = fix(config[0])
    primarymon = primon

    if (cfg eq 0) then begin
      swe_snap_layout, 0
      windex = -1
      putwin, /stat
      return
    endif

    mgeom = rects
    mgeom[1,*] = rects[3,primarymon] - rects[3,*] - rects[1,*]
    maxmon = numMons - 1

    case maxmon of
       0   : windex = 0                        ; laptop only
       1   : windex = 3                        ; laptop with single external
       2   : if (cfg gt 1) then begin          ; laptop with double-wide external
               mgeom[0,1] = min(mgeom[0,1:2])
               mgeom[2,1] += mgeom[2,2]
               mgeom = mgeom[*,0:1]
               maxmon -= 1
               primarymon = 1
               windex = 1
             endif else windex = 2             ; laptop with two externals
      else : windex = 5                        ; unknown configuration
    endcase
    swe_snap_layout, windex
    putwin, /stat
    return
  endif

; If no configuration is set, then just pass everything to WINDOW

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
  if (n_elements(monitor) eq 0) then monitor = primarymon else monitor = fix(monitor[0])
  monitor = (monitor > 0) < maxmon
  if (size(aspect,/type) gt 0) then begin
    if (n_elements(xsize) gt 0) then begin
      ysize = float(xsize[0])/aspect
    endif else begin
      if (n_elements(ysize) gt 0) then xsize = float(ysize[0])*aspect
    endelse
  endif
  if (n_elements(xsize) eq 0) then xsize = 800
  if (n_elements(ysize) eq 0) then ysize = 500
  if (n_elements(scale) eq 0) then scale = 1.
  xsize = fix(float(xsize[0])*scale)
  ysize = fix(float(ysize[0])*scale)
  if (n_elements(dx) eq 0) then dx = 0
  if (n_elements(dy) eq 0) then dy = 0
  if keyword_set(norm) then begin
    dx *= mgeom[2, monitor]
    dy *= mgeom[3, monitor]
  endif
  if keyword_set(center) then begin
    xcenter = 1
    ycenter = 1
  endif
  if keyword_set(xcenter) then dx = (mgeom[2, monitor] - xsize)/2
  if keyword_set(ycenter) then dy = (mgeom[3, monitor] - ysize)/2
  dx = fix(dx[0])
  dy = fix(dy[0])
  if (n_elements(corner) eq 0) then corner = 0 else corner = fix(corner[0])
  corner = abs(corner) mod 4

  xoff = mgeom[0, monitor]          ; horizontal offset
  yoff = mgeom[1, monitor]          ; vertical offset
  xdim = mgeom[2, monitor]          ; horizontal dimension
  ydim = mgeom[3, monitor]          ; vertical dimension

  if keyword_set(full) then begin
    xfull = 1
    yfull = 1
    undefine, aspect
  endif

  if keyword_set(xfull) then begin
    xsize = xdim
    dx = 0
    if (size(aspect,/type) gt 0) then ysize = fix(float(xsize)/aspect)
  endif

  if keyword_set(yfull) then begin
    ysize = ydim - tbar
    dy = 0
    if (size(aspect,/type) gt 0) then xsize = fix(float(ysize)*aspect)
  endif

; Make sure window will fit by moving, then shrinking if necessary

  if ~keyword_set(nofit) then begin
    dx = dx < ((xdim - xsize) > 0)
    dy = dy < ((ydim - tbar - ysize) > 0)
    xsize = xsize < (xdim - dx)
    ysize = ysize < (ydim - tbar - dy)
  endif

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
