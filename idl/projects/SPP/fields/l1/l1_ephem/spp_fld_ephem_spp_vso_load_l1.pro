;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2018-10-09 16:19:41 -0700 (Tue, 09 Oct 2018) $
;  $LastChangedRevision: 25943 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_spp_vso_load_l1.pro $
;

pro spp_fld_ephem_spp_vso_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_SPP_VSO_'

  spp_fld_ephem_load_l1, file, prefix = prefix

end