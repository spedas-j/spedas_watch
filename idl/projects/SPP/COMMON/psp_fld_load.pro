;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2020-10-26 15:37:07 -0700 (Mon, 26 Oct 2020) $
; $LastChangedRevision: 29296 $
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
  get_support = get_support, $
  no_staging = no_staging

  if n_elements(level) EQ 0 then level = 2

  spp_fld_load, trange=trange, type = type, $
    files = files, $
    fileprefix = fileprefix,$
    tname_prefix = tname_prefix, $
    pathformat = pathformat,$
    varformat = varformat, $
    level = level, $
    get_support = get_support, $
    no_staging = 1

end
