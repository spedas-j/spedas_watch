;+
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-

FUNCTION PWR10TICK, axis, index, value

   expval=FIX(ROUND(ALOG10(value)))


   RETURN, STRJOIN('10!U'+STRTRIM(STRING(expval),2)+'!N')
END
