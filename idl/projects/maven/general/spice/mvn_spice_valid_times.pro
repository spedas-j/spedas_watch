;+
;
;FUNCTION:        MVN_SPICE_VALID_TIMES
;
;PURPOSE:         
;                 Checks whether the currently loaded SPICE/kernels are valid for the specified time.
;
;INPUTS:          Time or time array to be checked.
;
;KEYWORDS:        None.
;
;CREATED BY:      Takuya Hara on 2018-07-11.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-07-16 13:08:30 -0700 (Mon, 16 Jul 2018) $
; $LastChangedRevision: 25483 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_valid_times.pro $
;
;-
FUNCTION mvn_spice_valid_times, tvar, verbose=verbose, tolerance=tol
  status = 0 ; invalid
  IF SIZE(tol, /type) EQ 0 THEN tol = 120.d0

  IF SIZE(tvar, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'You must supply a time or time array to be checked.'
     RETURN, status
  ENDIF ELSE BEGIN
     time = tvar
     IF SIZE(time, /type) EQ 7 THEN time = time_double(time)
     ntime = N_ELEMENTS(time)
     IF ntime GT 1 THEN pflg = 1 ELSE pflg = 0
  ENDELSE 

  test = spice_test('*')
  IF (N_ELEMENTS(test) EQ 1 AND test[0] EQ '') THEN $
     dprint, dlevel=2, verbose=verbose, 'SPICE/kernels should be loaded at first.' $
  ELSE BEGIN
     info = spice_kernel_info(/use_cache)
     w = WHERE(info.type EQ 'CK' AND STRMATCH(FILE_BASENAME(info.filename), 'mvn_swea*.bc') EQ 0, nw)
     IF nw GT 0 THEN ck = info[w]
    
     w = WHERE(info.type EQ 'SPK' AND STRMATCH(FILE_BASENAME(info.filename), 'maven_orb*.bsp') EQ 1, nw)
     IF nw GT 0 THEN spk = info[w]

     undefine, w, nw, info

     info = [ck, spk]
     kernels = info.filename
     kernels = kernels[UNIQ(kernels, SORT(kernels))]
     nk = N_ELEMENTS(kernels)

     valid = INTARR(nk, ntime)
     FOR i=0, nk-1 DO BEGIN
        t = WHERE(STRMATCH(info.filename, kernels[i]) EQ 1, nt)
        checks = INTARR(ntime, nt)

        FOR j=0, nt-1 DO BEGIN
           index = INTERPOL([0., 1.], time_double(info[t[j]].trange) + [1.d0, -1.d0]*tol, time)

           w = WHERE(index GE 0. AND index LE 1., nw, complement=v, ncomplement=nv)
           IF nw GT 0 THEN checks[w, j] = 1
           IF nv GT 0 THEN checks[v, j] = 0
           undefine, w, v, nw, nv
        ENDFOR 

        IF SIZE(checks, /n_dimension) EQ 2 THEN checks = TOTAL(checks, 2)
        w = WHERE(checks GT 0, nw)
        IF nw GT 0 THEN valid[i, w] = 1
        undefine, w, nw
     ENDFOR 

     IF nk GT 1 THEN valid = PRODUCT(valid, 1)
     w = WHERE(valid EQ 0, nw, complement=v, ncomplement=nv)
     IF (pflg) THEN BEGIN
        status = INTARR(ntime)
        IF nv GT 0 THEN status[v] = 1
     ENDIF ELSE IF nw EQ 0 THEN status = 1 ; valid
  ENDELSE
  RETURN, status
END
