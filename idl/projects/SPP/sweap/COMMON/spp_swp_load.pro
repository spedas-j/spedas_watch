; $LastChangedBy: ali $
; $LastChangedDate: 2019-10-18 14:47:33 -0700 (Fri, 18 Oct 2019) $
; $LastChangedRevision: 27898 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_load.pro $
;
pro spp_swp_load,ssr=ssr,all=all,spe=spe,spi=spi,spc=spc,mag=mag,fld=fld,trange=trange,types=types,level=level,varformat=varformat

  if keyword_set(all) then begin
    spe=1
    spi=1
    spc=1
    mag=1
    fld=1
  endif
  
  if keyword_set(spe) then spp_swp_spe_load,trange=trange,types=types,level=level,varformat=varformat
  if keyword_set(spi) then spp_swp_spi_load,trange=trange,types=types,level=level,varformat=varformat
  if keyword_set(spc) then spp_swp_spc_load,trange=trange,type=types,ltype=level,/nul
  if keyword_set(mag) then spp_swp_mag_load,trange=trange,type=types
  if keyword_set(fld) then spp_fld_load,trange=trange,type=types,level=level,varformat=varformat

  if keyword_set(ssr) then begin
    ssrfiles = spp_file_retrieve(/ssr,trange=trange)
    spp_ssr_file_read,ssrfiles
  endif

end
