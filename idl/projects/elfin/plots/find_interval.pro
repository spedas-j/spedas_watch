pro find_interval,index,istart,iend 


;Procedure looks for intervals of consecutive indices in an index array
;and determines start and end index of each interval.
;INPUT:
;index: index array usually from where function
;KEYWORD:
;dist  - specifies number of entries that separates intervals
;        default is 1
;OUTPUT:
;start: index of first element of an interval
;end  :index of last element of an interval
;to test use index=[0,3,10,11,45,46,47,48,49,40,70]
;v1.0 S.Frey 12-30-03
;            03-20-08 added uniq(sort) NOTE this may change size of index
;            04-07-11 adding keyword dist

if not keyword_set(dist) then dist=1
index=index[uniq(index,sort(index))]
diff=index-shift(index,1)
temp=where(diff gt 1,count)
if count ne 0 then begin
 temp=[0,temp]
 diff2=(temp-shift(temp,1))[1:*]
endif else begin
 temp=0
 diff2=n_elements(index)
endelse
istart=index[temp]
iend=index[temp+diff2-1]
if index[n_elements(index)-1] ge istart[n_elements(istart)-1] and $
   index[n_elements(index)-1] ne iend[n_elements(iend)-1]   then $
   iend=[iend,index[n_elements(index)-1]]

end