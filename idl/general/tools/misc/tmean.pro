;+
;PROCEDURE:   tmean
;PURPOSE:
;  Calculate the mean, median, and standard deviation of a 1-D tplot
;  variable over a specified time range.  The variable and time range
;  are selected with the cursor or via keyword.  Skew and kurtosis
;  are also calculated:
;
;    skewness: = 0 -> distribution is symmetric about the maximum
;              < 0 -> distribution is skewed to the left
;              > 0 -> distribution is skewed to the right
;
;    kurtosis: = 0 -> distribution is peaked like a Gaussian
;              < 0 -> distribution is less peaked than a Gaussian
;              > 0 -> distribution is more peaked than a Gaussian
;
;  This routine can optionally perform 1-D cluster analysis to divide
;  the data into two groups (Jenks natural breaks optimization).
;  Statistics are given for each group separately.
;
;USAGE:
;  tmean, var
;
;INPUTS:
;       var:     Tplot variable name or number.  If not specified, determine
;                based on which panel the mouse is in when clicked.  Currently,
;                this routine only works with 1-D data.
;
;KEYWORDS:
;       TRANGE:  Use this time range instead of getting it interactively
;                with the cursor.  In this case, you must specify var.
;
;       OFFSET:  Value to subtract from the data before calculating statistics.
;                Default = 0.
;
;       OUTLIER: Ignore values more than OUTLIER sigma from the mean.
;                Default = infinity.
;
;       MINPTS:  If OUTLIER is set, this specifies the minimum number of 
;                points remaining after discarding outliers.  Default = 3.
;
;       CORE:    Perform 1-D cluster analysis to separate the data into
;                two groups.  Disables OUTLIER.
;
;       MAXDZ:   Use largest break between clusters near minimum variance
;                to divide the clusters.  Default = 1.
;
;       RESULT:  Named variable to hold the result.
;
;       HIST:    Plot a histogram of the distribution in a separate window.
;
;       NBINS:   If HIST is set, number of bins in the histogram.
;
;       NPTS:    Number of points surrounding the selected point.
;
;       DST:     Retain the distribution.  Does not allow compiling multiple
;                results.
;
;       T0:      Times in cluster 0.
;
;       T1:      Times in cluster 1.
;
;       DIAG:    Return cluster analysis diagnostics:
;                  minvar : minimum total variance
;                  maxvar : maximum total variance
;                  maxsep : separation between clusters
;                  sepval : value of optimal separation
;
;       SILENT:  Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-05-16 09:18:55 -0700 (Mon, 16 May 2022) $
; $LastChangedRevision: 30824 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/tmean.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro tmean, var, trange=trange, offset=offset, outlier=outlier, result=result, hist=hist, $
                nbins=nbins, npts=npts, silent=silent, minpts=minpts, dst=dst, core=core, $
                t0=t0, t1=t1, maxdz=maxdz, diag=diag

  @swe_snap_common

  oflg = keyword_set(outlier)
  blab = ~keyword_set(silent)
  if (n_elements(minpts) eq 0) then minpts = 3 else minpts = round(minpts)
  if (n_elements(nbins) eq 0) then nbins = 32 else bins = fix(nbins[0])
  hist = keyword_set(hist)
  core = keyword_set(core)
  if (core) then oflg = 0  ; disable OUTLIER removal for cluster analysis
  dst = keyword_set(dst)
  if (dst) then undefine, result
  if (size(maxdz,/type) eq 0) then maxdz = 1
  maxdz = keyword_set(maxdz)
  t0 = 0D
  t1 = 0D
  if (size(offset,/type) eq 0) then offset = 0. else offset = float(offset[0])

  diag = {minvar:0., maxvar:0., maxsep:0., sepval:0.}

  if (n_elements(trange) lt 2) then begin
    if keyword_set(npts) then ctime, tsp, panel=p, npoints=1, prompt='Choose a variable/time' $
                         else ctime, tsp, panel=p, npoints=2, prompt='Choose a variable/time range'
    cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(tsp,/type) ne 5) then return
  endif else begin
    if (size(var,/type) eq 0) then begin
      print,"Keyword TRANGE requires the tplot variable to be specified."
      return
    endif
    tsp = minmax(time_double(trange))
  endelse

  if (size(var,/type) eq 0) then begin
    tplot_options, get=topt
    var = topt.varnames[p[0]]
  endif

