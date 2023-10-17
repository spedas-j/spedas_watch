;+
;PROCEDURE  file_chgrp
;
;PURPOSE:  Changes the group ownership of a directory or file.  Caller must own the
;          file and be a group member.  Works only in UNIX-like environments.
;
;          This routine is intended for one or a small number of files.  Changing
;          the group ownership of a large number of files, or descending though a 
;          directory structure is much better done in a unix shell.  See the manual
;          page for chgrp.
;
;USAGE:
;   file_chgrp, files, group
;
;INPUTS:
;   files:      One or more file names.  Caller must own these files.
;
;   group:      Desired group ownership for files.  Caller must be a member
;               of this group.
;
;KEYWORDS:
;   SUCCESS:    A integer array containing a success flag for each file.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-10-16 09:19:30 -0700 (Mon, 16 Oct 2023) $
; $LastChangedRevision: 32186 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_chgrp.pro $
;-
pro file_chgrp, files, group, success=ok

  ok = 0

  if (strupcase(!version.os_family) ne 'UNIX') then begin
    print, 'OS family is not unix.'
    return
  endif

  if (size(files,/type) ne 7) then begin
    print, 'You must specify one or more file names.'
    return
  endif

  nfiles = n_elements(files)
  ok = replicate(0, nfiles)

  if (size(group,/type) ne 7) then begin
    print, 'You must specify a group.'
    return
  endif
  group = group[0]  ; only one group is allowed

  spawn, 'groups', mygroups
  mygroups = strsplit(mygroups, ' ', /extract)
  i = where(mygroups eq group, count)
  if (count eq 0L) then begin
    print, 'I''m not a member of the group: ' + group
    return
  endif

  for i=0, nfiles-1 do begin
    file = files[i]
    if (file_test(file, /user)) then begin
      spawn, 'chgrp ' + group + ' ''' + file + ''''
      ok[i] = 1  ; assume success if you get this far
    endif else print, 'File does not exist, or I''m not the owner: ' + file
  endfor

end
