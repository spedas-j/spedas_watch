;+
;NAME:
;fa_despin_process
;PURPOSE:
;For a given orbit or time interval, grab fields data already loaded
;into sdt, via sdt_batch, run fa_fields_despin, and write out a CDF
;file with the data.
;CALLING SEQUENCE:
;fa_despin_process, full_database_management = full_database_management, $
;                   datatype = datatype
;INPUT:
;None, the data are assumed to have been loaded in an sdt_batch call
;OUTPUT:
;No explicit output
;KEYWORDS:
;full_database_management = if set, will handle deletion of a lock
;file created by the shell script that calles the program, and
;increment the file 'orbit.txt'. Also writes CDF file with proper
;orbit and datetime in filename. Otherwise a generic CDF is produced.
;datatype = 'S', 'svy' (same as S), '4k', '16k', the default is survey
;data.
;nocatch = run without the catch error block, so that you can debug
;directory = if set, the data will be put in a subdirectory of this,
;arranged by datatype and orbit number. The default is
;/disks/data/fast/l2/. Only used for full_database_management option,
;otherwise, the file is written to the current directory
;
;HISTORY:
; 19-mar-2024, jmm, jimm@ssl.berkeley.edu
; 16-apr-2024, jmm, adds sc/potential to output
; 5-sep-2024, jmm, added E_0_S_GSE, GSM, DSC, and all probe
;                  potentials, version 3
; 16-sep-2024, jmm, added spin axis direction in GSE, GSM, prepended
;                   FAST_ to variables that didn't have
;                   it. Dropped spinfit variables
;-
Pro fa_despin_process, full_database_management = full_database_management, $
                       datatype = datatype, nocatch = nocatch, directory = directory

;catch errors
  error_status = 0
  If(~keyword_set(nocatch)) Then Begin
     catch, error_status
     If(error_status ne 0) Then Begin
        catch, /cancel
        print, '%FA_DESPIN_PROCESS: Got Error Message'
        help, /last_message, output = err_msg
        For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
        If(keyword_set(full_database_management)) Then Begin
           message, /info, 'Full database management invoked.'
           If(orb_process) Then Begin
              message, /info, 'Incrementing orbit.txt'
              orbit = long(orb_str)
              orbit = orbit+1
              orb_str = strcompress(string(orbit), /remove_all)
              openw, unit1, 'orbit.txt', /get_lun
              printf, unit1, orb_str
              free_lun, unit1
           Endif
        Endif
        If(is_string(file_search('process_orbit.lock'))) Then Begin
           message, /info, 'deleting process_orbit.lock'
           file_delete, 'process_orbit.lock'
        Endif
        Return
     Endif
  Endif
;Read in orbit, if available, then put in a five character string for filename
  If(is_string(file_search('orbit.txt'))) Then Begin
     orb_process = 1b
     openr, unit, 'orbit.txt', /get_lun
     orb_str = strarr(1)
     readf, unit, orb_str
     free_lun, unit
     orb_str = string(orb_str[0], format = '(i5.5)')
  Endif Else Begin
     orb_process = 0b
     message, /info, 'No orbit.txt file'
     orb_str = 'XXXXX'
  Endelse
  If(is_string(file_search('end_orbit.txt'))) Then Begin
     openr, unit3, 'end_orbit.txt', /get_lun
     end_orb_str = strarr(1)
     readf, unit3, end_orb_str
     free_lun, unit3
  Endif Else Begin
     message, /info, 'No end_orbit.txt file'
     end_orb = '51000'
  Endelse

;Don't process past the end_orbit
  If(long(orb_str) Gt long(end_orb_str[0])) Then Begin
     message, /info, 'End Orbit reached, No Process'
     Return
  Endif

;Set up datatype for survey, 4k burst, and 16k burst
  If(~is_string(datatype)) Then typ = 'esv' Else Begin
     Case datatype of
        'S':typ = 'esv'
        's':typ = 'esv'
        'esv':typ='esv'
        '4k':typ = 'e4k'
        '16k':typ = 'e16k'
        'e4k':typ = 'e4k'
        'e16k':typ = 'e16k'
        'esv_long':typ = 'esv_long'
        Else:typ = 'esv'
     Endcase
  Endelse

