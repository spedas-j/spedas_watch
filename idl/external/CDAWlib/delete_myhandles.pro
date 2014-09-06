;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/delete_myhandles.pro,v 1.1 2006/09/12 14:31:58 kovalick Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
; Prior to destroying or deleting one of the anonymous structures, determine
; if any data handles exists, and if so, free them.

PRO delete_myhandles, a

for i=0, n_elements(tag_names(a))-1 do begin
  ti = tagindex('HANDLE', tag_names(a.(i)))
  if ti ne -1 then begin

;    b = handle_info(a.(i).HANDLE, /valid_id)
;    if b eq 1 then handle_free, a.(i).HANDLE
    if handle_info(a.(i).HANDLE, /valid_id) then $
      handle_free, a.(i).HANDLE

  endif
endfor

end
