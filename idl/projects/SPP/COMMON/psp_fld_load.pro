;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2020-12-13 22:47:02 -0800 (Sun, 13 Dec 2020) $
; $LastChangedRevision: 29477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/psp_fld_load.pro $
;
;-

pro psp_fld_load, trange=trange, type = type, $
  files=files, $
  fileprefix=fileprefix,$
  tname_prefix=tname_prefix, $
  pathformat=pathformat,$
  varformat=varformat, $
  level = level, $
  longterm_ephem = longterm_ephem, $
  get_support = get_support, $
  no_staging = no_staging, $
  version = version

  if n_elements(level) EQ 0 then level = 2

  spp_fld_load, trange=trange, type = type, $
    files = files, $
    fileprefix = fileprefix,$
    tname_prefix = tname_prefix, $
    pathformat = pathformat,$
    varformat = varformat, $
    level = level, $
    longterm_ephem = longterm_ephem, $
    get_support = get_support, $
    version = version, $
    no_staging = 1

end
