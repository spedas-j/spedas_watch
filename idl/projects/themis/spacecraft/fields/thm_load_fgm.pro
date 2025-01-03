;+
;Procedure: THM_LOAD_FGM
;
;Purpose:  Loads THEMIS fluxgate magnetometer data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, 'fge', 'fgh', or 'fgl'.  'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data to read, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  type=   'raw' or 'calibrated'. default is calibrated.
;  coord=  coordinate system of output.  default is 'dsl'
;  suffix= suffix to add to output data quantity (not added to support data)
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;          into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info, set to 0 to or 1 to reduce output.
;  /NO_TIME_CLIP: Disables time clipping, which is the default
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections 
;   applied).  use_eclipse_corrections=1 applies partial eclipse 
;   corrections (not recommended, used only for internal SOC processing).  
;   use_eclipse_corrections=2 applies all available eclipse corrections.
;  
;  NOTE: The following keywords are only used if level=1 is set 
;  cal_dac_offset = apply calibrations that remove digital analog
;                   converter nonlinearity by addition of offset.
;                   Algorithm generated by Dragos Constantine
;                   <d.constantinescu@tu-bs.de>. This is the default
;                   process as of 7-Jan-2010, to disable, explicitly
;                   set this keyword to 0.
;  cal_spin_harmonics = apply calibrations from a file that remove
;                       spin harmonics by applying spin-dependent
;                       offsets generated by David Fischer
;                       <david.fischer@oeaw.ac.at>. This is the default  
;                       process as of 7-Jan-2010, to disable, explicitly
;                       set this keyword to 0. 
;  cal_tone_removal = fitting algorithm removes orbit dependent
;                     spintone without removing scientifically salient
;                     features. Algorithm generated by Ferdinand Plaschke
;                     <f.plaschke@tu-bs.de>. This is the default  
;                     process as of 7-Jan-2010, to disable, explicitly
;                     set this keyword to 0. 
;  cal_get_fulloffset = returns the offset used for spintone removal.(this keyword used for valididation)
;                       Because there may be a different offset for each combination of probe and datatype, 
;                       This is returned as a struct of structs, with each element in the child structs being an N by 3 array.
;                       For example, if offset_struct is the name of a struct with the return value from the cal_get_fulloffset keyword,
;                         print,offset_struct.tha.fgl
;                       Will print the fulloffset for probe a and datatype fgl.
;  cal_get_dac_dat = Returns the raw data from directly after the DAC(non-linearity offset) calibration is applied.  For verification.
;  cal_get_spin_dat = Returns the raw data from directly after the spin harmonic(solar array current) calibration is applied.  For verification.
;  interpolate_cal = if it is set, then thm_cal values are interpolated to 10 min time intervals
; check_l1b: if set, then look for L1B data files that include
;            estimates for Bz. This is the deafult for THEMIS E 
;            after 2024-06-01 (date subject to change....)
;  
;Example:
;   thg_load_fgm,probe=['a','b']
;Notes:
;  This routine is (should be) platform independent.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-11-20 11:24:00 -0800 (Wed, 20 Nov 2024) $
; $LastChangedRevision: 32968 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_load_fgm.pro $
;-

; fgm-specific helper function
; to return relative path names to files in the data tree.
; this routine maps datatypes to file type.
function thm_load_fgm_relpath, sname=probe, filetype=ft, $
                               level=lvl, trange=trange, $
                               addmaster=addmaster, _extra=_extra

  relpath = 'th'+probe+'/'+lvl+'/'+ ft+'/'
  prefix = 'th'+probe+'_'+lvl+'_'+ft+'_'
  dir = 'YYYY/'

;     The following was a temporary cluge to get to tmserver1 data
;     I am leaving it in place as an example of how to call
;     file_dailynames with an alternative directory structure.
  if strcmp(!themis.remote_data_dir, 'http://themis-tmserver1',18) eq 1 $
  then begin
;    pathformat = 'L1CDF/th'+sc+'/YYYY/MM/DD/th'+sc+'_l1_fgm_YYYYMMDD_v01.cdf'
     relpath = 'L1CDF/th'+probe+'/'
     dir = 'YYYY/MM/DD/'
  endif
  ending = '_v01.cdf'

  return, file_dailynames(relpath, prefix, ending, dir=dir, $
                          trange = trange,addmaster=addmaster)
end

