;+
;NAME: DSC_MISSION_COMPARE_CRIB
;
;DESCRIPTION:
; Crib sheet to demonstrate the setup, plotting, and time shifting
; routines added to support straightforward comparisons of linear 
; data between multiple missions.
;
;CALLING SEQUENCE:
;   .run dsc_mission_compare_crib  OR cut-and-paste relevant portions
;
;NOTES:
;  DSC_MISSION_COMPARE currently supports the default data loads for 
;  the DSCOVR, ACE, and WIND missions.
;  
;  The DSC_SHIFTLINE routine can be used generically, on any previously generated
;  line plot -- not just those plots generated by a DSC_MISSION_COMPARE::Plot call.
;  
;OUTLINE:
; 1) Setup the DSC_MISSION_COMPARE object
;   1.1) Create the Compare Object
;   1.2) Modify Object Values
;     1.2.1) SetAll
;     1.2.2) SetTitle
;     1.2.3) SetMissions
;     1.2.4) SetVars
;     1.2.5) SetVar
;     1.2.6) ClearVar
;     1.2.7) Ordering and Reorder Method
;     1.2.8) Setting Color options
; 2) Plot the Comparison		
; ; include behavior on missing variable; describe combo names created
; 3) Time Shift the Plotted Data (DSC_SHIFTLINE)
;   3.1) Shift String Syntax  
;   ;  One panel (forward/back both lines, one line) ;show cumulative
;   3.2) Shifts on Select Panels and Data Sources
;   3.3) Shifts with DSC_DYPLOT Confidence Intervals
;   3.4) Cleanup DSC_SHIFTLINE Created Variables
;
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/examples/dsc_mission_compare_crib.pro $
;-

;------------------------------------------------------------------------------
; 1) Setup the DSC_MISSION_COMPARE object
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   1.1) Create the Compare Object
;------------------------------------------------------------------------------
; Create a new mission compare object via
; Obj_New('DSC_MISSION_COMPARE',..) or DSC_MISSION_COMPARE(...) syntax

; With element KEYWORDS (m1/m2/vars/title)
; Mission kewords (m1/m2) should regex match one of the supported missions
;   - This describes a comparison of Bx,By,and Np data between
;     the WIND and DSCOVR missions.
;   - The TITLE keyword defines the plot title
compile_opt IDL2
mco = Obj_New("DSC_MISSION_COMPARE",m1='wi',m2='d',vars=['np','bx','by'],title="My New Title")
print,mco,/implied	
stop                

; Will create a default title if none is supplied
; and use default colors if none are supplied
mco = DSC_MISSION_COMPARE(m1='ace',m2='dsc',vars=['b'])
print,mco,/implied
stop

; OR Create the object by passing a structure via the SET= keyword
; - useful if you want to set the variables by toggling structure fields
mc_str = {DSC_MISSION_COMPARE}
print,mc_str,/implied

mc_str.mission1 = 'wi'
mc_str.mission2 = 'ds'
mc_str.bx = 1
mc_str.vphi = 1
print,mc_str,/implied

mco = DSC_MISSION_COMPARE(set=mc_str)	; Will standardize mission names.
print,mco,/implied										; Will NOT create a default title, it maintains
stop																	; the title field found in the passed structure

; Prompts user if a mission is missing/invalid 
; or if no variables are set
stop
mco = DSC_MISSION_COMPARE(title='Values were set interactively')
print,mco,/implied	
stop

; Use the static method FindMTag to see currently
; supported missions
std_names = DSC_MISSION_COMPARE.FindMTag(/all)
foreach name,std_names do print,name
stop


;------------------------------------------------------------------------------
;   1.2) Modify Object Values
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;     1.2.1) SetAll
;------------------------------------------------------------------------------
; Modify all fields of the object by passing a structure

mco = DSC_MISSION_COMPARE(set=mc_str)
st = mco.getall()					;Retrieve structure from existing object 
print,st,/implied					;OR Create structure from scratch
stop											;  st = {DSC_MISSION_COMPARE}	

st.title = 'Comparing DSCOVR and WIND'
st.bx = 0
st.vphi = 0
st.b = 1
st.np = 1
print,st,/implied
stop

mco.setAll,st				; Modified values passed to the object
print,mco,/implied
stop

stop							; Similar to initializing with a structure, will prompt
st.mission1 = ''	; for missing mission/variable settings.
mco.setAll,st     
stop


;------------------------------------------------------------------------------
;     1.2.2) SetTitle
;------------------------------------------------------------------------------
mco.SetTitle,'A New Title'	; Modify title with a scalar string
print,mco,/implied
stop

