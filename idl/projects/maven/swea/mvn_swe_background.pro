;+
;FUNCTION:   mvn_swe_background
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
;  PERIAPSIS:  Measure the penetrating background at periapsis instead of
;              apoapsis.  Useful when periapsis is the only part of the
;              orbit where the 3.3-to-4.6-keV count rate is constant.
;
;  K40:        The count rate due to radioactive decay of potassium 40 in
;              the MCP glass.  This should be a single value that's valid
;              for the entire mission.
;
;  RESIDUAL:   Create a tplot variable that shows the residual (measured 
;              background subtract model).
;
;SEE ALSO:
;   mvn_swe_secondary:  Calculates the secondary electron background.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-14 11:32:59 -0700 (Sun, 14 Jul 2024) $
; $LastChangedRevision: 32745 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_background.pro $
;
;CREATED BY:    David L. Mitchell  07-05-24
;FILE: mvn_swe_background.pro
;-
pro mvn_swe_background, periapsis=periapsis, k40=k40, residual=residual

  @mvn_swe_com

; Make sure data and ephemeris exist

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print, "You must load SWEA SPEC data first.", format='(/,a,/)'
    return
  endif

  mvn_spice_stat, check=mvn_swe_engy.time, summary=sinfo, /silent
  if (sinfo.spk_check eq 0) then begin
    print,"Insufficient SPICE coverage for SWEA SPEC data.",format='(/,a)'
    print,"   SPEC: ",time_string(minmax(spec.time)),format='(a,a19," - ",a19)'
    print,"    SPK: ",time_string(sinfo.spk_trange),format='(a,a19," - ",a19)'
    print,"Try reinitializing SPICE.",format='(a,/)'
    return
  endif

  peri = keyword_set(periapsis)
  k40 = n_elements(k40) gt 0 ? float(k40[0]) : 0.

; Prepare SPEC data for analysis

  spec = mvn_swe_engy                                ; get SPEC data from the common block
  spec.bkg = 0.                                      ; clear the background array
  mvn_swe_secondary, spec                            ; calculate secondary contamination
  old_units = spec[0].units_name                     ; remember the original units
  mvn_swe_convert_units, spec, 'crate'               ; convert units to corrected count rate
  bkg = average(spec.data[0:3,*], 1, /nan)           ; estimate penetrating particle background
  bkgs = smooth_in_time(bkg, spec.time, 64)          ; smooth in time by 64 sec (32 spectra)
  store_data, 'swe_bkg', data={x:spec.time, y:bkgs}  ; make a tplot variable
  options, 'swe_bkg', 'ytitle', 'CRATE (>3.3 keV)'

  tplot_options, get=topt
  i = where(strmatch(topt.varnames, 'swe_bkg*'), count)
  if (count gt 0) then tplot else tplot, 'swe_bkg', add=-1

; Interactively find a time range for measuring the background

  msg = peri ? 'PERIAPSIS' : 'APOAPSIS'
  print," "
  print,"Choose a time range around " + msg + " where the >3.3 keV count rate is constant."
  swe_engy_snap, /sum, yrange=[1e-1,1e5], units='crate', result=dat
  tmean, 'swe_bkg', trange=dat.trange, result=dat
  bkg_avg = dat.mean

; Correct for variable Mars shielding

  timestr = time_string(spec.time,prec=5)
  cspice_str2et, timestr, et
  cspice_spkezr, 'MAVEN', et, 'IAU_MARS', 'NONE', 'Mars', state, ltime
  mvn_altitude, cart=state[0:2,*], datum='ell', result=result

  Rm = 3389.5                                    ; Mars volumetric mean radius, km
  x = Rm/(Rm + result.alt)                       ; sine of half-angle subtended by Mars
  blk = (1. - sqrt(1 - x*x))/2.                  ; fraction of sky blocked by Mars
  bkg_model = (bkg_avg - k40)*(1. - blk)/(1. - (minmax(blk))[peri]) + k40

  store_data, 'swe_bkg_model', data={x:spec.time, y:bkg_model}
  options, 'swe_bkg_model', 'thick', 2

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
  endif

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

  if keyword_set(residual) then begin
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

  tplot, varnames                                ; display the measured background and model

; Save the result

  spec.bkg += replicate(1.,64) # bkg_model       ; sum secondary and penetrating bkgs
  mvn_swe_convert_units, spec, old_units         ; convert back to original units
  mvn_swe_engy = spec                            ; store the result in the common block

end
