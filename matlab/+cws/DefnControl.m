classdef DefnControl < handle
  %UNTITLED11 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    fromFile
    runMode         % 'REALTIME', 'BATCH'
    driverJarFiles  %
    controlType     % 'INTERNAL', 'EXTERNAL', 'EDDIES'
    messengerId     % string
    useRestart = false; % true or false
    dataStyle = 'EVERY';% 'EVERY', 'CHANGES',
    
  end
  
  methods
    
    function self = configure(self, HashMap)
      sKeys = cell(HashMap.keySet().toArray());
      for isKey = 1:length(sKeys)
        sKey = sKeys{isKey};
        switch sKey
          case {'run mode','run_mode','runMode'}
            self.runMode = char(HashMap.get(sKey));
          case {'control type','control_type','controlType','type'}
            self.controlType = char(HashMap.get(sKey));
          case {'control messenger','messenger'}
            self.messengerId = char(HashMap.get(sKey));
          case {'driver files','extraJarFiles','jar files'}
            self.driverJarFiles = HashMap.get(sKey);
          case {'use restart','use continue'}
            self.useRestart = HashMap.get(sKey);
          case {'data provided','data provisioning'}
            self.dataStyle = char(HashMap.get(sKey));
        end
      end
    end
    
    
    function str = char(self)
      str = sprintf('\ncanary:\n');
      str = sprintf('%s  run mode: %s\n',str,upper(self.runMode));
      str = sprintf('%s  control type: %s\n',str,upper(self.controlType));
      switch upper(self.controlType)
        case {'INTERNAL'}
          str = sprintf('%s  control messenger: %s\n',str,'null');
        otherwise
          str = sprintf('%s  control messenger: %s\n',str,self.messengerId);
      end
      if ~isempty(self.driverJarFiles)
        str = sprintf('%s  driver files:\n',str);
        for i = 1:length(self.driverJarFiles),
          str = sprintf('%s  - %s\n',str,self.driverJarFiles{i});
        end
      else
        str = sprintf('%s  driver files: null\n',str);
      end
      if self.useRestart,
        str = sprintf('%s  use continue: yes\n',str);
      else
        str = sprintf('%s  use continue: no\n',str);
      end
      str = sprintf('%s  data provided: %s\n',str,upper(self.dataStyle));  
    end
    
  end
  
end

