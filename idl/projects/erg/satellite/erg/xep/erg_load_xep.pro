;+
; PRO  erg_load_xep
;
; :Description:
;    The data read script for ERG/XEP data.
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: Data type to be loaded. Currently "omniflux" is acceptable.
;   trange: If a time range is set, timespan is executed with it at the end of this program
;   /get_support_data, load support_data variables as well as data variables into tplot variables.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   verbose:  Set to make some commands in this program verbose.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extracted as tplot variables.
;   localdir: Set a local directory path to save data files in the
;             designated directory.
;   remotedir: Set a remote directory in the URL form where the
;              program will look for data files to download.
;   datafpath: If set a full file path of CDF file(s), then the
;              program loads data from the designated CDF file(s), ignoring any
;              other options specifying local/remote data paths.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_xep
;   IDL> erg_load_xep, datatype='omniflux'
;
; :History:
; 2016/02/01: first protetype
; 2018/08/01: modified to load omni-directional XEP data
;
; :Author:
;   Y. Miyashita, ERG Science Center, ISEE, Nagoya Univ. (erg-sc-core at isee.nagoya-u.ac.jp)
;   M. Teramoto, ERG Science Center, ISEE, Nagoya Univ.
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
; $LastChangedRevision: 25628 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/xep/erg_load_xep.pro $
;-
pro erg_load_xep, $
  debug=debug, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  varformat=varformat,$
  localdir=localdir, $
  remotedir=remotedir, $
  datafpath=datafpath, $
  uname=uname, passwd=passwd

  ;Initialize the system variable for ERG
  erg_init

  ;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then lvl = 'l2'
  if ~keyword_set(datatype) then datatype = 'omniflux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0
  if ~keyword_set(varformat) then varformat='*'
  ;Local and remote data file paths

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir =    !erg.local_data_dir      + 'satellite/erg/xep/'+lvl+'/' +datatype+'/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/xep/'+lvl+'/'+datatype+'/'
  endif

  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;Relative file path
  relfpathfmt = 'YYYY/MM/erg_xep_' + lvl + '_' +datatype + '_' + 'YYYYMMDD_v??_??.cdf'

  ;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths

  ;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
      spd_download( remote_file = relfpaths, $
      remote_path = remotedir, local_path = localdir, /last_version,$
      url_username=uname, url_password=passwd,no_download=no_download)
  endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
    print, 'Cannot find any data file. Exit!'
    return
  endif
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set

  ;Read CDF files and generate tplot variables
  prefix = 'erg_xep_'+lvl+'_'
  cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
    verbose = verbose, varformat=varformat

  if tnames(prefix+'FEDO_SSD') eq '' then begin
    dprintf, prefix+'Failed loading FEDO_SSD data! Exit.'
    return
  endif


  get_data,prefix+'FEDO_SSD',data=fedo,dl=dl,lim=lim
  new_v=fltarr(n_elements(fedo.v(0,*)))
  for ik=0, n_elements(fedo.v(0,*))-1 do $
    new_v[ik]=sqrt(fedo.v(0,ik)*fedo.v(1,ik))
  store_data,prefix+'FEDO_SSD',data={x:fedo.x,y:fedo.y,v:new_v},$
    dl=dl,lim=lim
  tclip,prefix+'FEDO_SSD',0.05,2.0e5,/over
  options,prefix+'FEDO_SSD',labels=strcompress(string(new_v,format='(I4.4)')+' keV'),$
    labflag=-1,ylog=1,zlog=1, ztickformat='pwr10tick',ytitle='ERG XEP!CFEDO_SSD',ysubtitle='Energy [keV]',$
    ztitle='[/cm!U2!N-str-s-keV]'
  ylim,prefix+'FEDO_SSD',450,5000

  ;--- print PI info and rules of the road
  gatt=dl.cdf.gatt

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, gatt.PROJECT
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG XEP'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
  print, ''
  print_str_maxlet, gatt.LINK_TEXT+' '+ gatt.HTTP_LINK[0]+' '+gatt.HTTP_LINK[1],70
  print, '**********************************************************************'
  print, ''

  return
end
