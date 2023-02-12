;+
;WIDGET Procedure:
;  socket_reader
;PURPOSE:
; Widget tool that opens a socket and reads streaming data from a server (host) and can save it to a file
; or send to a user specified routine. This tool runs in the background.
; Keywords:
;   SET_FILE_TIMERES : defines how often the current output file will be closed and a new one will be opened
;   DIRECTORY:  string prepended to fileformat when opening an output file.
; Author:
;    Davin Larson - January 2023
;    proprietary - D. Larson UC Berkeley/SSL
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: ) $
; $LastChangedRevision:  $
; $URL: $
;
;-

COMPILE_OPT IDL2



function socket_reader::read_nbytes,nb,source,pos=pos

  on_ioerror, fixit
  buf = !null

  if ~isa(pos) then pos=0ul
  if isa(source,/array) then begin          ; source should be a an array of bytes
    n = nb < (n_elements(source) - pos)
    if n gt 0 then   buf = source[pos:pos+n-1]
    pos = pos+n
  endif else begin
    source = self.input_lun           ;
    if isa(source) and keyword_set(source) then begin                ; source should be a file LUN
      if file_poll_input(source,timeout=0) && ~eof(source)  then begin
        buf = bytarr(nb)
        readu,source,buf,transfer_count=n
        pos = pos+n
      endif
    endif
  endelse
  self.write,buf
  return,buf
  fixit: 
  dprint,'IO error'
  stop
  return,buf
  
end





pro socket_reader::write ,buffer
  if keyword_set(self.output_lun) then begin
    if self.file_timeres gt 0 then begin
      if self.time_received ge self.next_filechange then begin
        ; dprint,verbose=self.verbose,dlevel=2,time_string(self.time_received,prec=3)+ ' Time to change files.'
        if self.output_lun then begin
          self.open_output
        endif
      endif
      self.next_filechange = self.file_timeres * ceil(self.time_received / self.file_timeres)
    endif
    if keyword_set(buffer) then begin
      writeu,self.output_lun, buffer
    endif else flush,self.output_lun
  endif
  ; flush,self.output_lun
end







