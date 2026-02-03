pro swfo_load,make=make,trange=trange,types=types,current=current,datahash=datahash,resolution=resolution,file_hashes=file_hashes,user_pass=user_pass


  if isa(user_pass,'string') then setenv,'SWFO_USER_PASS='+user_pass

  swfo_user_pass = getenv('SWFO_USER_PASS')
  
  pathname0 = 'swfo/data/test3/NCDF/$NAME$/DAY/YYYY/MM/$NAME$_YYYY-MM-DD.nc'



  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    local_data_dir:root_data_dir(),  $
    master_file:'swfo/.master', $
    min_age_limit :100,$
    no_update : 0 ,$
    no_download :0 ,$
    user_pass:  swfo_user_pass, $
    resolution: 3600d*24  }

  if keyword_set(make) then begin
    
 
    if make eq 3 then begin
      message ,'Not ready yet'
      
    endif
    
    
    if make eq 2 then begin
      if ~keyword_set(trange) then trange = time_double(['2025 9 24','now'])
      if ~keyword_set(res) then res = 24*3600d  ;3600d
      ;res = 3600d  *24  ; 1 day
      tints = floor(time_double(trange)/res)
      nt = tints[1] - tints[0] +1
      ;types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64']

      for tint= tints[0],tints[1]+1 do begin
        tr= (tint +[0,1]) *res 
        swfo_ccsds_frame_read,trange=tr,merge=0,reader=rdr,user_pass=getenv('SWFO_USER_PASS')  
        dh=!null
        
        swfo_load,/make,datahash=dh,types=types,resolution=res,file_hashes=rdr.dyndata
        foreach d,dh do begin
          d.size = 0      ;clear contents of dynamic arrays
        endforeach   ; data type
        dprint,time_string(tr)
        
      endfor   ; day
      
      return
    endif           ; end of make eq 2
    
    
    if ~keyword_set(datahash) then begin
      datahash= orderedhash()
      objs = swfo_apdat()
      foreach obj,objs do begin
        if keyword_set(obj.name) then begin
          datahash[obj.name] = obj.data
        endif
      endforeach
      datahash['file_hashes'] =file_hashes
    endif
    
 ;   if n_elements(trange) ne 2 then trange =[time_double('2025-9-23'),systime(1) ]   ;+ [-1,0] * 3600d *24 * current
;    n = n_elements(objs)
    foreach da,datahash,key do begin
      if isa(da,'dynamicarray') then begin
        if da.size gt 0 then begin
          dprint,key,' ',da.name,da.size
          da.ncdf_make_file,/append ,resolution=resolution, pathformat=pathname0 ; don't include trange!,trange=trange
        endif
      endif
    endforeach
    return
  endif         ; End of make
  
  
  
  
  
