;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/monday.pro,v 1.3 2012/05/01 22:26:06 johnson Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;+
; NAME:  MONDAY.PRO
;
; PURPOSE:  convert year and day_of_year to month and day or vice versa
;
; CALLING SEQUENCE:
;	monday,year,doy,mo,day,[/YEARDAY]
;
;	If the keyword, YEARDAY is set, the routine will take the
;	year, the month, and the day of the year and return the
;	day number of the year (Jan. 1 = 1).
;
;	If the keyword is not set, the routine will take the
;	year and day of year and return the month and day.
; 
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------

pro monday,year,doy,imon,iday,yearday=yearday


 dmons=[31,28,31,30,31,30,31,31,30,31,30,31]
 cdmons=[31,59,90,120,151,181,212,243,273,304,334,365]

  if (year mod 4) eq 0 then begin
    dmons[1] =dmons[1] + 1
    for i=1,11 do cdmons[i] = cdmons[i] + 1
  endif
;
if (keyword_set(YEARDAY)) then $
  if (imon EQ 1) then doy = iday else doy = cdmons[imon-2]+iday $
else begin
  imon=0
  for i=0,11 do begin
 	id=doy-cdmons[i]
	if id gt 0 then begin
		imon = imon+1
		iday = doy-cdmons[i]
	endif
  endfor
  imon = imon+1;
endelse
end
