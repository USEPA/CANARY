%PROCESS_MESSAGE Execute the next command in the command queue
%
% CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
% Copyright 2007-2009 Sandia Corporation.
% This source code is distributed under the LGPL License.
% Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
% the U.S. Government retains certain rights in this software.
%
% This library is free software; you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation; either version 2.1 of the License, or (at
% your option) any later version. This library is distributed in the hope
% that it will be useful, but WITHOUT ANY WARRANTY; without even the
% implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with this library; if not, write to the Free Software Foundation,
% Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
%
% Usage:
%     Status = process_message( obj, event, MessengerObj, SignalsObj, Message)
%
% Example:
%     ret = process_message( [] , [] , MSG , CDS , Msg );
%
function ret = process_message( obj, event, MSG , CDS , data )
  % cws.logger('enter process_message');
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL;
  ret = 1;
  import cws.*
  if ~isempty(MSG.GUIHandle),
    try
      handles = guidata(MSG.GUIHandle);
    catch ERR
      if strcmp(ERR.identifier,'MATLAB:guidata:InvalidInput'),
        HH = canary_gui(data);  %% This is where the GUI is launched
        MSG.GUIHandle = HH;
        handles = guidata(MSG.GUIHandle);
        set(handles.statusText,'String',text);
        set(HH,'Name',['CANARY']);
        drawnow;
      else
        rethrow(ERR);
      end
    end
  else
    HH = canary_gui(data);  %% This is where the GUI is launched
    MSG.GUIHandle = HH;
    handles = guidata(MSG.GUIHandle);
    set(handles.statusText,'String',text);
    set(HH,'Name',['CANARY']);
    drawnow;
  end
  if ~isempty(handles)
    if MSG.IsConnected,
      set(handles.cb_isMessaging,'Value',true);
    else
      set(handles.cb_isMessaging,'Value',false);
    end
    set(handles.cb_isRunning,'Value',true);
  end
  switch lower(MSG.run_mode)
    case {'realtime','real-time','online','on-line'}
      cws.currentTime( obj, event, MSG );
  end
  try
    while ret == 1
      try
        message = MSG.read();
      catch ERR
        if strcmp(ERR.identifier,'xmlmessenger:datamismatch')
          rethrow(ERR)
        end
        fprintf(2,'*** ERROR *** Messenger Failed to Read!');
        disp(ERR.message);
        message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
      end
      response = cws.Message('to','CONTROL','from','CANARY');
      [msg,opt] = strtok(message.subj);
      opt = strtrim(opt);
      val = message.cont;
      if DeBug && ~strcmpi(message.error,'no message found'),
        disp(message);
      end
      % Select and action based on the message
      switch lower(msg)
        
        case {'welcome'}
          set_status(MSG, data, handles,'CANARY has started');
          
        case {'shutdown'}
          set_status(MSG, data, handles,'Shutting down CANARY ...');
          [ret, response] = pm_shutdown(data);
          MSG.send(response);
          MSG.b_done = true;
          fprintf(1,'\n- Shutdown timestamp: %s\n',datestr(now(),30));
          
        case {'start'}
          set_status(MSG, data, handles,['Starting location: ',opt]);
          [ret, response] = pm_start(opt,CDS,data,val);
          set_status(MSG, data, handles,response.subj);
          MSG.send(response);
          
        case {'restart'}
          set_status(MSG, data, handles,['Restarting location: ',opt]);
          [ret, response] = pm_restart(opt,CDS,data);
          set_status(MSG, data, handles,response.subj);
          MSG.send(response);
          
        case {'stop'}
          set_status(MSG, data, handles,['Stopping location: ',opt]);
          [ret, response] = pm_stop(opt,CDS);
          set_status(MSG, data, handles,response.subj);
          MSG.send(response);
          
        case {'timestep'}
          MSG.ClearRcvdNewData();
          [ret, response] = pm_timestep(opt,CDS,data,MSG,val,DeBug);
          set_status(MSG, data, handles,response.subj);
          MSG.send(response);
          
        case {'save'}
          set_status(MSG, data, handles,'Attempting to save data');
          [ret, response] = pm_save(CDS,MSG);
          set_status(MSG, data, handles,response.subj);
          
        case {'clusterize'}
          set_status(MSG, data, handles,'Clusterizing data ...');
          [ret, response] = pm_clusterize(CDS);
          set_status(MSG, data, handles,response.subj);
          
        case {'update'}
          set_status(MSG, data, handles,'Processing update ...');
          [ret, response] = pm_update(CDS,data,val);
          MSG.send(response);
          set_status(MSG, data, handles,response.subj);
          
        case {'postmessage'}
          [ret, response] = pm_post_message(MSG);
          set_status(MSG, data, handles,response.subj);
          
        case {'pause'}
          set_status(MSG, data, handles,'Messenger disconnected ... waiting 10s ...');
          [ ret , msgtxt ] = pm_pause();
          set_status(MSG, data, handles,msgtxt);
          
        otherwise
          set_status(MSG, data, handles,['CANARY is waiting @ ',datestr(now(),30)]);
          pause(0.1);
          cws.verify_connection([],[],MSG);
          ret = 0;
      end
    end
  catch UPDERR
    if strcmp(ERR.identifier,'xmlmessenger:datamismatch')
      rethrow(ERR)
    end
    cws.logger('error process_message');
    set_status(MSG, data, handles,'ERROR in messenger');
    cws.verify_connection([],[],MSG);
    ret = 0;
    cws.errTrace(UPDERR);
  end
  %cws.logger('exit  process_message');
