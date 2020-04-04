;+
;  spp_data_product_hash
;  This basic object is the entry point for defining and obtaining all data for all data products
; $LastChangedBy:  $
; $LastChangedDate: 2019-01-29 16:17:12 -0800 (Tue, 29 Jan 2019) $
; $LastChangedRevision:  $
; $URL: svn+ssh://thmsvn@pro $
;-
;COMPILE_OPT IDL2


FUNCTION spp_data_product_hash,name,data,help=help,delete=delete
  COMPILE_OPT IDL2
  common spp_data_product_com, alldat
  if ~ keyword_set(alldat) then begin
    dprint,'Initializing Storage space'
    alldat = orderedhash()
  endif
  if keyword_set(help) then begin
    print,alldat.keys()
  endif
  if isa(name,/string) then begin
    if ~ alldat.haskey(name) then begin
      dp = spp_data_product(name=name)
      alldat[name] = dp
    endif else begin
      dp = alldat[name]
      if keyword_set(delete) then begin
        alldat.remove,name
        obj_destroy,dp
        return,!null
      endif
    endelse
    if isa(data) then begin
      dp.savedat, data
    endif
    return,dp
  endif
  return,!null
END






