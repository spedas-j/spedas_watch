;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/mlt.pro,v 1.2 1996/08/09 18:04:28 kovalick Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;
;+
; NAME:
;	MLT
;
; PURPOSE:
;
;	convert UT time to MLT
;
;	calling sequence:
;	  mt = mlt(year, ut_seconds, mag_long)
;		inputs:  year, time in seconds from Jan. 1 at 00;00:00 UT
;		         magnetic longitude of the observation point
;	
;	        the time in seconds can be found with routine "cnvtime"
;		the magnetic longitude of the obs. point can be found
;		  by using routine "cnvcoord"
;
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
function mlt, year, t, mlong
	year = fix(year)
;	t = long(t)
	mlong = float(mlong)
                
	mt = 0.0

;	mt = call_external(getenv ('SD_LIB_PGM'), 'mlt_idl', $
;		year, t, mlong,/f_value)
;	mt = call_external(getenv('libpgm.so.1.1'), 'mlt_idl', $
;	  	year, t, mlong,/f_value)

       mt = call_external('LIB_PGM.so', 'mlt_idl', $
               year, t, mlong,/f_value)
       
;      if check_math(1,1) ne 0 then begin
;       print, year, t, mlong, mt
;       endif

	return, mt
	end
