;+
; NAME: SPP EVA
;
; PURPOSE: burst-trigger management tool for SPP
;
; CALLING SEQUENCE: Type in 'SPPEVA' into the IDL console and hit return.
;
; CREATED BY: Mitsuo Oka   Sep 2018
;
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-07-16 11:34:01 -0700 (Thu, 16 Jul 2015) $
; $LastChangedRevision: 18152 $
; $URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/eva.pro $
;-


PRO sppeva_event, event
  @tplot_com
  compile_opt idl2
  widget_control, event.top, GET_UVALUE=wid


  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message,/reset
    return
  endif

  exitcode = 0
  case event.id of
    wid.base        : if strmatch(tag_names(event,/structure_name),'WIDGET_KILL_REQUEST') then exitcode=1
    wid.exit        : exitcode = 1
    wid.mnPref      : begin
      sppeva_pref, GROUP_LEADER = event.top
      end
    wid.mnHelp_about:begin
      msg = ['##### SPP EVA #####',' ']
      vrs = spd_read_current_version()
      if size(vrs,/type) ne 7 then begin
        msg = [msg, 'Your SPEDAS version: N/A',' ']
        msg = [msg, 'The SPEDAS version will be displayed if called from ']
        msg = [msg, 'a copy of the bleeding-edge zip instead of svn repo.']
      endif else begin
        msg = [msg, 'Your SPEDAS version: '+ v]
      endelse
      msg = [msg, ' ', 'Created by Mitsuo Oka at UC Berkeley']
      answer=dialog_message(msg,/info,/center)
      end
    else:
  endcase

  if exitcode then begin
    tplot_options,'base',-1
    obj_destroy, obj_valid()
    tn=tnames('*',ct)
    ;if ct gt 0 then del_data,'*'
    widget_control, event.top, /DESTROY
    if (!d.flags and 256) ne 0  then begin    ; windowing devices
      str_element,tplot_vars,'options.window',!d.window,/add_replace
      str_element,tplot_vars,'settings.window',!d.window,/add_replace
    endif
  endif else begin
    widget_control, event.top, SET_UVALUE=wid
  endelse
END

PRO sppeva
  compile_opt idl2
  
  ;////////// INITIALIZE /////////////////////////////////
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif

  If(xregistered('sppeva') ne 0) then begin
    message, /info, 'You are already running SPP_EVA.'
    answer = dialog_message('You are already running SPP_EVA.',title='SPP_EVA',/center)
    return
  endif

  if !VERSION.RELEASE lt 8.4 then begin
    answer = dialog_message("You need IDL version 8.4 or higher for SPP_EVA",/center)
    return
  endif

  !EXCEPT = 0; stop reporting of floating point errors

  spd_graphics_config,colortable=colortable
  
  ;////////// WIDGET LAYOUT /////////////////////////////////

  scr_dim    = get_screen_size()
  xoffset = 0;scr_dim[0]*0.3 > 0.;-650.-286-50. > 0.

  ;------------------
  ; System Variable
  ;------------------
  user_name = (get_login_info()).USER_NAME
  user = {id:user_name, fullname:user_name, $
    email:'N/A', team:'N/A'}
  fild = {sppfldsoc_id:'',sppfldsoc_pw:'',FLD_LOCAL_DATA_DIR:'./'}
  gene = {fom_max_value:25, basepos:0, split_size_in_sec:600, ROOT_DATA_DIR:''}
  dash = {widget:0}
  stack = {fld_i:0L, fld_list:list({Nsegs:0L}), swp_i:0L, swp_list:list({Nsegs:0L})}
  com   = {mode:'FLD', strTR:['',''], parameterset:'01_WIND_basic.txt', commDay:'5',$
    user_name:user_name, $
    fieldPTR:'spp_fld_f1_100bps_DCB_ARCWRPTR',$
    sweapPTR:'psp_swp_swem_dig_hkp_SW_SSRWRADDR'}
  def_struct = {user:user, gene:gene, fild:fild, dash:dash, com:com, stack:stack}
  defsysv,'!sppeva',exists=exists
  if not exists then begin
    defsysv,'!sppeva', def_struct
  endif
  
  ;--------------------------
  ; Import Saved Preferences
  ;--------------------------
  fname = 'sppeva_setting.sav'
  found = file_test(fname)
  if found then begin
    restore, fname
    sppeva_pref_import, 'USER', sppeva_user_values
    sppeva_pref_import, 'GENE', sppeva_gene_values
    sppeva_pref_import, 'FILD', sppeva_fild_values
  endif
  
  info = get_login_info()
  !SPPEVA.USER.ID = info.USER_NAME
  
  ;---------------------
  ; ID & PW for FIELDS
  ;---------------------
