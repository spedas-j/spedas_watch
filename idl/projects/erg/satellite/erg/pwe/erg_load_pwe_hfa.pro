;+
; PRO erg_load_pwe_hfa
;
; The read program for PWE-HFA data
;
; :Keywords:
;   level: level of data products. Currently 'l2' and 'l3' are acceptable.
;   mode: 'l'/'low'=low, 'm'/'monit'/'monitor'=monitor, 'h'/'high'=high mode.
;         'a'/'all'=low & monitor & high modes.
;         If nothing, low & monitor modes are loaded and combined.
;   get_suuport_data: Set to load support data in CDF data files.
;   trange: Set a time range to load data explicitly for the specified
;           time range.
;   downloadonly: If set, data files are downloaded and the program
;                exits without generating tplot variables.
;   no_download: Set to prevent the program from searching in the
;                remote server for data files.
;   verbose:  Set to make some commands in this program verbose.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_pwe_hfa
;
; :Authors:
;   Masafumi Shoji ERG Science Center (E-mail: masafumi.shoji at
;   nagoya-u.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-09-04 15:57:53 -0700 (Tue, 04 Sep 2018) $
; $LastChangedRevision: 25725 $
; $URL:
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/pwe/erg_load_pwe_hfa.pro $
;-

pro erg_load_pwe_hfa, $
  level=level, $
  mode=mode, $
  trange=trange, $
  get_support_data = get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  uname=uname, $
  passwd=passwd, $
  _extra=_extra

  erg_init
  
  if ~keyword_set(level) then level='l2'
  if isa(level,'INT') then level='l'+string(level,format='(I0)')
  lvl=strlowcase(level)

  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then begin
    no_download = 0
;    if ~keyword_set(uname) then begin
;      uname=''
;      read, uname, prompt='Enter username: '
;    endif
     
;    if ~keyword_set(passwd) then begin
;      passwd=''
;      read, passwd, prompt='Enter passwd: '
;    endif
  endif

  if ~keyword_set(mode) then begin
    nmd=1
    imd=['low','monit']
  endif else begin
    if strcmp(mode[0],'a') or strcmp(mode[0],'all') then begin
      nmd=2
      imd=['low','monit','high']
    endif else begin
      nmd=n_elements(mode)-1
      imd=strarr(nmd+1)
      for j=0, nmd do begin
        if strcmp(mode[j],'l') or strcmp(mode[j],'low') then imd[j]='low'
        if strcmp(mode[j],'m') or strcmp(mode[j],'monit') or strcmp(mode[j],'monitor') then imd[j]='monit'
        if strcmp(mode[j],'h') or strcmp(mode[j],'high') then imd[j]='high'
      endfor
    endelse
  endelse

  if ~strcmp(lvl,'l2') then begin
    nmd=0
    imd=''
  endif

  for j=0, nmd do begin

  ;  remotedir = !erg.remote_data_dir+'satellite/erg/pwe/hfa/'+lvl+'/low/'
    remotedir = !erg.remote_data_dir+'satellite/erg/pwe/hfa/'+lvl+'/spec/'+imd[j]+'/'
  ;  localdir = root_data_dir() + 'ergsc/satellite/erg/pwe/hfa/'+lvl+'/'
  ;  localdir = !erg.local_data_dir + 'satellite/erg/pwe/hfa/'+lvl+'/low/'
    localdir = !erg.local_data_dir + 'satellite/erg/pwe/hfa/'+lvl+'/spec/'+imd[j]+'/'
  ;  localdir = './'+imd[j]+'/'
    
    if strcmp(lvl,'l2') then begin
      relfpathfmt = 'YYYY/MM/erg_pwe_hfa_' + lvl + '_spec_' + imd[j] + '_YYYYMMDD_v??_??.cdf' 
      prefix = 'erg_pwe_hfa_'+lvl+'_'+imd[j]+'_'
    endif else begin
      relfpathfmt = 'YYYY/MM/erg_pwe_hfa_' + lvl + '_YYYYMMDD_v??_??.cdf'
      prefix = 'erg_pwe_hfa_'+lvl+'_'
    endelse
      
    relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)

    files=spd_download(remote_file=relfpaths,remote_path = remotedir,local_path=localdir,no_download=no_download,$
                       _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
    filestest=file_test(files)

    if(total(filestest) ge 1) then begin
      datfiles=files[where(filestest eq 1)]
    endif else return

    if ~downloadonly then $
      cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
                 verbose = verbose

  endfor

  prefix = 'erg_pwe_hfa_'+lvl+'_'
  if strcmp(lvl,'l2') then begin
    com=['eu','ev','bgamma','esum', 'er', 'el', 'e_mix', 'e_ar', 'eu_ev', 'eu_bg', 'ev_bg']

;    if ~keyword_set(mode) then begin
;      for i=0, n_elements(com)-1 do begin
;        store_data, prefix+'spectra_'+com[i], data=[prefix+'low_'+'spectra_'+com[i], prefix+'monit_'+'spectra_'+com[i]]
;      endfor
;    endif

    if total(stregex(imd,'low',/boolean))+total(stregex(imd,'monit',/boolean)) ge 2 then begin
      for i=0, n_elements(com)-1 do begin
        store_data, prefix+'lm_spectra_'+com[i], data=[prefix+'low_spectra_'+com[i], prefix+'monit_spectra_'+com[i]]
      endfor
    endif 
    if total(stregex(imd,'low',/boolean))+total(stregex(imd,'high',/boolean)) ge 2 then begin
      for i=0, n_elements(com)-1 do begin
        store_data, prefix+'lh_spectra_'+com[i], data=[prefix+'low_spectra_'+com[i], prefix+'high_spectra_'+com[i]]
      endfor
    endif 

    for i=0, n_elements(com)-1 do begin                
      options, prefix+'*spectra_'+com[i], 'ytitle', 'ERG PWE/HFA ('+strupcase(com[i])+')'       
    endfor

    options, prefix+'*spectra_*',      'ysubtitle', 'frequency [kHz]'
    options, prefix+'*spectra_*',      'ytickformat', '(F10.0)'
    options, prefix+'*spectra_e*',     'ztitle', 'mV^2/m^2/Hz'
    options, prefix+'*spectra_bgamma', 'ztitle', 'pT^2/Hz'
    options, prefix+'*spectra_e_ar',   'ztitle', 'LH:-1/RH:+1'
    options, prefix+'*spectra_e*_bg',  'ztitle', 'mV/m pT/Hz'
    ylim,    prefix+'*spectra_e*',     2.0, 10000.0, 1
    ylim,    prefix+'*spectra_bgamma', 2.0, 200.0, 1
    zlim,    prefix+'*spectra_'+['eu','ev','esum','er','el','e_mix'], 1e-10, 1e-3, 1
    zlim,    prefix+'*spectra_bgamma', 1e-4, 1e2, 1
    zlim,    prefix+'*spectra_e_ar',   -1, 1, 0
    options, prefix+'*spectra_*',      'datagap', 70.

  endif else begin
    options, tnames(prefix+['Fuhr','ne_mgf']), 'datagap', 60.
  endelse
  
  gatt=cdf_var_atts(datfiles[0])
  
  print_str_maxlet, ' '
  print, '**************************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 75
  print, ''
  print, 'Information about ERG PWE HFA'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 75
  print, ''
  print, 'Rules of the Road for ERG PWE HFA Data Use:'
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 75
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**************************************************************************'
     
END