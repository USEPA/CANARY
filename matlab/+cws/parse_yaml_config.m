function  [CDef, SIGS, INPS, OUTS] = parse_yaml_config(ObjEDS , ...
    CDef , allowdisableds ) %#ok<*INUSD,*INUSL>
  
  filename = ObjEDS.configFile;
  filepath = ObjEDS.runDirectory;
  logfile  = ObjEDS.logfilePrefix;
  
  import cws.* xml.*;
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL; %#ok<*NODEF>
  global VERSION;
  Version = VERSION;
  drivers.type = '';
  drivers.driver = '';
  drivers.datasource = '';
  drivers.jarfile = '';
  if nargin < 5,
    allowdisableds = false; %#ok<*NASGU>
  end
  if nargin < 1, filename = ''; end;
  if nargin < 4
    CDef = [];
  end
  
  prov_type = 'all';
  
  if nargin < 1 || isempty(filename),
    cws.trace( 'tevaCanary:yamlConfig:fileFailure' , 'No configuration file' );
    error('CANARY:ConfigErr',...
      'No configuration file specified' );
  else
    if DeBug, cws.trace( 'config:load' , filename); end;
    try
      import('org.yaml.snakeyaml.Yaml')
      yamlreader = Yaml();
      ymltxt = fileread(filename);
      jYamlObj = yamlreader.load(ymltxt);
      %%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%
    catch ERRcfg
      base_ME = MException('tevaCanary:yamlConfig:fileFailure',...
        'Unable to load configuration file %s', filename);
      base_ME = addCause(base_ME, ERRcfg);
      throw(base_ME);
    end
  end
  if DeBug, cws.trace( 'config:load' , 'Success!' ); end;

  % Set up return variables (modify existing)
  if isempty(CDef);
    CDef = struct();
    CDef.INPUTS = [];
    CDef.OUTPUTS = [];
    CDef.SIGNALS = [];
    DSRCS(1).handle = [];
    DSRCS(1).name = '';
    SIGS = cws.Signals;
    MSGR = [];
  else
    INPS = CDef.INPUTS;
    OUTS = CDef.OUTPUTS;
    SIGS = CDef.SIGNALS;
    MSGR = CDef.MESSENGER;
  end
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
  [ p, configName] = fileparts(filename);
  SIGS.filepath = filepath;
  SIGS.case_prefix = [configName '.'];
  SIGS.configfile = filename;
  SIGS.prov_type = prov_type;
  skipMsgBld = false;
  
  rootKeys = cell(jYamlObj.keySet().toArray());
  tryRestart = ObjEDS.useContinue;
  yamlDatasourceList = [];
  
  yParamList = [];
  ObjEDS.cfgControl = DefnControl();
  ObjEDS.cfgControl.fromFile = filename;
  ObjEDS.cfgControl.controlType = 'INTERNAL';
  
  for iKey = 1:length(rootKeys)
    vKey = rootKeys{iKey};
    switch (vKey)
      case {'runMode'}
        ObjEDS.cfgControl.runMode = char(jYamlObj.get(vKey));
      case {'dataDir'}
        ObjEDS.runDirectory = char(jYamlObj.get(vKey));
      case {'extraJarFiles'}
        ObjEDS.cfgControl.driverJarFiles = jYamlObj.get(vKey);
      case {'control'}
        yCtl = jYamlObj.get(vKey);
        if yCtl.containsKey('type')
          ObjEDS.cfgControl.controlType = char(yCtl.get('type'));
        else
          ObjEDS.cfgControl.controlType = 'INTERNAL';
        end
        if yCtl.containsKey('messenger')
          ObjEDS.cfgControl.messengerId = char(yCtl.get('messenger'));
        end
      case {'canary'}
        yCanaryObj = jYamlObj.get(vKey);
        ObjEDS.cfgControl.configure(yCanaryObj);
        if ~tryRestart,
          tryRestart = ObjEDS.cfgControl.useRestart;
        end
        SIGS.prov_type = ObjEDS.cfgControl.dataStyle;
      case {'timingOptions','timing options'}
        ymlTimingObj = jYamlObj.get(vKey);
        TIME.configure(ymlTimingObj);
      case {'datasource','datasources','datasource list','data sources'}
        yamlDatasourceList = jYamlObj.get(vKey).toArray;
      case {'signal','signals','signal list'}
        ySignalList = jYamlObj.get(vKey).toArray;
      case {'algorithm','algorithms','algorithm list'}
        yAlgorithmList = jYamlObj.get(vKey).toArray();
      case {'station','stations','station list','monitoring stations'}
        yStaionList = jYamlObj.get(vKey).toArray;
      case {'parameters','parameter definitions'}
        yParamList = jYamlObj.get(vKey).toArray;
      otherwise
        warning('canary:yaml:config','Unknown entry in configuration file: %s',vKey)
    end %end of switch
  end %end of for key in rootKeys

  % Star of processing
  if ~isdeployed
    S = dbstatus;
  end
  if ~isempty(ObjEDS.cfgControl.driverJarFiles),
    switch class(ObjEDS.cfgControl.driverJarFiles)
      case {'java.util.ArrayList'}
        paths = {};
        ex = ObjEDS.cfgControl.driverJarFiles.iterator();
        i = 0;
        while ex.hasNext()
          i = i+1;
          paths{i} = char(ex.next());
        end
        clear 'ex' ;
        ObjEDS.cfgControl.driverJarFiles = paths;
        for i = 1:length(ObjEDS.cfgControl.driverJarFiles)
          JPath = javaclasspath;
          if isempty(strmatch(ObjEDS.cfgControl.driverJarFiles{i},JPath,'exact')),
            try
              javaaddpath(ObjEDS.cfgControl.driverJarFiles{i});
            catch ERR
              cws.errTrace(ERR);
            end
          end
        end
      case {'cell'}
        for i = 1:length(ObjEDS.cfgControl.driverJarFiles)
          JPath = javaclasspath;
          if isempty(strmatch(ObjEDS.cfgControl.driverJarFiles{i},JPath,'exact')),
            try
              javaaddpath(ObjEDS.cfgControl.driverJarFiles{i});
            catch ERR
              cws.errTrace(ERR);
            end
          end
        end
      otherwise
        ObjEDS.cfgControl.driverJarFiles = {ObjEDS.cfgControl.driverJarFiles};
        JPath = javaclasspath;
        if isempty(strmatch(ObjEDS.cfgControl.driverJarFiles{1},JPath,'exact')),
          try
            javaaddpath(ObjEDS.cfgControl.driverJarFiles{1});
          catch ERR
            cws.errTrace(ERR);
          end
        end
    end
    clear DEBUG_LEVEL VERSION;
    global DEBUG_LEVEL; %#ok<TLEV,REDEF>
    DEBUG_LEVEL = DeBug; %#ok<NASGU>
    global VERSION; %#ok<TLEV,REDEF>
    VERSION = Version; %#ok<NASGU>
  end;
  if ~isdeployed
    dbstop(S);
  end
  ObjEDS.cfgDatasources = repmat(cws.DefnDatasource,length(yamlDatasourceList),1);
  for i = 1:length(yamlDatasourceList)
    ds = yamlDatasourceList(i);
    if ds.containsKey('id');
      try
        dsId = ds.get('id');
        dsType = ds.get('type');
        switch lower(char(dsType))
          case {'db','jdbc'}
            DS = cws.JDBCDataSource(ds);
          case {'eddies'}
            DS = cws.EDDIESDataSource(ds);
          case {'xml'}
            DS = cws.XMLDataSource(ds);
          case {'csv','file','files','csvfile','csv-file','csv file'}
            DS = cws.CSVDataSource(ds);
          otherwise
            error('CANARY:datasource','unknown connection type: "%s" in data source definition "%s"',char(dsType),char(dsId));
            DS = cws.DataSource(ds);
        end
        DS.run_mode = ObjEDS.cfgControl.runMode;
        DS.conn_id_num = i;
        ObjEDS.cfgDatasources(i) = DS.saveCurrentConfiguration();
        %DS.data_dir_path = datadir;
        %DS.log_path = logpath;
        DS.time = TIME;
        DSRCS(i).name = dsId; %#ok<*AGROW>
        DSRCS(i).handle = DS;
      catch ERR
        cws.errTrace(ERR);
      end
    end
  end
  
  if ~isempty(ObjEDS.cfgControl.messengerId) && ~strcmpi(ObjEDS.cfgControl.messengerId,'')
    Num = find(strcmp({ DSRCS(:).name },ObjEDS.cfgControl.messengerId));
    if Num > 0,
      MSGR = DSRCS(Num).handle;
      MSGR.useAsControl();
      MSGR.msgr_type = ObjEDS.cfgControl.controlType;
    end
  end
  if isempty(ObjEDS.cfgControl.messengerId)
    MSGR = cws.MSGRDataSource();
    MSGR.useAsControl();
    id = 'CONTROL';
    MSGR.conn_id = id;
    MSGR.conn_type = 'MSGR';
    MSGR.msgr_type = ObjEDS.cfgControl.controlType;
    MSGR.conn_url = '';
    MSGR.driver_datasource_class = '';
    MSGR.run_mode = ObjEDS.cfgControl.runMode;
    %MSGR.data_dir_path = datadir;
    %MSGR.log_path = logpath;
    MSGR.time = TIME;
  end
  
  for i = 1:length(yParamList)
    param = yParamList(i);
    if param.containsKey('id');
      try
        newP = cws.Parameter(param);
      catch ERR
        cws.errTrace(ERR);
      end
      SIGS.parameters.(newP.id) = newP;
    end
  end
  
  for i = 1:length(ySignalList)
    sig = ySignalList(i);
    if sig.containsKey('id');
      try
        sigCfg = cws.DefnSignal();
        sigCfg.configure(sig);
        SIGS.configureSignal(sig);
      catch ERR
        cws.errTrace(ERR);
      end
    end
  end
  SIGS.setupCompositeSignals();
  
  maxWinSize = 0;
  for i = 1:length(yAlgorithmList)
    alg = yAlgorithmList(i);
    if alg.containsKey('id');
      try
        ALGS.configureAlgorithm(alg);
      catch ERR
        cws.errTrace(ERR);
      end
    end
    if alg.containsKey('history window')
      norm_window = alg.get('history window');
      maxWinSize = max([maxWinSize, norm_window]);
    end
  end
  MSGR.ts_to_backfill = max([maxWinSize, TIME.date_mult]);
  
  for i = 1:length(yStaionList)
    stn = yStaionList(i);
    if stn.containsKey('id');
      try
        stnId = stn.get('id');
        MyLOC = cws.Location(stnId);
        MyLOC.configureStation(stn,SIGS,DSRCS);
        SIGS.addLocationDef(stnId,MyLOC);
      catch ERR
        cws.errTrace(ERR);
      end
    end
  end
  
  if tryRestart,
    DirCont = dir('.');
    Files = {DirCont.name};
    Restart = [];
    for i = 1:length(Files),
      F = Files(i);
      isContinue = strcmpi(F,'continue.edsd');
      if isContinue,
        Restart = load('continue.edsd','-MAT');
      end
    end
    if ~isempty(Restart),
      fprintf(2,'WARNING! Using a restart file means that NOT ALL CHANGES WILL BE APPLIED\n');
      fprintf(2,'         Changes to EXISTING SIGNALS will be applied (limits, precision, etc.).\n');
      fprintf(2,'         Changes to MONITORING STATIONS and ALGORITHMS will NOT be applied\n');
      fprintf(2,'         If this is not the desired effect, you MUST delete the "continue.edsd"\n');
      fprintf(2,'         file from the current directory, or set "use restart: False" in the\n');
      fprintf(2,'         configuration file.\n');
      fprintf(2,'WARNING! Now loading "continue.edsd" and continuing interrupted run!\n');
      orig_time = TIME;
      TIME = Restart.self.time;
      MSGR.time = TIME;

      SIGS.algorithms = Restart.self.algorithms;
      SIGS.time = TIME;
      SIGS.deepCopy(Restart.self);
      for i = 1:length(DSRCS),
        DSRCS(i).handle.time = TIME;
      end
    else
      tryRestart = false;
    end
    MSGR.use_continue = tryRestart;
  end
  
  CDef.INPUTS = DSRCS;
  CDef.OUTPUTS = DSRCS;
  CDef.SIGNALS = SIGS;
  CDef.MESSENGER = MSGR;
  CDef.runmode = ObjEDS.cfgControl.runMode;
  CDef.datadir = pwd;
  CDef.extras = ObjEDS.cfgControl.driverJarFiles;
  CDef.messaging_mode = MSGR.msgr_type;
  CDef.messaging_id = MSGR.conn_id;
  %TIME.set_dynamic(MSGR);
  if TIME.dynamic && ~tryRestart
    dist = ceil(1 + (MSGR.ts_to_backfill / TIME.date_mult));
    TIME.set_date_start(floor(now-dist));
    TIME.set_date_end(ceil(now+1));
  elseif TIME.dynamic && tryRestart
    cur_idx = TIME.getDateIdx(now);
    MSGR.ts_to_backfill = min([MSGR.ts_to_backfill,...
                        cur_idx - SIGS.locations(1).handle.lastIdxEvaluated + 3]);
    TIME.set_date_end(ceil(now+1));
  end
  create_yaml_config( [configName,'_out.yml'] , DSRCS , MSGR , SIGS , ObjEDS.cfgControl.runMode , filepath , ObjEDS.cfgControl.driverJarFiles );
  
  ObjEDS.dataSignals = SIGS;
  ObjEDS.dataMessenger = MSGR;
  ObjEDS.dataInOut = DSRCS;
  ObjEDS.runDirectory = CDef.datadir;
  ObjEDS.dataTiming = TIME;

  
