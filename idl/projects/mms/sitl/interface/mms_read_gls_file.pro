; Function to read MMS gls files
; Input is the filename
; Output is a structure that includes FOM_Start, FOM_stop, FOM and comment. Times are given in UTC time format.
; 
; Note - this only reads a single file. If there are multiple files, this will need to be called more than once.

function mms_read_gls_file, filename

output = read_csv(filename)

start_time = output.field1
stop_time = output.field2
fom = output.field3
comment = output.field4

outstruct = {start: start_time, $
             stop: stop_time, $
             fom: fom, $
             comment: comment}
             
return, outstruct
             
end