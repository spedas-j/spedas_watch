; the purpose of this routine is to plot MAVEN quicklook data
; alongside EMUS geometry and brightness data using the tplot routine
; for a certain time span

; the keyword DISK is a structure produced by the routine
; emm_emus_examine_disk. If this has already been run, you can provide
; this directly to save time.

pro emm_emus_maven_ql, time_range, disk = disk

  emissions = ['O I 130.4 triplet', 'O I 135.6 doublet']

  !p.background = 255
  !p.color = 0
  tplot_options,var_label= ['sza', 'orbnum']
  window, 1, xsize = 1300, ysize = 770 
  brightness_range = [[2, 20], [1, 8]]
  zlog = [1, 0]
  

  mvn_ql_pfp_tplot, time_range, /pad, window = 1,/bcrust,sep = 0, sta = 0, euv = 0, $
                    lpw = 0,/mag,/spacewe,/restore
; calculate cone and clock angles
  get_data, 'mvn_mag_bmso_1sec', data =  bmso
  if Size (bmso,/type) ne 8 then message, 'B-field data does not exist for this time range.'
  bx= bmso.y [*, 0] & by = bmso.y [*, 1] & bz = bmso.y [*, 2]
  Clock = clock_angle (by, bz) 
  cone =  cone_angle (bx, by, bz) 
  bphi = ATAN(by, bx)
  btotal = sqrt (BX*BX + By*by + bz*bz)
  btheta = ASIN(bz / btotal)
  store_data, 'cone', data = {x: bmso.x, y:cone}
  store_data, 'clock', data = {x:bmso.x, y: clock}
  
  aopt = {yaxis: 1, ystyle: 1, yrange: [0, 180], ytitle: 'Bcone [deg]', $
          color: 6, yticks: 4, yminor: 3}
  IF tag_exist(topt, 'charsize') THEN str_element, aopt, 'charsize', topt.charsize, /add
  store_data, 'mvn_mag_cone_clock', data=$
              {x: bmso.x, y: [ [2.*cone], [clock]]}, $
              dlimits={psym: 3, colors: [6, 0], ytitle: 'MAG MSO', $
                       ysubtitle: 'Bclock [deg]', $
                       yticks: 4, yminor: 3, axis: aopt}
  ylim, 'mvn_mag_cone_clock', 0., 360., 0., /def
  options, 'mvn_mag_cone_clock', ystyle=9

  if not keyword_set (disk) then  emm_emus_examine_disk, time_range, $
     emission = emissions, color_table = [8, 3], $
     brightness_range = brightness_range, zlog =zlog, $
     disk = disk
  Timespan, time_range 
  emm_emus_image_bar,trange = time_range, disk = disk, $
                     brightness_range = brightness_range 

  !p.charsize = 1.2 
  Tplot, ['mvn_swis_en_eflux', 'mvn_swe_etspec','mvn_mag_bamp', $
          'mvn_mag_cone_clock', 'alt2',$
          'emus_lt','emus_br','emus_O_1304'] 
end

