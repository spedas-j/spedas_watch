;+
; PROCEDURE:
;         elf_load_state
;
; PURPOSE:
;         Load the ELFIN ephemeris and attitude data 
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for elf probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         datatype:     valid datatypes include ['pos', 'vel']
;                       Note: attitude data will be added soon [spinras, spindec, spinper, ..]. 
;         level:        there is only one level for state - 'l1'
;         data_rate:    instrument data rates are not applicable for state data
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\elf\)
;         source:       specifies a different system variable. By default the elf mission system
;                       variable is !elf
;         get_support_data: load support data (defined by support_data attribute in the CDF)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're
;                       using this load routine from a terminal without an X server running
;         time_clip:    clip the data to the requested time range; note that if you do not use
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer data is
;                       found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
;         cdf_version:  specify a specific CDF version # to load (e.g., cdf_version='4.3.0')
;         latest_version: only grab the latest CDF version in the requested time interval
;                       (e.g., /latest_version)
;         major_version: only open the latest major CDF version (e.g., X in vX.Y.Z) in the requested time interval
;         min_version:  specify a minimum CDF version # to load
;         cdf_records:  specify a number of records to load from the CDF files.
;                       e.g., cdf_records=1 only loads in the first data point in the file
;                       This is especially useful for loading S/C position for a single time
;         spdf:         grab the data from the SPDF instead of the LASP SDC (only works for public access)
;         available:    returns a list of files available at the SDC for the requested parameters
;                       this is useful for finding which files would be downloaded (along with their sizes) if
;                       you didn't specify this keyword (also outputs total download size)
;         versions:     this keyword returns the version #s of the CDF files used when loading the data
;         always_prompt: set this keyword to always prompt for the user's username and password;
;                       useful if you accidently save an incorrect password, or if your SDC password has changed
;         tt2000: flag for preserving TT2000 timestamps found in CDF files (note that many routines in
;                       SPEDAS (e.g., tplot.pro) do not currently support these timestamps)
;         pred: set this flag to retrieve predicted data. default is definitive.  
;
; EXAMPLES:
;         to load/plot the S/C position data for probe a on 2/20/2016:
;         elf> elf_load_state, probe='a', trange=['2016-02-20', '2016-02-21']
;         elf> tplot, 'ela_pos_gsm'
;
; NOTES:
;    Will need to add attitude data - so far this only handles position and velocity
;   
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_state.pro $
;-

pro elf_load_state, trange = trange, probes = probes, datatype = datatype, $
  level = level, data_rate = data_rate, pred = pred, $
  local_data_dir = local_data_dir, source = source, $
  get_support_data = get_support_data, $
  tplotnames = tplotnames, no_color_setup = no_color_setup, $
  time_clip = time_clip, no_update = no_update, suffix = suffix, $
  varformat = varformat, cdf_filenames = cdf_filenames, $
  cdf_version = cdf_version, latest_version = latest_version, $
  min_version = min_version, cdf_records = cdf_records, $
  spdf = spdf, available = available, versions = versions, $
  always_prompt = always_prompt, major_version=major_version, tt2000=tt2000

  if undefined(probes) then probes = ['a'] ; default to ela
  if probes EQ ['*'] then probes = ['a', 'b']
  if n_elements(probes) GT 2 then begin
    dprint, dlevel = 1, 'There are only 2 ELFIN probes - a and b. Please select again.'
    return
  endif
  ; check for valid probe names
  probes = strlowcase(probes)
  idx = where(probes EQ 'a', acnt)
  idx = where(probes EQ 'b', bcnt)
  if acnt EQ 0 && bcnt EQ 0 then begin
    dprint, dlevel = 1, 'Invalid probe name. Valid probes are a and/or b. Please select again.'
    return    
  endif

;  TODO: may want to add check of var types
  if undefined(datatype) then datatype = ['pos_gei', 'vel_gei']
  idx=where(datatype EQ 'pos', ncnt)
  if ncnt GT 0 then datatype[idx]='pos_gei'
  idx=where(datatype EQ 'vel', ncnt)
  if ncnt GT 0 then datatype[idx]='pos_vel'
   
  ;clear so new names are not appended to existing array
  undefine, tplotnames
  ; clear CDF filenames, so we're not appending to an existing array
  undefine, cdf_filenames

  if undefined(level) then level = 'l1' else level=strlowcase(level)
  if level NE 'l1' then begin
    dprint, dlevel = 1, 'State data does not have level = ' + level
    dprint, dlevel = 1, 'Defaulting to l1.'
    level = 'l1'
  endif
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = ''
 
  if ~keyword_set(pred) then begin
    elf_load_data, trange = trange, probes = probes, level = level, instrument = 'state', $
      data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
      datatype = datatype, get_support_data = get_support_data, pred = pred, $
      tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
      no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
      cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
      cdf_records = cdf_records, spdf = spdf, available = available, versions = versions, $
      always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
  endif
  
  ; check that data was loaded, if not and the keyword_set pred was not set then 
  ; try predicted data  
  if keyword_set(pred) || undefined(tplotnames) || tplotnames[0] eq '' then begin
     dprint, dlevel = 1, 'Downloading predicted state data. '
     elf_load_data, trange = trange, probes = probes, level = level, instrument = 'state', $
      data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
      datatype = datatype, get_support_data = get_support_data, pred = 1, $
      tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
      no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
      cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
      cdf_records = cdf_records, spdf = spdf, available = available, versions = versions, $
      always_prompt = always_prompt, major_version=major_version, tt2000=tt2000
  endif

  ; no reason to continue if no data were loaded
  if undefined(tplotnames) || tplotnames[0] EQ '' then begin
    dprint, dlevel = 1, 'No data was loaded.'
    return
  endif
  
  for probe_idx = 0, n_elements(probes)-1 do begin
    elf_state_fix_metadata, probes[probe_idx]
  endfor

end