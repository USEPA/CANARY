classdef Parameter %< handle
  properties
    id = ''; % the parameter ID (short! 10 chars max!)
    type_str = '';
    type_no = 0;
    
    % Descriptive properties
    description = ''; % a long description of the parameter
    units = ''; % units used on output
    
    % Physical limitations / event detection algorithm modifiers (eps)
    epsilon = 0.01; % minimum change that is "real"
    val_min = -inf; % physical constraints / valid range of values
    val_max = inf;
    
    % Set-Point anomaly detection
    set_err_min = -inf; % set-point error-level values
    set_err_max = inf;
    set_eps = 0.01;
    
    % Pattern Matching 
    pat_delta = 0.1; % The discretization step size for pattern matching
    pat_sigma = 0.1; % standard deviation of values around a "true" measure
    pat_zero = inf; % the zero-point to use when creating pattern; -inf or inf is relative
    
    % Rate-Of-Change anomaly detection
    frozen_lim = inf; % numbe of steps of 0.00 change for warning of frozen param to be raised
    
    % Graphics
    gfx_group = '';
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
        yaml.num2str(self.epsilon));
      str = sprintf('%s  setpoint precision: %s\n',str, ...
        yaml.num2str(self.set_eps));
      str = sprintf('%s  valid range: [%s, %s]\n',str, ...
        yaml.num2str(self.val_min), yaml.num2str(self.val_max));
      str = sprintf('%s  error setpoints: [%s, %s]\n',str, ...
        yaml.num2str(self.set_err_min), yaml.num2str(self.set_err_max));
      str = sprintf('%s  frozen after: %s\n',str, ...
        yaml.num2str(self.frozen_lim));
      str = sprintf('%s  graphing group: %s\n',str, self.gfx_group);
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
            self.description = char(val);
          case 'units'
            self.units = char(val);
          case {'algorithm epsilon','epsilon','precision','min change'}
            self.epsilon = val;
          case {'setpoint precision'}
            self.set_eps = val;
          case {'valid range','physical range'}
            range = val.toArray();
            self.val_min = range(1);
            self.val_max = range(2);
          case {'setpoints','set-points','set points','error setpoints'}
            range = val.toArray();
            self.set_err_min = range(1);
            self.set_err_max = range(2);
          case {'frozen if unchanged for','frozen after'}
            self.frozen_lim = val;
          case {'graphing group','graph group'}
            self.gfx_group = char(val);
          otherwise
            fprintf(2,'Unknown option - parameters:{ %s:{ %s: %s }}\n',...
              self.id,key,char(val.toString()));
        end
      end
    end
    
  end
  
end