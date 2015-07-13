classdef DeltasLibrary < handle & cws.PatternLib% ++++++++++++++++++++++++++++++++++++++++++++
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
    patterns = {}
    names
    m0_len = 5;
    m1_len = 5;
    sep_min = 5;
    sep_max = 10;
    alpha_reject = 0.01;
    n_sigs = 0;
  end
  
  % METHODS
  
  % * PUBLIC METHODS
  methods
    
    function self = DeltasLibrary( varargin )
      self.names = java.util.LinkedHashMap();
    end
    
    function [ isCluster , probs ] = matchWindow( self , CDS , LOC , idx , algIdx)
      params = lower(LOC.sigids);
      probs = zeros(2,3);
      isCluster = false;
      for i = 1:length(self.patterns)
        thisPat = self.patterns{i};
        if isempty(thisPat.Winv)
          thisPat.Winv = inv(thisPat.Sigma);
        end
        dEnd = thisPat.nt1;
        dMid = thisPat.nt1 + thisPat.dtA;
        dSta = thisPat.nt1 + thisPat.dtA + thisPat.nt0;
        nPar = length(thisPat.params);
        vals = zeros(dSta,nPar);
        for j = 1:nPar
          parIdxInLoc = 0;
          thisPar = thisPat.params{j};
          parIdxs = regexp(thisPar,params,'once');
          for k = 1:length(params),
            if ~isempty(parIdxs{k}),
              parIdxInLoc = k;
            end
          end
          if parIdxInLoc > 0
            parIdxInCDS = LOC.sigs(parIdxInLoc);
            vals(:,j) = CDS.values(idx-dSta+1:idx,parIdxInCDS);
          else
            vals(:,j) = nan;
          end
        end
        mu0 = nanmedian(vals(1:thisPat.nt0,:));
        mu1 = nanmedian(vals(end-thisPat.nt1+1:end,:));
        delta0 = mu1 - mu0;
        x0 = thisPat.delta - delta0;
        %rawPVal = mvnpdf(delta0,thisPat.delta,thisPat.Sigma);
        t2 = x0 * thisPat.Winv * x0';
        F = t2 * (thisPat.nSamp + 1 - nPar - 1)/((thisPat.nSamp+1-2)*nPar);
        p = fcdf(F,nPar,thisPat.nSamp+1-1-nPar);
        if p > 0.5, p = 1 - p; end;
        if p > 0.0001
          format short;
          disp([i,t2,F,p])
        end
        if p > self.alpha_reject
          isCluster = true;
          if p > probs(1,1)
            probs(:,2:3) = probs(:,1:2);
            probs(2,1) = i;
            probs(1,1) = p;
          elseif p > probs(1,2)
            probs(:,3) = probs(:,2);
            probs(2,2) = i;
            probs(1,2) = p;            
          elseif p > probs(1,3)
            probs(2,3) = i;
            probs(1,3) = p;            
          end
        end
      end
    end
    
    function createPattern( self, name, pat )
      if self.names.containsKey(name),
        % raise exception
      else
        if nargin > 2,
          self.patterns{end+1} = pat;
        else
          self.patterns{end+1} = cws.DeltasEntry;
        end
        self.names.put(name,length(self.patterns));
      end
    end
    
    function configureFromFile( self, filename )
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
      self.configure(jYamlObj);
    end
    
    function configure( self, HashMap )
      if HashMap.containsKey('deltas library')
        libConf = HashMap.get('deltas library');
        if libConf.containsKey('alpha reject')
          self.alpha_reject = libConf.get('alpha reject');
        end
      end
      if HashMap.containsKey('pattern list')
        patlist = HashMap.get('pattern list').toArray();
        for i = 1:length(patlist),
          pat = cws.DeltasEntry;
          pat.configure(patlist(i));
          self.createPattern(pat.name,pat);
        end
      elseif HashMap.containsKey('delta pattern')
        pat = cws.DeltasEntry;
        pat.configure(HashMap.get('delta pattern'));
        self.createPattern(pat.name,pat);
      elseif HashMap.containsKey('pattern')
        pat = cws.DeltasEntry;
        pat.configure(HashMap.get('pattern'));
        self.createPattern(pat.name,pat);
      end
    end
    
    function addEvent( self , patName , eventObj )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function addEventFromFile( self , patname , filename )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
   
  end
  
  % * PRIVATE METHODS
  methods ( Access = private )
    
  end
    
  % * STATIC METHODS
  methods ( Static = true )
    
  end
  
end
