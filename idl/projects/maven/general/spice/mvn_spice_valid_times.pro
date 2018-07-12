;+
;
;FUNCTION:        MVN_SPICE_VALID_TIMES
;
;PURPOSE:         
;                 Checks whether the currently loaded SPICE/kernels are valid for the specified time.
;
;INPUTS:          Time to be checked.
;
;KEYWORDS:        None.
;
;CREATED BY:      Takuya Hara on 2018-07-11.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-07-11 17:35:33 -0700 (Wed, 11 Jul 2018) $
; $LastChangedRevision: 25463 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_valid_times.pro $
;
;-
FUNCTION mvn_spice_valid_times, tvar, verbose=verbose
  status = 0 ; invalid

  IF SIZE(tvar, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'You must supply a time to be checked.'
     RETURN, status
  ENDIF ELSE BEGIN
     time = tvar
     IF SIZE(time, /type) EQ 7 THEN time = time_double(time)
  ENDELSE 

  test = spice_test('*')
  IF (N_ELEMENTS(test) EQ 1 AND test[0] EQ '') THEN $
     dprint, dlevel=2, verbose=verbose, 'SPICE/kernels should be loaded at first.' $
  ELSE BEGIN
     ck = spice_kernel_info(type='ck')
     w = WHERE(STRMATCH(FILE_BASENAME(ck.filename), 'mvn_swea*.bc') EQ 0, nw)
     IF nw GT 0 THEN ck = ck[w]
    
     spk = spice_kernel_info(type='spk')
     w = WHERE(STRMATCH(FILE_BASENAME(spk.filename), 'maven_orb*.bsp') EQ 1, nw)
     IF nw GT 0 THEN spk = spk[w]

     undefine, w, nw

     info = [ck, spk]
     kernels = info.filename
     kernels = kernels[UNIQ(kernels, SORT(kernels))]

     nk = N_ELEMENTS(kernels)
     valid = INTARR(nk)
     FOR i=0, nk-1 DO BEGIN
        w = WHERE(STRMATCH(info.filename, kernels[i]) EQ 1, nw)
        checks = INTARR(nw)
        FOR j=0, nw-1 DO IF (time GE time_double(info[w[j]].trange[0]) AND time LE time_double(info[w[j]].trange[1])) THEN checks[j] = 1
        w = WHERE(checks EQ 1, nw)
        IF nw GT 0 THEN valid[i] = 1
     ENDFOR 

     w = WHERE(valid EQ 0, nw)
     IF nw EQ 0 THEN status = 1 ; valid
  ENDELSE
  RETURN, status
END
