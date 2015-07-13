classdef EDDIESDataSource < handle & cws.DataSource% ++++++++++++++++++++++++++++++++++++++++++++++++
  % DATASOURCE class definition
  %
  % CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
  % Copyright 2007-2012 Sandia Corporation.
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
  
  methods % PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    function self = EDDIESDataSource( varargin ) % ------------------- CONSTRUCTOR --
      %DATASOURCE/DATASOURCE constructs a new DATASOURCE Object using the
      %property value paris provided as parameters to the constructor
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'DataSource') || isa(obj,'Connection') || isa(obj,'struct')
          FN = fieldnames(self);
          for iFN = 1:length(FN)
            self.(char(FN(iFN))) = obj.(char(FN(iFN)));
          end
          self.IsConnected = false;
        elseif isa(obj,'char')
          self.conn_id = obj;
        elseif isa(obj,'java.util.LinkedHashMap')
          self.constructFromYAML(obj);
        else
          error('CANARY:datasource:eddies','Unknown construction method: %s',class(self));
        end
      elseif nargin > 1
        args = varargin;
        while ~isempty(args)
          fld = char(args{1});
          val = args{2};
          try
            self.(fld) = val;
          catch ERR
            if DeBug, cws.errTrace(ERR); end
            warning off backtrace
            warning('CANARY:datasource:eddies','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
      % END OF CONSTRUCTOR ----------------------------------------------------
    end
    
    function self = connect(self)
      %CONNECT connect to the web, a database or a file
      %   This function connects an Object to the appropriate network asset, database,
      %   or file to be used by a CanaryInput, CanaryOutput or Messenger Object. This
      %   depends on the value of the CONN_TYPE property of the base Object. The
      %   acceptable values for CONN_TYPE are:
      %
      %       XML     - used to indicate a Connection via a website Connection
      %
      %       JDBC    - used to indicate a database that uses JDBC drivers
      %
      %       FILE    - This is a file Connection or internal stack (Messenger)
      %
      %  See also disconnect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      %
      %  Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      %       if self.IsConnected
      %         warning('CANARY:reconnect','Connection being terminated prior to reConnection');
      %         self.disconnect();
      %       end
      cws.logger('create jdbc connection');
      try
        if self.IsConnected,
          return;
        end
        if ~self.IsRegistered
          self.RegisterDriver();
        end
        if ~isempty(self.driver_datasource_class)
          ds = eval(self.driver_datasource_class);
          ds.setURL(self.conn_url);
          if DeBug,
            fprintf(1,'DEBUG: ds.getURL() => %s\n',char(ds.getURL()))
          end
          if self.conn_interactive && isempty(self.conn_password),
            prompt = {'Username:','Password:'};
            name = ['Login to ',self.conn_id];
            numlines=1;
            defaultanswer={'',''};
            answer = inputdlg(prompt,name,numlines,defaultanswer);
            self.conn_username = answer{1};
            self.conn_password = answer{2};
            user = java.lang.String(self.conn_username);
            pass = java.lang.String(self.conn_password);
            self.ConnID = ds.getConnection(user,pass);
            self.IsConnected = true;
            self.conn_interactive = false;
          else
            user = java.lang.String(self.conn_username);
            pass = java.lang.String(self.conn_password);
            self.ConnID = ds.getConnection(user,pass);
            self.IsConnected = true;
          end
        else
          self.ConnID = java.sql.DriverManager.getConnection(self.conn_url,...
            self.conn_username,self.conn_password);
          self.IsConnected = true;
        end
        cws.logger(sprintf('debug conn id %s',class(self.ConnID)));
        if DeBug,
          fprintf(2,'DEBUG: self.ConnID = %s\n',class(self.ConnID));
          self.ConnID
        end
      catch ERR
        cws.logger('jdbc  error in connection creation');
        if DeBug, cws.errTrace(ERR); end
        prompt = {'Database URL','Username:','Password:'};
        name = ['Login to ',self.conn_id];
        numlines=1;
        defaultanswer={self.conn_url,self.conn_username,self.conn_password};
        if self.conn_interactive && isempty(self.conn_password),
          answer = inputdlg(prompt,name,numlines,defaultanswer);
          self.conn_url = answer{1};
          ds.setURL(self.conn_url);
          self.conn_username = answer{2};
          self.conn_password = answer{3};
        else
          cws.trace('Trying to log in',[self.conn_url,' ',self.conn_username,' ',self.conn_password]);
        end
        ds.setURL(self.conn_url);
        user = java.lang.String(self.conn_username);
        pass = java.lang.String(self.conn_password);
        try
          self.ConnID = ds.getConnection(user,pass);
          self.IsConnected = true;
          self.conn_interactive = false;
        catch ERR
          baseME = MException('CANARY:datasource:eddies','Connection failed for JDBC driver');
          newME = addCause(baseME,ERR);
          cws.errTrace(newME);
          throw(newME);
        end
      end
      % END OF CONNECT --------------------------------------------------------
    end
    
    function self = disconnect( self )
      %DISCONNECT Closes the Connection made previously
      %   disconnects a connected Object and displays any warning messages than may
      %   appear (such as disconnecting an already disconnected Object). This method
      %   may be overloaded in subclasses due to specific needs.
      %
      % See also connect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.IsConnected = false;
      try
        cws.logger('jdbc  disconnect');
        if ~isempty(self.ConnID)
          try
            self.ConnID.close();
          catch ERR
            cws.errTrace(ERR);
            self.ConnID = [];
          end
        end
        if self.IsControl,
          self.IsCtlInit = false;
          self.Isinitialized = false;
          self.dbUpdated = false;
          self.dbUpdateDone = 0;
          self.haveGotData = 0;
        end
        self.CurrMsgID = 0;
        self.messageCenter.NextTxID = 0;
        self.messageCenter.NextRxID = 0;
        self.IsConnected = false;
      catch ERR
        if DeBug, cws.errTrace(ERR); end
        self.IsConnected = false;
        warning('CANARY:datasource:eddies',ERR.message);
      end
      if self.LogFID > 0,
        fprintf(self.LogFID,'Messenger shutdown: "%s"\n',datestr(now(),30));
        fclose(self.LogFID);
        self.LogFID = 0;
      end
      self.Isinitialized = false;
      self.addMessageCS = [];
      self.getMessageCS = [];
      % END OF DISCONNECT -----------------------------------------------------
    end
    
    function self = update( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('start datasource update');
      if ~self.isused, return ; end
      %       if sum(self.isActive) < 1 , return ; end
      %       usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj','Updating data','cont',datestr(now));
      %       disp(usrmsg);
      if ~self.IsInput(), return; end;
      if DeBug,
        st1 = datestr(now(),30);
        fprintf(2,'- update from source: %s\n',self.conn_url);
      end
      self.read_eddies(varargin{:});
      if DeBug,
        st2 = datestr(now(),30);
        fprintf(2,'  update duration:  %s --> %s\n',st1,st2);
      end
      
      % END OF UPDATE ---------------------------------------------------------
    end
    
    function self = postResult( self , idx , LOC , timestep , CDS )
      cws.logger('enter postResult');
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if idx ~= LOC.lastIdxPosted
        [ code , txt ] = self.send_eddies_analysis_result(idx,LOC,timestep);
        if code, disp(txt); end;
        [ code , txt ] = self.send_eddies_parameter_result(idx,LOC,timestep);
        if code, disp(txt); end;
        LOC.lastIdxPosted = idx;
      end
      cws.logger('exit  postResult');
      % END OF POSTRESULT -----------------------------------------------------
    end
    
    function message = read( self )
      %READMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('enter read');
      message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
      if ~self.Isinitialized,
        try
          self.initialize();
        catch ERR
          if DeBug, cws.errTrace(ERR); end
          self.disconnect();
          self.Isinitialized = false;
          self.IsCtlInit = false;
          baseME = MException('CANARY:datasource:eddies:messageReadFailed','Failed to read messages');
          newME = addCause(baseME,ERR);
          throw(newME);
        end
      end
      if ~self.IsConnected,
        try
          self.connect();
        catch ERR
          if DeBug, cws.trace(ERR.stack(1).name,num2str(ERR.stack(1).line)); end
          self.disconnect();
          baseME = MException('CANARY:datasource:eddies:messageReadFailed','Failed to read messages');
          newME = addCause(baseME,ERR);
          throw(newME);
        end
      end
      try
        if DeBug,
          fprintf(2,'DEBUG: self.getMessageCS = %s\n',char(self.getMessageCS.toString()));
        end
        self.getMessageCS.execute();
        self.clear_idle();
        message.to = 'CANARY';
        message.from = char(self.getMessageCS.getString(1));
        message.subj = char(self.getMessageCS.getString(2));
        message.cont = char(self.getMessageCS.getString(3));
        message.number = self.getMessageCS.getInt(4);
        message.date = char(self.getMessageCS.getString(5));
        message.error = char(self.getMessageCS.getString(6));
        if DeBug,
          fprintf(2,'DEBUG: %s %s %s %s %s %s\n',char(self.getMessageCS.getString(1)),...
            char(self.getMessageCS.getString(2)),...
            char(self.getMessageCS.getString(3)),...
            char(self.getMessageCS.getString(4)),...
            char(self.getMessageCS.getString(5)),...
            char(self.getMessageCS.getString(6)));
        end
      catch ERR
        cws.errTrace(ERR);
        baseME = MException('CANARY:datasource:eddies:messageReadFailed','Failed to read messages');
        newME = addCause(baseME,ERR);
        throw(newME);
      end
      if DeBug && ~strcmpi(message.error,'no message found'),
        disp(message);
      elseif DeBug,
        %        fprintf(2,'.');
      end
      if ~strcmpi(message.error,'no message found')
        if self.LogFID > 0,
          fprintf(self.LogFID,'%s\n',char(message));
        else
          self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'at');
          if self.LogFID > 0,
            fprintf(self.LogFID,'%s\n',char(message));
          else
            fprintf(2,'%s\n',char(message));
          end
        end
      end
      if ~isempty(message.error) && ~strcmpi(message.error,'no message found')
        fprintf(2,'%s\n',char(message));
      end
      cws.logger('exit  read');
      % END OF READ -----------------------------------------------------------
    end
    
    function errortext = send( self , message )
      %SENDMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('enter send');
      if ~self.Isinitialized,
        warning('CANARY:datasource:eddies:messengerNotinitialized',...
          'The messenger was not yet initialized when a send requested');
        try
          self.initialize();
        catch ERR
          if DeBug, fprintf(2,'TRACE: %s at %d\n',ERR.stack(1).name,ERR.stack(1).line); end
          baseME = MException('CANARY:datasource:eddies:messageSendFailed','Failed to send messages');
          newME = addCause(baseME,ERR);
          throw(newME);
        end
      end
      if ~isa(message,'cws.Message')
        error('CANARY:datasource:eddies:noMessage','Your message is an invalid Object');
      end
      if ~isempty(message.error),
        fprintf(2,'%s\n',char(message));
      end
      if strcmpi(message.to,'CONTROL'),
        message.to = 'EDDIES';
      end
      self.addMessageCS.setString(1,message.to(1:min(end,99)));
      self.addMessageCS.setString(2,message.subj(1:min(end,99)));
      self.addMessageCS.setString(3,message.cont(1:min(end,999)));
      self.addMessageCS.execute();
      errortext = char(self.addMessageCS.getString(4));
      self.clear_idle();
      message.error = errortext;
      if self.LogFID > 0,
        fprintf(self.LogFID,'%s\n',char(message));
      else
        self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'at');
        if self.LogFID > 0,
          fprintf(self.LogFID,'%s\n',char(message));
        else
          fprintf(2,'%s\n',char(message));
        end
      end
      cws.logger('exit  send');
      % END OF SEND -----------------------------------------------------------
    end
    
    function self = initializeInput( self , varargin )
      %INITIALIZE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Input'); end;
      if ~self.isused,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.input_type),
        self.input_type = self.conn_type;
      end
      try self.initialize_eddies();
      catch InitErr
        if DeBug, cws.errTrace(InitErr); end
        self.IsInpInit = true;
        rethrow(InitErr)
      end
      self.IsInpInit = true;
      % END OF INITIALIZEINPUT ------------------------------------------------
    end
    
    function self = initializeOutput( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Output'); end;
      if ~self.isused || ~self.IsOutput,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.output_type)
        self.output_type = self.conn_type;
      end
      if self.IsOutInit,
        return;
      end
      CallSyntax = 'begin ANALYSIS_RESULT.ADD_RESULT(?, ?, ?, ?, ?, ?, ?); end;';
      self.addResultsCS = self.ConnID.prepareCall(CallSyntax);
      self.addResultsCS.registerOutParameter(7, java.sql.Types.VARCHAR);
      CallSyntax = 'begin PARAMETER_TYPE_RESULT.ADD_RESULT(?, ?, ?, ? , ?); end;';
      self.addParamRsCS = self.ConnID.prepareCall(CallSyntax);
      self.addParamRsCS.registerOutParameter(5, java.sql.Types.VARCHAR);
      self.IsOutInit = true;
      % END OF INITIALIZEOUTPUT -----------------------------------------------
    end
    
    function self = initializeControl( self , varargin )
      %INITIALIZE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('INITIALIZATION','Initializing Control'); end;
      if isempty(varargin),
        locations = [];
      else
        locations = varargin{1};
      end
      if ~self.IsConnected,
        self.connect();
        if ~self.IsConnected,
          ME = MException('CWS:DataSource:Control','Failure to connect during initialization');
          throw(ME);
        end
      end
      if ~self.IsConnected || isempty(self.ConnID),
        self.ConnID
        self.connect();
        if ~self.IsConnected,
          ME = MException('CWS:DataSource:Control','Failure to connect during initialization');
          throw(ME);
        end
      end
      self.getMessageCS = self.ConnID.prepareCall(strcat('begin MESSAGE.GET_MESSAGE(?, ?, ?, ?, ?, ?); end;'));
      self.getMessageCS.registerOutParameter(1, java.sql.Types.VARCHAR);
      self.getMessageCS.registerOutParameter(2, java.sql.Types.VARCHAR);
      self.getMessageCS.registerOutParameter(3, java.sql.Types.VARCHAR);
      self.getMessageCS.registerOutParameter(4, java.sql.Types.DOUBLE);
      self.getMessageCS.registerOutParameter(5, java.sql.Types.DATE);
      self.getMessageCS.registerOutParameter(6, java.sql.Types.VARCHAR);
      self.addMessageCS = self.ConnID.prepareCall(strcat('begin MESSAGE.ADD_MESSAGE(?, ?, ?, ?); end;'));
      self.addMessageCS.registerOutParameter(4, java.sql.Types.VARCHAR);
      self.IsCtlInit = true;
      self.state = 1;
      self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'wt');
      fprintf(self.LogFID,'# Messenger startup: %s\n',datestr(now(),30));
      % END OF INITIALIZECONTROL ----------------------------------------------
    end
    
    % END OF PUBLIC METHODS ===============================================
  end
  
  methods ( Access = 'private' ) % +++++++++++++++++++++++++++++++++++++++
    
    function [ code , txt ] = send_eddies_analysis_result ( self , idx , LOC , ts )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter send_eddies_analysis_result');
      if isempty(self.addResultsCS)
        error('CANARY:datasource:eddies','No ADD_RESULT call defined!');
      end
      code = abs(LOC.algs(end).eventcode(idx,end,end));
      if code == 4, code = 2; end;
      self.addResultsCS.setString(1,'CANARY');
      self.addResultsCS.setString(2,char(LOC));
      if isempty(self.time.current_timestep),
        self.addResultsCS.setString(3,ts);
      else
        self.addResultsCS.setString(3,self.time.current_timestep);
      end
      self.addResultsCS.setString(4,LOC.algs(end).comments{idx});
      self.addResultsCS.setString(5,num2str(code,'%d'));
      self.addResultsCS.setString(6,num2str(LOC.algs(end).eventprob(idx,end,end),'%.5f'));
      try
        self.addResultsCS.execute();
        self.clear_idle();
      catch ERR
        self.IsOutInit = false;
      end
      txt = self.addResultsCS.getString(7);
      if ~isempty(txt),
        msg = cws.Message('to','','from',LOC.name,'subj','EDDIES:','warn',txt);
        fprintf(2,'%s\n',char(msg));
        code = 1;
      else code = 0;
      end
      cws.logger('exit  send_eddies_analysis_result');
      % END OF SEND_EDDIES_ANALYSIS_RESULT ------------------------------------
    end
    
    function [ code , txt ] = send_eddies_parameter_result ( self , idx , LOC , ts )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter send_eddies_parameter_result');
      if isempty(self.addParamRsCS),
        error('CANARY:datasource:eddies','The PARAMETER_TYPE_RESULT is undefined!');
      end
      code = 0; txt = '';
      paramIds = LOC.sigs(abs(LOC.algs(end).event_contrib(idx,:,end))==1);
      if isempty(paramIds), return; end;
      paramTypes = {LOC.sigids{abs(LOC.algs(end).event_contrib(idx,:,end))==1}};
      if isempty(paramTypes), return; end
      self.addParamRsCS.setString(1,'CANARY');
      self.addParamRsCS.setString(2,char(LOC));
      if isempty(self.time.current_timestep)
        self.addParamRsCS.setString(3,ts);
      else
        self.addParamRsCS.setString(3,self.time.current_timestep);
      end
      for iP = 1:length(paramTypes),
        self.addParamRsCS.setString(4,char(paramTypes{iP}));
        self.addParamRsCS.execute();
        txt = self.addParamRsCS.getString(5);
        if ~isempty(txt),
          msg = cws.Message('to','','from',LOC.name,'subj',char(paramTypes{iP}),'warn',txt);
          fprintf(2,'%s\n',char(msg));
          code = 1;
        end
      end
      self.clear_idle();
      cws.logger('exit  send_eddies_parameter_result');
      % END OF SEND_EDDIES_PARAMETER_RESULT
    end
    
    function self = initialize_eddies ( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter initialize_eddies');
      self.input_table = 'ANALYSIS_SAMPLES';
      
      todateFunc = self.conn_toDateFunc;
      if isempty(strfind(todateFunc,'('))
        todateFunc = [todateFunc,'('];
      end
      if isempty(self.sqlDateConvertA),
        self.sqlDateConvertA = todateFunc;
      end
      if isempty(self.sqlDateConvertB),
        self.sqlDateConvertB = ''',';
      end
      if isempty(self.sqlDateConvertC),
        self.sqlDateConvertC = ') ';
      end
      
      self.sqlQueryA = ['SELECT ',self.timestep_field,', PARAMETER_ID, SAMPLE_VALUE, SAMPLE_QUALITY ',...
        'FROM ',self.input_table,' WHERE (',self.timestep_field,' > ', self.sqlDateConvertA ];
      self.sqlQueryB = [ self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC ,...
        ' AND ',self.timestep_field,' <= ', self.sqlDateConvertA ];
      sqlQuery = [self.sqlDateConvertB , self.conn_toDateFmt , self.sqlDateConvertC, ' )',...
        '  ORDER BY ',self.timestep_field,''];
      self.sqlQueryC = sqlQuery;
      cws.logger('exit  initialize_eddies');
    end
    
    function self = read_eddies ( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter read_eddies');
      if nargin < 3,
        error('CANARY:datasource:eddies',...
          'You must supply at least one date when Updating EDDIES Input Objects');
      end
      if strcmpi(self.run_mode,'batch') || strcmpi(self.run_mode,'batch_daily'),
        self.TimeDrift = 0;
      end
      self.get_server_date();
      CDS = varargin{1};
      if nargin < 4,
        stopTime = varargin{2};
        idx = self.time.getDateIdx(varargin{2});
        if idx < 0, return; end;
        idx = max(idx,1);
        if idx > length(CDS.timesteps),
          startTime = self.time.getDateStr(idx-1);
          CDS.timesteps{idx} = stopTime;
        else
          startTime = CDS.timesteps{idx-1};
        end
        idx1 = idx + self.TimeDrift;
        idx0 = idx + self.TimeDrift;
      else
        startTime = varargin{2};
        stopTime = varargin{3};
        idx = self.time.getDateIdx(stopTime);
        idx1 = idx + self.TimeDrift;
        idx0 = self.time.getDateIdx(startTime) + self.TimeDrift;
      end
      CDS.values(idx,1) = 0;
      sqlQuery = [self.sqlQueryA,char(startTime),self.sqlQueryB,char(stopTime),self.sqlQueryC];
      
      if DeBug
        fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
        fprintf(fid,'%s\n',sqlQuery);
        fclose(fid);
      end
      
      cs = self.ConnID.prepareStatement(char(sqlQuery));
      cs.execute();
      self.clear_idle();
      rs = cs.getResultSet();
      recCt = 0;
      prevTS = '';
      prevIDX = 0;
      while rs.next,
        try
          recCt = recCt + 1;
          tstp = char(rs.getString(self.timestep_field));
          par = char(rs.getString('PARAMETER_ID'));
          parNum = strmatch(par,CDS.scadatags,'exact');
          val = rs.getDouble('SAMPLE_VALUE');
          wasNull = false;
          try
            if rs.wasNull()
              wasNull = true;
            end
          catch E
          end
          qty = char(rs.getString('SAMPLE_QUALITY'));
          if strcmpi(qty,'bad'),
            val = nan;
          end
          if strcmpi(tstp,prevTS),
            idx = prevIDX;
          else
            idx = self.time.getDateIdx(tstp,'yyyy-mm-dd HH:MM:SS.FFF') - self.TimeDrift;
            prevIDX = idx;
            prevTS = tstp;
          end
          if isempty(parNum),
            continue;
          end
          if idx < 1, continue; end;
          for pn = 1:length(parNum),
            if CDS.sigtype(parNum(pn)) == 1,
              if ~wasNull,
                CDS.values(idx,parNum(pn)) = val;
              end
            elseif CDS.sigtype(parNum(pn)) == -1,
              va = str2double(CDS.alarmvalue{parNum(pn)});
              if val == va && ~wasNull,
                CDS.values(idx,parNum(pn)) = nan;
              else
                CDS.values(idx,parNum(pn)) = 0;
              end
            elseif CDS.sigtype(parNum(pn)) == 0,
              va = str2double(CDS.alarmvalue{parNum(pn)});
              if val == va && ~wasNull,
                CDS.values(idx,parNum(pn)) = nan;
              else
                CDS.values(idx,parNum(pn)) = 0;
              end
            elseif CDS.sigtype(parNum(pn)) == 2,
              if ~wasNull,
                CDS.values(idx,parNum(pn)) = val;
                CDS.values(idx+1,parNum(pn)) = val;
              end
            else
              CDS.values(idx,parNum(pn)) = val;
            end
          end
        catch DBErr
          if DeBug, cws.errTrace(DBErr); end
          rs.close();
          cs.close();
          rethrow(DBErr)
        end
      end
      rs.close();
      cs.close();
      numRows = recCt;
      self.evalComposites(CDS, idx0, idx1);
      cws.logger('exit  read_eddies');
    end
    
    function self = RegisterDriver( self )
      %REGISTERDRIVER Method to register a JDBC driver, if necessary
      %   This method is somewhat obsolete, since newer JDBC drivers do not use the
      %   DriverManager, but use DataSources instead. The latter is by far the
      %   preferred method to connect to a JDBC database. For files or XML
      %   Connections, it does nothing but set the appropriate flags.
      %
      % See also connect and disconnect
      %
      % Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      switch lower(self.conn_type)
        case {'xml'} % This is an XML Connection
          disp('xml Connections not yet implemented');
        case {'jdbc','db'} % This is a JDBC Connection
          try
            if ~isempty(self.driver_class)
              driver = eval(self.driver_class);
              javaMethod('registerDriver','java.sql.DriverManager',driver);
            end
            self.IsRegistered = true;
          catch CONERR
            cws.errTrace(CONERR);
            self.IsRegistered = false;
            error('CANARY:datasource:eddies:DriverRegFailed','Error registering driver: %s',self.driver_class);
          end
        case {'file'}
          disp('No need to register a file.');
      end
      % END OF REGISTERDRIVER -------------------------------------------------
    end
    
    % END OF PRIVATE METHODS ==================================================
  end
  
  % END OF CLASSDEF DATASOURCE ================================================
end