pro socket_reader::lun_read
  ; Read data from stream until EOF is encountered or no more data is available on the stream
  ; if the proc flag is set then it will process the data
  ; if the output lun is non zero then it will save the data.

  buffer = !null
  ;dprint,'entering lun_read
  if self.input_lun ne 0 then begin
    bufsize = 10240UL
    on_ioerror, stream_error
    eofile =0
    self.time_received = systime(1)
    buffer= bytarr(bufsize)
    b = bytarr(1)
    in_lun = self.input_lun
    nbytes = 0UL
    while file_poll_input(in_lun,timeout=0) && (~eofile) && (nbytes lt bufsize) do begin
      readu,in_lun,b,transfer_count=nb
      if nb gt 0 then  buffer[nbytes++] = b
    endwhile
    eofile = eof(in_lun)

    if eofile eq 1 then begin
      stream_error:
      dprint,dlevel=self.dlevel-1,self.title_num+'File error: '+self.hostname+':'+self.hostport+' broken. ',i
      dprint,dlevel=self.dlevel,!error_state.msg
    endif

    if nbytes gt 0 then begin                      ;; process data
      ;dprint,'Hello 3
      buffer = buffer[0:nbytes-1]
      *self.buffer_ptr = buffer
      msg = string(/print,nbytes,buffer[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')
      self.msg = time_string(self.time_received,tformat='hh:mm:ss - ',local=localtime) + msg
    endif else begin
      *self.buffer_ptr = !null
      self.msg =time_string(self.time_received,tformat='hh:mm:ss - No data available',local=localtime)
    endelse

    self.process_data

    if 0 then begin
      handler = self.handler_obj
      ;buffer = self.read_func()
      ; while( isa(buffer) ) do begin
      self.write,buffer
      if self.run_proc && obj_valid(handler) then handler.decommutate, buffer
      msg = self.msg

      ;   buffer = self.read_lun()
      ;endwhile

      dprint,verbose=self.verbose,dlevel=3,self.msg,/no_check

    endif


  endif


end


pro socket_reader::open_output,fileformat,time=time,close=close

  dprint,verbose=self.verbose,dlevel=2,"Opening output for: "+self.name

  if self.output_lun gt 0 then begin   ; Close old file
    dprint,verbose=self.verbose,dlevel=2,'Closing file: "'+self.filename+'"'
    free_lun,self.output_lun
    self.output_lun = 0
  endif
  if isa(fileformat,/string) then  self.fileformat = fileformat
  if keyword_set(close) then return
  if keyword_set(self.fileformat) then begin
    if ~keyword_set(time) then time=systime(1)
    self.filename = time_string(time,tformat=self.fileformat)
    fullfilename = self.directory + self.filename
    file_open,'u',fullfilename, unit=output_lun,dlevel=4,compress=-1  ;,file_mode='666'o,dir_mode='777'o
    dprint,verbose=self.verbose,dlevel=2,'Opening file: "'+fullfilename+'" Unit:'+strtrim(output_lun,2)+' '+self.title_num
    self.output_lun = output_lun
    self.filename= fullfilename
  endif else dprint,'Fileformat is not specified for "',self.title_num,'"'
end



pro socket_reader::file_read,filenames
  on_ioerror, keepgoing
  for i= 0,n_elements(filenames)-1 do begin
    file = filenames[i]
    file_open,'r',file,unit=lun,compress=-1
    if keyword_set(lun) then begin
      self.input_lun = lun
      self.lun_read
      free_lun,lun
      keepgoing:
      self.input_lun = 0
    endif
  endfor

end



pro socket_reader::handle, buffer, source_dict=source_dict

  dprint,dlevel=3,verbose=self.verbose,n_elements(buffer),' Bytes for Handler: "',self.name,'"'
  self.nbytes += n_elements(buffer)
  self.npkts  += 1

  if self.run_proc then begin
    if self.procedure_name then begin
      call_procedure,self.procedure_name,buffer ,source_dict=self.source_dict
    endif else begin
      if debug(3,self.verbose,msg=self.name) then begin
        hexprint,buffer
      endif
    endelse
  endif

end




;pro socket_reader::process_data,buffer
;  if self.run_proc then begin
;    dprint,self.msg
;    hexprint,buffer
;  endif
;end


PRO socket_reader::SetProperty, _extra=ex
  ; If user passed in a property, then set it.
  if keyword_set(ex) then begin
    struct_assign,ex,self,/nozero
  endif
END


pro socket_reader::help , item
  if keyword_set(self.base) then begin
    msg = string('Base ID is: ',self.base)
    output_text_id = widget_info(self.base,find_by_uname='OUTPUT_TEXT')
    widget_control, output_text_id, set_value=msg    
  endif
  help,self
  help,self.getattr(item)
  ;  help,self,/obj,output=output
  ;  for i=0,n_elements(output)-1 do print,output[i]
end


;function socket_reader::struct
;  ;  strct = {socket_reader}
;  strct = create_struct(name=typename(self))
;  struct_assign , self, strct
;  return,strct
;END

;function socket_reader::proc_name
;  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
;  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name   else proc_name = self.exec_proc
;  return, proc_name[0]
;end



function socket_reader::get_value,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_value=value
  return,value
end


function socket_reader::get_uvalue,uname
  id = widget_info(self.base,find_by_uname=uname)
  widget_control, id, get_uvalue=value
  return,value
end





pro socket_reader::timed_event

  if self.input_lun gt 0 then begin

    self.lun_read

    wids = *self.wids
    if isa(wids) then begin
      widget_control,wids.output_text,set_value=self.msg
      widget_control,wids.poll_int,get_value = poll_int
      poll_int = float(poll_int)
      if poll_int le 0 then poll_int = 1
      if 1 then begin
        poll_int = poll_int - (systime(1) mod poll_int)  ; sample on regular boundaries
      endif

      if not keyword_set(eofile) then WIDGET_CONTROL, wids.base, TIMER=poll_int else begin
        widget_control,wids.host_button,timer=2
      endelse

    endif
  endif

end




pro socket_reader::host_button_event

  host_button_id = widget_info(self.base,find_by_uname='HOST_BUTTON')
  host_text_id   = widget_info(self.base,find_by_uname='HOST_TEXT')
  output_text_id   = widget_info(self.base,find_by_uname='OUTPUT_TEXT')
  host_port_id   = widget_info(self.base,find_by_uname='HOST_PORT')
  widget_control,host_button_id,get_value=status
  widget_control,host_text_id, get_value=server_name
  widget_control,host_port_id, get_value=server_port
  server_n_port = server_name+':'+server_port
  self.hostname = server_name
  self.hostport = server_port
  case status of
    'Connect to': begin
      *self.buffer_ptr = !null                                  ; Get rid of previous buffer contents cache
      WIDGET_CONTROL, host_button_id, set_value = 'Connecting',sensitive=0
      WIDGET_CONTROL, host_text_id, sensitive=0
      WIDGET_CONTROL, host_port_id, sensitive=0
      socket,input_lun,/get_lun,server_name,fix(server_port),error=error ,/swap_if_little_endian,connect_timeout=10
      if keyword_set(error) then begin
        dprint,dlevel=self.dlevel-1,self.title_num+!error_state.msg,error   ;strmessage(error)
        widget_control, output_text_id, set_value=!error_state.msg
        WIDGET_CONTROL, host_button_id, set_value = 'Failed:',sensitive=1
        WIDGET_CONTROL, host_text_id, sensitive=1
        WIDGET_CONTROL, host_port_id, sensitive=1
      endif else begin
        dprint,dlevel=self.dlevel,self.title_num+'Connected to server: "'+server_n_port+'"  Unit: '+strtrim(input_lun,2)
        self.input_lun = input_lun
        WIDGET_CONTROL, self.base, TIMER=1    ;
        WIDGET_CONTROL, host_button_id, set_value = 'Disconnect',sensitive=1
      endelse
    end
    'Disconnect': begin
      WIDGET_CONTROL, host_button_id, set_value = 'Closing'  ,sensitive=0
      WIDGET_CONTROL, host_text_id, sensitive=1
      WIDGET_CONTROL, host_port_id, sensitive=1
      msg = 'Disconnected from server: "'+server_n_port+'"'
      widget_control, output_text_id, set_value=msg
      dprint,dlevel=self.dlevel,self.title_num+msg
      free_lun,self.input_lun
      self.input_lun =0
      wait,1
      WIDGET_CONTROL, host_button_id, set_value = 'Connect to',sensitive=1
    end
    else: begin
      WIDGET_CONTROL, host_text_id, sensitive=1
      WIDGET_CONTROL, host_port_id, sensitive=1
      WIDGET_CONTROL, host_button_id, set_value = 'Connect to',sensitive=1
      dprint,self.title_num+'Error Recovery'
    end
  endcase

end





pro socket_reader::dest_button_event

  dest_button_id = widget_info(self.base,find_by_uname='DEST_BUTTON')
  dest_text_id = widget_info(self.base,find_by_uname='DEST_TEXT')
  host_text_id = widget_info(self.base,find_by_uname='HOST_TEXT')
  host_port_id = widget_info(self.base,find_by_uname='HOST_PORT')
  dest_flush_id = widget_info(self.base,find_by_uname='DEST_FLUSH')

  widget_control,dest_button_id,get_value=status

  widget_control,dest_text_id, get_value=filename
  case status of
    'Write to': begin
      if keyword_set(self.output_lun) then begin
        free_lun,self.output_lun
        self.output_lun = 0
      endif
      WIDGET_CONTROL, dest_button_id      , set_value = 'Opening' ,sensitive=0
      widget_control, dest_text_id, get_value = fileformat,sensitive=0
      self.fileformat = fileformat[0]
      filename = time_string(systime(1),tformat = self.fileformat)                     ; Substitute time string
      widget_control,host_text_id, get_value=hostname
      self.hostname = hostname[0]
      filename = str_sub(filename,'{HOST}',strtrim(self.hostname,2) )
      widget_control,host_port_id, get_value=hostport
      self.hostport = hostport
      self.filename = str_sub(filename,'{PORT}',strtrim(self.hostport,2) )               ; Substitute port number
      widget_control, dest_text_id, set_uvalue = fileformat,set_value=self.filename
      if keyword_set(self.filename) then begin
        file_open,'u',self.directory+self.filename, unit=output_lun,dlevel=4,compress=-1,file_mode='666'o,dir_mode='777'o
        dprint,dlevel=dlevel,self.title_num+' Opened output file: '+self.directory+self.filename+'   Unit:'+strtrim(output_lun)
        self.output_lun = output_lun
        self.filename= self.directory+self.filename
        widget_control, dest_flush_id, sensitive=1
      endif
      ;              wait,1
      WIDGET_CONTROL, dest_button_id, set_value = 'Close   ',sensitive =1
    end
    'Close   ': begin
      WIDGET_CONTROL, dest_button_id,          set_value = 'Closing',sensitive=0
      widget_control, dest_flush_id, sensitive=0
      widget_control, dest_text_id ,get_uvalue= fileformat,get_value=filename
      if self.output_lun gt 0 then begin
        free_lun,self.output_lun
        self.output_lun =0
      endif
      ;            wait,1
      widget_control, dest_text_id ,set_value= self.fileformat,sensitive=1
      WIDGET_CONTROL, dest_button_id, set_value = 'Write to',sensitive=1
      dprint,dlevel=self.dlevel,self.title_num+'Closed output file: '+self.filename,no_check_events=1
    end
    else: begin
      dprint,self.title_num+'Invalid State'
    end
  endcase
end


pro socket_reader::proc_button_event, on
  proc_name_id = widget_info(self.base,find_by_uname='PROC_NAME')
  proc_button_id = widget_info(self.base,find_by_uname='PROC_BUTTON')

  ;  if n_elements(on) eq 0 then on =1
  if keyword_set(proc_name_id) then widget_control,proc_name_id,get_value=proc_name  $
  else proc_name=''
  if keyword_set(prc_name_id) then  widget_control,proc_name_id,sensitive = (on eq 0)
  self.run_proc = on
  dprint,verbose=self.verbose,dlevel=1,self.title_num+'"'+proc_name+ '" is '+ (self.run_proc ? 'ON' : 'OFF')
end


pro socket_reader::destroy
  if self.input_lun gt 0 then begin
    fs = fstat(self.input_lun)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.input_lun
  endif
  if self.output_lun gt 0 then begin
    fs = fstat(self.output_lun)
    dprint,dlevel=self.dlevel-1,self.title_num+'Closing '+fs.name
    free_lun,self.output_lun
  endif
  WIDGET_CONTROL, self.base, /DESTROY
  ; ptr_free,ptr_extract(self.struct())
  dprint,dlevel=self.dlevel-1,self.title_num+'Widget Closed'
  return
end



PRO socket_reader_proc,buffer,info=info

  n = n_elements(buffer)
  if n ne 0 then  begin
    if debug(2) then begin
      dprint,time_string(info.time_received,prec=3) +''+ strtrim(n_elements(buffer))
      n = n_elements(buffer) < 512
      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
    endif
  endif else print,format='(".",$)'
  dprint,dlevel=2,phelp=2,info
  return
end


function socket_reader_object,base
  widget_control, base, get_uvalue= info   ; get all widget ID's
  return,info
end







PRO socket_reader_event, ev   ; socket_reader
  ;   on_error,1
  uname = widget_info(ev.id,/uname)
  dprint,uname,ev,/phelp,dlevel=5

  widget_control, ev.top, get_uvalue= self   ; get the object to make this "look" like a method

  ;printdat,ev,uname
  CASE uname OF                         ;  Timed events
    'BASE':                 self.timed_event
    'HOST_BUTTON' :         self.host_button_event
    'DEST_BUTTON' :         self.dest_button_event
    'DEST_FLUSH': begin
      self.dest_button_event   ; close old file
      self.dest_button_event   ; open  new file
    end
    'PROC_BUTTON':         self.proc_button_event, ev.select
    'DONE':                self.destroy
    else:                  self.help
  ENDCASE
END


;PRO socket_reader_template,buffer,info=info
;;    savetomain,buffer
;;    savetomain,time
;
;    n = n_elements(buffer)
;    if n ne 0 then  begin
;    if debug(2) then begin
;      dprint,time_string(self.time_received,prec=3) +''+ strtrim(n_elements(buffer))
;      n = n_elements(buffer) < 512
;      hexprint,buffer[0:n-1]    ;,swap_endian(uint(buffer,0,n_elements(buffer)/2))
;    endif
;    endif else print,format='(".",$)'
;
;    return
;end


;
;function spp_ptp_header_struct,ptphdr
;  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
;  ptp_code = ptphdr[2]
;  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))
;  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
;  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
;  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
;  utime = (days-4383L) * 86400L + ms/1000d
;  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
;  ;      if keyword_set(time) then dt = utime-time  else dt = 0
;  source   =    ptphdr[13]
;  spare    =    ptphdr[14]
;  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
;  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
;  return,ptp_header
;end