;Despin the SDT fields data
  If(typ Eq 'esv') Then Begin
     fa_fields_despin3
     get_data, 'fa_e_near_b', data = e
     If(~is_struct(e)) Then message, 'FA_FIELDS_DESPIN3 Failed:'
     potvar = get_fa_potential(/store)
     get_data, 's/c$potential', data = p
     If(~is_struct(p)) Then message, /info, 'GET_FA_POTENTIAL Failed:'
     copy_data, 's/c$potential', 'fa_sc_pot'
     potvar_spin = get_fa_potential(/store, /spin)
     get_data, 's/c$potential', data = p
     If(~is_struct(p)) Then message, /info, 'GET_FA_POTENTIAL Failed:'
     copy_data, 's/c$potential', 'fa_sc_pot_fit'
     to_be_stored = ['fa_e_near_b','fa_e_along_v', $
                     'fa_efit_near_b', 'fa_efit_along_v', $
                     'fa_sc_pot', 'fa_sc_pot_fit', 'fa_data_quality',$
                     'fa_e12','fa_e58','fa_bphase', 'fa_sphase', $
                     'fa_e0_s_gse', 'fa_e0_s_gsm', 'fa_e0_s_dsc', $
                     'fa_v1_v2_s', 'fa_v1_v4_s', 'fa_v5_v8_s', 'fa_v9_v10_s', $
;                     'fa_v1_s', 'fa_v5_s', 'fa_v3_s', $
                     'fa_v2_s', 'fa_v4_s', $
                     'fa_v6_s', 'fa_v7_s', 'fa_v8_s', 'fa_v9_s', $
                     'fa_v10_s', 'fa_dsc_gse', 'fa_dsc_gsm', $
                     'fa_spin_axis_gse', 'fa_spin_axis_gsm', $
                     'fa_probe_dist', 'fa_probe_phase', $
                     'fa_v12_dist', 'fa_v14_dist', 'fa_v58_dist', $
                     'fa_v910_dist']
;  endif Else IF(typ Eq 'esv_long') Then Begin
     ;need to add fa_
;     ff_despin_svy_long
;     get_data, 'E_NEAR_B', data = e
;     If(~is_struct(e)) Then message, 'FF_FIELDS_DESPIN_SVY_LONG Failed:'
;     copy_data, 'E_NEAR_B', 'E_NEAR_B_S'
;     copy_data, 'E_ALONG_V', 'E_ALONG_V_S'
;     to_be_stored = ['E_NEAR_B_S','E_ALONG_V_S','POT']
  Endif Else If(typ Eq 'e4k') Then Begin
     fa_fields_despin_4k
     to_be_stored = 'fa_'+['e_near_b_4k','e_along_v_4k']
     get_data, 'fa_e_near_b_4k', data = e
     if(~is_struct(e)) Then message, 'FA_FIELDS_DESPIN_4K Failed:'
  Endif Else If(typ Eq 'e16k') Then Begin
     fa_fields_despin_16k
     to_be_stored = 'fa_'+['e_near_b_16k','e_along_v_16k']
     get_data, 'fa_e_near_b_16k', data = e
     If(~is_struct(e)) Then message, 'FA_FIELDS_DESPIN_16K Failed:'
  Endif Else Begin
     message, /info, 'Bad TYP input'
  Endelse
;Datetime stuff for filename
  date = time_string(min(e.x), format=6)
  
;If required, handle database stuff
  If(keyword_set(full_database_management)) Then Begin
     message, /info, 'Full database management invoked.'
;create global attributes
     gen_date = time_string(systime(/sec), precision=-3)
     global_att = {Acknowledgment:'None', $
                   Data_type:'CAL>Calibrated', $
                   Data_version:'0', $
                   Descriptor:'FA_DESPUN_EFIELD>Fast Auroral SnapshoT Explorer, Despun Electric Field', $
                   Discipline:'Space Physics>Planetary Physics>Fields', $
                   File_naming_convention: 'descriptor_datatype_yyyyMMddHHmmss_orbno', $
                   Generated_by:'FAST SOC' , $
                   Generation_date:gen_date , $
                   HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                   Instrument_type:'Electric Fields (space)' , $
                   LINK_TEXT:'General Information about the FAST mission' , $
                   LINK_TITLE:'FAST home page' , $
                   Logical_file_id:'fa_despun_'+typ+'_l2_00000000000000_00000_v01.cdf' , $
                   Logical_source:'fa_despun_'+typ+'_l2_XXX' , $
                   Logical_source_description:'FAST Spacecraft-collected (EFI) Electric field', $
                   Mission_group:'FAST' , $
                   MODS:'Rev-0 2024-03-21' , $
                   PI_name:'R.E. Ergun', $
                   PI_affiliation:'LASP, C.U. Boulder', $
                   Planet:'Earth', $
                   Project:'FAST', $
                   Rules_of_use:'Open Data for Scientific Use' , $
                   Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                   TEXT:'EFI>Electric Field Instrument', $
                   Time_resolution:'0.001-4.0 s', $
                   Title:'FAST EFI Despun Electric Field'}
