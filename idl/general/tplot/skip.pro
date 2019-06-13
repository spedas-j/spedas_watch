;+
;PROCEDURE:   skip
;PURPOSE:
;  Shifts the tplot plotting window forward/backward by a number of
;  orbits, days, hours, minutes, seconds, or "pages".  A page is 
;  defined as the currently displayed time range.
;
;USAGE:
;  skip, n
;
;INPUTS:
;       n:        Number of orbits, days, hours, minutes, seconds, or pages
;                 (positive or negative) to shift.  Default = +1.  Normally,
;                 this would be an integer, but it can also be a float.
;
;KEYWORDS:
;       PAGE:     (Default) Shift in units of the time range currently displayed.
;                 This keyword and the next 5 define the shift units.  Once you 
;                 set the units, it remains in effect until you explicitly select 
;                 different units.
;
;       DAY:      Shift in days.
;
;       HOUR:     Shift in hours.
;
;       MINUTE:   Shift in minutes.
;
;       SEC:      Shift in seconds.
;
;       ORB:      Shift in orbits.  Currently only works for MAVEN.
;
;       FIRST:    Go to the beginning of the loaded time range and
;                 plot the requested interval from there.  Do not
;                 collect $200.
;
;       LAST:     Go to end of loaded time range and plot the requested
;                 interval from there.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-06-12 13:37:59 -0700 (Wed, 12 Jun 2019) $
; $LastChangedRevision: 27344 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/skip.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro skip, n, orb=orb, day=day, sec=sec, minute=minute, hour=hour, page=page, $
             first=first, last=last

  common skip_com, ptime, period, mode

; Determine skip units

  tplot_options, get=topt
  t = minmax(topt.trange_full)

  ok = 0
  if ((not ok) and keyword_set(sec)) then begin
    mode = 1
    ok = 1
  endif
  if ((not ok) and keyword_set(minute)) then begin
    mode = 2
    ok = 1
  endif
  if ((not ok) and keyword_set(hour)) then begin
    mode = 3
    ok = 1
  endif
  if ((not ok) and keyword_set(day)) then begin
    mode = 4
    ok = 1
  endif
  if ((not ok) and keyword_set(page)) then begin
    mode = 5
    ok = 1
  endif
  if ((not ok) and keyword_set(orb)) then begin
    mode = 6
    ok = 1
  endif
  if ((not ok) and (size(mode,/type) ne 2)) then mode = 5

; Get orbit data if needed

  if ((mode eq 6) and (size(period,/type) eq 0)) then begin
    orb = mvn_orbit_num()
    period = orb.peri_time - shift(orb.peri_time,1)
    period[0] = period[1]
    ptime = orb.peri_time

    i = nn2(ptime,[t[0],mean(topt.trange),t[1]])
    p = period[i]
  endif

  case mode of
    1 : delta_t = 1D
    2 : delta_t = 60D
    3 : delta_t = 3600D
    4 : delta_t = 86400D
    5 : delta_t = topt.trange[1] - topt.trange[0]
    6 : begin
          delta_t = p[1]
          if keyword_set(first) then delta_t = p[0]
          if keyword_set(last) then delta_t = p[2]
        end
    else : begin
             print, "Mode = ", mode
             print, "This is impossible!"
             return
           end
  endcase

  if (size(n,/type) eq 0) then n = 1D else n = double(n[0])
  delta_t *= n

; Shift the time window

  if keyword_set(first) then begin
    tlimit, [t[0], t[0]+delta_t]
    return
  endif

  if keyword_set(last) then begin
    tlimit, [t[1]-delta_t, t[1]]
    return
  endif

  tlimit, topt.trange + delta_t
  return

end
