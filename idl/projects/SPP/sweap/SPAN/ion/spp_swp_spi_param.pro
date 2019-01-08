;+
;
; SPP_SWP_SPI_PARAM
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26425 $
; $LastChangedDate: 2019-01-06 22:03:49 -0800 (Sun, 06 Jan 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_param.pro $
;
;-

PRO spp_swp_spi_param

   ;; COMMON BLOCK
   COMMON spi_param, param, dict

   ;; Events
   spp_swp_spi_flight_evt, evt

   ;; DAC to Voltage
   spp_swp_spi_flight_dac, dac

   ;; DAC to Deflection
   spp_swp_spi_flight_def, def

   ;; DAC to Energy
   spp_swp_spi_flight_nrg, nrg

   ;; Memory Map
   spp_swp_spi_flight_mem, mem

   ;; Sweep Tables
   spp_swp_spi_flight_tbl, tbl
   
   ;; Science Parameters
   spp_swp_spi_flight_sci, dac, sci
   
   ;; Anode Board
   spp_swp_spi_flight_ano, ano

   ;; Electrostatic Analyzer
   spp_swp_spi_flight_esa, esa

   ;; Time-of-Flight Parameters
   spp_swp_spi_flight_tof, ano, sci, tof

   ;; Ion Carbon Foil Energy Loss
   spp_swp_spi_flight_elo, sci, tof, elo

   ;; Mass Tables
   spp_swp_spi_flight_mas, mas, dac, sci, tof, elo
   
   ;; Geometric Factor
   spp_swp_spi_flight_geo, geo

   ;; Efficiencies - Anode
   ;;spp_swp_spi_flight_eff_ano, eff_ano
   
   ;; Efficiencies - Deflector
   ;;spp_swp_spi_flight_eff_def, eff_def
   
   ;; Efficiencies - Energy
   ;;spp_swp_spi_flight_eff_nrg, eff_nrg

   ;; Final Structure
   param = {sci:sci,$
            evt:evt,$
            dac:dac,$
            tbl:tbl,$
            ano:ano,$
            esa:esa,$
            elo:elo,$
            def:def,$
            mas:mas,$
            tof:tof,$
            geo:geo}
            ;;eff_ano:eff_ano,$
            ;;eff_def:eff_def,$
            ;;eff_nrg:eff_nrg}

   
END
