;+
; PROCEDURE: erg_load_mgf
;
; PURPOSE:
;   To load ERG MGF magnetic field data from the ERG-SC site
;
; KEYWORDS:
;   datatype = Time resolution. '8sec' for 8 s resolution, and
;              '64hz', '128hz', and '256hz' for 64, 128, and 256 Hz
;              sampling rate, respectively. The default is '8sec'.
;   coord = Coordinate system of output. The default is 'sm'.
;   /get_support_data, load support_data variables as well as data variables into tplot variables.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
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
;
; EXAMPLE:
;   erg_load_mgf, datatype='8sec', trange=['2017-03-01/00:00:00','2017-03-02/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see https://ergsc.isee.nagoya-u.ac.jp/
;
; Written by: Y. Miyashita, Feb 10, 2017
;             ERG Science Center, ISEE, Nagoya University
;             erg-sc-core at isee.nagoya-u.ac.jp
; Modified by: M. Teramoto(MT), June 23, 2017
;             ERG Science Center, ISEE, Nagoya University
;             erg-sc-core at isee.nagoya-u.ac.jp
; Modified by: MT, June 28, 2018
;                 change the directroy structure of 8sec data from IYYYY to IYYYY/IMM
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2018-08-10 15:43:17 -0700 (Fri, 10 Aug 2018) $
;   $LastChangedRevision: 25628 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/mgf/erg_load_mgf.pro $
;-

pro erg_load_mgf, datatype=datatype, coord=coord, get_support_data=get_support_data, $
  downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
  trange=trange, timeclip=timeclip, uname=uname, passwd=passwd, localdir=localdir, $
  remotedir=remotedir, $
  datafpath=datafpath, $
  _extra=_extra


  ;*** Initialize the system variable for ERG ***
  erg_init

  ;*** time resolution ***
  if ~keyword_set(datatype) then datatype='8sec'
  datatype=strlowcase(strcompress(string(datatype),/remove_all))

  case datatype of
    '8s':  datatype='8sec'
    '8':   datatype='8sec'
    '64':  datatype='64hz'
    '128': datatype='128hz'
    '256': datatype='256hz'
    '8sec':  break
    '64hz':  break
    '128hz': break
    '256hz': break
    else: begin
      print,'Wrong resolution.' & return
    end
  endcase

  ;*** keyword set ***
  if ~keyword_set(coord) then coord='sm'

  if ~keyword_set(downloadonly) then downloadonly=0
  if ~keyword_set(no_server) then no_server=0
  if ~keyword_set(no_download) then no_download=0


  ;*** load CDF ***
  ;--- Create (and initialize) a data file structure
  source=file_retrieve(/struct)

  ;--- Set parameters for the data file class

  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    source.local_data_dir = !erg.local_data_dir
  endif else source.local_data_dir=localdir
  if ~keyword_set(remotedir) then begin
    source.remote_data_dir=!erg.remote_data_dir
  endif else  source.remote_data_dir=remotedir





  ;--- Download parameters
  if keyword_set(downloadonly) then source.downloadonly=1
  if keyword_set(no_server)    then source.no_server=1
  if keyword_set(no_download)  then source.no_download=1
  ;localdir = root_data_dir() + 'satellite/erg/mgf/'

  ;--- Generate the file paths by expanding wilecards of date/time
  ;    (e.g., YYYY, YYYYMMDD) for the time interval set by "timespan"
  ;--- Set the file path which is added to source.local_data_dir/remote_data_dir.
  case datatype of
    '8sec': begin
      relpathnames1=file_dailynames(file_format='YYYY/MM', trange=trange)
      relpathnames2=file_dailynames(file_format='YYYYMMDD', trange=trange)
      relpathnames='satellite/erg/mgf/l2/8sec/'+relpathnames1 $
        +'/erg_mgf_l2_8sec_'+relpathnames2+'_v??.??.cdf'

      if ~keyword_set(no_download) then $
        remotedir = !erg.remote_data_dir
    end
    else:   begin
      relpathnames1=file_dailynames(file_format='YYYY/MM', /hour_res, trange=trange)
      relpathnames2=file_dailynames(file_format='YYYYMMDDhh', /hour_res, trange=trange)
      relpathnames='satellite/erg/mgf/l2/'+datatype+'/'+relpathnames1 $
        +'/erg_mgf_l2_'+datatype+'_'+coord+'_'+relpathnames2+'_v??.??.cdf'

    end
  endcase

  ;--- Download the designated data files from the remote data server
  ;    if the local data files are older or do not exist.
  if keyword_set(datafpath) then files = datafpath else $
    files=spd_download(remote_file=relpathnames,remote_path = remotedir,no_download=no_download,$
    _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
    files=files(where(filestest eq 1))

    ;--- Load data into tplot variables
    if(downloadonly eq 0) then begin
      cdf2tplot, file=files, get_support_data=get_support_data, $
        verbose=source.verbose, prefix='erg_mgf_l2_'
      ;--- time clip
      if keyword_set(timeclip) then begin
        get_timespan, tr & tmspan=time_string(tr)
        time_clip, 'erg_mgf_l2_*_'+datatype+'*', tmspan[0], tmspan[1], /replace
      endif

      ;--- Missing data -1.e+31 --> NaN
      tclip, 'erg_mgf_l2_date_time_'+datatype, -1.e+6, 1.e+6, /overwrite
      tclip, 'erg_mgf_l2_mag_'+datatype+'_*', -1.e+6, 1.e+6, /overwrite
      tclip, 'erg_mgf_l2_magt_'+datatype, -1.e+6, 1.e+6, /overwrite
      tclip, 'erg_mgf_l2_dyn_rng_'+datatype, -120, 1.e+6, /overwrite
      tclip, 'erg_mgf_l2_quality_'+datatype, -1.e+6, 1.e+6, /overwrite

      if(datatype eq '8sec') then begin
        tclip, 'erg_mgf_l2_rmsd_8sec_*', -1.e+6, 1.e+6, /overwrite
        tclip, 'erg_mgf_l2_rmsd_8sec', -1.e+6, 1.e+6, /overwrite
        get_data, 'erg_mgf_l2_n_rmsd_8sec',data=bb,dlim=dlim
        index_lt0=where(bb.y lt 0, innum)
        if innum gt 0 then begin
          bb.y[index_lt0,*]=0
          bb.x[index_lt0]=!values.f_nan
          store_data, 'erg_mgf_l2_n_rmsd_8sec',data=bb,dlim=dlim
        endif
      endif

      ;--- Labels

      options, 'erg_mgf_l2_mag_'+datatype+'_*', labels=['Bx','By','Bz']
      options, 'erg_mgf_l2_mag_'+datatype+'_*', labflag=1, colors=[2,4,6]

      if(datatype eq '8sec') then begin
        options,'erg_mgf_l2_rmsd_8sec_*', labels=['Bx','By','Bz']
        options, 'erg_mgf_l2_igrf_8sec_*', labels=['Bx','By','Bz']
        options, 'erg_mgf_l2_rmsd_8sec_*',  labflag=1, colors=[2,4,6]
        options, 'erg_mgf_l2_igrf_8sec_*', labflag=1, colors=[2,4,6]
      endif
    endif

    ;--- print PI info and rules of the road
    gatt=cdf_var_atts(files[0])

    print_str_maxlet, ' '
    print, '**********************************************************************'
    print, gatt.PROJECT
    print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
    print, ''
    print, 'Information about ERG MGF'
    print, ''
    print, 'PI: ', gatt.PI_NAME
    print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
    print, ''
    for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
    print, ''
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**********************************************************************'
    print, ''

  endif

  ;---
  return
end