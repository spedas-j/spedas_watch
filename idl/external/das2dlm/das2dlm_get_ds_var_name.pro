;+
; PRO: das2dlm_get_ds_var_name, ...
;
; Description:
;    Return the name of the data variable in the dataset. 
;
; Keywords:
;    ds: Dataset returned by das2c_datasets(query)
;    vnames: list of names of the data variable
;    exclude (optional): array of variables to exclude from the list  
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;    
; NOTE:
;   This function is under active development. Its behavior can change in the future.
;
; $LastChangedBy: adrozdov $
; $Date: 2020-10-26 18:36:43 -0700 (Mon, 26 Oct 2020) $
; $Revision: 29297 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_get_ds_var_name.pro $
;-

pro das2dlm_get_ds_var_name, ds, vnames=vnames, exclude=exclude

  pdims = das2c_pdims(ds) ; get all pdims
  nd = size(pdims, /n_elem)
  ; Get all variables
  vnames = []
  for i=0,nd-1 do begin
    name = pdims[i].pdim
    ; exlude variables that we don't want (e.g 'time')
    if array_contains(name, exclude) then continue    
    vnames = [vnames, name]    
  endfor
end