;output with orbit and time in filename
     filename = 'fa_despun_'+typ+'_l2_'+date+'_'+orb_str+'_v01'
     If(keyword_set(directory)) Then rdir = directory $
     Else rdir = '/disks/data/fast/l2/'
     orbit_dir = strmid(orb_str,0,2)+'000'
     fulldir = rdir+typ+'/'+orbit_dir+'/'
     If(~is_string(file_search(fulldir))) Then file_mkdir, fulldir
;Create variable attributes for each variable, and add CDF structure
;to limits array
     vatt_str = {CATDESC:'NA', $
                 DISPLAY_TYPE:'time_series', $
                 FIELDNAM:'NA', $
                 FORMAT:'E25.18', $
                 LABLAXIS:'NA', $;        STRING    'E NEAR B!C!C(mV/m)'
                 UNITS:'undefined', $
                 VAR_TYPE:'data', $
                 FILLVAL:!values.d_nan, $
                 VALIDMIN:-10000.0, $
                 VALIDMAX:10000.0, $
                 DEPEND_0:'Epoch'}
     print, tnames()
     tb = tnames(to_be_stored)
     print, tb
     nvar = n_elements(tb)
     For j = 0, nvar-1 Do Begin
        vattj = vatt_str
        vattj.fieldnam = tb[j]
        If(strmid(tb[j],0,4) Eq 'fa_e') Then Begin
           vattj.units = 'mV/m'
           vattj.lablaxis = tb[j]+' (mV/m)'           
        Endif Else If(strmid(tb[j],0,1) Eq 'e') Then Begin
           vattj.units = 'mV/m'
           vattj.lablaxis = tb[j]+' (mV/m)'
        Endif Else If(strmid(tb[j],0,4) Eq 'fa_v') Then Begin
           vattj.units = 'V'
           vattj.lablaxis = tb[j]+' (V)'
        Endif Else If(strmid(tb[j],0,5) Eq 'fa_sc') Then Begin
           vattj.units = 'V'
           vattj.lablaxis = tb[j]+' (V)'
        Endif Else If(tb[j] Eq 'fa_data_quality') Then Begin
           vattj.units = 'NA'
           vattj.lablaxis = tb[j]
        Endif Else If(tb[j] Eq 'fa_bphase' Or tb[j] Eq 'fa_sphase') Then Begin
           vattj.units = 'radians'
           vattj.lablaxis = tb[j]
           vattj.validmin = -10.0
           vattj.validmax = 10.0
        Endif Else If(tb[j] Eq 'fa_dsc_gse' Or tb[j] Eq 'fa_dsc_gsm') Then Begin
           vattj.units = 'NA'
           vattj.lablaxis = tb[j]
        Endif Else If(strpos(tb[j], 'dist') Ne -1) Then Begin
           vattj.units = 'm'
           vattj.lablaxis = tb[j]
           vattj.var_type = 'support_data'
           vattj.validmin = 0.0
           vattj.validmax = 100.0
        Endif Else If(tb[j] Eq 'fa_probe_phase') Then Begin
           vattj.units = 'radians'
           vattj.lablaxis = tb[j]
           vattj.var_type = 'support_data'
           vattj.validmin = -10.0
           vattj.validmax = 10.0
        Endif
           
        Case tb[j] Of
           'fa_e_near_b': vattj.catdesc = 'FAST Survey mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_e_along_v': vattj.catdesc = 'FAST Survey mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_sc_pot': vattj.catdesc = 'FAST Spacecraft Potential'
           'fa_sc_pot_fit': vattj.catdesc = 'FAST Spacecraft Potential, fit over spin'
           'fa_efit_near_b': vattj.catdesc = 'Survey mode Spin-fit electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_efit_along_v': vattj.catdesc = 'Survey mode Spin-fit electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_e_near_b_4k': vattj.catdesc = 'FAST 4k Burst mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_e_along_v_4k': vattj.catdesc = 'FAST 4k Burst mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_e_near_b_16k': vattj.catdesc = 'FAST 16k Burst mode electric field, in the direction corresponding to zero degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_e_along_v_16k': vattj.catdesc = 'FAST 16k Burst mode electric field, in the direction corresponding to ninety degrees magnetic phase, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_data_quality': vattj.catdesc = 'FAST EFI Quality flag, 0 = ok data, 1 = Magnetic shadow, 2 = sun shadow, 3 = both'
           'fa_e12': vattj.catdesc = 'FAST E12, probe 1-2 field, calibrated, not despun'
           'fa_e58': vattj.catdesc = 'FAST E58, probe 5-8 field, calibrated, not despun'
           'fa_e0_s_gse': vattj.catdesc = 'FAST Survey mode electric field, spin plane, in GSE coordinates'
           'fa_e0_s_gsm': vattj.catdesc = 'FAST Survey mode electric field, spin plane, in GSM coordinates'
           'fa_e0_s_dsc': vattj.catdesc = 'FAST Survey mode electric field, spin plane, in DSC (Despun spacecraft) coordinates'
           'fa_bphase': vattj.catdesc = 'FAST B field phase, used for despin'
           'fa_sphase': vattj.catdesc = 'FAST Sun phase, the projection of the sun on the spin plane, SPHASE = 0 corresponds to the X-axis of DSC coordinates'
           'fa_v1-v2_s': vattj.catdesc = 'FAST probe 1-2 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v1-v4_s': vattj.catdesc = 'FAST probe 1-4 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v5-v8_s': vattj.catdesc = 'FAST probe 5-8 Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v9-v10_s': vattj.catdesc = 'FAST probe 9-10 (Axial) Voltage difference, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
