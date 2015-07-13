classdef Algorithms < handle
  %ALGORITHMS definitions of different algorithms are contained in a single object
  %
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
  %   This object serves as a sort of library of algorithms defined in the XML
  %   configuration file. These can be accessed or added via the member functions
  %   of this class.
  %
  % Properties (used during add, provided during get):
  %   short_id          The short-id alias used by <location> definitions
  %   type              The type of algorithm (string, see documentation)
  %   mfile             M-file to access for this algorithm (only for custom)
  %   n_h               The window size (integer)
  %   tau_out           An array of outlier thresholds (reals, space separated)
  %   use_bed           Boolean value on whether to use BED
  %   n_bed             Number of timesteps in the BED window (prev. bed-window-min)
  %   p_out             Probability of an outlier (prev. bed-p-outlier)
  %   tau_evt           Threshold at which an alarm sounds (prev. bed-p-threshold)
  %   n_eto             Number of time steps after alarm starts that it is
  %                     automatically shut off (prev. bed-window-max)
  %   algs_in           Cell array containing names of algorithms to use as input
  %                     to this algorithm (for refiltering and conscensus algs)
  %
  % Examples: The following are examples of the different class methods
  %
  %   [ algStruct , colID ] = MyAlgs.getAlgorithm( algShortID );
  %
  %   pre_algs = data.algorithms.getPreReqAlgs( algShortID );
  %
  %   exists = data.algorithms.IsAlgorithm( 'LPCF-12' );
  %
  %   data.algorithms.addAlgorithm( 'short_id', 'LPCF-12', 'type', 'LPCF', ... );
  %
  % See also cws.Signals
  %
  properties
    short_id   = {}; % cell array of strings
    type  = {};      % cell array of strings
    mfile  = {};     % cell array of strings
    n_h      % integer array
    tau_out  = {}; % cell array of double arrays
    use_bed  % boolean array
    use_cluster %
    n_bed    % integer array
    p_out    % double  array
    tau_evt  % double  array
    n_eto    % integer array
    back_save = [];
    library = {};  % name of library file
    algs_in = {};  % cell array of cell arrays
    javaClass = {};
    list = { 'LPCF' , 'LPCF - Linear Predictor Coefficients Filter' , 1 ; ...
      'MVNN','MVNN - Multivariate Nearest Neighbor' , 1 ;...
      'SPPB','SPPB - Set-point Proximity Beta' , 0 ;...
      'SPPE','SPPE - Set-point Proximity Exponential' , 0 ;...
      'JAVA','JAVA - External Java Function' , 1 ;...
      'CAND','CAND - Combined Algorithms - AND-ed' , 1 ;...
      'CAVE','CAVE - Combined Algorithms - Averaged Pe' , 0 ;...
      'CMAX','CMAX - Combined Algorithms - Maximum Pe' , 0 ;...
      'EXTERNAL','EXTERNAL - Java Function (No BED or Clustering' , 1 ;};
  end
  
  methods

    function list = PrintAsXML( self )
      list = cell(length(self.short_id)+2,1);
      list(1) = {' <Algorithms>'};
      for aid = 1:length(self.short_id)
        list(aid+1) = {self.PrintAlgorithmAsXML(aid)};
      end
      list(end) = {' </Algorithms>'};
    end
    
    function list = getAlgorithmList( self )
      list = self.list;
    end
    
    function str = PrintAlgorithmAsXML( self , algid )
      str = sprintf('  <Algorithm name="%s" type="%s" history-window-TS="%d" outlier-threshold-SD="%s" event-threshold-P="%f" event-timeout-TS="%d" window-save-TS="%d" >\n',...
        self.short_id{algid},self.type{algid},self.n_h(algid),num2str(self.tau_out{algid}),self.tau_evt(algid),self.n_eto(algid),self.back_save(algid));
      if self.use_bed(algid),
        str = sprintf('%s   <BED bed-window-TS="%d" bed-P-outlier="%f" />\n',str,self.n_bed(algid),self.p_out(algid));
      end
      if self.use_cluster(algid) || ~isempty(self.library{algid}),
        if ischar(self.library{algid})
          str = sprintf('%s   <Clustering load-from-file="%s" />\n',str,self.library{algid});
        elseif isstruct(self.library{algid})
          libDat = self.library{algid};
          library = cws.ClusterLib;
          FN = fieldnames(libDat);
          for iii = 1:length(FN)
            library.(FN{iii}) = libDat.(FN{iii});
          end
          str = sprintf('%s   %s\n',str,library.PrintClusterAsXML);
        elseif isa(self.library{algid},'ClusterLib')
          lib = self.library{algid};
          str = sprintf('%s   %s\n',str,lib.PrintClusterAsXML);
        end
      end
      if ~isempty(self.algs_in{algid}),
        algsin = self.algs_in{algid};
        for i = 1:length(algsin),
          str = sprintf('%s   <UseAlgorithm name="%s" />\n',str,algsin{i});
        end
      end
      if ~isempty(self.javaClass{algid}),
        str = sprintf('%s   <ExternalAlgorithm class="%s" />\n',str,self.javaClass{algid}{1});
      end
      str = sprintf('%s  </Algorithm>',str);
    end
    
    function str = printAllYAML( self )
      str = sprintf('algorithms: \n');
      for aid = 1:length(self.short_id)
        str = sprintf('%s%s\n',str,self.printYAML(aid));
      end
    end
    
    function str = printYAML( self, algid)
      str = sprintf('- id: %s\n  type: %s\n  history window: %d\n  outlier threshold: %s\n  event threshold: %s\n  event timeout: %d\n  event window save: %d\n',...
        self.short_id{algid},self.type{algid},self.n_h(algid),yaml.num2str(self.tau_out{algid}),yaml.num2str(self.tau_evt(algid)),self.n_eto(algid),self.back_save(algid));
      if self.use_bed(algid),
        str = sprintf('%s  BED:\n    window: %d\n    outlier probability: %s\n',...
          str,self.n_bed(algid),yaml.num2str(self.p_out(algid)));
      end
      if self.use_cluster(algid) || ~isempty(self.library{algid}),
        if ischar(self.library{algid})
          str = sprintf('%s  cluster library file: %s\n',str,self.library{algid});
        end
      end
      if ~isempty(self.algs_in{algid}),
        algsin = cellstr(self.algs_in{algid});
        str = sprintf('%s  use algorithm inputs:\n',str);
        for i = 1:length(algsin)
          str = sprintf('%s    - id: %s\n',str,algsin{i});
        end
      end
      if ~isempty(self.javaClass{algid}),
        if ~isempty(self.javaClass{algid}{1})
          str = sprintf('%s  external algorithm class: %s\n',str,self.javaClass{algid}{1});
          if length(self.javaClass{algid})>1
            str = sprintf('%s  external algorithm configuration: |\n',str);
            try
              str = sprintf('%s    %s\n',str,self.javaClass{algid}{2});
            catch
              str = sprintf('%s    \n\n',str);
            end
          end
        end
      end
    end
    
    function [ algStruct , colID ] = getAlgorithm( self, short_id , n_sig)
      if nargin < 3,
        n_sig = 1;
      end
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug > 0,
         disp(short_id)
         disp(self.short_id)
         disp(strmatch(short_id,self.short_id,'exact'));
      end
      colID = strmatch(short_id,self.short_id,'exact');
      if isempty(colID)
        error('cws:Algorithms',...
          'No such algorithm alias: %s',short_id);
      end
      type = char(self.type{colID});
      mfile = char(self.type{colID});
      n_h = self.n_h(colID);
      tau_out = self.tau_out{colID};
      use_bed = self.use_bed(colID);
      n_bed = self.n_bed(colID);
      p_out = self.p_out(colID);
      tau_evt = self.tau_evt(colID);
      back_save = self.back_save(colID);
      n_eto = self.n_eto(colID);
      n_tau = length(tau_out);
      use_cluster = self.use_cluster(colID);
      if isempty(self.library{colID}),
        library = [];
        use_cluster = false;
      elseif ischar(self.library{colID}),
        try
            % FIXME: load .yml pattern matching file!!!!
          libDat = load(self.library{colID},'-MAT');
          library = libDat.MyCluster;
          use_cluster = true;
        catch ERR
          if strcmp(ERR.identifier,'MATLAB:load:couldNotReadFile'),
            cws.trace(['CONFIG:algorithm:',short_id],['Bad or missing cluster-file: ',self.library{colID}]);
            use_cluster = false;
            library = [];
            cws.trace(['CONFIG:algorithm:',short_id],'Continuing without pattern matching');
          else
            cws.trace(['CONFIG:algorithm:',short_id],['Error using cluster-file: ',self.library{colID}]);
            cws.errTrace(ERR)
            rethrow(ERR);
          end
        end
      elseif isstruct(self.library{colID})
        libDat = self.library{colID};
        library = cws.ClusterLib;
        use_cluster = false;
        FN = fieldnames(libDat);
        for iii = 1:length(FN)
          library.(FN{iii}) = libDat.(FN{iii});
        end
      elseif isa(self.library{colID},'ClusterLib')
        library = self.library{colID};
        use_cluster = true;
      else
        library = [];
        use_cluster = false;
      end
      window = zeros(n_h,n_sig,n_tau);
      residuals = zeros(n_h,n_sig,n_tau);
      eventprob = zeros(n_h,n_sig,n_tau);
      eventcode = zeros(n_h,n_sig,n_tau);
      event_ct = zeros(1,1,n_tau);
      setPtViol = zeros(1,1,1);
      event_contrib = zeros(1,n_sig,n_tau);
      cluster_probs = zeros(1,3,n_tau);
      cluster_ids = zeros(1,3,n_tau);
      bedwin = zeros(n_bed,1,n_tau);
      comments = cell(1,1,1);
      algJ = {[]};
      if ~isempty(self.javaClass),
        if ~isempty(self.javaClass{colID}),
        if ~isempty(self.javaClass{colID}{1}),
          for i = 1:n_tau,
            algJ{i} = javaObject(self.javaClass{colID}{1});
            algJ{i}.configure(self.javaClass{colID}{2}(1));
            algJ{i}.initialize(n_sig);
          end
        end
        end
      end
      %        if isempty(algJ), algJ = []; end;
      algStruct = struct('type',type,...
        'mFile',mfile,'n_h',n_h,'tau_out',tau_out,...
        'use_bed',use_bed,'n_bed',n_bed,'p_out',p_out,'tau_evt',tau_evt,...
        'n_eto',n_eto,'window',window,'residuals',residuals,...
        'eventprob',eventprob,'eventcode',eventcode,'bedwin',bedwin,...
        'event_ct',event_ct,'event_contrib',event_contrib,...
        'setPtViol',setPtViol,'back_save',back_save,...
        'comments',comments,'report',false,'use_cluster',use_cluster,...
        'library',library,'cluster_probs',cluster_probs,...
        'cluster_ids',cluster_ids,'algs_in',[],'algJ',[algJ{:}]);
    end
    
    function pre_algs = getPreReqAlgs( self , short_id )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      pre_algs = {};
      MyID = strmatch(short_id,self.short_id,'exact');
      if isempty(MyID), return; end
      pre_algs = self.algs_in{MyID};
    end
    
    function exists = IsAlgorithm( self , short_id )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      exists = ~isempty(strmatch(short_id,self.short_id,'exact'));
    end
    
    function MyID = configureAlgorithm(self, HashMap)
      try 
        if HashMap.containsKey('id')
          id = HashMap.get('id');
        else
          error('tevaCanary:yamlConfig:missingField',...
            'Error - the following entry was missing the "id" field.\n  %s',...
            HashMap.toString());
        end
        MyID = self.addAlgorithm(id);
        if MyID < 1,
          error('tevaCanary:yamlConfig:missingField',...
            'Error - the following entry has an invalid "id" field: %s\n  %s',...
            id,HashMap.toString());
        end
        keys = HashMap.keySet().toArray();
        for i = 1:length(keys)
          key = char(keys(i));
          val = HashMap.get(key);
          switch key
            case 'id'
              self.short_id{MyID} = char(val);
            case 'type'
              self.type{MyID} = char(val);
              self.mfile{MyID} = char(val);
            case {'historyWindow','history window'}
              self.n_h(MyID) = val;
            case {'outlierThreshold','outlier threshold'}
              if isa(val,'double')
                self.tau_out{MyID} = val;
              else
                self.tau_out{MyID} = str2num(char(val.toString())); %#ok<ST2NM>
              end
            case {'eventThreshold','event threshold'}
              self.tau_evt(MyID) = val;
            case {'eventTimeout','event timeout'}
              self.n_eto(MyID) = val;
            case {'eventWindowSave','event window save'}
              self.back_save(MyID) = val;
              if self.n_bed(MyID) == 0,
                  self.n_bed(MyID) = val;
              end
            case 'BED'
              self.use_bed(MyID) = true;
              sKeyList = cell(val.keySet().toArray());
              for iSub = 1:length(sKeyList)
                sKey = sKeyList{iSub};
                switch sKey
                  case {'window','BED window','bed window'}
                    self.n_bed(MyID) = val.get(sKey);
                  case {'outlierProb','outlier probability','shape parameter'}
                    self.p_out(MyID) = val.get(sKey);
                  otherwise
                    warning('tevaCanary:yamlConfig:invalidField',...
                      'Unknown key for signal[%s] => %s => %s',...
                      id,key,sKey);
                end
              end
            case {'externalAlgorithmClass','external algorithm class'}
              self.javaClass{MyID} = {val};
            case {'externalAlgorithmConfig','external algorithm configuration'}
              self.javaClass{MyID}(end+1) = {{val}};
            case {'clusterLibraryFile','cluster library file'}
              self.library{MyID} = char(val);
            case {'useAlgorithmInputs','use algorithm inputs'}
              uval = val.toArray();
              algs_in = cell(length(uval),1);
              for j = 1:length(uval)
                algs_in{j} = char(uval(j).get('id'));
              end
              self.algs_in{MyID} = algs_in;
            otherwise
              warning('tevaCanary:yamlConfig:invalidField',...
                'Unknown key/value for algorithm[%s] => %s: %s',...
                id,char(key),char(val.toString()));
          end
        end
      catch ERR
        cws.errTrace(ERR);
        rethrow(ERR)
      end
    end
    
    function MyID = addAlgorithm(self,id)
      if ~isempty(strmatch(id,self.short_id,'exact'))
        MyID = strmatch(id,self.short_id,'exact');
      else
        MyID = length(self.short_id) + 1;
        self.short_id{MyID} = '';
        self.type{MyID} = '';
        self.mfile{MyID} = '';
        self.n_h(MyID) = 0;
        self.tau_out{MyID} = [0 0];
        self.use_bed(MyID) = false;
        self.use_cluster(MyID) = false;
        self.javaClass{MyID} = {};
        self.n_bed(MyID) = 20;
        self.back_save(MyID) = 30;
        self.p_out(MyID) = 0.5;
        self.tau_evt(MyID) = 1;
        self.n_eto(MyID) = 60;
        self.library{MyID} = [];
        self.algs_in{MyID} = [];
      end
    end
    
    function self = addAlgorithmDef( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      try
        MyID = length(self.short_id) + 1;
        self.short_id{MyID} = '';
        self.type{MyID} = '';
        self.mfile{MyID} = '';
        self.n_h(MyID) = 0;
        self.tau_out{MyID} = [0 0];
        self.use_bed(MyID) = false;
        self.use_cluster(MyID) = false;
        self.javaClass{MyID} = {};
        self.n_bed(MyID) = 20;
        self.back_save(MyID) = 30;
        self.p_out(MyID) = 0.5;
        self.tau_evt(MyID) = 1;
        self.n_eto(MyID) = 60;
        self.library{MyID} = [];
        self.algs_in{MyID} = [];
        args = varargin;
        while ~isempty(args) && length(args) >= 2
          fld = char(args{1});
          val = args{2};
          switch lower(fld)
            case {'short_id'}
              if ~isempty(strmatch(val,self.short_id,'exact'))
                error('CANARY:algorithmalreadydefined',...
                  'Algorithm "%s" already definied.',char(val));
              end
              self.short_id{MyID} = char(val);
            case {'type'}
              self.type{MyID} = char(val);
            case {'mfile'}
              self.mfile{MyID} = char(val);
            case {'tau_out'}
              self.tau_out{MyID} = val;
            case {'library'}
              if isstruct(val)
                self.library{MyID} = val;
              else
                self.library{MyID} = char(val);
              end
            case {'algs_in'}
              self.algs_in{MyID} = char(val);
            case {'javaclass'}
              self.javaClass{MyID} = val;
            otherwise
              try
                self.(char(fld))(MyID) = val;
              catch ERR
                error('cws:Algorithms','%s',ERR.message);
              end
          end
          args = {args{3:end}};
        end
      catch ERRSD
        nAlgs = length(self.short_id) - 1;
        flds = fieldnames(self);
        for i = 1:length(flds)
          fld = flds(i);
          switch char(fld)
            case {'short_id','type','mfile','tau_out'}
              if size(self.(char(fld)),2) > nAlgs,
                self.(char(fld)) = {self.(char(fld)){1:nAlgs}};
              end
            otherwise
              if size(self.(char(fld)),2) > nAlgs,
                self.(char(fld)) = self.(char(fld))(1:nAlgs);
              end
          end
        end
        rethrow(ERRSD);
      end
    end
    
    function self = ModAlgorithmDef( self , short_id , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      try
        MyID = strmatch(short_id,self.short_id,'exact');
        if isempty(MyID),
          MyID = length(self.short_id) + 1;
          self.short_id{MyID} = short_id;
          self.type{MyID} = '';
          self.mfile{MyID} = '';
          self.n_h(MyID) = 0;
          self.back_save(MyID) = 20;
          self.tau_out{MyID} = [0 0];
          self.use_bed(MyID) = false;
          self.use_cluster(MyID) = false;
          self.n_bed(MyID) = 20;
          self.p_out(MyID) = 0.5;
          self.tau_evt(MyID) = 1;
          self.n_eto(MyID) = 60;
        end
        args = varargin;
        while ~isempty(args) && length(args) >= 2
          fld = char(args{1});
          val = args{2};
          switch lower(fld)
            case {'short_id'}
              warning('cws:Algorithms','Please don''t re-define the short-id, add a new algorithm instead');
            case {'type'}
              self.type{MyID} = char(val);
            case {'mfile'}
              self.mfile{MyID} = char(val);
            case {'tau_out'}
              self.tau_out{MyID} = val;
            case {'library'}
              if isstruct(val)
                self.library{MyID} = val;
              else
                self.library{MyID} = char(val);
              end
            case {'algs_in'}
              self.algs_in{MyID} = val;
            case {'javaclass'}
              self.javaClass{MyID} = char(val);
            otherwise
              try
                self.(char(fld))(MyID) = val;
              catch ERR
                error('cws:Algorithms','%s',ERR.message);
              end
          end
          args = {args{3:end}};
        end
      catch ERRSD
        nAlgs = length(self.short_id) - 1;
        flds = fieldnames(self);
        for i = 1:length(flds)
          fld = flds(i);
          switch char(fld)
            case {'short_id','type','mfile','tau_out'}
              if size(self.(char(fld)),2) > nAlgs,
                self.(char(fld)) = {self.(char(fld)){1:nAlgs}};
              end
            otherwise
              if size(self.(char(fld)),2) > nAlgs,
                self.(char(fld)) = self.(char(fld))(1:nAlgs);
              end
          end
        end
        rethrow(ERRSD);
      end
    end
    
  end
  
end
