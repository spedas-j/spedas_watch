;+
;PROCEDURE: 
;	mvn_swe_sciplot
;PURPOSE:
;	Creates a science-oriented summary plot for SWEA and MAG and optionally other 
;   instruments.
;
;   Warning: This routine can consume a large amount of memory:
;
;     SWEA + MAG : 0.6 GB/day
;     SEP        : 0.2 GB/day
;     SWIA       : 0.2 GB/day
;     STATIC     : 3.5 GB/day
;     LPW        : 0.001 GB/day
;     EUV        : 0.004 GB/day
;     -------------------------
;      total     : 4.5 GB/day
;
;   You'll also need memory for performing calculations on large arrays, so you
;   can create a plot with all data types spanning ~1 day per 8 GB of memory.
;
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_sciplot
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;   SUN:       Create a panel for the Sun direction in spacecraft coordinates.
;
;   RAM:       Create a panel for the RAM direction in spacecraft coordinates.
;
;   SEP:       Include two panels for SEP data: one for ions, one for electrons.
;
;   SWIA:      Include panels for SWIA ion density and bulk velocity (coarse
;              survey ground moments).
;
;   STATIC:    Include two panels for STATIC data: one mass spectrum, one energy
;              spectrum.
;
;   NO2:       Include O2+ density calculated from STATIC.  Has no effect unless
;              STATIC keyword is set.
;
;   NO1:       Include O+ density calculated from STATIC.  Has no effect unless
;              STATIC keyword is set.
;
;   LPW:       Include panel for electron density from LPW data.
;
;              Note: if two or more of O2+, O+, and electron densities are present
;              they are combined into a single panel.
;
;   EUV:       Include a panel for EUV data.
;
;   SC_POT:    Include a panel for spacecraft potential.
;
;   EPH:       Named variable to hold ephemeris data.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-06-06 08:45:03 -0700 (Mon, 06 Jun 2016) $
; $LastChangedRevision: 21267 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sciplot.pro $
;
;-

pro mvn_swe_sciplot, sun=sun, ram=ram, sep=sep, swia=swia, static=static, lpw=lpw, euv=euv, $
                     sc_pot=sc_pot, eph=eph, nO1=nO1, nO2=nO2

  compile_opt idl2

  @mvn_swe_com
  @maven_orbit_common
  
  if keyword_set(nO1) then doO1 = 1 else doO1 = 0
  if keyword_set(nO2) then doO2 = 1 else doO2 = 0

  mvn_swe_sumplot,/loadonly
  mvn_swe_sc_pot,/over
  engy_pan = 'swe_a4_pot'
  options,engy_pan,'ytitle','SWEA elec!ceV'

; Try to load resampled PAD data

  mvn_swe_pad_restore
  tname = 'mvn_swe_pad_resample'
  get_data,tname,index=i
  if (i gt 0) then begin
    pad_pan = tname
    options,tname,'ytitle','SWEA PAD!c(111-140 eV)'
  endif else pad_pan = 'swe_a2_280'

; Spacecraft orientation

  alt_pan = 'alt2'

  if keyword_set(sun) then begin
    mvn_swe_sundir
    sun_pan = 'Sun_MAVEN_SPACECRAFT'
    get_data,sun_pan,index=i
    if (i gt 0) then begin
      options,sun_pan,'ytitle','Sun (PL)'
    endif else sun_pan = ''
  endif else sun_pan = ''

  if keyword_set(ram) then begin
    mvn_sc_ramdir
    ram_pan = 'V_sc_MAVEN_SPACECRAFT'
    get_data,ram_pan,index=i
    if (i gt 0) then begin
      options,ram_pan,'ytitle','RAM (PL)!ckm/s'
    endif else ram_pan = ''
  endif else ram_pan = ''

; MAG data

  mvn_swe_addmag
  mvn_mag_geom
  mvn_mag_tplot, /model
  
  mag_pan = 'mvn_mag_bamp mvn_mag_bang'

; SEP electron and ion data - sum all look directions for both units

  sep_pan = ''
  if keyword_set(sep) then mvn_swe_addsep, pans=sep_pan

; SWIA survey data

  swi_pan = ''
  if keyword_set(swia) then mvn_swe_addswi, pans=swi_pan

