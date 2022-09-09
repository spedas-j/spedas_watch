

; The purpose of this script is to examine auroral emissions image by
; EMUS, to categorize them according to crustal magnetic fields and
; solar wind conditions

; the keywords for MAVEN and Mars Express are for when we want to plot
; their positions and ground tracks on the images

; the satellite and hammer keywords refer to the projections

pro emm_emus_examine_disk, time_range, MAVEN = MAVEN, MEX = MEX, $
                        satellite = satellite, hammer = hammer

; note that this routine only works with a local source of
; files. It doesn't do anything fancy like search for latest
; versions in an online database.
  os2 = emm_file_retrieve (time_range,level = 'l2b', mode = 'os2', local_path = $
                          '/disks/hope/home/rlillis/emm/data/')
  os1 = emm_file_retrieve (time_range,level = 'l2b', mode = 'os1', local_path = $
                          '/disks/hope/home/rlillis/emm/data/')
  osr = emm_file_retrieve (time_range,level = 'l2b', mode = 'osr', local_path = $
                          '/disks/hope/home/rlillis/emm/data/')

  all_files = ''
  file_indices = replicate (-1, 3, 1)
  dates = ''
  mode = ''
  if size (os2,/type) eq 8 then begin
     all_files = [all_files,os2.files]
     file_indices = [[file_indices],[os2.file_indices]] ; FS = file structure
     dates = [dates, os2.dates]
     nos2= n_elements (os2.dates)
     mode = [mode, replicate ('os2',nos2)]
  endif
  
  if size (osr,/type) eq 8 then begin
     nosr= n_elements (osr.dates)
     all_files = [all_files,osr.files]
; to make sure the file_indices array treats the OS2 and OSR files in
; order
     add = intarr(3, nosr)
     add [0,*] = max (os2.file_indices) +1
     file_indices = [[file_indices], [add + osr.file_indices]]
     dates = [dates, osr.dates]
     mode = [mode, replicate ('osr',nosr)]
  endif
 
  if n_elements (all_files) eq 1 then message, 'No valid files for this time range!'

; get rid of the first dummy element of the files array
  all_files = all_files [1:*]
  file_indices = file_indices [*, 1:*]
  set_count = n_elements (file_indices [0,*])
  mode = mode[1:*]
  dates = dates[1:*]

; Need to define the wavelength array to interpolate to
  dwv = 0.5                     ; nanometers
  Wavelength_min = 82.5
  wavelength_max = 201.5
  nwv= round (wavelength_max - wavelength_min)/dwv
  wavelength_array =  wavelength_min +dwv*findgen (nwv)

; examine the bands you want to see in L2a
  bands = ['O989','O1304', 'O1356']
  nb = n_elements (bands)
  wv_ranges = [[97.5, 100.5], [129.0, 132.0], [134.5, 137.5]]
  index_ranges = value_locate (wavelength_array, WV_ranges)
; color scale maximum   
  zmax = [10.0, 50.0, 500.0]
; keep track of every pixel separately
  nint_Max = 260
  NPIX_Max = 192                ; pixels along the slit.  Usually 128, sometimes 192
  max_swaths = 3
  nc = 5                        ; middle +4 corners

; define a structure, one element for each swath
  aurora = {files: '', $
            date_String: '', $
            time:dblarr (nint_max)*sqrt (-7.2), $
            bmag:fltarr (nint_max, npix_max)*sqrt (-7.2), $
            belev:fltarr (nint_max, npix_max)*sqrt (-7.2), $ 
            local_time:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            mrh:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $ ,$
            sza:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            ea:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            latss:fltarr (nint_max)*sqrt (-7.2), $
            elonss:fltarr (nint_max)*sqrt (-7.2), $
            elon:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            lat:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            bands: Bands, $
            Rad:fltarr (nint_max, npix_max, nb)*sqrt (-7.2), $
            sc_alt:fltarr (nint_max)*sqrt (-7.2), $
            SC_pos: fltarr(3, nint_max)*sqrt (-7.2), $ ; MSO
            elon_ssc:fltarr (nint_max)*sqrt (-7.2), $
            lat_ssc:fltarr (nint_max)*sqrt (-7.2), $
            lat_MSO_look:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
            elon_MSO_look:fltarr (nint_max, npix_max, nc)*sqrt (-7.2),$
            MAVEN_pos_Geo: fltarr(3,nint_max)*sqrt (-7.2), $
            MEX_pos_GeO: fltarr(3,nint_max)*sqrt (-7.2), $
            MAVEN_pos_MSO: fltarr(3,nint_max)*sqrt (-7.2), $
            MEX_pos_MSO: fltarr(3,nint_max)*sqrt (-7.2)}
  
  aurora = replicate (Aurora, set_count, max_swaths)

  wv_string = sTRarr (nb)
  for K = 0, nb-1 do begin
     wv_string [k] = roundst (wv_ranges [0, k], dec = -1) + '-' + $
                     roundst (wv_ranges [1, k], dec = -1) + ' nm'
  endfor
  
                                ;for K = 0, 27-1 do print, k,data.emiss[k].name
  
  emission_index = [4, 17, 18]

  
