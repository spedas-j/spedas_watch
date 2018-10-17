PRO spp_swp_spi_tables, table, modeid=modeid

   ;; Parse MODE ID
   IF ~keyword_set(modeid) THEN BEGIN
      print, 'MODEID not defined. Using default 0x0015'
      modeid = '15'x
   ENDIF 
   energy_id = (ishft(modeid,-4) and 15)
   tmode_id  = (ishft(modeid,-8) and 15)

   ;; SPAN-Ai Instrument Parameters
   k = 16.7
   nen = 128.
   emin = 5.
   emax = 4000.
   rmax = 11.
   vmax = 4000.
   spfac = 0.
   maxspen = 5000.
   hvgain = 1000.
   spgain = 20.12
   fixgain = 13.
   version = 2
   
   ;; Select Energy Table
   CASE energy_id OF
      ;; Science Tables 0x01
      '01'x: BEGIN
         emin  = 500.
         emax  = 2000.
         spfac = 0.15
      END
      ;; Science Tables 0x02
      '02'x: BEGIN
         emin  = 5.
         emax  = 1500.
         spfac = 0.15
      END
      ;; Science Tables 0x03
      '03'x: BEGIN
         emin  = 1500.
         emax  = 20000.
         spfac = 0.15
      END
      ;; Science Tables 0x04
      '04'x: BEGIN
         emin  = 5.
         emax  = 20000.
         spfac = 0.15
      END
   ENDCASE

   ;; Structure with values
   table = { modeid:modeid,$
             energy_id:energy_id,$
             tmode_id:tmode_id,$
             version:version,$
             k:k,$
             rmax:rmax,$
             vmax:vmax,$
             nen:nen,$
             emin:emin,$
             emax:emax,$
             spfac:spfac,$
             maxspen:maxspen,$
             hvgain:hvgain,$
             spgain:spgain,$
             fixgain:fixgain,$
             hem_dac:intarr(4096),$
             def1_dac:intarr(4096),$
             def2_dac:intarr(4096),$
             spl_dac:intarr(4096),$
             hem_v:intarr(4096),$
             def1_v:intarr(4096),$
             def2_v:intarr(4096),$
             spl_v:intarr(4096),$
             fsindex:intarr(1024),$
             tsindex:intarr(256,256)}

   ;; Compile
   spp_swp_spx_tables, table

   ;; Sweep Table Voltages
   spp_swp_spx_get_voltages, table

   ;; Sweep Table Voltages
   spp_swp_spx_get_dacs, table

   ;; Full Sweep Index
   spp_swp_spx_get_fslut, table

   ;; Targeted Sweep Index
   FOR i=0, 255 DO spp_swp_spx_get_tslut, table, i

   stop
   
END
