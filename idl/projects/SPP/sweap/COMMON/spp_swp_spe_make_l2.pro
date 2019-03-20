

  ;--------------------------------------------------------------------
  ; PSP SPAN make L2
  ;
  ;
  ; $LastChangedBy: phyllisw2 $
  ; $LastChangedDate: 2019-03-19 17:20:53 -0700 (Tue, 19 Mar 2019) $
  ; $LastChangedRevision: 26858 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_spe_make_l2.pro $
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
  
  
  

pro spp_swp_spe_make_l2,init=init,trange=trange,all=all,verbose=verbose

  if keyword_set(all) then trange= ['2018 8 30',time_string(systime(1))]

  compile_opt idl2
  dlevel=3
  L1_fileformat = 'psp/data/sci/sweap/SP?/L1/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'  
  pmodes = hash(16,'16A',32,'32E',4096,'16Ax8Dx32E')         ; product_size: product_name
  trange = timerange(trange)
  
  spxs = ['spa','spb']
  types = ['sf0','sf1']
  if (get_login_info()).user_name eq 'davin' then $
    types = ['sf1','sf0','st1','st0']   ; add archive when available
  
  foreach type,types do begin
    foreach spx, spxs do begin
      fileformat = str_sub(L1_fileformat,'SP?', spx)              ; instrument string substitution
      fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
      dprint,dlevel=dlevel,fileformat

      files = spp_file_retrieve(fileformat,trange=trange,/daily,verbose=verbose)    ; retrieve all daily files within the time range
      w= where( file_test(files),/null,nw )
      if ~isa(w) then begin
        dprint,dlevel=dlevel,'No files found matching: "',fileformat,'"'
        continue
      endif else begin
        dprint,dlevel=dlevel,'Found '+strtrim(nw)+' files matching: "'+fileformat+'"'
        files = files[w]
      endelse

      for fn = 0,n_elements(files)-1 do begin
        file = files[fn]
        if file_test(file) eq 0 then continue
        l1_cdf = cdf_tools(file)                           ; Read in file

        l1_counts = l1_cdf.vars['DATA'].data.array
        l1_datasize = l1_cdf.vars['DATASIZE'].data.array
        l1_nrecs = n_elements(l1_datasize)
        l1_emode = l1_cdf.vars['EMODE'].data.array
        l1_status_bits = l1_cdf.vars['STATUS_BITS'].data.array
        dprint,verbose=verbose,dlevel=dlevel,/phelp,uniq(l1_datasize);,varname='uniq'
        dprint,verbose=verbose,dlevel=dlevel,/phelp,l1_datasize[uniq(l1_datasize)];,varname='datasize'
        dprint,verbose=verbose,dlevel=dlevel,uniq(l1_emode)
        dprint,verbose=verbose,dlevel=dlevel,l1_emode[uniq(l1_emode)]
        dprint,verbose=verbose,dlevel=dlevel,l1_status_bits[uniq(l1_status_bits)]
        
        foreach pmode,pmodes,psize do begin

          records = where(/null,l1_datasize eq psize, l2_nrecs)
          if ~isa(records) then continue
          dprint,dlevel=dlevel,verbose=verbose,'Found '+strtrim(l2_nrecs,2)+' of '+strtrim(l1_nrecs,2)+' packets of pmode: '+pmode+' in file: '+file

          l2_cdf = cdf_tools(file)   ; make a copy
          l2_cdf.filter_variables, records                  ; down  select the pmodes

          l2_counts = l2_cdf.vars['DATA'].data.array
          l2_emode = l2_cdf.vars['EMODE'].data.array
          l2_status_bits = l2_cdf.vars['STATUS_BITS'].data.array
                    
          l2_counts = l2_counts[*,0:psize-1]

          eflux = l2_counts
          energy = fill_nan(l2_counts)
          theta  = energy
          phi    = energy

          emode_last = -1
          status_bits_last = -1
          

          for i = 0 , l2_nrecs-1 do begin
            emode = l2_emode[i]
            status_bits = l2_status_bits[i]
            if (emode_last ne emode) or (status_bits_last ne status_bits) then begin
              param = spp_swp_spe_param(detname = spx, emode = emode, pmode = pmode, status_bits = status_bits)
              fswp = spp_swp_spe_sweeps(param=param)
              ptable = param['PTABLE']
              rswp =  spp_swp_spe_reduced_sweep(fullsweep=fswp,ptable=ptable)
              emode_last = emode
            endif

            eflux[i,*] = l2_counts[i,*] / rswp['geomdt']
            energy[i,*] = rswp['energy']
            theta[i,*] = rswp['theta']
            phi[i,*] = rswp['phi']
            
          endfor
          
          
          eflux_var = cdf_tools_varinfo('EFLUX',reform(eflux[0,*]),all_values=eflux,/recvary)
          l2_cdf.add_variable, eflux_var
          energy_var = cdf_tools_varinfo('ENERGY',reform(energy[0,*]),all_values=energy,/recvary)
          l2_cdf.add_variable, energy_Var
          THETA_var = cdf_tools_varinfo('THETA',reform(theta[0,*]),all_values=theta,/recvary)
          l2_cdf.add_variable, theta_var
          PHI_var = cdf_tools_varinfo('PHI',reform(phi[0,*]),all_values=phi,/recvary)
          l2_cdf.add_variable, phi_var
          ;    printdat,cdf
          l2_file = file
          l2_file = str_sub(l2_file,'L1','L2')
          l2_file = str_sub(l2_file,'_L2_', '_L2_'+pmode+'_')
;          l2_file = str_sub(l2_file,'_v00.', '_v01.')
          l2_cdf.write,L2_file
         
        endforeach
        
       endfor
      
    endforeach
  endforeach



end