; load up crustal magnetic field model from Langlais [2019]
  Langlais_file = '/home/rlillis/work/data/spherical_harmonic_models/Langlais2018/Langlais2018_150km_0.25deg.sav'
  restore, Langlais_file
  nelon_Langlais = n_elements (Langlais.Elon)
  nlat_Langlais = n_elements (Langlais.lat)
  
  restore,'/home/rlillis/work/data/spherical_harmonic_models/Morschhauser_spc_dlat0.5_delon0.5_dalt10.sav'
  Altitude = 300.0              ; kilometers
  altitude_index = value_locate (Morschhauser.altitude, altitude)
  bradius = reform (Morschhauser.b[0, altitude_index,*,*])
  btheta = reform (Morschhauser.b[1, altitude_index,*,*])
  bphi = reform (Morschhauser.b[2, altitude_index,*,*])
  nelon_Morschhauser = n_elements (Morschhauser.longitude)
  nlat_Morschhauser = n_elements (Morschhauser.latitude)

  Aurora_file = '~/work/emm/emus/data/aurora_' + $
                time_string (time_range [0], tformat = 'YYYY-MM-DD') + '_to_' + $
                time_string (time_range [1], tformat = 'YYYY-MM-DD') + '.sav'
                                ;if file_test (aurora_file) then goto, here

  
  color_tables = [1,8,7]

; try running Justin's code
                                ; file_array = all_files [file_indices [*, 12]]
                                ;.r emus_map_vis_mean_aurora
                                ;emus_map_vis_mean_aurora, file_array
  

  !p.charsize = 2.6
  dt= 10.0; seconds
  time_range = time_double (time_range)
  t_total = time_double (time_range [1]) - time_double (time_range [0])
  nt = round (T_total/dt)
  time_range [1] = time_range [0] + dt*nt
  Times = array (time_range [0], time_range [1],nt)

  et = time_ephemeris(times)
  
; load up MAVEN position for this entire time
  if keyword_set (maven) then begin
     maven_kernels = mvn_spice_kernels(trange = time_range,/load, $
                                       ['STD','SCK','FRM','IK','SPK']) 
    
     objects = ['MAVEN_SC_BUS','MAVEN', 'MARS']
     time_valid = spice_valid_times(et,object=objects) 
     printdat,check_objects,time_valid
     ind = where(time_valid ne 0,nind)
     if ind[0] eq -1 then begin
        print, 'SPICE kernels are missing for all the requested times.'
        return
     endif 
     
     MAVEN_position_GEO = spice_body_pos('MAVEN','MARS',utc=times,$
                                         et=et,frame='IAU_MARS',check_objects='MAVEN')
     MAVEN_position_MSO = spice_body_pos('MAVEN','MARS',utc=times,$
                                         et=et,frame='MAVEN_MSO',check_objects='MAVEN')

     cart2latlong, MAVEN_position_Geo [0,*], MAVEN_position_Geo [1,*], $
                   MAVEN_position_Geo [2,*], r_MAVEN,lat_MAVEN, elon_MAVEN
  endif

  if keyword_set (mex) then begin
     mex_kernels = mex_spice_kernels(trange = time_range,/load, $
                                     ['SCK','FRM','IK','SPK']) 
     
     MEX_position_GEO = spice_body_pos('MARS EXPRESS','MARS',utc=times,$
                                       et=et,frame='IAU_MARS',check_objects='MARS EXPRESS')
     MEX_position_MSO = spice_body_pos('MARS EXPRESS','MARS',utc=times,$
                                       et=et,frame='MAVEN_MSO',check_objects='MARS EXPRESS')

     cart2latlong, MEX_position_Geo [0,*], MEX_position_Geo [1,*], $
                   MEX_position_Geo [2,*], r_MEX,lat_MEX, elon_MEX
  endif

