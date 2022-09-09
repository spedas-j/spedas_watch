;+
;PROCEDURE:   emm_emus_image_bar
;PURPOSE:
;  Creates tplot variables representing the longitudes and local times
;of image sampling.
;
;USAGE:
;  emm_emus_image_bar, /local_time,/longitude
;
;INPUTS:
;
;KEYWORDS:
;      trange:   time range for which image bars are requested

;
; $LastChangedBy: rlillis3 $
; $LastChangedDate: 2022-09-08 06:21:19 -0700 (Thu, 08 Sep 2022) $
; $LastChangedRevision: 31072 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/emm/emm_emus_image_bar.pro $
;
;CREATED BY:    Rob Lillis
;-
pro emm_emus_image_bar, trange = trange

  ltname = 'image_LT'
  elonname = 'image_elon'
  
  Pathnames = '/disks/hope/home/rlillis/?'
  y = replicate(1.,n_elements(wake.x),2)
  indx = where(finite(wake.y), count)
  if (count gt 0L) then y[indx,*] = 0.

  store_data,bname,data={x:wake.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,-0.5,3.5,0 ; optimized for color table 43
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
