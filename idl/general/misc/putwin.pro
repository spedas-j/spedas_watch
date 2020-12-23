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
;  putwin [, wnum [, monitor]] [, KEYWORD=value, ...]  ; normal usage
;
;  putwin, CONFIG=value [, TBAR=value]  ; initialization
;
;INPUTS:
;       wnum:      Window number.  Can be an integer from 0 to 31.
;                  Default: next free widow number > 31.
;
;                  This can also be set to a variable name, which will
;                  return the window number chosen.
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
;                  monitor.  See keywords SECONDARY and SHOW.
;
;                  This can also be set to a variable name, which will
;                  return the monitor number chosen.
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
;                     1 = automatic: get configuration by querying the
;                                    operating system
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
;                  monitor for both forms of CONFIG.
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
;                  monitor array and the primary monitor index.
;
;       SHOW:      Same as STAT, except in addition a small window is
;                  placed in each monitor for 2 sec to identify
;                  the monitor numbers, including which is primary.
;
;       MONITOR:   Put window in this monitor.
;
;                  Default is the primary monitor (see CONFIG).
;
;       SECONDARY: Put window in highest numbered non-primary monitor
;                  (usually the largest one).
;
;       DX:        Horizontal offset from left or right edge (pixels).
;                    If DX is positive, offset is from left.
;                    If DX is negative, offset is from right.
;                  Replaces XPOS.  Default = 0.
;
;       DY:        Vertical offset from top or bottom edge (pixels).
;                    If DY is positive, offset is from top.
;                    If DX is negative, offset is from bottom.
;                  Replaces YPOS.  Default = 0.
;
;                  Note: XPOS and YPOS only work if CONFIG = 0.  They
;                  refer to position on a rectangular "super monitor"
;                  that encompasses all physical monitors.  This super
;                  monitor will typically have regions that are out of
;                  the bounds of the physical monitors, so windows can
;                  be placed in regions that cannot be seen.
;
;       CORNER:    Alternate method for determining which corner to 
;                  place window.  If this keyword is set, then only the
;                  absolute values of DX and DY are used.
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
;                  until the window does fit.  If ASPECT is set, then
;                  the window is further reduced, if necessary, to 
;                  maintain the aspect ratio.  Set NOFIT to disable
;                  this behavior and create the window as requested.
;
;       XFULL:     Make the window full-screen in X.
;                  (Ignore XSIZE, DX.)
;
;       YFULL:     Make the window full-screen in Y.
;                  (Ignore YSIZE, DY.)
;
;       FULL:      If set, make a full-screen window in MONITOR.
;                  (Ignore XSIZE, YSIZE, DX, DY, SCALE, ASPECT.)
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
;                  Case folded minimum matching is used to match tag
;                  names in this structure to valid keywords.  For
;                  example:
;
;                    {f:1, m:2} is interpreted as FULL=1, MONITOR=2.
;
;                  Unrecognized or ambiguous tag names are ignored.
;
;                  Keywords set using this mechanism take precedence.
;                  All other keywords for WINDOW must be passed
;                  separately in the usual way.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-12-22 16:32:15 -0800 (Tue, 22 Dec 2020) $
; $LastChangedRevision: 29552 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, wnum, mnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  _extra=extra

  @putwin_common

; Silently act like window until CONFIG is set.

  if (size(windex,/type) eq 0) then windex = -1

; Alternate method of setting PUTWIN keywords.  Except for XSIZE and YSIZE,
; all keywords for WINDOW must be passed separately in the usual way.

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    klist = ['CONFIG','STAT','SHOW','MONITOR','SECONDARY','DX','DY','NORM', $
             'CENTER','XCENTER','YCENTER','CORNER','SCALE','FULL','XFULL', $
             'YFULL','ASPECT','XSIZE','YSIZE','NOFIT','TBAR']
    for j=0,(n_elements(ktag)-1) do begin
      i = strmatch(klist, ktag[j]+'*', /fold)
      case (total(i)) of
          0  : print, "Keyword not recognized: ", ktag[j]
          1  : case (where(i eq 1))[0] of
                  0 : config = key.(j)
                  1 : stat = key.(j)
                  2 : show = key.(j)
                  3 : monitor = key.(j)
                  4 : secondary = key.(j)
                  5 : dx = key.(j)
                  6 : dy = key.(j)
                  7 : norm = key.(j)
                  8 : center = key.(j)
                  9 : xcenter = key.(j)
                 10 : ycenter = key.(j)
                 11 : corner = key.(j)
                 12 : scale = key.(j)
                 13 : full = key.(j)
                 14 : xfull = key.(j)
                 15 : yfull = key.(j)
                 16 : aspect = key.(j)
                 17 : xsize = key.(j)
                 18 : ysize = key.(j)
                 19 : nofit = key.(j)
                 20 : tbar = key.(j)
               endcase
        else : print, "Keyword ambiguous: ", ktag[j]
      endcase
    endfor
  endif

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
          xs = mgeom[2,i]/10.
          ys = mgeom[3,i]/10.
          putwin, 32, i, xsize=xs, ysize=ys, /center
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

; Title bar width

  if (size(tbar2,/type) gt 0) then tbar = fix(tbar2[0])
  if (size(tbar,/type) eq 0) then tbar = 22

; Monitor configuration

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

; Calculate window geometry and placement

  if (n_elements(wnum) eq 0) then wnum = -1 else wnum = fix(wnum[0])
  if (size(mnum,/type) gt 0) then monitor = fix(mnum[0])
  if (n_elements(monitor) eq 0) then begin
    monitor = primarymon
    if keyword_set(secondary) then begin
      mons = indgen(maxmon+1)
      i = where(mons ne primarymon, count)
      if (count gt 0) then monitor = max(mons[i])
    endif
  endif else monitor = fix(monitor[0])
  monitor = (monitor > 0) < maxmon
  mnum = monitor

  if (size(aspect,/type) gt 0) then begin
    if (n_elements(xsize) gt 0) then begin
      ysize = float(xsize[0])/aspect
    endif else begin
      if (n_elements(ysize) gt 0) then xsize = float(ysize[0])*aspect
    endelse
    if ((n_elements(xsize) eq 0) and (n_elements(ysize) eq 0)) then begin
      ysize = mgeom[3, monitor]/2
      xsize = float(ysize[0])*aspect
    endif
  endif
  if (n_elements(xsize) eq 0) then begin
    xsize = mgeom[2, monitor]/2
    if ((windex eq 1) and (monitor eq 1)) then xsize /= 2
  endif
  if (n_elements(ysize) eq 0) then ysize = mgeom[3, monitor]/2
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

  if (n_elements(corner) eq 0) then begin
    corner = 0
    if (dx lt 0) then begin
      if (dy lt 0) then corner = 3 else corner = 1
    endif else begin
      if (dy lt 0) then corner = 2 else corner = 0
    endelse
  endif else corner = abs(fix(corner[0])) mod 4
  dx = abs(dx)
  dy = abs(dy)

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
    if (size(aspect,/type) gt 0) then begin
      asp = float(xsize)/float(ysize)
      if (asp gt aspect) then xsize = fix(float(ysize)*aspect) $
                         else ysize = fix(float(xsize)/aspect)
    endif
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
    wnum = fix(!d.window)
  endif else begin
    window, wnum, xpos=x0, ypos=y0, xsize=xsize, ysize=ysize, _extra=extra
  endelse

  return

end
