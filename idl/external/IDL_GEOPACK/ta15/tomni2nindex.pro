pro tomni2nindex, imf_by=imf_by,imf_bz=imf_bz, sw_speed=sw_speed,out_name=out_name

   if ~keyword_set(imf_by) || (size(imf_by,/type) ne 7) then begin
      dprint,'Required imf_by parameter missing or invalid'
      return
   endif
   
   if ~keyword_set(imf_bz) || (size(imf_bz,/type) ne 7) then begin
     dprint,'Required imf_bz parameter missing or invalid'
     return
   endif

   if ~keyword_set(sw_speed) || (size(sw_speed,/type) ne 7) then begin
     dprint,'Required sw_speed parameter missing or invalid'
     return
   endif

   if ~keyword_set(out_name) || (size(out_name,/type) ne 7) then begin
     dprint,'Required out_name parameter missing or invalid'
     return
   endif
   
   get_data,imf_by,data=imf_by_d
   get_data,imf_bz,data=imf_bz_d
   get_data,sw_speed,data=sw_speed_d
   
   if size(imf_by_d,/type) ne 8 then begin
    dprint,imf_by+' is not a valid tplot variable name.'
    return
   endif
   
   if size(imf_bz_d,/type) ne 8 then begin
     dprint,imf_bz+' is not a valid tplot variable name.'
     return
   endif

   if size(sw_speed_d,/type) ne 8 then begin
     dprint,sw_speed+' is not a valid tplot variable name.'
     return
   endif

   n_index = omni2nindex(imf_by=imf_by_d.y, imf_bz=imf_bz_d.y, sw_speed=sw_speed_d.y)   

   store_data,out_name,data={x:imf_by_d.x, y:n_index}
end
