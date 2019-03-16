;+
; PRO erg_load_pwe_wfc
;
; The read program for Level-2 PWE/WFC data
;
; :Keywords:
;   level: level of data products. Currently only 'l2_prov' is
;   acceptable.
;   datatype: types of data products. Currently only 'spec' is
;   acceptable. (For futrue, 'waveform' prepared.)
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
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_pwe_wfc
;   IDL> erg_load_pwe_wfc, datatype='spec'
;
; :Authors:
;   Masafumi Shoji, ERG Science Center (E-mail: masafumi.shoji at
;   nagoya-u.jp)
;
; $LastChangedDate: 2019-03-15 12:52:35 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26822 $
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/pwe/erg_load_pwe_wfc.pro $
;-

pro erg_load_pwe_wfc, $
   component=component, $
   mode = mode, $
   datatype = datatype, $
   level=level, $
   trange=trange, $
   get_support_data = get_support_data, $
   verbose=verbose, $
   no_download=no_download, $
   downloadonly=downloadonly, $
   uname=uname, passwd=passwd, $
   _extra=_extra

  if undefined(component) then component='all'
  if undefined(level) then level='l2_prov' 
  if undefined(mode) then mode='65khz' ;; 'wp65khz'
  if undefined(datatype) then datatype = 'spec'

  if undefined(trange) then begin
     get_timespan, trange
  endif

  if undefined(downloadonly) then downloadonly = 0
  if undefined(no_download) then begin
     no_download = 0
     if ~keyword_set(uname) then begin
        uname=''
        read, uname, prompt='Enter username: '
     endif

     if ~keyword_set(passwd) then begin
        passwd=''
        read, passwd, prompt='Enter passwd: '
     endif
  endif


  if strcmp(level, 'l2_prov') or strcmp(level, 'l2p') or strcmp(level,'l2pre') then begin
     Lvl='l2pre'
  endif else Lvl=level

  erg_init

;  prefix = 'erg_pwe_wfc_'+level+'_'+mode+'_'

;  wfe=['E1', 'E2']+'_waveform'
;  wfb=['Balpha0', 'Bbeta0', 'Bgamma0']+'_waveform'

  wfe=['Ex','Ey']+'_waveform'
  wfb=['Bx','By','Bz']+'_waveform'

  if strcmp(datatype, 'spec') then begin
     wfe=['E']+'_spectra'
     wfb=['B']+'_spectra'
  endif

  if strcmp(component, 'all') then begin
     com=['e','b']
     eb=[wfe,wfb]
  endif else begin
     if strcmp(component, 'e') then begin
        com=['e']
        eb=[wfe]
     endif else begin
        if strcmp(component, 'b') then begin
           com=['b']
           eb=[wfb]
        endif else print, 'Illigal keyword set for "component". It only allows "all", "e", or "b".'
     endelse
  endelse

  prefix = 'erg_pwe_wfc_'+com+'_'+level+'_'+mode+'_'

  for i=0, n_elements(com)-1 do begin

     relfpathfmt = 'YYYY/MM/erg_pwe_wfc_'+com[i]+'_'+level+'_'+datatype+'_'+mode+'_YYYYMMDDhh_v??.cdf'
     relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times, /hour_res)

     localdir=!erg.local_data_dir+'satellite/erg/pwe/wfc/'+Lvl+'/'+datatype+'/'
     remotedir=!erg.remote_data_dir+'satellite/erg/pwe/wfc/'+Lvl+'/'+datatype+'/'

     files=spd_download(remote_file=relfpaths,remote_path = remotedir,local_path=localdir,no_download=no_download,$
                        _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
     filestest=file_test(files)

     if(total(filestest) ge 1) then begin
        datfiles=files[where(filestest eq 1)]
     endif else begin
        print, 'No file is loaded.'
        return
     endelse

     if ~keyword_set(downloadonly) then $
        cdf2tplot, datfiles, prefix = prefix[i], get_support_data = get_support_data, $
                   verbose = verbose $
     else return
     
  endfor


  if strcmp(datatype, 'spec') then begin     
     tn = prefix+eb
     ylim, tn, 32., 2e4, 1
     zlim, prefix[0]+wfE, 1e-9, 1e-2, 1
     zlim, prefix[1]+wfB, 1e-4, 1e2, 1
     options, tn, 'ysubtitle', '[Hz]'
     options, prefix[0]+wfE, 'ztitle', '[mV^2/m^2/Hz]'
     options, prefix[1]+wfB, 'ztitle', '[pT^2/Hz]'
     goto, gt1
  endif

  for x=0, n_elements(eb)-1 do begin

     tn = prefix+eb[x]

     if strcmp(tnames(tn),'') then begin
        print, 'error: A variable '+ tn + ' does not exist!'
        goto, gt0
     endif

     get_data, tn, data=data, dlim=dlim

     time1=data.x
     dt=data.v ;time_offsets

     delta=time1[1]-time1[0]
     nt=n_elements(time1)

     if keyword_set(trange) then begin
        
        trange=time_double(trange)
        
        if trange[1] - trange[0] le delta then begin
           yn=''
           read, yn, prompt='Invalid time range. Use full time range?: [y/n] '
           
           if strcmp(yn,'n') then return
                      
           it_start=0
           it_end=nt-1
           
        endif else begin
           it = where(time1 ge trange[0] and time1 le trange[1],nt)
           it_start = it[0]
           it_end = it[nt-1]
        endelse
        
     endif else begin
        it_start=0
        it_end=nt-1
     endelse
     
     ndt=n_elements(dt)
     
     ndata=nt*ndt
     
     time_new=dblarr(ndata)
     data_new=fltarr(ndata)

     for i=0, nt-1 do begin
        time_new[ndt*i:ndt*(i+1)-1]=time1[i+it_start]+dt[*]*1e-3
        data_new[ndt*i:ndt*(i+1)-1]=data.y[i+it_start,*]
     endfor

     store_data, tn, data={x:time_new, y:data_new}, dlim=dlim

     gt0:
  endfor
  
  
  gt1:

  gatt=cdf_var_atts(datfiles[0])

   print_str_maxlet, ' '
   print, '**********************************************************************'
   if strcmp(level, 'l2_prov') then begin
      print, 'Information about ERG PWE/WFC-SPEC Provisional CDF'
   endif else begin
      print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 80
   endelse
   print, ''
   print, 'Information about ERG PWE WFC'
   print, ''
   print, 'PI: ', gatt.PI_NAME
   print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 80
   print, ''
   print, 'Rules of the Road for ERG PWE WFC Data Use:'
   for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 80
   print, ''
   print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
   print, '**********************************************************************'

END
