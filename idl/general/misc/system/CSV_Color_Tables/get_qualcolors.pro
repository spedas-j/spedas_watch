;+
;FUNCTION:   get_qualcolors
;PURPOSE:
;  Returns a copy of the qualcolors structure.
;
;USAGE:
;  qualcolors = get_qualcolors()
;
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-19 12:08:13 -0700 (Tue, 19 Jul 2022) $
; $LastChangedRevision: 30945 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/CSV_Color_Tables/get_qualcolors.pro $
;-
function get_qualcolors
  common qualcolors_com, qualcolors
  if (size(qualcolors,/type) ne 8) then return,-1 else return, qualcolors
end