end

function set_status(MSG, data, handles, text)
  if ~isempty(handles),
    try
      set(handles.statusText,'String',text);
      drawnow; 
    catch
      HH = canary_gui(data);  %% This is where the GUI is launched
      MSG.GUIHandle = HH;
      handles = guidata(MSG.GUIHandle);
      set(handles.statusText,'String',text);
      set(HH,'Name','CANARY');
      drawnow;
    end
  end
end

function [ret, response] = pm_start(opt,CDS,data,val)
  cws.logger('enter pm_start');
  response = cws.Message('to','CONTROL','from','CANARY');
  try
    response.subj = ['START ',opt,' COMPLETED'];
    response.cont = '';
    locID = strmatch(opt,{CDS.locations.name},'exact');
    if isempty(locID)
      error('CANARY:startLocation','The location "%s" was not recognized',opt);
    end
    LOC = CDS.locations(locID).handle;
    LOC.updateConfig(CDS,val);
    if ~isempty(CDS.time.date_end),
      nData = CDS.time.getDateIdx(CDS.time.getEndDate);
    else
      nData = 10000;
    end
    LOC.start(nData);
    for iIID = 1:length(LOC.useInputIds) % activate inputs
      uIID = LOC.useInputIds(iIID);
      data.INPUTS(uIID).handle.activate(locID);
    end
    for iOID = 1:length(LOC.useOutputIds) % initialize outputs
      uOID = LOC.useOutputIds(iOID);
      data.OUTPUTS(uOID).handle.initialize_files(LOC,CDS);
    end
    fprintf(1,'- initialize location: \t%s\n',opt);
  catch ERRmsg
    cws.errTrace(ERRmsg);
    response.subj = ['START ',opt,' FAILED'];
    response.cont = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
    cws.logger('error pm_start');
  end
  ret = 1;
  cws.logger('exit  pm_start');
end