mco.SetTitle,5430						; Bad arguments leave existing title unchanged
print,mco.getTitle()
stop

mco.SetTitle								; Without argument creates the default title
print,mco,/implied
stop


;------------------------------------------------------------------------------
;     1.2.3) SetMissions
;------------------------------------------------------------------------------
print,'--Creating Object--'
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars='b')
print,mco,/implied

print,'--Modifying Missions--'
mco.SetMissions,'ace','dsc'	; If missions are changed will prompt user
stop												; on whether to update the title

mco.SetMissions,'wind'			; One argument updates mission1
stop

stop												; No arguments prompts user to select from list
mco.SetMissions							
stop


;------------------------------------------------------------------------------
;     1.2.4) SetVars
;------------------------------------------------------------------------------
; Set all comparison variables.
;  - If passed a string (scalar or array) will set these variables
;    as those to be compared and will de-select all others.
mco.setVars,'bx'              ; Now only BX is set
print,mco,/implied
stop

mco.setVars,['v','np','bz']   ; Now only V,NP,BZ are set. BX is cleared
print,mco,/implied
stop

stop								;  If no strings, or bad strings, are passed
mco.setVars					;  an interactive prompt is generated.
print,mco,/implied	
stop

;  - Can pass a {DSC_MISSION_COMPARE} structure as well.
;    Will ignore any title or mission fields set and only
;    modify the variable settings.
st = mco.getall()					;Retrieve structure from existing object 
st.title = 'No change to title if structure passed in SetVars call'
st.bz = 0
st.vphi = 1
st.b = 1
st.np = 0
mco.setVars,st
print,mco,/implied
stop

;------------------------------------------------------------------------------
;     1.2.5) SetVar
;------------------------------------------------------------------------------
; Set one variable to be compared, leaving other variable
; settings intact.
;
mco.setVars,['v','np','bz']   ; Now V,NP,BZ are set. 
print,mco,/implied
stop

mco.setVar,'b'       					; Now NP,BX,BY and B are all set
print,mco,/implied
stop

mco.setVar,'btheta'						; Now NP,BX,BY,B and BTHETA are all set
print,mco,/implied
stop

mco.setVar,/all				; Use the /all keyword to set all variables for comparison
print,mco,/implied
stop

;------------------------------------------------------------------------------
;     1.2.6) ClearVar
;------------------------------------------------------------------------------
; De-selects one variable from the comparison, leaving other
; variable settings intact.
;
mco.setVars,['v','np','bz']   ; Now V,NP,BZ are set.
print,mco,/implied
stop

mco.clearVar,'bz'       			; Now only V and NP are set
print,mco,/implied
stop

mco.clearVar,/all 		; Use the /all keyword to unset all variables
print,mco,/implied
stop


;------------------------------------------------------------------------------
;     1.2.7) Ordering and Reorder Method
;------------------------------------------------------------------------------
;  Reorders the comparison variables.
;  If passed no arguments it will enter an interactive session.
;
;  Order positions are described by 1-indexed positions.
;  (I.e.- the top panel is in position 1, the next panel down in
;   position 2, etc.)

;-- General Ordering Rules
mco.setVars,['v','bz','np','bphi']	; Variables set by array (init or setVars)
stop 																; will be ordered to match the array order.

mco.setVar,'b'					; Variables set one-by-one (setVar or setVars interactively)
mco.setVar,'vtheta'			; are ordered in the order they set.  Using setVar appends the
print,mco.getVars()			; element to the order of previously set variables.
stop

mco.setVar,'b'					; Duplicated variables are ignored.
mco.setVar,'bz'
mco.setVar,'vphi'
print,mco.getVars()
stop

g = {DSC_MISSION_COMPARE}		; Setting variables from a structure (init, setAll, or setVars)
g.v = 1									; will use a default order matching the order of the variable
g.np = 1								; fields in the object UNLESS you expressly modify the ._ORDER
g.b = 1									; property to a valid ordering.
mco.setvars,g
stop

g._order = ptr_new(['v','np','b'])		; Example: Manually set the ORDER field in passed structure
mco.setvars,g
stop
 
;-- Using the Reorder method
mco.setVars,['v','bz','np','bphi']	
mco.reorder,4		; Move 4th item to top spot
stop						;expected> ['bphi','v','bz','np']

mco.reorder,2,3		; Move 2nd item to 3rd position
stop							;expected> ['bphi','bz','v','np']

mco.reorder,'bz'		; Alternately, identify the moving item with a string 
stop								; Move BZ to top
										;expected> ['bz','bphi','v','np']

mco.reorder,'np',2		; Move NP item to 2nd position
stop									;expected> ['bz','np','bphi','v']

