;+
; PRO erg_load_pwe_ofa
;
; The read program for Level-2 PWE/OFA data 
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only 'spec' is
;   acceptable. (For futrue, 'matrix' and 'complex' are prepared.)
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
;   IDL> erg_load_pwe_ofa
;   IDL> erg_load_ofa, datatype='spec'
;
; :Authors:
;   Masafumi Shoji, ERG Science Center (E-mail: masafumi.shoji at nagoya-u.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
; $LastChangedRevision: 25628 $
; $URL:
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/mep/erg_load_pwe_ofa.pro $
;-

pro erg_load_pwe_ofa, $
   level=level, $
   datatype=datatype, $
   trange=trange, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   get_support_data = get_support_data, $
   verbose=verbose, $
   uname=uname, $
   passwd=passwd, $
   _extra=_extra

  erg_init
  
  if ~keyword_set(level) then level='l2' ;; level='l1_prime'
  if ~keyword_set(datatype) then datatype='spec'
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

  if ~strcmp(datatype, 'spec') and ~strcmp(datatype, 'matrix') and ~strcmp(datatype, 'complex') then begin
     print, 'Keyword datatype accepts only "spec", "matrix" and "complex".'
     return
  endif
     
  remotedir=!erg.remote_data_dir+'satellite/erg/pwe/ofa/'+level+'/'+datatype+'/'
  localdir = !erg.local_data_dir + 'satellite/erg/pwe/ofa/'+level+'/'+datatype+'/'

  if strcmp(level,'l2') then begin
     relfpathfmt = 'YYYY/MM/erg_pwe_ofa_' + level+'_'+datatype+'_YYYYMMDD_v??_??.cdf' ;;real
  endif else begin
     relfpathfmt = 'YYYY/erg_pwe_ofa_' + level + '_YYYYMMDD_v??.cdf'
  endelse

  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  files=spd_download(remote_file=relfpaths,remote_path = remotedir,local_path=localdir,no_download=no_download,$
                     _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
     datfiles=files[where(filestest eq 1)]
  endif else return

  
 ; stop

  prefix = 'erg_pwe_ofa_'+datatype+'_'+level+'_'
  if ~downloadonly then $
     cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
                verbose = verbose
  

  if strcmp(datatype, 'spec') then begin
     
     zlim, prefix+['E_spectra_*'], 1e-9, 1e-2, 1
     zlim, prefix+['B_spectra_*'], 1e-4, 1e2, 1
     options, prefix+['E_spectra_*'], 'datagap', 8.
     options, prefix+['B_spectra_*'], 'datagap', 8.
     
     
     if strcmp(tnames(prefix+['E_spectra_66']),'') and strcmp(tnames(prefix+['E_spectra_132']),'') and $
        strcmp(tnames(prefix+['E_spectra_264']),'') and strcmp(tnames(prefix+['E_spectra_528']),'') then begin
        
        print, 'No varid OFA spectra data is loaded.'
        goto, gt1
     endif else begin    
        store_data, prefix+'E_spectra_merged', data=[tnames(prefix+['E_spectra_66','E_spectra_132','E_spectra_264','E_spectra_528'])]
        store_data, prefix+'B_spectra_merged', data=[tnames(prefix+['B_spectra_66','B_spectra_132','B_spectra_264','B_spectra_528'])]
     endelse
     
;   stop
     
     ylim, prefix+'E_spectra_*', 32e-3, 20., 1
     ylim, prefix+'B_spectra_*', 32e-3, 20., 1
     options, prefix+['E_spectra_*'], 'ytitle', 'ERG PWE/OFA-SPEC (E)'
     options, prefix+['B_spectra_*'], 'ytitle', 'ERG PWE/OFA-SPEC (B)'
     options, ['*_spectra_*'], 'ysubtitle', 'frequency [kHz]'
     options, prefix+'E_spectra_*', 'ztitle', 'mV^2/m^2/Hz'
     options, prefix+'B_spectra_*', 'ztitle', 'pT^2/Hz'
     
  endif else begin
     zlim, prefix+'Etotal_*', 1e-9, 1e-2, 1
     zlim, prefix+'Btotal_*', 1e-4, 1e2, 1
     ylim, prefix+'Etotal_*', 32e-3, 20., 1
     ylim, prefix+'Btotal_*', 32e-3, 20., 1
  endelse
  
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
   
  
   gt1:
   
END
