


pro swfo_stis_load,file_type=file_type,station=station,host=host , trange=trange,opts=opts

  if ~keyword_set(trange) then trange=2   ; default to last 2 hours
  if ~keyword_set(file_type) then file_type = 'gsemsg'
  if ~keyword_set(station) then station='S1'

  if ~isa(opts,'dictionary') then   opts=dictionary()
  
  if ~opts.haskey('trange') then opts.trange = trange
  if ~opts.haskey('station') then opts.station = station
  if ~opts.haskey('file_type') then opts.file_type = file_type

  stis = 1

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
        opts.port =  2128
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/gsemsg/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'
      end
      'S1/ccsds': begin
        opts.port =  2129
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/ccsds/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_ccsds_YYYYMMDD_hh.dat'
      end
      'S1/sccsds': begin
        opts.port =  2127
        opts.reldir     = 'swfo/data/sci/stis/prelaunch/realtime/S1/sccsds/'
        opts.fileformat = 'YYYY/MM/DD/swfo_stis_sccsds_YYYYMMDD_hh.dat'
      end
      else: begin
        dprint,'Undefined: '+file_type
        return
      end
    endcase

    opts.host = 'swifgse1.ssl.berkeley.edu'
    opts.root_dir = root_data_dir()
    opts.url = 'http://research.ssl.berkeley.edu/data/'
    opts.title = 'SWFO'

    if keyword_set(offline) then opts.url=''

    opts.exec_text =  ['tplot,verbose=0,trange=systime(1)+[-1.,.05]*600','timebar,systime(1)']
    ;    opts.file_trange = 3


    ;    trange = struct_value(opts,'file_trange',default=!null)
    if keyword_set(trange) then begin
      ;trange = opts.file_trange
      pathformat = opts.reldir + opts.fileformat
      ;filenames = file_retrieve(pathformat,trange=trange,/hourly_,remote_data_dir=opts.remote_data_dir,local_data_dir= opts.local_data_dir)
      if n_elements(trange eq 1)  then trange = systime(1) + [-trange[0],0]*3600.
      dprint,dlevel=2,'Download raw telemetry files...'
      if 1 then begin
        filenames = file_retrieve(pathformat,trange=trange,/hourly,remote=opts.url,local=opts.root_dir,resolution=3600L)
      endif else begin
        filenames = swfo_file_retrieve(pathformat,trange=trange)
      endelse
      dprint,dlevel=2, "Files to be loaded:"
      dprint,dlevel=2,file_info_string(filenames)
      opts.filenames = filenames
    endif

    str_element,opts,'filenames',filenames
    
    
    swfo_stis_apdat_init,/save_flag    ; initialize apids
    ;swfo_apdat_info,/rt_flag ,/save_flag       ; don't use rt_flag anymore
    swfo_apdat_info,/print,/all        ; display apids


    directory = opts.root_dir + opts.reldir
    file_type = opts.file_type
    rdr = 0
    case file_type of
      'ptp_file': begin   ; obsolete - Do not use
        message,"Obsolete - Don't use this",/cont
        swfo_ptp_recorder,title=opts.title,port=opts.port, host=opts.host, exec_proc='swfo_ptp_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d
      end
      'gsemsg': begin
        if 1 then begin
          rdr = swfo_raw_tlm('gsemsg',port=opts.port,host=opts.host)
          opts.rdr = rdr
          if opts.haskey('filenames') then begin
            rdr.file_read,opts.filenames
          endif
          swfo_apdat_info,/all,/print
          swfo_apdat_info,/all,/create_tplot_vars
        endif else begin
          if opts.haskey('filenames') then begin
            swfo_ptp_file_read,opts.filenames,file_type=opts.file_type  ;,/no_clear
          endif
          swfo_apdat_info,/all,/rt_flag
          swfo_apdat_info,/all,/print
          swfo_recorder,title=opts.title,port=opts.port, host=opts.host, exec_proc='swfo_gsemsg_lun_read',destination=opts.fileformat,directory=directory,set_file_timeres=3600d
        endelse
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
        rdr  = swfo_ccsds(port=opts.port, host=opts.host,directory=directory,fileformat=opts.fileformat)
        opts.rdr = rdr

        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (CCSDS)'

      end
      'ccsds': begin
        rdr  = swfo_ccsds(port=opts.port, host=opts.host,directory=directory,fileformat=opts.fileformat)
        opts.rdr = rdr
        if opts.haskey('filenames') then begin
          rdr.file_read, opts.filenames        ; Load in the files
        endif
        swfo_apdat_info,/all,/create_tplot_vars
        tplot_options,title='Real Time (Sync CCSDS)'
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

  endif

end