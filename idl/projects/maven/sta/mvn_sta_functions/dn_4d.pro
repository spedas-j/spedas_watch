;+
;FUNCTION:	dn_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=mass,m_int=mi,q=q)
;INPUT:	
;	dat:	structure,	3d data structure filled by themis routines get_th?_p???
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;	MASS:	intarr(nm)	optional, 
;PURPOSE:
;	Returns the density array, n, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	13-11-13	
;LAST MODIFICATION:
;-
function dn_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q

density = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, density
endif

dat = conv_units(dat2,"counts")		; initially use counts
dat1 = dat
dat1.data(*)=1.				; make an array with 1 count in each bin
na = dat.nenergy
nb = dat.nbins
nm = dat.nmass

data = dat.data 
data1 = dat1.data 
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass*dat.mass_arr 

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
endif

if keyword_set(mi) then begin
	dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr 
endif else begin
	dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr	; the minus 0.1 helps account for straggling at low mass
endelse

dat.data=data
dat = conv_units(dat,"df")		; Use distribution function
dat1 = conv_units(dat1,"df")		; Use distribution function
data=dat.data
data1=dat1.data

Const = (mass)^(-1.5)*(2.)^(.5)
charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if dat.nbins eq 1 then begin
	ddensity = (total(Const^2*denergy^2*energy*data*data1*2.^2*(cos(theta))^2*(sin(dtheta/2.))^2*dphi^2,1))^.5
endif else begin	
	ddensity = (total(total(Const^2*denergy^2*energy*data*data1*2.^2*(cos(theta))^2*(sin(dtheta/2.))^2*dphi^2,1),1))^.5
endelse	

if keyword_set(ms) then ddensity=total(ddensity)

; units are 1/cm^3

return, ddensity
end