; we want to look at these in time order
  dates_UNIX = time_double (dates, tformat = 'YYYYMMDDthhmmss')
  order = sort (dates_UNIX[file_indices[0,*]])
  file_indices = file_indices [*, order]

  
  for p = 0, set_count-1 do begin& $
     n_swath = n_elements (where (file_indices [*, p] ge 0))& $
     for l = 0,n_swath-1 do begin& $
     if file_indices [l,p] eq -1 then continue& $
     if not file_test (all_files [file_indices [l, p]]) then continue& $
     Aurora [p, l].files= all_files [file_indices [l, p]]& $
     Aurora [p, l].date_string = dates [file_indices [l, p]]& $
     print, dates [file_indices [l, p]]& $
     endfor& $
     endfor


  for p = 0, set_count-1 do begin
     !p.charsize = 2.5
     n_swath = n_elements (where (file_indices [*, p] ge 0))
     for l = 0,n_swath-1 do begin
        if file_indices [l,p] eq -1 then continue
        if not file_test (all_files [file_indices [l, p]]) then continue
        Aurora [p, l].files= all_files [file_indices [l, p]]
        Aurora [p, l].date_string = dates [file_indices [l, p]]
        print, dates [file_indices [l, p]]
                                ;Data = iuvs_read_fits (all_files [file_indices[l,p]])
        FOV_geom = mrdfits(all_files [file_indices[l,p]],'FOV_GEOM')
        SC_geom = mrdfits(all_files [file_indices[l,p]],'SC_GEOM')
        cal = mrdfits(all_files [file_indices[l,p]],'CAL')
        wv = mrdfits(all_files [file_indices[l,p]],'WAVELENGTH')
        tim = mrdfits(all_files [file_indices[l,p]],'TIME')
        print, all_files [file_indices [l, p]]
; instead of plotting with respect to RA and DEC, more intuitive to
; plot in terms of MSO coordinates
        cart2latlong, FOV_geom.VEC_MSO [*,*, 0], $
                      FOV_geom.VEC_MSO [*,*, 1],$
                      FOV_geom.VEC_MSO [*,*, 2],$
                      radius, MSO_lat, MSO_elon
        nint= n_elements (cal)                    ; number of integrations
        npix = n_elements (FOV_geom[0].ra [*, 0]) ; number of pixels
        print, p, l
        if nint eq 0 then begin
           print, 'Nah'
           continue
        endif
        
        nw = n_elements (wv.wavelength_l2a [*, 0])
        
        aurora [p, l].lat_MSO_look[0:nint -1,0:npix-1,*] = transpose (MSO_LAT, [2, 0, 1])
        aurora [p, l].elon_MSO_look[0:nint -1,0:npix-1,*] = transpose (MSO_ELON, [2, 0, 1])
        
        aurora [p, l].sc_ALT [0:nint -1] = sc_geom.sc_alt
        aurora [p, l].elon_ssc [0:nint -1] = sc_geom.sub_sc_lon
        aurora [p, l].lat_ssc [0:nint -1] = sc_geom.sub_sc_lat

        aurora [p, l].Elonss [0:nint -1] = sc_geom.sub_solar_lon
        aurora [p, l].latss [0:nint -1] = sc_geom.sub_solar_lat
        
        aurora [p, l].sc_pos[*, 0:nint -1] =sc_geom.v_SC_POS_MSO
                                ;aurora [p, l].sc_SLT [0:nint -1] = sc_geom.sub_solar_lat
        

        aurora [p, l].time[0:nint-1] = time_double (tim.time_UTC,$
                                                    tformat = 'YYYY-MM-DDThh:mm:ss.fff')
        
        aurora [p, l].sza [0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.solar_z_angle), [2, 0, 1])
        
        aurora [p, l].ea[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.emission_angle), [2, 0, 1])
        aurora [p, l].local_time[0:nint-1,0:npix-1] = $
           transpose(reform (fov_geom.local_time[*,0,*]))
        
        aurora [p, l].lat[0:nint-1,0:npix-1,*] = transpose (reform (fov_geom.lat), [2, 0, 1])
        aurora [p, l].elon[0:nint-1,0:npix-1,*] = transpose (reform (fov_geom.lon), [2, 0, 1])
        
        aurora [p, l].mrh[0:nint-1,0:npix-1,*] = transpose (reform (fov_geom.mrh_alt), [2, 0, 1])
        
        
