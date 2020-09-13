;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2020-09-11 23:51:55 -0700 (Fri, 11 Sep 2020) $
; $LastChangedRevision: 29148 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/psp_fld_examples.pro $
;
;-

pro psp_fld_examples

  ; First, show the directory where you have SPEDAS installed.  If this yields
  ; an error or no result, then you need a recent 'bleeding edge' version
  ; of SPEDAS, see:
  ; http://spedas.org/wiki/index.php?title=Main_Page#Downloads_and_Installation

  libs, 'psp_fld_load'

  ; Confirm that you have installed a recent version of the CDF patch.
  ; Versions including and above 3.6.3.1 should work.  If you don't have a
  ; recent version, install one from:
  ; https://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html
  
  help, 'CDF', /dlm
  
  ; You can download files manually and load them, but it's easier to use
  ; the SPEDAS file_retrieve routine. 

  ; Set a timespan for four days near perihelion 2.

  timespan, '2019-04-03', 4
  
  ; This command downloads MAG data in RTN coordinates
  
  psp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'

  psp_fld_load, type = 'rfs_hfr'
  psp_fld_load, type = 'rfs_lfr'
  
  stop

  tplot, ['psp_fld_l2_mag_RTN_4_Sa_per_Cyc', $
    'psp_fld_l2_rfs_hfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_quality_flags']

end