PRO spp_swp_spi_param_func, X, A, F, pder  
   bx = EXP(A[1] * X)  
   F = A[0] * bx + A[2]  
   IF N_PARAMS() GE 4 THEN $  
    pder = [[bx], [A[0] * X * bx], $
            [replicate(1.0, N_ELEMENTS(X))]]  
END 



PRO spp_swp_spi_param_mass_table, write_file=write_file

   ;;------------------------------------------------------
   ;; COMMON BLOCK
   COMMON spi_param, spi_param


   ;;#####################
   ;; Mass Table 0
   ;;#####################

   ;; Array of 128 DAC boundaries 
   hv_dac = ishft(lindgen(128L),9)

   ;; DAC to V and then
   ;; to particle energy [eV] then
   ;; to time-of-flight [ns]
   hv = -1*(spi_param.hemi_fitt[0] + $
            hv_dac*spi_param.hemi_fitt[1])
   ev = hv * 16.7 + 15000.
   mass     = [1,2,21,32]
   mass_nn  = n_elements(mass)
   mass_amu = replicate(1.,n_elements(ev))#(mass)
   enrg_amu = ev#replicate(1.,mass_nn)
   mass_tof = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                   spi_param.tof_flight_path^2/$
                   spi_param.sci.evtoj/$
                   (enrg_amu))/1e-9

   ;; Counter
   kk = 0
   
   ;; Find and store mass tof bin locations
   mass_ppp   = intarr(n_elements(ev),mass_nn)
   mass_eloss = intarr(n_elements(ev),mass_nn)
   FOR i=0, mass_nn-1 DO BEGIN
      FOR j=0, n_elements(ev)-1 DO BEGIN 
         mass_ppp[j,i] = value_locate($
                         spi_param.tof512_bnds,$
                         reform(mass_tof[j,i]))
         mass_eloss[j,i] = (*spi_param.eloss)[mass_ppp[j,i],j]
      ENDFOR
   ENDFOR
   
   ;; Account for energy loss
   enrg_amu_corr = enrg_amu*(mass_eloss/100.)

   ;; Account for TOF correction
   mass_tof_corr = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                        spi_param.tof_flight_path^2/$
                        spi_param.sci.evtoj/$
                        (enrg_amu_corr))/1e-9 - $
                   spi_param.tof_e_corr*1e9

   ;; Setup final mass table
   ;; Value 63 will be used for trash
   mass_table_0 = fix((*spi_param.eloss) * 0) + 63

   FOR i=0, 127 DO BEGIN

      ;; Find tof at current energy
      m0 = mean(mass_tof_corr[i,0])
      m1 = mean(mass_tof_corr[i,1])
      m2 = mean(mass_tof_corr[i,2])
      m3 = mean(mass_tof_corr[i,3])

      ;; Find corresponding TOF bin number
      ;; and force it to be even
      p0 = value_locate(spi_param.tof512_bnds, m0)
      IF (p0 MOD 2) THEN p0 = p0-1
      p1 = value_locate(spi_param.tof512_bnds, m1)
      IF (p1 MOD 2) THEN p1 = p1-1
      p2 = value_locate(spi_param.tof512_bnds, m2)
      IF (p2 MOD 2) THEN p2 = p2-1
      p3 = value_locate(spi_param.tof512_bnds, m3)
      IF (p3 MOD 2) THEN p3 = p3-1

      p0_range = [p0-8:p0+7]
      p1_range = [p1-8:p1+7]
      p2_range = [p2-8:p2+7]
      p3_range = [p3-8:p3+7]

      ;; Make sure no overlap between p0/p1
      diff = min(p1_range) - max(p0_range)
      IF diff LT 0 THEN BEGIN
         diff = temporary(ABS(diff))
         p0_range = [p0-8:p0+7] - ceil(diff/2.)
         p1_range = [p1-8:p1+7] + floor(diff/2.)+1
      ENDIF 

      ;; Make sure no overlap between p1/p2
      diff = min(p2_range) - max(p1_range)
      IF diff LT 0 THEN BEGIN
         diff = temporary(ABS(diff))
         p2_range = [p2-8:p2+7] + diff
      ENDIF 
      
      mass_table_0[p0_range,i] = indgen(16) +  0
      mass_table_0[p1_range,i] = indgen(16) + 16
      mass_table_0[p2_range,i] = indgen(16) + 32
      mass_table_0[p3_range,i] = indgen(16) + 48

      ;;print, format='(8I4)',$
      ;;       minmax(p0_range), $
      ;;       minmax(p1_range), $
      ;;       minmax(p2_range), $
      ;;       minmax(p3_range)

   ENDFOR

   ;;FOR i=0, 127 DO BEGIN
   ;;   plot, mass_table_0[*,i]
   ;;   wait, 0.5
   ;;ENDFOR



   ;;#####################
   ;; Mass Table 1 
   ;;#####################

   ;; Array of 128 DAC boundaries 
   hv_dac = ishft(lindgen(128L),9)

   ;; DAC to V and then to particle energy
   hv = -1*(spi_param.hemi_fitt[0] + $
            hv_dac*spi_param.hemi_fitt[1])
   ev = hv * 16.7 + 15000.
   mass     = [1,2,21,32]
   mass_nn  = n_elements(mass)
   mass_amu = replicate(1.,n_elements(ev))#(mass)
   enrg_amu = ev#replicate(1.,mass_nn)
   mass_tof = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                   spi_param.tof_flight_path^2/$
                   spi_param.sci.evtoj/$
                   (enrg_amu))/1e-9

   ;; 
   kk = 0
   ;mass_ppp   = intarr(n_elements(ev)*mass_nn)
   mass_ppp   = intarr(n_elements(ev),mass_nn)
   mass_eloss = intarr(n_elements(ev),mass_nn)
   FOR i=0, mass_nn-1 DO BEGIN
      FOR j=0, n_elements(ev)-1 DO BEGIN 
         mass_ppp[j,i] = value_locate($
                         spi_param.tof512_bnds,$
                         reform(mass_tof[j,i]))
         mass_eloss[j,i] = (*spi_param.eloss)[mass_ppp[j,i],j]
      ENDFOR
   ENDFOR
   
   ;; Account for energy loss
   enrg_amu_corr = enrg_amu*(mass_eloss/100.)

   ;; Account for TOF correction
   mass_tof_corr = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                        spi_param.tof_flight_path^2/$
                        spi_param.sci.evtoj/$
                        (enrg_amu_corr))/1e-9 - $
                   spi_param.tof_e_corr*1e9
   mass_table_1 = fix((*spi_param.eloss) * 0)

   p0 = intarr(128)
   p1 = intarr(128)
   p2 = intarr(128)
   FOR i=0, 127 DO BEGIN

      m0 = mean(mass_tof_corr[i,0:1])
      m1 = mean(mass_tof_corr[i,1:2])
      m2 = mean(mass_tof_corr[i,2:3])

      p0[i] = value_locate(spi_param.tof512_bnds, m0)
      IF (p0[i] MOD 2) THEN p0[i] = p0[i]-1
      p1[i] = value_locate(spi_param.tof512_bnds, m1)
      IF (p1[i] MOD 2) THEN p1[i] = p1[i]-1
      p2[i] = value_locate(spi_param.tof512_bnds, m2)
      IF (p2[i] MOD 2) THEN p2[i] = p2[i]-1

      p0_range = fix((findgen(p0[i])/p0[i])*16.) 
      p1_range = fix((findgen(p1[i]-p0[i])/(p1[i]-p0[i])*16.)+16.)
      p2_range = fix((findgen(p2[i]-p1[i])/(p2[i]-p1[i])*16.)+32.)
      p3_range = fix((findgen(512-p2[i])/(512-p2[i])*16.)+48.)
      
      mass_table_1[0:p0[i]-1, i] = p0_range
      mass_table_1[p0[i]:p1[i]-1,i] = p1_range
      mass_table_1[p1[i]:p2[i]-1,i] = p2_range
      mass_table_1[p2[i]:511, i] = p3_range

   ENDFOR
   
   (*spi_param.mass_table_1) = mass_table_1

   IF 0 THEN BEGIN 
      ;;#####################
      ;; Mass Table 2
      ;;#####################

      ;; Array of 128 DAC boundaries 
      hv_dac = ishft(lindgen(128L),9)

      ;; DAC to V and then to particle energy
      hv = -1*(spi_param.hemi_fitt[0] + $
               hv_dac*spi_param.hemi_fitt[1])
      ev = hv * 16.7 + 15000.
      mass     = [1,2,21,32]
      mass_nn  = n_elements(mass)
      mass_amu = replicate(1.,n_elements(ev))#(mass)
      enrg_amu = ev#replicate(1.,mass_nn)
      mass_tof = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                      spi_param.tof_flight_path^2/$
                      spi_param.sci.evtoj/$
                      (enrg_amu))/1e-9

      ;; 
      kk = 0
                                ;mass_ppp   = intarr(n_elements(ev)*mass_nn)
      mass_ppp   = intarr(n_elements(ev),mass_nn)
      mass_eloss = intarr(n_elements(ev),mass_nn)
      FOR i=0, mass_nn-1 DO BEGIN
         FOR j=0, n_elements(ev)-1 DO BEGIN 
            mass_ppp[j,i] = value_locate($
                            spi_param.tof512_bnds,$
                            reform(mass_tof[j,i]))
            mass_eloss[j,i] = (*spi_param.eloss)[mass_ppp[j,i],j]
         ENDFOR
      ENDFOR
      
      ;; Account for energy loss
      enrg_amu_corr = enrg_amu*(mass_eloss/100.)

      ;; Account for TOF correction
      mass_tof_corr = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                           spi_param.tof_flight_path^2/$
                           spi_param.sci.evtoj/$
                           (enrg_amu_corr))/1e-9 - $
                      spi_param.tof_e_corr*1e9
      mass_table_2 = fix((*spi_param.eloss) * 0)

      FOR i=0, 127 DO BEGIN

         m0 = mean(mass_tof_corr[i,0:1])
         m1 = mean(mass_tof_corr[i,1:2])
         m2 = mean(mass_tof_corr[i,2:3])

         p0 = value_locate(spi_param.tof512_bnds, m0)
         IF (p0 MOD 2) THEN p0 = p0-1
         p1 = value_locate(spi_param.tof512_bnds, m1)
         IF (p1 MOD 2) THEN p1 = p1-1
         p2 = value_locate(spi_param.tof512_bnds, m2)
         IF (p2 MOD 2) THEN p2 = p2-1


         p0_range = [replicate(2,(p0-2)/2), replicate(3,(p0-2)/2) ]
         p1_range = [replicate(4,(p1-p0)/2),replicate(5,(p1-p0)/2)]
         p2_range = fix(interpol([ 6:32],$
                                 findgen(27),$
                                 findgen(p2-p1)/(p2-p1)*27))
         p3_range = [fix(interpol([33:63],$
                                  findgen(31),$
                                  findgen(511-p2)/(511-p2)*31)),63]

         mass_table_2[0:1,i]     = [0,1]
         mass_table_2[2:p0-1,i]  = p0_range
         mass_table_2[p0:p1-1,i] = p1_range
         mass_table_2[p1:p2-1,i] = p2_range
         mass_table_2[p2:511,i]  = p3_range

      ENDFOR
      
      (*spi_param.mass_table_2) = mass_table_2


      ;; MRLUT
      ;; 64 Element Array
      mrlut_2 = intarr(64)
      mrlut_2[0:1] = 4
      mrlut_2[2:3] = 0
      mrlut_2[4:5] = 1
      mrlut_2[p2_range[uniq(p2_range)]] = 2
      mrlut_2[p3_range[uniq(p3_range)]] = 3
      (*spi_param.mrlut_2) = mrlut_2

   ENDIF
   
   
   ;; WRITING TO FILE
   IF 0 THEN BEGIN ;;keyword_set(write_file) THEN BEGIN

      ;; MLUT DEFAULT
      openw, 1, '~/Desktop/mlut_default.txt'
      mass_table_default_arr = ishft(indgen(512),-3)
      FOR i=0, 127 DO BEGIN
         FOR j=0, 511 DO BEGIN
            printf,1,format='(I2)',mass_table_default_arr[j]
         ENDFOR
      ENDFOR 
      close, 1

      ;; MLUT 0
      openw, 1, '~/Desktop/mlut0.txt'
      FOR i=0, 127 DO BEGIN
         FOR j=0, 511 DO BEGIN
            printf,1,format='(I2)',mass_table_0[j,i]
         ENDFOR
      ENDFOR 
      close, 1

      ;; MLUT 1
      openw, 1, '~/Desktop/mlut1.txt'
      FOR i=0, 127 DO BEGIN
         FOR j=0, 511 DO BEGIN
            printf,1,format='(I2)',mass_table_1[j,i]
         ENDFOR
      ENDFOR 
      close, 1

      ;; MLUT 2
      openw, 1, '~/Desktop/mlut2.txt'
      FOR i=0, 127 DO BEGIN
         FOR j=0, 511 DO BEGIN
            printf,1,format='(I2)',mass_table_2[j,i]
         ENDFOR
      ENDFOR 
      close, 1
      
      openw, 1, '~/Desktop/mrlut2.txt'
      FOR i=0, 63 DO printf,1,format='(I2)',mrlut_2[i]
      close,1
   ENDIF 



   ;; PLOTTING
   ;; IF keyword_set(plott) THEN BEGIN
   loadct2, 5
   mt1 = mass_table_1
   pp0 = where(mt1 GE   0 AND mt1 LE  15,cc0)
   pp1 = where(mt1 GE  16 AND mt1 LE  31,cc1)
   pp2 = where(mt1 GE  32 AND mt1 LE  47,cc2)
   pp3 = where(mt1 GE  48 AND mt1 LE  63,cc3)
   ;;pp4 = where(mt1 GE 33 AND mt1 LE 63,cc4)      
   ;;mt1[pp0] = 1.
   ;;mt1[pp1] = 2.
   ;;mt1[pp2] = 3.
   ;;mt1[pp3] = 4.
   ;;mt1[pp4] = 4.
   ;;mt1 = mt1/4. * 256.
   ;;contour, mt1, nlevel=4, /fill, xs=1,ys=1
   ;; Plotting 

   tt1=mean(mass_tof_corr[*,0:1],dimension=2)
   tt2=mean(mass_tof_corr[*,1:2],dimension=2)
   tt3=mean(mass_tof_corr[*,2:3],dimension=2)   
   
   stop
   
   loadct2, 34
   ;oplot, transpose(mass_tof_corr[*,0]),indgen(128),color=250
   ;oplot, transpose(mass_tof_corr[*,1]),indgen(128),color=250
   ;oplot, transpose(mass_tof_corr[*,2]),indgen(128),color=250
   ;oplot, transpose(mass_tof_corr[*,3]),indgen(128),color=250
   ;ENDIF
   
