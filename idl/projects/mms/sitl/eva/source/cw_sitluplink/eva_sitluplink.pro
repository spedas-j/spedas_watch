PRO eva_sitluplink_updateFOM, state
  compile_opt idl2

  if state.Evalstarttime eq 'N/A' then return
  
  tn=tnames('mms_stlm_fomstr',ct)
  if(ct eq 1) then begin
    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
    s = lim.UNIX_FOMSTR_MOD
    str_element,/add, s, 'uplinkflag', state.Uplink
    str_element,/add, s, 'evalstarttime', time_double(state.Evalstarttime)
  endif
  options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
END

FUNCTION eva_sitluplink_updateState, state, str_time, uplink
  compile_opt idl2
  
  ;---------------
  ; State
  ;---------------
  ;time = (str_time eq 'N/A') ? 0.d0 : time_double(str_time)

  str_element,/add,state,'EvalStartTime',str_time; put tstring into state structure
  ;str_element,/add,state,'EvalStartTimeDouble',time
  widget_control, state.fldEvalStartTime, SET_VALUE=str_time; update GUI field
 
  str_element,/add,state,'Uplink',uplink
  
  ;---------------
  ; Display in "SITL" tab
  ;---------------
  strUplink = (state.Uplink eq 1) ? 'Yes' : 'No'
  id_sitl = widget_info(state.parent, find_by_uname='eva_sitl')
  sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
  WIDGET_CONTROL, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY
  widget_control, sitl_state.lblEvalStartTime, SET_VALUE='Next SITL Window Start Time: '+str_time
  widget_control, sitl_state.lblUplink, SET_VALUE='Uplink - '+strUplink
  WIDGET_CONTROL, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY
  
  return, state
END

