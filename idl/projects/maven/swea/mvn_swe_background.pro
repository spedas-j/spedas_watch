; Fitting function for SWEA penetrating particle and radioactive decay background.
;
; background = (penetrating particle)*(1 - Mars shielding) + radioactive decay
;
;   h   = spacecraft altitude (km)
;   a   = penetrating particle background for zero Mars shielding
;   k40 = background from radioactive decay of potassium 40
;

function swe_background, h,  parameters=p,  p_names=p_names, pder_values=pder_values

  if not keyword_set(p) then p = {func:'swe_background', a:1D, k40:0D}

  if n_params() eq 0 then return, p

  Rm = 3389.5D                        ; +/- 0.2, volumetric radius of Mars (km)
  sina = Rm/(Rm + h)                  ; sine of half-angle subtended by Mars
  y = (1D - sqrt(1D - sina*sina))/2D  ; fraction of sky blocked by Mars
  f = p.a*(1D - y) + p.k40            ; background vs. altitude

  if keyword_set(p_names) then begin
     np = n_elements(p_names)
     nd = n_elements(f)
     pder_values = dblarr(nd,np)
     for i=0,np-1 do begin
        case strupcase(p_names(i)) of
            'A'   : pder_values[*,i] = 1D - y
            'K40' : pder_values[*,i] = 1D
        endcase
     endfor
  endif

  return, f

end

;+
;PROCEDURE:   mvn_swe_background
;PURPOSE:
;  At energies above ~1 keV, the SWEA count rate comes from three
;  sources:  >1-keV electrons, penetrating high-energy particles, and
;  radioactive decay of potassium 40 in the MCP glass.  Often, the
;  background from penetrating particles and radioactive decay dominates
;  the signal, so it is essential to remove this background to obtain
;  reliable measurements of the >1-keV electron component.
;
;  Protons with energies above ~20 MeV and electrons with energies above
;  ~2 MeV can penetrate the instrument housing and internal walls to pass
;  through the MCP, where they can trigger electron cascades and generate
;  counts.  Galactic Cosmic Rays (GCRs) peak near 1 GeV and easily pass
;  through the instrument (and the entire spacecraft), resulting in a
;  background count rate of several counts per second summed over all
;  anodes.  GCR's are isotropic, but Mars effectively shields part of the
;  sky.  Since MAVEN's orbit is elliptical, the GCR background varies 
;  along the orbit according to the changing angular size of the planet.
;  SEP events are episodic, but can increase the penetrating particle
;  background by orders of magnitude for days.
;
;  Since penetrating particles bypass SWEA's optics, they result in a
;  constant count rate across SWEA's energy range.  The GCR background is
;  ~1 count/sec/anode, varying by a factor of two over the solar cycle.
;  Penetrating background can be identified by a constant count rate in
;  SWEA's highest energy channels.  However, there are times when < 4.6 keV
;  electrons are present at the same time as penetrating particles.  This
;  is particularly true during SEP events.  When this happens, this routine
;  will overestimate the background, so it may be necessary to fit the 
;  measured signal with a model that includes contributions from >1-keV
;  electrons, penetrating particles, and radioactive decay.
;
;  Potassium 40 has a half-life of ~1 billion years, so it generates a 
;  constant background.  This part of the background does not vary along 
;  the orbit, so it can in principle be separated from the GCR background.
;  One good measurement of the potassium 40 background can be used for
;  the entire mission.
;
;  This routine estimates the penetrating particle background when the
;  highest four energy channels (3.3 to 4.6 keV) exhibit a constant count
;  rate.  If there is any slope in this energy range, then you should not
;  use this routine, but instead do a 3-parameter fit to the measurements.
;
;  This routine requires SPICE.
;
;USAGE:
;  mvn_swe_background
;
;INPUTS:
;  None.       SPEC data are obtained from the SWEA common block.
;
;KEYWORDS:
;  K40:        If set, then fit for the radioactive decay background in
;              addition to the penetrating particle background.
;              Default = 0 (no).
;
;  NBINS:      Number of altitude bins for the >3.3-keV count rate data.
;              Default = 30.
;
;  EXCLUDE:    If set, interactively exclude one or more time ranges from
;              the fit.  This can be used to exclude times when the >3.3-keV
;              count rate is not constant.
;
;  RESULT:     Returns the fitted/assumed results:
;                alt   = altitude bins
;                data  = average >3.3-keV count rate per bin
;                sdev  = statistical uncertainty for each bin
;                npts  = number of points per bin
;                model = count rate vs. altitude for best fit
;                units = count rate per anode
;                a     = penetrating background count rate corresponding
;                        to zero shielding from Mars (alt -> infinity)
;                a_sigma = uncertainty in a
;                k40   = count rate from radioactive decay of potassium 40
;                        in the MCP glass
;                k40_sigma = uncertainty in k40 (if applicable)
;
;  RESIDUAL:   Create a tplot variable that shows the residual (measured 
;              background subtract model).  Default = 1 (yes).
;
;  SHOWFIT:    If set, show the fit results in a separate window.  The top
;              panel shows the binned count rate vs. altitude along with the
;              best fit.  The next two panels show the number of samples per
;              bin and the Poisson correction.
;
;SEE ALSO:
;   mvn_swe_secondary:  Calculates the secondary electron background.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-22 16:23:25 -0700 (Mon, 22 Jul 2024) $
; $LastChangedRevision: 32756 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_background.pro $
;
;CREATED BY:    David L. Mitchell  07-05-24
;FILE: mvn_swe_background.pro
;-
pro mvn_swe_background, k40=k40, residual=residual, result=result, nbins=nbins, $
                        exclude=exclude, showfit=showfit

  @mvn_swe_com

