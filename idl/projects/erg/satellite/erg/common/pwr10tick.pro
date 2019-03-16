;+
; $LastChangedDate: 2019-03-15 12:52:35 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26822 $
;-

FUNCTION PWR10TICK, axis, index, value

   expval=FIX(ROUND(ALOG10(value)))


   RETURN, STRJOIN('10!U'+STRTRIM(STRING(expval),2)+'!N')
END