; Make sure variable exists and can be interpreted properly

  get_data, var, data=dat, alim=lim, index=i
  if (i eq 0) then begin
    print,'Variable not defined: ',var
    return
  endif
  str_element, dat, 'x', success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  str_element, dat, 'y', success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  if ((size(dat.y))[0] gt 1) then begin
    print,'Only works for 1-D variables: ',var
    return
  endif

; Create plot window(s)

  if (hist) then begin
    twin = !d.window
    putwin, /free, /secondary, xsize=800, ysize=600, dx=10
    hwin = !d.window
    if (core) then begin
      putwin, /free, relative=hwin, xsize=800, ysize=600, dx=10
      vwin = !d.window
    endif
  endif

; Select data

  keepgoing = 1

  while (keepgoing) do begin
    result = 0

    if keyword_set(npts) then begin
      i = nn2(dat.x, tsp[0])
      indx = lindgen(npts) + (i - npts/2)
      j = where((indx ge 0L) and (indx le (n_elements(dat.x)-1L)), ntot)
      if (ntot gt 0L) then begin
        indx = indx[j]
        tmin = min(dat.x[indx], max=tmax)
      endif
    endif else begin
      tmin = min(tsp, max=tmax)
      indx = where((dat.x ge tmin) and (dat.x le tmax), ntot)
    endelse

    if (ntot eq 0L) then begin
      print,"No data within range."
      if (hist) then begin
        wdelete, hwin
        if (core) then wdelete, vwin
        wset, twin
      endif
      return
    endif
    x = dat.x[indx]
    y = dat.y[indx] - offset

    kndx = where(finite(y), ntot)
    if (ntot lt minpts) then begin
      print,"Fewer than ",strtrim(string(minpts),2)," good points."
      if (hist) then begin
        wdelete, hwin
        if (core) then wdelete, vwin
        wset, twin
      endif
      return
    endif
    if (ntot gt 0L) then begin
      x = x[kndx]
      y = y[kndx]
    endif

; Group the data into two clusters (Jenks natural breaks optimization)

    if (core) then begin
      z = y[sort(y)]
      avg1 = replicate(!values.f_nan,ntot)
      avg2 = avg1
      var1 = avg1
      var2 = avg1
      for i=2,(ntot-4) do begin
        mom  = moment(z[0:i], maxmoment=2, /nan)
        avg1[i]  = mom[0]
        var1[i]  = mom[1]
        mom  = moment(z[i+1:ntot-1], maxmoment=2, /nan)
        avg2[i]  = mom[0]
        var2[i]  = mom[1]
      endfor

      v = var1 + var2
      dv = v - shift(v,1)
      dv[0] = !values.f_nan
      sign = dv * shift(dv,1)
      sign /= abs(sign)
      indx = where(sign lt 0., count) - 1L  ; local extrema (excludes endpoints)
      if (count eq 0L) then begin
        print,"Cluster analysis found no local minimum in the variance."
        if (hist) then begin
          wdelete, hwin
          if (core) then wdelete, vwin
          wset, twin
        endif
        return
      endif
      minvar = min(v[indx], j)              ; deepest local minimum
      icut = indx[j]

      if (maxdz) then begin
        nz = n_elements(z)
        dz = z - shift(z,1)
        dz[[0,(nz-1)]] = !values.f_nan
        nj = (nz - icut)/4 > 3
        mdz = max(dz[icut:(icut+nj)], jcut)
        icut += (jcut - 1)
      endif
      ycut = (z[icut] + z[icut+1])/2.
      nclusters = 2

      diag = {minvar: minvar         , $
              maxvar: max(var1+var2) , $
              maxsep: mdz            , $
              sepval: ycut              }

    endif else begin
      icut = ntot - 1
      ycut = max(y)
      nclusters = 1
    endelse

