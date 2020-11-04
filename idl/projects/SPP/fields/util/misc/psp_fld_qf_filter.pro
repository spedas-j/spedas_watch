;+
;NAME: PSP_FLD_QF_FILTER
;
;DESCRIPTION:
; Removed flagged values from PSP FIELDS magnetometer tplot variables based 
; on selected quality flags.  See usage notes and available flag definitions 
; by calling with the /HELP keyword.
;
; For each TVAR passed in a new tplot variable is created with the filtered 
; data.  The new name is of the form:  <tvarname>_XXXXXX 
; where each 'XXX' is a 0 padded flag indicator sorted from lowest to highest.
; 
; So, psp_fld_qf_filter,'mag_RTN_1min_x',[4,16] results in tvar named "mag_RTN_1min_x_004016"
; Or, psp_fld_qf_filter,'mag_RTN_1min',0 results in tvar named "mag_RTN_1min_000"
; 
; Valid for 'psp_fld_l2_mag...' prefixed variables only.
;  
;INPUT:
; TVARS:    (string/strarr) Elements are data handle names
;             OR (int/intarr) tplot variable reference numbers
; DQFLAG:   (int/intarr) Elements indicate which of the data quality flags
;             to filter on. From the set {0,1,2,4,8,16,32,64,128}   
;             Note: if using 0 or -1, no other flags should be selected for filter
;             -1: Keep cases with no set flags or only the 128 flag set 
;             0: No set flags. (default)
;             1: FIELDS antenna bias sweep
;             2: PSP thruster firing
;             4: SCM Calibration
;             8: PSP rotations for MAG calibration (MAG rolls)
;             16: FIELDS MAG calibration sequence
;             32: SWEAP SPC in electron mode
;             64: PSP Solar limb sensor (SLS) test
;             128: PSP spacecraft is off umbra pointing     
;
;KEYWORDS:
; HELP:   If set, print a listing of the available data quality flags and 
;         their meaning.
; VERBOSE:     Integer indicating the desired verbosity level. Default = 2
; 
;OUTPUTS:
; NAMES_OUT:  Named variable holding the tplot variable names created 
;             from this filter. Order corresponds to the input array of tvar
;             names, so that tvar[i] filtered is in names_out[i]
;
;EXAMPLE:
;
;
;CREATED BY: Ayris Narock, Jonathan Tsang (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-11-03 08:57:10 -0800 (Tue, 03 Nov 2020) $
; $LastChangedRevision: 29319 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/misc/psp_fld_qf_filter.pro $
;-

pro psp_fld_qf_filter, tvars, dqflag,HELP=help, NAMES_OUT=names_out, $
                        verbose=verbose
                       
  compile_opt idl2
  
  ; Handle HELP option
  @psp_fld_common
  if keyword_set(help) then begin
    print,mag_dqf_infostring,format='(A)'
    return
  endif
  
  if ~isa(verbose, 'INT') then verbose = 2
   
  names_out = []
  
  ; Argument checking
  if isa(dqflag, 'UNDEFINED') then dqflag = 0 else $
  if ~isa(dqflag, /INT) then begin
    dprint, dlevel=1, verbose=verbose, "DQFLAG must be INT or INT ARRAY"
    return
  endif

  foreach flg,dqflag do begin
    r = where([0,1,2,4,8,16,32,64,128,-1] eq flg, count)
    if count eq 0 then begin
      msg = ["Bad DQFLAG value ("+flg.ToString()+").", $
            "Must be in the set{0,1,2,4,8,16,32,64,128,-1}"]
      dprint, dlevel=1, verbose=verbose, msg, format='(A)'
      return
    endif
  endforeach

  ; Retrieve DQF array and flagged bits      
  ; 
  ;FIELDS quality flags. This is a bitwise variable, meaning that multiple flags
  ;can be set for a single time, by adding flag values. Current flagged values
  ;are: 1: FIELDS antenna bias sweep, 2: PSP thruster firing,
  ;4: SCM Calibration, 8: PSP rotations for MAG calibration (MAG rolls),
  ;16: FIELDS MAG calibration sequence, 32: SWEAP SPC in electron mode,
  ;64: PSP Solar limb sensor (SLS) test. 128: PSP spacecraft is off umbra
  ;pointing. A value of zero corresponds to no set flags.
  ;Not all flags are relevant to all FIELDS data products, refer to notes in the
  ;CDF metadata and on the FIELDS SOC website for information on how the various
  ;flags impact FIELDS data. Additional flagged items may be added in the future. 
  
  ; First, know which resolution quality flag to reference
  ; 1=hires, 2=1min, 3=4 Sa per Cyc
  res = []
  foreach tname,tvars do begin
    tn = tnames(tname)
    if tn.Matches('_4_Sa_per_Cyc') then res = [res, 3] $
    else if tn.Matches('_1min') then res = [res, 2] $
    else if tn.Matches('(mag_RTN|mag_SC)$') then res = [res, 1] $
    else message,'Bad variable passed: '+tn
  endforeach
  r = where(res eq 1, count1)
  r = where(res eq 2, count2)
  r = where(res eq 3, count3)
  
  ; Get bits array for all needed time resolutions
  if count1 gt 0 then begin
    get_data,'psp_fld_l2_quality_flags_hires',data=d
    dqf1 = d.y
    n1 = n_elements(d.x)
    bits2, dqf1, dqfbits1
  endif
  if count2 gt 0 then begin
    get_data,'psp_fld_l2_quality_flags_1min',data=d
    dqf2 = d.y
    n2 = n_elements(d.x)
    bits2, dqf2, dqfbits2
  endif
  if count3 gt 0 then begin
    get_data,'psp_fld_l2_quality_flags_4_per_cycle',data=d
    dqf3 = d.y
    n3 = n_elements(d.x)
    bits2, dqf3, dqfbits3
  endif  
  
  ; Handle -1 case (0 and 128) and return
  if isa(dqflag, /SCALAR) && (dqflag eq -1) then begin
    suffix = '_0-1'
    for i=0,n_elements(tvars)-1 do begin
      case (res[i]) of
        1: begin
          dqfbits = dqfbits1
          dqf = dqf1
        end
        2: begin
          dqfbits = dqfbits2
          dqf = dqf2       
        end
        3: begin
          dqfbits = dqfbits3
          dqf = dqf3  
        end
      endcase
      rgood = where((dqf eq 0) OR (dqf eq 128), /NULL, COMPLEMENT=r) 
      get_data,tvars[i],data=d, dl=dl
      d.y[r,*] = !values.f_NAN
      if tag_exist(dl, 'ytitle',/quiet) then begin
        dl.ytitle = dl.ytitle +"!Cfilter"+suffix
      endif
      if tag_exist(l, 'ytitle',/quiet) then begin
        l.ytitle = l.ytitle +"!Cfilter"+suffix
      endif      
      store_data,tnames(tvars[i])+suffix,data=d,dl=dl
      names_out = [names_out, tnames(tvars[i])+suffix]      
    endfor  
    return
  endif else if isa(dqflag, /ARRAY) then begin
    r = where(dqflag eq -1, count)
    if count gt 0 then begin
      dprint, dlevel=1, verbose=verbose, "DQFLAG of -1 must be set by itself"
      return
    endif
  endif
  
  
  ;handle case 0 and return
  if isa(dqflag, /SCALAR) && (dqflag eq 0) then begin
    suffix = '_000'
    for i=0,n_elements(tvars)-1 do begin
      case (res[i]) of
        1: begin
          dqfbits = dqfbits1
          dqf = dqf1
        end
        2: begin
          dqfbits = dqfbits2
          dqf = dqf2
        end
        3: begin
          dqfbits = dqfbits3
          dqf = dqf3
        end
      endcase
      rgood = where((dqf eq 0) , /NULL, COMPLEMENT=r)
      get_data,tvars[i],data=d, dl=dl, lim=l
      d.y[r,*] = !values.f_NAN
      if tag_exist(dl, 'ytitle',/quiet) then begin
        dl.ytitle = dl.ytitle +"!Cfilter"+suffix
      endif
      if tag_exist(l, 'ytitle',/quiet) then begin
        l.ytitle = l.ytitle +"!Cfilter"+suffix
      endif
      store_data,tnames(tvars[i])+suffix,data=d,dl=dl, lim=l
      names_out = [names_out, tnames(tvars[i])+suffix]
    endfor
    return
  endif else if isa(dqflag, /ARRAY) then begin
    r = where(dqflag eq 0, count)
    if count gt 0 then begin
      dprint, dlevel=1, verbose=verbose, "DQFLAG of 0 must be set by itself"
      return
    endif
  endif
  
  
  ; If not asking for 0 or -1, Find index of elements to remove based on DQFLAGS
  bits2,0,mybits
  foreach flg,dqflag do begin
    bits2,flg,flgbits
    mybits = mybits + flgbits
  endforeach

  if count1 gt 0 then begin
    rem_mask1 = replicate(0, n1)
    for i=0,n_elements(mybits)-1 do begin
      if mybits[i] eq 1 then begin
        r = where(dqfbits1[i,*] eq 1, /NULL)
        rem_mask1[r] = 1
      endif
    endfor
    rem_idx1 = where(rem_mask1 eq 1, /NULL)    
  endif
  if count2 gt 0 then begin
    rem_mask2 = replicate(0, n2)
    for i=0,n_elements(mybits)-1 do begin
      if mybits[i] eq 1 then begin
        r = where(dqfbits2[i,*] eq 1, /NULL)
        rem_mask2[r] = 1
      endif
    endfor
    rem_idx2 = where(rem_mask2 eq 1, /NULL)    
  endif
  if count3 gt 0 then begin
    rem_mask3 = replicate(0, n3)
    for i=0,n_elements(mybits)-1 do begin
      if mybits[i] eq 1 then begin
        r = where(dqfbits3[i,*] eq 1, /NULL)
        rem_mask3[r] = 1
      endif
    endfor
    rem_idx3 = where(rem_mask3 eq 1, /NULL)    
  endif
    
  ; Remove data from tplot vars and store in "meaningful" tplot names
  suffix = '_'
  foreach flg,dqflag do suffix+= flg.ToString('(I03)')
  for i=0,n_elements(tvars)-1 do begin
    case (res[i]) of
      1: rem_idx = rem_idx1
      2: rem_idx = rem_idx2
      3: rem_idx = rem_idx3
    endcase
    get_data,tvars[i],data=d, dl=dl
    d.y[rem_idx,*] = !values.f_NAN
    if tag_exist(dl, 'ytitle',/quiet) then begin
      dl.ytitle = dl.ytitle +"!Cfilter"+suffix
    endif
    if tag_exist(l, 'ytitle',/quiet) then begin
      l.ytitle = l.ytitle +"!Cfilter"+suffix
    endif    
    store_data,tnames(tvars[i])+suffix,data=d,dl=dl
    names_out = [names_out, tnames(tvars[i])+suffix]
  endfor  
end
