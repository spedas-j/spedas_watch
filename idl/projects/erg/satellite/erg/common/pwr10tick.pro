;+
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
; $LastChangedRevision: 25628 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/common/pwr10tick.pro $
;-

FUNCTION PWR10TICK, axis, index, value

   expval=FIX(ROUND(ALOG10(value)))


   RETURN, STRJOIN('10!U'+STRTRIM(STRING(expval),2)+'!N')
END