; calculate MAVEN and Mars express positions
        if keyword_set (MAVEN) then begin
           for k=0, 2 do begin
              aurora [p, l].MAVEN_POS_Geo [k,0:nint-1] = $
                 interpol (MAVEN_position_Geo[k,*], times, $
                           aurora [p, l].time[0:nint-1],/nan)
              aurora [p, l].MAVEN_POS_MSO [k,0:nint-1] = $
                 interpol (MAVEN_position_MSO[k,*], times, $
                           aurora [p, l].time[0:nint-1],/nan)
           endfor
        endif
        if keyword_set (MEX) then begin
           for k = 0, 2 do begin
              aurora [p, l].MEX_POS_Geo [k,0:nint-1] = $
                 interpol (MEX_position_Geo[k,*], times, aurora [p, l].time[0:nint-1],/nan)
              aurora [p, l].MEX_POS_MSO [k,0:nint-1] = $
                 interpol (MEX_position_MSO[k,*], times, aurora [p, l].time[0:nint-1],/nan)
           endfor
        endif
        if 5 eq 3 then begin
           fractional_indices_longitude = $
              interpol (findgen (nelon_Langlais), Langlais.elon,elon_Geo[p, l,0:nint-1,0:npix-1],/nan)
           fractional_indices_latitude = $
              interpol (findgen (nlat_Langlais),Langlais.lat,lat_Geo [p, l, 0: nint -1,*])
           bmag[p, l,0:nint-1,0:npix-1] = $
              interpolate(sqrt(Langlais.br^2 + $
                               Langlais.bt^2 + $
                               Langlais.bp^2), $
                          fractional_indices_longitude, fractional_indices_latitude)
           belev[p, l,0:nint-1,0:npix-1] = $
              interpolate(asin(Langlais.br/sqrt(Langlais.br^2 + $
                                                Langlais.bt^2 + $
                                                Langlais.bp^2))/!dtor, $
                          fractional_indices_longitude, fractional_indices_latitude)
        endif else begin          
           fractional_indices_longitude = $
              interpol (findgen (nelon_Morschhauser), $
                        Morschhauser.longitude,aurora [p, l].elon[0:nint-1,0:npix-1,0])
           fractional_indices_latitude = $
              interpol (findgen (nlat_Morschhauser), $
                        Morschhauser.latitude,aurora [p, l].lat[0: nint -1,0:npix -1,0])
           aurora [p, l].bmag[0:nint-1,0:npix-1] = $
              interpolate(sqrt(bradius^2 + $
                               btheta^2 + $
                               bphi^2), $
                          fractional_indices_longitude, fractional_indices_latitude)
           aurora [p, l].belev[0:nint-1,0:npix-1] = $
              interpolate(asin(bradius/sqrt(bradius^2 + btheta^2 + bphi^2))/!dtor, $
                          fractional_indices_longitude, fractional_indices_latitude)
        endelse
        
        Radiance = fltarr (nint, npix_max,nwv)
        band_radiance = fltarr (nint, npix_max,nb) 
        
        for j = 0, nint-1 do begin 
           for i = 0, npix-1 do begin 
                                ; find the wavelength indices
              wv_indices = value_locate (wv.wavelength_L2A[*,i], WV_ranges)
              for K = 0, nb-1 do begin                
                 band_radiance [j, i,k] = $
                    int_simple (wv.wavelength_l2a [wv_indices [0, k]+1: wv_indices [1, k]], $
                                cal[j].radiance [wv_indices [0, k]+1: wv_indices [1, k],i])
                 aurora [p, l].rad [j,i, k] = band_radiance [j,i, k]
              endfor
                                ;Print, i, j, rad_Cal [ p, l, j, i, 1]
                                ;if 5 eq 3 then begin 
                                ;plot, wv.wavelength_l2A, cal [j].radiance [*, i], $
                                ;         xtitle = 'wavelength, nm', ytitle = 'radiance, R/nm',/ylog, PSy = 4, $
                                ;         yrange = [1e-2, 1e4]
                                ;   oplot, wavelength_array, radiance [i, j,*], color = 2  
                                ;endif  
