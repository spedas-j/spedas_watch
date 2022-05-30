;+
; ta16_supported
;
; Purpose: returns 1 if TA16 is supported (geopack version is 10.9 or higher)
;          TA16 also requires file TA16_RBF.par in the same directory
;
; Notes:
;   2022-05-23: Geopack DLM v10.9 is a beta version:
;               https://www.korthhaus.com/index.php/idl-software/idl-geopack-dlm/
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-05-29 14:31:21 -0700 (Sun, 29 May 2022) $
; $LastChangedRevision: 30837 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/ta16_supported.pro $
;-

function ta16_supported

  help, 'geopack', /dlm, output=dlm_about
  result = 0

  if n_elements(dlm_about) gt 1 then begin
    d = strsplit(dlm_about[1], /extract)
    if n_elements(d) gt 1 then begin
      v = strsplit(d[1], '.', /extract)
      if n_elements(v) gt 0 then begin
        v0 = v[0]
        v1 = strsplit(v[1], ',', /extract)
        if v0 gt 10 then begin
          result = 1 ; geopack 11 and over
        endif else begin
          if v0 eq 10 && v1 ge 9 then result = 1 ; geopack 10.9 and over
        endelse
      endif
    endif
  endif

  if result eq 0 then begin
    dprint, "TA16 model is supported only in GEOPACK 10.9 or higher. Please upgrade your GEOPACK version."
    help, 'geopack', /dlm
  endif else begin
    ; requires file TA16_RBF.par in the same directory
    dir = FILE_DIRNAME(ROUTINE_FILEPATH(), /MARK_DIRECTORY)
    file = dir + 'TA16_RBF.par'
    if FILE_TEST(file, /read) then begin
      GEOPACK_TA16_SETPATH, dir
    endif else begin
      dprint, "TA16 model requires file TA16_RBF.par. It was not found in current directory."
      result = 0
    endelse
  endelse

  return, result
end