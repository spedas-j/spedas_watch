;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2018-11-08 16:37:26 -0800 (Thu, 08 Nov 2018) $
;  $LastChangedRevision: 26080 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_earth_fixed_load_l1.pro $
;

pro spp_fld_ephem_earth_fixed_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_EARTH_FIXED_'

  spp_fld_ephem_load_l1, file, prefix = prefix

end