; cl_load_csa_crib.pro
; 
; 
pro cl_load_csa_crib
;  Get lists of valid probes and datatypes

cl_load_csa,probes=valid_probes,datatypes=valid_datatypes,/valid_names

trange=['2001-02-01T00:00:00Z','2001-02-04T00:00:00Z']

; Load CP_FGM_FULL data for C1

;cl_load_csa,trange=trange,probes='C1',datatypes='CP_FGM_FULL'

;cl_load_csa,trange=trange,probes=valid_probes[0], datatypes=valid_datatypes[0:9]

;cl_load_csa,trange=trange,probes='C1',datatypes='CP_STA_CS_HBR',verbose=5
; Try to load all valid datatypes for C1

for i=0,n_elements(valid_datatypes)-1 do begin
  print,"Loading "+valid_datatypes[i]
  cl_load_csa,trange=trange,probes='C1', datatypes=valid_datatypes[i], verbose=3
endfor
end
