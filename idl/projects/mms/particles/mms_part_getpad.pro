;+
; PROCEDURE:
;         mms_part_getpad
;
; PURPOSE:
;         Quickly generate pitch angle spectrograms from multipad output from mms_part_getspec/mms_part_products_new
;
; NOTES:
;         still a work in progress
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-03-20 13:51:47 -0700 (Tue, 20 Mar 2018) $
; $LastChangedRevision: 24919 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_getpad.pro $
;-


pro mms_part_getpad, probe=probe, data_rate=data_rate, energy=energy, pitch=pitch, species=species, suffix=suffix, $
  instrument=instrument

  if undefined(instrument) then instrument = 'fpi'
  if undefined(species) then species = 'e'
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(pitch) then pitch = [0, 180]
  if undefined(data_rate) then data_rate = 'fast'
  if undefined(suffix) then suffix = ''
  
  get_data, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+'_pad'+suffix, data=d, dlimits=dl, limits=l
  
  if ~is_struct(d) then begin
    dprint, dlevel = 0, 'Error, multi-dimensional PAD variable not found; call mms_part_getspec with the "multipad" output option'
    return
  endif
  
  if undefined(energy) then energy = [d.v1[0], d.v1[n_elements(d.v1)-1]]
  
  en_in_range = where(d.V1 ge energy[0] and d.V1 le energy[1], en_count)
  pa_in_range = where(d.V2 ge pitch[0] and d.V2 le pitch[1], pa_count)

  out = average(d.Y[*, en_in_range, pa_in_range], 2, /nan)
  
  store_data, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+suffix+'_pad_'+strcompress(string(energy[0]), /rem)+'eV_'+strcompress(string(energy[1]), /rem)+'eV', $
    data={x: d.X, y: out, v: d.V2[pa_in_range]}, dlimits=dl, limits=l
  
end