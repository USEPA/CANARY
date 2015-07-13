classdef DeltasEntry < handle % ++++++++++++++++++++++++++++++++++++++++++++
  %CLUSTERLIB provides "known event" clustering capabilities to algorithms
  %
  % CANARY-EDS Continuous Analysis of Netowrked Array of Sensors for Event Detection
  % Copyright 2007-2012 Sandia Corporation.
  % This source code is distributed under the LGPL License.
  % Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
  % the U.S. Government retains certain rights in this software.
  
  % PROPERTIES
  
  % * PUBLIC PROPERTIES
  properties
    name = '';
    description = '';
    nPar = 0;
    nt0 = 5;
    nt1 = 5;
    dtA = 5;
    dtB = 10;
    params = {};
    mu0 = [];
    delta = [];
    Sigma = [];
    Winv = [];
    cMin = 1.0;
    cMax = 1.0;
    cVar = 0.1;
    nSamp = 0;
  end
  % METHODS
  
  % * PUBLIC METHODS
  methods
    function initialize( self, params )
      self.nPar = length(params);
      for i = 1:self.nPar
        self.params(i) = lower(params(i));
        self.delta(i) = 0;
        self.Sigma(i,i) = 0;
        self.mu0(i) = nan;
        self.nSamp = self.nPar + 1;
      end
    end
    
    function configure( self, HashMap )
      key = '';
      val = [];
      try
        keys = HashMap.keySet().toArray();
        for i = 1:length(keys)
          key = char(keys(i));
          val = HashMap.get(key);
          %fprintf(2,'%s: %s\n',key,char(val))
          switch key
            case 'name'
              self.name = val;
            case 'description'
              self.description = val;
            case 'parameters'
              pvs = val.toArray();
              for j = 1:length(pvs)
                self.params{j} = lower(char(pvs(j)));
              end
              if self.nPar == 0,
                self.nPar = length(pvs);
              end
              if self.nSamp == 0,
                self.nSamp = self.nPar + 1;
              end
            case 'm0 length'
              self.nt0 = val;
            case 'm1 length'
              self.nt1 = val;
            case 'separation min'
              self.dtA = val;
            case 'separation max'
              self.dtB = val;
            case 'starting values'
              if ~isempty(val)
                pvs = val.toArray();
                for j = 1:length(pvs)
                  self.mu0(j) = pvs(j);
                end
              end
            case 'delta values'
              pvs = val.toArray();
              for j = 1:length(pvs)
                self.delta(j) = pvs(j);
              end
            case 'delta mult min'
              self.cMin = val;
            case 'delta mult max'
              self.cMax = val;
            case 'delta mult var'
              self.cVar = val;
            case 'variances'
              pvs = val.toArray();
              if length(pvs) == length(self.params)
                for j = 1:length(pvs)
                  self.Sigma(j,j) = pvs(j);
                end
              else
                ct = 0;
                for j = 1:length(self.params)
                  for k = j:length(self.params)
                    ct = ct + 1;
                    self.Sigma(j,k) = pvs(ct);
                    self.Sigma(k,j) = pvs(ct);
                  end
                end
              end
              self.Winv = inv(self.Sigma);
            case 'num samples'
              self.nSamp = val;
            otherwise
              fprintf(2,'Error reading delta-pattern configuration\n  unknown key: %s\n', key);
          end
        end
      catch
        
      end

    end

    function configureFromFile(self, filename )
      try
        import('org.yaml.snakeyaml.Yaml')
        yamlreader = Yaml();
        ymltxt = fileread(filename);
        jYamlObj = yamlreader.load(ymltxt);
      catch ERRcfg
        base_ME = MException('tevaCanary:yamlConfig:fileFailure',...
          'Unable to load configuration file %s', filename);
        base_ME = addCause(base_ME, ERRcfg);
        throw(base_ME);
      end
      if jYamlObj.containsKey('pattern')
        self.configure(jYamlObj.get('pattern'));
      elseif jYamlObj.containsKey('delta pattern')
        self.configure(jYamlObj.get('delta pattern'));
      end
    end
    
  end
  
  % * PRIVATE METHODS
  methods ( Access = private )
    
  end
    
  % * STATIC METHODS
  methods ( Static = true )
    
  end
  
end
