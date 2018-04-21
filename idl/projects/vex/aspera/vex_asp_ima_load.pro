;+
;
;PROCEDURE:       VEX_ASP_IMA_LOAD
;
;PURPOSE:         
;                 Loads VEX/ASPERA-4 (IMA) data from ESA/PSA.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;      SAVE:      If set, makes the IDL save file.
;
; NO_SERVER:      If set, prevents any contact with the remote server.
;
;CREATED BY:      Takuya Hara on 2017-04-15 -> 2018-04-16.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-19 19:38:38 -0700 (Thu, 19 Apr 2018) $
; $LastChangedRevision: 25082 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_ima_load.pro $
;
;-
PRO vex_asp_ima_list, trange, verbose=verbose, save=save, file=file, time=modify_time
  ldir = root_data_dir() + 'vex/aspera/ima/tab/'
  file_mkdir2, ldir

  mtime = ['2005-11', '2007-10-03', '2009-06', '2010-09', '2013']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = 'EXT' + phase[v]
  pdir = 'VEX-V-SW-ASPERA-2-' + phase + '-IMA-V1.0/' ; pdir stands for "phase dir".

  dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'

  rpath = 'ftp://psa.esac.esa.int/pub/mirror/VENUS-EXPRESS/ASPERA4/'
  ndat = N_ELEMENTS(date)

  FOR i=0, ndat-1 DO BEGIN
     rdir = rpath + pdir[i] + 'DATA/'
     
     rflg = 0
     IF SIZE(rdir_old, /type) EQ 0 THEN rflg = 1 $
     ELSE IF rdir NE rdir_old THEN rflg = 1
     IF (rflg) THEN BEGIN
        list_dir = spd_download(remote_path=rdir, remote_file='*', local_path=ldir, local_file='vex_asp_ima_lists.txt', ftp_connection_mode=0)
        rdir_old = rdir

        OPENR, unit, list_dir, /get_lun
        text = STRARR(FILE_LINES(list_dir))
        READF, unit, text
        FREE_LUN, unit

        text = STRSPLIT(text, ' ', /extract)
        text = text.toarray()
        subdir = REFORM(TEMPORARY(text[*, -1]))
        dir_time = STRSPLIT(REFORM(subdir), '_', /extract)
        dir_time = dir_time.toarray()
        dir_time = time_double(REFORM(dir_time[*, 0]), tformat='YYYYMMDD')
     ENDIF 

     w = FIX(INTERP(FINDGEN(N_ELEMENTS(dir_time)), dir_time, time_double(date[i]))) < (N_ELEMENTS(dir_time)-1)

     dflg = 0
     IF SIZE(subdir_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF subdir[w] NE subdir_old THEN dflg = 1
     IF (dflg) THEN list_file = spd_download(remote_path=rdir + subdir[w] + '/', remote_file='*', local_path=ldir, local_file='vex_asp_ima_lists.txt', ftp_connection_mode=0)
     subdir_old = subdir[w]
  
     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit

     text = STRSPLIT(text, ' ', /extract)
     text = text.toarray()
     text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')
     mod_time = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY')
     
     w = WHERE(STRMATCH(text[*, -1], 'IMA_M*_' + time_string(date[i], tformat='yyMMDD') + '*') EQ 1, nw)
     
     IF nw GT 0 THEN afile = rdir + subdir_old + '/' + text[w, -1]

     IF SIZE(afile, /type) NE 0 THEN BEGIN
        append_array, file, afile
        append_array, modify_time, mod_time[w]
     ENDIF 
     undefine, w, nw, text, afile
  ENDFOR 
  IF SIZE(list_file, /type) EQ 7 THEN FILE_DELETE, list_file
  RETURN
END

PRO vex_asp_ima_save, time, counts, polar, pacc, file=file, verbose=verbose
  prefix = 'vex_asp_ima_'
  
  name  = (STRSPLIT(file[0], '_', /extract))[2]
  ftime = time_double(name, tformat='yyMMDDhhmmss')
 
  path  = root_data_dir() + 'vex/aspera/ima/sav/' + time_string(ftime, tformat='YYYY/MM/')
  fname = prefix + time_string(ftime, tformat='YYYYMMDD_hhmmss') + '.sav'

  asp_ima_stime = time
  asp_ima_polar = polar
  asp_ima_pacc  = pacc
  asp_ima_cnts  = counts
  asp_ima_file  = file

  file_mkdir2, path, dlevel=2, verbose=verbose
  dprint, dlevel=2, verbose=verbose, 'Saving ' + path + fname + '.'
  SAVE, filename=path + fname, asp_ima_stime, asp_ima_polar, asp_ima_pacc, asp_ima_cnts, asp_ima_file

  RETURN
END

PRO vex_asp_ima_com, time, counts, polar, pacc, verbose=verbose, $
                     data=asp_ima_dat, trange=trange

  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  units = 'counts'
  dt = 12.d0
  nenergy = 96
  nmass = 32
  nbins = 16

  stime = REFORM(time[*, 0])
  etime = REFORM(time[*, 1])

  dformat = {units_name: units, time: 0.d0, end_time: 0.d0, $
             energy: DBLARR(nenergy, nbins, nmass), $
             data: FLTARR(nenergy, nbins, nmass), polar: 0, pacc: 0} ;, $
             ;theta: FLTARR(nenergy, nbins, nmass), bkg: FLTARR(nenergy, nbins, nmass)}

  ndat = N_ELEMENTS(stime)
  vex_asp_ima = REPLICATE(dformat, ndat)

  vex_asp_ima.time     = stime
  vex_asp_ima.end_time = etime
  vex_asp_ima.polar    = polar
  vex_asp_ima.pacc     = pacc
  vex_asp_ima.data     = TRANSPOSE(counts, [1, 2, 3, 0])

  time = MEAN(time, dim=2)
  vex_asp_ima_ene_theta, time, verbose=verbose, energy=energy
  vex_asp_ima.energy = TRANSPOSE(TEMPORARY(energy), [1, 2, 3, 0])

  IF SIZE(trange, /type) NE 0 THEN BEGIN
     w = WHERE(time GE trange[0] AND time LE trange[1], nw)
     vex_asp_ima = vex_asp_ima[w]
  ENDIF

  asp_ima_dat = vex_asp_ima
  RETURN
