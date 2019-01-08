;+
;
; SPP_SWP_SPI_FLIGHT_TBL
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26431 $
; $LastChangedDate: 2019-01-06 22:08:29 -0800 (Sun, 06 Jan 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_tbl.pro $
;
;-

PRO spp_swp_spi_flight_tbl, tbl

   spp_swp_spi_tables, tbl1, modeid='0010'x
   spp_swp_spi_tables, tbl2, modeid='0020'x
   spp_swp_spi_tables, tbl3, modeid='0030'x
   spp_swp_spi_tables, tbl4, modeid='0040'x
   spp_swp_spi_tables, tbl5, modeid='0050'x
   spp_swp_spi_tables, tbl6, modeid='0060'x

   tbl = {tbl1:tbl1,$
          tbl2:tbl2,$
          tbl3:tbl3,$
          tbl4:tbl4,$
          tbl5:tbl5,$
          tbl6:tbl6}
   
END
