pro spp_fld_make_cdf_l2, l2_datatype, $
  l2_master_cdf, $
  trange = trange, $
  l1_cdf_datatypes = l1_cdf_datatypes, $
  l1_cdf_dir = l1_cdf_dir, $
  l1_cdf_files = l1_cdf_files, $
  filename = filename, $
  load = load

  if n_elements(trange) EQ 0 then begin

    dprint, dlevel = 1, 'No timerange specified for CDF file creation. Exiting.'

    return

  endif

  spp_fld_cdf_timespan, trange = trange, success = ts_success, $
    filename_timestring = filename_timestring

  if n_elements(l1_cdf_dir) EQ 0 then begin

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
        l1_cdf_datatypes = ['rfs_lfr_auto']
      end
      'scm': begin
        l1_cdf_datatypes = ['dfb_wf03','dfb_wf04','dfb_wf05']
      end
      'dfb_spec': begin
        l1_cdf_datatypes = [$
          'dfb_dc_spec1','dfb_dc_spec2', $
          'dfb_dc_spec3','dfb_dc_spec4', $
          'dfb_ac_spec1','dfb_ac_spec2', $
          'dfb_ac_spec3','dfb_ac_spec4']
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

  l1_cdf_files = dictionary(l1_cdf_datatypes)

  foreach l1_cdf_datatype, l1_cdf_datatypes do begin

    ; TODO: Increment version number

    l1_cdf_files[l1_cdf_datatype] = l1_cdf_dir + 'spp_fld_l1_' + $
      l1_cdf_datatype + '_' + filename_timestring + '_v00.cdf'

  end

  ; Read in the L1 CDF files

  foreach l1_cdf_file, l1_cdf_files do spp_fld_load_l1, l1_cdf_file


  ; Define the L2 master and buffer CDF files based on the L2 skeleton file

  l2_skt = spp_fld_l2_cdf_skt_file(l2_datatype, l2_version = l2_version)

  cd, file_dirname(l2_skt) + '/../../../../../', current = old_dir

  spawn, 'svnversion', svnversion_string

  dprint, dlevel = 1, 'SVN Version ' + svnversion_string

  cd, old_dir

  l2_cdf_tmp_dir = getenv('SPP_FLD_CDF_DIR') + '/tmp/'

  file_mkdir, l2_cdf_tmp_dir

  l2_master_cdf = l2_cdf_tmp_dir + 'psp_fld_l2_' + $
    l2_datatype + '_00000000_v' + $
    l2_version + '.cdf'

  ; TODO: move this out of temp dir

  l2_cdf = l2_cdf_tmp_dir + 'psp_fld_l2_' + $
    l2_datatype + '_' + filename_timestring + '_v' + $
    l2_version + '.cdf'

  ; Create a (temporary) master CDF file from the skeleton file

  file_delete, l2_master_cdf, /allow_nonexistent
  file_delete, l2_cdf, /allow_nonexistent

  spawn, 'skeletoncdf -cdf ' + l2_master_cdf + ' ' + l2_skt

  ; Use the master CDF to create a buffer CDF to write the data into

  ;l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  cdf_leap_second_init

  call_procedure, make_cdf_l2_pro, l2_master_cdf, l2_cdf, trange = trange

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


  ;
  ; If load keyword set, load file into tplot variables
  ;

  if keyword_set(load) then begin

    load_pro = 'psp_load_' + l2_datatype

    call_procedure, load_pro, file = l2_cdf

    if !spp_fld_tmlib.test_cdf_dir NE '' then begin

      file_mkdir, !spp_fld_tmlib.test_cdf_dir

      file_copy, filename, !spp_fld_tmlib.test_cdf_dir, /over

    end

  end

end