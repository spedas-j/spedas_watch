pro spp_fld_make_cdf_l2_mag, $
  trange = trange, $
  input_cdf_files = input_cdf_files, $
  load = load
  
  ;.compile read_mycdf
  ;.compile IDLmakeCDF

  trange = time_double(['2018-03-18/20:00:00','2018-03-19/00:00:00'])
  
  ; Generate 1 minute time cadence during time range
  
  n_min = long((trange[1] - trange[0]) / 60d)
  
  unix_time_1min = trange[0] + 60d * dindgen(n_min)
  
  timespan, trange
  
  ; Creation of a L2 CDF file requires input L1 CDF files

  ; For the MAG L2 file, these are required:

  l1_cdf_datatypes = ['mago_survey', 'magi_survey', 'mago_hk', 'magi_hk']

  test_dir = '/Users/pulupa/Desktop/spp_fld_test/FM_ucb/2018/03/20180319_050525_Test_MAGi_sinusoid_temp/'

  l1_cdf_files = dictionary(l1_cdf_datatypes)

  foreach l1_cdf_datatype, l1_cdf_datatypes do begin

    l1_cdf_files[l1_cdf_datatype] = test_dir + 'spp_fld_l1_' + l1_cdf_datatype + '_20180318_200000_20180319_000000_v00.cdf'

  end

  l2_master_cdf = '/Users/pulupa/Documents/idlpro/spdsw/projects/SPP/fields/skt/l2/psp_fld_l2_mag_00000000_v00.cdf'

  l2_cdf = '/Users/pulupa/Documents/idlpro/spdsw/projects/SPP/fields/skt/l2/psp_fld_l2_mag_TEST_v00.cdf'

  ; Change some global attributes
  
  foreach l1_cdf_file, l1_cdf_files do spp_fld_load_l1, l1_cdf_file

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)
  
  cdf_leap_second_init

  get_data, 'spp_fld_magi_survey_mag_bx_nT', data = mago_bx
  get_data, 'spp_fld_magi_survey_mag_by_nT', data = mago_by
  get_data, 'spp_fld_magi_survey_mag_bz_nT', data = mago_bz
  
  get_data, 'spp_fld_magi_survey_range', data = mago_range
  
  unix_time = mago_bx.x
  
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