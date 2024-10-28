;swfo_test
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-10-27 01:24:49 -0700 (Sun, 27 Oct 2024) $
; $LastChangedRevision: 32908 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_frame_read_crib.pro $




pro swfo_frame_header_plot, hdrs, _extra = ex
  if n_elements(hdrs) le 1 then begin
    printdat,hdrs
    return
  endif
  plt = get_plot_state()
  ;charsize = !p.charsize
  !p.charsize = 2
  !p.multi = [0,1,8]
  !x.style=3
  !y.style=3
  !y.margin = 1
  !p.psym = struct_value(ex,'psym',default=!p.psym)
  index = lindgen(n_elements(hdrs))
  plot,hdrs.seqn,/ynozero
  seqn_delta = long(hdrs.seqn) - shift(hdrs.seqn,1)
  seqn_delta[0] = 5
  plot,seqn_delta,yrange = [-10,10]
  oplot,seqn_delta,psym=1,color=6,symsize=.5
  plot,hdrs.vcid,/ynozero
  plot,hdrs.sigfield,/ynozero
  ;bitplot,hdrs.index,hdrs.vcid
  plot,hdrs.last4[2],/ynozero
  bitplot,index,hdrs.last4[2],limits=struct(negate=0x0)
  plot,hdrs.seqid,/ynozero
  plot,hdrs.last4[3]
  ;!p.multi=0
  ;!p.charsize = charsize
  restore_plot_state,plt
end




if ~keyword_set(files) then begin
  trange = ['2024 9 18','2024 9 19']
  trange = '2024-9-18 / 20:45'
  trange = '2024-9-19 ' + [' 0:0',' 24:00']
  trange = '2024-9-18 ' + [' 0:0',' 24:00']
  trange = ['2024 9 19 12','2024 9 21']
  trange = '2024-9-18 ' + [' 12:0',' 18:00']
  ;trange = ['2024 9 17','2024 9 25']
  trange = '2024 10 17/' + ['0','6']
  trange = '2024 10 18/' + ['0','24']
  ;trange = systime(1) + [-1,0] *3600d *6
  trange = '2024 10 18/' + ['13:15','16:35']
  ;trange = ['2024 10 14','2024 10 22']
  stop


  if ~isa(rdr) then begin
    swfo_stis_apdat_init,/save_flag
    rdr = ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    !p.charsize = 1.2
  endif



  no_download = 0    ;comment out this line to download the files  (or set no_download =0

  ;https://sprg.ssl.berkeley.edu/data/swfo/outgoing/swfo-l1/l0/
  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
       resolution: 900L  }


  case 2 of
    0: begin
      pathname = 'swfo/swpc/L0/YYYY/MM/DD/it_frm-rt-l0_swfol1_sYYYYMMDDThhmm00Z_*.nc'
      files = file_retrieve(pathname,_extra=source,trange=trange,/no_update,no_download=no_download)
      w=where(file_test(files),/null)
      files = files[w]
    end
    1: begin
      pathname = 'swfo/swpc/E2E2b/decomp/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc'
      allfiles = file_retrieve(pathname,_extra=source,/no_update,no_download=no_download)  ; get All the files first
      fileformat = file_basename(str_sub(pathname,'*.nc','YYYYMMDDThhmm00'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'frames'
    end
    2: begin
      pathname = 'swfo/aws/L0/SWFOWCD/YYYY/MM/DD/OR_SWFOWCD-L0_SL1_s*.nc'
      source.resolution = 24L*3600
      allfiles = file_retrieve(pathname,_extra=source,no_update=1,no_download=no_download,trange=trange)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc','YYYYDOYhhmm'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
    3: begin
      pathname = 'swfo/aws/L0/SWFOCBU/YYYY/MM/DD/OR_SWFOCBU-L0_SL1_s*.nc'
      source.resolution = 24L*3600
      allfiles = file_retrieve(pathname,_extra=source,no_update=1,no_download=no_download,trange=trange)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc','YYYYDOYhhmm'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
  endcase



  if strmid(pathname,2,3,/reverse) eq '.gz' then begin
    file_gunzip,files
    ofiles = files
    for i=0,n_elements(files)-1 do files[i] = strmid(files[i],0,strlen(files[i])-3)
  endif

endif


if 0 &&  ~isa(dat) then begin

  dat = swfo_ncdf_read(files,force_recdim=1)

  if ~keyword_set(dhdrs) then begin
    foo_rdr = ccsds_frame_reader(mission='SWFO',/no_widget)
    dhdrs = dynamicarray(name='test')
    nframes = n_elements(dat)
    for i=0,nframes-1 do dhdrs.append, foo_rdr.header_struct(dat[i].frames)

  endif
  hdrs = dhdrs.array
  ;hdrs.time = dindgen(n_elements(hdrs))

  if 1 then begin   ; filter out all the duplicate frames
    hsh = hdrs.hashcode
    s= sort(hsh)
    u = uniq( hsh[ s ] )
    hdrs = hdrs[s[u]]
    s = sort(hdrs.index)
    hdrs = hdrs[s]
  endif

  wi,2   ,wsize=[1200,1100]

  if 1 then begin
    hdrs.seqn_delta = hdrs.seqn - shift(hdrs.seqn,1)
    swfo_frame_header_plot, hdrs
    stop


    seqids = hdrs.seqid
    uniq_seqids = seqids[ uniq( seqids, sort(seqids) ) ]
    printdat,uniq_seqids
    for i = 0,n_elements(uniq_seqids)-1 do begin
      w = where( hdrs.seqid eq uniq_seqids[i],nw)
      print,uniq_seqids[i],nw
      swfo_frame_header_plot, hdrs[w]
      stop
    endfor

  endif

endif



stop



if keyword_set(1) then begin
  parent = dictionary()
  rdr.parent_dict = parent
  rdr.verbose = 3
  rdr.source_dict.run_proc = 1
  for i = 0, n_elements(files)-1 do begin
    file = files[i]
    dprint,string(rdr.getattr('index'))+'   '+ file
    parent.filename = files
    parent.num_duplicates = 0
    parent.max_displacement = 0
    dat = ncdf2struct(file)
    frames = struct_value(dat,frames_name,default = !null)
    rdr.read , frames
  endfor
endif


stop



swfo_apdat_info,/create_tplot_vars,/all,/print  ;  ,verbose=0


swfo_apdat_info,/print,/all


printdat,rdr.dyndata.array

swfo_frame_header_plot, rdr.dyndata.array

stop




swfo_stis_tplot,/set
tplot,'*SEQN *SEQN_DELTA'

stop
swfo_apdat_info,/sort,/all,/print
delta_data,'*SEQN',modulo=2^14
options,'*_delta',psym=-1,symsize=.4,yrange=[-10,10]


tplot,'*SEQN *SEQN_delta'


end
