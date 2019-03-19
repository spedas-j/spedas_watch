;+
; PRO erg_load_lepe
;
; The read program for Level-2 LEP-e data
;
; :Note:
;    In order to let users easily plot the spectrum, flux and count arrays are sorted
;    in ascending order in terms of energy and saved in tplot variables. The actual
;    order of energy step is stored in data variable FEDU_Energy. Please refer to it 
;    to derive the exact timing of each energy step within a spin phase.
;
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only '3dflux' and 'omniflux' are acceptable.
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_support_data: Set to load support data in CDF data files.
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
;   split_ch: Set to generate a FEDU tplot variable for each Channel.
;
;
; :Examples:
;  IDL> timespan,'2017-03-24'
;  IDL> erg_load_lepe,uname=uname,pass=pass   ;;3D flux data
;  IDL> erg_load_lepe,uname=uname,pass=pass,/split_ch   ;;3D flux data for each Channel
;  IDL> erg_load_lepe,uname=uname,pass=pass,datatype='omniflux'  ;;omniflux data
;
; :revised by Tzu-Fang Chang (E-mail: jocelyn at isee.nagoya-u.ac.jp)
; $LastChangedDate: 2018-05-02 10:00:00
;
; :Authors:
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
pro erg_load_lepe, $
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
   split_ch=split_ch, $
   no_sort_enebin=no_sort_enebin, $
   _extra=_extra

  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(level) then level = 'l2'
  if ~keyword_set(datatype) then datatype = 'omniflux'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0
  if undefined(no_sort_enebin) then sort_enebin = 1 else sort_enebin = 0
  
  
  ;; ; ; ; USER NAME ; ; ; ;
  if keyword_set(datafpath) or keyword_set(no_download) then begin
    uname = ' ' & passwd = ' '  ;;padding with a blank
  endif

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/lepe/' $
               + level + '/' + datatype + '/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/lepe/' $
                + level + '/' + datatype + '/'
  endif

  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  cdffn_prefix = 'erg_lepe_'+level+'_'+datatype+'_'
  relfpathfmt = 'YYYY/MM/' + cdffn_prefix+'YYYYMMDD_v*.cdf'

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

  ;;Read CDF files and generate tplot variables
  prefix = 'erg_lepe_' + level + '_' + datatype + '_'
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data, $
             varformat=varformat, verbose=verbose


  ;;Options for tplot variables
  vns = ''
  if total(strcmp( datatype, '3dflux' )) then $
     append_array, vns, prefix+['FEDU', 'FEEDU', 'Count_Raw']  ;;common to flux/count arrays
  if total(strcmp( datatype, 'omniflux')) then $
     append_array, vns, prefix+'FEDO'  ;;Omni flux array
  options, vns, spec=1, ysubtitle='[eV]', ztickformat='pwr10tick', extend_y_edges=1, $
           datagap=17., zticklen=-0.4

  ;;Filter vns with varformat to avoid manipulating pre-existing
  ;;tplot variables in the part below
  if keyword_set(varformat) then vns = strfilter( vns, prefix+strsplit(/ext, varformat) )
  
  ;;sorted flux and count arrays for plotting the spectrum
  for i=0, n_elements(vns)-1 do begin
    if tnames(vns[i]) eq '' then continue
    get_data, vns[i], data=data, dl=dl, lim=lim

    if vns[i] eq prefix+'FEDO' then begin
      ene = total(data.v, 2)/2

      if sort_enebin then begin
        if debug then begin
          dprint, 'Sorting in energy bin '+vns[i]
        endif
        for n=0, n_elements(data.x)-1 do begin
          sort_idx = sort(ene[n, *])
          data.y[n, *] = data.y[n, sort_idx]
          ene[n, *] = ene[n, sort_idx]
        endfor
      endif
      
      store_data, vns[i], data={x:data.x, y:data.y, v:ene }, dl=dl, lim=lim
      options, vns[i], ztitle='[/s-cm!U2!N-sr-eV]', ytitle='ERG!CLEP-e!CFEDO!CEnergy'

    endif else begin

      ene = total(data.v1, 2)/2

      if sort_enebin then begin
        if debug then begin
          dprint, 'Sorting in energy bin '+vns[i]
        endif
        for n=0, n_elements(data.x)-1 do begin
          sort_idx = sort(ene[n, *])
          data.y[n, *, *, *] = data.y[n, sort_idx, *, *]
          ene[n, *] = ene[n, sort_idx]
        endfor
      endif
      
      store_data, vns[i], data={x:data.x, y:data.y, v:ene, v2:data.v2, $
                                v3:indgen(16) }, dl=dl, lim=lim
      options, vns[i], ztitle='['+dl.cdf.vatt.units+']'
      options, vns[i], ytitle='ERG!CLEP-e!C'+dl.cdf.vatt.fieldnam+'!CEnergy'
    endelse

    ylim, vns[i], 1e+1, 3e+4, 1
    zlim, vns[i], 0, 0, 1
  endfor

  ;;Generate separate tplot variables for Channels
  if keyword_set(split_ch) and total(strcmp( vns, prefix+'FEDU' )) gt 0 then begin
    get_data, prefix+'FEDU', data=d, dl=dl, lim=lim
    for i=0, n_elements(d.y[0, 0, *, 0])-1 do begin
      if i lt 5 then vn = prefix+'FEDU_ch'+string(i+1, '(i02)')
      if i gt 6 then vn = prefix+'FEDU_ch'+string(i+11, '(i02)')
      if i eq 5 then vn = prefix+'FEDU_chA'
      if i eq 6 then vn = prefix+'FEDU_chB'
      store_data, vn, data={x:d.x, y:reform(d.y[*, *, i, *]), v:d.v, v2:indgen(16)}, dl=dl, lim=lim
      if i lt 5 then options, vn, ytitle='ERG!CLEP-e!CFEDU_Ch'+string(i+1, '(i02)')+'!CEnergy'
      if i gt 6 then options, vn, ytitle='ERG!CLEP-e!CFEDU_Ch'+string(i+11, '(i02)')+'!CEnergy'
      if i eq 5 then options, vn, ytitle='ERG!CLEP-e!CFEDU_ChA!CEnergy'
      if i eq 6 then options, vn, ytitle='ERG!CLEP-e!CFEDU_ChB!CEnergy'
    endfor
  endif

  
  ;;--- print PI info and rules of the road
  gatt = dl.cdf.gatt

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, gatt.PROJECT
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG LEP-e'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**********************************************************************'
  print, ''

  return
end