END



PRO spp_swp_spi_param_eloss_matrix, eloss_matrix, verbose=verbose

   ;;------------------------------------------------------
   ;; COMMON BLOCK
   COMMON spi_param, spi_param

   ;; What we learned from Flight Calibration
   
   ;; Remove last nine bits from Hemisphere DACS
   ;hv_dac = (uindgen('ffff'x)) and ('ffff'x-'111111111'b)
   ;hv_dac = hv_dac[uniq(hv_dac)]
   hv_dac = ishft(lindgen(128L),9)

   ;; Change HEM index to voltage and then to particle energy
   hv = -1*(spi_param.hemi_fitt[0] + hv_dac*spi_param.hemi_fitt[1])
   ev = hv * 16.7 + 15000.

   ;; From TRIM 1.0 microgram/cm^2

   ;; Hydrogen Start Energy
   hse = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.
   ;; Oxygen Start Energy
   ose = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.
   ;; Argon Start Energy
   ase = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.

   ;; Hydrogen Exit Energy 
   hee = [14574., 14969., 15463., 16452., 24380., 34321., 79235.]
   ;; Oxygen Exit Energy 
   oee = [12791., 13188., 13669., 14652., 22552., 32483., 77283.]
   ;; Argon Exit Energy 
   aee = [10310., 10680., 11171., 12112., 19836., 29640., 74270.]

   hh = 100.*hee/hse
   oo = 100.*oee/ose
   aa = 100.*aee/ase
   
   sigmah = replicate(1., n_elements(hh))
   sigmao = replicate(1., n_elements(oo))
   sigmab = replicate(1., n_elements(aa))

   ;; Curvefit Results of an exponential
   ;; a1*exp(energy*a2)+a3
   ah = [  -5.2, -4.5e-05, 99.2]
   ao = [ -28.5, -5.7e-05, 96.8]
   ab = [ -57.1, -5.5e-05, 93.4]

   ;; Perform fit
   ;; func = 'spp_swp_spi_param_func'
   ;; hfit = curvefit(hv, hh, weights, ah, sigmah, function_name=func)
   ;; ofit = curvefit(ov, oo, weights, ao, sigmao, function_name=func)
   ;; afit = curvefit(av, aa, weights, ab, sigmab, function_name=func)

   hfit = (ah[0]*exp(ev*ah[1])+ah[2]) < 100.0
   ofit = (ao[0]*exp(ev*ao[1])+ao[2]) < 100.0
   afit = (ab[0]*exp(ev*ab[1])+ab[2]) < 100.0

   eloss_matrix = fltarr(512, 128)

   ;; Mass to time
   mass = [1, 16, 40]

   FOR i=0, 127 DO BEGIN
      tt = sqrt(0.5*mass*spi_param.sci.atokg*$
                spi_param.tof_flight_path^2/spi_param.sci.evtoj/ev[i])/1e-9
      yy = [hfit[i], ofit[i], afit[i]]
      tmp1 =  interpol(yy, tt, spi_param.tof512_avgs) > 0
      tmp2 = tmp1 < 100.0
      eloss_matrix[*, i] = tmp2
      IF keyword_set(verbose) THEN BEGIN 
         plot,  tt, yy,  xr=[1, 100], xs=1, yr=[50, 100], ys=1, /xlog,title=string(ev[i])
         oplot, spi_param.tof512_avgs, eloss_matrix[*, i], color=250,psym=-1
         wait, 0.05
      ENDIF
   ENDFOR





   ;;===============================================================================
   ;; PLOTS
   ;;===============================================================================
   IF keyword_set(verbose) THEN BEGIN

      ;; Generate masses in amu and tof
      ;; Find corresponding tof bin
      specific_mass = [1,2,4,14,16,18,20,28,29,30,38,39,40]
      specific_mass = [1,2,4,20]
      mass_nn  = n_elements(specific_mass)
      mass_amu = replicate(1.,n_elements(ev))#(specific_mass)
      enrg_amu = ev#replicate(1.,mass_nn)
      mass_tof = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                      spi_param.tof_flight_path^2/$
                      spi_param.sci.evtoj/$
                      (enrg_amu))/1e-9
      mass_ppp   = intarr(n_elements(ev)*mass_nn)
      kk = 0
      mass_ppp   = intarr(n_elements(ev),mass_nn)
      mass_eloss = intarr(n_elements(ev),mass_nn)
      FOR i=0, mass_nn-1 DO BEGIN
         FOR j=0, n_elements(ev)-1 DO BEGIN 
            mass_ppp[j,i] = value_locate($
                            spi_param.tof512_bnds,$
                            reform(mass_tof[j,i]))            
            mass_eloss[j,i] = eloss_matrix[mass_ppp[j,i],j]
         ENDFOR
      ENDFOR
      
      ;; Account for energy loss
      enrg_amu_corr = enrg_amu*(mass_eloss/100.)
      mass_tof_corr = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                           spi_param.tof_flight_path^2/$
                           spi_param.sci.evtoj/$
                           (enrg_amu_corr))/1e-9

      ;; Setup Plotting Windows
      window, xsize=1200,ysize=900
      !p.multi = [0,2,2]
      ;; PLOT 1: TOF vs. Energy (black)
      ;;         TOF vs. Energy including loss (red)
      yyr = minmax([mass_tof,$
                    mass_tof_corr,$
                    mass_tof_corr-spi_param.tof_e_corr*1e9])
      xxr = minmax(enrg_amu)
      plot, [1.,1000.],[0,1],/nodata,$
            ytitle='ns',xtitle='Particle Energy [eV]',$
            title='TOF vs Energy',$
            yr=yyr,xr=xxr,$
            ys=1,xs=1,xlog=1    ;,ylog=1
      FOR i=0, mass_nn-1 DO BEGIN 
         oplot, enrg_amu[*,i],mass_tof[*,i]
         oplot, enrg_amu[*,i],mass_tof_corr[*,i],color=250
         oplot, enrg_amu[*,i],mass_tof_corr[*,i]-spi_param.tof_e_corr*1e9,color=50
      ENDFOR 

      ;; Add results from Davin's Energy-Mass Scans
      IF file_test('~/Desktop/tmp.sav') THEN BEGIN 
         restore, '~/Desktop/tmp.sav'
         oplot, vh, h, color=80, psym=1
         oplot, vo, o, color=80, psym=1
         oplot, vc, c, color=80, psym=1
      ENDIF
      
      ;; Add results from Colutron scan
      h   = spi_param.tof_moy.tof_mq1*[1,2.365,1]
      h2  = spi_param.tof_moy.tof_mq2*[1,2.365,1]
      he  = spi_param.tof_moy.tof_mq4*[1,2.365,1]
      o   = spi_param.tof_moy.tof_mq16*[1,2.365,1]
      nne = spi_param.tof_moy.tof_mq20*[1,2.365,1]
      ni = spi_param.tof_moy.tof_mq28*[1,2.365,1]
      xx = 16000.
      oplot, replicate(xx,2), [h[2] - h[1], h[2]  + h[1]],  thick=5
      oplot, replicate(xx,2), [h2[2]- h2[1],h2[2] + h2[1]], thick=5
      oplot, replicate(xx,2), [he[2]- he[1],he[2] + he[1]], thick=5
      ;oplot, replicate(xx,2), [ni[2]- ni[1],ni[2] + ni[1]], thick=5
      oplot, replicate(xx,2), [o[2] - o[1], o[2]  + o[1]],  thick=5
      ;oplot, replicate(xx,2), [nne[2]-nne[1],nne[2]+nne[1]], thick=5

      ;;coef = spi_param.mass_enrg
      ;;xx   = indgen(8000.)+15000.
      ;;yyh  = coef[0,0] * exp(coef[1,0]*xx) + coef[2,0]
      ;;yyo  = coef[0,1] * exp(coef[1,1]*xx) + coef[2,1]
      ;;yyu  = coef[0,2] * exp(coef[1,2]*xx) + coef[2,2] 

      ;;oplot, xx, yyh, color=80
      ;;oplot, xx, yyo, color=80
      ;;oplot, xx, yyu, color=80
      
      ;; PLOT 2: Added seconds due to loss vs Energy for specific masses.
      mass_tof_diff = ABS(mass_tof - mass_tof_corr)
      xxr = minmax(enrg_amu)
      yyr = minmax(mass_tof_diff-spi_param.tof_e_corr*1e9)
      plot, [0,1],[0,1],/nodata,xr=xxr,$
            ytitle='ns',xtitle='Particle Energy [eV]',$
            title='TOF Difference vs Energy',$
            ys=1,xs=1,yr=yyr,xlog=1;,ylog=1
      FOR i=0, n_elements(specific_mass)-1 DO BEGIN
         oplot, enrg_amu[*,i], mass_tof_diff[*,i],color=250
         oplot, enrg_amu[*,i], mass_tof_diff[*,i]-$
                spi_param.tof_e_corr*1e9,color=50
      ENDFOR
      ;; PLOT 3:
      stop
      !p.multi = 0

      
      
   ENDIF 
   
