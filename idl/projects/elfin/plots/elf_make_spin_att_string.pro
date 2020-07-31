function elf_make_spin_att_string, probe=probe

   get_data, 'el'+probe+'_spin_att_ang', data=d
   zone_string1='B/SP: ' 
   zone_string2=' (NA/ND/SD/SA, deg) '
   zone_string=''
   
   ; Find NA, ND, SD, SA
   idx=where(d.z EQ 'NA', ncnt)
   if ncnt EQ 0 then begin
      print, 'Error - No North Ascending node was found'
      return, -1
   endif else begin
      zone_string=zone_string+strtrim(string(fix(d.y[idx])),1)+'/'
   endelse
   
   idx=where(d.z EQ 'ND', ncnt)
   if ncnt EQ 0 then begin
     print, 'Error - No North Descending node was found'
     return, -1
   endif else begin
     zone_string=zone_string+strtrim(string(fix(d.y[idx])),1)+'/'
   endelse

   idx=where(d.z EQ 'SD', ncnt)
   if ncnt EQ 0 then begin
     print, 'Error - No South Descending node was found'
     return, -1
   endif else begin
     zone_string=zone_string+strtrim(string(fix(d.y[idx])),1)+'/'
   endelse

   idx=where(d.z EQ 'SA', ncnt)
   if ncnt EQ 0 then begin
     print, 'Error - No South Ascending node was found'
     return, -1
   endif else begin
     zone_string=zone_string+strtrim(string(fix(d.y[idx])),1)
   endelse
        
   full_zone_string=zone_string1+zone_string+zone_string2

   return, full_zone_string
   
end