;           'fa_v1_s': vattj.catdesc = 'FAST probe 1 Voltage (Calculated from V1-V4_S, V4_S)'
           'fa_v2_s': vattj.catdesc = 'FAST probe 2 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
;           'fa_v3_s': vattj.catdesc = 'FAST probe 3 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v4_s': vattj.catdesc = 'FAST probe 4 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
;           'fa_v5_s': vattj.catdesc = 'FAST probe 5 Voltage (Calculated from V5-V8_S, V8_S)'
           'fa_v6_s': vattj.catdesc = 'FAST probe 6 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v7_s': vattj.catdesc = 'FAST probe 7 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v8_s': vattj.catdesc = 'FAST probe 8 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v9_s': vattj.catdesc = 'FAST probe 9 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_v10_s': vattj.catdesc = 'FAST probe 10 Voltage, direct SDT output, See:http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html'
           'fa_dsc_gse': vattj.catdesc = 'FAST DSC_GSE coordinate transformation matrix, 9 components in order a11,a12,a13,a21,a22,a23,a31,a32,a33'
           'fa_dsc_gsm': vattj.catdesc = 'FAST DSC_GSM coordinate transformation matrix, 9 components in order a11,a12,a13,a21,a22,a23,a31,a32,a33'
           'fa_spin_axis_gse': vattj.catdesc = 'FAST spin axis direction in GSE coordinates'
           'fa_spin_axis_gsm': vattj.catdesc = 'FAST spin axis direction in GSM coordinates'
           'fa_probe_dist': vattj.catdesc = 'FAST distance of each EFI probe from payload, values valid after variable time'
           'fa_probe_phase': vattj.catdesc = 'FAST angle between each EFI probe and spin X-axis in spin plane, spin plane DSC position = probe_dist*[cos(sphase+probe_phase), sin(sphase+probe_phase)]'
           'fa_v12_dist': vattj.catdesc = 'Fast distance between spin-plane probes 1 and 2 in meters, values valid after variable time'
           'fa_v14_dist': vattj.catdesc = 'Fast distance between spin-plane probes 1 and 4 in meters, values valid after variable time'
           'fa_v58_dist': vattj.catdesc = 'Fast distance between spin-plane probes 5 and 8 in meters, values valid after variable time'
           'fa_v910_dist': vattj.catdesc = 'Fast distance between axial probes 9 and 10 in meters, values valid after variable time'
           Else: print, 'MISSING: '+tb[j]
        End
;Create a CDF structure for the output, and put the vattj structure in
;the attrptr for the structure
        fa_tplot_add_cdf_structure, tb[j], /add_tname_to_epoch
        get_data, tb[j], alimit=al
        If(ptr_valid(al.cdf.vars.attrptr)) Then ptr_free, al.cdf.vars.attrptr
        al.cdf.vars.attrptr = ptr_new(vattj)
        store_data, tb[j], data = d, limits=al, dlimits=al
        print, 'PROCESSED: '+tb[j]
     Endfor
        
     fa_tplot2cdf, filename = fulldir+filename, tvars = tb, $
                   g_attributes = global_att, /compress_cdf, $
                   /add_tname_to_epoch
     If(orb_process) Then Begin
        message, /info, 'Incrementing orbit.txt'
        orbit = long(orb_str)
        orbit = orbit+1
        orb_str = strcompress(string(orbit), /remove_all)
        openw, unit2, 'orbit.txt', /get_lun
        printf, unit2, orb_str
        free_lun, unit2
     Endif
;If there is a lock file, delete it
     If(is_string(file_search('process_orbit.lock'))) Then Begin
        message, /info, 'deleting process_orbit.lock'
        file_delete, 'process_orbit.lock'
     Endif
  Endif Else Begin              ;output with nothing
     filename = 'fa_despun_'+typ+'_l2_'+date+'_'+orb_str+'_v03'
     tplot2cdf, filename = filename, tvars = to_be_stored, /default
  Endelse
End
