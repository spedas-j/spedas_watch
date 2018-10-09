;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2018-10-08 17:26:35 -0700 (Mon, 08 Oct 2018) $
;  $LastChangedRevision: 25933 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_eclipj2000_load_l1.pro $
;

pro spp_fld_ephem_eclipj2000_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_ECLIPJ2000_'

  spp_fld_ephem_load_l1, file, prefix = prefix

end