mco.reorder,['np','bz','v','bphi']		; Arrange panels to match string array
stop																	;expected> ['np','bz','v','bphi']

mco.reorder,[4,3,2,1]		; Arrange panels to match index array
stop										;expected> ['bphi','v','bz','np']

stop								; Set order interactively by supplying (item,position) pairs.
mco.reorder					; No '' needed around string entries (e.g.: >np,3 moves NP to 3rd pos)
stop								


;------------------------------------------------------------------------------
;     1.2.8) Setting Color Options
;------------------------------------------------------------------------------
; By default, all lines for the Mission1 variables will be plotted in blue and
; those for Mission 2 in black.

; Use the C1= and C2= keywords at initialization to deviate from the default
; WIND all variables red, DSCOVR all variables green
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars=['vx','np','bz'],c1='r',c2='g')
print,mco.getColor(),/implied
stop

; WIND Vx is blue, NP is green, Bz is red; All DSCOVR lines in black
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars=['vx','np','bz'],c1=['b','g','r'])
print,mco.getColor(),/implied
stop

; After creation, use SetColor to modify the color values.
mco.setColor,/help	; Print brief ussage reminder
stop

mco.setColor				; Set all lines to default colors
print,mco.getColor(),/implied
stop

print,mco.getColor(),/implied  ; Retrieve currently set colors as colortable values
stop

mco.setColor,2,'r'	; Set all mission2 lines red
print,mco.getColor(),/implied
stop

mco.setColor,1  		; Set all mission1 lines to default color
print,mco.getColor(),/implied
stop

mco.setColor,1,112	; Use colortable index as well as single character color desination
print,mco.getColor(),/implied
stop

mco.setColor,2,[3,2,1]	; Color argument can be an array if size = number of set variables
print,mco.getColor(),/implied
stop

; Can designate a panel to color by string, or panel index(1-based)
; Array and scalar arguments are accepted
mco.setColor,1,250,'np'				; Set mission1 NP variable line to colortable valued 250	
print,mco.getColor(),/implied	
stop

mco.setColor,2,['r','y'],[1,2] ; Set the Mission2 lines in the 1st and 2nd panels to red and yellow
print,mco.getColor(),/implied
stop


;------------------------------------------------------------------------------
; 2) Plot the Comparison
;------------------------------------------------------------------------------
timespan,0,0
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars=['vx','np','bz'],c1='r',c2='g')
stop			; Plot the described comparison using TPLOT
mco.plot	; - Will prompt to have at least one variable to compare
					; - Will prompt for date/timerange if one has not been previously set
					;   in TPLOT
					; - Loads data into TPLOT as needed
					; - TPLOT functionality remains (e.g.: tlimit, dsc_dyplot, etc.) and
					;   data preferences respected (i.e.: if !dsc.no_download=1 then
					;   only locally hosted data will be available for plots)   

stop
timespan,'2017-01-01'
mco.SetVars,['b','Np','v']
mco.SetMissions,'wind','dsc'
mco.plot
stop

tlimit,'2017-01-01/2:00','2017-01-01/4:00'	; Zoom in
stop

dsc_dyplot			; Show confidence intervals on DSCOVR Faraday Cup data
stop

mconames = tnames('WIND&DSC*') 			; Creates combination tplot variables for each panel 
foreach name,mconames do print,name	; with standard naming convention MISSION1&MISSION2_variable
stop

mco.SetMissions,'ace','wind'	; A panel may not have a comparison if one
mco.SetVars,['b','vx','v']		; mission does not support the given variable
mco.plot											; e.g.: Ace 'vx' not availabe in k0 
stop


;------------------------------------------------------------------------------
; 3) Time Shift the Plotted Data (DSC_SHIFTLINE)
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;   3.1) Shift String Syntax
;------------------------------------------------------------------------------
tlimit,/full
tplot,dsc_ezname('b'),title=''		;Create a simple tplot with loaded data
stop

; Shift a line plot forward or backward in time using DSC_SHIFTLINE and SHIFTSTRING= keyword
;	  * Shift String Format: '#d#h#m#s#ms'
;		* You may leave out unit id strings, but not repeat them:
;		    OK     '3h2m'
;		    NOT OK '3h45m13m'
;		* Numbers must all be positive integers, with the execption of the leading negative.
;		    OK '3d4h23m16s400ms'
;		    OK '-23h'
;		    NOT OK '15h-4m'
;		    NOT OK '15.4m'

dsc_shiftline,shiftstring='30m'	; 30 minutes ahead
stop														; Right side labels are updated to reflect current offset

dsc_shiftline,shift='-3h'		; 3 hours back (from previous. i.e.: total offset now 2.5 hours back)
stop												; Offset is **cumulative**

