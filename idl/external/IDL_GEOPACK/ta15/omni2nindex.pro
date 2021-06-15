function omni2nindex,imf_by=imf_by,imf_bz=imf_bz, sw_speed=sw_speed

   ; clock angle of IMF, radians
   theta_c = atan2(imf_by,imf_bz)
   
   ; tangential component of IMF  
   b_t = sqrt(imf_by*imf_by + imf_bz*imf_bz)
   
   ; Raise to even powers first, to avoid NaNs with fractional exponents
   bt5 = b_t/5.0D
   bt5_sqr = bt5*bt5
   
   stc2 = sin(theta_c/2.0D)
   stc2_sqr = stc2*stc2
   stc4 = stc2_sqr*stc2_sqr
   stc8 = stc4*stc4  ;  8th power of sin(theta_c/2)
   
   
   n_index = 0.86D * (sw_speed/400.0D)^(4.0D/3.0D) * (bt5_sqr)^(1.0/3.0D) * stc8^(1.0D/3.0D)
   
   return, n_index
end