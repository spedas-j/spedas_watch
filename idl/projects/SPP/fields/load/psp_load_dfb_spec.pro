pro psp_load_dfb_spec, files = files

  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_dfb_', verbose=4, /get_support

    options, 'psp_fld_dfb_spec*', 'ylog', 1
    options, 'psp_fld_dfb_spec*', 'no_interp', 1

    options, 'psp_fld_dfb_spec*', 'ysubtitle', '[Hz]'
    options, 'psp_fld_dfb_spec*', 'ztitle', 'Log Auto [arb]'

  end

end