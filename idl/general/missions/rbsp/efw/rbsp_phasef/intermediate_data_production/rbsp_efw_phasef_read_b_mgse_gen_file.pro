;+
; Preprocess and load b_mgse to memory.
;-

pro rbsp_efw_phasef_read_b_mgse_gen_file, time, probe=probe, filename=file

;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif


;---Constants and settings.
    secofday = 86400d
    errmsg = ''

    prefix = 'rbsp'+probe+'_'
    if size(time[0],/type) eq 7 then time = time_double(time)
    date = time[0]-(time[0] mod secofday)
    time_range = date+[0,secofday]

    b_mgse_var = prefix+'b_mgse'
    time_step = 1d/16
    common_times = make_bins(time_range, time_step)
    ntime = n_elements(common_times)
    ndim = 3
    b_mgse = fltarr(ntime,ndim)+!values.f_nan
    store_data, b_mgse_var, common_times, b_mgse
    add_setting, b_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )
        

;---Load B UVW.
    b_uvw_var = prefix+'b_uvw'
    rbsp_read_emfisis, time_range+[-1,1]*60, probe=probe, id='l2%magnetometer'
    get_data, b_uvw_var, times
    
;---Remove invalid data and convert b_uvw to b_mgse.
    index = lazy_where(times, '[]', time_range, count=count)
    if count ge 10 then begin
        ; Mask invalid data with NaN.
        cal_state = get_var_data(prefix+'cal_state', times=uts)
        mag_valid = get_var_data(prefix+'mag_valid')
        bad_index = where(cal_state ne 0 or mag_valid eq 1, count, complement=good_index)
        fillval = !values.f_nan
        pad_time = 10.   ; sec.
        if count ne 0 then begin
            time_ranges = uts[time_to_range(bad_index,time_step=1)]
            ntime_range = n_elements(time_ranges)*0.5
            b_uvw = get_var_data(b_uvw_var, times=uts)
            for ii=0,ntime_range-1 do begin
                index = lazy_where(uts, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
                if count eq 0 then continue
                b_uvw[index,*] = fillval
            endfor
            store_data, b_uvw_var, uts, b_uvw            
        endif
        
        b_uvw = get_var_data(b_uvw_var, times=uts)
        b_valid = -99999
        pad_time = 0.   ; sec.
        bad_index = where((b_uvw[*,0] lt b_valid) or (b_uvw[*,1] lt b_valid) or (b_uvw[*,2] lt b_valid), count)
        if count ne 0 then begin
            time_ranges = uts[time_to_range(bad_index,time_step=1)]
            ntime_range = n_elements(time_ranges)*0.5
            for ii=0,ntime_range-1 do begin
                index = lazy_where(uts, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
                if count eq 0 then continue
                b_uvw[index,*] = fillval
            endfor
            store_data, b_uvw_var, uts, b_uvw
        endif
        
        interp_time, b_uvw_var, common_times
        b_uvw = get_var_data(b_uvw_var)
        b_mgse = cotran(b_uvw, common_times, 'uvw2mgse', probe=probe)
        store_data, b_mgse_var, common_times, b_mgse
    endif


    if probe eq 'b' then begin
        bad_time_range = time_double(['2018-09-27/04:00','2018-09-27/14:00'])
        get_data, b_mgse_var, times, b_mgse
        index = lazy_where(times, '[]', bad_time_range, count=count)
        if count ne 0 then begin
            b_mgse[index,*] = !values.f_nan
            store_data, b_mgse_var, times, b_mgse
        endif
    endif


;---Save data.
    path = fgetpath(file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    data_file = file
    if file_test(data_file) eq 1 then file_delete, data_file  ; overwrite old files.

    ginfo = dictionary($
        'TITLE', 'RBSP EMFISIS B field in mGSE', $
        'TEXT', 'Generated by Sheng Tian at the University of Minnesota' )
    cdf_save_setting, ginfo, filename=file
    save_vars = b_mgse_var
    stplot2cdf, save_vars, istp=1, filename=file, time_var='epoch'



end

;
;stop
;probes = ['a','b']
;root_dir = join_path([rbsp_efw_phasef_local_root()])
;secofday = constant('secofday')
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    time_range = rbsp_efw_phasef_get_valid_range('b_mgse', probe=probe)
;    days = make_bins(time_range+[0,-1]*secofday, secofday)
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,'efw_phasef','b_mgse',rbspx,str_year])
;        base = prefix+'b_mgse_'+time_string(day,tformat='YYYY_MMDD')+'_v01.cdf'
;        file = join_path([path,base])
;;if file_test(file) eq 1 then continue
;        print, file
;        rbsp_efw_phasef_read_b_mgse_gen_file, day, probe=probe, filename=file
;    endforeach
;endforeach
;stop


time_range = time_double(['2013-01-01','2013-01-02'])
time_range = time_double(['2015-12-29','2015-12-31'])   ; wrong data.
time_range = time_double(['2012-09-06','2012-09-07'])
probe = 'a'
file = join_path([homedir(),'test_b_mgse.cdf'])

time_range = time_double(['2018-09-27','2018-09-28'])   ; weird data.
probe = 'b'

;time_range = time_double(['2012-09-16','2012-09-17'])
;probe = 'a'

rbsp_efw_phasef_read_b_mgse_gen_file, time_range, probe=probe, filename=file
end
