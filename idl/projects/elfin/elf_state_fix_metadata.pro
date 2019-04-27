;+
; PROCEDURE:
;         elf_state_fix_metadata
;
; PURPOSE:
;         Helper routine for setting metadata of ELFIN state variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-05-01 13:00:22 -0700 (Mon, 01 May 2017) $
;$LastChangedRevision: 23255 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_fix_metadata.pro $
;-

pro elf_state_fix_metadata, probe, suffix = suffix

  if undefined(suffix) then suffix = ''
  probe = strcompress(string(probe), /rem)
  position_vars = tnames('el'+probe+'_pos_*')
  velocity_vars = tnames('el'+probe+'_vel_*')
 
  for pos_idx = 0, n_elements(position_vars)-1 do begin
    get_data, position_vars[pos_idx], data=d, dlimits=dl, limits=l
    coloridx=where(tag_names(dl) EQ 'COLORS', ccnt)
    if ccnt EQ 0 then dl = create_struct(dl, 'colors', [2, 4, 6])
    labelidx=where(tag_names(dl) EQ 'LABELS', lcnt)
    if lcnt EQ 0 then dl = create_struct(dl, 'labels', ['X', 'Y', 'Z'])
    store_data, position_vars[pos_idx], data=d, dlimits=dl, limits=l
  endfor
  for vel_idx = 0, n_elements(velocity_vars)-1 do begin
    get_data, velocity_vars[vel_idx], data=d, dlimits=dl, limits=l
    coloridx=where(tag_names(dl) EQ 'COLORS', ccnt)
    if ccnt EQ 0 then dl = create_struct(dl, 'colors', [2, 4, 6])
    labelidx=where(tag_names(dl) EQ 'LABELS', lcnt)
    if lcnt EQ 0 then dl = create_struct(dl, 'labels', ['X', 'Y', 'Z'])
    store_data, velocity_vars[vel_idx], data=d, dlimits=dl, limits=l
  endfor

end