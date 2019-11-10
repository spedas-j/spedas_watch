;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2019-11-09 17:31:21 -0800 (Sat, 09 Nov 2019) $
; $LastChangedRevision: 28000 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/psp_fld_load.pro $
;
;-

pro psp_fld_load, trange=trange, type = type, $
  files=files, $
  fileprefix=fileprefix,$
  tname_prefix=tname_prefix, $
  pathformat=pathformat,$
  varformat=varformat, $
  get_support = get_support, $
  no_staging = no_staging

  spp_fld_load, trange=trange, type = type, $
    files = files, $
    fileprefix = fileprefix,$
    tname_prefix = tname_prefix, $
    pathformat = pathformat,$
    varformat = varformat, $
    level = 2, $
    get_support = get_support, $
    no_staging = 1

end
