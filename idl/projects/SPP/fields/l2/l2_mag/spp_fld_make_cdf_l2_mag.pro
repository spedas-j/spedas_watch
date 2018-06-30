pro spp_fld_make_cdf_l2_mag, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir, $
  load = load
  
  ;.compile read_mycdf
  ;.compile IDLmakeCDF
  
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

  l1_cdf_datatypes = ['mago_survey', 'magi_survey', 'mago_hk', 'magi_hk']

  l1_cdf_files = dictionary(l1_cdf_datatypes)

  foreach l1_cdf_datatype, l1_cdf_datatypes do begin

    ; TODO: Increment version number

    l1_cdf_files[l1_cdf_datatype] = l1_cdf_dir + 'spp_fld_l1_' + $
      l1_cdf_datatype + '_' + filename_timestring + '_v00.cdf'

  end

  ; Red in the L1 CDF files

  foreach l1_cdf_file, l1_cdf_files do spp_fld_load_l1, l1_cdf_file


  ; Define the L2 master and buffer CDF files based on the L2 skeleton file

  l2_datatype = 'mag'

  l2_skt = spp_fld_l2_cdf_skt_file(l2_datatype, l2_version = l2_version)
  
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

  spawn, 'skeletoncdf -cdf ' + l2_master_cdf + ' ' + l2_skt

  ; Use the master CDF to create a buffer CDF to write the data into

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)
  
  cdf_leap_second_init

  ; Read data from the TPLOT variables

  get_data, 'spp_fld_magi_survey_mag_bx_nT', data = mago_bx
  get_data, 'spp_fld_magi_survey_mag_by_nT', data = mago_by
  get_data, 'spp_fld_magi_survey_mag_bz_nT', data = mago_bz
  
  get_data, 'spp_fld_magi_survey_range', data = mago_range
  
  unix_time = mago_bx.x
  
  ; Generate 1 minute time cadence during time range

  n_min = long((trange[1] - trange[0]) / 60d)

  unix_time_1min = trange[0] + 60d * dindgen(n_min)

  n_full = n_elements(unix_time)
  
  met_time = unix_time - time_double('2010-01-01/00:00:00')
  tt2000_time = long64((add_tt2000_offset(unix_time)-time_double('2000-01-01/12:00:00'))*1.e9)

  tt2000_time_1min = long64((add_tt2000_offset(unix_time_1min)-time_double('2000-01-01/12:00:00'))*1.e9)

  mag_mode = lonarr(n_full)
  mago_rate = lonarr(n_full) + 7
  magi_rate = lonarr(n_full)
  quality_flag = lonarr(n_full)

  mag_data = transpose([[mago_bx.y], [mago_by.y], [mago_bz.y]])
  mag_data_rtn = -transpose([[mago_bx.y], [mago_by.y], [mago_bz.y]])

  orth1_o = rebin(identity(3), 3, 3, n_min, /sample)
  payld1_o = rebin(identity(3), 3, 3, n_min, /sample)

  orth1_i = rebin(identity(3), 3, 3, n_min, /sample)
  payld1_i = rebin(identity(3), 3, 3, n_min, /sample)

  zero1_o = dblarr(3,4,n_min)
  sens1_o = dblarr(3,4,n_min)
  ampl1_o = dblarr(3,4,n_min)

  zero1_i = dblarr(3,4,n_min)
  sens1_i = dblarr(3,4,n_min)
  ampl1_i = dblarr(3,4,n_min)


  *l2_cdf_buffer.Epoch.data         = tt2000_time
  *l2_cdf_buffer.Epoch1.data        = tt2000_time_1min

  *l2_cdf_buffer.B_SC.data          = mag_data
  *l2_cdf_buffer.B_RTN.data         = mag_data_rtn
  *l2_cdf_buffer.RANGE.data         = mago_range.y

  *l2_cdf_buffer.MAG_MODE.data      = mag_mode
  *l2_cdf_buffer.MAGO_RATE.data     = mago_rate
  *l2_cdf_buffer.MAGI_RATE.data     = magi_rate
  *l2_cdf_buffer.QUALITY_FLAG.data  = quality_flag
  
  *l2_cdf_buffer.ORTH1_O.data       = orth1_o
  *l2_cdf_buffer.ZERO1_O.data       = zero1_o
  *l2_cdf_buffer.SENS1_O.data       = sens1_o
  *l2_cdf_buffer.AMPL1_O.data       = ampl1_o
  *l2_cdf_buffer.PAYLD1_O.data      = payld1_o

  *l2_cdf_buffer.ORTH1_I.data = orth1_i
  *l2_cdf_buffer.ZERO1_I.data = zero1_i
  *l2_cdf_buffer.SENS1_I.data = sens1_i
  *l2_cdf_buffer.AMPL1_I.data = ampl1_i
  *l2_cdf_buffer.PAYLD1_I.data = payld1_i

  l2_write_status = write_data_to_cdf(l2_cdf, l2_cdf_buffer)

  ; The write_data_to_cdf procedure doesn't allow for easy modification
  ; of global variables, so we do it here instead.

  cdf_id = cdf_open(l2_cdf)

  attexst = cdf_attexists(cdf_id,'l1_mago_survey_file')
  if (attexst) then begin
    attid = cdf_attnum(cdf_id, 'l1_mago_survey_file')
    cdf_attput, cdf_id, attid, 0L, 'placeholder_for_input_filename'
    dprint, dlevel = 3, 'Changed l1_mago_survey_file attribute to ','placeholder_for_input_filename'
  endif

  cdf_close, cdf_id

  cdf2tplot, l2_cdf, prefix = 'psp_fld_mag_', verbose=4, /get_support

  options, 'psp_fld_mag_B_SC', 'colors', 'rgb'
  options, 'psp_fld_mag_B_SC', 'labels', ['X','Y','Z']
  options, 'psp_fld_mag_B_SC', 'max_points', 10000

  tplot, 'psp_fld_mag_B_SC'

  options, 'psp_fld_mag_B_SC', 'max_points', 10000

  tplot, 'psp_fld_mag_B_SC'

  stop  

end