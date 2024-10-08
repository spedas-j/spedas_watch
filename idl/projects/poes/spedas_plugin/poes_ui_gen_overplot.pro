;+
; NAME:
;  poes_ui_gen_overplot
;
; PURPOSE:
;  Widget wrapper for poes_overview_plot used to create POES overview plots in the GUI
;
; CALLING SEQUENCE:
;  success = poes_ui_gen_overplot(gui_id, historyWin, oplot_calls, callSequence,$
;                                windowStorage,windowMenus,loadedData,drawObject)
;
; INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  oplot_calls:  The number calls to poes_ui_gen_overplot
;  callSequence: object that stores sequence of procedure calls that was used to load data
;  windowStorage: standard windowStorage object
;  windowMenus: standard menu object
;  loadedData: standard loadedData object
;  drawObject: standard drawObject object
;  
;
; OUTPUT:
;  none
;  
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 13:45:18 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30651 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/spedas_plugin/poes_ui_gen_overplot.pro $
;-

pro poes_ui_gen_overplot_event, event

  Compile_Opt hidden
 
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating POES overview plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate POES overview plot widget killed' 
    state.historyWin->Update,'POES_UI_GEN_OVERPLOT: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'POES_UI_GEN_OVERPLOT: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'GOWEB': BEGIN
      timeid = widget_info(event.top, find_by_uname='time')
      widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      if valid then begin
        state.tr_obj->getproperty, starttime=starttime, endtime=endtime
        starttime->getproperty, year=year, month=month, date=date
        probet = state.probe
        ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.
        url = "http://themis.ssl.berkeley.edu/summary.php?bigvar=" + string(year, format='(I04)') + "___" + string(month, format='(I02)') + "___" + string(date, format='(I02)') + "___0024___poes___poes" + probet
        spd_ui_open_url, url
      endif else begin
        ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
          /center)   
      endelse


     end
     
    'APPLY': BEGIN
    ; Check whether times set in widget are valid
    timeid = widget_info(event.top, find_by_uname='time')
    widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
    if valid then begin
      state.tr_obj->getproperty, starttime=starttime, endtime=endtime
      starttime->getproperty, tdouble=st_double
      endtime->getproperty, tdouble=et_double
      dur = (et_double - st_double) / 86400
      if dur le 0 then begin
        etxt = 'End time is earlier than start time.'
        ok = dialog_message(etxt,title='Error in Generate Overview Plot', /center, information=1)
        
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif
       
      widget_control, /hourglass
      
      if ~state.windowStorage->add(isactive=1) then begin
        ok = spd_ui_prompt_widget(state.tlb,state.statusbar,state.tlb,prompt='Error initializing new window for generating POES overview plots.', $
               title='Error in POES overview plot',/traceback, frame_attr=8)
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif  
      
      activeWindow = state.windowStorage->GetActive()
    
      tplot_options, title=strupcase(string(state.probe))+' Overview ('+time_string(st_double)+')'

      state.statusBar->Update,'Generating POES overview plot. Please wait!...'
      poes_overview_plot, date = st_double, probe = state.probe, duration = dur, /gui_overplot, $
                          oplot_calls = (*state.data).oplot_calls, error = error
      
      if ~error then begin
        
        ;add to call sequence
        state.callSequence->addPluginCall, 'poes_overview_plot', $
          date = st_double, probe = state.probe, duration = dur, $
          gui_overplot=1, oplot_calls = (*state.data).oplot_calls, track_one=1b, $
          import_only=1 ;when replaying overviews, we only want it to import data, since the window/panel structure is already serialized xml tgd document
        
        ; update the size of the labels       
        activeWindow->GetProperty, panels = panelsObj
        panels = panelsObj->get(/all)
      
        ; loop through the panels setting the label options
        for i = 0,n_elements(panels)-1 do begin
            panels[i]->getProperty,yaxis=yobj
            yobj->setProperty, stackLabels = 1, orientation = 0 
            yobj->getProperty, labels = ylbls
            if obj_valid(ylbls) then begin
                lobj = ylbls->get(/all)
                for j = 0, n_elements(lobj)-1 do begin
                    lobj[j]->setProperty, size=10.0
                endfor
            endif
        endfor

        (*state.data).oplot_calls = (*state.data).oplot_calls + 1 ; update # of calls to overplot
        (*state.data).track_one = 1b
        
        msg = 'POES overview plot completed.'
      endif else begin
        msg = 'Error generating POES everview plot.'
      endelse
      state.statusBar->Update, msg
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      return
    endif else ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
                                   /center)
    END
    'CANC': BEGIN
      state.historyWin->update,'Generate POES overview plot canceled',/dontshow
      state.statusBar->Update,'Generate POES overview plot canceled.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'KEY': begin
      spd_ui_overplot_key, state.gui_id, state.historyWin, /modal, poes=1
    end
    ; follows the same format as for SPEDAS overview plots
    'PROBE:01': state.probe='metop1'
    'PROBE:02': state.probe='metop2'
    'PROBE:15': state.probe='noaa15'
    'PROBE:16': state.probe='noaa16'
    'PROBE:18': state.probe='noaa18'
    'PROBE:19': state.probe='noaa19'
    'TIME': ; don't send 'Not yet implemented' to the console for time events
    ELSE: dprint,  'Not yet implemented'
  ENDCASE
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


