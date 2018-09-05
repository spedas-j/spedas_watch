;+
; PRO erg_load_mepi_nml
;
; The read program for Level-2 MEP-i Normal mode data
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only 'omniflux' and '3dflux' are acceptable.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extracted as tplot variables.
;   get_suuport_data: Set to load support data in CDF data files.
;                     (e.g., spin_phase, mode_reduction)
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
;   localdir: Set a local directory path to save data files in the
;             designated directory.
;   remotedir: Set a remote directory in the URL form where the
;              program will look for data files to download.
;   datafpath: If set a full file path of CDF file(s), then the
;              program loads data from the designated CDF file(s), ignoring any
;              other options specifying local/remote data paths. 
;   split_anode: Set to generate a F?DU tplot variable for each anode separately
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_mepi_nml, uname='?????', pass='?????'
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-09-04 15:57:53 -0700 (Tue, 04 Sep 2018) $
; $LastChangedRevision: 25725 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/mep/erg_load_mepi_nml.pro $
;-
pro erg_load_mepi_nml, $
   debug=debug, $
   level=level, $
   datatype=datatype, $
   varformat=varformat, $
   get_support_data=get_support_data, $
   trange=trange, $
   downloadonly=downloadonly, no_download=no_download, $
   verbose=verbose, $
   uname=uname, passwd=passwd, $
   localdir=localdir, $
   remotedir=remotedir, $
   datafpath=datafpath, $
   split_anode=split_anode, $
   _extra=_extra 

  
  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then level = 'l2'
  if ~keyword_set(datatype) then datatype = 'omniflux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0

  
  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/mepi/' $
               + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/mepi/' $
                + level + '/' + datatype + '/'
  endif
  
  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  cdffn_prefix = 'erg_mepi_'+level+'_'+datatype+'_'
  relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v??_??.cdf'
  
  ;;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths
  
  ;;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
       spd_download( local_path=localdir $
                   , remote_path=remotedir, remote_file=relfpaths $
                   , no_download=no_download, /last_version $
                     , url_username=uname, url_password=passwd $
                 )
  endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
    print, 'Cannot find any data file. Exit!'
    return
  endif
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set

  ;;Species to be loaded
  spcs = strsplit(/ext, 'P HE2 HE OPP O O2P' )
   
  ;;Read CDF files and generate tplot variables
  prefix = 'erg_mepi_' + level + '_' + datatype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose

  ;;Options for F?DO tplot variables
  if strcmp( datatype[0], 'omniflux' ) then begin

    vns_fido = [ 'FPDO', 'FHE2DO', 'FHEDO', 'FOPPDO', 'FODO', 'FO2PDO' ] 
    for i=0, n_elements(vns_fido)-1 do begin
      vn_fido = prefix+vns_fido[i]
      if tnames(vn_fido) eq '' then continue

      options, vn_fido, $
               spec=1, ysubtitle='[keV/q]', ztickformat='pwr10tick', extend_y_edges=1, $
               datagap=17., zticklen=-0.4
      get_data, vn_fido, dl=dl
      options, vn_fido, $
               ztitle='['+dl.cdf.vatt.units+']', ytitle='ERG!CMEP-i/NML!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
      ylim, vn_fido, 4., 190., 1
      zlim, vn_fido, 0, 0, 1
    endfor
    
    
  endif else begin ;; for 3-D flux data
      
    ;;Options for tplot variables
    vns_fidu = [ 'FPDU', 'FHE2DU', 'FHEDU', 'FOPPDU', 'FODU', 'FO2PDU' ] 
    vns_fiedu = [ 'FPEDU', 'FHE2EDU', 'FHEEDU', 'FOPPEDU', 'FOEDU', 'FO2PEDU' ]
    vns_cnt = 'count_raw_' + strsplit(/ext, 'P HE2 HE OPP O O2P' )
    
    vns = prefix + [ vns_fidu, vns_fiedu, vns_cnt ]  ;;common to flux/count arrays
    vns = tnames(vns) & if vns[0] eq '' then return
    
    options, vns, spec=1, ysubtitle='[keV/q]', ztickformat='pwr10tick', extend_y_edges=1, $
             datagap=17., zticklen=-0.4
    for i=0, n_elements(vns)-1 do begin
      if tnames(vns[i]) eq '' then continue
      get_data, vns[i], data=data, dl=dl, lim=lim
      store_data, vns[i], data={x:data.x, y:data.y, v1:data.v1, v2:data.v2, $
                                v3:indgen(16) }, dl=dl, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']', $
               ytitle='ERG!CMEP-i/NML!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
      ylim, vns[i], 4., 190., 1
      zlim, vns[i], 0, 0, 1
    endfor
    ;;The unit of differential flux is explicitly set for ztitle currently.
    vns = tnames(prefix+vns_fidu)
    if vns[0] ne '' then options, vns, ztitle='[/s-cm!U2!N-sr-keV/q]'
    ;;The unit of differential energy flux is explicitly set for ztitle.
    vns = tnames(prefix+vns_fiedu)
    if vns[0] ne '' then options, vns, ztitle='[keV/s-cm!I2!N-sr-keV]'
    
    ;;Generate the omni-directional flux (F?DO) 
    for i=0, n_elements(vns_fidu)-1 do begin
      vn = prefix + vns_fidu[i] 
      vn_fido = vn & strput, vn_fido, 'O', strlen(vn_fido)-1
      if tnames(vn) eq '' then continue 
      
      get_data, vn, data=d, dl=dl, lim=lim
      store_data, vn_fido, data={x:d.x, y:total(total( d.y, 2, /nan), 3, /nan)/(16*16), v:d.v2}, lim=lim
      spcs_str = vns_fidu[i] & strput, spcs_str, 'O', strlen(spcs_str)-1 
      options, vn_fido, ytitle='ERG!CMEP-i/NML!C'+spcs_str+'!CEnergy'
    endfor
    
    ;;Generate separate tplot variables for the anodes
    if keyword_set(split_anode) then begin
      for j=0, n_elements(vns_fidu)-1 do begin
        if tnames(prefix+vns_fidu[j]) eq '' then continue
        
        get_data, prefix+vns_fidu[j], data=d, dl=dl, lim=lim
        for i=0, n_elements(d.y[0, 0, 0, *])-1 do begin
          vn = prefix+vns_fidu[j]+'_anode'+string(i, '(i02)')
          store_data, vn, data={x:d.x, y:reform(d.y[*, *, *, i]), v1:d.v1, v2:d.v2}, dl=dl, lim=lim
          options, vn, ytitle='ERG!CMEP-i/NML!C'+vns_fidu[j]+'!Canode'+string(i, '(i02)')+'!CEnergy'
        endfor
      endfor
      
    endif

  endelse
  
  ;;--- print PI info and rules of the road
  if strcmp(datatype, '3dflux') then vn = prefix+'F*DU' $
  else vn = prefix+'F*DO'
  vn = (tnames(vn))[0]
  if vn ne '' then begin
    get_data, vn, dl=dl
    gatt = dl.cdf.gatt
    
    print_str_maxlet, ' '
    print, '**********************************************************************'
    print, ''
    print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
    print, 'PI: ', gatt.PI_NAME
    print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
    print, ''
    for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
    print, ''
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**********************************************************************'
    print, ''

  endif

  
  return
end