;
;
;pro socket_reader::read_lun,lun
;on_ioerror, nextfile
;isasocket = self.isasocket
;;lun = self.output_lun
;
;buf = bytarr(17)
;remainder = !null
;while (isasocket ? file_poll_input(lun) : ~eof(lun) ) do begin
;  info.time_received = systime(1)
;  readu,lun,buf
;  hdrbuf = [remainder,buf]
;  sz = hdrbuf[0]*256 + hdrbuf[1]
;  if (sz lt 17) || (hdrbuf[2] ne 3) || (hdrbuf[3] ne 0) || (bhdrbuf[4] ne 'bb'x) then  begin     ;; Lost sync - read one byte at a time
;    remainder = hdrbuf[1:*]
;    buf = bytarr(1)
;    if debug(3) then begin
;      dprint,dlevel=3,'Lost sync:',dwait=10
;    endif
;    continue
;  endif
;  ptp_struct = spp_ptp_header_struct(hdrbuf)
;  ccsds_buf = bytarr(sz - n_elements(hdrbuf))
;  readu,lun,ccsds_buf,transfer_count=nb
;
;  if nb ne sz then begin
;    dprint,'File read error. Aborting @ ',fp,' bytes'
;    break
;  endif
;  spp_ccsds_pkt_handler,ccsds_buf,ptp_header=ptp_header
;  ;      if debug(2) then begin
;  ;        dprint,dwait=dwait,dlevel=2,'File percentage: ' ,(fp*100.)/fi.size
;  ;      endif
;  buf = bytarr(17)
;  remainder=!null
;endwhile
;
;if 0 then begin
;  nextfile:
;  dprint,!error_state.msg
;  dprint,'Skipping file'
;endif
;;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size
;end
;
;