; Calculate the mean and standard deviation within requested time range

    for i=0,(nclusters-1) do begin
      if (i eq 0) then begin
        j = where(y le ycut, count)
        xc = x[j]
        yc = y[j]
        t0 = xc
      endif else begin
        j = where(y gt ycut, count)
        xc = x[j]
        yc = y[j]
        t1 = xc
      endelse

      mom  = moment(yc, mdev=adev, /nan)
      avg  = mom[0]
      rms  = sqrt(mom[1])

      if (oflg) then begin
        maxdev = float(outlier[0])*rms
        jndx = where(abs(yc - avg) le maxdev, ngud, ncomplement=nbad)
        while ((nbad gt 0) and (ngud ge minpts)) do begin
          xc = xc[jndx]
          yc = yc[jndx]
          if (blab) then print,"Removing ",strtrim(string(nbad),2)," outliers."
          mom  = moment(yc, mdev=adev, /nan)
          avg  = mom[0]
          rms  = sqrt(mom[1])
          maxdev = float(outlier[0])*rms
          jndx = where(abs(yc - avg) le maxdev, ngud, ncomplement=nbad)
        endwhile
      endif

      skew = mom[2]
      kurt = mom[3]
      med  = median(yc)
      lim = minmax(yc)

; Report the result

      tmp = {varname : var            , $
             cluster : i              , $
             time    : mean(xc)       , $
             trange  : [tmin, tmax]   , $
             offset  : offset         , $
             lim     : lim            , $
             median  : med            , $
             mean    : avg            , $
             stddev  : rms            , $
             rerr    : abs(rms/avg)   , $
             skew    : skew           , $
             kurt    : kurt           , $
             npts    : n_elements(yc)    }

      if (dst) then str_element, tmp, 'y', yc, /add

      str_element, result, 'varname', success=ok
      if (ok) then result = [result, tmp] else result = tmp

      if (blab) then begin
        print,"Cluster  : ",strtrim(string(i),2)
        print,"Variable : ",var
        print,"  ",time_string(tmin)," --> ",strmid(time_string(tmax),11)
        print,"  # points : ",n_elements(yc)
        print,"  Offset   : ",offset
        print,"  Minimum  : ",lim[0]
        print,"  Maximum  : ",lim[1]
        print,"  Median   : ",med
        print,"  Average  : ",avg
        print,"  Stddev   : ",rms
        print,"  Rel Err  : ",abs(rms/avg)
        print,"  Skew     : ",skew
        print,"  Kurtosis : ",kurt
        print,""
      endif
    endfor

    if (blab and core) then print,"Clusters divide at: ",ycut,format='(a,f,/)'

    if (hist) then begin
      if (core) then begin
        wset, vwin
        plot,z,(var1+var2),psym=-4,ytitle='Total Variance',charsize=1.8
        oplot,[ycut,ycut],[0.,2.*max(var1+var2)],line=2,color=6
      endif
      wset, hwin
      if keyword_set(nbins) then nbins = fix(nbins) else nbins = 32
      range = minmax(y)
      dy = (range[1] - range[0])/float(nbins)
      h = histogram(y, binsize=dy, loc=hy, min=range[0], max=range[1])
      title = 'N = ' + strtrim(string(round(total(h))),2)

      hy = [min(hy)-dy, hy, max(hy) + dy]  ; complete drawing of first and last bins
      h  = [0, h, 0]

      plot,hy,h,psym=10,charsize=1.8,xtitle=var,ytitle='Sample Number',title=title,_extra=extra
      for i=1,5 do begin
        oplot,[avg,avg]+(i*rms),[0,2.*max(h)],linestyle=1,color=4
        oplot,[avg,avg]-(i*rms),[0,2.*max(h)],linestyle=1,color=4
      endfor
      ; oplot,[med,med],[0,2.*max(h)],linestyle=2,color=6

      if (core) then begin
        oplot,[ycut,ycut],[0,2.*max(h)],linestyle=2,color=6
        fcol = 1  ; color for cluster 1
        avg = result[1].mean
        rms = result[1].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        j = where(hy gt ycut)
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h[j])/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2

        fcol = 4  ; color for cluster 0
        avg = result[0].mean
        rms = result[0].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        j = where(hy lt ycut)
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h[j])/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2
      endif else begin
        fcol = 1
        avg = result[0].mean
        rms = result[0].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h)/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2
      endelse

      wset, twin    
    endif

    if (n_elements(trange) lt 2) then begin
      if keyword_set(npts) then ctime, tsp, panel=p, npoints=1, prompt='Choose a variable/time' $
                           else ctime, tsp, panel=p, npoints=2, prompt='Choose a variable/time range'
      cursor,cx,cy,/norm,/up  ; make sure mouse button is released
      if (size(tsp,/type) ne 5) then keepgoing = 0
    endif else keepgoing = 0

  endwhile

  if (hist) then begin
    wdelete, hwin
    if (core) then wdelete, vwin
    wset, twin
  endif

  return

end
