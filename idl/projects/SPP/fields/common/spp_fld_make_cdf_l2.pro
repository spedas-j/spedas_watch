; Two configurations:
; In the TEST configuration, a time range (trange) and l1_cdf_dir is specified.
; spp_fld_make_cdf_l2 looks in the l1_cdf_dir for a corresponding l1 cdf file
; (or multiple files) and loads that data.  From those loaded variables (and
; the associated skeleton file definitions), the l2 data file is created.
;
; In the standard (DAILY) configuration, a single element time range is
; specified, and the l1_cdf_dir is not specified.  The program will use the
; input time to determine where the l1 cdf files are (based on environment
; variables) then read them automatically and create daily l2 files.  (This is
; not implemented yet).

pro spp_fld_make_cdf_l2, l2_datatype, $
  l2_master_cdf, $
  trange = trange, $
  l1_cdf_datatypes = l1_cdf_datatypes, $
  l1_cdf_dir = l1_cdf_dir, $
  l1_cdf_files = l1_cdf_files, $
  filename = filename, $
  load = load, $
  no_load_l1 = no_load_l1, $
  daily = daily, $
  downsample_cadence = downsample_cadence

  if n_elements(trange) EQ 0 then begin

    dprint, dlevel = 1, 'No timerange specified for CDF file creation. Exiting.'

    return

  endif

  spp_fld_cdf_timespan, trange = trange, success = ts_success, $
    filename_timestring = filename_timestring, daily = daily

  if n_elements(no_load_l1) EQ 0 then no_load_l1 = 0

  if n_elements(l1_cdf_dir) EQ 0 and no_load_l1 NE 1 then begin

    ; TODO: Set up default location for L1 input CDF files based on
    ; requested input time

    dprint, dlevel = 1, 'No input directory specified.  Exiting.'

    return

  endif

  ; Creation of a L2 CDF file requires input L1 CDF files
  ; For the MAG L2 file, these are required:

  if n_elements(l2_datatype) EQ 1 then begin

    case l2_datatype of
      'mag': begin
        l1_cdf_datatypes = ['mago_survey', 'magi_survey', 'mago_hk', 'magi_hk']
      end
      'rfs_lfr': begin
        l1_cdf_datatypes = ['rfs_lfr_auto', 'rfs_lfr_cross', 'rfs_lfr_hires']
      end
      'rfs_hfr': begin
        l1_cdf_datatypes = ['rfs_hfr_auto', 'rfs_hfr_cross']
      end
      'rfs': begin
        l1_cdf_datatypes = ['rfs_lfr_auto']
      end
      'scm': begin
        l1_cdf_datatypes = ['dfb_wf03','dfb_wf04','dfb_wf05']
      end
      'dfb_dc_spec': begin
        l1_cdf_datatypes = 'dfb_dc_spec' + ['1','2','3','4']
      end
      'dfb_ac_spec': begin
        l1_cdf_datatypes = 'dfb_ac_spec' + ['1','2','3','4']
      end
      ELSE: begin

        dprint, dlevel = 1, 'Unrecognized L2 data type.  Exiting'

        return

      end

    endcase

  endif else begin

    dprint, dlevel = 1, 'No valid L2 data type specified.  Exiting'

    return

  endelse

  make_cdf_l2_pro = 'spp_fld_make_cdf_l2_' + l2_datatype


  ; Read in the L1 CDF files

  if no_load_l1 EQ 0 then begin
    foreach l1_cdf_datatype, l1_cdf_datatypes do spp_fld_load_l1, l1_cdf_file

    l1_cdf_files = dictionary(l1_cdf_datatypes)

    foreach l1_cdf_datatype, l1_cdf_datatypes do begin

      ; TODO: Increment version number

      l1_cdf_files[l1_cdf_datatype] = l1_cdf_dir + 'spp_fld_l1_' + $
        l1_cdf_datatype + '_' + filename_timestring + '_v00.cdf'

    end

  end

  ; Define the L2 master and buffer CDF files based on the L2 skeleton file

  l2_skt = spp_fld_l2_cdf_skt_file(l2_datatype, l2_version = l2_version)


  if l2_skt EQ '' then begin

    dprint, dlevel = 1, 'Exiting SPP_FLD_MAKE_CDF_L2'

    return

  endif

  cd, file_dirname(l2_skt) + '/../../../../../', current = old_dir

  spawn, 'svnversion', svnversion_string

  dprint, dlevel = 1, 'SVN Version ' + svnversion_string

  cd, old_dir

  ; TODO: better structure of daily/test/temp directories

  l2_cdf_tmp_dir = getenv('SPP_FLD_CDF_DIR') + 'l2_test/' + l2_datatype + '/'

  l2_cdf_test_dir = getenv('SPP_FLD_CDF_DIR') + 'l2_test/' + l2_datatype + '/'

  file_mkdir, l2_cdf_tmp_dir

  file_mkdir, l2_cdf_test_dir

  l2_master_cdf = l2_cdf_tmp_dir + 'psp_fld_l2_' + $
    l2_datatype + '_00000000_v' + $
    l2_version + '.cdf'

  if n_elements(downsample_cadence) GT 0 then begin

    downsample_string = '_1sec'

  endif else begin

    downsample_string = ''

  endelse

  l2_cdf = l2_cdf_test_dir + 'psp_fld_l2_' + $
    l2_datatype + downsample_string + '_' + filename_timestring + '_v' + $
    l2_version + '.cdf'

  l2_cdf_dump = l2_cdf_test_dir + 'psp_fld_l2_' + $
    l2_datatype + downsample_string + '_' + filename_timestring + '_v' + $
    l2_version + '.cdfdump.txt'


  ; Create a (temporary) master CDF file from the skeleton file

  file_delete, l2_master_cdf, /allow_nonexistent
  file_delete, l2_cdf, /allow_nonexistent

  spawn, getenv('CDF_BIN') + '/skeletoncdf -cdf ' + l2_master_cdf + ' ' + l2_skt

  if ~file_test(l2_master_cdf) then begin

    dprint, dlevel = 1, 'Unable to create CDF from skeleton file ' + l2_master_cdf

    return

  endif

  ; Use the master CDF to create a buffer CDF to write the data into

  ;l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  cdf_leap_second_init

  libs, make_cdf_l2_pro, routine_names = routine_names

  if routine_names EQ '' then begin

    dprint, dlevel = 1, 'Procedure ' + strupcase(make_cdf_l2_pro) + $
      ' not found on IDL path.  Exiting'

    return

  endif

  call_procedure, make_cdf_l2_pro, l2_master_cdf, l2_cdf, trange = trange, $
    downsample_cadence = downsample_cadence

  ; The write_data_to_cdf procedure doesn't allow for easy modification
  ; of global variables, so we do it here instead.

  cdf_id = cdf_open(l2_cdf)

  attexst = cdf_attexists(cdf_id,'svn_version')
  if (attexst) then begin
    attid = cdf_attnum(cdf_id, 'svn_version')
    cdf_attput, cdf_id, attid, 0L, svnversion_string[0]
    dprint, dlevel = 3, 'Changed SVN version string attribute to ', $
      svnversion_string
  endif

  cdf_close, cdf_id

  cd, l2_cdf_test_dir, current = old_dir

  spawn, getenv('CDF_BIN') + '/cdfdump ' + l2_cdf + ' -recordrange 1,10', $
    l2_cdf_dump_lines

  OPENW, dump_lun, l2_cdf_dump, /GET_LUN

  for i = 0, n_elements(l2_cdf_dump_lines) - 1 do begin

    PRINTF, dump_lun, l2_cdf_dump_lines[i]

  end

  free_lun, dump_lun

  cd, old_dir

  ;stop

  ;
  ; If load keyword set, load file into tplot variables
  ;

  if keyword_set(load) then begin

    load_pro = 'psp_load_' + l2_datatype

    call_procedure, load_pro, file = l2_cdf

    if !spp_fld_tmlib.test_cdf_dir NE '' then begin

      file_mkdir, !spp_fld_tmlib.test_cdf_dir

      file_copy, l2_cdf, !spp_fld_tmlib.test_cdf_dir, /over

    end

  end

end