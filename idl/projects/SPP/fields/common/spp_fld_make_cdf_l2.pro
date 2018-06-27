pro spp_fld_make_cdf_l2, l2_datatype, $
  l2_master_cdf, $
  trange = trange, $
  l1_cdf_datatypes = l1_cdf_datatypes, $
  l1_cdf_files = l1_cdf_files, $
  filename = filename, $
  load = load
 
  if n_elements(l1_cdf_files) GT 0 then begin
    
    ; use provided files
    
    ;foreach l1_cdf_file, l1_cdf_files do spp_fld_load_l1, l1_cdf_file
    
  endif else begin

    ; return    
    
  endelse


  ;
  ; If load keyword set, load file into tplot variables
  ;

  if keyword_set(load) then begin

    if file_test(filename) then begin

      spp_fld_load_l2, filename

      if !spp_fld_tmlib.test_cdf_dir NE '' then begin

        file_mkdir, !spp_fld_tmlib.test_cdf_dir

        file_copy, filename, !spp_fld_tmlib.test_cdf_dir, /over

      end

    end

  end

end