END




FUNCTION spp_swp_spi_param_esa

   
   ;;------------------------------------------------------
   ;; ESA Dimensions
                                          ;; Toroidal Section 
   r1 = 3.34                              ;; Inner Hemisphere Radius
                                          ;; Toroidal Section
   r2 = r1*1.06                           ;; Outer Hemisphere Radius
   r3 = r1*1.639                          ;; Inner Hemisphere
   r4 = r3*1.06                           ;; Top Cap Radius
   rd = 3.863                             ;; Deflector Radius
   o1 = [0.000,-2.080]                    ;; Origin of Top Cap/Spherical
   o2 = [0.480, 0,000]                    ;; Origin of Toroidal Section
   o3 = [2.500,-0.575]                    ;; Origin of Lower Deflector
   o4 = [2.500, 7.588]                    ;; Origin of Upper Deflector
   deg     = findgen(9000.)/100.
   d2      =  2.5                         ;; Distance of def. from
                                          ;; rotation axis
   dr      =  3.863                       ;; Deflector Radius 38.63mm
   dist    =  0.56                        ;; Distance between deflectors
                                          ;; (58.7-53.1)
   drp     = dr+dist/2.                   ;; Radius of particle path
                                          ;; with deflection
   top_def = [[dr*cos(!DTOR*deg)],$       ;; x
              [dr*sin(!DTOR*deg)]]        ;; y
   top_def_path = [[drp*cos(!DTOR*deg)],$ ;; x
                   [drp*sin(!DTOR*deg)]]  ;; y
   deg = -1.*deg
   bot_def = [[dr*cos(!DTOR*deg)],$       ;; x
              [dr*sin(!DTOR*deg)]]        ;; y
   bot_def_path = [[drp*cos(!DTOR*deg)],$ ;; x
                   [drp*sin(!DTOR*deg)]]  ;; y
   deg = -1.*deg

   yaw_vals = fltarr((90-6)*10)
   lin_vals = fltarr((90-6)*10)
   ii=0.
   FOR yaw=  0.,  70.,  5 DO BEGIN
      
      ;; Crude Approximation of Tangent Point
      pp  =  where(ABS(reverse(deg) - yaw) EQ $
                   min(ABS(reverse(deg) - yaw)), cc)
      IF cc EQ 0 THEN stop
      ;; Adjust yaw and linear parameters
      ;; to match tangent line
      theta =  (yaw)*!DTOR
      ;; Top Deflector
      xx =  (top_def[*, 0]+d2)
      yy =  (top_def[*, 1]-dr-dist/2.)
      xx11 =  xx*cos(theta)-yy*sin(theta)
      yy11 =  xx*sin(theta)+yy*cos(theta)
      ;; Top Deflector Path
      xx =  top_def_path[*, 0]+d2
      yy =  top_def_path[*, 1]-dr-dist/2.
      xx22 =  xx*cos(theta)-yy*sin(theta)
      yy22 =  xx*sin(theta)+yy*cos(theta)
      ;; Linear Shift
      lin =  yy22[pp[0]]
      plot,   xx11,  yy11-lin, $
              xrange=[-10, 10], $
              yrange=[-10, 10], $
              ystyle=1, $
              /iso
      oplot,  xx22,  yy22-lin, $
              color=250
      ;; Beam
      beam =  [[findgen(1000)-500], [replicate(0., 1000)]]
      oplot,  beam[*, 0],  beam[*, 1]
      ;; Bottom Deflector
      xx =  bot_def[*, 0]+d2
      yy =  bot_def[*, 1]+dr+dist/2.
      xx1 =  xx*cos(theta)-yy*sin(theta)
      yy1 =  xx*sin(theta)+yy*cos(theta)
      oplot,  xx1,  yy1-lin
      xx =  bot_def_path[*, 0]+d2
      yy =  bot_def_path[*, 1]+dr+dist/2.
      xx1 =  xx*cos(theta)-yy*sin(theta)
      yy1 =  xx*sin(theta)+yy*cos(theta)
      oplot,  xx1,  yy1-lin
      ;; Plot temporary location of tangent
      oplot,  top_def_path[pp, 0]+d2,  $
              top_def_path[pp, 1]-dr-dist/2.,  psym=1
      ;; Information
      xyouts,  -8, -8, $
               'yaw=' + strtrim(string(yaw),2)+'   '+$
               'lin=' + strtrim(string(lin),2)
      wait, 0.025   
      yaw_vals[ii] = yaw
      lin_vals[ii] = lin
      ii=ii+1
      IF yaw EQ 65 THEN stop
      IF yaw EQ 70 THEN stop
      
   ENDFOR
                    
