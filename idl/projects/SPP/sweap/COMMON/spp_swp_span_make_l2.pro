

  ;--------------------------------------------------------------------
  ; PSP SPAN make L2
  ;
  ;
  ; $LastChangedBy: davin-mac $
  ; $LastChangedDate: 2018-12-04 15:35:12 -0800 (Tue, 04 Dec 2018) $
  ; $LastChangedRevision: 26234 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_span_make_l2.pro $
  ;--------------------------------------------------------------------

  ; BASIC STEPS TO LOOKING AT DATA
  ;
  ; Notes on Data Names:
  ;
  ;   SPAN-E produces two products for data taken during the same
  ;   time interval: a "P0" and a "P1" packet. The P0 packet will
  ;   always be a higher-dimension product than the P1 packet. By
  ;   default, P0 is a 16X32X8 3D spectrum, and P1 is a 32 reduced
  ;   energy spectrum.
  ;
  ;   SPAN-E also produces Archive and Survey data - expect the
  ;   Survey data all the time during encounter. Archive is few
  ;   and far between since it's high rate data and takes up a lot
  ;   of downlink to pull from the spacecraft.
  ;
  ;   The last thing you need to know is that SPAN-E alternates
  ;   every other accumulation period sweeping either over the
  ;   "Full" range of energies and deflectors, or a "Targeted"
  ;   range where the signal is at a maximum.
  ;
  ;   Therefore, when you look at the science data from SPAN-E,
  ;   you can pull a "Survey, Full, 3D" distribution by calling
  ;
  ;   IDL> tplot_names, '*sp[a,b]*SF0*SPEC*
  ;
  ;   And the slices through that distribution will be called.
  ;
  ;   Enjoy!
  ;
  ;
  ; note that table files are doubled until [insert date here]

pro spp_swp_span_make_l2,init=init,trange=trange

  compile_opt idl2

  if ~keyword_set(trange) then trange = ['2018 8 30',time_string(systime(1))]
;  trange = '2018 10 3'
  L1_fileformat = 'spp/data/sci/sweap/spa/L1/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L1_YYYYMMDD_v00.cdf'  ; ENERGY_32

  L1_fileformat = 'spp/data/sci/sweap/spa/L1/YYYY/MM/spa_sf0/spp_swp_spa_sf0_L1_YYYYMMDD_v00.cdf'  ; FULL
  files = spp_file_retrieve(L1_fileformat,trange=trange,/daily)

  for fn = 0,n_elements(files)-1 do begin
    file = files[fn]
    if file_test(file) eq 0 then continue
    cdf = cdf_tools(file)

    counts = cdf.vars['PDATA'].data.array
    dim = size(/dimens,counts) 
    if dim[1] ne 4096 then begin
      dprint,'file error: ' , file
      counts= counts[*,0:4095]
    endif
    emode = cdf.vars['EMODE'].data.array
    pmode = 'FULL'
    eflux = counts
    energy = fill_nan(counts)
    theta  = energy
    phi    = energy
    

    emode_last = -1

    for i = 0 , n_elements(emode)-1 do begin
      if emode_last ne  emode[i] then begin
        param = spp_swp_spe_param(detname='spa',emode=emode[i],pmode=pmode)
        fswp = spp_swp_span_sweeps(param=param)
        ptable = param['PTABLE']
        rswp =  spp_swp_span_reduced_sweep(fullsweep=fswp,ptable=ptable)
        emode_last = emode[i]
      endif

      eflux[i,*] = counts[i,*] / rswp['geomdt']
      energy[i,*] = rswp['energy']
      theta[i,*] = rswp['theta']
      phi[i,*] = rswp['phi']

    endfor

    eflux_var = cdf_tools_varinfo('EFLUX',reform(eflux[0,*]),all_values=eflux,/recvary)
    cdf.add_variable, eflux_var
    energy_var = cdf_tools_varinfo('ENERGY',reform(energy[0,*]),all_values=energy,/recvary)
    cdf.add_variable, energy_Var
    THETA_var = cdf_tools_varinfo('THETA',reform(theta[0,*]),all_values=theta,/recvary)
    cdf.add_variable, theta_var
    PHI_var = cdf_tools_varinfo('PHI',reform(phi[0,*]),all_values=phi,/recvary)
    cdf.add_variable, phi_var
;    printdat,cdf
    l2_file = str_sub(file,'L1','L2')
    cdf.write,L2_file
  endfor


end


