pro spp_fld_make_cdf_l2_mag, $
  l2_master_cdf, l2_cdf, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir, $
  downsample_cadence = downsample_cadence

  l2_cdf_buffer = read_master_cdf(l2_master_cdf,l2_cdf)

  if n_elements(trange) EQ 1 then trange = trange + [0d, 86400d]

  ; MAGo only for now

  ; Read raw count data from the Level 1 TPLOT variables

  get_data, 'spp_fld_mago_survey_mag_bx', data = mago_bx
  get_data, 'spp_fld_mago_survey_mag_by', data = mago_by
  get_data, 'spp_fld_mago_survey_mag_bz', data = mago_bz

  get_data, 'spp_fld_mago_survey_range', data = mago_range

  get_data, 'spp_fld_mago_survey_CCSDS_MET_Seconds', data = mago_met
  get_data, 'spp_fld_mago_survey_CCSDS_MET_SubSeconds', data = mago_ssec

  ; Raw vectors

  rawVectors = transpose([[mago_bx.y], [mago_by.y], [mago_bz.y]])

  ; Read Andriy Koval's time dependent offset files

  mago_offset_file_2018 = '/Users/pulupa/Documents/spp_svn/06_SOC/calibrations/mag_offsets_andriy/psp_mago_zeros_range0_2018_v00.dat'
  mago_offset_file_2019 = '/Users/pulupa/Documents/spp_svn/06_SOC/calibrations/mag_offsets_andriy/psp_mago_zeros_range0_2019_v00.dat'

  mago_offset_2018 = read_ascii(mago_offset_file_2018)
  mago_offset_2019 = read_ascii(mago_offset_file_2019)

  mago_offset = [[mago_offset_2018.field01],[mago_offset_2019.field01]]

  mago_year = reform(mago_offset[0,*])
  mago_doy =  reform(mago_offset[1,*])

  ; The times in the files are mid-day

  mago_time = time_double(string(mago_year, format = '(I4)') + '-' + $
    string(mago_doy, format = '(I03)') + $
    '/12:00:00', tformat = 'YYYY-DOY/hh:mm:ss')

  mago_off = {time:mago_time, $
    year:reform(mago_offset[0,*]), $
    doy:reform(mago_offset[1,*]), $
    range:reform(mago_offset[2,*]), $
    flag:reform(mago_offset[3,*]), $
    xzero:reform(mago_offset[4,*]), $
    yzero:reform(mago_offset[5,*]), $
    zzero:reform(mago_offset[6,*]), $
    xrms:reform(mago_offset[7,*]), $
    yrms:reform(mago_offset[8,*]), $
    zrms:reform(mago_offset[9,*])}

  ; Interpolate offset values for each sample time stamp

  mago_xzero = interp(mago_off.xzero, mago_off.time, mago_bx.x)
  mago_yzero = interp(mago_off.yzero, mago_off.time, mago_by.x)
  mago_zzero = interp(mago_off.zzero, mago_off.time, mago_bz.x)

  ; Use magConvertAndRotate to subtract the offsets

  mag_data = magConvertAndRotate('MAGo', rawVectors, 0, transpose([[mago_xzero], [mago_yzero],[mago_zzero]]))

  ; Calculate the UTC time for the MAG packets from the MET and subseconds
  ; values for each packet

  utc_packets = psp_fld_met_to_utc(mago_met.y, mago_ssec.y)

  ; Calculate the time (in TPLOT/unix time) for each sample time with an
  ; interpolating function from the calculated UTC (SPICE-corrected) and unix
  ; time (uncorrected) for the packet times

  unix_time = interp(time_double(utc_packets), mago_met.x, mago_bx.x)


  ; Generate 1 minute time cadence during time range for various metadata
  ; variables

  n_min = long((trange[1] - trange[0]) / 60d)

  unix_time_1min = trange[0] + 60d * dindgen(n_min)

  ; Load the SC to RTN rotation matrix at a time cadence of 1 minute

  spp_fld_load_ephem, ref = 'SPP_RTN', timein = unix_time_1min

  get_data, 'spp_fld_cmat_SPP_RTN', data = cmat_rtn

  ; Interpolate the rotation matrix to each sample value

  n_full = n_elements(unix_time)

  cmat_rtn_full = dblarr(n_full, 3, 3)

  for i = 0, 2 do begin
    for j = 0, 2 do begin

      cmat_rtn_full[*,i,j] = interp(cmat_rtn.y[*,i,j],unix_time_1min,unix_time)

    endfor
  endfor

  ; Calculate TT2000 time stamps

  tt2000_time = long64((add_tt2000_offset(unix_time)-time_double('2000-01-01/12:00:00'))*1.e9)
  tt2000_time_1min = long64((add_tt2000_offset(unix_time_1min)-time_double('2000-01-01/12:00:00'))*1.e9)


  ; Define MAG metadata variables (1 per sample)

  mag_mode = lonarr(n_full)
  mago_rate = lonarr(n_full)
  magi_rate = lonarr(n_full)
  quality_flag = lonarr(n_full)
  
  mago_rng = mago_range.y


  ; Limit to fixed boundaries

  tt2000_min = long64((add_tt2000_offset(trange[0]) - time_double('2000-01-01/12:00:00'))*1e9)
  tt2000_max = long64((add_tt2000_offset(trange[1]) - time_double('2000-01-01/12:00:00'))*1e9)

  tt2000_valid = where((tt2000_time GE tt2000_min) and (tt2000_time LT tt2000_max), valid_count)

  if valid_count EQ 0 then return
  
  tt2000_time  = tt2000_time[tt2000_valid]
  
  mag_data     = mag_data[*,tt2000_valid]

  mag_mode     = mag_mode[tt2000_valid]
  mago_rate    = mago_rate[tt2000_valid]
  mago_rng     = mago_rng[tt2000_valid]
  magi_rate    = magi_rate[tt2000_valid]
  quality_flag = quality_flag[tt2000_valid]

  ;stop

  if keyword_set(downsample_cadence) then begin
    
    ns_interval = downsample_cadence * 1e9
    
    n_intervals = long((tt2000_max - tt2000_min) / ns_interval)
    
    h = histogram(tt2000_time, binsize = ns_interval, min = tt2000_min, nbins = n_intervals, rev = ri, locations = loc)
    
    tt2000_time_ds  = lon64arr(n_intervals)

    mag_data_ds     = dblarr(3,n_intervals)

    mag_mode_ds     = lonarr(n_intervals)
    mago_rate_ds    = lonarr(n_intervals)
    mago_rng_ds     = lonarr(n_intervals)
    magi_rate_ds    = lonarr(n_intervals)
    quality_flag_ds = lonarr(n_intervals)

    for i = 0, n_elements(h) - 1 do begin
      
      tt2000_time_ds[i] = loc[i] + ns_interval / 2
      
      ri0 = ri[ri[i]]
      ri1 = ri[ri[i+1]-1]
      
      if ri1 GE ri0 then begin
        mag_data_ds[*,i] = mean(mag_data[*,ri0:ri1],dim=2)
        mag_mode_ds[i] = mag_mode[ri0]
        mago_rate_ds[i] = mago_rate[ri0]
        mago_rng_ds[i] = mago_rng[ri0]
        magi_rate_ds[i] = magi_rate[ri0]
        quality_flag_ds[i] = quality_flag[ri0]
      endif

      
    endfor
    
    tt2000_time  = tt2000_time_ds

    mag_data     = mag_data_ds
    mag_mode     = mag_mode_ds
    mago_rate    = mago_rate_ds
    mago_rng     = mago_rng_ds
    magi_rate    = magi_rate_ds
    quality_flag = quality_flag_ds
    
    ;stop
    
  endif

  ; Rotate to RTN coordinates

  mag_data_rtn = transpose(cmat_rtn_full,[1,2,0]) # mag_data

  ; Define 1 minute metadata

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

  ; Write data to the L2 CDF buffer (see spp_fld_make_cdf_l2)

  *l2_cdf_buffer.Epoch.data         = tt2000_time
  *l2_cdf_buffer.Epoch1.data        = tt2000_time_1min

  *l2_cdf_buffer.B_SC.data          = mag_data
  *l2_cdf_buffer.B_RTN.data         = mag_data_rtn
  *l2_cdf_buffer.RANGE.data         = mago_rng

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

end