function socket_reader::init,name,base=base,title=title,ids=ids,host=host,port=port,fileformat=fileformat,exec_proc=exec_proc, $
  set_connect=set_connect, set_output=set_output, pollinterval=pollinterval, set_file_timeres=set_file_timeres ,$
  get_procbutton = get_procbutton,set_procbutton=set_procbutton,directory=directory, $
  get_filename=get_filename,info=info,no_widget=no_widget,verbose=verbose

  if ~keyword_set(name) then name='generic'
  self.name  =name

  self.source_dict = dictionary()
  if isa(verbose) then self.verbose = verbose else self.verbose = 2

  if not keyword_set(host) then host = ''
  if not keyword_set(port) then port = '2000'
  if not keyword_set(title) then title = name+' Reader'
  if not keyword_set(set_file_timeres) then set_file_timeres=3600.d
  self.file_timeres =set_file_timeres
  port=strtrim(port,2)
  if not keyword_set(fileformat) then fileformat = name+'/YYYY/MM/DD/'+name+'_YYYYMMDD_hh.dat'
  self.hostname = HOST
  self.hostport = port
  self.title = title
  self.fileformat = fileformat
  self.buffer_ptr = ptr_new(/allocate_heap)
  ;self.buffersize = 2L^10
  self.dlevel = 2
  self.isasocket=1
  self.run_proc = isa(run_proc) ? run_proc : 1    ; default to running proc
  self.dyndata = dynamicarray(name=name)


  if ~keyword_set(no_widget) then begin
    if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
      self.base = WIDGET_BASE(/COLUMN, title=title , uname='BASE')
      ids = create_struct('base', self.base )
      ids = create_struct(ids,'host_base',   widget_base(ids.base,/row, uname='HOST_BASE') )
      ids = create_struct(ids,'host_button', widget_button(ids.host_base, uname='HOST_BUTTON',value='Connect to') )
      ids = create_struct(ids,'host_text',   widget_text(ids.host_base,  uname='HOST_TEXT' ,VALUE=host ,/EDITABLE ,/NO_NEWLINE ) )
      ids = create_struct(ids,'host_port',   widget_text(ids.host_base,  uname='HOST_PORT',xsize=6, value=port   , /editable, /no_newline))
      ids = create_struct(ids,'poll_int' ,   widget_text(ids.host_base,  uname='POLL_INT',xsize=6,value='1',/editable,/no_newline))
      ;    if n_elements(directory) ne 0 then $
      ;      ids = create_struct(ids,'destdir_text',   widget_text(ids.base,  uname='DEST_DIRECTORY',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=directory))
      ids = create_struct(ids,'dest_base',   widget_base(ids.base,/row, uname='DEST_BASE'))
      ids = create_struct(ids,'dest_button', widget_button(ids.dest_base, uname='DEST_BUTTON',value='Write to'))
      ids = create_struct(ids,'dest_text',   widget_text(ids.dest_base,  uname='DEST_TEXT',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=fileformat))
      ids = create_struct(ids,'dest_flush',  widget_button(ids.dest_base,uname='DEST_FLUSH', value='New' ,sensitive=0))
      ids = create_struct(ids,'output_text', WIDGET_TEXT(ids.base, uname='OUTPUT_TEXT'))
      ids = create_struct(ids,'proc_base',   widget_base(ids.base,/row, uname='PROC_BASE'))
      ids = create_struct(ids,'proc_base2',  widget_base(ids.proc_base ,/nonexclusive))
      ids = create_struct(ids,'proc_button', widget_button(ids.proc_base2,uname='PROC_BUTTON',value='Procedure:'))
      ids = create_struct(ids,'proc_name',   widget_text(ids.proc_base,xsize=35, uname='PROC_NAME', value = keyword_set(exec_proc) ? exec_proc :'socket_reader_proc',/editable, /no_newline))
      ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.proc_base, VALUE='Done', UNAME='DONE'))
      
      self.title_num  = self.title+' ('+strtrim(ids.base,2)+'): '

      self.wids = ptr_new(ids)

      WIDGET_CONTROL, self.base, SET_UVALUE=self
      WIDGET_CONTROL, self.base, /REALIZE
      widget_control, self.base, base_set_title=self.title_num
      XMANAGER, 'socket_reader', self.base,/no_block
      dprint,dlevel=dlevel,self.title_num+'Widget started'
      base = self.base
    endif else begin
      widget_control, base, get_uvalue= info   ; get all widget ID's
      ids = info.wids
    endelse
    ;if size(/type,exec_proc) eq 7 then    widget_control,ids.proc_name,set_value=exec_proc
    if size(/type,exec_proc) eq 7 then self.exec_proc = exec_proc
    if size(/type,destination) eq 7 then  widget_control,ids.dest_text,set_value=destination
    if size(/type,host) eq 7 then  widget_control,ids.host_text,set_value=host
    if n_elements(port) eq 1 then  widget_control,ids.host_port,set_value=strtrim(port,2)
    if n_elements(pollinterval) ne 0 then widget_control,ids.poll_int,set_value=strtrim(pollinterval,2)
    if n_elements(set_output)  eq 1 && (keyword_set(info.output_lun) ne keyword_set(set_output )) then socket_reader_event, { id:ids.dest_button, top:ids.base }
    if n_elements(set_connect) eq 1 && (keyword_set(info.input_lun) ne keyword_set(set_connect)) then socket_reader_event, { id:ids.host_button, top:ids.base }
    if n_elements(set_procbutton) eq 1 then begin
      widget_control,ids.proc_button,set_button=set_procbutton
      socket_reader_event, { top:ids.base, id:ids.proc_button, select: keyword_set(set_procbutton) }
    endif
    if n_elements(set_file_timeres) then begin
      self.file_timeres = set_file_timeres
    endif
    if n_elements(directory) then begin
      self.directory = directory
    endif
    get_procbutton = widget_info(ids.proc_button,/button_set)
    ;widget_control,ids.dest_text,get_value=get_filename
    get_filename = keyword_set(self.output_lun) ? self.filename : ''
    widget_control, base, set_uvalue= self
    
  endif

  return,1