; STATIC data

  sta_pan = ''
  if keyword_set(static) then mvn_swe_addsta, pans=sta_pan, nO1=doO1, nO2=doO2

; LPW data

  lpw_pan = ''
  if keyword_set(lpw) then mvn_swe_addlpw, pans=lpw_pan

; EUV data

  euv_pan = ''
  if keyword_set(euv) then mvn_swe_addeuv, pans=euv_pan

; Spacecraft Potential

  pot_pan = ''
  if keyword_set(sc_pot) then begin
    pot_pan = 'mvn_swe_pot_all'
    mvn_swe_shape_par, /keep_nan
    mvn_swe_sc_negpot
    store_data,pot_pan,data=['mvn_swe_sc_pot','neg_pot']
    options,'neg_pot','constant',!values.f_nan
    options,'neg_pot','color',6
    options,pot_pan,'ytitle','S/C Potential!cVolts'
  endif

; Ephemeris information from SPICE

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init,/force
  eph = state

  mvn_mars_localtime, result=mlt  
  str_element, eph, 'lst', mlt.lst, /add
  str_element, eph, 'slon', mlt.slon, /add
  str_element, eph, 'slat', mlt.slat, /add

; Make density overlay if both STATIC and LPW densities are present

  n_pans = ['']
  n_labs = ['']
  n_cols = [0]
  n_sta = 0
  n_lpw = 0
  i = strpos(sta_pan,'mvn_sta_O2+_raw_density')
  if (i gt -1) then begin
    n_pans = [n_pans,'mvn_sta_O2+_raw_density']
    n_labs = [n_labs,'O2+']
    n_cols = [n_cols,6]
    sta_pan = strmid(sta_pan,0,i) + strmid(sta_pan,(i+23))
    n_sta++
  endif
  i = strpos(sta_pan,'mvn_sta_O+_raw_density')
  if (i gt -1) then begin
    n_pans = [n_pans,'mvn_sta_O+_raw_density']
    n_labs = [n_labs,'O+']
    n_cols = [n_cols,4]
    sta_pan = strmid(sta_pan,0,i) + strmid(sta_pan,(i+22))
    n_sta++
  endif
  i = strpos(lpw_pan,'mvn_lpw_lp_ne_l2')
  if (i gt -1) then begin
    n_pans = [n_pans,'mvn_lpw_lp_ne_l2']
    n_labs = [n_labs,'e-']
    n_cols = [n_cols,2]
    lpw_pan = strmid(lpw_pan,0,i) + strmid(lpw_pan,(i+16))
    n_lpw++
  endif
  
  np = n_elements(n_pans) - 1

  if (np gt 1) then begin
    n_pans = n_pans[1:np]
    n_labs = n_labs[1:np]
    n_cols = n_cols[1:np]
    tplot_options, get=topt
    tsp = time_double(topt.trange_full)

    if (n_sta gt 10) then begin  ; disable for now (not very helpful)
      add_data, 'mvn_sta_O2+_raw_density', 'mvn_sta_O+_raw_density',  $
                newname='mvn_sta_ion_raw_density'
      n_pans = ['mvn_sta_ion_raw_density', n_pans]
      n_labs = ['i+', n_labs]
      n_cols = [!p.color, n_cols]
      np++
    endif

    store_data,'n_lab',data={x:tsp, y:replicate(-1.,2,np), v:indgen(np)}
    options,'n_lab','labels',n_labs
    options,'n_lab','colors',n_cols
    options,'n_lab','labflag',1

    store_data,'n_ion',data=['n_lab', n_pans]
    ylim,'n_ion',10,1e5,1
    options,'n_ion','ytitle','Density!c!c(cm!u-3!n)'

    sta_pan = sta_pan + ' ' + 'n_ion'
  endif

; Assemble the panels and plot

  pans = ram_pan + ' ' + sun_pan + ' ' + alt_pan + ' ' + euv_pan + ' ' + $
         swi_pan + ' ' + sta_pan + ' ' + mag_pan + ' ' + sep_pan + ' ' + $
         lpw_pan + ' ' + pad_pan + ' ' + pot_pan + ' ' + engy_pan
  
  tplot, pans

  return

end