function [ret, response] = pm_timestep(opt,CDS,data,MSG,val,DeBug)
  cws.logger('enter pm_timestep');
  response = cws.Message('to','CONTROL','from','CANARY');
  if ~isempty(MSG.GUIHandle),
    try
      handles = guidata(MSG.GUIHandle);
    catch ERR
      if strcmp(ERR.identifier,'MATLAB:guidata:InvalidInput'),
        HH = canary_gui(data);  %% This is where the GUI is launched
        MSG.GUIHandle = HH;
        handles = guidata(MSG.GUIHandle);
        set(handles.statusText,'String',text);
        set(HH,'Name',['CANARY']);
        drawnow;
      else
        rethrow(ERR);
      end
    end
  else
    HH = canary_gui(data);  %% This is where the GUI is launched
    MSG.GUIHandle = HH;
    handles = guidata(MSG.GUIHandle);
    set(handles.statusText,'String',text);
    set(HH,'Name',['CANARY']);
    drawnow;
  end
  try
    if ~isempty(opt), myTxt = ['TIMESTEP ',opt,' PROCESSED'];
    else myTxt = 'TIMESTEP PROCESSED'; end;
    response.subj = myTxt;
    response.cont = val;
    switch (lower(opt))
      case {'start'}
        cws.logger('case  pm_timestep//start');
        CDS.time.set_date_start(val);
        fprintf(1,'\n- Batch Processing\n\n');
        fprintf(1,'- Processing start timestamp: %s\n',datestr(now(),30));
        fprintf(1,'- batch start date time: %s\n',val);
        MSG.IsBatch = true;
      case {'end'}
        cws.logger('case  pm_timestep//end');
        if isempty(val)
          val = datestr(CDS.time.date_end,CDS.time.date_fmt);
          if CDS.time.date_start > CDS.time.date_end,
            response.cont = ['TIMESTEP ',opt,' PROCESSED'];
            error('CANARY:BATCH:startDateAfterEndDate',...
              'The start date specified "%s" is later than the end date specified "%s"',...
              datestr(CDS.time.date_start,CDS.time.date_fmt),val);
          end
        end
        minHistKeep = max([ceil(MSG.ts_to_backfill / CDS.time.date_mult),1]);
        fprintf(1,'  batch stop date time: %s\n',val);
        updStartDate = CDS.time.date_start;
        CDS.time.set_date_end(val);
        updEndDate = CDS.time.date_end;
        FileNameList = {};
        curEndDate = min([updStartDate+minHistKeep-1/CDS.time.date_mult,updEndDate]);
        CDS.time.set_date_end(min([updStartDate+minHistKeep+2,updEndDate]));
        CDS.initialize(true);
        CDS.time.set_date_end(val);
        tsCurMax = CDS.time.getDateIdx(curEndDate);
        tsCurMin = CDS.time.getDateIdx(updStartDate);
        date0 = datestr(updStartDate-1/CDS.time.date_mult,CDS.time.date_fmt);
        date1 = datestr(curEndDate,CDS.time.date_fmt);
        % Update the data
        for iCon = 1:length(data.INPUTS)
          INP = data.INPUTS(iCon).handle;
          fprintf(1,'- update from source: %s\n',INP.conn_url);
          st1 = datestr(now(),30);
          INP.update(CDS,date0,date1);
          st2 = datestr(now(),30);
          fprintf(1,'  update duration:  %s --> %s\n',st1,st2);
        end
        idx2 = max(tsCurMin,1);
        % Evaluate timesteps
        for idx = 1:tsCurMax % Process each remaining data point
          idx2 = CDS.procAlgsAtIdx(idx2,data.OUTPUTS,MSG);
          idx2 = idx2 + 1;
        end
        idx2 = idx2 - 1;
        endDateMsg = CDS.timesteps{idx2};
        nDay = 0;
        tdDay = 0;
        t = toc;
        nDay = nDay + 1;
        tdDay = tdDay + t;
        aveDay = tdDay / nDay;
        nDayRem = updEndDate - curEndDate;
        remMin = aveDay*nDayRem/60;
        msg = cws.Message('from','EDS','to','',...
          'subj',sprintf('Time to process day: %.1f sec; est. remain: %.1f min',t,remMin),...
          'cont',endDateMsg);
        disp(msg);
        tic;
        set_status(MSG, data, handles,sprintf('Time to process day: %.1f sec; est. remain: %.1f min',t,remMin));
        % Process the remaining days
        for curStartDate = updStartDate+minHistKeep:1:updEndDate
          curEndDate = min([curStartDate+1-1/CDS.time.date_mult,updEndDate]);
          tsCurMax = CDS.time.getDateIdx(curEndDate);
          tsCurMin = CDS.time.getDateIdx(curStartDate);
          date0 = datestr(curStartDate-1/CDS.time.date_mult,CDS.time.date_fmt);
          date1 = datestr(curEndDate,CDS.time.date_fmt);
          % Update the data
          for iCon = 1:length(data.INPUTS)
            INP = data.INPUTS(iCon).handle;
            INP.update(CDS,date0,date1);
          end
          idx2 = max(tsCurMin,1);
          % Evaluate timesteps
          for idx = tsCurMin:tsCurMax % Process each remaining data point
            idx2 = CDS.procAlgsAtIdx(idx2,data.OUTPUTS,MSG);
            idx2 = idx2 + 1;  %% CHANGED 2009-AUG-10
          end
          idx2 = idx2 - 1;
          % Do daily shifting
          filename = CDS.saveCurrent(idx2,MSG.data_dir_path);
          if DeBug,
            fprintf(2,'- saving current: %s\n',filename);
          end
          endDateMsg = CDS.timesteps{idx2};
          CDS.shiftDate(-1);
          FileNameList{end+1} = filename; %#ok<AGROW>
          t = toc;
          nDay = nDay + 1;
          tdDay = tdDay + t;
          aveDay = tdDay / nDay;
          nDayRem = updEndDate - curEndDate;
          remMin = aveDay*nDayRem/60;
          msg = cws.Message('from','EDS','to','',...
            'subj',sprintf('Time to process day: %.1f sec; est. remain: %.1f min',t,remMin),...
            'cont',endDateMsg);
          disp(msg);
          set_status(MSG, data, handles,sprintf('Time to process day: %.1f sec; est. remain: %.1f min',t,remMin));
          tic;
        end
        % Combine the temporary files
        try
          CDS.loadFiles(FileNameList);
          if DeBug,
            save(fullfile(MSG.data_dir_path,'batch_save.edsd'),'CDS','-MAT','-V7');
          end
          for fnIdx = 1:length(FileNameList)
            delete(FileNameList{fnIdx});
          end
        catch ERR
          cws.errTrace(ERR);
        end
        
        fprintf(1,'- Processing complete timestamp: %s\n',datestr(now(),30));
      otherwise
        for iCon = 1:length(data.INPUTS) % update data from inputs
          INP = data.INPUTS(iCon).handle;
          if isempty(CDS.time.current_timestep)
            first_idx = CDS.time.getDateIdx(val);
            first_date = CDS.time.getDateStr(first_idx-CDS.time.date_mult,CDS.time.date_fmt);
            if DeBug,
                disp('FIRST DATE')
                disp(first_idx)
                disp(first_date)
            end
            INP.update(CDS,first_date,val);
          end
          if ~strcmpi(INP.input_type,'xml'),
            INP.update(CDS,val);
          end
        end
        CDS.time.current_timestep = val;
        idx = CDS.time.getDateIdx(val);
        if idx == 1,
          fprintf(1,'\n- Online Processing\n\n');
        end
        CDS.procAlgsAtIdx(idx,data.OUTPUTS,MSG);
        CDS.saveContinue(idx,MSG.data_dir_path);
    end
  catch ERRmsg
    cws.logger('error pm_timestep');
    cws.errTrace(ERRmsg);
    if ~isempty(opt), myTxt = ['TIMESTEP ',opt,' FAILED'];
    else myTxt = 'TIMESTEP FAILED'; end;
    response.subj = myTxt;
    response.error = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
  ret = 1;
  cws.logger('exit  pm_timestep');
