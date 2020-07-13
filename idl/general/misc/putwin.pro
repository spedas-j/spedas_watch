;+
;PROCEDURE:   putwin
;PURPOSE:
;  Creates a window and places it, according to one of four possible
;  monitor configurations, with offsets relative to the screen edges.
;  This is a user-friendly version of window that is designed for a 
;  multiple monitor setup.
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
;       CONFIG:    Monitor configuration (default = -1):
;
;                    -1 = disabled: putwin acts like window
;                     0 = 1440x900 only
;                     1 = 1440x900 (below), 5120x1440 (above)
;                     2 = 1440x900 (below), 2560x1440 (left, right)
;                     3 = 1440x900 (below), 2560x1440 (above)
;
;                  Additional configurations (> 3) can be defined.
;                  Do not edit configurations that you do not own.
;                  You will need the screen dimensions (in pixels)
;                  and the coordinates of the lower left corner for
;                  every monitor.  Note that these coordinates depend
;                  on the arrangement of the monitors in the operating
;                  system.
;
;                  If this keyword is set, the configuration is defined
;                  and stored in a common block, but no window is
;                  created.  If CONFIG = -1, putwin behaves exactly like
;                  window, and all of the following keywords, with the
;                  exception of SCALE are silently ignored.
;
;       MONITOR:   Put window in this monitor:
;
;                    0 = notebook monitor
;                    1 = external monitor 1 (above or left)
;                    2 = external monitor 2 (right)
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
;       CORNER:    DX and DY are measured from this corner:
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
; $LastChangedDate: 2020-07-12 16:40:46 -0700 (Sun, 12 Jul 2020) $
; $LastChangedRevision: 28880 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, wnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, _extra=extra

  common putwincom, windex, maxmon, xgeom, ygeom

  if (size(windex,/type) eq 0) then windex = -1

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

  if (size(config,/type) gt 0) then begin
    windex = fix(config[0])

    if ((windex lt -1) or (windex gt 3)) then begin
      print,"Configuration must be one of:"
      print,"  -1 = disabled -> putwin acts like window"
      print,"   0 = 1440x900 only"
      print,"   1 = 1440x900 (below), 5120x1440 (above)"
      print,"   2 = 1440x900 (below), 2560x1440 (left, right)"
      print,"   3 = 1440x900 (below), 2560x1440 (above)"
      print,""
      windex = -1
      return
    endif

    xgeom = intarr(3,2)
    ygeom = xgeom

    case windex of
     -1 : swe_snap_layout, 0
      0 : begin
            xgeom[0,*] = [1440,    0]  ; laptop
            ygeom[0,*] = [ 900,    0]
            maxmon = 0
            swe_snap_layout, 0
          end
      1 : begin
            xgeom[0,*] = [1440, 1847]  ; laptop
            ygeom[0,*] = [ 900, -900]
            xgeom[1,*] = [5120,    0]  ; double-wide external above
            ygeom[1,*] = [1440,    0]
            maxmon = 1
            swe_snap_layout, 1
          end
      2 : begin
            xgeom[0,*] = [1440, 1847]  ; laptop
            ygeom[0,*] = [ 900, -900]
            xgeom[1,*] = [2560,    0]  ; external left
            ygeom[1,*] = [1440,    0]
            xgeom[2,*] = [2560, 2560]  ; external right
            ygeom[2,*] = [1440,    0]
            maxmon = 2
            swe_snap_layout, 2
          end
      3 : begin
            xgeom[0,*] = [1440, 1847]  ; laptop (need to verify offset)
            ygeom[0,*] = [ 900, -900]
            xgeom[1,*] = [2560,    0]  ; external above
            ygeom[1,*] = [1440,    0]
            maxmon = 1
            swe_snap_layout, 3
          end
    endcase

    print,"Monitor configuration: ",format='(a,$)'
    case windex of
     -1 : print,'disabled -> putwin acts like window'
      0 : print,'1440x900'
      1 : print,'1440x900 (below), 5120x1440 (above)'
      2 : print,'1440x900 (below), 2560x1440 (left, right)'
      3 : print,'1440x900 (below), 2560x1440 (above)'
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
  if (monitor eq 0) then cbar = 22 else cbar = 0  ; command bar width
  xdim = xgeom[monitor,0]           ; horizontal dimension
  xoff = xgeom[monitor,1]           ; horizontal offset
  ydim = ygeom[monitor,0]           ; vertical dimension
  yoff = ygeom[monitor,1]           ; vertical offset

; Make sure window will fit

  if keyword_set(full) then begin
    xsize = xdim
    ysize = ydim
    dx = 0
    dy = 0
    corner = 0
  endif

  xsize = xsize < (xdim - dx)
  ysize = ysize < (ydim - tbar - cbar - dy)

; Place window relative to corner

  case corner of
    0 : begin  ; top left
          x0 = xoff + dx
          y0 = yoff + (ydim - ysize - cbar) - dy
        end
    1 : begin  ; top right
          x0 = xoff + (xdim - xsize) - dx
          y0 = yoff + (ydim - ysize - cbar) - dy
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
