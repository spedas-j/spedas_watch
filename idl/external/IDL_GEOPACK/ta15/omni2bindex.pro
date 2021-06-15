function omni2bindex,imf_by=imf_by,imf_bz=imf_bz, sw_prot_dens=sw_prot_dens, sw_speed=sw_speed

   ; clock angle of IMF, radians
   theta_c = atan2(imf_by,imf_bz)
   
   ; tangential component of IMF  
   b_t = sqrt(imf_by*imf_by + imf_bz*imf_bz)
   
   bt5 = b_t/5.0D
     
   stc2 = sin(theta_c/2.0D)
   stc2_sqr = stc2*stc2  ; squared
   stc3 = stc2*stc2_sqr  ; cubed
   stc6 = stc3*stc3  ;  6th power of sin(theta_c/2)
   
   
   b_index = sqrt(sw_prot_dens/5.0D)*(sw_speed/400.0D)^(5.0D/2.0D) * bt5 * stc6
   
   return, b_index
end