;+
;
;PROCEDURE:       VEX_ASP_SWM_LOAD
;
;PURPOSE:         
;                 Loads VEX/ASPERA-4 (IMA) solar wind ion moment data from ESA/PSA.
;                 Results are stored as tplot variables.
;
;INPUTS:          Time range to be loaded (but it is optional).
;
;KEYWORDS:
;
; NO_SERVER:      If set, prevents any contact with the remote server.
;
; NO_DOWNLOAD:    Synonym for NO_SERVER.
;
;CREATED BY:      Takuya Hara on 2019-06-26.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2019-06-26 14:35:42 -0700 (Wed, 26 Jun 2019) $
; $LastChangedRevision: 27382 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_swm_load.pro $
;
;-
PRO vex_asp_swm_load, itime, verbose=verbose, no_download=no_download, no_server=no_server
  t0 = SYSTIME(/sec)

  IF SIZE(itime, /type) NE 0 THEN BEGIN
     trange = itime
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDIF 

  IF KEYWORD_SET(no_server) THEN nflg = 0
  IF KEYWORD_SET(no_download) THEN nflg = 0
  IF SIZE(nflg, /type) EQ 0 THEN nflg = 1

  ldir  = root_data_dir() + 'vex/aspera/ima/swm/'
  lfile = 'ASP4_IMA_SWM.TAB'

  IF FILE_TEST(ldir + lfile) EQ 0 THEN nflg = 1

  IF (nflg) THEN BEGIN
     file_mkdir2, ldir

     dprint, dlevel=2, verbose=verbose, 'Starts connecting ESA/PSA FTP server...'
     
     rdir = 'ftp://psa.esac.esa.int/pub/mirror/VENUS-EXPRESS/ASPERA4/VEX-SUN-ASPERA4-4-SWM-V1.0/DATA/'

     lists = spd_download(remote_path=rdir, remote_file='*', local_path=ldir, local_file='vex_asp_swm_lists.txt', ftp_connection_mode=0)
     OPENR, unit, lists, /get_lun
     text = STRARR(FILE_LINES(lists))
     READF, unit, text
     FREE_LUN, unit

     text = STRSPLIT(text, ' ', /extract)
     text = text.toarray()
     text[*, 6] = STRING(LONG(text[*, 6]), '(I2.2)')

     w = WHERE(STRMATCH(text[*, 7], '*:*'), nw)
     IF nw EQ 0 THEN mtime = time_double(text[*, 5] + text[*, 6] + text[*, 7], tformat='MTHDDYYYY') $
     ELSE BEGIN
        today = SYSTIME(/sec)
        year  = time_string(today, tformat='YYYY')
        mtime = time_double(text[*, 5] + text[*, 6] + text[*, 7] + year, tformat='MTHDDhh:mmYYYY')
        w = WHERE(mtime GT today, nw)
        IF nw GT 0 THEN BEGIN
           year = STRING(LONG(year) - 1, '(I4.4)')
           mtime = time_double(text[*, 5] + text[*, 6] + text[*, 7] + year, tformat='MTHDDhh:mmYYYY')
        ENDIF 
     ENDELSE 
     w = WHERE(text[*, -1] EQ lfile, nw)
     IF nw GT 0 THEN mtime = mtime[w]
     undefine, w, nw, text
     IF lists NE '' THEN FILE_DELETE, lists

     file = spd_download(remote_path=rdir, remote_file=lfile, local_path=ldir, ftp_connection_mode=0)
     file_touch, file, mtime - DOUBLE(time_zone_offset()) * 3600.d0, /mtime
  ENDIF ELSE file = ldir + lfile

  OPENR, unit, file, /get_lun
  text = STRARR(FILE_LINES(file))
  READF, unit, text
  FREE_LUN, unit

  text = STRSPLIT(text, ' ', /extract)
  text = text.toarray()

  time = time_double(text[*, 0], tformat='YYYY-MM-DDThh:mm:ss')

  IF SIZE(trange, /type) EQ 0 THEN w = INDGEN(N_ELEMENTS(time)) $
  ELSE BEGIN
     w = WHERE(time GE trange[0] AND time LE trange[1], nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'No data found in the specified time range.'
        RETURN
     ENDIF 
  ENDELSE 

  time = time[w]
  dens = DOUBLE(text[w, 1])
  vel  = DOUBLE(text[w, 2])
  temp = DOUBLE(text[w, 3])
  flag = LONG(text[w, 4]) ; quality flags

  store_data, 'vex_asp_nsw', data={x: time, y: dens}, dlim={ytitle: 'VEX', ysubtitle: 'Nsw [cm!E-3!N]'}
  store_data, 'vex_asp_vsw', data={x: time, y: vel},  dlim={ytitle: 'VEX', ysubtitle: 'Vsw [km/s]'}
  store_data, 'vex_asp_tsw', data={x: time, y: temp}, dlim={ytitle: 'VEX', ysubtitle: 'Tsw [K]'}
  store_data, 'vex_asp_qsw', data={x: time, y: flag}, $
              dlim={ytitle: 'VEX', ysubtitle: 'SWM!CFLAG', psym: 10, yrange: [-0.5, 5.5], panel_size: 0.5, ystyle: 1, ytickinterval: 1, yminor: 1}

  IF (nflg) THEN dprint, dlevel=2, verbose=verbose, 'Ellapsed time: ' + time_string(SYSTIME(/sec)-t0, tformat='mm:ss.fff')
  RETURN
END
