;+
; NAME:
;   MVN_SWE_MAKECDF_SPEC
; SYNTAX:
;   MVN_SWE_MAKECDF_SPEC, DATA, FILE = FILE, VERSION = VERSION
; PURPOSE:
;   Routine to produce CDF file from SWEA spec data structures.
;   This routine has been updated to produce Version 5 of the CDF files.
;   Version 5 is backward compatible with the version 4 reader.
;
; INPUT:
;   DATA: Structure with which to populate the CDF file
;         (nominally created by mvn_swe_getspec.pro)
; OUTPUT:
;   CDF file
; KEYWORDS:
;   FILE: full name of the output file - only used for testing
;         if not specified (usually won't be), the program creates the appropriate filename
;   VERSION: integer; software version
;          - read from common block (SWE_CFG) defined in mvn_swe_calib.pro
;          - keyword no longer need (but kept for compatibility)
; HISTORY:
;   created by Matt Fillingim (with code stolen from JH and RL)
;   Added directory keyword, and deletion of old files, jmm, 2014-11-14
;   Read version number from common block; MOF: 2015-01-30
;   ISTP compliance scrub; DLM: 2016-04-08
;   Code for data version 5; DLM: 2023-08
; VERSION:
;   $LastChangedBy: dmitchell $
;   $LastChangedDate: 2024-01-14 17:10:01 -0800 (Sun, 14 Jan 2024) $
;   $LastChangedRevision: 32362 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makecdf_spec.pro $
;
;-

pro mvn_swe_makecdf_spec, data, file = file, version = version, directory = directory

  @mvn_swe_com

  nrec = n_elements(data)

  if (nrec lt 2) then begin ; no data!
    print, 'No SPEC data!'
    print, 'CDF file not created.'
    return
  endif

; Identify data that do not use sweep table 3, 5 or 6.  Table 3
; is primary during cruise, and was superceded by table 5 during 
; transition on Oct. 6, 2014.  Table 6 is very similar to 5, 
; except that it enables V0.  Exclude invalid data from the CDF.

  indx = where(~mvn_swe_validlut(data.lut), count)
  if (count gt 0L) then begin
    data[indx].valid = 0B

    indx = where(data.valid, nrec)
    if (nrec eq 0L) then begin
      print, 'No valid SPEC data!'
      print, 'CDF file not created.'
      return
    endif
    data = temporary(data[indx])
  endif

; Get data type -- survey or archive

  CASE data[0].apid OF
    'A4'X: BEGIN
             tag = 'svy'
             title = 'MAVEN SWEA SPEC Survey'
           END
    'A5'X: BEGIN
             tag = 'arc'
             title = 'MAVEN SWEA SPEC Archive'
           END
    ELSE:  BEGIN
             PRINT, 'Invalid APID: ', data[0].apid
             tag = 'und'
             title = 'MAVEN SWEA SPEC Undefined'
             STOP ; kind of harsh
           END
  ENDCASE

; Get date (avoid any potential weird first-record-of-day timing)

  mid = nrec/2
  dum_str = time_string(data[mid].time) ; use midpoint of day

  yyyy = strmid(dum_str, 0, 4)
  mm = strmid(dum_str, 5, 2)
  dd = strmid(dum_str, 8, 2)
  yyyymmdd = yyyy + mm + dd

  if (not keyword_set(file)) then begin

; hardcoded data directory path
; Added directory keyword, for testing, jmm, 2014-11-14

    if (keyword_set(directory)) then path = directory[0] else $
      path = '/disks/data/maven/data/sci/swe/l2/' + yyyy + '/' + mm + '/'
    if (n_elements(file_search(path)) Eq 0) then file_mkdir2, path, mode = '0775'o

; Create file name using SIS convention

    file = 'mvn_swe_l2_' + tag + 'spec_' + yyyymmdd

; Read version number from common block (SWE_CFG) defined in mvn_swe_calib.pro

    if (not keyword_set(version)) then version = mvn_swe_version
    ver_str = string(version, format='(i2.2)')
    file = file + '_v' + ver_str

; Search for previously generated CDF files for this date.
; Check for latest reversion number, add one to it (delete/overwrite old version)   

  file_list = file_search(path + file + '*.cdf', count = nfiles) 
  if (nfiles gt 0) then begin    ; file for this day already exists
    latest = file_list[nfiles-1] ;  latest should be last in list
    old_rev_str = strmid(latest, 5, 2, /reverse_offset)
    revision = fix(old_rev_str) + 1
  endif else begin               ; file for this day does not yet exist
    revision = 1
  endelse

; Append version and revision to the file name
; file variable now contains full path, filename, and extension

    rev_str = string(revision, format='(i2.2)')

    head_file = file + '_r' + rev_str + '.cdf'
    temp_file = 'tmp_' + head_file
    file = path + head_file

  endif else begin ; if (not keyword_set(file))
    path = file_dirname(file) + '/'
    head_file = file_basename(file)
    temp_file = 'tmp_' + head_file
    ver_str = '00' ; needed in the header
    rev_str = '00' ; needed in the header
  endelse

  print, file

; Use a temporary filename to hide from the automated transfer bot while
; the file is being assembled.

  file = path + temp_file

; compute various times
; load leap seconds

  cdf_leap_second_init

; get date ranges (for CDF files)
;    Launch       2013-11-18 UT
;    Nominal EOM  2032-01-01 UT

  date_range = time_double(['2013-11-18','2033-01-01'])

; nominal conversion from UT to MET (note that MET is not zero at launch)

  met_range = date_range - time_double('2000-01-01/12:00') ; JH

  epoch_range = time_epoch(date_range)
  tt2000_range = long64((add_tt2000_offset(date_range) $
                 - time_double('2000-01-01/12:00'))*1e9)

; *** uses general/misc/time/time_epoch.pro ***
; time_epoch ==> return, 1000.d*(time_double(time) + 719528.d*24.d*3600.d)
; epoch is milliseconds from 0000-01-01/00:00:00.000 

  epoch = time_epoch(data.time) ; time is unix time in swea structures

; *** uses general/misc/time/TT2000/add_tt2000_offest.pro ***

  tt2000 = long64((add_tt2000_offset(data.time) $
           - time_double('2000-01-01/12:00'))*1e9)

  t_start_str = time_string(data[0].time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')
  t_end_str = time_string(data[nrec-1].end_time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')

; include SPICE kernels used
; spacecraft clock kernel

  i = where(strmatch(swe_kernels,'*sclk*',/fold), count)
  if (count gt 0) then driftname = file_basename(swe_kernels[i])

; leapseconds kernel

  j = where(strmatch(swe_kernels,'*.tls',/fold), count)
  if (count gt 0) then leapname = file_basename(swe_kernels[j])

; create and populate CDF file

  fileid = cdf_create(file, /single_file, /network_encoding, /clobber)

  varlist = ['epoch', 'time_tt2000', 'time_met', 'time_unix', $
             'num_accum', 'counts', 'diff_en_fluxes', 'weight_factor', $
             'geom_factor', 'g_engy', 'de_over_e', 'accum_time', 'energy', $
             'num_spec', 'en_label', 'quality', 'variance', 'secondary']

  id0  = cdf_attcreate(fileid, 'TITLE',                      /global_scope)
  id1  = cdf_attcreate(fileid, 'Project',                    /global_scope)
  id2  = cdf_attcreate(fileid, 'Discipline',                 /global_scope)
  id3  = cdf_attcreate(fileid, 'Source_name',                /global_scope)
  id4  = cdf_attcreate(fileid, 'Descriptor',                 /global_scope)
  id5  = cdf_attcreate(fileid, 'Data_type',                  /global_scope)
  id6  = cdf_attcreate(fileid, 'Data_version',               /global_scope)
  id7  = cdf_attcreate(fileid, 'TEXT',                       /global_scope)
  id8  = cdf_attcreate(fileid, 'MODS',                       /global_scope)
  id9  = cdf_attcreate(fileid, 'Logical_file_id',            /global_scope)
  id10 = cdf_attcreate(fileid, 'Logical_source',             /global_scope)
  id11 = cdf_attcreate(fileid, 'Logical_source_description', /global_scope)
  id12 = cdf_attcreate(fileid, 'PI_name',                    /global_scope)
  id13 = cdf_attcreate(fileid, 'PI_affiliation',             /global_scope)
  id14 = cdf_attcreate(fileid, 'Instrument_type',            /global_scope)
  id15 = cdf_attcreate(fileid, 'Mission_group',              /global_scope)
  id16 = cdf_attcreate(fileid, 'Parents',                    /global_scope)
  id17 = cdf_attcreate(fileid, 'Spacecraft_clock_kernel',    /global_scope)
  id18 = cdf_attcreate(fileid, 'Leapseconds_kernel',         /global_scope)
  id19 = cdf_attcreate(fileid, 'PDS_collection_id',          /global_scope)
  id20 = cdf_attcreate(fileid, 'PDS_start_time',             /global_scope)
  id21 = cdf_attcreate(fileid, 'PDS_stop_time',              /global_scope)
  id22 = cdf_attcreate(fileid, 'PDS_sclk_start_count',       /global_scope)
  id23 = cdf_attcreate(fileid, 'PDS_sclk_stop_count',        /global_scope)

  cdf_attput, fileid, 'TITLE',                      0, $
    title
  cdf_attput, fileid, 'Project',                    0, $
    'MAVEN'
  cdf_attput, fileid, 'Discipline',                 0, $
    'Planetary Physics>Planetary Plasma Interactions'
;   'Planetary Physics>Particles'
  cdf_attput, fileid, 'Source_name',                0, $
    'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
  cdf_attput, fileid, 'Descriptor',                 0, $
    'SWEA>Solar Wind Electron Analyzer'
  cdf_attput, fileid, 'Data_type',                  0, $
    'CAL>Calibrated'
  cdf_attput, fileid, 'Data_version',               0, $
    ver_str ; version
  cdf_attput, fileid, 'TEXT',                       0, $
    'MAVEN SWEA Energy Spectra'
  cdf_attput, fileid, 'MODS',                       0, $
    'Revision 0'
  cdf_attput, fileid, 'Logical_file_id',            0, $
    head_file
  cdf_attput, fileid, 'Logical_source',             0, $
    'swea.calibrated.' + tag + '_spec'
  cdf_attput, fileid, 'Logical_source_description', 0, $
    'DERIVED FROM: MAVEN SWEA (Solar Wind Electron Analyzer) Energy Spectra'
  cdf_attput, fileid, 'PI_name', 0, $
    'David L. Mitchell (mitchell@ssl.berkeley.edu)'
  cdf_attput, fileid, 'PI_affiliation',             0, $
    'UC Berkeley Space Sciences Laboratory'
  cdf_attput, fileid, 'Instrument_type',            0, $
    'Plasma and Solar Wind'
  cdf_attput, fileid, 'Mission_group',              0, $
    'MAVEN'
  cdf_attput, fileid, 'Parents',                    0, $
    'None'
  cdf_attput, fileid, 'Spacecraft_clock_kernel',    0, $
    driftname[0]
  cdf_attput, fileid, 'Leapseconds_kernel',         0, $
    leapname[0]
  cdf_attput, fileid, 'PDS_collection_id',          0, $
   'data.' + tag + '_spec'
;  'urn:nasa:pds:maven.swea.calibrated:data.' + tag + '_spec'
  cdf_attput, fileid, 'PDS_start_time',             0, $
    t_start_str
  cdf_attput, fileid, 'PDS_stop_time',              0, $
    t_end_str

;jmm, 2014-01-30, changed met to sclk count

  PDS_etime = time_ephemeris([data[0].time, data[nrec-1].end_time])
  cspice_sce2c, -202, PDS_etime[0], PDS_sclk0
  cspice_sce2c, -202, PDS_etime[1], PDS_sclk1
  cdf_attput, fileid, 'PDS_sclk_start_count',       0, $
    PDS_sclk0
  cdf_attput, fileid, 'PDS_sclk_stop_count',        0, $
    PDS_sclk1

  dummy = cdf_attcreate(fileid, 'FIELDNAM',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'MONOTON',      /variable_scope)
  dummy = cdf_attcreate(fileid, 'FORMAT',       /variable_scope)
  dummy = cdf_attcreate(fileid, 'FORM_PTR',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABLAXIS',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'LABL_PTR_1',   /variable_scope)
  dummy = cdf_attcreate(fileid, 'VAR_TYPE',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'FILLVAL',      /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_0',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DEPEND_1',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'DISPLAY_TYPE', /variable_scope)
  dummy = cdf_attcreate(fileid, 'VALIDMIN',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'VALIDMAX',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'SCALEMIN',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'SCALEMAX',     /variable_scope)
  dummy = cdf_attcreate(fileid, 'TIME_BASE',    /variable_scope)
  dummy = cdf_attcreate(fileid, 'UNITS',        /variable_scope)
  dummy = cdf_attcreate(fileid, 'CATDESC',      /variable_scope)

; for each item in varlist

; *** epoch *** (Actually time_tt2000)

  vndx = (where(varlist eq 'epoch'))[0]
  tndx = (where(varlist eq 'time_tt2000'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_TIME_TT2000, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[tndx],                /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I22',                        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[tndx],                /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',               /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, long64(-9223372036854775808), /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',                /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN',  varlist[vndx], tt2000_range[0], /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'VALIDMAX',  varlist[vndx], tt2000_range[1], /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'SCALEMIN',  varlist[vndx], tt2000[0],       /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'SCALEMAX',  varlist[vndx], tt2000[nrec-1],  /ZVARIABLE, /CDF_EPOCH
  cdf_attput, fileid, 'TIME_BASE', varlist[vndx], 'J2000',         /ZVARIABLE
  cdf_attput, fileid, 'UNITS',     varlist[vndx], 'ns',            /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',   varlist[vndx], 'INCREASE',      /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',   varlist[vndx], $
    'Time, center of sample, in TT2000 time base', /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], tt2000

; *** MET ***

  vndx = (where(varlist eq 'time_met'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], met_range[0],     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], met_range[1],     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], data[0].met,      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], data[nrec-1].met, /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 's',              /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',  varlist[vndx], 'INCREASE',       /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Time, center of sample, in raw mission elapsed time',         /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch' ,         /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data.met

; *** time_unix ***

  vndx = (where(varlist eq 'time_unix'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], date_range[0],     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], date_range[1],     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], data[0].time,      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], data[nrec-1].time, /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 's',               /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',  varlist[vndx], 'INCREASE',        /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Time, center of sample, in Unix time',                         /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',           /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data.time

; *** num_accum ***

  vndx = (where(varlist eq 'num_accum'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_INT2, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],   /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I7',            /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],   /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',  /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, fix(-32768),     /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',   /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 1,            /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 100,          /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 1,            /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 10,           /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Number of two-second accumulations per energy spectrum',  /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',      /ZVARIABLE

  num_accum = lonarr(nrec)

; check smode - sum mode
; number of data points equals number of a4*16 (16 spectra per a4)

  for i = 0l, nrec-1 do $
    if (a4[i/16].smode EQ 0) then num_accum[i] = 1 $
    else num_accum[i] = 2^a4[i/16].period

  cdf_varput, fileid, varlist[vndx], fix(num_accum)

; *** counts ***

  dim_vary = [1]
  dim = [64]  
  vndx = (where(varlist eq 'counts'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.1',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,                      /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.e10,                   /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,                      /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.e6,                    /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 'counts',                /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Raw Instrument Counts', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',                 /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1', varlist[vndx], 'energy',                /ZVARIABLE

; Convert to units of raw counts

  mvn_swe_convert_units, data, 'counts'

; Extract geometric factor; look for changes with time that are caused
; by MCP bias adjustments (these are rare).  When this happens, scale 
; the raw counts to compensate for the change in geometric factor, 
; because there can be only one geometric factor per UT day.

  gf_i = data.gf[0]
  geom_factor = median([gf_i])  ; most common value
  scale = geom_factor/gf_i      ; unity except on days when MCP bias is adjusted
  scale = replicate(1.,64) # scale

  cdf_varput, fileid, varlist[vndx], data.data * scale

; *** diff_en_fluxes -- Differential energy fluxes ***

  dim_vary = [1]
  dim = [64]  
  vndx = (where(varlist eq 'diff_en_fluxes'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, $
    /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'E15.7',       /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'data',        /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,        /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series', /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.e14,     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.e11,     /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], $
    'eV/[eV cm^2 sr s]',                                    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varlist[vndx], 'data',    /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Calibrated differential energy flux',                  /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0',   varlist[vndx], 'epoch',    /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1',   varlist[vndx], 'energy',   /ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_1', varlist[vndx], 'en_label', /ZVARIABLE

; convert to units of energy flux

  mvn_swe_convert_units, data, 'eflux'
  cdf_varput, fileid, varlist[vndx], data.data

; *** variance -- in units of (differential energy flux)^2 ***
;   Note: I'm including this since it's not at all obvious how to account
;         for digitization noise starting from raw counts.  It is assumed
;         that the user will know that data and sqrt(variance) should have
;         the same units.

  dim_vary = [1]
  dim = [64]  
  vndx = (where(varlist eq 'variance'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, $
    /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'E15.7',       /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'data',        /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,        /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series', /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.e14,     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.e11,     /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], $
    '(eV/[eV cm^2 sr s])^2',                                /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varlist[vndx], 'data',    /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Variance of differential energy flux',                    /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0',   varlist[vndx], 'epoch',    /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1',   varlist[vndx], 'energy',   /ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_1', varlist[vndx], 'en_label', /ZVARIABLE

; units are (energy flux)^2 from the previous variable

  cdf_varput, fileid, varlist[vndx], data.var

; *** secondary electrons -- in units of differential energy flux ***

  dim_vary = [1]
  dim = [64]  
  vndx = (where(varlist eq 'secondary'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_VARY, $
    /ZVARIABLE) 

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'E15.7',       /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'data',        /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,        /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series', /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.e14,     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,        /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.e11,     /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], $
    'eV/[eV cm^2 sr s]',                                    /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varlist[vndx], 'data',    /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Secondary electron contamination',                        /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0',   varlist[vndx], 'epoch',    /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_1',   varlist[vndx], 'energy',   /ZVARIABLE
  cdf_attput, fileid, 'LABL_PTR_1', varlist[vndx], 'en_label', /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data.bkg  ; units are energy flux

; *** weight_factor -- Weighting factor ***

  vndx = (where(varlist eq 'weight_factor'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,         /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.,         /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,         /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.,         /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Weighting factor for converting raw counts to raw count rate', /ZVARIABLE

  weight_factor = total(swe_hsk[0].dsf)/6.
  cdf_varput, fileid, varlist[vndx], weight_factor

; *** geom_factor -- Geometric factor ***

  vndx = (where(varlist eq 'geom_factor'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,              /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.,              /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,              /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 1.e-2,           /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 'cm^2 sr eV/eV', /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Full sensor geometric factor (per anode) at 1.4 keV',        /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], geom_factor

; *** g_engy -- Relative sensitivity as a function of energy ***

  dim_vary = [1]
  dim = 64
  vndx = (where(varlist eq 'g_engy'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,        /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 2.0,        /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.0,        /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 0.2,        /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Relative sensitivity as a function of energy',          /ZVARIABLE

  g_engy = data[mid].eff*data[mid].gf/geom_factor ; [64]
  cdf_varput, fileid, varlist[vndx], g_engy

; *** de_over_e -- DE/E ***

  dim_vary = [1]
  dim = 64
  vndx = (where(varlist eq 'de_over_e'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,               /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,               /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.0,               /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 0.3,               /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 'eV/eV',           /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'DeltaE/E (FWHM)', /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data[mid].denergy/data[mid].energy ; [64]

; *** accum_time -- Accumulation Time ***

  vndx = (where(varlist eq 'accum_time'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.0,                 /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 1.0,                 /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.0,                 /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 0.1,                 /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 's',                 /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Accumulation Time', /ZVARIABLE

; should be 96*4*1.09 ms -- data.integ_t is 4*1.09 ms

  cdf_varput, fileid, varlist[vndx], 96.*data[mid].integ_t

; *** energy ***

  dim_vary = [1]
  dim = 64
  vndx = (where(varlist eq 'energy'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_FLOAT, dim_vary, DIM = dim, /REC_NOVARY, $
    /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],  /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0.,         /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 5.e4,       /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0.,         /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 5.e3,       /ZVARIABLE
  cdf_attput, fileid, 'UNITS',    varlist[vndx], 'eV',       /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], 'Energies', /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data[mid].energy ; [64]

; *** quality flag ***

  vndx = (where(varlist eq 'quality'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_UINT1, /REC_VARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],   /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I1',            /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],   /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',  /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, 255B,            /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',   /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0B,               /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 2B,               /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0,                /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 3,                /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
    'Quality flag: 0 = low-energy anomaly, 1 = unknown, 2 = good', /ZVARIABLE
  cdf_attput, fileid, 'DEPEND_0', varlist[vndx], 'epoch',          /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], data.quality

; *** Energy Label

  dim_vary = [1]
  dim = 64

  vndx = (where(varlist eq 'en_label'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)

  cdf_attput, fileid, 'FIELDNAM', varid, varlist[vndx], /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',   varid, 'A3',          /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE', varid, 'metadata',    /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',  varid, " ",           /ZVARIABLE
  cdf_attput, fileid, 'CATDESC', 'en_label', 'Energy Axis Label for CDF compatibility', /ZVARIABLE

  labs = 'E' + strcompress(string(indgen(64)),/rem)
  len = strlen(labs)
  w = where(len lt 3)
  if (w[0] ne -1) then labs(w) = ' ' + labs(w)

  cdf_varput, fileid, varlist[vndx], labs

; *** num_spec -- Number of Spectra ***

  vndx = (where(varlist eq 'num_spec'))[0]
  varid = cdf_varcreate(fileid, varlist[vndx], /CDF_INT4, /REC_NOVARY, /ZVARIABLE)

  cdf_attput, fileid, 'FIELDNAM',     varid, varlist[vndx],     /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid, 'I12',             /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid, varlist[vndx],     /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',    /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid, long(-2147483648), /ZVARIABLE
  cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',     /ZVARIABLE

  cdf_attput, fileid, 'VALIDMIN', varlist[vndx], 0L,     /ZVARIABLE
  cdf_attput, fileid, 'VALIDMAX', varlist[vndx], 43200L, /ZVARIABLE
  cdf_attput, fileid, 'SCALEMIN', varlist[vndx], 0L,     /ZVARIABLE
  cdf_attput, fileid, 'SCALEMAX', varlist[vndx], 43200L, /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',  varlist[vndx], $
  'Number of energy spectra in file',                    /ZVARIABLE

  cdf_varput, fileid, varlist[vndx], nrec

  cdf_close,fileid

; Rename the file to the original

  tofile = path + head_file
  cmd = 'mv ' + file + ' ' + tofile
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error renaming file: "
    print, "  ", cmd
    print, "  ", err
    return
  endif
  file = tofile

; compression, md5, and permissions (rw--rw--r--)

  mvn_l2file_compress, file

; Try to make sure maven has group ownership
; (only works for the file's owner)

  file_chgrp, file, 'maven'
  file_chgrp, file_dirname(file) + '/' + file_basename(file,'.cdf') + '.md5', 'maven'

;Delete old files, jmm, 2014-11-14, include md5's, jmm, 2014-11-25

  if (nfiles Gt 0) then begin
    for j = 0, nfiles-1 do begin
      file_delete, file_list[j]
      md5j = file_dirname(file_list[j])+'/'+$
             file_basename(file_list[j], '.cdf')+'.md5'
      if(keyword_set(file_search(md5j))) then file_delete, md5j
    endfor
  endif

  return

end