END

PRO vex_asp_ima_read, trange, verbose=verbose, time=stime, counts=counts, polar=polar, pacc=pacc, $
                      save=save, file=remote_file, mtime=modify_time, status=status, no_server=no_server
  nan = !values.f_nan
  status = 1
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  
  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))

  ldir = root_data_dir() + 'vex/aspera/ima/tab/' 
  spath = ldir + time_string(date, tformat='YYYY/MM/')

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(spath[i], 'IMA_M*' + time_string(date[i], tformat='yyMMDD') + '*', count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR 
  
  IF SIZE(file, /type) EQ 0 THEN rflg = 1 $
  ELSE BEGIN
     IF (nflg) THEN $
        IF (N_ELEMENTS(file) EQ N_ELEMENTS(remote_file)) AND $
        (compare_struct(FILE_BASENAME(file[SORT(file)]), FILE_BASENAME(remote_file[SORT(remote_file)])) EQ 1) THEN $
           rflg = 0 ELSE rflg = 1 ELSE rflg = 0
  ENDELSE 
  
  IF (rflg) THEN BEGIN
     nfile = N_ELEMENTS(remote_file)
     FOR i=0, nfile-1 DO BEGIN
        IF SIZE(file, /type) EQ 0 THEN dflg = 1 $
        ELSE BEGIN
           w = WHERE(STRMATCH(FILE_BASENAME(file), FILE_BASENAME(remote_file[i])) EQ 1, nw)
           IF nw EQ 0 THEN dflg = 1 ELSE dflg = 0
        ENDELSE 
        IF (dflg) THEN BEGIN
           suffix = FILE_BASENAME(remote_file[i])
           suffix = STRSPLIT(suffix, '_', /extract)
           suffix = time_string(time_double(suffix[2], tformat='yyMMDDhhmmss'), tformat='YYYY/MM/')
           append_array, fname, spd_download(remote_file=remote_file[i], local_path=ldir+suffix, ftp_connection_mode=0)
           file_touch, fname[-1], modify_time[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE append_array, fname, file[w]
     ENDFOR
  ENDIF ELSE fname = file
  
  IF N_ELEMENTS(fname) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     status = 0
     RETURN
  ENDIF ELSE undefine, file

  w = WHERE(REFORM(((STRSPLIT(fname, '.', /extract)).toarray())[*, 1]) EQ 'TAB', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN tfile = fname[w]
  IF nv GT 0 THEN lfile = fname[v]
  nfile = nw
  
  IF nw NE nv THEN BEGIN
     dprint, dlevel=2, verbose=verbose, ''
     status = 0
     RETURN
  ENDIF ELSE undefine, w, v, nw, fname

  FOR i=0, nv-1 DO BEGIN
     OPENR, unit, lfile[i], /get_lun
     data = STRARR(FILE_LINES(lfile[i]))
     READF, unit, data
     FREE_LUN, unit

     iv = WHERE(STRMID(data, 0, 10) EQ 'START_TIME')
     data = (STRSPLIT(data[iv:iv+1], ' ', /extract)).toarray()
     tdata = time_double(data[*, 2], tformat='YYYY-MM-DDThh:mm:ss.fff')

     idx = INTERP([0., 1.], trange, tdata)
     iv = WHERE(MAX(idx) LT 0. OR MIN(idx) GT 1., niv)
     IF niv EQ 0 THEN append_array, file, tfile[i]
     undefine, data, tdata, idx, iv, niv
  ENDFOR
  IF SIZE(file, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     status = 0
     RETURN
  ENDIF ELSE undefine, nv

  counts = list()
  stime  = list()
  polar  = list()
  pacc   = list()
  fname  = list()
  FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
     mode = STRMID((STRSPLIT(FILE_BASENAME(file[i]), '_', /extract))[1], 1, 2)
     CASE mode OF               ; phi, mass, energy, polar(=time)
        '24': nbins = LONG([16, 32, 96, 16])
        '25': nbins = LONG([16, 32, 96,  8])
        ELSE: BEGIN
           dprint, 'Unexpected error.', dlevel=2, verbose=verbose
           status = 0 
           RETURN
        END 
     ENDCASE

     dprint, dlevel=2, verbose=verbose, 'Reading ' + file[i] + '.'
     OPENR, unit, file[i], /get_lun
     data = STRARR(FILE_LINES(file[i]))
     READF, unit, data
     FREE_LUN, unit

     data = STRSPLIT(data, ' ', /extract)
     ndat = N_ELEMENTS(data)
     fname.add, file[i]
     cnts = list()
     FOR j=0, ndat-1 DO BEGIN
        onescan = data[j]
        IF N_ELEMENTS(onescan[31:*]) EQ PRODUCT(nbins) THEN BEGIN
           t1scan = time_double(onescan[0], tformat='YYYY-MM-DDThh:mm:ss.fff')
           append_array, pac, REPLICATE(FLOAT(onescan[16]), nbins[-1])
           
           onescan = FLOAT(REFORM(onescan[31:*], nbins))
           onescan = TRANSPOSE(onescan, [3, 2, 0, 1]) ; polar(=time), energy, phi, mass
           cnts.add, TEMPORARY(onescan)
           
           IF (nbins[-1] EQ 8) THEN BEGIN
              append_array, time, t1scan + 2.d0 + dgen(range=[0.d0, 192.d0-24.d0], nbins[-1]) ; Based on IRF-Kiruna IDL save files.
              append_array, pol, INDGEN(nbins[-1])*2
           ENDIF
           IF (nbins[-1] EQ 16) THEN BEGIN
              append_array, time, t1scan + dgen(range=[12.d0, 192.d0], nbins[-1])
              append_array, pol, INDGEN(nbins[-1])
           ENDIF
        ENDIF 
     ENDFOR
     counts.add, cnts.toarray(/dim)
     pacc.add,  TEMPORARY(pac)
     stime.add, TEMPORARY(time)
     polar.add, TEMPORARY(pol)
     undefine, data, cnts
  ENDFOR

  IF KEYWORD_SET(save) THEN $
     FOR i=0, N_ELEMENTS(fname)-1 DO $
        vex_asp_ima_save, stime[i], counts[i], polar[i], pacc[i], file=fname[i], verbose=verbose

  RETURN
END

PRO vex_asp_ima_load, itime, verbose=verbose, save=save, no_server=no_server
  COMMON vex_asp_dat, vex_asp_ima, vex_asp_els
  undefine, vex_ima_els
  t0 = SYSTIME(/sec)
  IF SIZE(itime, /type) EQ 0 THEN get_timespan, trange $
  ELSE BEGIN
     trange = itime
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDELSE 
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  IF (nflg) THEN BEGIN
     vex_asp_ima_list, trange, verbose=verbose, file=remote_file, time=mtime
     IF N_ELEMENTS(remote_file) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
  ENDIF 

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  path = root_data_dir() + 'vex/aspera/ima/sav/' + time_string(date, tformat='YYYY/MM/') + $
         'vex_asp_ima_*' + time_string(date, tformat='YYYYMMDD') + '*.sav'

  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(path[i], count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR

  IF SIZE(file, /type) NE 0 THEN BEGIN
     IF (nflg) THEN BEGIN
        FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
           obj = OBJ_NEW('IDL_Savefile', file[i])
           obj -> RESTORE, 'asp_ima_file'
           append_array, lfile, TEMPORARY(asp_ima_file)
           OBJ_DESTROY, obj
        ENDFOR 
        lfile = lfile[SORT(lfile)]
        rfile = FILE_BASENAME(remote_file)
        rfile = rfile[SORT(rfile)]
        IF (compare_struct(rfile, lfile) EQ 1) THEN sflg = 0 ELSE sflg = 1
     ENDIF ELSE sflg = 0
  ENDIF ELSE sflg = 1

  IF (sflg) THEN BEGIN
     vex_asp_ima_read, trange, time=stime, counts=counts, polar=polar, pacc=pacc, $
                       verbose=verbose, save=save, file=remote_file, mtime=mtime, status=status, no_server=no_server
     IF (status EQ 0) THEN RETURN
  ENDIF ELSE BEGIN
     stime  = list()
     counts = list()
     polar  = list()
     pacc   = list()
     FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Restoring ' + file[i] + '.'
        obj = OBJ_NEW('IDL_Savefile', file[i])
        vname = obj -> Names()
        v = WHERE(STRMATCH(vname, '*FILE') EQ 0)
        obj -> Restore, vname[v]
        stime.add,  TEMPORARY(asp_ima_stime)
        counts.add, TEMPORARY(asp_ima_cnts)
        polar.add,  TEMPORARY(asp_ima_polar)
        pacc.add,   TEMPORARY(asp_ima_pacc)
        undefine, obj, vname, v
     ENDFOR 
  ENDELSE 
 
  counts = counts.toarray(dim=1)
  stime  = stime.toarray(dim=1)
  polar  = polar.toarray(dim=1)
  pacc   = pacc.toarray(dim=1)
  
  etime = stime + 12.d0

  time = [ [stime], [etime] ]
  time = MEAN(time, dim=2)
  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF ELSE BEGIN
     vex_asp_ima_com, [ [stime], [etime] ], counts, polar, pacc, data=ima, trange=trange
     time = time[w]
  ENDELSE 

  cnt = ima.data
  ene = ima.energy

  store_data, 'vex_asp_ima_espec', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnt, 2), 2)), v: TRANSPOSE(MEAN(MEAN(ene, dim=2, /nan), dim=2, /nan))}, $
              dlim={spec: 1, datagap: 30.d0, ysubtitle: 'Energy [eV]', ytitle: 'VEX/ASPERA-4 (IMA)'}, limits={minzlog: 1}

  ylim, 'vex_asp_ima_espec', 10., 30.e3, 1, /def
  zlim, 'vex_asp_ima_espec', 1., 1.e4, 1, /def
  options, 'vex_asp_ima_espec', ztitle='Counts [#]', /def

  dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