END








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;          SPAN-Ai Flight Calibration Experiments              ;;;
;;;                       CAL Facility                           ;;;
;;;                        2017-03-07                            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


FUNCTION spp_swp_spi_param_fm_cal_times


   
   ;;---------------------------------------------------------------
   ;; Gun Map
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   tt_gunmap_1 = ['2017-03-09/04:12:00','2017-03-09/22:36:00']

   ;; First Half
   tt_gunmap_11 = ['2017-03-09/04:25:10','2017-03-09/06:22:10']
   ;; Second Half
   tt_gunmap_12 = ['2017-03-09/20:25:20','2017-03-09/22:15:00']

   
   
   ;; Rotation Scan before TOF correction
   tt_rotscan_1 = ['2017-03-10/07:28:20','2017-03-10/08:44:40']
   ;; Rotation Scan after TOF correction
   ;rotscan2 = [
   
  
   ;;---------------------------------------------------------------
   ;; Threshold Scan
   ;;
   ;; INFO
   ;;   - CFD Threshold scan of all START and STOP channels.
   ;; CONFIG
   ;;   - AZ  = [0,1,2,3]
   ;;   - RAW = [0xD000]
   ;;   - MCP = [0xD000]
   ;;   - ACC = [0xFF00]
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_thresh_scan1 = ['2017-03-12/05:47:00','2017-03-12/19:00:00']
   
   
   ;;---------------------------------------------------------------
   ;; Rotation Scan
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_rotscan_2 = ['2017-03-13/07:12:35','2017-03-13/08:32:45']


   ;;---------------------------------------------------------------
   ;; Energy Angle Scan
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_eascan_1 = ['2017-03-13/18:21:00','2017-03-13/23:47:00']


   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - HIGH DETAIL - ANODE 0x0
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_def_sweep_1 = ['2017-03-14/06:31:50','2017-03-14/10:04:30']


   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - COARSE - ALL ANODES
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]

   ;; Anode 0x0 - 0x1
   tt_def_sweep_2 = ['2017-03-14/18:28:00','2017-03-14/22:30:00']

   ;; Anode 0x2 - 13 or 14 (check)
   tt_def_sweep_3 = ['2017-03-15/05:12:00','2017-03-15/22:02:00']



   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - Fine - anodes 9,10,11,12,13
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   tt_def_sweep_4=['2017-03-21/07:38:30','2017-03-21/17:46:00']

   ;; Anode 0x9
   tt_def_sweep_5=['2017-03-21/07:36:50','2017-03-21/09:16:05']

   ;; Anode 0xA
   tt_def_sweep_6=['2017-03-21/09:41:50','2017-03-21/11:21:50']

   ;; Anode 0xB
   tt_def_sweep_7=['2017-03-21/11:47:00','2017-03-21/13:30:00']

   ;; Anode 0xC
   tt_def_sweep_8=['2017-03-21/13:51:30','2017-03-21/15:33:30']

   ;; Anode 0xD
   tt_def_sweep_9=['2017-03-21/15:57:00','2017-03-21/17:33:50']

   ;; Anode 0xE
   ;trange=[]





   
   ;; Turned back on 05:55
   ;; Quick Rotation scan to get beam back to anode 0
   trange = ['2017-03-22/06:00:00', '2017-03-22/06:15:00']

 
   ;; Sweep YAW with constant deflector
   ;; Anode 0x0 and partially Anode 0x1
   trange = ['2017-03-22/06:16:20', '2017-03-22/11:49:40']

   ;; Anode 0x4 and partially Anode 0x5
   trange = ['2017-03-22/11:49:30', '2017-03-22/17:46:00']

   ;; Anode 0xA
   trange = ['2017-03-22/17:46:00', '2017-03-22/23:05:30']

   ;; Energy Scan (k-Factor and Mass Table)
   trange = ['2017-03-23/06:30:10', '2017-03-23/09:17:50']

   ;;---------------------------------------------------------------
   ;; K Factor Sweep
   tt_ksweep_1 = ['2017-03-23/06:30:00', '2017-03-23/09:30:00']

   ;;---------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Nitrogen Gas Gun
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_mass_scan_nitrogen = ['2017-03-22/02:00:00','2017-03-22/03:00:00']


   ;;---------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Gas mixture of H2, He, Ne, Ar
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet   
   tt_mass_scan_gas_mix = ['2017-03-24/17:00:00','2017-03-24/22:00:00']

   tt_mass_scan_h   = ['2017-03-24/21:03:30','2017-03-24/21:17:25']
   tt_mass_scan_h2  = ['2017-03-24/20:57:05','2017-03-24/21:02:40']
   tt_mass_scan_he  = ['2017-03-24/18:36:05','2017-03-24/18:48:45']
   tt_mass_scan_m4  = ['2017-03-24/19:01:15','2017-03-24/19:07:00']
   tt_mass_scan_m5  = ['2017-03-24/19:09:40','2017-03-24/19:13:20']
   tt_mass_scan_m6  = ['2017-03-24/19:22:20','2017-03-24/19:28:30']
   tt_mass_scan_m7  = ['2017-03-24/19:31:35','2017-03-24/19:36:20']
   tt_mass_scan_m8  = ['2017-03-24/19:39:00','2017-03-24/19:42:55']
   tt_mass_scan_m9  = ['2017-03-24/19:43:40','2017-03-24/19:50:25']
   tt_mass_scan_m10 = ['2017-03-24/19:52:40','2017-03-24/20:01:05']
   tt_mass_scan_m11 = ['2017-03-24/20:04:50','2017-03-24/20:12:35']
   tt_mass_scan_m12 = ['2017-03-24/20:15:15','2017-03-24/20:21:10']
   tt_mass_scan_m13 = ['2017-03-24/20:25:10','2017-03-24/20:39:25']  
   
   str_mass_scan_1 = [{name:'full', tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N+',   tt_mass_scan:tt_mass_scan_nitrogen}, $
                      {name:'N2+',  tt_mass_scan:tt_mass_scan_nitrogen}]
   str_mass_scan_2 = [{name:'full', tt_mass_scan:tt_mass_scan_gas_mix},  $
                      {name:'H+',   tt_mass_scan:tt_mass_scan_h},   $
                      {name:'H2+',  tt_mass_scan:tt_mass_scan_h2},  $
                      {name:'He+',  tt_mass_scan:tt_mass_scan_he},  $
                      {name:'m4',   tt_mass_scan:tt_mass_scan_m4},  $
                      {name:'m5',   tt_mass_scan:tt_mass_scan_m5},  $
                      {name:'m6',   tt_mass_scan:tt_mass_scan_m6},  $
                      {name:'m7',   tt_mass_scan:tt_mass_scan_m7},  $
                      {name:'m8',   tt_mass_scan:tt_mass_scan_m8},  $
                      {name:'m9',   tt_mass_scan:tt_mass_scan_m9},  $
                      {name:'m10',  tt_mass_scan:tt_mass_scan_m10}, $
                      {name:'m11',  tt_mass_scan:tt_mass_scan_m11}, $
                      {name:'m12',  tt_mass_scan:tt_mass_scan_m12}, $
                      {name:'m13',  tt_mass_scan:tt_mass_scan_m13}]

   ;;---------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - ACC Scan
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Gas Mix
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_acc_scan = ['2017-03-24/22:00:00', '2017-03-25/01:00:00']

   tt_acc_scan_co2_1 = ['2017-03-24/22:22:29', '2017-03-24/22:41:19']
   tt_acc_scan_co2_2 = ['2017-03-24/23:32:10', '2017-03-24/23:47:19'] 

   tt_acc_scan_h_1 = ['2017-03-25/00:09:20', '2017-03-25/00:25:50']
   tt_acc_scan_h_2 = ['2017-03-25/00:25:50', '2017-03-25/00:45:40']

   

   

   
   ;;---------------------------------------------------------------
   ;; Long term anode 11 with 2kV beam
   trange = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']


   
   ;;---------------------------------------------------------------
   ;; Energy Scan using Davin's tables

   tt_e_scan_full  = ['2017-03-26/01:30:00', '2017-03-26/11:00:00']

   tt_e_scan_full1 = ['2017-03-26/01:30:00', '2017-03-26/05:59:00']
   tt_e_scan_full2 = ['2017-03-26/08:00:00', '2017-03-26/11:00:00']
   
   tt_e_scan_d1 = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']
   tt_e_scan_d2 = ['2017-03-26/02:34:25', '2017-03-26/02:43:30']
   tt_e_scan_d3 = ['2017-03-26/03:13:20', '2017-03-26/03:23:00']
   tt_e_scan_d4 = ['2017-03-26/04:21:55', '2017-03-26/04:30:45']

   tt_e_scan_d_anodes = ['2017-03-26/08:41:10', '2017-03-26/10:36:20']

   tt_e_scan_d_an15 = ['2017-03-26/08:39:20', '2017-03-26/08:48:30']
   tt_e_scan_d_an14 = ['2017-03-26/08:48:30', '2017-03-26/08:55:50']
   tt_e_scan_d_an13 = ['2017-03-26/08:55:50', '2017-03-26/09:02:40']
   tt_e_scan_d_an12 = ['2017-03-26/09:02:40', '2017-03-26/09:10:10']
   tt_e_scan_d_an11 = ['2017-03-26/09:10:10', '2017-03-26/09:17:10']
   tt_e_scan_d_an10 = ['2017-03-26/09:17:10', '2017-03-26/09:24:10']
   tt_e_Scan_d_an09 = ['2017-03-26/09:24:10', '2017-03-26/09:31:20']
   tt_e_scan_d_an08 = ['2017-03-26/09:31:20', '2017-03-26/09:38:20']
   tt_e_scan_d_an07 = ['2017-03-26/09:38:20', '2017-03-26/09:45:20']
   tt_e_scan_d_an06 = ['2017-03-26/09:45:20', '2017-03-26/09:52:10']
   tt_e_scan_d_an05 = ['2017-03-26/09:52:10', '2017-03-26/09:59:10']
   tt_e_scan_d_an04 = ['2017-03-26/09:59:10', '2017-03-26/10:06:10']
   tt_e_scan_d_an03 = ['2017-03-26/10:06:10', '2017-03-26/10:13:20']
   tt_e_scan_d_an02 = ['2017-03-26/10:13:20', '2017-03-26/10:20:20']
   tt_e_scan_d_an01 = ['2017-03-26/10:20:20', '2017-03-26/10:27:10']
   tt_e_scan_d_an00 = ['2017-03-26/10:27:34', '2017-03-26/10:34:50']


   
   str_e_scan_davin_1 = [{name:'full', tt_mass_scan:tt_e_scan_full1},  $
                         {name:'d1',  tt_mass_scan:tt_e_scan_d1},  $
                         {name:'d2',  tt_mass_scan:tt_e_scan_d2},  $
                         {name:'d3',  tt_mass_scan:tt_e_scan_d3},  $
                         {name:'d4',  tt_mass_scan:tt_e_scan_d4}]


   str_e_scan_davin_2 = [{name:'full', tt_mass_scan:tt_e_scan_full2},  $
                         {name:'anode_00', tt_e_scan:tt_e_scan_d_an00}, $
                         {name:'anode_01', tt_e_scan:tt_e_scan_d_an01}, $
                         {name:'anode_02', tt_e_scan:tt_e_scan_d_an02}, $
                         {name:'anode_03', tt_e_scan:tt_e_scan_d_an03}, $
                         {name:'anode_04', tt_e_scan:tt_e_scan_d_an04}, $
                         {name:'anode_05', tt_e_scan:tt_e_scan_d_an05}, $
                         {name:'anode_06', tt_e_scan:tt_e_scan_d_an06}, $
                         {name:'anode_07', tt_e_scan:tt_e_scan_d_an07}, $
                         {name:'anode_08', tt_e_scan:tt_e_scan_d_an08}, $
                         {name:'anode_09', tt_e_scan:tt_e_scan_d_an09}, $
                         {name:'anode_10', tt_e_scan:tt_e_scan_d_an10}, $
                         {name:'anode_11', tt_e_scan:tt_e_scan_d_an11}, $
                         {name:'anode_12', tt_e_scan:tt_e_scan_d_an12}, $
                         {name:'anode_13', tt_e_scan:tt_e_scan_d_an13}, $
                         {name:'anode_14', tt_e_scan:tt_e_scan_d_an14}, $
                         {name:'anode_15', tt_e_scan:tt_e_scan_d_an15}]
   



   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight CPT                      ;;;
   ;;;                       APL EMC Facility                       ;;;
   ;;;                          2017-06-29                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2017-06-29/18:25:00']
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight LPT                      ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-01-22                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-01-23/02:00:00']

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight Cover                    ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-01-22                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-02-24/07:23:56']

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                  SPAN-Ai Flight Hot/Cold CPT                 ;;;
   ;;;                            Goddard                           ;;;
   ;;;                          2018-03-06                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-03-06/00:00:00','2018-03-09/00:00:00'] 

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;                      SPAN-Ai Flight MSIM-4                   ;;;
   ;;;                          Astro-Tech                          ;;;
   ;;;                          2018-05-15                          ;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   trange = ['2018-05-15']

   
   ;; Return Time Structure
   
   times = { $

   tt_gunmap_1:tt_gunmap_1, $
    tt_gunmap_11:tt_gunmap_11, $
    tt_gunmap_12:tt_gunmap_12, $
            
   tt_rotscan_1:tt_rotscan_1, $
    tt_rotscan_2:tt_rotscan_2, $
    
   tt_eascan_1:tt_eascan_1, $

   tt_ksweep_1:tt_ksweep_1, $
    
   tt_def_sweep_1:tt_def_sweep_1, $

   str_mass_scan_1:str_mass_scan_1, $
    
   str_mass_scan_2:str_mass_scan_2, $
   
   str_e_scan_davin_1:str_e_scan_davin_1, $

   str_e_scan_davin_2:str_e_scan_davin_2}
   
   return,  times

END




PRO spp_swp_spi_param_science, science

   ;; Electron Mass [kg]
   mass_e_kg = 9.10938356e-31
   ;; Electron Mass            (to get grams multiply by 1.6e-22.)
   mass_e = 5.68566e-06        ;; [ev/c2] where c = 299792 [km/s]  
   ;; Proton Mass [kg]
   mass_p_kg = 1.6726219e-27
   ;; Proton Mass              (to get grams multiply by 1.6e-22.)
   mass_p   = 0.0104389          ;; [ev/c2] where c = 299792 [km/s]  

   ;; Speed of light
   cc     = 299792458d         ;; [m s-1]
   ;; 1 Electronvolt to Joule
   evtoj  = 1.602176565e-19     ;; [J] = [kg m2 s-2]
   ;; Boltzmann Constant
   kk     = 1.38064852e-23      ;; [m2 kg s-2 K-1]
   ;; 1 AMU to kg
   atokg = 1.66054e-27
   
   science = {mass_e:mass_e,$
              mass_e_kg:mass_e_kg,$
              mass_p:mass_p,$
              mass_p_kg:mass_p_kg,$
              cc:cc,$
              evtoj:evtoj,$
              kk:kk,$
              atokg:atokg}
   
END







PRO spp_swp_spi_param_anode_board, ano
   
   ;;------------------------------------------------------
   ;; Anode Board Dimensions [in]
   nn = 10.
   rad1 = 0.818
   rad2 = 1.147
   rad3 = 1.246
   rad4 = 1.813
   anode_dim = fltarr(27,2,nn*2+2)

   ;; Start Anodes
   pp = indgen(nn+1)/nn*22.5*!DTOR
   off = 180*!DTOR 
   FOR i=0, 10 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+22.5*i*!DTOR+off)*rad1,$
      cos(reverse(pp)+22.5*i*!DTOR+off)*rad2],$
     [sin(pp+22.5*i*!DTOR+off)*rad1,$
      sin(reverse(pp)+22.5*i*!DTOR+off)*rad2]])

   ;; Small Stop Anodes
   pp = indgen(nn+1)/nn*11.25*!DTOR
   off =  180*!DTOR - (90.+11.25*3)*!DTOR
   FOR i=11, 20 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+11.25*i*!DTOR+off)*rad3,$
      cos(reverse(pp)+11.25*i*!DTOR+off)*rad4],$
     [sin(pp+11.25*i*!DTOR+off)*rad3,$
      sin(reverse(pp)+11.25*i*!DTOR+off)*rad4]])

   ;; Large Stop Anodes
   pp = indgen(nn+1)/nn*22.5*!DTOR
   offs = 11.*11.25*!DTOR
   FOR i=21, 26 DO $
    anode_dim[i,*,*] = transpose($
    [[cos(pp+22.5*i*!DTOR+offs+off)*rad3,$
      cos(reverse(pp)+22.5*i*!DTOR+offs+off)*rad4],$
     [sin(pp+22.5*i*!DTOR+offs+off)*rad3,$
      sin(reverse(pp)+22.5*i*!DTOR+offs+off)*rad4]])

   ;; PLOT ANODE BOARD
   IF keyword_set(plot_anodes) THEN begin
      window, 0, xsize = 900,ysize = 900
      plot, [0,1],[0,1],xr=[-3,3],yr=[-3,3],/iso,xs=1,ys=1, /nodata
      FOR i=0,26 DO begin
         xx = [reform(anode_dim[i,0,*]),anode_dim[i,0,0]]
         yy = [reform(anode_dim[i,1,*]),anode_dim[i,1,0]]
         oplot, xx, yy
      ENDFOR
   ENDIF

   ano =  {rad1:rad1,$
           rad2:rad2,$
           rad3:rad3,$
           rad4:rad4,$
           anode_dim:anode_dim}

