;swfo_test

pro swfo_frame_header_plot, hdrs
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
  trange = '2024 10 18/' + ['13:15','14:35']
  ;trange = ['2024 10 14','2024 10 22']
  stop

  !p.charsize = 1.2
  ;!x.style=3
  ;!y.style =3

  no_download = 0    ;comment out this line to download the files  (or set no_download =0

  ;https://sprg.ssl.berkeley.edu/data/swfo/outgoing/swfo-l1/l0/
  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    resolution :900   }
    
   

  if 0 then begin
    pathname = 'swfo/swpc/L0/YYYY/MM/DD/it_frm-rt-l0_swfol1_sYYYYMMDDThhmm00Z_*.nc'
    files = file_retrieve(pathname,_extra=source,trange=trange,/no_update,no_download=no_download)    
    w=where(file_test(files),/null)
    files = files[w]
  endif else begin
    pathname = 'swfo/swpc/E2E2b/decomp/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc'
    files = file_retrieve(pathname,_extra=source,/no_update,no_download=no_download)  ; get All the files first
    fileformat = file_basename(str_sub(pathname,'*.nc','YYYYMMDDThhmm00'))
    filerange = time_string(trange,tformat=fileformat)
    w = where(file_basename(files) ge filerange[0] and file_basename(files) lt filerange[1],nw,/null)
    files = files[w]   
  endelse

  ;f = '/Users/davin/Downloads/it_frm-rt-l0_swfol1_s20240918T151500Z_e20240918T152959Z_p20240918T153015Z_emb.nc'  ; Very large
  ;f = '/Users/davin/Downloads/it_frm-rt-l0_swfol1_s20240919T061500Z_e20240919T062959Z_p20240919T063015Z_emb.nc'  ; no STIS
  ;f = '/Users/davin/Downloads/it_frm-rt-l0_swfol1_s20240920T174500Z_e20240920T175959Z_p20240920T180015Z_emb.nc'  ; has STIS


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


swfo_stis_apdat_init,/save_flag

rdr = ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose)


if keyword_set(dat) then begin
  rdr.read,(dat.frames)[*]

endif else begin
  for i = 0, n_elements(files)-1 do begin
    d = swfo_ncdf_read(file=files[i],force_recdim=1)
   if isa(d) then  rdr.read , d.frames
  endfor
endelse






swfo_apdat_info,/create_tplot_vars,/all,/print  ;  ,verbose=0


swfo_apdat_info,/print,/all


printdat,rdr.dyndata.array

if 0 then begin
  ;pkt_rdr = rdr.getattr('ccsds_packet_reader')
  h = rdr.getattr('handlers')
  hi= h.keys()
  if ~isa(pkt_rdr) then pkt_rdr = h[hi[0]]

  printdat,pkt_rdr.dyndata.array

  wi,4
  plot,pkt_rdr.dyndata.array.apid,psym=3,yrange=[0,2000]

  wi,5
  pkt_rdr = h[hi[1]]
  plot,pkt_rdr.dyndata.array.apid,psym=3

endif
  

swfo_stis_tplot,/set
tplot,'*SEQN
tplot,'*SEQN_DELTA',add=99


end