pro thm_load_fgm_post, sname=probe, datatype=dt, level=lvl, $
                       tplotnames=tplotnames, $
                       interpolate_cal=interpolate_cal, $
                       suffix=suffix, proc_type=proc_type, coord=coord, $
                       delete_support_data=delete_support_data,cal_spin_harmonics=cal_spin_harmonics,$
                       cal_dac_offset=cal_dac_offset,cal_tone_removal=cal_tone_removal,$
                       cal_get_fulloffset=cal_get_fulloffset,cal_get_dac_dat=cal_get_dac_dat,$
                       cal_get_spin_dat=cal_get_spin_dat,$
                       use_eclipse_corrections=use_eclipse_corrections,_extra=_extra

  ;; remove suffix from support data
  ;; and add DLIMIT tags to data quantities
  for l=0, n_elements(tplotnames)-1 do begin
     tplot_var = tplotnames[l]
     dtl = strmid(tplot_var, 4, 3)
     get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
     if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' $
     then begin
        if strmatch(lvl, 'l1') then begin
           unit='ADC'
           data_att = { data_type:'raw', coord_sys:'fgm_sensor', $
                        units:unit}
           labels = [ 'b1', 'b2', 'b3']
           colors = [ 2, 4, 6]
        end else if strmatch(lvl, 'l2') then begin
           spd_new_units, tplot_var
           spd_new_coords, tplot_var
           get_data, tplot_var, dlimits = dl_str
           
           str_element, dl_str.data_att, 'units', success=s
           if s eq 1 then begin
             unit = dl_str.data_att.units
  ;the units tag has the coordinate system included; for ysubtitle and
  ;for SPDF plots. Strip it from the units tag here, but not from the
  ;'unit' variable, since that goes to ysubtitle
             u1 = strsplit(unit, ' ', /extract)
             dl_str.data_att.units = u1[0]
           endif else unit = 'unknown'
           data_att = dl_str.data_att
           is_btotal = total(strmatch(strsplit(tplot_var, '_', /extract), 'btotal'))
           If(is_btotal Gt 0) Then Begin
             labels = '|B|'
             colors = 0
           Endif Else Begin
             labels = [ 'bx', 'by', 'bz']
             colors = [2, 4, 6]
           Endelse
        end
        str_element, dl_str, 'data_att', data_att, /add
        str_element, dl_str, 'colors', colors, /add
        str_element, dl_str, 'labels', labels, /add
        str_element, dl_str, 'labflag', 1, /add
        str_element, dl_str, 'ytitle', tplot_var, /add
        str_element, dl_str, 'ysubtitle', '['+unit+']', /add
        store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
     endif else begin
        ;; for support data,
        ;; rename original variable to exclude suffix
        if keyword_set(suffix) then begin
           tplot_var_root = strmid(tplot_var, 0, $
                                   strpos(tplot_var, suffix, /reverse_search))
         ;  store_data, delete=tplot_var
           if tplot_var_root then begin
              store_data, tplot_var_root, data=d_str, limit=l_str, dlimit=dl_str
           endif
          tplot_var = tplot_var_root
        endif  
        ;; save name of support tplot variable for possible deletion
        if tplot_var  then begin
           if size(support_var_list,/type) eq 0 then $
              support_var_list = [tplot_var +suffix[0]] $
           else $
              support_var_list = [support_var_list,tplot_var+suffix[0]]
             
            if size(tplot_var_root,/type) ne 0 then begin  
                if size(support_var_root_list,/type) eq 0 then $
                   support_var_root_list = [tplot_var_root] $
                else $
                  support_var_root_list = [support_var_root_list,tplot_var_root]   
            endif
              
        endif

     endelse
  endfor

  ;; calibrate and transform coordinates, if this is L1
  if strmatch(lvl, 'l1') then begin
     if ~keyword_set(proc_type) || strmatch(proc_type, 'calibrated') then begin
        thm_cal_fgm, probe=probe, datatype=dt, coord=coord, $
                     in_suffix=suffix, out_suffix=suffix,$
                     cal_spin_harmonics=cal_spin_harmonics,$
                     cal_dac_offset=cal_dac_offset,$                     
                     interpolate_cal=interpolate_cal,$
                     cal_tone_removal=cal_tone_removal,$
                     cal_get_fulloffset=cal_get_fulloffset,$
                     cal_get_dac_dat=cal_get_dac_dat,$
                     cal_get_spin_dat=cal_get_spin_dat,$
                     use_eclipse_corrections=use_eclipse_corrections, $
                     _extra = _extra
                    
        ;; delete support data
        if keyword_set(delete_support_data) then begin
          if size(support_var_list, /type) ne 0 then del_data, support_var_list
          if size(support_var_root_list, /type) ne 0 then del_data, support_var_root_list
        endif else begin
          if keyword_set(suffix) then  begin
            if size(support_var_root_list, /type) ne 0 then del_data, support_var_root_list
          endif 
        endelse           
        
     endif

  endif
