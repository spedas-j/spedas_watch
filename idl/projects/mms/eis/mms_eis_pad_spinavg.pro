;+
; PROCEDURE:
;         mms_eis_pad_spinavg
;
; PURPOSE:
;         Calculates spin-averaged PADs for the EIS instrument
;
; KEYWORDS:
;         probe:        Probe # to calculate the spin averaged PAD for
;                       if no probe is specified the default is probe '1'
;         datatype:     eis data types include ['electronenergy', 'extof', 'partenergy', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts'].
;                       The default is 'flux'.
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      species (should be: proton, oxygen, alpha or electron)
;         scopes:       string array of telescopes to be included in PAD ('0'-'5')
;
; OUTPUT:
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-10 15:07:50 -0800 (Wed, 10 Feb 2016) $
;$LastChangedRevision: 19941 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_pad_spinavg.pro $
;
; REVISION HISTORY:
;       + 2016-01-26, I. Cohen      : added scopes keyword and scope_suffix definition to allow for distinction between single telescope PADs (reflects change in mms_eis_pad.pro)
;                                   
;-

pro mms_eis_pad_spinavg, probe=probe, species = species, data_units = data_units, $
  datatype = datatype, energy = energy, bin_size = bin_size, data_rate = data_rate, $
  suffix = suffix, scopes = scopes
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  if undefined(species) then species = 'proton'
  if undefined(suffix) then suffix = ''
  if undefined(energy) then energy = [0, 1000]
  if undefined(bin_size) then bin_size = 15
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(scopes) then scopes = ['0','1','2','3','4','5']

  en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
  units_label = data_units eq 'cps' ? 'Counts/s': '#/(cm!U2!N-sr-s-keV)'

  if (data_rate eq 'brst') then prefix = 'mms'+probe+'_epd_eis_brst_'+datatype+'_' else prefix = 'mms'+probe+'_epd_eis_'+datatype+'_'
  if (n_elements(scopes) eq 1) then scope_suffix = '_t'+scopes else if (n_elements(scopes) eq 6) then scope_suffix = '_omni'
  ; get the spin #s asscoiated with each measurement
  get_data, prefix + 'spin', data=spin_nums

  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)
  pad_name = prefix + en_range_string + '_' + species + '_' + data_units + scope_suffix + '_pad'

  get_data, pad_name, data=pad_data, dlimits=pad_dl

  if ~is_struct(pad_data) then begin
    ;stop
    dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
    return
  endif

  spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.Y[0, *]))
  spin_times = dblarr(n_elements(spin_starts))

  current_start = 0
  ; loop through the spins for this telescope
  for spin_idx = 0, n_elements(spin_starts)-1 do begin
    ; loop over energies
    ; spin_sum_flux[spin_idx, *] = total(pad_data.Y[current_start:spin_starts[spin_idx], *], 1)
    spin_sum_flux[spin_idx, *] = average(pad_data.Y[current_start:spin_starts[spin_idx], *], 1, /nan)
    spin_times[spin_idx] = pad_data.X[current_start]
    current_start = spin_starts[spin_idx]+1
  endfor

  suffix = suffix + '_spin'
  newname = prefix+en_range_string+'_'+species+'_'+data_units+scope_suffix+'_pad'+suffix

  ; rebin the data before storing it
  ; the idea here is, for bin_size = 15 deg, rebin the data from center points to:
  ;    new_bins = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135 , 150, 165, 180]

  n_pabins = 180./bin_size
  new_bins = 180.*indgen(n_pabins+1)/n_pabins

  rebinned_data = congrid(spin_sum_flux, n_elements(spin_starts), n_elements(new_bins), /center, /interp)

  store_data, newname, data={x: spin_times, y: rebinned_data, v: new_bins}, dlimits=flux_dl
  options, newname, spec=1, ystyle=1, ztitle=units_label, ytitle='MMS'+probe+' EIS '+species, ysubtitle=en_range_string+'!CPAD (deg)', minzlog=.01
  zlim, newname, 0, 0, 1
  ylim, newname, 1., 180.

  ; zlim, newname, 0, 0, 1
  ;options, newname, no_interp=0
  ;  tdegap, newname, /overwrite
end