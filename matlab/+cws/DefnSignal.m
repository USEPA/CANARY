classdef DefnSignal < handle
  %UNTITLED2 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    fromFile
    id
    scadaTag
    sqlTagStr
    tagType
    
    descr
    units
    
    evalType
    evalIgnore
    
    paramTypeId
    paramTypeStr
    paramTypeNum
    
    valEps
    valMin
    valMax
    
    setErrLo
    setErrHi
    setErrEps
    
    rocLimDec
    rocLimInc
    rocPeriod
    
    valOffline
    valFrozen
    valLag
    
    dataCol
    
    alarmScope
    alarmValue
    alarmNormal
    
    idLookUp
    idStation
    idPointNr
    
    compositeSignal
  end
  
  methods
    function self = configure(self, HashMap)
      try
        keys = HashMap.keySet().toArray();
        for i = 1:length(keys)
          key = char(keys(i));
          val = HashMap.get(key);
          switch key
            case 'id'
              self.id = char(val);
            case {'SCADATag','scada tag','SCADA tag'}
              if isnumeric(val),
                self.scadaTag = sprintf('%d',val);
                self.tagType = 'num';
                self.sqlTagStr = sprintf('%d',val);
              else
                self.scadaTag = char(val);
                self.tagType = 'str';
                self.sqlTagStr = sprintf('''%s''',char(val));
              end
            case {'type','evaluation type'}
              switch lower(char(val))
                case {'wq','water quality','quality'}, self.evalType = 1;
                case {'op','operations','supplemental'}, self.evalType = 2;
                case {'alm','alarm','hardware alarm'}, self.evalType = -1;
                case {'cal','calibration'}, self.evalType = 0;
                case {'info','information'}, self.evalType = nan;
                otherwise
                  fprintf(2,'(WARNING) Unknown value for signal:%s::type: %s\n',...
                    self.id,char(val));
              end
            case {'parameter','parameter type'}
              self.paramTypeStr = char(val);
            case {'ignore','ignoreChanges','ignore changes'}
              switch lower(val)
                case{'none'}, self.evalIgnore = 0;
                case{'increases'}, self.evalIgnore = 1;
                case{'decreases'}, self.evalIgnore = -1;
                case{'both'}, self.evalIgnore = 2;
                case{'all'}, self.evalIgnore = nan;
                otherwise
                  fprintf(2,'(WARNING) Unknown value for signal:%s::ignoreChanges: %s\n',...
                    self.id,char(val));
              end
            case {'trackingLag','tracking lag'}
              self.valLag = val;
            case {'description'}
              self.descr = char(val);
            case {'dataType','data options'}
              sKeyList = cell(val.keySet().toArray());
              for iSub = 1:length(sKeyList)
                sKey = sKeyList{iSub};
                switch sKey
                  case {'precision'} 
                    self.valEps = val.get(sKey);
                  case {'RoC limit decreasing'}
                    self.rocLimDec = val.get(sKey);
                  case {'RoC limit increasing'}
                    self.rocLimInc = val.get(sKey);
                  case {'RoC period'}
                    self.rocPeriod = val.get(sKey);
                  case {'value when offline'}
                    self.valOffline = val.get(sKey);
                  case {'frozen value limit'}
                    self.valFrozen = val.get(sKey);
                  case {'units'}
                    self.units = char(val.get(sKey));
                  case {'validRange','valid range'}
                    range = val.get(sKey).toArray();
                    if length(range) ~= 2,
                      fprintf(2,'(WARNING) Unknown key/value for signal:%s::dataType:validRange: %s\n',...
                        self.id,char(val.get(sKey).toString()));
                    else
                      self.valMin = range(1);
                      self.valMax = range(2);
                    end
                  case {'setPoints','set points','set-points'}
                    range = val.get(sKey).toArray();
                    if length(range) ~= 2,
                      fprintf(2,'(WARNING) Unknown key/value for signal:%s::dataType:validRange: %s',...
                        self.id,char(val.get(sKey).toString()));
                    else
                      self.setErrLo = range(1);
                      self.setErrHi = range(2);
                    end
                  otherwise
                    fprintf(2,'(WARNING) Unknown key for signal[%s] => %s => %s',...
                      self.id,char(key),char(sKey));
                end
              end
            case {'alarmType','alarm options'}
              sKeyList = cell(val.keySet().toArray());
              for iSub = 1:length(sKeyList)
                sKey = sKeyList{iSub};
                switch sKey
                  case {'scope'}
                    self.alarmScope = char(val.get(sKey));
                  case {'value when active','valueWhenActive'}
                    vwa = val.get(sKey);
                    self.alarmValue = num2str(vwa);
                  otherwise
                    fprintf(2,'(WARNING) Unknown key for signal[%s] => %s => %s',...
                      self.id,key,sKey);
                end
              end
            case {'compositeType','composite rules','composite operations'}
              composite_string = val;
              composite_list = textscan(composite_string,'%s');
              composite_list = composite_list{1};
              composite_signal = struct('rp_signal_names',{ {} },'rp_value_cols',{ [] },'rp_row_shift',{ [] },'rp_commands',{ {} },'function',{ {} });
              for iE = 1:length(composite_list)
                val = composite_list{iE};
                if isempty(val), break; end;
                composite_signal.rp_signal_names{iE} = '';
                composite_signal.rp_value_cols(iE) = 0;
                composite_signal.rp_row_shift(iE) = 0;
                composite_signal.rp_commands{iE} = '';
                switch val(1)
                  case '@'
                    val2 = regexprep(val,'@|\[|\]',' ');
                    val3 = textscan(val2,'%s %d');
                    sig_name = char(val3{1});
                    sig_shift = val3{2};
                    if isempty(sig_shift) || isnan(sig_shift),
                      sig_shift = 0; 
                    end;
                    composite_signal.rp_signal_names{iE} = sig_name;
                    composite_signal.rp_row_shift(iE) = sig_shift;
                  case '('
                    val2 = regexprep(val,'\(|\)','');
                    composite_signal.rp_signal_names{iE} = val2;
                    composite_signal.rp_value_cols(iE) = -1;
                  otherwise
                    composite_signal.rp_commands{iE} = val;
                    composite_signal.rp_value_cols(iE) = -2;
                end
              end
              self.compositeSignal = composite_signal;
            otherwise
              fprintf(2,'(WARNING) Unknown key/value for signal[%s] => %s',...
                self.id,key);
          end
        end
      catch ERR
        disp(HashMap.toString())
        cws.errTrace(ERR);
        rethrow(ERR)
      end
    end
  
  end
  
end

