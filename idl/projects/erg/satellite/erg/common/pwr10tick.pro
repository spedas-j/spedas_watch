;+
; $LastChangedDate: 2021-03-09 10:21:19 -0800 (Tue, 09 Mar 2021) $
; $LastChangedRevision: 29747 $
;-

FUNCTION PWR10TICK, axis, index, value

   expval=FIX(ROUND(ALOG10(value)))


   RETURN, STRJOIN('10!U'+STRTRIM(STRING(expval),2)+'!N')
END