end


pro thm_load_fgm, probe = probe, datatype = datatype, trange = trange, $
                  level = level, verbose = verbose, downloadonly = downloadonly, $
                  relpathnames_all = relpathnames_all, no_download = no_download, $
                  cdf_data = cdf_data, get_support_data = get_support_data, $
                  varnames = varnames, valid_names = valid_names, files = files, $
                  suffix = suffix, type = type, coord = coord,  $
                  interpolate_cal=interpolate_cal,$
                  progobj = progobj, cal_spin_harmonics = cal_spin_harmonics, $
                  cal_dac_offset = cal_dac_offset, cal_tone_removal = cal_tone_removal, $
                  cal_get_fulloffset = cal_get_fulloffset, cal_get_dac_dat = cal_get_dac_dat, $
                  cal_get_spin_dat = cal_get_spin_dat, $
                  use_eclipse_corrections=use_eclipse_corrections, $
                  _extra = _extra

  if ~keyword_set(probe) then probe = ['a', 'b', 'c', 'd', 'e']

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  if not keyword_set(suffix) then suffix = ''
  if not keyword_set(coord) then coord='dsl'
  if n_elements(use_eclipse_corrections) LT 1 then use_eclipse_corrections=0
  if ~keyword_set(interpolate_cal) then interpolate_cal=0 else interpolate_cal=1
  
  vlevels = 'l1 l2'
  deflevel = 'l1'
  lvl = thm_valid_input(level,'Level',vinputs=vlevels,definput=deflevel,$
                        format="('l', I1)", verbose=0)
  if lvl eq '' then return

  if lvl eq 'l2' and keyword_set(type) then begin
    dprint, "Type keyword not valid for level 2 data."
    return
  endif

  if lvl eq 'l1' then begin
     ;; default action for loading level 1 is to calibrate
     if ~keyword_set(type) || strmatch(type, 'calibrated') then begin
        ;; we're calibrating, so make sure we get support data
        if not keyword_set(get_support_data) then begin
           get_support_data = 1
           delete_support_data = 1
        endif
     endif
     ;; check that a minimum of 10 minutes is available for spin calibration     
     if ~keyword_set(trange) then trange=timerange()
     dur = time_double(trange[1])-time_double(trange[0])
     ;; if not then pad duration to 10 minutes 
     if dur LT 600.d then begin
        new_range = [time_double(trange[0])+dur/2.-300., time_double(trange[0])+dur/2.+300.]
        trange = time_string(new_range)
        dprint, "FGM data padded to 10 minutes duration for spin calibration"        
     endif    
  endif

  thm_load_xxx, sname = probe, datatype = datatype, trange = trange, $
    level = level, verbose = verbose, downloadonly = downloadonly, $
    relpathnames_all = relpathnames_all, no_download = no_download, $
    cdf_data = cdf_data, get_cdf_data = arg_present(cdf_data), $
    get_support_data = get_support_data, $
    varnames = varnames, valid_names = valid_names, files = files, $
    vsnames = 'a b c d e', $
    type_sname = 'probe', $
    vdatatypes = 'fgl fgh fge', $
    file_vdatatypes = 'fgm', $
    vlevels = vlevels, $
    vL2datatypes = 'fgs fgl fgh fge fgs_btotal fgl_btotal fgh_btotal fge_btotal', $
    vL2coord = 'ssl dsl gse gsm none', $
    vtypes = 'raw calibrated', $
    deflevel = deflevel, $
    version = 'v01', $
    relpath_funct = 'thm_load_fgm_relpath', $
    post_process_proc = 'thm_load_fgm_post', $
    delete_support_data = delete_support_data, $
    proc_type = type, coord = coord, suffix = suffix, $
    progobj = progobj, $
    cal_spin_harmonics = cal_spin_harmonics, $
    cal_dac_offset = cal_dac_offset, $
    cal_tone_removal = cal_tone_removal, $
    cal_get_fulloffset = cal_get_fulloffset, $
    cal_get_dac_dat = cal_get_dac_dat, $
    cal_get_spin_dat = cal_get_spin_dat, $
    use_eclipse_corrections=use_eclipse_corrections,$
    msg_out = msg_out, $
    interpolate_cal=interpolate_cal,$
    _extra = _extra

  
  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end