; Make sure data and ephemeris exist

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print, "You must load SWEA SPEC data first.", format='(/,a,/)'
    return
  endif

  mvn_spice_stat, check=mvn_swe_engy.time, summary=sinfo, /silent
  if (sinfo.spk_check eq 0) then begin
    print,"Insufficient SPICE SPK coverage for SWEA SPEC data.",format='(/,a)'
    print,"   SPEC: ",time_string(minmax(spec.time)),format='(a,a19," - ",a19)'
    print,"    SPK: ",time_string(sinfo.spk_trange),format='(a,a19," - ",a19)'
    print,"Reinitialize SPICE and try again.",format='(a,/)'
    return
  endif

  res = (n_elements(residual) gt 0) ? keyword_set(residual) : 1
  k40 = keyword_set(k40)
  nbins = (n_elements(nbins) gt 0) ? fix(nbins[0]) : 30
  exclude = keyword_set(exclude)
  showfit = keyword_set(showfit)

; Prepare SPEC data for analysis

  spec = mvn_swe_engy                                ; get SPEC data from the common block
  spec.bkg = 0.                                      ; clear the background array
  mvn_swe_secondary, spec                            ; calculate secondary contamination
  old_units = spec[0].units_name                     ; remember the original units
  mvn_swe_convert_units, spec, 'crate'               ; convert units to corrected count rate
  bkg = average(spec.data[0:3,*], 1, /nan)           ; estimate penetrating particle background
  bkgs = smooth_in_time(bkg, spec.time, 64)          ; smooth in time by 64 sec (32 spectra)
  store_data, 'swe_bkg', data={x:spec.time, y:bkgs}  ; make a tplot variable of smoothed data
  options, 'swe_bkg', 'ytitle', 'CRATE (>3.3 keV)'

; Choose a graphics window.  Make one if necessary.

  device, window_state=ws
  tplot_options, get=topt
  str_element, topt, 'window', i, success=ok
  if (ok) then begin
    if (ws[i]) then wset, i else win, i, /center
  endif else if (~max(ws)) then win, 0, /center
  twin = !d.window

; Determine which panels to plot.  Make sure swe_bkg is on the list.

  str_element, topt, 'varnames', varnames, success=ok
  if (not ok) then begin
    mvn_swe_sumplot, /load
    tplot, ['alt2','swe_bkg','swe_a4']
  endif else begin
    i = where(strmatch(topt.varnames, 'swe_bkg*'), count)
    if (count gt 0) then tplot else tplot, 'swe_bkg', add=-1
  endelse

; Get altitude

  timestr = time_string(spec.time,prec=5)
  cspice_str2et, timestr, et
  cspice_spkezr, 'MAVEN', et, 'IAU_MARS', 'NONE', 'Mars', state, ltime
  mvn_altitude, cart=state[0:2,*], datum='ell', result=dat
  h = dat.alt
  undefine, dat

; Exclude data from the fit

  mask = replicate(1B, n_elements(spec.time))
  if (exclude) then begin
    ok = 1
    print, "Select time range(s) to exclude from the fit (right click to exit) ... "
    while (ok) do begin
      ctime, tt, npoints=2, /silent
      cursor,cx,cy,/norm,/up  ; make sure mouse button is released
      if (n_elements(tt) eq 2) then begin
        indx = where(spec.time ge min(tt) and spec.time le max(tt), count)
        if (count gt 0L) then begin
          mask[indx] = 0B
          timebar, min(tt), /line, color=4
          timebar, max(tt), /line, color=6
        endif
      endif else ok = 0
    endwhile
  endif

  jndx = where(mask eq 1B, count)
  if (count eq 0) then begin
    print, "No data to fit."
    return
  endif

