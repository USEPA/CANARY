classdef DefnDatasource < handle
  %UNTITLED8 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    fromFile
    id
    
    dsType
    dsLocation
    
    dsLocTSAppend
    dsLocFormatStr
    
    enabled
    
    dsConfigFile
    dsMesgWaitSec = 0;
    
    tsField = 'TIME_STEP';
    tsFormat
    tsConvertFunc
    
    dsTimeShift = 0;
    dsJavaClass
    
    inputTable = 'CWS_INPUT';
    inputCurrent = false;
    inputFormat = 'default';
    inputFieldTimestep = 'TIME_STEP';
    inputFieldSCADATag = 'TAG_NAME';
    inputFieldTagType
    inputFieldValue = 'VALUE';
    inputFieldQuality = false;
    inputFieldQualType
    
    outputTable = 'CWS_OUTPUT';
    outputFormat = 'default';
    outputConditions = 'ALL';
    outputFieldTimestep = 'TIME_STEP';
    outputFieldInstanceId = 'INSTANCE_ID';
    outputFieldStationId = 'LOCATION_ID';
    outputFieldAlgorithmId = false;
    outputFieldParameterId = false;
    outputFieldParamResid = false;
    outputFieldParamTag = false;
    outputFieldEventCode = 'DETECTION_INDICATOR';
    outputFieldEventProb = 'DETECTION_PROBABILITY';
    outputFieldEventContrib = 'CONTRIBUTING_PARAMETERS';
    outputFieldPatId1 = false;
    outputFieldPatId2 = false;
    outputFieldPatId3 = false;
    outputFieldPatProb1 = false;
    outputFieldPatProb2 = false;
    outputFieldPatProb3 = false;
    outputFieldComments = 'ANALYSIS_COMMENTS';
    
    dsLoginRequired = false;
    dsLoginPrompt = false;
    dsLoginUser
    dsLoginPass
    
  end
  
  methods
    
    function self = DefnDatasource( varargin )
      if nargin == 1 && isa(varargin(1),'java.util.LinkedHashMap')
        self.configure(HashMap);
      end
    end
    
    function self = configure(self, HashMap)
      keys = HashMap.keySet.toArray();
      for ik = 1:length(keys)
        key = char(keys(ik));
        val = HashMap.get(key);
        switch (key)
          case 'id'
            self.id = char(val);
          case 'type'
            self.dsType = lower(char(val));
          case {'location','file name','url'}
            self.dsLocation = char(val);
          case 'enabled'
            if val, self.enabled = 'enabled';
            else self.enabled = 'disabled';
            end
          case 'configFile'
            if ~isempty(val)
              self.dsConfigFile = char(val);
            end
          case 'message waiting period'
            self.dsMesgWaitSec = val;
          case {'timestepOpts','timestep options','time step options','time-step options'}
            toKeys = val.keySet.toArray();
            for it = 1:length(toKeys),
              tKey = char(toKeys(it));
              tVal = val.get(tKey);
              switch(tKey)
                case 'field'
                  self.tsField = char(tVal);
                case 'format'
                  self.tsFormat = char(tVal);
                case {'convertFunc','convert function','conversion function'}
                  self.tsConvertFunc = char(tVal);
                otherwise
                  fprintf(2,'Unknown option - datasource => %s => %s: \n',key,tKey,tVal.toString());
              end
            end
          case {'databaseOpts','database options','database'}
            doKeys = val.keySet.toArray();
            for iK = 1:length(doKeys),
              dKey = char(doKeys(iK));
              dVal = val.get(dKey);
              switch dKey
                case {'className','class name','JDBC2 class name'}
                  self.dsJavaClass = char(dVal);
                case {'inputTable', 'input table'}
                  self.inputTable = char(dVal);
                case {'input table only has current'}
                  self.inputCurrent = dVal;
                case {'inputFormat', 'input format','input fields'}
                  if isa(dVal,'java.util.HashMap')
                    self.inputFormat = 'custom';
                    foKeys = dVal.keySet.toArray();
                    for foid = 1:length(foKeys),
                      fKey = char(foKeys(foid));
                      fVal = dVal.get(fKey);
                      if isa(fVal,'java.lang.String')
                        ffval = char(fVal);
                      else
                        ffval = fVal;
                      end
                      switch fKey
                        case {'timestep','timestep field','timestamp','time-step'}
                          self.inputFieldTimestep = ffval;
                        case {'parameterTag','parameter tag'}
                            self.inputFieldSCADATag = ffval;
                        case {'parameterValue','parameter value'}
                          self.inputFieldValue = ffval;
                        case {'parameterQuality','parameter quality'}
                          self.inputFieldQuality = ffval;
                        otherwise
                          fprintf(2,'Unknown option - datasource => %s => %s => %s: %s\n',key,dKey,fKey,fVal.toString());
                      end
                    end
                  else
                    if isempty(dVal)
                      dVal = 'default';
                    end
                    self.inputFormat = char(dVal);
                  end
                case {'outputTable','output table'}
                  self.outputTable = char(dVal);
                case {'outputFormat','output format','output fields'}
                  if isa(dVal,'java.util.HashMap')
                      %self.outputFormat = 'custom';
                    foKeys = dVal.keySet.toArray();
                    for foid = 1:length(foKeys),
                      fKey = char(foKeys(foid));
                      fVal = dVal.get(fKey);
                      if isa(fVal,'java.lang.String')
                        ffval = char(fVal);
                      else
                        ffval = fVal;
                      end
                      switch fKey
                        case {'conditions','write conditions'}
                          self.outputConditions = ffval;
                        case {'timestep','time step','timestamp','time-step'}
                          self.outputFieldTimestep = ffval;
                        case {'instanceID','instance name','instance ID','instance id'}
                          self.outputFieldInstanceId = ffval;
                        case {'stationID','station name','station ID','station id'}
                          self.outputFieldStationId = ffval;
                        case {'algorithmID','algorithm name','algorithm ID','algorithm id'}
                          self.outputFieldAlgorithmId = ffval;
                        case {'parameterID','parameter name','parameter ID','parameter id'}
                          self.outputFieldParameterId = ffval;
                        case {'parameterResid','parameter resid','parameter residual'}
                          self.outputFieldParamResid =  ffval;
                        case {'parameterTag','parameter tag'}
                          self.outputFieldParamTag = ffval;
                        case {'eventCode','event code','event status','status code'}
                          self.outputFieldEventCode = ffval;
                        case {'eventProb','event prob','event probability','probability of event'}
                          self.outputFieldEventProb = ffval;
                        case {'eventContrib','event contrib','contributing parameters'}
                          self.outputFieldEventContrib = ffval;
                        case {'comments'}
                          self.outputFieldComments = ffval;
                        case {'pattern match id','patternID','pattern ID','pattern id'}
                          self.outputFieldPatId1 = ffval;
                        case {'pattern match probability','patternProb','pattern probability','match probability'}
                          self.outputFieldPatProb1 = ffval;
                        case {'secondary match id','patternID2','pattern ID 2','pattern id 2'}
                          self.outputFieldPatId2 = ffval;
                        case {'secondary match probability','patternProb2','pattern probability 2','match probability 2'}
                          self.outputFieldPatProb2 = ffval;
                        case {'tertiary match id','patternID3','pattern ID 3','pattern id 3'}
                          self.outputFieldPatId3 = ffval;
                        case {'tertiary match probability','patternProb3','pattern probability 3','match probability 3'}
                          self.outputFieldPatProb3 = ffval;
                        otherwise
                          fprintf(2,'Unknown option - datasource => %s => %s => %s: %s\n',key,dKey,fKey,ffval);
                      end
                    end
                  else
                    if isempty(dVal)
                      dVal = 'default';
                    end
                    self.outputFormat = char(dVal);
                  end
                case {'timeDrift','time drift','server time offset'}
                  self.dsTimeShift = dVal;
                case 'login'
                  self.dsLoginRequired = true;
                  if dVal.containsKey('username')
                    self.dsLoginUser = char(dVal.get('username'));
                  end
                  if dVal.containsKey('password')
                    self.dsLoginPass = char(dVal.get('password'));
                  end
                  if dVal.containsKey('promptForLogin')
                    self.dsLoginPrompt = dVal.get('promptForLogin');
                  end
                  if dVal.containsKey('interactive login')
                    self.dsLoginPrompt = dVal.get('interactive login');
                  end
                  if dVal.containsKey('prompt for login')
                    self.dsLoginPrompt = dVal.get('prompt for login');
                  end
                otherwise
                  fprintf(2,'Unknown option - datasource => %s => %s: %s\n',key,dKey,dVal.toString());
              end
            end
          otherwise
            fprintf(2,'Unknown option - datasource => %s: %s\n',key,val.toString());
        end
      end
    end
    
    function str = char(self)
      % Print the datasource object as a dictionary, provided as an array
      % element (the starting -). The details output depend on the
      % configuration; default values or null values may be omitted.
      str = sprintf('- id: %s\n', self.id);
      str = sprintf('%s  type       : %s\n',str,self.dsType);
      str = sprintf('%s  location   : %s\n',str,self.dsLocation);
      if strcmpi(self.enabled,'enabled')
        str = sprintf('%s  enabled    : yes\n',str);
      else
        str = sprintf('%s  enabled    : no\n',str);
      end
      if ~isempty(self.dsConfigFile) && ~strcmpi(self.dsConfigFile,''),
        str = sprintf('%s  configFile: %s\n',str, self.dsConfigFile);
      end
      str = sprintf('%s  message waiting period: %d\n',str,self.dsMesgWaitSec);
      str = sprintf('%s  time-step options:\n',str);
      str = sprintf('%s    field: %s\n',str, ...
        yaml.toString(self.tsField,'"'));
      if ~isempty(self.tsFormat)
        str = sprintf('%s    format: %s\n',str, ...
          yaml.toString(self.tsFormat,'"'));
      end
      if ~isempty(self.tsConvertFunc)
        str = sprintf('%s    conversion function: %s\n',str, ...
          yaml.toString(self.tsConvertFunc,'"'));
      end
      if strcmpi(self.dsType,'db') || ...
          strcmpi(self.dsType,'eddies') || ...
          strcmpi(self.dsType,'jdbc')
        str = sprintf('%s  database options:\n',str);
        str = sprintf('%s    time drift: %s\n',str, yaml.toString(self.dsTimeShift));
        str = sprintf('%s    JDBC2 class name: %s\n',str, yaml.toString(self.dsJavaClass));
        str = sprintf('%s    input table: %s\n',str, yaml.toString(self.inputTable));
        % str = sprintf('%s    input table only has current: %s\n',str,yaml.toString(self.inputCurrent));
        str = sprintf('%s    input format : %s\n',str, yaml.toString(self.inputFormat));
        if strcmpi(self.inputFormat,'custom')
          str = sprintf('%s    input fields :\n',str);
          str = sprintf('%s      time-step : %s\n',str,yaml.toString(self.inputFieldTimestep));
          str = sprintf('%s      parameter tag : %s\n',str,yaml.toString(self.inputFieldSCADATag));
          str = sprintf('%s      parameter value : %s\n',str,yaml.toString(self.inputFieldValue));
          str = sprintf('%s      parameter quality : %s\n',str,yaml.toString(self.inputFieldQuality));
        end
        str = sprintf('%s    output table : %s\n',str, yaml.toString(self.outputTable));
        str = sprintf('%s    output format: %s\n',str, yaml.toString(self.outputFormat));
        %if strcmpi(self.outputFormat,'custom') 
          str = sprintf('%s    output fields :\n',str);
          str = sprintf('%s      write conditions : %s\n',str,yaml.toString(self.outputConditions));
          str = sprintf('%s      time-step : %s\n',str,yaml.toString(self.outputFieldTimestep));
          str = sprintf('%s      instance id : %s\n',str,yaml.toString(self.outputFieldInstanceId));
          str = sprintf('%s      station id : %s\n',str,yaml.toString(self.outputFieldStationId));
          str = sprintf('%s      algorithm id : %s\n',str,yaml.toString(self.outputFieldAlgorithmId));
          str = sprintf('%s      parameter type : %s\n',str,yaml.toString(self.outputFieldParameterId));
          str = sprintf('%s      parameter residual : %s\n',str,yaml.toString(self.outputFieldParamResid));
          str = sprintf('%s      parameter tag : %s\n',str,yaml.toString(self.outputFieldParamTag));
          str = sprintf('%s      event code : %s\n',str,yaml.toString(self.outputFieldEventCode));
          str = sprintf('%s      event probability : %s\n',str,yaml.toString(self.outputFieldEventProb));
          str = sprintf('%s      contributing parameters : %s\n',str,yaml.toString(self.outputFieldEventContrib));
          str = sprintf('%s      pattern match id : %s\n',str,yaml.toString(self.outputFieldPatId1));
          str = sprintf('%s      pattern match probability : %s\n',str,yaml.toString(self.outputFieldPatProb1));
          str = sprintf('%s      secondary match id : %s\n',str,yaml.toString(self.outputFieldPatId2));
          str = sprintf('%s      secondary match probability : %s\n',str,yaml.toString(self.outputFieldPatProb2));
          str = sprintf('%s      tertiary match id : %s\n',str,yaml.toString(self.outputFieldPatId3));
          str = sprintf('%s      tertiary match probability : %s\n',str,yaml.toString(self.outputFieldPatProb3));
          str = sprintf('%s      comments : %s\n',str,yaml.toString(self.outputFieldComments));
          %end
        str = sprintf('%s    login:\n',str);
        str = sprintf('%s      prompt for login: %s\n',str, yaml.toString(self.dsLoginPrompt,'yn'));
        if ~self.dsLoginPrompt
          str = sprintf('%s      username : %s\n',str, yaml.toString(self.dsLoginUser));
          str = sprintf('%s      password : %s\n',str, yaml.toString(self.dsLoginPass));
        end
      end
    end

    
    
  end
  
end

