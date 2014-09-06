;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/save_mystruct.pro,v 1.6 2013/09/06 18:03:48 johnson Exp kovalick $
;$Locker: kovalick $
;$Revision: 15739 $
; Utilize IDL's SAVE procedure to save the structure a into the given filename.
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
PRO save_mystruct,a,fname
COMMON CDFmySHARE, v0  ,v1, v2, v3, v4, v5, v6, v7, v8, v9,$
                   v10,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20
if tagindex('HANDLE',tag_names(a.(0))) eq -1 then begin
  ; data is stored directly in the structure
  SAVE,a,FILENAME=fname
endif else begin
  ; data is stored in handles.  Retrieve the data from the handles,
  ; and store the data into 'n' local variables, then SAVE.
  ; RCJ Restore will not restore the data in the handles, so "handle_value,a.(0).handle,tt " for example
  ;    will not work after you restore the saved file.
  tn = tag_names(a) 
  nt = n_elements(tn) 
  cmd = 'SAVE,a'
  ; Preallocate some temporary variables.  The EXECUTE command cannot
  ; create new variables...they must already exist.  Lets hope 20 is enough.
  ;TJK comment this check out since this is now done dynamically
  ;  if nt ge 20 then begin
  ;    print,'ERROR= too many handle values in structure to save' & return
  ;  endif

  ;  v0=0L  & v1=0L  & v2=0L  & v3=0L  & v4=0L  & v5=0L  & v6=0L  & v7=0L
  ;  v8=0L  & v9=0L  & v10=0L & v11=0L & v12=0L & v13=0L & v14=0L & v15=0L
  ;  v16=0L & v17=0L & v18=0L & v19=0L & v20=0L

  for i=0,nt-1 do begin ; retrieve each handle value
    order = 'handle_value,a.(i).HANDLE,v' + strtrim(string(i),2)
    ; RCJ  Well, my idea below was to save the var w/ its proper var name,
    ; but if the user is going to use restore_mystruct to get the data back it really doesn't
    ; matter what the var is called.
    ;order = 'handle_value,a.(i).HANDLE,' + strtrim(a.(i).varname,2)
     status = EXECUTE(order)
    cmd = cmd + ',v' +  strtrim(string(i),2)
    ;cmd = cmd + ',' +  strtrim(a.(i).varname,2)
   endfor

  ; Add the filename keyword to save command
  cmd = cmd+",FILENAME='"+fname+"'"
  status = execute(cmd) ; execute the save command
  if status[0] eq 1 then print,'Done saving file' else print,'A problem occurred when saving the file'
endelse
end