END





pro socket_reader__define
  dummy = {socket_reader, $
    inherits generic_object, $
    base:0L ,$
    wids:ptr_new(), $
    hostname:'',$
    hostport:'', $
    title: '', $
    title_num: '', $
    time_received: 0d,  $
    file_timeres: 0d,   $   ; Defines time interval of each output file
    next_filechange: 0d, $ ; don't use - will be deprecated in future
    isasocket:0,  $          
    input_lun:0,  $               ; host input file pointer (lun)
    output_lun:0 , $               ; destination output file pointer (lun)
    directory:'' ,  $          ; output/input directory
    fileformat:'',  $          ; output/input fileformat  - accepts time wild cards i.e.:  "file_YYYYMMDD_hh.dat"
    filename:'', $             ; output filename
    msg: '', $
    ;buffersize:0L, $
    buffer_ptr: ptr_new(),   $
    pollinterval:0., $
    source_dict: obj_new(),  $
    name: '',  $
    nbytes: 0UL, $
    npkts:  0ul, $
    nreads: 0ul, $
 ;   brate: 0. , $ ; don't use - will be deprecated in future
 ;   prate: 0. , $ ; don't use - will be deprecated in future
 ;   output_filename:  '',   $
    procedure_name: '', $
    dyndata: obj_new(), $
    run_proc:0 }

end