pro poes_ui_gen_overplot, gui_id = gui_id, $
                          history_window = historyWin, $
                          status_bar = statusbar, $
                          call_sequence = callSequence, $
                          time_range = tr_obj, $
                          window_storage = windowStorage, $
                          loaded_data = loadedData, $
                          data_structure = data_structure, $
                          _extra = _extra

  compile_opt idl2


  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Begin
      print, err_msg[j]
      If(obj_valid(historywin)) Then historyWin -> update, err_msg[j]
    Endfor
    Print, 'Error--See history'
    ok = error_message('An unknown error occured starting widget to generate POES overview plot. ', $
         'See console for details.', /noname, /center, title='Error while generating POES overview plot')
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  
  tlb = widget_base(/col, title='Generate POES Overview Plot', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    probeBase = widget_base(mainBase, row=1, /align_center)
     probeLabel = widget_label(probeBase, value='Probe:  ', /align_left)
      probeButtonBase = widget_base(probeBase, row=2, /align_left, /exclusive)
    midBase = widget_base(mainBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, Frame=1, xpad=8)
      keyButtonBase = widget_button(midBase, Value='Plot Key', UValue='KEY', $
                                    tooltip = 'Displays detailed descriptions of POES overview plot panels.')
    goWebBase = Widget_Base(mainBase, /Row, Frame=1, xpad=8)
    buttonBase = Widget_Base(mainBase, /row, /align_center)
    goWebLabel = widget_label(goWebBase, Value='  Alternatively, you can view the plot on the web (single day).  ', /align_left)
    goWebButton = Widget_Button(goWebBase, Value='  Web Plot  ', UValue='GOWEB')
    

; Help text
  wj = widget_label(txtbase, value='Creating the overview plot might take a few minutes.', /align_left)

; Probe selection widgets
  Button01 = widget_button(probeButtonBase, value='MetOp 1', uvalue='PROBE:01')
  Button02 = widget_button(probeButtonBase, value='MetOp 2', uvalue='PROBE:02')
  Button15 = widget_button(probeButtonBase, value='NOAA 15', uvalue='PROBE:15')
  Button16 = widget_button(probeButtonBase, value='NOAA 16', uvalue='PROBE:16')
  Button18 = widget_button(probeButtonBase, value='NOAA 18', uvalue='PROBE:18')
  Button19 = widget_button(probeButtonBase, value='NOAA 19', uvalue='PROBE:19')
  
  widget_control, Button19, /set_button
  probe='noaa19'

; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  if ~obj_valid(tr_obj) then begin
    st_text = '2013-03-23/00:00:00.0'
    et_text = '2013-03-24/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif


  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time', startyear = 2000);, oneday=1 
  

; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='Apply', UValue='APPLY')
  cancelButton = Widget_Button(buttonBase, Value='Cancel', UValue='CANC')

  ;flag denoting successful run
  success = 0

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif

  data_ptr = ptr_new(data_structure)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           tr_obj:tr_obj, probe:probe,success:ptr_new(success), $
           data:data_ptr, $
           callSequence:callSequence,windowStorage:windowStorage,$
           loadedData:loadedData}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'poes_ui_gen_overplot', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  RETURN
end
