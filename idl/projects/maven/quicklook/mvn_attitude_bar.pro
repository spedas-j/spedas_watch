;+
;PROCEDURE:   mvn_attitude_bar
;PURPOSE:
;  Creates a horizontal color bar for tplot, where the spacecraft attitude
;  is coded by color:
;
;    orange = Sun point
;    blue   = Earth point
;
;USAGE:
;  mvn_attitude_bar
;
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-02-17 09:13:07 -0800 (Sun, 17 Feb 2019) $
; $LastChangedRevision: 26640 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_attitude_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_attitude_bar

  mvn_sundir, frame='spacecraft', /pol
  get_data,'Sun_PL_The',data=sth
  npts = n_elements(sth.x)
  sun_th = sth.y

  et = time_ephemeris(sth.x)
  cspice_spkpos, 'Earth', et, 'MAVEN_MSO', 'NONE', 'Mars', pearth, ltime
  pearth = transpose(pearth)/1.495978707d8
  xearth = pearth[*,0]/sqrt(total(pearth*pearth,2))
  earth_th = 90D - acos(xearth)*!radeg  ; elongation of Earth from Mars

  bname = 'mvn_att_bar'
  y = replicate(!values.f_nan,npts,2)
  indx = where(abs(sun_th - 90.) lt 0.5, count)      ; s/c pointing at Sun
  if (count gt 0L) then y[indx,*] = 0.8
  indx = where(abs(sun_th - earth_th) lt 0.5, count) ; s/c pointing at Earth
  if (count gt 0L) then y[indx,*] = 0.3

  store_data,bname,data={x:sth.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,1,0
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1

  return
end