dsc_shiftline,shift='500s'  ; 500 seconds ahead (from current offset)
stop

dsc_shiftline,shift='2h30m15s'			; 2 hours, 30 minutes, and 15 seconds ahead (from current offset)
stop

dsc_shiftline,shift='-1d3h5000ms'		; 1 day, 3 hours, and 50000 milliseconds back (from current offset)
stop																; N.B.: No additional data is loaded. If shifted timerange
																		;       falls outside the set timespan, no data appears.
 
dsc_shiftline,/reset	; Return line to initial position (i.e.: no offset)
stop


;------------------------------------------------------------------------------
;   3.2) Shifts on Select Panels and Data Sources
;------------------------------------------------------------------------------
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars='vx')	; Create a 1-panel comparison plot
mco.plot
stop

; Shift one or more lines within a TPLOT panel using the VARPATTERN= keyword
dsc_shiftline,varpattern='dsc',shift='2h'	; Only DSCOVR data shifted ahead 2 hours
stop

dsc_shiftline,var='wi',shift='-15m'				; Only WIND data shifted back 15 minutes
stop

dsc_shiftline,shift='-1h30m'	 		; Both lines shifted back 1.5 hours
stop

dsc_shiftline,var='swe',/reset	; N.B.: VARPATTERN keyword uses 
stop 														; REGEX matching on tplot variable names. 


; Create a shift on a subset of panels using the PANEL= keyword
mco.SetVar,'b'		; Create a multi-panel comparison plot
mco.SetVar,'np'
mco.plot
stop

dsc_shiftline,panel=2,shift='15m'						; All data in panel 2, ahead 15 minutes
stop

dsc_shiftline,panel=1,var='wi',shift='-8m'	; WIND data in panel 1, back 8 minutes
stop

dsc_shiftline,panel=[2,3],var='dsc',shift='1h15s'	; DSCOVR data in panels 2 and 3, ahead 1h15s
stop

dsc_shiftline,/reset		; No PANEL keyword => all panels
stop

; Pass ARRAY arguments to VAR= and SHIFT= keywords 
; to correspond with selected panels
dsc_shiftline,panel=[1,3],var='dsc',shift=['8m','-1h']	; DSCOVR data ahead 8 minutes in panel 1
stop																										; DSCOVR data back 1 hour in panel 3

dsc_shiftline,/reset
dsc_shiftline,panel=[2,3],var=['wi','dsc'],shift='10m'	; WIND data ahead 10 minutes in panel 2
stop																										; DSCOVR data ahead 10 minutes in panel 3

dsc_shiftline,/reset
dsc_shiftline,var=['wi','wi','dsc'],shift=['-30m','2h','400m']
stop		; Panel 1 - WIND data back 30 minutes
				; Panel 2 - WIND data ahead 2 hours
				; Panel 3 - DSCOVR data ahead 400 minutes


;------------------------------------------------------------------------------
;   3.3) Shifts with DSC_DYPLOT Confidence Intervals
;------------------------------------------------------------------------------
; Create a plot showing confidence intervals
timespan,'2017-01-01'
mco = DSC_MISSION_COMPARE(m1='wind',m2='dsc',vars=['vx','np','bz'])
mco.plot
tlimit,'2017-01-01/10:00','2017-01-01/12:00'
dsc_dyplot
stop

; Basic call to DSC_SHIFTLINE erases confidence intervals
dsc_shiftline,var='wi',shift='-7m'
stop

; Call with /DSCDY keyword to mimic a no-argument DSC_DYPLOT call
;   i.e.: settings for each variable are read from their tplot data options
dsc_shiftline,/reset
dsc_shiftline,var='wi',shift='-7m',/dscdy
stop

; Use DYINFO= keyword for more complex dsc_dyplot calls
mco.plot
dsc_dyplot,panel=[1,3],/force,new_dyinfo=dyinfo		; Store the dy settings passed in this call
stop																							; In this case: force showing any available
                                                  ;   confidence for panels 1 and 2, not 3

dsc_shiftline,var='wi',shift='-7m',dyinfo=dyinfo		
stop


;------------------------------------------------------------------------------
;   3.4) Cleanup DSC_SHIFTLINE Created Variables
;------------------------------------------------------------------------------
foreach name,tnames() do print,name	; DSC_SHIFTLINE creates combo and single variable 
stop																; containing the string 'SHIFT'

dsc_deletevars,/shift ;Will remove all single and combo-variables containing
stop                  ;'SHIFT' in the name (Not just DSCOVR data.)

foreach name,tnames() do print,name	; DSC_SHIFTLINE creates combo and single variable
stop
END