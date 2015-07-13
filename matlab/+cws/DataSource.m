classdef DataSource < handle % ++++++++++++++++++++++++++++++++++++++++++++
  % DATASOURCE class definition
  %
  % The DATASOURCE class is no longer an object class; it is not serving
  % the purpose of an _abstract_ class instead. Pelase subclass DataSource
  % into the proper type of class you need.
  %
  % See also: XMLDataSource, MSGRDataSource, CSVDataSource, JDBCDataSource
  %
  % Copyright 2007-2012 Sandia Corporation.
  
  % priv, pub
  properties ( SetAccess = 'public' , GetAccess = 'public' ) % ++++++++++++
    IsConnected = false;
    IsRegistered = false;
    Isinitialized = false;
    IsInput = false;
    IsOutput = false;
    IsControl = false;
    CurrMsgID = 0
    OutputQueue = []
    RecievedQueue = []
    SentQueue = []
    ControlQueue = []
    messageCenter = cws.MessageCenter();
    IdleCount = 0;
    LastDateTimeSeen = '';
    RcvdNewData = false;
    AverageDataProcessingDelay = 20;
    IsWaiting = false;
    msgs_clear = false;
    clear_delay = 2;
    configuration
    
    IsInpInit = false;
    IsOutInit = false;
    IsCtlInit = false;
    ConnID
    
    % Input Uses
    isused = false;
    isActive = false;
    input_fields = {};
    
    % Messenger Uses
    addMessageCS
    getMessageCS
    inputStrm
    outputStrm
    sockAddr
    dbUpdated = false;
    dbUpdateDone = 0;
    LogFID
    queue
    extraMessage = '';
    fileCache
    
    % Output Uses
    addResultsCS
    addParamRsCS
    sqlCreate
    sqlA
    haveGotData = 0;
    
    sqlDateConvertA = '';
    sqlDateConvertB = '';
    sqlDateConvertC = '';
    sqlDateDatatype = 'DATETIME';
    
    tableFldIDs = [];
    tableParNum = [];
    
    conn_id = 'NEWCONN';
    conn_id_num = 0;
    conn_type = '';
    conn_url = '';
    canaryID = 'CANARY';
    driver_config = '';
    driver_class = '';
    driver_datasource_class = '';
    conn_instance = '';
    conn_ipaddress = '';
    conn_port = 0;
    conn_username = '';
    conn_password = '';
    conn_interactive = false;
    conn_toDateFunc = '';
    conn_toDateFmt = '';
    time
    log_path = '';
    data_dir_path = '';
    run_mode = '';
    GUIHandle
    state = 0;
    data_to_send = 0;
    ts_to_backfill = 0;
    conn_state = 'enabled';
    use_continue = false;
    
    % Messenger Specific
    msgr_type = '';
    b_done = false;
    cur_ts = 0;
    TimeDrift = 0;
    data_done = 0;
    
    % Input Specific
    input_id = '';
    input_type = '';
    input_format = '';
    input_table = 'CWS_INPUT';
    timestep_field = 'TIME_STEP';
    sqlQueryA= '';
    sqlQueryAA= '';
    sqlQueryB= '';
    sqlQueryC= '';
    sqlQueryD1= '';
    sqlQueryD2= '';
    IsBatch = false;
    
    % Output Specific
    output_id = '';
    output_type = '';
    output_format = '';
    output_table = 'CWS_OUTPUT';
    
    % Database Schema Parameters
    db_rt_fn_timestep = 'TIME_STEP';
    db_rt_fn_parameterTag = 'TAG_NAME';
    db_rt_fn_parameterValue = 'VALUE';
    db_rt_fn_parameterQuality = false;
    
    db_wt_on_condition = 'all';
    db_wt_fn_timestep = 'TIME_STEP';
    db_wt_fn_instanceID = 'INSTANCE_ID';
    db_wt_fn_stationID = 'LOCATION_ID';
    db_wt_fn_algorithmID = false;
    db_wt_fn_parameterID = false;
    db_wt_fn_parameterResid = false;
    db_wt_fn_parameterTag = false;
    db_wt_fn_eventCode = 'DETECTION_INDICATOR';
    db_wt_fn_eventProb = 'DETECTION_PROBABILITY';
    db_wt_fn_eventContrib = 'CONTRIBUTING_PARAMETERS';
    db_wt_fn_comments = 'ANALYSIS_COMMENTS';
    db_wt_fn_patternID = false;
    db_wt_fn_patternProb = false;
    db_wt_fn_patternID2 = false;
    db_wt_fn_patternProb2 = false;
    db_wt_fn_patternID3 = false;
    db_wt_fn_patternProb3 = false;
    db_read_current = false;
    
    % END OF PUBLIC PROPERTIES ================================================
  end
  
  methods % PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++
    
    % THESE ARE STANDARD AND NOT OVERLOADED (GENERALLY)
    function str = printYAML( self )
      str = char(self.configuration);
    end
    
    function str = PrintDataSourceAsXML( self )
      str = sprintf(' <datasource short-id="%s" type="%s" location="%s" datasource-class="%s" username="%s" password="%s" state="%s" >\n',...
        self.conn_id , self.conn_type , self.conn_url , self.driver_datasource_class , self.conn_username , self.conn_password, self.conn_state);
      str = sprintf('%s  <driver-config>%s</driver-config>\n',...
        str, self.driver_config);
      str = sprintf('%s  <time-drift>%s</time-drift>\n',...
        str, self.TimeDrift);
      str = sprintf('%s  <input-type>%s</input-type>\n',...
        str, self.input_type);
      str = sprintf('%s  <output-type>%s</output-type>\n',...
        str, self.output_type);
      str = sprintf('%s  <interactive-login>%d</interactive-login>\n',...
        str, self.conn_interactive);
      str = sprintf('%s  <input-table>%s</input-table>\n',...
        str, self.input_table);
      str = sprintf('%s  <output-table>%s</output-table>\n',...
        str, self.output_table);
      str = sprintf('%s  <canary-id>%s</canary-id>\n',...
        str, self.canaryID);
      str = sprintf('%s  <to-date-fmt>%s</to-date-fmt>\n',...
        str, self.conn_toDateFmt);
      str = sprintf('%s  <to-date-func>%s</to-date-func>\n',...
        str, self.conn_toDateFunc);
      str = sprintf('%s  <timestep-field>%s</timestep-field>\n',...
        str, self.timestep_field);
      if ~isempty(self.conn_ipaddress),
        str = sprintf('%s  <url-type><!-- combined in location attribute above /--></url-type>\n',...
          str);
        str = sprintf('%s  <ipaddress><!-- combined in location attribute above /--></ipaddress>\n',...
          str);
        str = sprintf('%s  <port><!-- combined in location attribute above /--></port>\n',...
          str);
      else
        str = sprintf('%s  <url-type></url-type>\n',...
          str);
        str = sprintf('%s  <ipaddress></ipaddress>\n',...
          str);
        str = sprintf('%s  <port></port>\n',...
          str);
      end
      str = sprintf('%s </datasource>',str);
    end
    
    function str = PrintMessengerAsXML( self )
      switch lower(self.msgr_type)
        case {'internal'}
          str = sprintf(' <messaging type="%s" />',self.msgr_type);
        case {'external','eddies'}
          str = sprintf(' <messaging type="%s" use-id="%s" />',self.msgr_type,self.conn_id);
        otherwise
          str = '';
      end
    end
    
    function str = printControlYAML( self )
      switch lower(self.msgr_type)
        case {'internal'}
          str = sprintf('control:\n  type: INTERNAL\n  messenger: null\n');
        case {'external','eddies'}
          str = sprintf('control:\n  type: %s\n  messenger: %s\n',self.msgr_type,self.conn_id);
        otherwise
          str = sprintf('control:\n');
      end
    end
    
    function self = ConfigureDriver( self , filename )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin < 2, filename = self.driver_config;
      end
      if isempty(filename),
        if DeBug,
          cws.trace('CANARY:noDriverSpecified','No driver configuration file specified.');
        end
        return;
      end
      if DeBug,
        fprintf(1,'LoadConfiguration: %s\n',filename);
      end
      configPath = { '' ; getenv('CANARY_CFG') ; self.data_dir_path ; '.' };
      try
        ConfigFile = '';
        for i = 1:length(configPath)
          if ~isempty(dir(fullfile(configPath{i},filename)));
            ConfigFile = fullfile(configPath{i},filename);
            break;
          end
        end
        if isempty(ConfigFile),
          error('CANARY:badDriverConfig','The configuration file "%s" was not found on the search path.',filename);
        end
        FID = fopen(ConfigFile,'r');
        if FID < 0,
          error('CANARY:badDriverConfig','The configuration file "%s" failed to open.',filename);
        end
        line = fgets(FID);
        if length(line)>3 && DeBug,
          fprintf(1,'ReadConfiguration: %s\n',line(2:end-1));
        end
        while ~feof(FID)
          line = fgets(FID);
          [ name , val ] = strtok(line,':=');
          val = strtrim(val(2:end));
          switch name
            case {'DriverFile','DriverJarFile'}
              JPath = javaclasspath;
              if isempty(strmatch(val,JPath)),
                try
                  javaaddpath(val);
                catch ERR
                  cws.errTrace(ERR);
                end
              end
            case {'DataSourceClass','DataSource','DataSourcePool','DataSourcePoolClass'}
              self.driver_datasource_class = val;
            case {'StringToDate','StringDateCommand','DateConvert','DateTimeConvert'}
              [ self.sqlDateConvertA , rest ] = strtok(val,'?');
              rest = rest(2:end);
              [ self.sqlDateConvertB , rest ] = strtok(rest,'?');
              self.sqlDateConvertC = rest(2:end);
              self.conn_toDateFunc = self.sqlDateConvertA;
            case {'DateTimeDatatype','DateDatatype'}
              self.sqlDateDatatype = val;
            case {'DefaultDateTimeFormat','DateTimeFormat'}
              if isempty(self.conn_toDateFmt)
                self.conn_toDateFmt = val;
              end
            otherwise
              if DeBug,
                fprintf(2,'Unknown option in driver configuration file "%s": %s = %s\n',filename,name,val);
              end
          end
        end
        fclose(FID);
      catch ERR
        cws.errTrace(ERR);
      end
    end
    
    function configure( self, config )
      if nargin == 2 && isa(config,'cws.DefnDatasource'),
        self.configuration = config;
        CfgDS = self.configuration;
      elseif nargin == 1 && ~isempty(self.configuration)
        CfgDS = self.configuration;
      elseif nargin == 2 && isa(config,'java.util.LinkedHashMap')
        CfgDS = cws.DefnDatasource();
        CfgDS.configure(config);
        self.configuration = CfgDS;
      end
      
      self.conn_id = CfgDS.id;
      
      self.conn_type = CfgDS.dsType;
      self.input_type = CfgDS.dsType;
      self.output_type = CfgDS.dsType;
      self.conn_url = CfgDS.dsLocation;
      if strcmpi(self.conn_type,'xml')
        [ip,port] = strtok(self.conn_url,':');
        self.conn_ipaddress = ip;
        self.conn_port = str2double(port(2:end));
      end
      self.conn_state = CfgDS.enabled;
      if ~isempty(CfgDS.dsConfigFile)
        self.driver_config = CfgDS.dsConfigFile;
      end
      if ~isempty(CfgDS.dsMesgWaitSec)
        self.clear_delay = CfgDS.dsMesgWaitSec;
      end
      self.timestep_field = CfgDS.tsField;
      self.conn_toDateFmt = CfgDS.tsFormat;
      self.conn_toDateFunc = CfgDS.tsConvertFunc;
      self.driver_datasource_class = CfgDS.dsJavaClass;
      self.input_table =CfgDS.inputTable;
      self.db_read_current = CfgDS.inputCurrent;
      self.input_format = CfgDS.inputFormat;
      self.db_rt_fn_timestep = CfgDS.inputFieldTimestep;
      self.db_rt_fn_parameterTag =CfgDS.inputFieldSCADATag;
      self.db_rt_fn_parameterValue =CfgDS.inputFieldValue;
      self.db_rt_fn_parameterQuality =CfgDS.inputFieldQuality;
      self.output_table = CfgDS.outputTable;
      self.output_format = CfgDS.outputFormat;
      self.db_wt_on_condition = CfgDS.outputConditions;
      self.db_wt_fn_timestep = CfgDS.outputFieldTimestep;
      self.db_wt_fn_instanceID =CfgDS.outputFieldInstanceId;
      self.db_wt_fn_stationID = CfgDS.outputFieldStationId;
      self.db_wt_fn_algorithmID =CfgDS.outputFieldAlgorithmId;
      self.db_wt_fn_parameterID =CfgDS.outputFieldParameterId;
      self.db_wt_fn_parameterResid =CfgDS.outputFieldParamResid;
      self.db_wt_fn_parameterTag =CfgDS.outputFieldParamTag;
      self.db_wt_fn_eventCode =CfgDS.outputFieldEventCode;
      self.db_wt_fn_eventProb =CfgDS.outputFieldEventProb;
      self.db_wt_fn_eventContrib =CfgDS.outputFieldEventContrib;
      self.db_wt_fn_comments =CfgDS.outputFieldComments;
      self.db_wt_fn_patternID = CfgDS.outputFieldPatId1;
      self.db_wt_fn_patternProb = CfgDS.outputFieldPatProb1;
      self.db_wt_fn_patternID2 = CfgDS.outputFieldPatId2;
      self.db_wt_fn_patternProb2 = CfgDS.outputFieldPatProb2;
      self.db_wt_fn_patternID3 = CfgDS.outputFieldPatId3;
      self.db_wt_fn_patternProb3 = CfgDS.outputFieldPatProb3;
      self.TimeDrift = CfgDS.dsMesgWaitSec;
      if CfgDS.dsLoginRequired,
        self.conn_username = CfgDS.dsLoginUser;
        self.conn_password = CfgDS.dsLoginPass;
        self.conn_interactive = CfgDS.dsLoginPrompt;
      end
      if ~isempty(CfgDS.dsConfigFile),
        self.ConfigureDriver();
      end
    end
    
    function CfgDS = saveCurrentConfiguration( self )
      if isempty(self.configuration)
        CfgDS = cws.DefnDatasource();
      else
        CfgDS = self.configuration;
      end
      CfgDS.id = self.conn_id;
      CfgDS.dsType = self.conn_type;
      CfgDS.dsLocation = self.conn_url;
      CfgDS.enabled = self.conn_state;
      CfgDS.dsConfigFile = self.driver_config;
      CfgDS.dsMesgWaitSec = self.clear_delay;
      CfgDS.tsField = self.timestep_field ;
      CfgDS.tsFormat = self.conn_toDateFmt;
      CfgDS.tsConvertFunc = self.conn_toDateFunc;
      CfgDS.dsJavaClass = self.driver_datasource_class;
      CfgDS.inputTable = self.input_table;
      CfgDS.inputCurrent = self.db_read_current;
      CfgDS.inputFormat = self.input_format;
      CfgDS.inputFieldTimestep = self.db_rt_fn_timestep;
      CfgDS.inputFieldSCADATag = self.db_rt_fn_parameterTag;
      CfgDS.inputFieldValue = self.db_rt_fn_parameterValue;
      CfgDS.inputFieldQuality = self.db_rt_fn_parameterQuality;
      CfgDS.outputTable = self.output_table;
      CfgDS.outputFormat = self.output_format;
      CfgDS.outputConditions = self.db_wt_on_condition;
      CfgDS.outputFieldTimestep = self.db_wt_fn_timestep;
      CfgDS.outputFieldInstanceId = self.db_wt_fn_instanceID;
      CfgDS.outputFieldStationId = self.db_wt_fn_stationID;
      CfgDS.outputFieldAlgorithmId = self.db_wt_fn_algorithmID;
      CfgDS.outputFieldParameterId = self.db_wt_fn_parameterID;
      CfgDS.outputFieldParamResid = self.db_wt_fn_parameterResid;
      CfgDS.outputFieldParamTag = self.db_wt_fn_parameterTag;
      CfgDS.outputFieldEventCode = self.db_wt_fn_eventCode;
      CfgDS.outputFieldEventProb = self.db_wt_fn_eventProb;
      CfgDS.outputFieldEventContrib = self.db_wt_fn_eventContrib;
      CfgDS.outputFieldComments = self.db_wt_fn_comments;
      CfgDS.outputFieldPatId1 = self.db_wt_fn_patternID;
      CfgDS.outputFieldPatProb1 = self.db_wt_fn_patternProb;
      CfgDS.outputFieldPatId2 = self.db_wt_fn_patternID2;
      CfgDS.outputFieldPatProb2 = self.db_wt_fn_patternProb2;
      CfgDS.outputFieldPatId3 = self.db_wt_fn_patternID3;
      CfgDS.outputFieldPatProb3 = self.db_wt_fn_patternProb3;
      CfgDS.dsMesgWaitSec = self.TimeDrift;
      if ~isempty(CfgDS.dsLoginUser)
        CfgDS.dsLoginRequired = true;
      end
      CfgDS.dsLoginUser = self.conn_username;
      CfgDS.dsLoginPass = self.conn_password;
      CfgDS.dsLoginPrompt = self.conn_interactive;
    end
    
    
    function constructFromYAML( self, HashMap )
      % Technically, this is just a "constructFromHashMap" function. I.e.,
      % if a JSON parsed HashMap was passed instead, it should process just
      % fine.
      
      self.configure(HashMap);
      
    end
    
    function self = DataSource( varargin ) % ------------------- CONSTRUCTOR --
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
          error('CANARY:unknownConn','Unknown construction method: %s',class(self));
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
            warning('CANARY:unkownOption','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
      % END OF CONSTRUCTOR ----------------------------------------------------
    end
    
    function self = clear_idle( self )
      self.IdleCount = 0;
    end
    
    function self = idle( self )
      cws.logger(0);
      self.IdleCount = self.IdleCount + 1;
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      %       if DeBug, cws.trace('IDLE',['Idle count = ',num2str(self.IdleCount)]);
      %       end
      if self.IdleCount > 10,
        t = timerfind('Tag','tsUpdate');
        if ~isempty(t) && self.haveGotData > 0,
          if strcmp(t.Running,'off'),
            start(t);
          end
        end
      end
    end
    
    function delete( self ) % ----------------------------------- DESTRUCTOR --
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.disconnect();
      % END OF DESTRUCTOR -----------------------------------------------------
    end
    
    function saveMessageList( self , filename )
      if isempty(filename), filename=fullfile(self.data_dir_path,'messageList.debug'); end;
      self.messageCenter.print(filename);
    end
    
    function str = char( self ) % ------------------------------------- CHAR --
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      str = self.toString();
    end
    
    function self = useAsInput( self )
      self.IsInput = true;
      if isempty(self.input_type),
        self.input_type = self.conn_type;
      end
      % END OF USEASINPUT -----------------------------------------------------
    end
    
    function self = useAsOutput( self )
      self.IsOutput = true;
      if isempty(self.output_type),
        self.output_type = self.conn_type;
      end;
      % END OF USEASOUTPUT ----------------------------------------------------
    end
    
    function self = useAsControl( self )
      self.IsControl = true;
      % END OF USEASCONTROL ---------------------------------------------------
    end
    
    function self = use( self )
      self.isused = true;
      % END OF USE ------------------------------------------------------------
    end
    
    function self = activate( self , locID )
      self.isActive(locID) = true;
      % END OF ACTIVATE -------------------------------------------------------
    end
    
    function self = deactivate( self , locID )
      self.isActive(locID) = false;
      % END OF DEACTIVATE -----------------------------------------------------
    end
    
    function self = initialize( self , varargin )
      if self.IsInput && ~self.IsInpInit,
        self.initializeInput(varargin{:});
      end
      if self.IsOutput && ~self.IsOutInit,
        self.initializeOutput(varargin{:});
      end
      if self.IsControl && ~self.IsCtlInit,
        self.initializeControl(varargin{:});
      end
      if  ~xor(self.IsControl, self.IsCtlInit) && ...
          ~xor(self.IsOutput,  self.IsOutInit) && ...
          ~xor(self.IsInput,   self.IsInpInit)
        self.Isinitialized = true;
        self.IdleCount = 0;
      end
      % END OF INITIALIZE -----------------------------------------------------
    end
    
    function evalComposites(self, CDS, idx0, idx1)
      for k = 1:length(CDS.composite_signal_list)
        kompIdx = CDS.composite_signal_list(k);
        idx0 = max([idx0,1]);
        idx1 = max([idx1,1]);
        try
          CDS.values(idx0:idx1,kompIdx) = CDS.evalCompositeSignals( kompIdx , idx0 , idx1 );
        catch ERR
          CDS.values(idx0:idx1,kompIdx) = nan;
        end
      end
    end
    
    function self = TimeStep( self )
      %TIMESTEP Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.send(cws.Message('to','CANARY','from','CANARY','subj','TIMESTEP','cont',datestr(now(),self.time.date_fmt)));
      % END OF TIMESTEP -------------------------------------------------------
    end
    
    function ClearRcvdNewData( self )
      self.RcvdNewData = false;
    end
    
    function self = initialize_files( self , varargin)
      % do nothing if not a CSVDataSource object
      i = 1;
      %warning('CANARY:datasource','Using base class method for what should be overloaded: %s',self.conn_id);
    end
    
    function serverDatetime = get_server_date(self, shift)
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      serverDatetime = [];
      switch lower(self.conn_type),
        case {'db','jdbc','eddies'}
        otherwise
          return
      end
      if nargin < 2,
        shift = 1/24;
      end
      idx = 1 + self.time.getDateIdx(now-shift) + self.TimeDrift;
      if isnan(shift) || idx < 1,
        cws.trace('database','Unable to find any rows in table');
        return
      end
      s = lower(char(self.ConnID));
      a = strfind(s,'mysql');
      if ~isempty(strfind(s,'mysql'))
        sqlQuery = ['SELECT * FROM ',self.input_table, ...
          ' WHERE ',self.timestep_field,' > ', self.sqlDateConvertA, char(self.time.getDateStr(idx)), self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC , ...
          ' ORDER BY ',self.timestep_field,' DESC LIMIT 2'];
      elseif ~isempty(strfind(s,'oracle'))
        sqlQuery = ['SELECT * FROM ( SELECT * FROM ',self.input_table, ...
          ' WHERE ',self.timestep_field,' > ', self.sqlDateConvertA, char(self.time.getDateStr(idx)), self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC , ...
          ' ORDER BY ',self.timestep_field,' DESC) WHERE ROWNUM <= 2'];
      elseif ~isempty(strfind(s,'sqlserver'))
        sqlQuery = ['SELECT TOP 2 * FROM ( SELECT * FROM ',self.input_table, ...
          ' WHERE ',self.timestep_field,' > ', self.sqlDateConvertA, char(self.time.getDateStr(idx)), self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC , ...
          ' ORDER BY ',self.timestep_field,' DESC)'];
      else
        sqlQuery = ['SELECT * FROM ',self.input_table,...
          ' WHERE ',self.timestep_field,' > ', self.sqlDateConvertA, char(self.time.getDateStr(idx)), self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC , ...
          ' ORDER BY ',self.timestep_field,' DESC'];
      end
      if DeBug,
        fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
        fprintf(fid,'%s\n',sqlQuery);
        fclose(fid);
      end
      try
        sq = self.ConnID.prepareStatement(sqlQuery);
        sq.execute();
        rq = sq.getResultSet();
        if rq.next()
          serverDatetime = char(rq.getString(self.timestep_field));
        else
          serverDatetime = self.get_server_date(shift+1);
        end
        sq.close();
        rq.close();
        cws.trace('database',['Server date: ',serverDatetime]);
        fprintf(2,'%s\n',['Server date: ',serverDatetime]);
      catch E
        disp('error in sq select last row');
        cws.errTrace(E)
      end
    end
    
    function str = toString( self ) % ----------------------------- TOSTRING --
      str = self.char();
      % END OF TOSTRING -------------------------------------------------------
    end
    
    function resetLogFile(self)
      if self.LogFID > 0,
        fclose(self.LogFID);
      end
      self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'wt');
      fprintf(self.LogFID,'# Messenger log truncated: %s\n',datestr(now(),30));
    end
    
  end
  
  
  methods % OVERLOADED METHODS ++++++++++++++++++++++++++++++++++++++++++++
    
    function self = connect(self)
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = disconnect( self )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = update( self , varargin )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = postResult( self , idx , LOC , timestep , CDS )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function message = read( self )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function errortext = post( self )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function errortext = send( self , message )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = initializeInput( self , varargin )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = initializeOutput( self , varargin )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function self = initializeControl( self , varargin )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
  end
  
  % END OF CLASSDEF DATASOURCE ============================================
end
