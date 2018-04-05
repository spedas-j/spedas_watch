;+
;
;PROCEDURE:       MEX_ASP_IMA_LOAD
;
;PURPOSE:         
;                 Loads MEX/ASPERA-3 (IMA) data from ESA/PSA.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;      SAVE:      If set, makes the IDL save file.
;
; NO_SERVER:      If set, prevents any contact with the remote server.
;
;CREATED BY:      Takuya Hara on 2018-01-23.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 16:17:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_load.pro $
;
;-
PRO mex_asp_ima_list, trange, verbose=verbose, file=file, time=modify_time
  ldir = root_data_dir() + 'mex/aspera/ima/csv/'
  file_mkdir2, ldir

  mtime = ['2003-06-02', '2006-01', '2007-10', '2010', '2013', '2015']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = '-EXT' + phase[v]

  pdir = 'MEX-M-ASPERA3-2-EDR-IMA' ; pdir stands for "phase dir".
  pdir += phase + '-V1.0/'

  dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'

  rpath = 'ftp://psa.esac.esa.int/pub/mirror/MARS-EXPRESS/ASPERA-3/'
  ndat = N_ELEMENTS(date)

  FOR i=0, ndat-1 DO BEGIN
     cmd = rpath + pdir[i] + 'DATA/IMA_EDR_L1B_' + time_string(date[i], tformat='YYYY_')

     IF (date[i] GE time_double('2004')) THEN cmd += time_string(date[i], tformat='MM/') $
     ELSE IF LONG(time_string(date[i], tformat='DOY')) GT 250 THEN cmd += 'IC/' ELSE cmd += 'EV/'

     dflg = 0
     IF SIZE(cmd_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF cmd NE cmd_old THEN dflg = 1
     IF (dflg) THEN list_file = spd_download(remote_path=cmd, remote_file='*', local_path=ldir, local_file='mex_asp_ima_lists.txt', ftp_connection_mode=0)
     
     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit
     
     text = STRSPLIT(text, ' ', /extract)
     text = text.toarray()
     text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')
     mod_time = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY')

     w = WHERE(STRMATCH(text[*, -1], 'IMA_AZ*' + time_string(date[i], tformat='YYYYDOY') + '*.CSV') EQ 1, nw)
     IF nw GT 0 THEN afile = cmd + text[w, -1]
     IF SIZE(afile, /type) NE 0 THEN BEGIN
        append_array, file, afile
        append_array, modify_time, mod_time[w]
     ENDIF 
     undefine, w, nw, text, afile
     cmd_old = cmd
  ENDFOR 
  RETURN
END

PRO mex_asp_ima_save, time, counts, polar, pacc, hk, file=file, verbose=verbose
  prefix = 'mex_asp_ima_'
  lvl = 'l1b'
  name  = (STRSPLIT(file, '_', /extract))[0]
  ftime = time_double(name[1], tformat='AZ**YYYYDOYhhmmC')
  
  path  = root_data_dir() + 'mex/aspera/ima/sav/' + time_string(ftime, tformat='YYYY/MM/')
  fname = prefix + lvl + '_' + time_string(ftime, tformat='YYYYMMDD_hhmm') + '.sav'

  asp_ima_stime = REFORM(time[*, 0])
  asp_ima_etime = REFORM(time[*, 1])
  asp_ima_polar = polar
  asp_ima_pacc  = pacc
  asp_ima_cnts  = counts
  asp_ima_hk    = hk
  asp_ima_file  = file

  file_mkdir2, path, dlevel=2, verbose=verbose
  dprint, dlevel=2, verbose=verbose, 'Saving ' + path + fname + '.'
  SAVE, filename=path + fname, asp_ima_stime, asp_ima_etime, asp_ima_polar, $
        asp_ima_pacc, asp_ima_cnts, asp_ima_hk, asp_ima_file
  RETURN
END
                    
PRO mex_asp_ima_com, time, counts, polar, pacc, hk, file=file, verbose=verbose, $
                     data=mex_asp3_ima, trange=trange

  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  units = 'counts'
  dt = 12.d0
  nenergy = 96
  nmass = 32
  nbins = 16

  stime = REFORM(time[*, 0])
  etime = REFORM(time[*, 1])

  hk_form = {smask: 0, hmask: 0, emode: 0, opidx: 0, swidx: 0, asum: 0, psum: 0, msum: 0}
  dformat = {units_name: units, time: 0.d0, end_time: 0.d0, $
             energy: DBLARR(nenergy, nbins, nmass), enoise: DBLARR(nenergy, nbins, nmass), $
             theta: FLTARR(nenergy, nbins, nmass), data: FLTARR(nenergy, nbins, nmass),    $
             bkg: FLTARR(nenergy, nbins, nmass),    $
             polar: 0, pacc: 0, hk: hk_form}
             

  ndat = N_ELEMENTS(stime)
  mex_asp_ima = REPLICATE(dformat, ndat)

  mex_asp_ima.time     = stime
  mex_asp_ima.end_time = etime
  mex_asp_ima.polar    = polar
  mex_asp_ima.pacc     = pacc
  mex_asp_ima.data     = TRANSPOSE(counts, [1, 2, 3, 0])
  mex_asp_ima.hk       = hk

  time = MEAN(time, dim=2)
  mex_asp_ima_ene_theta, time, polar, opidx=hk.opidx, verbose=verbose, energy=energy, theta=theta, enoise=enoise
  mex_asp_ima.energy = energy
  mex_asp_ima.theta  = theta
  mex_asp_ima.enoise = enoise

  mex_asp_ima_bkg, verbose=verbose
  IF SIZE(trange, /type) NE 0 THEN BEGIN
     w = WHERE(time GE trange[0] AND time LE trange[1], nw)
     mex_asp_ima = mex_asp_ima[w]
  ENDIF

  mex_asp3_ima = mex_asp_ima
  RETURN
END

PRO mex_asp_ima_read, trange, verbose=verbose, time=stime, end_time=etime, counts=counts, polar=polar, pacc=pacc, $
                      hk=hk, save=save, file=remote_file, mtime=modify_time, status=status, no_server=no_server
  nan = !values.f_nan
  status = 1
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))

  ldir = root_data_dir() + 'mex/aspera/ima/csv/' 
  spath = ldir + time_string(date, tformat='YYYY/MM/')
  
  FOR i=0, N_ELEMENTS(date)-1 DO BEGIN
     afile = FILE_SEARCH(spath[i], 'IMA_AZ*' + time_string(date[i], tformat='YYYYDOY') + '*.CSV', count=nfile)
     IF nfile GT 0 THEN append_array, file, afile
     undefine, afile, nfile
  ENDFOR 
  
  IF (nflg) THEN mex_asp_ima_timestamp, remote_file, rtime, verbose=verbose, /csv, /uniq
  IF SIZE(file, /type) EQ 0 THEN rflg = 1 $
  ELSE BEGIN
     mex_asp_ima_timestamp, file, ltime, verbose=verbose, /csv, /uniq
     IF (nflg) THEN IF (N_ELEMENTS(rtime) EQ N_ELEMENTS(ltime)) AND (compare_struct(rtime, ltime) EQ 1) THEN rflg = 0 ELSE rflg = 1 ELSE rflg = 0
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
           suffix = time_string(time_double(suffix[1], tformat='AZ**YYYYDOYhhmmC'), tformat='YYYY/MM/')
           append_array, fname, spd_download(remote_file=remote_file[i], local_path=ldir+suffix, ftp_connection_mode=0)
           file_touch, fname[-1], modify_time[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE append_array, fname, file[w]
     ENDFOR
  ENDIF ELSE fname = file

  IF N_ELEMENTS(fname) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF 

  mex_asp_ima_timestamp, fname, ftime, /csv, /uniq
  nfile = N_ELEMENTS(ftime)

  counts = list()
  stime = list()
  etime = list()
  polar = list()
  pacc  = list()

  ;smask ; Shadow Mask
  ;hmask ; High Voltage Mask
  ;opidx ; Operational Index
  ;swidx ; Solar Wind Start Index
  ;asum  ; Azimuth Sum Mode
  ;psum  ; Polar Angle Sum Mode
  ;emode ; Energy Cycle Mode
  ;msum  ; Mass Channel Sum Mode

  hk = list()
  hk_format = {smask: 0, hmask: 0, emode: 0, opidx: 0, swidx: 0, asum: 0, psum: 0, msum: 0}
  undefine, file
  files = list()
  FOR i=0, nfile-1 DO BEGIN
     cnts = list()
     FOR j=0, 15 DO BEGIN
        idx = WHERE(STRMATCH(FILE_BASENAME(fname), 'IMA_AZ' + STRING(j, '(I2.2)') + time_string(ftime[i], tformat='YYYYDOYhhmm') + '*.CSV') EQ 1)

        OPENR, unit, fname[idx], /get_lun
        data = STRARR(FILE_LINES(fname[idx]))
        READF, unit, data
        FREE_LUN, unit
        
        IF j EQ 0 THEN BEGIN
           v = WHERE(STRMATCH(data, '*Polar Angle Index*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              IF (trange[0] GT time_double(mode[-1, 1], tformat='YYYY-DOYThh:mm:ss.fff')) OR $
                 (trange[1] LT time_double(mode[ 0, 0], tformat='YYYY-DOYThh:mm:ss.fff')) THEN GOTO, next $
              ELSE dprint, dlevel=2, verbose=verbose, 'Reading ' + FILE_DIRNAME(fname[idx], /mark) + $
                           'IMA_AZ**' + time_string(ftime[i], tformat='YYYYDOYhhmm') + 'C_ACCS01.CSV.'

              polar.add, FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*PACC Index*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              pacc.add, FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Shadow Mask*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add = REPLICATE(hk_format, nv)
              hk_add.smask = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*High Voltage Mask*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.hmask = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Operational Index*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.opidx = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Solar Wind Start Index*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.swidx = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Azimuth Sum Mode*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.asum = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Polar Angle Sum Mode*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.psum = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Energy Cycle Mode*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.emode = FIX(mode[*, -1])
           ENDIF 
           v = WHERE(STRMATCH(data, '*Mass Channel Sum Mode*') EQ 1, nv)
           IF nv GT 0 THEN BEGIN
              mode = STRSPLIT(data[v], ',', /extract)
              mode = mode.toarray()
              hk_add.msum = FIX(mode[*, -1])
           ENDIF 
           undefine, mode
           hk.add, TEMPORARY(hk_add)
           ndat = nv
        ENDIF 

        append_array, file, fname[idx]
        w = WHERE(STRMATCH(data, '*SENSOR*') EQ 1, nw)
        IF nw GT 0 THEN BEGIN
           sensor = STRSPLIT(data[w], ',', /extract)
           sensor = sensor.toarray()

           data = sensor[*, 6:*]
           cnt = list()
           
           IF j EQ 0 THEN BEGIN
              nenergy = N_ELEMENTS(data[0, *])
              undefine, st, et
              st  = list()
              et  = list()
           ENDIF 

           FOR k=0L, ndat-1L DO BEGIN
              cnt.add, FLOAT(data[32L*k:32L*k+31L, *])
              IF j EQ 0 THEN BEGIN
                 st.add, time_double(sensor[31L*k, 0], tformat='YYYY-DOYThh:mm:ss.fff')
                 et.add, time_double(sensor[31L*k, 1], tformat='YYYY-DOYThh:mm:ss.fff')
              ENDIF 
           ENDFOR 
           
           IF j EQ 0 THEN BEGIN
              stime.add, st.toarray()
              etime.add, et.toarray()
           ENDIF 
           cnts.add, cnt.toarray()
        ENDIF 
        undefine, w, nw, v, nv
        undefine, sensor, data, idx, cnt
     ENDFOR 
     cnts = TRANSPOSE(cnts.toarray(), [1, 3, 0, 2]) ; time, energy, angle, mass
     IF nenergy NE 96 THEN BEGIN
        sz = SIZE(cnts)
        cnt = FLTARR(sz[1], 96, sz[3], sz[4])
        cnt[*] = nan
        cnt[*, 0:nenergy-1, *, *] = TEMPORARY(cnts)
        cnts = TEMPORARY(cnt)
        undefine, sz
     ENDIF 
     counts.add, cnts
     files.add, TEMPORARY(file)
     next:
  ENDFOR 

  IF KEYWORD_SET(save) THEN $
     FOR i=0, N_ELEMENTS(files)-1 DO $
        mex_asp_ima_save, [ [stime[i]], [etime[i]] ], counts[i], polar[i], pacc[i], hk[i], $
                          file=files[i], verbose=verbose

  RETURN
END

PRO mex_asp_ima_timestamp, files, time, verbose=verbose, csv=csv, sav=sav, unique=unique
  file = FILE_BASENAME(files)
  time = STRSPLIT(file, '_', /extract)
  IF SIZE(time, /type) NE 7 THEN lflg = 1 ELSE lflg = 0
  IF KEYWORD_SET(unique) THEN uflg = 1 ELSE uflg = 0
  IF (lflg) THEN time = time.toarray()

  IF KEYWORD_SET(csv) THEN BEGIN
     IF (lflg) THEN time = time[*, 1] ELSE time = time[1]
     time = time_double(time, tformat='AZ**YYYYDOYhhmmC')
  ENDIF 

  IF KEYWORD_SET(sav) THEN BEGIN
     IF (lflg) THEN time = time[*, 4] + time[*, 5] ELSE time = time[4] + time[5]
     time = time_double(time, tformat='YYYYMMDDhhmm.sav')
  ENDIF 
  
  IF (uflg) THEN time = time[UNIQ(time, sort(time))]
  RETURN
END

FUNCTION mex_asp_ima_toarray, data
  ndat = N_ELEMENTS(data)
  hk = list()
  FOR i=0, ndat-1 DO hk.add, data[i], /extract
  hk = hk.toarray()
  RETURN, hk
END

PRO mex_asp_ima_load, trange, verbose=verbose, save=save, no_server=no_server, bkg=bkg
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  undefine, mex_asp_ima
  t0 = SYSTIME(/sec)
  IF SIZE(trange, /type) EQ 0 THEN get_timespan, trange
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  IF KEYWORD_SET(bkg) THEN bflg = 1 ELSE bflg = 0
  lvl = 'l1b'

  IF (nflg) THEN BEGIN
     mex_asp_ima_list, trange, verbose=verbose, file=remote_file, time=mtime
     IF N_ELEMENTS(remote_file) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF 
     mex_asp_ima_timestamp, remote_file, rtime, verbose=verbose, /csv, /uniq
  ENDIF 

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  path = root_data_dir() + 'mex/aspera/ima/sav/' + time_string(date, tformat='YYYY/MM/') + $
         'mex_asp_ima_*' + time_string(date, tformat='YYYYMMDD') + '*.sav'

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
     mex_asp_ima_read, trange, time=stime, end_time=etime, counts=counts, polar=polar, pacc=pacc, hk=hk, $
                       verbose=verbose, save=save, file=remote_file, mtime=mtime, status=status, no_server=no_server
     IF (status EQ 0) THEN RETURN
  ENDIF ELSE BEGIN
     stime  = list()
     etime  = list()
     counts = list()
     polar  = list()
     pacc   = list()
     hk     = list()
     FOR i=0, N_ELEMENTS(file)-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Restoring ' + file[i] + '.'
        obj = OBJ_NEW('IDL_Savefile', file[i])
        vname = obj -> Names()
        v = WHERE(STRMATCH(vname, '*FILE') EQ 0)
        obj -> Restore, vname[v]
        stime.add,  TEMPORARY(asp_ima_stime)
        etime.add,  TEMPORARY(asp_ima_etime)
        counts.add, TEMPORARY(asp_ima_cnts)
        polar.add,  TEMPORARY(asp_ima_polar)
        pacc.add,   TEMPORARY(asp_ima_pacc)
        hk.add,     TEMPORARY(asp_ima_hk)
        undefine, obj, vname, v
     ENDFOR 
  ENDELSE 

  counts = counts.toarray(dim=1)
  stime  = stime.toarray(dim=1)
  etime  = etime.toarray(dim=1)
  polar  = polar.toarray(dim=1)
  pacc   = pacc.toarray(dim=1)
  hk     = mex_asp_ima_toarray(hk)

  time = [ [stime], [etime] ]
  time = MEAN(time, dim=2)
  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found.'
     RETURN
  ENDIF ELSE BEGIN
     mex_asp_ima_com, [ [stime], [etime] ], counts, polar, pacc, hk, data=ima, trange=trange
     time = time[w]
     IF (bflg) THEN cnt = (ima.data - ima.bkg) > 0. ELSE cnt = ima.data
     ene  = ima.energy
  ENDELSE 

  store_data, 'mex_asp_ima_espec', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnt, 2), 2)), v: TRANSPOSE(MEAN(MEAN(ene, dim=2, /nan), dim=2, /nan))}, $
              dlim={spec: 1, datagap: 30.d0, ysubtitle: 'Energy [eV]', ytitle: 'MEX/ASPERA-3 (IMA)'} ;, $
                                ;ytickformat: 'exponent', ztickformat: 'exponent}
  ylim, 'mex_asp_ima_espec', 1., 30.e3, 1, /def
  zlim, 'mex_asp_ima_espec', 1., 1000., 1, /def
  options, 'mex_asp_ima_espec', ztitle='Counts [#]', /def
  
  dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