END 
   





PRO spp_swp_spi_param_esa, esa
   
   ;;------------------------------------------------------
   ;; ESA Dimensions
   r1 = 3.34                      ;; Inner Hemisphere Radius
   r2 = r1*1.06                   ;; Outer Hemisphere Radius
   r3 = r1*1.639                  ;; Inner Hemisphere Spherical Radius
   r4 = r3*1.06                   ;; Top Cap Radius
   rd = 3.863                     ;; Deflector Radius
   o1 = [0.000,-2.080]            ;; Origin of Top Cap/Spherical Section
   o2 = [0.480, 0,000]            ;; Origin of Toroidal Section
   o3 = [2.500,-0.575]            ;; Origin of Lower Deflector
   o4 = [2.500, 7.588]            ;; Origin of Upper Deflector

   deg     = findgen(9000.)/100.
   d2      =  2.5                 ;; Distance of def. from rotation axis
   dr      =  3.863               ;; Deflector Radius 38.63mm
   dist    =  0.56                ;; Distance between deflectors (58.7-53.1)
   drp     = dr+dist/2.           ;; Radius of particle path with deflection

   top_def = [[dr*cos(!DTOR*deg)],$       ;x
              [dr*sin(!DTOR*deg)]]        ;y
   top_def_path = [[drp*cos(!DTOR*deg)],$ ;x
                   [drp*sin(!DTOR*deg)]]  ;y
   deg = -1.*deg
   bot_def = [[dr*cos(!DTOR*deg)],$       ;x
              [dr*sin(!DTOR*deg)]]        ;y
   bot_def_path = [[drp*cos(!DTOR*deg)],$ ;x
                   [drp*sin(!DTOR*deg)]]  ;y
   deg = -1.*deg

   esa = {r1:r1,r2:r2,r3:r3,r4:r4,$
          o1:o1,o2:o2,o3:o3,o4:o4} 
   