; Bin and fit the measurements

  bindata, h[jndx], bkg[jndx], xbins=nbins, result=dat

  p = swe_background()
  if (k40) then names = 'a k40' else names = 'a'
  fit, dat.x, dat.y, dy=dat.sdev, param=p, names=names, function='swe_background', $
                         p_values=pval, p_sigma=psig
  yfit = swe_background(dat.x, param=p)

; Plot the fit results

  if (showfit) then begin
    win, /free, /sec, dx=10, xsize=800, ysize=1000, /yfull
    fwin = !d.window
    !x.omargin = [2,4]
    !p.multi = [0,1,3]  ; starting panel, number of columns, number of rows
      csize = 2.7
      lsize = 1.5
      xrange = [0., ceil(max(dat.x)/1000.)*1000.]
      plot, dat.x, dat.y, psym=10, xtitle='', ytitle='Count Rate (>3.3 keV)', yrange=[0.5,1.1], /ysty, $
            title='Penetrating Background', charsize=csize, xrange=xrange, /xsty
      oplot, dat.x, yfit, color=4, thick=2
      msg = 'Rate(alt -> !4y!1H) = ' + string(pval[0],format='(f4.2)') + ' +/- ' + string(psig[0],format='(f5.2)')
      xyouts, 0.55, 0.83, strcompress(msg) , /norm, charsize=lsize, color=4
      msg = 'K40 = ' + string(p.k40,format='(f5.2)')
      if (n_elements(psig) gt 1) then msg += ' +/- ' + string(psig[1],format='(f5.2)') else msg += ' (assumed)'
      xyouts, 0.55, 0.80, strcompress(msg) , /norm, charsize=lsize, color=4

      plot_io, dat.x, float(dat.npts), psym=10, xtitle='', ytitle='Number', $
            title='Number of Samples', charsize=csize, xrange=xrange, /xsty

      plot_io, dat.x, 0.5/(dat.y * dat.npts), psym=10, xtitle='Altitude (km)', $
            ytitle='Correction', title='Poisson Correction', charsize=csize, xrange=xrange, /xsty
    !p.multi = 0
    !x.omargin = [0,0]
  endif

; Create the result structure

  result = {trange:minmax(spec.time), alt:dat.x, data:dat.y, sdev:dat.sdev, npts:dat.npts, $
            model:yfit, units:'crate/anode', a:p.a, a_sigma:psig[0], k40:p.k40}

  if (n_elements(psig) gt 1) then str_element, result, 'k40_sigma', psig[1], /add $
                             else str_element, result, 'k40_sigma', !values.d_nan, /add

; Create/update tplot variables

  bkg_model = swe_background(h, param=p)
  vname = 'swe_bkg_model'
  store_data, vname, data={x:spec.time, y:bkg_model}
  options, vname, 'line_colors', 5
  options, vname, 'colors', [6]
  options, vname, 'thick', 2

  vname = 'swe_bkg_comp'
  store_data, vname, data=['swe_bkg','swe_bkg_model']
  options, vname, 'ytitle', 'CRATE (>3.3 keV)'
  options, vname, 'line_colors', 5
  options, vname, 'colors', [4,6]
  options, vname, 'labels', ['data', 'model']
  options, vname, 'labflag', 1
  if (k40 gt 0.) then begin
    options, vname, 'constant', k40
    options, vname, 'const_line', 2
    options, vname, 'const_color', 5
    options, vname, 'const_thick', 2
  endif else begin
    options, vname, 'constant', -1.
  endelse

  tplot_options, get=topt
  varnames = topt.varnames
  imax = n_elements(varnames) - 1
  i = where(varnames eq 'swe_bkg', count)
  if (count gt 0) then varnames[i] = vname
  i = where(varnames eq vname, count)
  if (count eq 0) then begin
    firstvars = [varnames[0:i], vname]
    if (i lt imax) then varnames = [firstvars, varnames[(i+1):imax]]
  endif

  if (res) then begin
    vname = 'swe_bkg_residual'
    store_data,vname,data={x:spec.time, y:(bkgs - bkg_model)}
    options,vname, 'ytitle', 'Residual'
    options,vname, 'constant', 0
    options,vname, 'line_colors', 5
    options,vname, 'const_color', 6
    options,vname, 'const_line', 0
    options,vname, 'const_thick', 2

    j = where(varnames eq vname, count)
    if (count eq 0) then begin
      imax = n_elements(varnames) - 1
      firstvars = [varnames[0:i], vname]
      if (i lt imax) then varnames = [firstvars, varnames[(i+1):imax]]
    endif
  endif

  wset, twin
  tplot, varnames                                ; display the measured background and model

; Save the result

  spec.bkg += replicate(1.,64) # bkg_model       ; sum secondary and penetrating bkgs
  mvn_swe_convert_units, spec, old_units         ; convert back to original units
  mvn_swe_engy = temporary(spec)                 ; store the result in the common block

end