;  a = getenv('FIELDS_USER_PASS')
;  if strlen(a) eq 0 then begin
;    setenv,'FIELDS_USER_PASS='+!SPPEVA.FILD.SPPFLDSOC_ID+':'+!SPPEVA.FILD.SPPFLDSOC_PW
;  endif
  a = getenv('PSP_STAGING_ID')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.FILD.SPPFLDSOC_ID) ne 0) then begin
    setenv,'PSP_STAGING_ID='+!SPPEVA.FILD.SPPFLDSOC_ID
  endif
  a = getenv('PSP_STAGING_PW')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.FILD.SPPFLDSOC_PW) ne 0) then begin
    setenv,'PSP_STAGING_PW='+!SPPEVA.FILD.SPPFLDSOC_PW
  endif
  a = getenv('ROOT_DATA_DIR')
  if (strlen(a) eq 0) and (strlen(!SPPEVA.GENE.ROOT_DATA_DIR) ne 0) then begin
    setenv,'ROOT_DATA_DIR='+!SPPEVA.GENE.ROOT_DATA_DIR
  endif
  
  ;
;  if strlen(getenv('SPP_USER_PASS')) eq 0 then begin
;    setenv,'SPP_USER_PASS='+!SPPEVA.FILD.SPPFLDSOC_ID+':'+!SPPEVA.FILD.SPPFLDSOC_PW
;  endif
  
  
;  if compare_struct(def_struct.user, !SPPEVA.USER) then begin
;    msg = 'EVA suggests you to update your user profile'
;    msg = [msg, 'in the Preference menu so that your info']
;    msg = [msg, 'will be properly included in your selection report.']
;    msg = [msg, 'This needs to be done only once.']
;    result = dialog_message(msg,/center)
;  endif
  
  ;----------------
  ; Top Level Base
  ;----------------
  base = widget_base(TITLE = 'SPP_EVA',MBAR=mbar,_extra=_extra,/column,$
    XOFFSET=xoffset, YOFFSET=0,TLB_KILL_REQUEST_EVENTS=1,space=7)
  str_element,/add,wid,'base',base

  ;-----------------
  ; menu
  ;-----------------
  mnFile = widget_button(mbar, VALUE='File', /menu)
  str_element,/add,wid,'mnPref',widget_button(mnFile,VALUE='Preference')
  str_element,/add,wid,'exit',widget_button(mnFile,VALUE='Exit',/separator)
  mnHelp = widget_button(mbar, VALUE='Help',/menu)
  str_element,/add,wid,'mnHelp_about',widget_button(mnHelp,VALUE='About SPP_EVA')

  ;-----------------
  ;  MAIN PANEL
  ;-----------------
  str_element,/add,wid,'spp_data',sppeva_data(base);,xsize=cpwdith); DATA MODULE
  str_element,/add,wid,'spp_dash',sppeva_dash(base);
  str_element,/add,wid,'spp_sitl',sppeva_sitl(base);,xsize=cpwdith); SITL MODULE
    
  ;--------------
  ; REALIZE
  ;--------------
  
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid
  xmanager, 'sppeva', base, /no_block;, GROUP_LEADER=group_leader
  
  ;--------------
  ; DASHBOARD
  ;--------------
  sppeva_dash_activate
END