END








;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************

PRO spp_swp_spi_param

   ;;------------------------------------------------------
   ;; COMMON BLOCK
   COMMON spi_param, vals

   ;;------------------------------------------------------
   ;; Science Parameters
   spp_swp_spi_param_science, sci
   
   ;;------------------------------------------------------
   ;; Anode Board Parameters
   spp_swp_spi_param_anode_board, ano

   ;;------------------------------------------------------
   ;; Anode Board Parameters
   spp_swp_spi_param_anode_board, esa

   ;;------------------------------------------------------
   ;; Telemetry Rate
   clock = 19.2e6                 ;; 19.2 [MHz]
   nys   = 1/clock * 'FFFFFF'x    ;; 0.87381327 [s] 

   ;;------------------------------------------------------
   ;; Time-of-Flight Flight Path
   tof_flight_path = 0.02    ;[m]

   ;;------------------------------------------------------
   ;; Start Electron Flight Path (Approximated)
   ;; Note: The path is a straight line and
   ;; acceleration is 1keV.
   stop_rad  = (ano.rad1+ano.rad2)/2.
   start_rad = (ano.rad3+ano.rad4)/2.
   epath = sqrt(tof_flight_path^2+((stop_rad-start_rad)*2.54/100.)^2)
   tof_e_corr = epath / $
                sqrt( (1000.*sci.evtoj) * $
                      2. / sci.mass_e_kg)
   
   ;;------------------------------------------------------
   ;; TOF Electronics Correction
   
   ;;------------------------------------------------------
   ;; Geometric Factor
   geom_factor = 1.

   ;;------------------------------------------------------
   ;; Efficiencies - Anode
      
   ;;------------------------------------------------------
   ;; Efficiencies - Deflector

   ;;------------------------------------------------------
   ;; Efficiencies - Energy

   ;;------------------------------------------------------
   ;; Colutron Characteristics
   
   ;; Model 600 Wien Filter - Gauss to Current Conv.
   col_gauss = [190.00,200.00,350.00,400.00,500.00,600.00,670.00]
   col_curr  = [  0.50,  0.60,  1.00,  1.23,  1.50,  1.85,  2.00]
   wien_param = linfit(col_curr,col_gauss)

   ;;------------------------------------------------------
   ;; Time-of-Flight Bin to Nanoseconds

   ;; Original 2048 array bin size in nanoseconds
   tof_bin = 0.101725 
   tof2048_bnds = findgen(2049)*tof_bin
   tof2048_avgs = tof2048_bnds[1:2048] - tof_bin/2

   ;; TOF Histogram
   ;; Compression 1: Cut off LSB and scheme below
   tof1024_bnds = tof2048_bnds[findgen(1025)*2]
   tof1024_avgs = tof2048_avgs[findgen(1024)*2]

   ;; Compression 2:
   ;; a) N       for         counts lt 256
   ;; b) N/2+128 for     256 ge counts lt 512
   ;; c) N/4+256 for         counts ge 512.

   ;p1_avgs      = tof1024_avgs[0:255]
   ;p2_avgs      = (tof1024_avgs[256:511])[findgen(128)*2]
   ;p3_avgs      = (tof1024_avgs[512:1023])[findgen(128)*4]
   ;tof512_avgs  = [p1_avgs,p2_avgs,p3_avgs]

   p1_bnds      = tof1024_bnds[0:256]
   p2_bnds      = (tof1024_bnds[256:512])[findgen(129)*2]
   p3_bnds      = (tof1024_bnds[512:1024])[findgen(129)*4]
   tof512_bnds  = [p1_bnds,p2_bnds[1:128],p3_bnds[1:128]]
   tof512_avgs  = (tof512_bnds[1:512]+tof512_bnds[0:511])/2.

   tof512_factor = [replicate(2,256),$
                    replicate(4,128),$
                    replicate(8,128)]
   
   ;; TOF Corrections from Flight Calibration
   tof_corr = [6, 5, 5, 6, 9, 8, 6, 6, $
               8, 5, 4, 0, 3, 3, 6, 1]

   ;; K Values from Calibration
   kval = [16.9059, 17.4086, 17.3547, 17.4056, 16.9689, $
           17.0019, 17.4656, 16.7100, 16.5611, 16.4142, $
           16.6191, 16.6381, 16.5431, 16.1663, 16.1003, 16.1353]

   ;;-----------------------------------------------------------
   ;; TOF [ms] Moyal Distributions with 1keV beam 
   ;;---------------------
   ;; Var      - Definition
   ;;---------------------
   ;; var.moy.p[0] - Coefficient
   ;; var.moy.p[1] - X Sigma
   ;; var.moy.p[2] - X Offset
   ;;
   ;; Functional Form:
   ;;
   ;; coef  = (*var.moy.p)[0,*]/sqrt(2.*!PI)/(*var.moy.p)[1,*]
   ;; z     = (*var.moy.xx-(*var.moy.p)[2,*])/(*var.moy.p)[1,*]
   ;; expo  = exp(-0.5*(z+exp(-1.*z)))   
   ;; moyss = coef * expo

   ;; NOTE: Commented values do not have
   ;;       start e- travelt time  correction

   ;; M/Q =  1 (H+) -------------------
   tof_mq1   =  [ 5295.93, 0.1841, 10.21];[ 5470.04, 0.1786, 11.44]
   tof_mq1_2 =  [   11.67, 0.3434, 26.21];[   11.08, 0.2773, 27.41]
   ;; M/Q =  2 (H2+) ------------------
   tof_mq2   =  [ 2013.17, 0.2661, 15.72];[ 2009.37, 0.2687, 16.93]
   tof_mq2_2 =  [    7.37, 0.6196, 26.41];[    6.99, 0.5057, 27.57]
   ;tof_mq2_3 =  [   50.00, 0.4000, 41.30]
   ;; M/Q =  4 (He+) ------------------
   tof_mq4  =   [15072.70, 0.1841, 22.59];[15098.76, 0.3219, 23.79]
   ;; M/Q = 14 (N+) -------------------
   tof_mq14 =   [ 6256.83, 1.2630, 46.56];[ 6318.45, 1.2800, 47.76]
   ;; M/Q = 16 (O+) -------------------
   tof_mq16   = [12901.90, 1.8893, 53.61];[12954.58, 1.8982, 54.83]
   tof_mq16_2 = [  312.06, 9.3227, 35.35];[  316.86, 9.4813, 36.68]
   tof_mq16_3 = [   10.15, 0.2841, 17.08];[    9.71, 0.2755, 18.35]
   ;; M/Q = 18 (H2O+) -----------------
   tof_mq18   = [54835.30, 2.5826, 56.41];[50510.93, 2.3723, 57.50]
   tof_mq18_2 = [  918,82, 2.1051, 44.95];[ 1207.98, 3.4384, 47.83]
   tof_mq18_3 = [ 1197.27, 3.1664, 39.95];[ 1127.26, 2.3023, 37.84]
   tof_mq18_4 = [  586.24, 1.9254, 30.65];[  617.57, 1.8847, 31.83]
   ;; M/Q = 20 (Ne+) ------------------
   tof_mq20   = [ 4193.21, 2.1612, 58.97];[ 4149.07, 2.1446, 60.21]
   tof_mq20_2 = [   51.13, 2.3090, 34.89];[   49.92, 2.2469, 36.10]
   tof_mq20_3 = [  141.17, 5.0153, 49.63];[  146.49, 5.0791, 50.93]
   ;; M/Q = 28 (???) ------------------
   tof_mq28   = [56034.10, 4.2916, 71.10];[56136.68, 4.3313, 72.30]
   tof_mq28_2 = [  180.59, 1.1200, 55.00];[  168.39, 1.2000, 56.30]
   tof_mq28_3 = [  222.65, 1.6188, 49.00];[  213.88, 1.6024, 50.30]
   tof_mq28_4 = [ 1109.50, 3.3198, 41.00];[ 1146.82, 3.3621, 42.30]
   ;; M/Q = 29 (???) ------------------
   tof_mq29   = [ 2785.29, 3.7721, 72.83];[ 2787.20, 3.7702, 74.00]
   tof_mq29_2 = [   64.41, 5.6845, 43.85];[   63.99, 5.6191, 45.04]
   ;; M/Q = 30 (???) ------------------
   tof_mq30   = [ 1152.24, 3.9932, 73.95];[ 1150.00, 3.9979, 75.17]
   tof_mq30_2 = [   46.11, 8.5072, 47.06];[   46.39, 8.5572, 48.35]
   ;; M/Q = 38 (???) ------------------
   tof_mq38   = [28727.20, 5.9106, 86.95];[28747.82, 5.9203, 88.16]
   tof_mq38_2 = [ 5553.48, 6.1426, 60.93];[ 5576.29, 6.1649, 62.12]
   tof_mq38_3 = [  898.48, 2.8359, 45.04];[  887.23, 2.8105, 46.19]
   tof_mq38_4 = [   16.84, 0.2005, 25.93];[   27.20, 0.3982, 26.97]
   tof_mq38_5 = [   40.53, 0.4622, 17.18];[   25.64, 0.2607, 18.43]
   ;; M/Q = 39 (???) ------------------
   tof_mq39   = [57521.60, 5.7394, 88.65];[57528.07, 5.7444, 89.83]
   tof_mq39_2 = [12394.80, 6.9519, 62.05];[12373.91, 6.9405, 63.25]
   ;; M/Q = 40 (???) ------------------
   tof_mq40   = [11549.80, 6.4919, 91.37];[11445.40, 6.2185, 91.73]
   tof_mq40_2 = [ 2336.54, 6.7952, 62.64];[ 2427.04, 6.9886, 64.02]
   tof_mq40_3 = [  325.19, 3.2499, 46.30];[  298.92, 3.1008, 47.20]
   tof_mq40_4 = [   10.61, 0.3338, 26.03];[    9.92, 0.3092, 27.30]
   tof_mq40_5 = [   13.67, 0.2909, 17.15];[   13.90, 0.2881, 18.38]
      

   tof_moy = {tof_mq1:tof_mq1,       $
              tof_mq1_2:tof_mq1_2,   $

              tof_mq2:tof_mq2,       $
              tof_mq2_2:tof_mq2_2,   $

              tof_mq4:tof_mq4,       $

              tof_mq14:tof_mq14,     $

              tof_mq16:tof_mq16,     $
              tof_mq16_2:tof_mq16_2, $
              tof_mq16_3:tof_mq16_3, $

              tof_mq18:tof_mq18,     $
              tof_mq18_2:tof_mq18_2, $
              tof_mq18_3:tof_mq18_3, $
              tof_mq18_4:tof_mq18_4, $
              
              tof_mq20:tof_mq20,     $
              tof_mq20_2:tof_mq20_2, $
              tof_mq20_3:tof_mq20_3, $
              
              tof_mq28:tof_mq28,     $
              tof_mq28_2:tof_mq28_2, $
              tof_mq28_3:tof_mq28_3, $
              tof_mq28_4:tof_mq28_4, $
              
              tof_mq29:tof_mq29,     $
              tof_mq29_2:tof_mq29_2, $
              
              tof_mq30:tof_mq30,     $
              tof_mq30_2:tof_mq30_2, $
              
              tof_mq38:tof_mq38,     $
              tof_mq38_2:tof_mq38_2, $
              tof_mq38_3:tof_mq38_3, $
              tof_mq38_4:tof_mq38_4, $
              tof_mq38_5:tof_mq38_5, $
              
              tof_mq39:tof_mq39,     $
              tof_mq39_2:tof_mq39_2, $
              
              tof_mq40:tof_mq40,     $
              tof_mq40_2:tof_mq40_2, $
              tof_mq40_3:tof_mq40_3, $
              tof_mq40_4:tof_mq40_4, $
              tof_mq40_5:tof_mq40_5}
              
   ;;------------------------------------------------------
   ;; DAC to Deflection (from deflector scan)
   ;;
   ;; Ion Gun: 0.85[A], 480 [eV]
   ;;
   ;; [0] + [1]*yaw + [2]*yaw^2 + [3]*yaw^3
   ;;
   anode0_poly = [-172.984,1110.45,0.5,-0.08]

   ;;------------------------------------------------------
   ;; DAC to Voltage (DVM from HV Calibration Test)

   ;; Hemisphere 
   hemi_dacs = ['0000'x,'0040'x,'0080'x,'00C0'x,'0100'x,$
                '0280'x,'0500'x,'0800'x,'0C00'x,'1000'x]
   hemi_volt = [0.006,-3.903,-7.8,-11.7,-15.61,$
                -39.04,-78.1,-125,-187.5,-250]

   ;; Deflector 1
   def1_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def1_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Deflector 2
   def2_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def2_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Spoiler 
   splr_dacs = ['0000'x,'0100'x,'0200'x,'0400'x,'1000'x,'4000'x]
   splr_volt = [0.0003,-0.31,-0.62,-1.243,-4.974,-19.9]


   hemi_fitt = linfit(hemi_dacs,hemi_volt)
   def1_fitt = linfit(def1_dacs,def1_volt)
   def2_fitt = linfit(def2_dacs,def2_volt)
   splr_fitt = linfit(splr_dacs,splr_volt)


   ;; Include times
   cal_times =  spp_swp_spi_param_fm_cal_times()


   ;;------------------------------------------------------
   ;; Davin's Energy Mass Scan results for H+, O+, and
   ;; a heavier unidentified mass.
   ;;
   ;; Exponential function used:
   ;; a[0] * exp(a[1]*x) + a[2]
   ;;
   ;; Fits derived using:
   ;; spp_swp_spi_flight_cal_energy_mass_scan.pro
   mass_enrg = [[ 27.32, -1.26e-4,  6.64],$  ; H+
                [ 58.78, -4.98e-5, 28.09],$  ; O+
                [101.35, -8.06e-5, 17.70]]   ; Unidentified



   
   vals = {$

          mass_enrg:mass_enrg,$
          
          tof_flight_path:tof_flight_path,$
          
          sci:sci, $
          
          clock: clock,$

          ano:ano,$

          esa:esa,$
          
          tof512_factor:tof512_factor,$
    
          tof_corr:tof_corr, $
          
          kval:kval, $
          
          wien_param:wien_param, $
          
          tof_bin:tof_bin, $
          
          tof_moy:tof_moy, $
          
          cal_times:cal_times,$
          
          hemi_dacs:hemi_dacs,$
          def1_dacs:def1_dacs,$
          def2_dacs:def2_dacs,$
          splr_dacs:splr_dacs,$
          
          hemi_volt:hemi_volt,$
          def1_volt:def1_volt,$
          def2_volt:def2_volt,$
          splr_volt:splr_volt,$
          
          hemi_fitt:hemi_fitt,$
          def1_fitt:def1_fitt,$
          def2_fitt:def2_fitt,$
          splr_fitt:splr_fitt,$
          
          tof2048_avgs:tof2048_avgs,$
          tof1024_avgs:tof1024_avgs,$
          tof512_avgs:tof512_avgs,  $

          tof2048_bnds:tof2048_bnds,$
          tof1024_bnds:tof1024_bnds,$
          tof512_bnds:tof512_bnds,  $

          tof_e_corr:tof_e_corr, $

          eloss:ptr_new(/alloc), $

          mass_table_0:ptr_new(/alloc), $
          mass_table_1:ptr_new(/alloc), $
          mass_table_2:ptr_new(/alloc), $
          mass_table_default:ptr_new(/alloc), $

          mrlut_1:ptr_new(/alloc), $
          mrlut_2:ptr_new(/alloc) $
          
          }



   ;;------------------------------------------------------
   ;; Energy Loss Matrix
   spp_swp_spi_param_eloss_matrix,eloss
   *vals.eloss =  eloss

   spp_swp_spi_param_mass_table,/write_file

END