end

function [ret, response] = pm_restart(opt,CDS,data)
  response = cws.Message('to','CONTROL','from','CANARY');
  try
    fprintf(1,'- RESTART\n');
    response.subj = ['RESTART ',opt,' COMPLETED'];
    response.cont = '';
    locID = strmatch(opt,{CDS.locations.name},'exact');
    if isempty(locID)
      error('CANARY:startLocation','The location "%s" was not recognized',opt);
    end
    LOC = CDS.locations(locID).handle;
    LOC.restart();
    for iIID = 1:length(LOC.useInputIds) % activate inputs
      uIID = LOC.useInputIds(iIID);
      data.INPUTS(uIID).handle.activate(locID);
    end
  catch ERRmsg
    cws.errTrace(ERRmsg);
    response.subj = ['RESTART ',opt,' FAILED'];
    response.cont = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
  ret = 1;
end

function [ret, response] = pm_stop(opt,CDS)
  response = cws.Message('to','CONTROL','from','CANARY');
  try
    response.subj = ['STOP ',opt,' COMPLETED'];
    response.cont = '';
    locID = strmatch(opt,{CDS.locations.name},'exact');
    if isempty(locID)
      error('CANARY:startLocation','The location "%s" was not recognized',opt);
    end
    LOC = CDS.locations(locID).handle;
    LOC.stop();
    %           for iIID = 1:length(LOC.useInputIds) % deactivate inputs
    %             uIID = LOC.useInputIds(iIID);
    %             data.INPUTS(uIID).handle.deactivate(locID);
    %           end
  catch ERRmsg
    cws.errTrace(ERRmsg);
    response.subj = ['STOP ',opt,' FAILED'];
    response.cont = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
  ret = 1;
