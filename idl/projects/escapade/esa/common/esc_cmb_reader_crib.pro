; esc_cmb_reader_crib
; 
; 



; 
; 


stop

cmb = cmblk_reader(host = 'abiad-sw',port=5004,directory='ESC_TEST/')
file = '/Users/phyllisw/Desktop/eesa.cmb'
cmb.file_read,file

; Then click on open button


; view what has been read in:
cmb.print_status

; get object related to Escapade:
esc = cmb.get_handlers('ESC_ESATM')


; Display help on esc data:
esc.help


;Turn on verbose mode:
esc.verbose=4

;Turn off verbose:
esc.verbose=2


; Get saved data:
da = esc.dyndata


; Create tplot variables to look at data:
store_data,da.name,data=da,tagnames='*'



tplot,'Esc*',trange=systime(1) + [-1,.05] * 60 *5






;Manipulator data:
manip = cmb.get_handlers('MANIP')
store_data,'Manip',data=manip.dyndata,tagnames='*'




end