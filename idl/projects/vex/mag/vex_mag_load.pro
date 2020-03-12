;+
;
;PROCEDURE:       VEX_MAG_LOAD
;
;PURPOSE:         
;                 Loads the VEX/MAG data from ESA/PSA.
;                 Results are returned as tplot variables.
;                 The directory structure was modified from those of ESA/PSA. 
;
;INPUTS:          Time interval used in analyses.
;
;KEYWORDS:
;
;   POS:          If set, the spacecraft position data is also restored.
;
;   RESULT:       Returned the restored data as a structure.
;
;   L4:           If set, the 4 sec smoothed data will be restored.
;
;   DOUBLE:       Returned the data as a double style.
;
;   REMOVE_NAN:   If set, removing NANs. 
;
;   NO_SERVER:    If set, prevents any contact with the remote server.
;
;CREATED BY:      Takuya Hara on 2016-07-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-03-11 17:15:03 -0700 (Wed, 11 Mar 2020) $
; $LastChangedRevision: 28406 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/mag/vex_mag_load.pro $
;
;-
PRO vex_mag_list, trange, verbose=verbose, l4=l4, file=file, time=modify_time
  IF KEYWORD_SET(l4) THEN BEGIN
     lvl = '4'
     suffix = '_S004'
  ENDIF ELSE BEGIN
     lvl = '3'
     suffix = '_D001'
  ENDELSE 

  rpath = 'ftp://psa.esac.esa.int/pub/mirror/VENUS-EXPRESS/MAG/'

  mtime = ['2005-11', '2007-10-03', '2009-10-06', '2010-09-01', '2013']
  mtime = time_double(mtime)

  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, date)) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = 'EXT' + phase[v] + '-'
  undefine, w, nw

  pdir = 'VEX-V-Y-MAG-' + lvl + '-' + phase + 'V1.0/DATA/'
  ndat = N_ELEMENTS(date)

  ;cmd = 'wget --spider -N -r -nd -A "MAG_'
  ldir = root_data_dir() + 'vex/mag/'
  file_mkdir2, ldir, dlevel=2, verbose=verbose

  dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'
  FOR i=0, ndat-1 DO BEGIN
     IF date[i] GE time_double('2006-05-14') THEN subdir = 'ORB' + time_string(date[i], tformat='YYYYMM') $
     ELSE subdir = 'CAPTORBIT'
     ;SPAWN, cmd + time_string(date[i], tformat='YYYYMMDD') + '*.TAB" ' + rpath + pdir[i] +  subdir + suffix + '/ -o ' + ldir + 'vex_mag_lists.txt'
     cmd = rpath + pdir[i] + subdir + suffix + '/'

     dflg = 0
     IF SIZE(cmd_old, /type) EQ 0 THEN dflg = 1 $
     ELSE IF cmd NE cmd_old THEN dflg = 1
     IF (dflg) THEN list_file = spd_download(remote_path=cmd, remote_file='*', local_path=ldir, local_file='vex_mag_lists.txt', ftp_connection_mode=0)

     OPENR, unit, list_file, /get_lun
     text = STRARR(FILE_LINES(list_file))
     READF, unit, text
     FREE_LUN, unit

     text = STRSPLIT(text, ' ', /extract)
     text = text.toarray()
     
     text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')
     mod_time = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY')
     w = WHERE(STRMATCH(text[*, -1], 'MAG_' + time_string(date[i], tformat='YYYYMMDD_') + '*.TAB') EQ 1, nw)
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

