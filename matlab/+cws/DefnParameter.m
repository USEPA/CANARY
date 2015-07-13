classdef DefnParameter < handle
  properties
    fromFile
    id
    typeStr 
    typeNum
    
    % Descriptive properties
    descr  % a long description of the parameter
    units  % units used on output
    
    % Physical limitations / event detection algorithm modifiers (eps)
    valEps % minimum change that is "real"
    valMin % physical constraints / valid range of values
    valMax 
    
    % Set-Point anomaly detection
    setErrLo % set-point error-level values
    setErrHi 
    setErrEps 
    
    % Pattern Matching 
    patDelta % The discretization step size for pattern matching
    patSigma % standard deviation of values around a "true" measure
    patZero  % the zero-point to use when creating pattern; -inf or inf is relative
    
    % Rate-Of-Change anomaly detection
    valFrozen % numbe of steps of 0.00 change for warning of frozen param to be raised
    valOffline
    
    % Graphics
    graphGroup
  end
  
  methods
    function self = Parameter( varargin )
      %PARAMETER/PARAMETER constructs a new PARAMETER object using either
      %an existing PARAMETER object or a HASHMAP object as the
      %configuration source
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'Parameter')
          % Copy all field values from the existing parameter object. This
          % is a shallow copy, but should be satisfactory, since all
          % properties of this class are scalars / vectors, not objects
          FN = fieldnames(self);
          for i = 1:length(FN),
            self.(char(FN(i))) = obj.(char(FN(i)));
          end
        elseif isa(obj,'java.util.LinkedHashMap')
          % Use the more detailed construction method if this was read from
          % a JSON or YAML file
          self.configure(obj);
        else
          error('CANARY:parametertype',...
            'Unknown construction method for %s: %s',...
            class(self),class(obj));
        end
      end
    end
    
    function str = printYAML(self)
      str = sprintf('- id: %s\n', self.id);
      str = sprintf('%s  description: %s\n',str, self.description);
      str = sprintf('%s  units: %s\n',str, self.units);
      str = sprintf('%s  algorithm epsilon: %s\n',str, ...
        yaml.num2str(self.valEps));
      str = sprintf('%s  setpoint precision: %s\n',str, ...
        yaml.num2str(self.setErrEps));
      str = sprintf('%s  valid range: [%s, %s]\n',str, ...
        yaml.num2str(self.valMin), yaml.num2str(self.valMax));
      str = sprintf('%s  error setpoints: [%s, %s]\n',str, ...
        yaml.num2str(self.setErrLo), yaml.num2str(self.setErrHi));
      str = sprintf('%s  frozen after: %s\n',str, ...
        yaml.num2str(self.valFrozen));
      str = sprintf('%s  graphing group: %s\n',str, self.graphGroup);
    end
    
    function self = configure( self, HashMap )
      keys = HashMap.keySet.toArray();
      for iKey = 1:length(keys)
        % Process each key in the mapping.
        key = char(keys(iKey));
        val = HashMap.get(key);
        switch (key)
          case 'id'
            self.id = char(val);
          case 'description'
            self.descr = char(val);
          case 'units'
            self.units = char(val);
          case {'algorithm epsilon','epsilon','precision','min change'}
            self.valEps = val;
          case {'setpoint precision'}
            self.setErrEps = val;
          case {'valid range','physical range'}
            range = val.toArray();
            self.valMin = range(1);
            self.valMax = range(2);
          case {'setpoints','set-points','set points','error setpoints'}
            range = val.toArray();
            self.setErrLo = range(1);
            self.setErrHi = range(2);
          case {'frozen if unchanged for','frozen after'}
            self.valFrozen = val;
          case {'graphing group','graph group'}
            self.graphGroup = char(val);
          otherwise
            fprintf(2,'Unknown option - parameters:{ %s:{ %s: %s }}\n',...
              self.id,key,char(val.toString()));
        end
      end
    end
    
  end
  
end