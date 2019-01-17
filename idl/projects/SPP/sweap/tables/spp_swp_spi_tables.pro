;+
;
; spp_swp_spi_tables
;
; :Params:
;    table : in, required, type=structure
;       PSP SWEAP SPAN-Ai Flight energy and telemetry mode configurations.
;    modeid : in, optional, type=integer
;       
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-01-15 22:37:05 -0800 (Tue, 15 Jan 2019) $
; $LastChangedRevision: 26467 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_spi_tables.pro $
;-

PRO spp_swp_spi_tables, table, modeid=modeid, verbose=verbose

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
         IF keyword_set(verbose) THEN print, 'Science Tables 0x01'
         ;; Launch
         emin  = 500.
         emax  = 2000.
         spfac_a = 0.10
         spfac_b = 0.25
         ;; 1st orbit (only ping side changed)
         emin  = 500.
         emax  = 10000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x02
      '02'x: BEGIN
         IF keyword_set(verbose) THEN print, 'Science Tables 0x02'
         emin  = 5.
         emax  = 1500.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x03
      '03'x: BEGIN
         IF keyword_set(verbose) THEN print, 'Science Tables 0x03'
         emin  = 1500.
         emax  = 20000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x04
      '04'x: BEGIN
         IF keyword_set(verbose) THEN print, 'Science Tables 0x04'
         emin  = 1000.
         emax  = 4000.
         spfac_a = 0.10
         spfac_b = 0.25
         ;; Science Tables 0x05
      END 
      '05'x: BEGIN
         IF keyword_set(verbose) THEN print, 'Science Tables 0x05'
         emin  = 125.
         emax  = 20000.
         spfac_a = 0.10
         spfac_b = 0.25
      END 
      ;; Science Tables 0x06
      '06'x: BEGIN
         IF keyword_set(verbose) THEN print, 'Science Tables 0x06'
         emin  = 4000.
         emax  = 40000.
         spfac_a = 0.10
         spfac_b = 0.25
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
             spfac:spfac_a,$
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

END
