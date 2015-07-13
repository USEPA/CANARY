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
% CANARY is a software package that allows developers to test different
% algorithms and settings on both off- and on-line water-quality data sets.
% Data can come from database or text file sources.
%
% This software was written as part of an Inter-Agency Agreement between
% Sandia National Laboratories and the US EPA NHSRC.
% PARSE_CONFIGFILE get settings from a configuration file
%
% Example DATA = parse_configfile 'my_config.xml';
%         DATA = parse_configfile(my_file);
%
% Patch: r3527 - John Knoll, TetraTech, 5/21/2010
%
% See also SignalData, TimeCfg
function [ CDef , SIGS , INPS , OUTS ] = parse_xml_config ( ObjEDS , ...
    CDef , allowdisableds )
  filename = ObjEDS.configFile;
  filepath = ObjEDS.runDirectory;
  logfile  = ObjEDS.logfilePrefix;
  
  % Initial Variable Set
  import cws.* xml.*;
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL; %#ok<NODEF>
  global VERSION;
  Version = VERSION; %#ok<NODEF>
  drivers.type = '';
  drivers.driver = '';
  drivers.datasource = '';
  drivers.jarfile = '';
  if nargin < 5,
    allowdisableds = false;
  end
  if nargin < 1, filename = ''; end;
  if nargin < 4
    CDef = [];
  end
  if isempty(CDef);
    CDef = struct();
    CDef.INPUTS = [];
    CDef.OUTPUTS = [];
    CDef.SIGNALS = [];
    %     INPS(1).handle = [];
    %     INPS(1).name = '';
    %     OUTS(1).handle = [];
    %     INPS(1).name = '';
    DSRCS(1).handle = [];
    DSRCS(1).name = '';
    SIGS = cws.Signals;
    % MSGR = cws.Messenger('CONTROL');
    MSGR = [];
  else
    INPS = CDef.INPUTS;
    OUTS = CDef.OUTPUTS;
    SIGS = CDef.SIGNALS;
    MSGR = CDef.MESSENGER;
  end
  [ p, configName] = fileparts(filename);
  SIGS.filepath = filepath;
  SIGS.case_prefix = [configName '.'];
  if nargin < 1 || isempty(filename),
    cws.trace( 'CANARY:configurationError' , 'No configuration file' );
    error('CANARY:ConfigErr',...
      'No configuration file specified' );
  else
    if DeBug, cws.trace( 'config:load' , filename); end;
    try
      xDoc = xml.get_docnode(filename);
    catch ERRcfg
      base_ME = MException('CANARY:ConfigErr',...
        'Unable to load configuration file %s', filename);
      base_ME = addCause(base_ME, ERRcfg);
      throw(base_ME);
    end
  end
    if DeBug, cws.trace( 'config:load' , 'Success!' ); end;
  if isempty(SIGS.time),
    TIME = cws.Timing;
    SIGS.time = TIME;
  else
    TIME = SIGS.time;
  end
  if isempty(SIGS.algorithms),
    ALGS = cws.Algorithms;
    SIGS.algorithms = ALGS;
  end
  % Pop out the XML nodes for each section of the configuration document
  if DeBug, cws.trace( 'config:read' , 'Popping out XML tags' ); end;
  xLog = char( xml.get_text( xDoc, 'log-file') );
  if isempty(xLog), xLog = logfile;
  end
  %assignin('base','logfile',xLog);
  
  
  % GET MAIN XML CHUNKS
  xGen = xml.get_child( xDoc , 'general-settings' );
  xJDBC = xml.get_child( xDoc , 'jdbc-driver' );
  xInp = xml.get_child( xDoc , 'input-options' );
  xOut = xml.get_child( xDoc , 'output-options' );
  xTime = xml.get_child( xDoc , 'timing-options' );
  xDSrc = xml.get_child( xDoc , 'datasource' );
  xDBG = char(xml.get_text(xDoc,'debug'));
  if ~isempty(xDBG),
    DeBug = xml.bool(xDBG);
  end
  runmode = char( xml.get_text( xDoc , 'run-mode' ) );
  datadir = char( xml.get_text( xDoc , 'data-dir' ) );
  extras = xml.get_text_array( xDoc , 'classpath' );
  if ~isdeployed
    S = dbstatus;
  end
  if ~isempty(extras),
    for i = 1:length(extras)
      JPath = javaclasspath;
      if isempty(strmatch(extras{i},JPath,'exact')),
        try
          javaaddpath(extras{i});
        catch ERR
          cws.errTrace(ERR);
        end
      end
    end      
  end;
  if ~isdeployed
    dbstop(S);
  end
  
  
  % Start Processing
  clear DEBUG_LEVEL VERSION;
  global DEBUG_LEVEL; %#ok<REDEF>
  
  DEBUG_LEVEL = DeBug; %#ok<NASGU>
  global VERSION; %#ok<REDEF>
  VERSION = Version; %#ok<NASGU>
  
  if isempty(datadir),
    datadir = filepath;
  end
  name = '';
  if isempty(datadir),
    [path,name] = fileparts(filename);
    if isempty(path),
      path = pwd;
    end
    datadir = path;  
  end
  if ~isempty(xLog),
    [logpath,logfile] = fileparts(xLog);
    if isempty(logpath),
      logpath = datadir;
    end
  else
    logpath = datadir;
    logfile = name;
  end
  
  sep = filesep;
  logpath = [ logpath sep logfile ];
  datadir = [ datadir sep ];
  xMsg = xml.get_child( xDoc , 'messaging' );
  SigFile = ''; %#ok<NASGU>
  xNewSigs = xml.get_child( xDoc , 'Signals' );
  xExtraSigs = xml.get_child( xGen , 'SignalsFile' );
  if ~isempty(xExtraSigs)
    SigFile = char( xml.get_attribute( xExtraSigs , 'name' ) );
    xExtraSigs = []; %#ok<NASGU>
    xGen2 = [];
  else
    SigFile = char( xml.get_attribute( xGen , 'filename' ) );
    if ~isempty(SigFile),
      try
        factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
        builder = factory.newDocumentBuilder();
        path = pwd;
        if ispc, file = char([ path '\' SigFile ]);
        else file = char([ path '/' SigFile ]); end
        javafile = java.io.File(file);
        xStr = builder.parse(javafile);
        xDoc2 = xStr.getDocumentElement;
        %clear 'xStr';
        xStr = []; %#ok<NASGU>
      catch ERRsig
        disp([' CANARY:config ==> Problem reading extra configuration file "' ...
          SigFile '"'])
        rethrow(ERRsig);
      end
      xGen2 = xml.get_child( xDoc2 , 'general-settings' );
      %clear 'xDoc2';
      xDoc2 = []; %#ok<NASGU>
    else
      xGen2 = [];
    end
    SigFile = '';
  end
  AlgFile = ''; 
  xNewAlgs = xml.get_child( xDoc , 'Algorithms' );
  xExtraAlgs = xml.get_child( xGen , 'AlgorithmsFile' );
  if ~isempty(xExtraAlgs)
    AlgFile = char( xml.get_attribute( xExtraAlgs , 'name' ) );
    xExtraAlgs = []; %#ok<NASGU>
  end
  % Parse the <timing-options> object
  if DeBug, cws.trace( 'CONFIG:timing' , 'Constructing timing object' ); end;
  data_int = xml.get_attribute( xTime , 'data-interval' );
  poll_int = xml.get_attribute( xTime , 'poll-interval' );
  sta_date = xml.get_attribute( xTime, 'start-date' );
  end_date = xml.get_attribute( xTime , 'end-date' );
  if isempty(end_date),
    end_date = xml.get_attribute( xTime , 'stop-date' );
  end
  date_fmt = xml.get_attribute( xTime , 'datetime-format' );
  dynamic  = xml.bool(xml.get_attribute( xTime , 'dynamic-start' ) );
  if isempty(dynamic),
    dynamic = false;
  end
  TIME.set_date_fmt(date_fmt);
  if dynamic == true,
    if DeBug,
      cws.trace('CONFIG:timing','Starting Dynamic Mode');
    end
    TIME.dynamic = true;
    TIME.set_date_start(floor(now-1));
    TIME.set_date_end(ceil(now+1));
  else
    TIME.dynamic = false;
    TIME.set_date_start(sta_date);
    TIME.set_date_end(end_date);
  end
  TIME.set_date_mult(data_int);
  TIME.set_poll_int(poll_int);
  if DeBug,
    fprintf(2,'%s\n',TIME.PrintTimingAsXML());
  end
  
  % Parse the <jdbc-driver> database definitions
  if DeBug, cws.trace( '' , 'Constructing jdbc objects' ); end;
  nJDBC = length(xJDBC);
  for i = 1:nJDBC
    drvclass = xml.get_attribute( xJDBC(i) , 'driver-class' );
    dsnclass = xml.get_attribute( xJDBC(i) , 'datasource-class');
    cpath = xml.get_attribute( xJDBC(i) , 'classpath' );
    db_type = xml.get_attribute( xJDBC(i) , 'type' );
    todatefcn = xml.get_attribute( xJDBC(i) , 'to-date-func');
    todatefmt = xml.get_attribute( xJDBC(i) , 'to-date-fmt' );
    if ~strfind(db_type,'jdbc')
      db_type = ['jdbc:',db_type];
    end
    drivers(i).type = db_type;
    drivers(i).driver = drvclass;
    drivers(i).datasource = dsnclass;
    drivers(i).jarfile = cpath;
    drivers(i).todatefcn = todatefcn;
    drivers(i).todatefmt = todatefmt;
  end
  
  % PARSE DATASOURCE DEFINITIONS
  if DeBug, cws.trace( '' , 'Constructing DataSource objects'); end;
  nDSrc = length(xDSrc);
  for i = 1:nDSrc
    dsId = char( xml.get_attribute( xDSrc(i) , 'short-id' ) );
    DSRCS(i).name = dsId;
    dsActive = (char( xml.get_attribute( xDSrc(i) , 'state' )));
    if ~allowdisableds && strcmpi(dsActive,'disabled'),
      cws.trace('CONFIG:warning',['Disabled data source DS: ',dsId]);
      continue
    end
    dsType = char( xml.get_attribute( xDSrc(i) , 'type' ));
    dsIType = char( xml.get_attribute( xDSrc(i) , 'input-type' ));
    dsOType = char( xml.get_attribute( xDSrc(i) , 'output-type' ));
    dsLoc = char(xml.get_attribute_or_text( xDSrc(i) , 'location' ));
    dsIPAdd = char( xml.get_attribute_or_text( xDSrc(i) , 'ipaddress' ) );
    dsPort = char( xml.get_attribute_or_text( xDSrc(i) , 'port' ) );
    dsURLType = char( xml.get_attribute_or_text( xDSrc(i) , 'url-type' ) );
    dsDrift = str2double(char(xml.get_attribute_or_text(xDSrc(i),'time-drift')));
    dsURL = '';
    if isempty(dsLoc) || ~isempty(dsURLType),
      if ~isempty(dsURLType),
        dsURL = [ dsURLType , '//'];
      end
      dsURL = [ dsURL , dsIPAdd , ':' , dsPort ]; %#ok<*AGROW>
      if ~isempty(dsLoc),
        dsURL = [ dsURL , '/' , dsLoc ];
      end
    elseif ~isempty(dsLoc) && isempty(dsURLType),
      dsURL = dsLoc;
    end
    if strcmp(dsURL,':')
      dsURL = configName;
    end
    dsClass = char(xml.get_attribute_or_text( xDSrc(i) , 'datasource-class' ) );
    dsConfigFile = char(xml.get_attribute_or_text( xDSrc(i) , 'driver-config' ) );
    dsINPTable = char( xml.get_attribute_or_text( xDSrc(i) , 'input-table' ) );
    dsOUTTable = char( xml.get_attribute_or_text( xDSrc(i) , 'output-table' ) );
    dsTSField = char( xml.get_attribute_or_text( xDSrc(i) , 'timestep-field' ) );
    dsTDFunc = char( xml.get_attribute_or_text( xDSrc(i) , 'to-date-func' ) );
    dsTDFmt = char( xml.get_attribute_or_text( xDSrc(i) , 'to-date-fmt' ) );
    dsUser = char( xml.get_attribute_or_text( xDSrc(i) , 'username' ) );
    dsPass = char( xml.get_attribute_or_text( xDSrc(i) , 'password' ) );
    dsPassDlg = xml.bool(char( xml.get_attribute_or_text( xDSrc(i) , 'interactive-login' )));
    dsCanaryId = char( xml.get_attribute_or_text( xDSrc(i), 'canary-id')); 
    if isempty(dsPassDlg),
      dsPassDlg = false;
    end
    if strcmpi(dsType,'mat') || strcmpi(dsType,'binary') || strcmpi(dsType,'edsd'),
      try
        fprintf(1,'Loading:\t%s as BINARY INPUT file\n',dsURL);
        try
          UseSigs = load(dsURL,'-MAT');
        catch ERR
          UseSigs = load(fullfile(datadir,dsURL),'-MAT');
        end
        if isfield(UseSigs,'self'),
          OldSigs = UseSigs.self;
        elseif isfield(UseSigs,'CDS'),
          OldSigs = UseSigs.CDS;
        elseif isfield(UseSigs,'V'),
          OldSigs = UseSigs.V;
        else
          error('canary:invalidfile','Not a valid EDSD input file: %s',dsURL);
        end
        OldSigs.filepath = filepath;
        OldSigs.case_prefix = [configName '.'];
        OldSigs.time.set_date_end(TIME.date_end);
        TIME = OldSigs.time;
        SIGS = OldSigs;
        SIGS.locations = struct('name','','handle',0,'stationNum',0);
        SIGS.nlocs = 0;
      catch loadERR,
        cws.errTrace(loadERR);
      end
    end
    switch lower(dsType)
      case {'db','jdbc'}
    DS = cws.JDBCDataSource(...,
      'conn_id',dsId,...
      'conn_type',dsType,...
      'conn_state',dsActive,...
      'conn_url',dsURL,...
      'conn_instance',dsLoc,...
      'conn_ipaddress',dsIPAdd,...
      'conn_port',dsPort,...
      'driver_datasource_class',dsClass,...
      'conn_toDateFunc',dsTDFunc,...
      'conn_toDateFmt',dsTDFmt,...
      'input_table',dsINPTable,...
      'output_table',dsOUTTable,...
      'timestep_field',dsTSField,...
      'conn_username',dsUser,...
      'conn_password',dsPass,...
      'conn_interactive',dsPassDlg,...
      'input_type',dsIType,...
      'output_type',dsOType);
        
      case {'eddies'}
    DS = cws.EDDIESDataSource(...,
      'conn_id',dsId,...
      'conn_type',dsType,...
      'conn_state',dsActive,...
      'conn_url',dsURL,...
      'conn_instance',dsLoc,...
      'conn_ipaddress',dsIPAdd,...
      'conn_port',dsPort,...
      'driver_datasource_class',dsClass,...
      'conn_toDateFunc',dsTDFunc,...
      'conn_toDateFmt',dsTDFmt,...
      'input_table',dsINPTable,...
      'output_table',dsOUTTable,...
      'timestep_field',dsTSField,...
      'conn_username',dsUser,...
      'conn_password',dsPass,...
      'conn_interactive',dsPassDlg,...
      'input_type',dsIType,...
      'output_type',dsOType);
        
      case {'xml'}
    DS = cws.XMLDataSource(...,
      'conn_id',dsId,...
      'conn_type',dsType,...
      'conn_state',dsActive,...
      'conn_url',dsURL,...
      'conn_instance',dsLoc,...
      'conn_ipaddress',dsIPAdd,...
      'conn_port',dsPort,...
      'driver_datasource_class',dsClass,...
      'conn_toDateFunc',dsTDFunc,...
      'conn_toDateFmt',dsTDFmt,...
      'input_table',dsINPTable,...
      'output_table',dsOUTTable,...
      'timestep_field',dsTSField,...
      'conn_username',dsUser,...
      'conn_password',dsPass,...
      'conn_interactive',dsPassDlg,...
      'input_type',dsIType,...
      'output_type',dsOType);
        
      case {'csv','file','files','csvfile','csv-file','csv file'}
    DS = cws.CSVDataSource(...,
      'conn_id',dsId,...
      'conn_type',dsType,...
      'conn_state',dsActive,...
      'conn_url',dsURL,...
      'conn_instance',dsLoc,...
      'conn_ipaddress',dsIPAdd,...
      'conn_port',dsPort,...
      'driver_datasource_class',dsClass,...
      'conn_toDateFunc',dsTDFunc,...
      'conn_toDateFmt',dsTDFmt,...
      'input_table',dsINPTable,...
      'output_table',dsOUTTable,...
      'timestep_field',dsTSField,...
      'conn_username',dsUser,...
      'conn_password',dsPass,...
      'conn_interactive',dsPassDlg,...
      'input_type',dsIType,...
      'output_type',dsOType);        
      otherwise
    DS = cws.DataSource(...,
      'conn_id',dsId,...
      'conn_type',dsType,...
      'conn_state',dsActive,...
      'conn_url',dsURL,...
      'conn_instance',dsLoc,...
      'conn_ipaddress',dsIPAdd,...
      'conn_port',dsPort,...
      'driver_datasource_class',dsClass,...
      'conn_toDateFunc',dsTDFunc,...
      'conn_toDateFmt',dsTDFmt,...
      'input_table',dsINPTable,...
      'output_table',dsOUTTable,...
      'timestep_field',dsTSField,...
      'conn_username',dsUser,...
      'conn_password',dsPass,...
      'conn_interactive',dsPassDlg,...
      'input_type',dsIType,...
      'output_type',dsOType);
    end
    DS.run_mode = runmode;
    DS.TimeDrift = dsDrift;
    DS.data_dir_path = datadir;
    DS.log_path = logpath;
    DS.time = TIME;
    DS.input_table = dsINPTable;
    DS.output_table= dsOUTTable;
    DS.timestep_field=dsTSField;
    DS.canaryID = dsCanaryId;
    if ~isempty(dsConfigFile),
      DS.driver_config = dsConfigFile;
      DS.ConfigureDriver();
    end

    DSRCS(i).handle = DS;
    if DeBug,
      fprintf(2,'%s\n',DS.PrintDataSourceAsXML());
    end
  end
  
  % Create the MESSENGER
  if DeBug, cws.trace( '' , 'Constructing messenger object' ); end;
  id = char( xml.get_attribute( xMsg , 'short-id' ));
  msgtype = char( xml.get_attribute( xMsg , 'type' ));
  useID = char( xml.get_attribute( xMsg , 'use-id' ));
  skipMsgBld = false;
  if ~isempty(useID),
    Num = find(strcmp({ DSRCS(:).name },useID));
    if Num > 0,
      MSGR = DSRCS(Num).handle;
      skipMsgBld = true;
      MSGR.useAsControl();
      MSGR.msgr_type = msgtype;
    end
  end
  if ~skipMsgBld
    MSGR = cws.MSGRDataSource();
    MSGR.useAsControl();
    if isempty(id), id = 'CONTROL'; end;
    MSGR.conn_id = id;
    MSGR.msgr_type = msgtype;
    location = char( xml.get_attribute( xMsg , 'location'));
    MSGR.conn_url = location;
    username = xml.get_attribute( xMsg , 'username' );
    if ~isempty(username)
      MSGR.conn_username = username;
    end
    password = xml.get_attribute( xMsg , 'password' );
    if ~isempty(password)
      MSGR.conn_password = password;
    end
    MSGR.driver_datasource_class = xml.get_attribute( xMsg , 'datasource-class' );
    dsTDFunc = char( xml.get_attribute( xMsg , 'to-date-func' ) );
    dsTDFmt = char( xml.get_attribute( xMsg , 'to-date-fmt' ) );
    if ~isempty(dsTDFunc), MSGR.conn_toDateFunc = dsTDFunc; end;
    if ~isempty(dsTDFmt), MSGR.conn_toDateFmt = dsTDFmt; end;
    if ~isempty(strfind(location,'jdbc'))
      MSGR.conn_type = 'jdbc';
    else
      MSGR.conn_type = 'file';
    end
    MSGR.run_mode = runmode;
    MSGR.data_dir_path = datadir;
    MSGR.log_path = logpath;
    MSGR.time = TIME;
  end
  % Parse the <input-options> definitions
  nInp = length(xInp);
  if DeBug, cws.trace( '' , 'Constructing input objects' ); end;
  nDSCur = length(DSRCS);
  for i = 1:nInp
    %     warning('CANARY:config:deprectatedOptions',...
    %       ['The <input-options> tag has been deprecated as of CANARY 3.6. ',...
    %       '\n       * Support for this tag will be discontinued in version 4.0.',...
    %       '\n       * Please change <input-options> to <datasource> in config file.']);
    inpid = char( xml.get_attribute( xInp(i) , 'short-id' ) );
    if isempty( inpid ), inpid = 'default';
    elseif ~isvarname( inpid ), inpid = genvarname( inpid );
    end
    inpid = lower(inpid);
    inpid = [inpid,'_in'];
    type = xml.get_attribute( xInp(i) , 'type' );
    location = xml.get_attribute( xInp(i) , 'location' );
    table = xml.get_attribute( xInp(i) , 'table' );
    if isempty(type)
      type = xml.get_attribute( xInp(i) , 'input-type' );
    end
    if isempty(location)
      location = xml.get_attribute( xInp(i) , 'input-source' );
    end
    if isempty(table)
      table = xml.get_attribute( xInp(i) , 'input-table' );
    end
    
    tsField = xml.get_attribute( xInp(i) , 'timestep-field' );
    if isempty(tsField),
      tsField = 'TIME_STEP';
    end
    
    %    CINP = cws.Input('input_id',inpid,'input_type',type,'time',TIME,'conn_id',inpid,'conn_url',location);
    CINP = cws.DataSource('input_id',inpid,'input_type',type,'time',TIME,'conn_id',inpid,'conn_url',location);
    CINP.useAsInput();
    if ~isempty(table), CINP.input_table = table; end;
    CINP.timestep_field = tsField;
    dsTDFunc = char( xml.get_attribute_or_text( xInp(i) , 'to-date-func' ) );
    dsTDFmt = char( xml.get_attribute_or_text( xInp(i) , 'to-date-fmt' ) );
    if ~isempty(dsTDFunc), CINP.conn_toDateFunc = dsTDFunc; end;
    if ~isempty(dsTDFmt), CINP.conn_toDateFmt = dsTDFmt; end;
    username = xml.get_attribute( xInp(i) , 'username' );
    if ~isempty(username)
      CINP.conn_username = username;
    end
    password = xml.get_attribute( xInp(i) , 'password' );
    if ~isempty(password)
      CINP.conn_password = password;
    end
    CINP.input_type = type;
    CINP.conn_type = type;
    CINP.driver_datasource_class = xml.get_attribute( xInp(i) , 'datasource-class' );
    CINP.log_path = logpath;
    CINP.data_dir_path = datadir;
    CINP.run_mode = runmode;
    DSRCS(nDSCur+i).handle = CINP;
    DSRCS(nDSCur+i).name = inpid;
  end
  % Parse the <output-options> definitions
  nOut = length(xOut);
  if DeBug, cws.trace( '' , 'Constructing output objects' ); end;
  nDSCur = length(DSRCS);
  for i = 1:nOut
    %     warning('CANARY:config:deprectatedOptions',...
    %       ['The <output-options> tag has been deprecated as of CANARY 3.6. ',...
    %       '\n       * Support for this tag will be discontinued in version 4.0.',...
    %       '\n       * Please change <output-options> to <datasource> in config file.']);
    outpid = char( xml.get_attribute( xOut(i) , 'short-id' ) );
    if isempty( outpid ), outpid = 'default';
    elseif ~isvarname( outpid ), outpid = genvarname( outpid );
    end
    outpid = lower(outpid);
    outpid = [outpid,'_out'];
    type = xml.get_attribute( xOut(i) , 'type' );
    if isempty(type)
      type = xml.get_attribute( xOut(i) , 'output-type' );
    end
    location = xml.get_attribute( xOut(i) , 'location' );
    if isempty(location)
      location = xml.get_attribute( xOut(i) , 'output-stub' );
    end
    table = xml.get_attribute( xOut(i) , 'table' );
    if isempty(table)
      table = xml.get_attribute( xOut(i) , 'output-table' );
    end
    %    COUT = cws.Output('output_id',outpid,'output_type',type,'time',TIME,'conn_id',outpid,'conn_url',location);
    dsTDFunc = char( xml.get_attribute_or_text( xOut(i) , 'to-date-func' ) );
    dsTDFmt = char( xml.get_attribute_or_text( xOut(i) , 'to-date-fmt' ) );
    if ~isempty(dsTDFunc), COUT.conn_toDateFunc = dsTDFunc; end;
    if ~isempty(dsTDFmt), COUT.conn_toDateFmt = dsTDFmt; end;
    COUT = cws.DataSource('output_id',outpid,'output_type',type,'time',TIME,'conn_id',outpid,'conn_url',location);
    COUT.useAsOutput();
    COUT.output_table = table;
    COUT.driver_datasource_class = xml.get_attribute( xOut(i) , 'datasource-class' );
    username = xml.get_attribute( xOut(i) , 'username' );
    if ~isempty(username)
      COUT.conn_username = username;
    end
    password = xml.get_attribute( xOut(i) , 'password' );
    if ~isempty(password)
      COUT.conn_password = password;
    end
    COUT.conn_type = type;
    COUT.log_path = logpath;
    COUT.data_dir_path = datadir;
    COUT.run_mode = runmode;
    DSRCS(nDSCur+i).handle = COUT;
    DSRCS(nDSCur+i).name = outpid;
  end
  
  
  % Clean up any empty datasource objects that may have been created
  use = zeros(size(DSRCS));
  for i = 1:length(DSRCS),
    if isempty(DSRCS(i).handle),
      use(i) = 0;
    else
      use (i) = 1;
    end
  end
  DSRCS = DSRCS(use==1);
  
  
  % Parse the <signal> object definitions
  xSigs = [ xml.get_child( xGen2 , 'signal' ) ...
    xml.get_child( xDoc , 'signal' ) ];
  nSig = length(xSigs);
  for i=1:nSig,
    sigid = xml.get_attribute( xSigs(i) , 'short-id' );
    scada_id = xml.get_attribute( xSigs(i) , 'scada-id' );
    if isempty( sigid ), sigid = scada_id;
    end
    if isempty( sigid ),
      sigid = xml.get_attribute (xSigs(i) ,'type');
      scada_id = sigid;
    end
    if ~isvarname( sigid ), sigid = genvarname( sigid );
    end
    %    sigid = lower(sigid);
    signal_type = xml.get_attribute( xSigs(i) , 'signal-type' );
    precision = xml.get_attribute( xSigs(i) , 'precision' );
    units = xml.get_attribute( xSigs(i) , 'units' );
    data_min = xml.get_attribute( xSigs(i) , 'data-min' );
    data_max = xml.get_attribute( xSigs(i) , 'data-max' );
    setpt_high = xml.get_attribute( xSigs(i) , 'set-point-max');
    setpt_low = xml.get_attribute(xSigs(i), 'set-point-min');
    info_only = xml.get_attribute( xSigs(i) , 'for-info-only' );
    alarm_scope = xml.get_attribute( xSigs(i) , 'alarm-scope' );
    if isempty(alarm_scope),
      alarm_scope = xml.get_attribute( xSigs(i), 'alarm-signal' );
    end
    normal_value = xml.get_attribute( xSigs(i) , 'normal-value' );
    if isempty(normal_value),
      normal_value = xml.get_attribute( xSigs(i) , 'alarm-normal' );
    end
    if ~isempty(alarm_scope) && isempty(signal_type)
      signal_type = 'ALM';
    end
    if isempty(normal_value),
      normal_value = xml.get_attribute( xSigs(i) , 'normal' );
    end
    if isempty(signal_type)
      signal_type = 'WQ';
    end
    bad_value = xml.get_attribute( xSigs(i) , 'bad-value' );
    lag_steps = xml.get_attribute( xSigs(i) , 'tracking_lag' );
    parameter_type = xml.get_attribute( xSigs(i) , 'parameter_type' );
    if isempty(precision), precision = 1e-4;
    else precision = str2double(precision);
    end
    if isempty(data_min), data_min = -inf;
    else data_min = str2double(data_min);
    end
    if isempty(data_max), data_max = inf;
    else data_max = str2double(data_max);
    end
    if ~isempty(info_only), info_only = xml.bool(info_only);
    else info_only = false;
    end
    if isempty(lag_steps), lag_steps = 0;
    else lag_steps = round(str2double(lag_steps));
    end
    data_ignore = xml.get_attribute(xSigs(i), 'ignore_changes');
    if isempty(data_ignore), data_ignore = 'none';end
    if info_only,
      data_ignore = 'all';
    end
    if isempty(setpt_high), setpt_high = inf;
    else setpt_high = str2double(setpt_high);
    end
    if isempty(setpt_low), setpt_low = -inf;
    else setpt_low = str2double(setpt_low);
    end
    
    SIGS.addSignalDef('name',sigid,...
      'scada_id',scada_id,...
      'signal_type',signal_type,...
      'parameter_type',parameter_type,...
      'precision',precision,...
      'units',units,...
      'data_min',data_min,...
      'data_max',data_max,...
      'alarm_scope',alarm_scope,...
      'alarm_value',bad_value,...
      'normal_value',normal_value,...
      'tracking_lag',lag_steps,...
      'ignore',data_ignore,...
      'setpoint_high',setpt_high,...
      'setpoint_low',setpt_low   );
    
  end
  if ~isempty(xNewSigs),
    SIGS = cws.parse_defs_sigs(xNewSigs,SIGS);
  end
  if ~isempty(SigFile),
    [pathstr,name,ext] = fileparts(SigFile);
    if isempty(pathstr),
      pathstr = datadir;
    end
    SigFile = fullfile(pathstr,[name ext]);
    SIGS = cws.parse_defs_sigs(SigFile,SIGS);
  end
  SIGS.setupCompositeSignals();
  
  % Parse the <algorithm> object definitions
  xAlgs = [    xml.get_child( xGen2 , 'algorithm' ) ...
    xml.get_child( xDoc , 'algorithm' ) ];
  nAlg = length(xAlgs);
  maxWinSizeForStartup = 0;
  if DeBug, cws.trace('CONFIG:algorithms','Defining algorithms'); end;
  for i = 1:nAlg,
    algid = xml.get_attribute( xAlgs(i) , 'short-id' );
    mfile = xml.get_attribute( xAlgs(i) , 'mFile' );
    if isempty( algid ), algid = mfile;
    end
    if ~isvarname( algid ), algid = genvarname( algid );
    end
    n_w = round(str2double(xml.get_attribute( xAlgs(i) , 'window' ) ));
    maxWinSizeForStartup = max(n_w,maxWinSizeForStartup);
    try
      tau_a = eval(xml.get_attribute( xAlgs(i) , 'threshold' ) );
    catch
      tau_a = eval(['[',xml.get_attribute( xAlgs(i) , 'threshold' ),']']);
    end
    bed = xml.bool(xml.get_attribute( xAlgs(i) , 'use-bed' ) );
    n_bmin = round(str2double(xml.get_attribute( xAlgs(i) , ...
      'binom-win-min' ) ) );
    n_bmax = round(str2double(xml.get_attribute( xAlgs(i) , ...
      'binom-win-max' ) ) );
    p_b = str2double(xml.get_attribute( xAlgs(i) , 'binom-p-value' ) );
    tau_b = str2double(xml.get_attribute( xAlgs(i) , 'binom-threshold' ) );
    xUseAlgs = xml.get_child( xAlgs(i) , 'use-algorithm');
    algs_in = {};
    xUseClust = xml.get_child( xAlgs(i) , 'clustering');
    if isempty(xUseClust),
      Clust = xml.get_attribute( xAlgs(i), 'cluster-file');
      if isempty(Clust),
        use_cluster = false;
        library = [];
      else
        use_cluster = true;
        library = char(Clust);
      end
    else
      use_cluster = true;
      library = char(xml.get_attribute(xUseClust(1) , 'file' ));
      if isempty(library),
        library = struct();
        p_thresh = str2double(char(xml.get_attribute(xUseClust(1) , 'p_thresh')));
        if ~isnan(p_thresh), library.p_thresh = p_thresh; end;
        r_order = str2double(char(xml.get_attribute(xUseClust(1) , 'r_order')));
        if ~isnan(r_order), library.r_order = r_order; end;
        n_rpts = str2double(char(xml.get_attribute(xUseClust(1) , 'n_rpts')));
        if ~isnan(n_rpts), library.n_rpts = n_rpts; end;
        p_level = str2double(char(xml.get_attribute(xUseClust(1) , 'p_level')));
        if ~isnan(p_level), library.p_level = p_level; end;
      end
    end
    javaClass = xml.get_attribute( xAlgs(i) , 'java-class' );
    algs_in = cell(length(xUseAlgs),1);
    for iUA = 1:length(xUseAlgs)
      algs_in{iUA} = xml.get_attribute( xUseAlgs(iUA) , 'id' );
    end
    ALGS.addAlgorithmDef('short_id',algid,'type',mfile,'mfile',mfile,...
      'n_h', n_w, 'tau_out', tau_a, 'use_bed', bed, 'n_bed', n_bmin, 'n_eto', n_bmax,...
      'p_out', p_b, 'tau_evt', tau_b, 'algs_in', algs_in, 'javaClass', javaClass, ...
      'use_cluster', use_cluster, 'library', library );
  end
  if ~isempty(xNewAlgs),
    n_w = cws.parse_defs_algs(xNewAlgs,ALGS);
    maxWinSizeForStartup = max(n_w,maxWinSizeForStartup);
  end
  if ~isempty(AlgFile),
    [pathstr,name,ext] = fileparts(AlgFile);
    if isempty(pathstr),
      pathstr = datadir;
    end
    AlgFile = fullfile(pathstr,[name ext]);
    cws.parse_defs_algs(AlgFile,ALGS);
  end
  
  
  MSGR.ts_to_backfill = maxWinSizeForStartup;
  % Parse the <location> object definitions
  xLocs = [ xml.get_child( xGen2 , 'location' )...
	  xml.get_child( xDoc , 'Station' ) ...
		xml.get_child( xGen2 , 'Station' ) ...
    xml.get_child( xDoc , 'location' ) ];
  nLoc = length(xLocs);
  for i = 1:nLoc,
    scada_id = xml.get_attribute( xLocs(i) , 'scada-id' );
    locActive = char(xml.get_attribute( xLocs(i) , 'state' ));
    if ~allowdisableds && strcmpi(locActive,'disabled')
      cws.trace('CONFIG:warning',['Disabled station definition: Location = ',scada_id]);
      continue
    end
    MyLOC = cws.Location(scada_id);
    MyLOC.loc_state = locActive;
    MyLOC.stationNum = str2double(xml.get_attribute(xLocs(i),'Station'));
    if isempty(MyLOC.stationNum) || isnan(MyLOC.stationNum),
      MyLOC.stationNum = str2double(xml.get_attribute(xLocs(i),'output_Station'));
    end
    if isempty(MyLOC.stationNum) || isnan(MyLOC.stationNum),
        MyLOC.stationNum = -i;
    end
    p_warn_thresh = get_attribute(xLocs(i),'outlier-warning-threshold');
    if ~isempty(p_warn_thresh),
      p_warn_thresh = str2double(p_warn_thresh);
      if p_warn_thresh <= 1 && p_warn_thresh >= 0.0,
        MyLOC.p_warn_thresh = p_warn_thresh;
      else
        cws.trace('CONFIG:warning',['Invalid outlier-warning-threshold at station ',scada_id,':  Value = ',get_attribute(xLocs(i),'outlier-warning-threshold')]);
      end
    end
    MyLOC.output_tag = get_attribute( xLocs(i) , 'output_TagName' );
    MyLOC.output_ptnum = get_attribute( xLocs(i) , 'output_PointNr' );
    patListDir = get_attribute( xLocs(i), 'PatListDir' );
    patGrfxDir = get_attribute( xLocs(i), 'PatGraphicsDir');
    if ~isempty(patListDir),
      MyLOC.patListDir = patListDir;
    end
    if ~isempty(patGrfxDir),
      MyLOC.patGrfxDir = patGrfxDir;
    end
    SIGS.addLocationDef(scada_id,MyLOC);
    lInps = xml.get_child( xLocs(i) , 'use-input' );
    lOuts = xml.get_child( xLocs(i) , 'use-output' );
    lSigs = xml.get_child( xLocs(i) , 'use-signal' );
    lAlgs = xml.get_child( xLocs(i) , 'use-algorithm' );
		
		% FOR EACH SIGNAL
    for iS = 1:length(lSigs)
      sigid = xml.get_attribute( lSigs(iS) , 'id' );
      useInLibs = xml.get_attribute( lSigs(iS) , 'no-cluster');
      if isempty(useInLibs), noClust = false;
      else noClust = xml.bool(useInLibs);
      end;
      MyLOC.addSignal(SIGS,sigid, noClust);
    end
		% FOR EACH ALGORITHM
    for iA = 1:length(lAlgs)
      algid = xml.get_attribute( lAlgs(iA) , 'id' );
      MyLOC.addAlgorithm(SIGS,algid);
    end
		% FOR EACH INPUT
    for iL = 1:length(lInps)
      inpid = xml.get_attribute( lInps(iL) , 'id' );
      inpnm = inpid;
      inpid = strmatch(inpid,{DSRCS(:).name},'exact');
      if isempty(inpid),
        inpid = lower(xml.get_attribute( lInps(iL) , 'id' ));
        inpid = [inpid,'_in']; %#ok<AGROW>
        inpid = strmatch(inpid,{DSRCS(:).name},'exact');
      end
      if isempty(inpid)
        cws.trace('CONFIG:warning',['Disabled or missing input id for station ',scada_id,': Name = ',inpnm]);
      else
        MyLOC.addInputID(inpid);
        DSRCS(inpid).handle.useAsInput();
        DSRCS(inpid).handle.use();
      end
    end
		% FOR EACH OUTPUT
    for iL = 1:length(lOuts)
      outid = xml.get_attribute( lOuts(iL) , 'id' );
      outnm = outid;
      outid = strmatch(outid,{DSRCS.name},'exact');
      if isempty(outid),
        outid = lower(xml.get_attribute( lOuts(iL) , 'id' )  );
        outid = [outid,'_out']; %#ok<AGROW>
        outid = strmatch(outid,{DSRCS.name},'exact');
      end
      if isempty(outid)
        cws.trace('CONFIG:warning',['Disabled or missing output id for station: ',scada_id,': Name = ',outnm]);
      else
        MyLOC.addOutputID(outid);
        DSRCS(outid).handle.useAsOutput();
        DSRCS(outid).handle.use();
      end
    end
    if isempty(MyLOC.calib) && ~isempty(MyLOC.name)
      noClust = true;
      sigid = ['CAL_',MyLOC.name];
      SIGS.addSignalDef('name',sigid,...
        'scada_id',sigid,...
        'signal_type','CAL',...
        'parameter_type','QUALITY',...
        'precision',0.01,...
        'units','',...
        'alarm_scope','',...
        'alarm_value','1' );
      MyLOC.addSignal(SIGS,sigid,noClust);
    end
  end
  use = zeros(size(DSRCS));
  for i = 1:length(DSRCS),
    if isempty(DSRCS(i).handle),
      use(i) = 0;
    else use (i) = 1;
    end
  end
  DSRCS = DSRCS(use==1);
  % Save the output objects
  CDef.INPUTS = DSRCS;
  CDef.OUTPUTS = DSRCS;
  CDef.SIGNALS = SIGS;
  CDef.MESSENGER = MSGR;
  CDef.runmode = runmode;
  CDef.datadir = datadir;
  CDef.extras = extras;
  CDef.messaging_mode = MSGR.msgr_type;
  CDef.messaging_id = MSGR.conn_id;

  if TIME.dynamic
    dist = 1+ceil(MSGR.ts_to_backfill / TIME.date_mult);
    TIME.set_date_start(floor(now-dist));
  end
  
  if DeBug, 
    create_config_file( 'debug.cfg.xml' , DSRCS , MSGR , SIGS , runmode , datadir , extras );
  end
  create_yaml_config( [filename '_convert.edsy'] , DSRCS , MSGR , SIGS , runmode , datadir , extras );

  xDoc = []; %#ok<NASGU>
  ObjEDS.dataSignals = SIGS;
  ObjEDS.dataMessenger = MSGR;
  ObjEDS.dataInOut = DSRCS;
  ObjEDS.runDirectory = datadir;
  
end