;   wait, 0.01 
           endfor
        endfor
        
        band_index = 1          ; 1304
        if 5 eq 3 then begin
           loadct2, 8
           scatter_specplot,aurora[p, l].elon_MSO_look[0: nint -1,*, 0], $
                            aurora[p, l].lat_MSO_look[0: nint -1,*, 0], $
                            aurora[p, l].rad_cal [0: nint -1,*, Band_index],$
                            xtitle= 'MSO longitude, Degrees', $
                            ytitle= 'MSO latitude, Degrees', $
                            ztitle= 'Rayleighs', psy= 6,symsize = 0.27,thick=2, $      
                            xr = xr,title = bands [band_index],$
                            /iso, zr =[0.1, 300],/zlog, $
                            yr = yr,/ystyle,/Xstyle, zstyle = 1
           scatter_specmap,aurora [p, l].elon [0: nint -1,*, 0], $
                           aurora [p, l].lat [0: nint -1,*, 0], $
                           aurora[p, l].rad_cal [0: nint -1,*, Band_index],$
                           zrange = [1.0, 3000],/zlog,/iso
        endif

        
; pixel zero of the detector is outside of our slits so it should
; always be put to zero
        Aurora [p, l].rad [j, 0,*] = 0.0 ;
        obs_string = dates[file_indices [l,p]] +' Sw '+string(l, format = '(I1)')+ ' '
        
     endfor
     
     
     ;.r emus_map_disk_maven_orbit
     ;stop
     ;emus_map_disk_maven_orbit,Aurora [p, *], bands_wanted = [1], radiance_range = $
     ;                          [[2.0, 50.0], [0, 10.0]],zlog=1, Color_Table = [8, 3], $
     ;                          mode = mode[file_indices [*,p]], $
     ;                          MAVEN = MAVEN, MEX = MEX
     If keyword_set (hammer) or keyword_set (satellite) then begin
        emus_map_disk_old, Aurora [p, *], bands_wanted = [0,1,2], zrange = $
                        [[2, 50],[2.0, 50.0], [2, 50.0]],zlog=[1,1,1], $
                           Color_Table = [1, 8, 3], $
                        mode = mode[file_indices [*,p]], hammer = hammer, $
                        satellite = satellite
     endif
                                ;make_JPEG, '~/work/emm/emus/data/os2_figures/' + date_string[file_indices [0, p]] + $
                                ;            bands [1] +'.jpeg'
     ;if p mod 10 eq 0 then save, Aurora, file = Aurora_file
     if p eq set_count -1 then save, aurora, file = Aurora_file
  endfor

  save, Aurora, File = Aurora_file
  
  return
; PRIMARY ISSUE:  aurora is strongest in 1304, but oxygen exosphere
; emits in 1304 also.

  for p = 0, set_count-1 do  begin & $
     for K = 0, 3-1 do print,  p, k, all_files [file_indices [ k, p]] & $
     endfor

;by eye
     
 ;    Print, all_files [file_indices [ k, p]]

 
  ;here:
  restore, aurora_file



; select only nightside pixels
  
  !P.multi = [0, 2, 2]
  !p.charsize = 1.7
  !p.Background = 255

  !p.color = 0

   Radiance_1304 = aurora.rad_MLR [*,*,*,*, 1]
   Radiance_1356 = aurora.rad_MLR [*,*,*,*, 2]
   stop
;first let's figure out where the nightside should begin
  disk_array = (Aurora.mrh lt 140.0)
  disk = Where (disk_array and ea lt 75)
  rad_SZA_1304 = bin_Data (Aurora.SZA[disk], Radiance_1304 [disk], nbins = 120, $
                      minx = 1e-20, maxx = 180.0,xc =szac)
rad_SZA_1356 = bin_Data (Aurora.SZA[disk], Radiance_1356 [disk], nbins = 120, $
                      minx = 1e-20, maxx = 180.0,xc =szac)

  
plot,szac, rad_SZA_1304, PSY = 4,/ylog, yrange = [.001, 1000], xtitle = ' Solar Zenith Angle', $
     ytitle = 'Brightness, Rayleighs', xrange = [0, 180.0], xticks = 6, xminor = 3,/xstyle, $
     ytickunits = 'Scientific'
