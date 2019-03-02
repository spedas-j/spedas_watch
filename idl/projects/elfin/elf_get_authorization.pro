;+
;  Function elf_get_authorization
;
;  This function returns a structure that contains the user_name and password
;  for accessing elfin data. 
;      authorization = { user_name: user_name, password: password }
;
;  Note this function is only necessary for ELFIN data that is not yet public.
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "ELF_INIT" procedure.
;
;  KEYWORDS
;     none
;
;-
function elf_get_authorization

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  user_name = ''
  password = ''
  
  authorization_file = !elf.local_data_dir + 'elf_authorization.txt'
  if strlowcase(!version.os_family) eq 'windows' then authorization_file = strjoin(strsplit(authorization_file, '/', /extract), path_sep())

  if file_test(authorization_file) then begin
    openr, lun, authorization_file, /get_lun
    readf, lun, user_name
    readf, lun, password
    free_lun, lun
  endif
  
  authorization = { user_name: user_name, password: password }
  
  return, authorization
  
end