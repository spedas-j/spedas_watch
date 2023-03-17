;$LastChangedBy: davin-mac $
;$LastChangedDate: 2023-03-16 01:51:24 -0700 (Thu, 16 Mar 2023) $
;$LastChangedRevision: 31637 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_load.pro $

pro swfo_stis_load,file_type=file_type,station=station,host=host, ncdf_resolution=ncdf_resolution , trange=trange,opts=opts,make_ncdf=make_ncdf, debug=debug

  if keyword_set(debug) then stop
  if ~keyword_set(trange) then trange=2   ; default to last 2 hours
  if ~keyword_set(file_type) then file_type = 'ccsds'
  if ~keyword_set(station) then station='S1'
  if ~keyword_set(ncdf_resolution) then ncdf_resolution = 1800
  
  if ~isa(opts,'dictionary') then   opts=dictionary()

  if ~opts.haskey('trange') then opts.trange = trange
  if ~opts.haskey('station') then opts.station = station
  if ~opts.haskey('file_type') then opts.file_type = file_type

  stis = 1

  opts.file_resolution = 3600     ; default file resolution for L0 files stored at Berkeley/ssl
  level = 'L0'
  ncdf_directory = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/'+station+'/ncdf/'

  if keyword_set(stis) then begin

    ss_type = opts.station+'/'+opts.file_type
    case ss_type of
      'S0/cmblk': begin
        opts.port       = 2432
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S0/cmblk/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S1/cmblk': begin
        opts.port       = 2433
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/cmblk/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
      end
      'S0/gsemsg': begin
        opts.port       =   2028
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S0/gsemsg/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S1/gsemsg': begin
        opts.port =        2128
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/gsemsg/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S1/ccsds': begin
        opts.port =        2129
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/ccsds/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S1/sccsds': begin
        opts.port =  2127
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/sccsds/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      'S1/ncdf': begin
        opts.port = 0
        opts.file_resolution = ncdf_resolution
        opts.reldir    = 'swfo/data/sci/stis/prelaunch/realtime/S1/ncdf/'
        opts.fileformat = '$NAME$/$TYPE$/YYYY/MM/DD/swfo_$NAME$_$TYPE$_$RES$_YYYYMMDD_hhmm_v00.nc'
        name  = 'stis_sci'
        res = strtrim(fix(ncdf_resolution),2)   ; '1800'
        level = 'L0B'
      end
      'S0/ncdf': begin
        opts.port = 0
        opts.file_resolution = ncdf_resolution
        opts.reldir    = 'swfo/data/sci/stis/prelaunch/realtime/S0/ncdf/'
        opts.fileformat = '$NAME$/$TYPE$/YYYY/MM/DD/swfo_$NAME$_$TYPE$_$RES$_YYYYMMDD_hhmm_v00.nc'
        name  = 'stis_sci'
        res = strtrim(fix(ncdf_resolution),2)   ; '1800'
        level = 'L0B'
      end
      else: begin
        dprint,'Undefined: '+ss_type
        opts.port = 0
        return
      end
    endcase

    if opts.file_type eq 'ncdf' then begin
      opts.fileformat = str_sub(opts.fileformat,'$NAME$', name)
      opts.fileformat = str_sub(opts.fileformat,'$TYPE$', level)
      opts.fileformat = str_sub(opts.fileformat,'$RES$', res)
    endif

    opts.host = 'swifgse1.ssl.berkeley.edu'
    opts.root_dir = root_data_dir()
    opts.url = 'http://research.ssl.berkeley.edu/data/'
    opts.title = 'SWFO'

    if keyword_set(offline) then opts.url=''

    opts.exec_text =  ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','timebar,systime(1)','swfo_stis_plot']
    ;    opts.file_trange = 3


    ;    trange = struct_value(opts,'file_trange',default=!null)
    if keyword_set(trange) then begin
      ;trange = opts.file_trange
      pathformat = opts.reldir + opts.fileformat
      ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
      if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0]*3600.
      dprint,dlevel=2,'Download raw telemetry files...'
      if 1 then begin
        filenames = file_retrieve(pathformat,trange=trange,remote=opts.url,local=opts.root_dir,resolution=opts.file_resolution)
      endif else begin
        filenames = swfo_file_retrieve(pathformat,trange=trange)
      endelse
      dprint,dlevel=2, "Files to be loaded:"
      dprint,dlevel=2,file_info_string(filenames)
      opts.filenames = filenames
    endif

    str_element,opts,'filenames',filenames

    if level eq 'L0' then begin
      swfo_stis_apdat_init,/save_flag    ; initialize apids
      ;swfo_apdat_info,/rt_flag ,/save_flag       ; don't use rt_flag anymore
      swfo_apdat_info,/print,/all        ; display apids

      if keyword_set(make_ncdf) then begin
        sci = swfo_apdat('stis_sci')
        sci.ncdf_directory = ncdf_directory
        sci.file_resolution = ncdf_resolution    ; setting the ncdf_resolution to a non zero number will tell the decom software to also generate NCDF files
      endif

    endif




    directory = opts.root_dir + opts.reldir
    file_type = opts.file_type
    rdr = 0
    case file_type of
      'ptp_file': begin   ; obsolete - Do not use
        message,"Obsolete - Don't use this",/cont
        swfo_ptp_recorder,title=opts.title,port=opts.port, host=opts.host, exec_proc='swfo_ptp_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d
      end
      'gsemsg': begin
        rdr = swfo_raw_tlm('gsemsg',port=opts.port,host=opts.host)
        opts.rdr = rdr
        if keyword_set(makencdf) then begin

        endif
        if opts.haskey('filenames') then begin
          rdr.file_read,opts.filenames
        endif
        swfo_apdat_info,/all,/print
        swfo_apdat_info,/all,/create_tplot_vars
      end
      'ptp': begin
        dprint,dlevel=0, 'Warning:  This file type is Obsolete and the code is not tested;
        if opts.haskey('filenames') then begin
          swfo_ptp_file_read,opts.filenames,file_type=opts.file_type  ;,/no_clear
        endif
        swfo_apdat_info,/all,/rt_flag
        swfo_apdat_info,/all,/print
        swfo_recorder,title=opts.title,port=opts.port, host=opts.host, exec_proc='swfo_gsemsg_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d
      end
      'cmblk': begin
        rdr  = cmblk_reader(port=opts.port, host=opts.host,directory=directory,fileformat=opts.fileformat)
        rdr.add_handler, 'raw_tlm',  swfo_raw_tlm('SWFO_raw_telem',/no_widget)
        rdr.add_handler, 'KEYSIGHTPS' ,  cmblk_keysight('Keysight',/no_widget)
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (CMBLK)'
      end
      'ccsds': begin
        rdr  = ccsds_reader('CCSDS',port=opts.port, host=opts.host,directory=directory,fileformat=opts.fileformat)
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (CCSDS)'
      end
      'sccsds': begin
        dprint,'Warning - this code segment has not been tested.'
        sync = byte(['1a'x,'cf'x,'fc'x,'1d'x])
        rdr  = ccsds_reader('Sync_CCSDS',sync=sync,port=opts.port, host=opts.host,directory=directory,fileformat=opts.fileformat)
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (Sync CCSDS)'
      end
      'ncdf': begin
        ncdf_data = swfo_ncdf_read(filenames=filenames)
        store_data,'ncdf_'+name+'_'+level+'_',data=ncdf_data,tagnames = '*'
      end
      else:  dprint,'Unknown file format'
    endcase


    str_element,opts,'exec_text',exec_text
    if keyword_set(exec_text) then begin
      exec, exec_text = exec_text,title=opts.title
    endif

    swfo_stis_tplot,/set,'dl3'
    !except=0
    opts.plotparam=dictionary('routine_name','swfo_stis_plot')
    opts.plotparam.read_object = rdr
    dprint,'For visualization, run:'
    print,'ctime,/silent,t,routine_param=opts.plotparam'

  endif

end