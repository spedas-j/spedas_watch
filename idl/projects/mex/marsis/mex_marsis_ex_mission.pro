;+
; FUNCTION:
;       mex_marsis_ex_mission
; PURPOSE:
;       returns "i"th extended missions from orbit numbers
;       needs to be updated manually every time a new extended mission starts
; CALLING SEQUENCE:
;       Nex = mex_marsis_ex_misssion(orbnum)
; INPUTS:
;       orbnum: orbit number(s)
; CREATED BY:
;       Yuki Harada on 2017-05-04
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-04-06 01:38:33 -0700 (Fri, 06 Apr 2018) $
; $LastChangedRevision: 25009 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/marsis/mex_marsis_ex_mission.pro $
;-

function mex_marsis_ex_mission, orbnums, rdr=rdr

Nex = replicate(-1l,n_elements(orbnums))

;;; primary
w = where( orbnums ge 1844 and orbnums le 2539 , nw )
if nw gt 0 then Nex[w] = 0

;;; 1st
w = where( orbnums ge 2540 and orbnums le 4799 , nw )
if nw gt 0 then Nex[w] = 1

;;; 2nd
w = where( orbnums ge 4800 and orbnums le 7669 , nw )
if nw gt 0 then Nex[w] = 2

;;; 3rd
w = where( orbnums ge 7690 and orbnums le 11449 , nw )
if nw gt 0 then Nex[w] = 3

;;; 4th
w = where( orbnums ge 11450 and orbnums le 13959 , nw )
if nw gt 0 then Nex[w] = 4

;;; 5th
w = where( orbnums ge 13960 and orbnums le 16469 , nw )
if nw gt 0 then Nex[w] = 5

;;; 6th
w = where( orbnums ge 16470 and orbnums le 30000 , nw )
if nw gt 0 then Nex[w] = 6

;;; inconsistent mission phases...
if keyword_set(rdr) then begin
   w = where( orbnums ge 11450 and orbnums le 13969 , nw )
   if nw gt 0 then Nex[w] = 4
endif


return,Nex

end
