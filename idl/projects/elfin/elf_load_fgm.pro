;+
; PROCEDURE:
;         elf_load_FGM
;
; PURPOSE:
;         Load the ELFIN FGM
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for elf probes are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         datatype:     valid datatypes include level 1 - ['fgf', 'fgs'] and 
;                       level 2 -['fgf_dsl','fgf_gei','fgf_mag','fgs_dsl','fgs_gei','fgs_mag']
;         data_rate:    instrument data rates include ['srvy', 'fast']. The default is 'srvy'.
;         level:        indicates level of data processing. levels include 'l1' and 'l2'
;                       The default if no level is specified is 'l1' (l1 default needs to be confirmed)
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\elfin\)
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
;
; EXAMPLES:
;         to load/plot the FGM magnetometer data for probe a on 2/20/2019:
;         elf> elf_load_fgm, probe='a', trange=['2016-02-20', '2016-02-21'], level='l1'
;         elf> tplot, 'ela_fgs'
;
; NOTES:
;
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_fgm.pro $
;-

pro elf_load_fgm, trange = trange, probes = probes, datatype = datatype, $
  level = level, data_rate = data_rate, $
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
  if undefined(level) then level = 'l1'
  if undefined(datatype) AND level eq 'l1' then datatype = ['fgs']
  if undefined(datatype) AND level eq 'l2' then datatype = ['fgs_gei']
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = ''

  elf_load_data, trange = trange, probes = probes, level = level, instrument = 'fgm', $
    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
    datatype = datatype, get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
    no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
    cdf_version = cdf_version, latest_version = latest_version, min_version = min_version, $
    cdf_records = cdf_records, spdf = spdf, available = available, versions = versions, $
    always_prompt = always_prompt, major_version=major_version, tt2000=tt2000

  ; no reason to continue if the user only requested available data
  if keyword_set(available) then return

  ; no reason to continue if no data were loaded
  if undefined(tplotnames) then return

end