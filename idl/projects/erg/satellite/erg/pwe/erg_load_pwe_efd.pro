;+
; PRO erg_load_pwe_efd
;
; The read program for Level-2 PWE/EFD data
; This program can run on IDL 8.0 or later version.
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   mode: types of data products. Currently only 'E_spin' is
;   acceptable. 
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
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
;   IDL> erg_load_pwe_efd
;   IDL> erg_load_efd, datatype='E_spin'
;
; :Authors:
;   Masafumi Shoji, ERG Science Center (E-mail: masafumi.shoji at
;   nagoya-u.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
; $LastChangedRevision: 25628 $
; $URL:
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/pwe/erg_load_pwe_efd.pro $
;-



pro erg_load_pwe_efd, $
   mode=mode, level = level, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   get_support_data=get_support_data, $
   verbose=verbose, $
   uname=uname, $
   passwd=passwd, $
   _extra=_extra  
  
  erg_init

  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then begin
     no_download = 0
;     if ~keyword_set(uname) then begin
;        uname=''
;        read, uname, prompt='Enter username: '
;     endif
;
;     if ~keyword_set(passwd) then begin
;        passwd=''
;        read, passwd, prompt='Enter passwd: '
;     endif
  endif

  if ~keyword_set(level) then begin 
     level='l2'
  endif

  if isa(level, 'INT') then begin
     level=strcompress('l'+string(level), /remove_all)
  endif

  if ~keyword_set(mode) then mode='E_spin'

  case level of

     'l2': begin
        Lvl = 'L2'
        prefix='erg_pwe_efd_l2_'        
     end

     'l3': begin
        Lvl = 'L3'
        prefix='erg_pwe_efd_l3_'
     end
     
     else: begin
        dprint, 'Incorrect keyword setting: level'
        return
     end
     
  endcase
  
  case mode of
     'E_spin': begin
        md='E_spin'
        component=['Eu','Ev','Eu1','Ev1','Eu2','Ev2']
        labels=['Ex', 'Ey']
     end
     'spin': begin
        md='E_spin'
        component=['Eu','Ev','Eu1','Ev1','Eu2','Ev2']
        labels=['Ex', 'Ey']
     end
     'spec': begin
        md='SPEC'
     end
     '64': begin
        md='E64Hz'
        component=['Eu_waveform_64HZ', 'Ev_waveform_64HZ']
     end
     '256': begin
        md='E256Hz'
        component=['Eu_waveform_256HZ', 'Ev_waveform_256HZ']
     end
     'pot': begin
        md='pot'
        component=['Vu1','Vu2','Vv1','Vv2', 'Vave']
     end

     else: begin
        dprint, 'Incorrect keyword setting: mode'
        return
     end

  endcase

  localdir=!erg.local_data_dir+'satellite/erg/pwe/efd/'+level+'/'+md+'/'
  remotedir=!erg.remote_data_dir+'satellite/erg/pwe/efd/'+level+'/'+md+'/'

  relfpathfmt= 'YYYY/'+'MM/' + 'erg_pwe_efd_'+level+'_'+md+'_YYYYMMDD_v??_??.cdf'
  relfpaths=file_dailynames(file_format=relfpathfmt)
  files=spd_download(remote_file=relfpaths,remote_path = remotedir,local_path=localdir,no_download=no_download,$
                     _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)

;  stop

  filestest=file_test(files)

;  net_obj = obj_new('idlneturl')
;  net_obj->getproperty, response_code=response_code

;  stop
  
  if(total(filestest) ge 1) then begin
     datfiles=files[where(filestest eq 1)]
  endif else begin
     print, 'No file is loaded.'
     return
  endelse

  if keyword_set(downloadonly) then return
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data

;  if strcmp(level,'l2') or strcmp(level,'l3') then return

  if strcmp(md,'E_spin') then begin
     foreach elem, component do $
        options, prefix+elem+'_dsi', labels=labels, ytitle=elem+' vector in DSI', constant=0
     goto, gt0
;     return
  endif

  if strcmp(md,'pot') then begin
     foreach elem, component do $
        options, prefix+elem, labels=labels, ytitle=elem+' potential', constant=0
     goto, gt0
;     return
  endif


  if strcmp(md,'SPEC') then begin

     zlim, 'erg_pwe_efd_l2_E_spectra', 1e-4, 1e-1
     ylim, 'erg_pwe_efd_l2_E_spectra', 0,250

     goto, gt0
;     return

  endif

  foreach elem, component do begin
     
     get_data, prefix+elem, data=data, dlim=dlim

     time1=data.x
     dt=data.v;time offsets
     delta=time1[1]-time1[0]
     nt=n_elements(time1)

     ndt=n_elements(dt)
     
     ndata=nt*ndt

     time_new=dblarr(ndata)
     data_new=fltarr(ndata)

     for i=0, nt-1 do begin
        time_new[ndt*i:ndt*(i+1)-1]=time1[i]+dt[*]*1e-3
        data_new[ndt*i:ndt*(i+1)-1]=data.y[i,*]
     endfor

     store_data, prefix+elem, data={x:time_new, y:data_new}, dlim=dlim

  end

  gt0:

  gatt=cdf_var_atts(datfiles[0])
  
  print_str_maxlet, ' '
  print, '**********************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 80
  print, ''
  print, 'Information about ERG PWE OFA'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 80
  print, ''
  print, 'Rules of the Road for ERG PWE OFA Data Use:'
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 80
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**********************************************************************'

END
