;+
; Read orbit number.
; Adopted from rbsp_read_ect_mag_ephem.
; This is obsoleted b/c the ect orbit number contains jumps occasionally at the beginning of a day.
;
; time. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_phasef_read_ect_orbit_num_gen_file, time, probe=probe, filename=file, $
    errmsg=errmsg, log_file=log_file


;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        lprmsg, errmsg, log_file
        return
    endif

;---Constants and settings.
    secofday = 86400d
    errmsg = ''
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    date = time[0]-(time[0] mod secofday)
    time_range = date+[0,secofday]
    tr = time_range
    timespan, tr[0], total(tr*[-1,1]), /seconds
    rbsp_read_ect_mag_ephem, probe
    orbnum_var = prefix+'orbit_num'
    rename_var, prefix+'ME_orbitnumber', to=orbnum_var

    ; In rare cases, this data is missing for the requested day.
    get_data, orbnum_var, data=dd
    if size(dd,/type) ne 8 then begin
        tr = time_range-secofday

        rbsp_efw_phasef_read_orbit_num, tr[0], probe=probe
        orbit_num = get_var_data(orbnum_var, times=times)
        rename_var, orbnum_var, to=prefix+'orbit_num1'

        ;timespan, tr[0], secofday, /second
        ;rbsp_read_ect_mag_ephem, probe
        ;orbit_num = get_var_data(prefix+'ME_orbitnumber')

        diff = orbit_num[1:-1]-orbit_num[0:-2]
        index = where(diff eq 1, count)
        if count eq 0 then begin
            perigee_times = tr[0]
            orbit_nums = orbit_num[0]
            orbit_num0 = orbit_nums[-1]
        endif else begin
            perigee_times = times[index]
            orbit_nums = orbit_num[index+1] ; The new orbit number after passing perigee.
            orbit_num0 = orbit_nums[-1]
        endelse

        ; Read one more orbit to ensure we catch the full perigee.
        rbsp_read_orbit, time_range+[-9,9]*3600, probe=probe, coord='gse'
        dis = snorm(get_var_data(prefix+'r_gse', times=uts))
        index = where(dis le 2, count)
        if count eq 0 then message, 'Invalid orbit data ...'
        perigee_time_ranges = uts[time_to_range(index,time_step=1)]
        nperigee = n_elements(perigee_time_ranges)*0.5
        perigee_uts = dblarr(nperigee)
        for perigee_id=0, nperigee-1 do begin
            index = lazy_where(uts, '[]', perigee_time_ranges[perigee_id,*])
            min_dis = min(dis[index], min_index)
            perigee_uts[perigee_id] = (uts[index])[min_index]
        endfor
        max_time = max(perigee_times)
        index = where(perigee_uts ge max_time)
        perigee_uts = [max_time,perigee_uts[index]]


        time_step = 60.
        common_times = make_bins(time_range, time_step)
        ncommon_time = n_elements(common_times)
        data = fltarr(ncommon_time)
        nperigee_ut = n_elements(perigee_uts)-1
        for ii=0, nperigee_ut-1 do begin
            index = lazy_where(common_times, '[)', perigee_uts[ii:ii+1], count=count)
            if count eq 0 then continue
            data[index] = orbit_num0
            orbit_num0 += 1
        endfor
        store_data, orbnum_var, common_times, data
    endif


    time_step = 60.
    common_times = make_bins(time_range, time_step)
    get_data, orbnum_var, times, data
    data = round(interpol(data, times, common_times))
    store_data, orbnum_var, common_times, data


;---Save data.
    save_var = orbnum_var
    path = fgetpath(file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    data_file = file
    if file_test(data_file) eq 1 then file_delete, data_file  ; overwrite old files.

    ginfo = dictionary($
        'TITLE', 'RBSP orbit number', $
        'TEXT', 'Generated by Sheng Tian at the University of Minnesota, adopted from rbsp_read_ect_mag_ephem' )
    cdf_save_setting, ginfo, filename=file
    get_data, save_var, times, data
    store_data, save_var, times, float(data), limits={units:'#'}
    stplot2cdf, save_var, istp=1, filename=file, time_var='epoch'

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'

; No orbit num for this day.
probe = 'a'
date = time_double('2015-06-30')
file = join_path([homedir(),'test.cdf'])
rbsp_efw_phasef_read_ect_orbit_num_gen_file, date, probe=probe, filename=file
end