PRO eva_sitluplink_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  if n_tags(value) eq 0 then begin
    eva_sitl_update_board, state, value
  endif else begin
    str_element,/add,state,'pref',value
  endelse
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitluplink_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitluplink_event, ev
  compile_opt idl2
  @xtplot_com.pro
  @tplot_com

  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    message, /reset
    return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif

  update=0
  
  case ev.id of
    state.fldEvalStartTime: begin
      widget_control, ev.id, GET_VALUE=new_time;get new time
      str_element,/add,state,'EvalStartTime',new_time
      update=1
    end
    state.calEvalStartTime: begin
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=state.EvalStartTime
      spd_ui_calendar,'EVA Calendar',otime,ev.top
      otime->GetProperty,tstring=tstring         ; get tstring
      state = eva_sitluplink_updateState(state, tstring, state.Uplink)
      obj_destroy, otime
      timebar,time_double(tstring), linestyle = 2, thick = 2;,/transient
      update=1
    end
    state.btnEvalStartTime: begin
      ctime,time,y,z,npoints=1
      timebar,time, linestyle = 2, thick = 2;,/transient
      state = eva_sitluplink_updateState(state, time_string(time), state.Uplink)
      update=1
    end
    state.btnDraw: begin
      widget_control, state.fldEvalStartTime, GET_VALUE=time; update GUI field
      timebar,time, linestyle = 2, thick = 2
    end
    state.btnErase: begin
      tplot
      ;widget_control, state.fldEvalStartTime, GET_VALUE=time; update GUI field
      ;timebar,state.EvalStartTimeDouble, linestyle = 2, thick = 2,/transient
      ;timebar,state.EvalStartTimeDouble, linestyle = 2, thick = 2,/transient
    end
    state.btnReset: begin
      state = eva_sitluplink_updateState(state, 'N/A', 0)
      widget_control,state.bgUplink,SET_VALUE=0
      tplot
      update=1
    end
    state.bgUplink: begin
      widget_control,state.bgUplink,GET_VALUE=gvl
      if (gvl eq 1) and (state.EvalStartTime eq 'N/A') then begin
        result = dialog_message("Please set start time first.",/center)
        gvl = 0
        widget_control,state.bgUplink,SET_VALUE=0
        update=0
      endif
      state = eva_sitluplink_updateState(state, state.EvalStartTime, gvl)
      if ev.SELECT eq 0 then update = 1
      end
    else:
  endcase

  if update then begin
    eva_sitluplink_updateFOM, state
    
    ;--------------------
    ; Validation by Rick
    ;--------------------
    tn=tnames('mms_stlm_fomstr',ct)
    if(ct gt 0)then begin
      get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
      s = lim.UNIX_FOMSTR_MOD
      r = eva_sitluplink_validateFOM(s)
      if(r gt 0) then begin
        state = eva_sitluplink_updateState(state, 'N/A', 0)
        widget_control,state.bgUplink,SET_VALUE=0
        tplot
        str_element,/delete,s,'EVALSTARTTIME'
        options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
      endif
    endif
  endif


  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitluplink, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  compile_opt idl2

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'

  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitluplink'
  if not (keyword_set(title)) then title='   UPLINK   '

  ; ----- STATE -----
  state = {$
    parent:parent,$
    EvalStartTime: 'N/A',$
    EvalStopTime: 'N/A',$
    EvalStartTimeDouble: 0.d0,$
    Uplink: 0}

  ; ----- CONFIG (READ) -----
  cfg = mms_config_read()         ; Read config file and
  pref = mms_config_push(cfg,pref); push the values into preferences
  str_element,/add,state,'pref',pref

  ; ----- SETTINGS ------
  ;//////////////////////////////
  valUplinkflag = !VALUES.F_NAN
  valEvalstarttime = 'N/A'
  ;//////////////////////////////
  tn = tnames()
  idx=where(tn eq 'mms_soca_fomstr',ct)
  if(ct eq 1) then begin
    get_data,'mms_soca_fomstr',dl=dl,lim=lim
    s = lim.UNIX_FOMSTR_ORG
    tgn = tag_names(s)
    idxA=where(strlowcase(tgn) eq 'uplinkflag',ctA)
    idxB=where(strlowcase(tgn) eq 'evalstarttime',ctB)
    valUplinkflag = (ctA eq 1) ? s.UPLINKFLAG : valUplinkflag
    valEvalstarttime  = (ctB eq 1) ? s.EVALSTARTTIME : valEvalstarttime
  endif


  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  
  ; calendar icon
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, parent, cal; thm_ui_match_background

  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitluplink_event", $
    FUNC_GET_VALUE = "eva_sitluplink_get_value", $
    PRO_SET_VALUE = "eva_sitluplink_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1, SPACE=0, YPAD=0)
  str_element,/add,state,'mainbase',mainbase

  subbase = widget_base(mainbase,/column,sensitive=0)
  str_element,/add,state,'subbase',subbase
  
    str_element,/add,state,'lblDummy1',widget_label(subbase,VALUE=' ')
    
    str_element,/add,state,'lblABS',widget_label(subbase,VALUE='Settings in ABS:')
    bsABS = widget_base(subbase, /COLUMN, SPACE=0, YPAD=0,/frame,xsize=xsize*0.94)
      str_element,/add,state,'lblABS_tstart',widget_label(bsABS,VALUE='EVAL START TIME: '+strtrim(string(valUplinkflag),2),/align_left)
      str_element,/add,state,'lblABS_uplink',widget_label(bsABS,VALUE='UPLINK FLAG: '+valEvalstarttime,/align_left)

    str_element,/add,state,'lblDummy2',widget_label(subbase,VALUE=' ')
    
    str_element,/add,state,'lblFOM',widget_label(subbase,VALUE='Settings to be submitted:')
    bsFOM = widget_base(subbase, /COLUMN, SPACE=0, YPAD=0,/frame,xsize=xsize*0.94,/align_center)
      lblEvalStartTime = widget_label(bsFOM,VALUE='Next SITL Window Start Time',/align_left)
      bsEvalStartTime = widget_base(bsFOM,/row, SPACE=0, YPAD=0)
        str_element,/add,state,'fldEvalStartTime',cw_field(bsEvalStartTime,VALUE=valEvalstarttime,TITLE='',/ALL_EVENTS,XSIZE=24)
        str_element,/add,state,'calEvalStartTime',widget_button(bsEvalStartTime,VALUE=cal)
        str_element,/add,state,'btnEvalStartTime',widget_button(bsEvalStartTime,VALUE=' Cursor ')
      bsReset = widget_base(bsFOM,/row, SPACE=0, YPAD=0,/align_center)
        str_element,/add,state,'btnDraw',widget_button(bsReset,VALUE=' Draw ');,xsize=150)
        lblReset1 = widget_label(bsReset,VALUE=' ')
        str_element,/add,state,'btnErase',widget_button(bsReset,VALUE=' Refresh ');,xsize=150)
        lblReset2 = widget_label(bsReset,VALUE='     ')
        str_element,/add,state,'btnReset',widget_button(bsReset,VALUE=' Reset ');,xsize=150)
      lblUplink = widget_label(bsFOM,VALUE='Uplink',/align_left)
      bsUplink = widget_base(bsFOM,/row, SPACE=0, YPAD=0)
        lblUplinkDummy = widget_label(bsUplink,VALUE='   ',/align_left)
        str_element,/add,state,'bgUplink',cw_bgroup(bsUplink,['No','Yes'],$
          EXCLUSIVE=1,SET_VALUE=0,COLUMN=2)
  

  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END