;  Start of load
  
  
  

  ;if ~keyword_set(current) then current=6
  if n_elements(trange) ne 2 then trange=timerange(trange)   ;systime(1) + [-1,0]*3600d*24*current

  if ~keyword_set(types) then begin
    types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64','ccsds_frame_reader']
  endif

  if ~isa(datahash,'hash') then datahash=orderedhash()
  
  source.local_data_dir = root_data_dir()  ; +'swfo/data/test2/'

  printdat,source

  tr = timerange(trange)
  
  foreach type,types do begin
    if datahash.haskey(type) then dynarray = datahash[type] else dynarray= dynamicarray(name=type)
    pathname = str_sub(pathname0,'$NAME$',type)
    files = file_retrieve(pathname,trange=tr,_extra=source)
    if 1 then begin
      pathname = str_sub(pathname0,'$NAME$', 'pb_'+type)
      pb_files = file_retrieve(pathname,trange=tr,_extra=source)
      files = [files,pb_files]
      da = swfo_ncdf_read(filenames = files,dynarray=dynarray)
      da.trim
      da.sort,/uniq
    endif else begin
      da = swfo_ncdf_read(filenames = files,dynarray=dynarray)
      da.trim 
    endelse
    dprint,da,da.name,da.size
    ;help,da
    
    if keyword_set(store) then  store_data,'swfo_'+type,data=da,tagnames='*'
   
    datahash[type] = da
    
  endforeach
  
  
  dprint,'Computing L0b',dlevel=2
  l0b = swfo_stis_sci_level_0b(datahash=datahash)
  l0b_da = dynamicarray(l0b,name='stis_l0b',/nocopy)
  datahash['stis_l0b'] = l0b_da
  
  dprint,'Computing L1a',dlevel=2
  l1a_da =  dynamicarray(name='stis_l1a', swfo_stis_sci_level_1a(l0b_da.array) )
  datahash['stis_l1a'] = l1a_da
  
  dprint,'Computing L1b',dlevel=2
  l1b_da =  dynamicarray(name='stis_l1b', swfo_stis_sci_level_1b(l1a_da.array) )


  datahash['stis_l1b'] = l1b_da

  if keyword_set(1 || tplot_store) then begin

    tname = 'swfo_stis_L1a'
    dprint,'Making L1 tplot variables: ',tname
 ;   l1a = dynamicarray(swfo_stis_sci_level_1a(l0b.array),name=tname)
    store_data,tname,data = l1a_da,tagnames = '*'
    store_data,tname,data = l1a_da,tagnames = 'SPEC_??',val_tag='_NRG'
    store_data,tname,data = l1a_da,tagnames = 'SPEC_???',val_tag='_NRG'
    store_data,tname,data = l1a_da,tagnames = 'SPEC_????',val_tag='_NRG'
    options,tname+'_SPEC_??',spec=1, zlog=1, ylog=1, yrange=[5,10000.]
    options,tname+'_SPEC_???',spec=1, zlog=1, ylog=1, yrange=[5,10000.]
    options,tname+'_SPEC_????',spec=1, zlog=1, ylog=1, yrange=[5,10000.]
    options,tname+'_RATE6',/ylog
    ;options,tname+['_RATE','*SIGMA','*BASELINE', /reverse_order, colors ='bgrmcd'
    
    tname = 'swfo_stis_L1b'
    store_data,tname,data=l1b_da,tagnames='*'
    dlim = {spec:1,ylog:1,yrange:[10.,10000.],zlog:1,zrange:[1e1,1e10]}
    store_data,tname,data=l1b_da,tagnames='*ION_FLUX',val='ION_ENERGY';,dlim=dlim
    store_data,tname,data=l1b_da,tagnames='*ELEC_FLUX',val='ELEC_ENERGY';,dlim=dlim
    options,'*HDR*',spec=1
    ylim,'*HDR*',5,10000,1
    zlim,'*HDR*',1,1,1

    options,/def,'*_RATE6 *BASELINE *SIGMA tlimi*NOISE_TOTAL',colors='bgrmcd',symsize=.5,$
      labels=channels,labflag=-1,constant=0,/reverse_order


  endif
  ;l1b_da.

  if 1 then begin
    dprint,'mag stuff'
    if datahash.haskey('mag') then maghr_da = datahash['mag']   ; else mag_da=dynamicarray(name='mag')

    if datahash.haskey('mag8')   then swfo_mag_decom,datahash['mag8'],maghr_da
    if datahash.haskey('mag64')  then swfo_mag_decom,datahash['mag64'],maghr_da
    datahash['mag'] = maghr_da
    
    store_data,'mag',data=maghr_da,tagname='*',dlim={colors:'bgr'}
    dprint,dlevel=2,'pathname0: ',pathname0
    maghr_da.ncdf_make_file,/append ,resolution=resolution, pathformat=pathname0,trange=trange
    
  endif
  tplot_options,'title','SWFO Prelimary Data - Do not disseminate'
  tplot_options,'notes','Preliminary data - Do not disseminate'
  dprint,'Done'
  ;stop

end
