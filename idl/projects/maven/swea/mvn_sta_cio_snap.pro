;+
;PROCEDURE:   mvn_sta_cio_snap
;PURPOSE:
;  Makes plots of statistics within individual pixels in maps created with
;  mvn_sta_cio_plot.
;
;USAGE:
;  mvn_sta_cio_snap, data
;
;INPUTS:
;       data:       A data structure returned by mvn_sta_cio_plot.
;
;KEYWORDS:
;       KEEP:       Keep the last snapshot window on exit.
;
;       RESULT:     Structure to hold the last distribution on exit.
;
;       RANGE:      Range for binning the data.  Default = minmax(data).
;
;       NBINS:      Number of bins.  Default = 30.
;
;       LPOS:       Legend position [X,Y], relative coordinates.
;
;       ALLSTAT:    Include skewness and kurtosis in legend.
;
;       This routine also passes keywords to PLOT.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-05-01 12:25:49 -0700 (Fri, 01 May 2020) $
; $LastChangedRevision: 28658 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_snap.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_snap.pro
;-
pro mvn_sta_cio_snap, data, keep=keep, result=result, range=range, nbins=nbins, lpos=lpos, $
                      allstat=allstat, nostat=nostat, _extra=extra

  result = 0
  dorange = n_elements(range) eq 2
  if (dorange) then range = range(sort(range))
  dostat = ~keyword_set(nostat)
  if not keyword_set(nbins) then nbins = 30

  case n_elements(lpos) of
     0   : lpos = [0.70, 0.85]
     1   : lpos = [lpos, 0.85]
    else : lpos = lpos[0:1]
  endcase

; Remember the graphics settings of the original plot

  pwin = !d.window
  xsys = !x
  ysys = !y
  zsys = !z
  psys = !p

; Make a new window to hold the snapshot

  if (not execute('wset,29',2,1)) then window, 29, xsize=700, ysize=500
  swin = !d.window

; Get a point on the original plot

  ok = 1
  nplot = 0
  wset, pwin
  crosshairs, cx, cy, /nolegend, /silent, /oneclick, lastbutton=button

  while (ok) do begin
    dx = min(abs(data.x - cx), i)
    dy = min(abs(data.y - cy), j)
    z = reform(data.dist[i,j,*])
    indx = where(finite(z), count)
    valid = data.valid[i,j]

; Put up a snapshot in the new window

    wset, swin

    if ((count gt 0) and valid) then begin
      if (not dorange) then range = minmax(z[indx])
      dz = (range[1] - range[0])/float(nbins)
      h = histogram(z[indx], binsize=dz, loc=hz, min=range[0], max=range[1])

      plot,hz,h,psym=10,charsize=1.8,xtitle=data.zvar,ytitle='Sample Number',_extra=extra
      hz = [hz[0] - dz, hz, max(hz) + dz]
      h = [0., h, 0.]
      result = {x:hz, y:h, dx:dz, npts:data.npts[i,j], mean:data.z[i,j], $
                median:data.med[i,j], skew:data.skew[i,j], kurt:data.kurt[i,j]}
    
      oplot,hz,h,psym=10
      
      if (dostat) then begin
        oplot,[data.z[i,j],data.z[i,j]],[0,10*max(h)],color=6,linestyle=2
        oplot,[data.med[i,j],data.med[i,j]],[0,10*max(h)],color=2,linestyle=2

        mx = lpos[0]
        my = lpos[1]
        mdy = 0.05
        msg = strcompress(string(data.npts[i,j],format='("Samples = ",i8)'))
        xyouts, mx, my, /norm, msg, charsize=1.5
        my -= mdy
        msg = strcompress(string(data.med[i,j],format='("Median = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5, color=2
        my -= mdy
        msg = strcompress(string(data.z[i,j],format='("Mean = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5, color=6
        my -= mdy
        msg = strcompress(string(data.sdev[i,j],format='("Std Dev = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5
        my -= mdy      
        if keyword_set(allstat) then begin
          msg = strcompress(string(data.skew[i,j],format='("Skewness = ",g8.3)'))
          xyouts, mx, my, /norm, msg, charsize=1.5
          my -= mdy
          msg = strcompress(string(data.kurt[i,j],format='("Kurtosis = ",g8.3)'))
          xyouts, mx, my, /norm, msg, charsize=1.5
          my -= mdy
        endif
      endif
    endif else begin
      erase
      xyouts, 0.5, 0.5, /norm, "No Data", charsize=3.0, align=0.5, charthick=2
    endelse

; Restore the original graphics settings and get the next point

    wset, pwin
    !x = xsys
    !y = ysys
    !z = zsys
    !p = psys
    
    nplot++

    crosshairs, cx, cy, /nolegend, /silent, /oneclick, lastbutton=button, /lastpoint
    if (button eq 4) then ok = 0

  endwhile

  if ~keyword_set(keep) then wdelete, swin

  return

end