end

function [ret, response] = pm_shutdown(data)
  response = cws.Message('to','CONTROL','from','CANARY');
  try
    response.subj = 'SHUTDOWN COMPLETED';
    response.cont = '';
    for iCon = 1:length(data.INPUTS)
      INP = data.INPUTS(iCon).handle;
      INP.disconnect;
    end
    for iCon = 1:length(data.OUTPUTS)
      OUT = data.OUTPUTS(iCon).handle;
      OUT.disconnect;
    end
  catch ERRmsg
    cws.errTrace(ERRmsg);
    response.subj = 'SHUTDOWN FAILED';
    response.cont = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
  ret = -1;
end

function [ret, msgtxt] = pm_pause()
  cws.logger(0);
  pause(10);
  ret = 0;
  msgtxt = 'Messenger reconnected';
end

function [ret, response] = pm_clusterize(CDS)
  response = cws.Message('to','CONTROL','from','CANARY');
  for iLoc = 1:length(CDS.locations),
    LOC = CDS.locations(iLoc).handle;
    NAM = CDS.locations(iLoc).name;
    if isempty(CDS.locations(iLoc).handle.algs(end).library)
      MyCluster = cws.ClusterLib;
    else
      MyCluster = CDS.locations(iLoc).handle.algs(end).library;
    end
    prompt={'Please enter the P(event) threshold to use:',...
      'Please enter the cluster window size to use:',...
      'Please enter the regression order to use:',...
      'Please enter the fit level threshold:'};
    name=['Clusterization Options for: ',NAM];
    defaultanswer={num2str(MyCluster.p_thresh),...
      num2str(MyCluster.n_rpts(1)),...
      num2str(MyCluster.r_order(1)),...
      num2str(MyCluster.p_level)};
    answer = inputdlg(prompt,name,1,defaultanswer);
    window_size = str2double(answer{2});
    p_thresh = str2double(answer{1});
    r_order = str2double(answer{3});
    p_level = str2double(answer{4});
    MyCluster.p_thresh = p_thresh;
    MyCluster.n_rpts = window_size;
    MyCluster.r_order = r_order;
    MyCluster.p_level = p_level;
    MyCluster.clusterize(CDS,LOC);
    [filename, pathname] = uiputfile('*.edsc', 'Pick a cluster file');
    save(fullfile(pathname,filename),'MyCluster','-MAT');
  end
  ret = 1;
end

function [ret, response] = pm_save(CDS,MSG)
  response = cws.Message('to','CONTROL','from','CANARY');
  idx = CDS.time.getDateIdx(now());
  CDS.saveCurrent(idx,MSG.data_dir_path,'_manual_save');
  response.subj = ['Saved data: ', MSG.data_dir_path]';
  ret = 1;
end

function [ret, response] = pm_update(CDS,data,val)
  response = cws.Message('to','CONTROL','from','CANARY');
  try
    myTxt = 'UPDATE PROCESSED';
    response.subj = myTxt;
    response.cont = val;
    for iCon = 1:length(data.INPUTS) % update data from inputs
      INP = data.INPUTS(iCon).handle;
      INP.update(CDS,val);
    end
  catch ERRmsg
    cws.errTrace(ERRmsg);
    myTxt = 'UPDATE FAILED';
    response.subj = myTxt;
    response.error = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
  ret = 1;
end

function [ret, response] = pm_post_message(MSG)
  response = cws.Message('to','CONTROL','from','CANARY');
  ret = 1;
  try
    MSG.post();
  catch ERRmsg
    cws.errTrace(ERRmsg);
    myTxt = 'POST FAILED';
    response.subj = myTxt;
    response.error = ERRmsg.message;
    fprintf(2,'%s\n',char(response));
  end
end

% function [ret, response] = pm_boilerplate(opt,CDS,data,MSG,val)
%   response = cws.Message('to','CONTROL','from','CANARY');
%   ret = 1;
% end
