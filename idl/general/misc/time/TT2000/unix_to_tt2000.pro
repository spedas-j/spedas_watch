;+
; FUNCTION:
;         unix_to_tt2000
;
; PURPOSE:
;         Converts unix times to TT2000 times. 
;
; INPUT:
;         time: unix time values 
;
; EXAMPLE:
;         IDL> tt2000_time = unix_to_tt2000(1.4501376e+09)
;         IDL> tt2000_time
;               503409664183998144
;            
;          convert back:
;         IDL> print, tt2000_2_unix(503409664183998144)
;               1.4501376e+09
;        
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-12-05 17:32:38 -0800 (Wed, 05 Dec 2018) $
;$LastChangedRevision: 26258 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/unix_to_tt2000.pro $
;-

function unix_to_tt2000, unix_times

  defsysv,'!CDF_LEAP_SECONDS',exists=exists

  if ~keyword_set(exists) then begin
    cdf_leap_second_init
  endif
  
  tt_conversion = 946727935.8160018921d

  tt2000_times = (unix_times - tt_conversion)*1d9
  return, long64(add_tt2000_offset(tt2000_times))
end