oplot,szac, rad_SZA_1356, PSY = 4, color = 2
xyouts, 100,100.0, '130.4 nm'
xyouts, 15.0, 8.0, '135.6 nm', color = 2


  center_Elon = reform (Aurora.Elon [0,*,*,*,*])
  center_lat = reform (aurora.lat [0,*,*,*,*])
  ;hs = histogram (alog10 (Aurora.radiance[disk]),min = -2, max = 3, binsize = 0.1

  Night_array =(aurora.SZA gt 110 and Aurora.MRH lt 135 and $
                (Aurora.Local_time gt 18.0 or aurora.Local_time lt 6.0) and $
               aurora.EA lt 60.0)
  night = where (night_array)

; First make a histogram of the radiance 
  ; first on a log scale
 
  HH_1304 = histogram (alog10 (radiance_1304 [night]), min = -1, max = 1.5, $
                  binsize = 0.02, LOC = LOC)
  HH_1356 = histogram (alog10 (radiance_1356 [night]), min = -1, max = 1.5, $
                  binsize = 0.02, LOC = LOC)

  plot, 10.0^ (LOC +0.005), HH_1304, PSY = 10 ,/xlog, xtitle = 'Radiance, R', $
        ytitle = 'Occurrences',/ylog, yrange = [0.7,1e4],/ystyle, $
        title = 'All Nightside pixels SZA > 110' 
  oplot, 10.0^ (LOC +0.005), HH_1356, PSY = 10, color = 2
xyouts, 10,100., '130.4 nm'
xyouts, 0.2, 2.0, '135.6 nm', color = 2

plot,Aurora.Elon [night], Aurora.lat [night], PSY = 3

;make a histogram of the geographic coverage
  dl = 10.0
  loadct2, 1
  geographic_hist = hist_2d(center_Elon [night], center_lat [night], $
                            min1 = 1e-19, max1 = 360, bin1 = DL, $
                            min2 = -90.0, max2 = 90.0,bin2 = DL)
  elon_hist_array = array (DL/2, 360 - DL/2, round (360/DL))
  lat_hist_array = array (-90.0+ DL/2, 90.0 - DL/2,round (180/DL))
  ;generate_custom_color_table, 12
  specmap, Elon_hist_array, lat_hist_array, geographic_hist, limit = $
           {no_interp: 1, xmargin: [7, 11], ztitle: '# observations', $
           title: 'Nightside OS2 Data Density', zrange:[1, 10000], zlog: 1}
  draw_crustal_fields_on_map,/BR, altitud = 400, contours = [-100, -50, -20, 20, 50, 100]

; let's look at one case of aurora, and make plots to show why it's
; difficult to pick out
  ; case one, 20170714
; FIRST A CASE WITH NO AURORA
p = 103 & l = 0
print, all_files [file_indices [l, p]]
rad_1304 = radiance_1304 [p, l,*,*]
rad_1356 = radiance_1356 [p, l,*,*]

good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)
size= 0.05
 HH_1304_none = histogram (alog10 (rad_1304 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)
  HH_1356_none = histogram (alog10 (rad_1356 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)

; next CASE WITH AURORA
P = 86 & L = 1
print, all_files [file_indices [l, p]]
rad_1304 = reform (radiance_1304 [p, l,*,*])
rad_1356 = reform (radiance_1356 [p, l,*,*])

elon = reform (aurora.elon [0, p, l,*,*])
lat = reform (aurora.lat [0, p, l,*,*])

good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)
size= 0.05
 HH_1304_aurora = histogram (alog10 (rad_1304 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)
  HH_1356_aurora = histogram (alog10 (rad_1356 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)

 time_range = ['2021-06-01', ' 2021-07-01']
mvn_swia_load_l2_data,/loadspec,/tplot, trange = time_range,/eflux
  tplot, 'mvn_swis_en_eflux'

  
  loadct2, 8
  !p.background = 0
  !p.Color = 255
  scatter_specmap,Elon [good], lat [good], rad_1304 [good], $
                  zrange = [1, 4],psy = 6, symsize = 0.13,/zlog

loadct2, 34
!p.background = 255
!p.color = 0
; try strong Aurora
P = 109 & L = 0
rad_1304 = radiance_1304 [p, l,*,*]
rad_1356 = radiance_1356 [p, l,*,*]

good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)
size= 0.05
 HH_1304_strong = histogram (alog10 (rad_1304 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)
  HH_1356_strong = histogram (alog10 (rad_1356 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)

; second swap strong Aurora
P = 109 & l = 1
rad_1304 = radiance_1304 [p, l,*,*]
rad_1356 = radiance_1356 [p, l,*,*]

good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)
size= 0.05
 HH_1304_second = histogram (alog10 (rad_1304 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)
  HH_1356_second = histogram (alog10 (rad_1356 [Good]), min = -2, max = 1.5, $
                  binsize = size, LOC = LOC)

obs = date_string[file_indices [l,p]] +' Sw '+$
      string (swath_number [file_indices [l, p]], format = '(I1)')+ ' '

  plot, 10.0^ (LOC +0.5*size), HH_1304_none*1.0/Max (HH_1304_none),/xlog, xtitle = 'Radiance, R', $
        ytitle = 'Normalized Occurrence',ylog= 0,yr = [0.01, 1.0], $
        title = 'SZA > 110', psy=10 
  oplot, 10.0^ (LOC +0.5*size), HH_1304_Aurora*1.0/Max (HH_1304_aurora), color =2, psy=10
  oplot, 10.0^ (LOC +0.5*size), HH_1304_strong*1.0/max (HH_1304_strong), color = 6, PSY = 10

  xyouts, 0.8, 0.8, '1304 No Aurora Example'
  xyouts, 0.8, 0.6, '1304 Moderate Aurora Example', color = 2
 xyouts, 0.8, 0.4, '1304 Strong Aurora Example', color = 6

;compare 
 plot, 10.0^ (LOC +0.5*size), HH_1304_strong*1.0/Max (HH_1304_strong),/xlog, $
       xtitle = 'Radiance, R', xr = [1.0, 100],$
        ytitle = 'Normalized Occurrence',ylog= 0,yr = [0.01, 1.0], $
        title = 'SZA > 110', psy=10 
  oplot, 10.0^ (LOC +0.5*size), HH_1304_second*1.0/max (HH_1304_second), color = 6, PSY = 10

  xyouts, 0.8, 0.8, 'First Swath'
 xyouts, 0.8, 0.4, 'Second swath', color = 6

  
; now to look at temporal variability, look for the spatial overlap
; between the first and second swath of p = 109.  interpolate to
; a regular geographic grid
 elon_Grid = array (0.5, 359.5, 360)
nelon = n_elements (elon_grid)

lat_grid = array (-89.5, 89.5, 180)
nlat = n_elements (lat_grid)

p = 109 & l = 0
fraction_indices_elon_swath1 = $
   interpol (findgen (nelon),elon_grid,reform (Aurora.Elon [0, p, l,*,*]))
fraction_indices_lat_swath1 = $
   interpol (findgen (nlat),lat_grid,reform (Aurora.Lat [0, p, l,*,*]))
rad_1304 = radiance_1304 [p, l,*,*]
rad_1356 = radiance_1356 [p, l,*,*]
good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)

brightness_swath1 = interpolate (rad_1304[good], fraction_indices_Elon_swath1[good], $
                                 fraction_indices_lat_swath1[Good])

p = 109 & l = 1
fraction_indices_elon_swath2 = $
   interpol (findgen (nelon),elon_grid,reform (Aurora.Elon [0, p, l,*,*]))
fraction_indices_lat_swath2 = $
   interpol (findgen (nlat),lat_grid,reform (Aurora.Lat [0, p, l,*,*]))

rad_1304 = radiance_1304 [p, l,*,*]
rad_1356 = radiance_1356 [p, l,*,*]
good = where (aurora.SZA [p, l,*,*] gt 110.0 and Aurora.MRH [p, l,*,*] lt 135.0)

brightness_swath2 = interpolate (rad_1304[good], fraction_indices_Elon_swath1[g], $
                                 fraction_indices_lat_swath1[Good])

difference = (brightness_swath1 - brightness_swath2)*100.0/brightness_swath1

specmap,elon_grid,lat_grid, difference


brightness_swath1 = interpolate


;Let
; now load the SWIA data
 time_range = ['2021-06-01', ' 2021-07-17']
mvn_swia_load_l2_data,/loadmom,/tplot, trange = time_range,/eflux
 get_data, 'mvn_swim_quality_flag',t,flag
 get_data, 'mvn_swim_velocity_MSO', t,  sw_velocity

 get_data,  'mvn_swim_density', t, sw_density
 

;'s load SWIA data from early June 2021 into July

;
; now one with obvious Aurora


; let's set a threshold for aurora
  threshold = 1.0

  Here = where (night_array and  aurora.EA lt 70 and Radiance_1304 gt threshold)

  bmag_hist = histogram (alog10(aurora.bmag [here]), min = 0, max = 3, binsize = 0.1, LOC = LOC)
  bmag_hist_total = histogram (alog10(aurora.bmag [night]), $
                               min = 0, max = 3, binsize = 0.1, LOC = LOC)

  plot, 10.0^ (LOC +0.05), bmag_hist*1.0/bmag_hist_total, PSy = 10,/xlog

!p.multi = [0, 1, 2]
; let's look at a spot where we don't expect Aurora
  here = where (night_array and center_Elon gt 250 and center_Elon lt 280 and $
                center_lat gt 5 and center_lat lt 35)

  Histogram_quiet = histogram (alog10(Radiance_1304 [here]),min = -2, max = 1.5, $
                              binsize = 0.1, LOC = LOC_quiet)
  plot, 10.0^ (LOC_quiet+0.05), histogram_quiet*1.0/total (histogram_quiet), PSY = -4,/xlog
; now compared to the sailboat
  Here = where (night_array and center_Elon gt 170 and center_Elon lt 180 and $
                center_lat gt -45 and center_lat lt -35)
 Histogram_Active = histogram (alog10(Radiance_1304 [here]),min = -2, max = 1.5, $
                              binsize = 0.1, LOC = LOC_Active)
  oplot, 10.0^ (LOC_Active+0.05), histogram_Active*1.0/total (histogram_Active), PSY = -4, color = 2



;============================================
;divide up the mapinto areas with strong vertical field
Active = Where (night_array and abs(Aurora.belev) gt 45.0 and Aurora.bmag gt 250.0)
plot, center_Elon [active], center_lat [active] , PSY = 3

;result:
; a couple of ideas for auroral frequency:
; 1) 

; make a histogram of the local time coverage
  hlt = histogram (aurora.Local_time [night], min = 0.0, max = 24.0, binsize = 1.0, LOC = LOC_LT)
  plot, LOC_LT +0.5, HLT, PSY = 10, Xtitle = 'local time', title = 'All observations', $
        xticks = 6, xminor = 4,/xstyle, xrange = [0, 24]

  bright = where (night_array and radiance_1304 gt 4.0 and Radiance_1304 lt 50)
  hlt_bright = histogram (aurora.Local_time [bright], min = 0.0, max = 24.0, $
                          binsize = 1.0, LOC = LOC_LT)
  plot, LOC_LT +0.5, HLT_bright, PSY = 10, xtitle = 'local time',title = 'Aurora only', $
        xticks = 6, xminor = 4,/xstyle, xrange = [0, 24]
  plot, LOC_LT +0.5, HLT_bright*1.0/HLT, PSY = 10, ytitle = 'Occurrence fraction', $
        xticks = 6, xminor = 4,/xstyle, xrange = [0, 24]

  !p.multi = 0
  scatter_specmap, center_elon [bright], center_lat [bright], Radiance_1304 [bright], $
                   zrange = [0.1, 100],/Zlog, z
                    
  for p = 0, set_count-1 do print, p,' ',date_string [file_indices [*,p]]
     

  !p.multi = [0, 1, 2]
  !p.charsize = 1.6
  p = 43 & l = 0
min_brightness = 0.1
  now = where (Aurora.MRH [p, l,*,*] lt 135.0 and Aurora.SZA [p, l,*,*] gt 110 and $
              radiance_1304 [p, l,*,*] gt min_brightness)
 ; plot, Aurora.SZA [p, l,*,*], Aurora.MRH [p, l,*,*], PSY = 3
  brightness = radiance_1304[p, l,*,*] 
  elon = center_Elon [p, l,*,*]
  lat = center_lat [p, l,*,*]
  
 
  loadct2, 8
  scatter_specmap,Elon [now], lat [now], brightness [now], zrange = [0.1, 10],/zlog, $
                  ztitle = '1304 brightness', title = date_string [file_indices [l, p]],psy=4, $
                  symsize = 0.5
draw_crustal_fields_on_map,/BR, altitud = 400, contours = [-100, -50, -20, 20, 50, 100]

   p = 43 & l = 1
  now = where (Aurora.MRH [p, l,*,*] lt 135.0 and Aurora.SZA [p, l,*,*] gt 110 and $
              radiance_1304 [p, l,*,*] gt min_brightness)
 ; plot, Aurora.SZA [p, l,*,*], Aurora.MRH [p, l,*,*], PSY = 3
  brightness = radiance_1304[p, l,*,*] 
  elon = center_Elon [p, l,*,*]
  lat = center_lat [p, l,*,*]  
   loadct2, 8
 
  scatter_specmap,Elon [now], lat [now], brightness [now], zrange = [0.1, 10], $
                  ztitle = '1304 brightness', title = date_string [file_indices [l, p]], $
                  symsize = 0.5, PSY = 4,/zlog
draw_crustal_fields_on_map,/BR, altitud = 400, contours = [-100, -50, -20, 20, 50, 100]

  
  stop
end
