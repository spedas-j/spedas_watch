;+
;NAME:
; run_mvn_over_shell30
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes the single-instrument plots fro thirty days ago. If the
; lock file exists, no processing 
;CALLING SEQUENCE:
; run_mvn_over_shell30, ndays_offset = ndays_offset
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; ndays_offset = days from now that is being processed, the default is
;                30. 
;HISTORY:
; 8-dec-2020, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-12-08 14:57:46 -0800 (Tue, 08 Dec 2020) $
; $LastChangedRevision: 29446 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/run_mvn_over_shell30.pro $
;-

Pro run_mvn_over_shell30, ndays_offset = ndays_offset

  test_file = file_search('/mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt'
     spawn, 'touch '+test_file[0]
     If(keyword_set(ndays_offset)) Then ndays = ndays_offset $
     Else ndays = 30
     date = systime(/sec)
;Subtract the number of days
     date = date - ndays*86400.0d0
     date = time_string(date, precision = -3)
     message, /info, 'PROCESSING: '+date
     mvn_over_shell, date = date
     message, /info, 'Removing Lock file /mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

