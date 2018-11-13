;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2018-10-11 11:55:31 -0700 (Thu, 11 Oct 2018) $
;  $LastChangedRevision: 25956 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_j2000_load_l1.pro $
;

pro spp_fld_ephem_j2000_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_j2000_'

  spp_fld_ephem_load_l1, file, prefix = prefix

end