PRO vex_mag_load, trange, verbose=verbose, pos=pos, result=result, l4=l4, double=double, remove_nan=remove_nan, no_server=no_server, no_download=no_download
  rv = 6052. ; Venus radius
  IF SIZE(pos, /type) EQ 0 THEN pflg = 0 ELSE pflg = FIX(pos)
  IF KEYWORD_SET(remove_nan) THEN rflg = 1 ELSE rflg = 0
  IF KEYWORD_SET(no_server) THEN nflg = 0 ELSE nflg = 1
  IF KEYWORD_SET(no_download) THEN nflg = 0 ELSE nflg = 1

  IF SIZE(l4, /type) EQ 0 THEN BEGIN
     lvl = 'l3'
     res = '1sec'
     dt = 1.d0
  ENDIF ELSE BEGIN
     lvl = 'l4'
     res = '4sec'
     dt = 4.d0
  ENDELSE 

  IF SIZE(trange, /type) EQ 0 THEN get_timespan, trange
  path = 'vex/mag/' + lvl + '/YYYY/MM/'
  fname = 'MAG_YYYYMMDD_*.TAB'
  files = file_retrieve(path + fname, local_data_dir=root_data_dir(), /no_server, trange=trange, /daily_res, /valid_only, /last)

  IF (nflg) THEN BEGIN
     vex_mag_list, trange, verbose=verbose, l4=l4, file=rfile, time=rtime 
     IF SIZE(rfile, /type) EQ 0 THEN BEGIN
        dprint, 'No data found.', dlevel=2, verbose=verbose
        RETURN
     ENDIF

     nfile = N_ELEMENTS(rfile)
     FOR i=0, nfile-1 DO BEGIN
        IF SIZE(files, /type) EQ 0 THEN dflg = 1 $
        ELSE BEGIN
           w = WHERE(STRMATCH(FILE_BASENAME(files), FILE_BASENAME(rfile[i])) EQ 1, nw)
           IF nw EQ 0 THEN dflg = 1 ELSE dflg = 0
        ENDELSE
        IF (dflg) THEN BEGIN
           suffix = FILE_BASENAME(rfile[i])
           suffix = STRSPLIT(suffix, '_', /extract)
           suffix = time_string(time_double(suffix[1], tformat='YYYYMMDD'), tformat='/YYYY/MM/')
           ldir = root_data_dir() + 'vex/mag/' + lvl + suffix
           append_array, file, spd_download(remote_file=rfile[i], local_path=ldir, ftp_connection_mode=0)
           file_touch, fname[-1], rtime[i] - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
        ENDIF ELSE append_array, file, files[w]
     ENDFOR
  ENDIF ELSE file = files

  w = WHERE(file NE '', nfile)
  IF nfile EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No file found.'
     RETURN
  ENDIF ELSE file = file[w]

  result = list()
  FOR i=0, nfile-1 DO BEGIN
     OPENR, unit, file[i], /get_lun
     adata = STRARR(FILE_LINES(file[i]))
     READF, unit, adata
     FREE_LUN, unit
     w = WHERE(STRMID(adata, 0, 4) EQ 'END ', nw)
     IF nw EQ 1 THEN BEGIN
        adata = adata[w+2:*]
        aresult = STRSPLIT(adata, ' ', /extract)
        aresult = aresult.toarray()

        result.add, aresult
        undefine, aresult
     ENDIF 
     undefine, w, nw, adata
  ENDFOR 
  
  data = TEMPORARY(result.toarray(dim=1))
  time = time_double(REFORM(data[*, 0]), tformat='YYYY-MM-DDThh:mm:ss.fff')
  undefine, result

  w = WHERE(time GE trange[0] AND time LE trange[1], nw)
  IF nw EQ 0 THEN BEGIN
     dprint, 'Data not found in the specified time range.', dlevel=2, verbose=verbose
     RETURN
  ENDIF 
  data = data[w, *]
  time = time[w]

  bx = FLOAT(REFORM(data[*, 1]))
  by = FLOAT(REFORM(data[*, 2]))
  bz = FLOAT(REFORM(data[*, 3]))
  btot = FLOAT(REFORM(data[*, 4]))

  IF KEYWORD_SET(double) THEN BEGIN
     bx = DOUBLE(bx)
     by = DOUBLE(by)
     bz = DOUBLE(bz)
     btot = DOUBLE(btot)
  ENDIF 

  store_data, 'vex_mag_' + lvl + '_bvso_' + res, $
              data={x: time, y: [ [bx], [by], [bz] ]}, dlim={ytitle: 'VEX MAG', ysubtitle: 'Bvso [nT]', colors: 'bgr', datagap: dt*1.5, $
                                                             labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, level: STRUPCASE(lvl)}
  store_data, 'vex_mag_' + lvl + '_btot_' + res, data={x: time, y: btot}, dlim={ytitle: 'VEX MAG', ysubtitle: '|B| [nT]', level: STRUPCASE(lvl), datagap: dt*1.5}

  tclip, 'vex_mag_' + lvl + '_bvso_' + res, -9999., +9999., /over
  tclip, 'vex_mag_' + lvl + '_btot_' + res, -9999., +9999., /over

  IF (rflg) THEN BEGIN
     get_data, 'vex_mag_' + lvl + '_btot_' + res, data=d, dl=dl, lim=lim
     w = WHERE(FINITE(d.y))
     store_data, 'vex_mag_' + lvl + '_btot_' + res, data={x: d.x[w], y: d.y[w]}, dl=dl, lim=lim

     get_data, 'vex_mag_' + lvl + '_bvso_' + res, data=d, dl=dl, lim=lim
     store_data, 'vex_mag_' + lvl + '_bvso_' + res, data={x: d.x[w], y: d.y[w, *]}, dl=dl, lim=lim
  ENDIF 
  result = {time: time, mag: [ [bx], [by], [bz] ]}
  IF (pflg) THEN BEGIN
     px = FLOAT(REFORM(data[*, 5]))
     py = FLOAT(REFORM(data[*, 6]))
     pz = FLOAT(REFORM(data[*, 7]))
     alt = FLOAT(REFORM(data[*, 8]))

     store_data, 'vex_eph_vso_' + res, data={x: time, y: ([ [px], [py], [pz] ])/rv}, $
                 dlim={ytitle: 'VEX POS', ysubtitle: 'VSO [Rv]', colors: 'bgr', $
                       labels: ['X', 'Y', 'Z'], labflag: -1, constant: 0, format: '(f0.2)'}
     store_data, 'vex_eph_alt_' + res, data={x: time, y: (alt-rv)}, dlim={ytitle: 'VEX', ysubtitle: 'Alt. [km]', ylog: 1}
     
     extract_tags, result, {pos: [ [px], [py], [pz] ], alt: alt}
  ENDIF 
  RETURN
END
