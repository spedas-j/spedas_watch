pro mvn_sep_elec_peri_mhd,mhd=mhd,bxyz=bijk,b1xyz=b1ijk,rxyz=rijk,plot=plot,save=save

folder='/home/rahmati/Desktop/crustalb/'
case mhd of
1: begin
  file=folder+'3d__mhd_6_n0040000_int_1000km' ;3deg resolution
  start=12
  ijk=[3,91,61,121]; [3,r,t,p]
  end
2: begin
  file=folder+'3d__ful_6_n0100000_int_1000km' ;1deg resolution
  start=15
  ijk=[3,91,181,361]; [3,r,t,p]
  end
  3: begin
    file='3d__ful_6_t_n_int1000km' ;new mhd
    if ~keyword_set(save) then begin
      restore,folder+file+'.sav'
      bijk=bt2
      b1ijk=bt1
      return
    endif
    start=15
    ijk=[3,91,61,121]; [3,r,t,p]
    filename=folder+file+'/3d__ful_6_t*_n*_int1000km.dat' ;1deg resolution
    files=file_search(filename)
    nt=n_elements(files)
    bt2=replicate(0.,[ijk,nt])
    bt1=bt2
    for it=0,nt-1 do begin
      bdata=read_ascii(files[it],data_start=start)
      b2=reform(bdata.field1[3:5,*],ijk)
      b1=reform(bdata.field1[6:8,*],ijk)
      bt2[*,*,*,*,it]=b2
      bt1[*,*,*,*,it]=b1
    endfor
    save,bt1,bt2,file=folder+file+'.sav'
  end
endcase

if keyword_set(save) then begin
  bdata=read_ascii(file+'.dat',data_start=start)
  r=bdata.field1[0:2,*]
  b=bdata.field1[3:5,*]
  if mhd eq 1 then save,r,b,file=file+'.sav' else begin
    b1=bdata.field1[6:8,*]
    save,r,b,b1,file=file+'.sav'
  endelse
endif
restore,file+'.sav'
rmars=3396. ;km
time='2017/09/13 03:20:34'
rijk=rmars*reform(r,ijk)
bijk=reform(b,ijk)
if mhd ge 2 then b1ijk=reform(b1,ijk)

if keyword_set(plot) then begin
  b0=bijk-b1ijk ;crustal field
  p=image(transpose(reform(b0[0,5,*,*])),rgb=colortable(70,/reverse),margin=0,min=-100,max=100)
  p=colorbar()
endif

;plot_3dbox,reform(r[0,0:a]),reform(r[1,0:a]),reform(r[2,0:a])
;for i=0,a do p=plot3d(reform(r[0,i]),reform(r[1,i]),reform(r[2,i]),'.',/aspect_r,/aspect_z,/o)

end