classdef JDBCDataSource < handle & cws.DataSource % ++++++++++++++++++++++++++++++++++++++++++++++++
  % DATASOURCE class definition
  %
  % CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
  % Copyright 2007-2012 Sandia Corporation.
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
  methods % PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    function self = JDBCDataSource( varargin ) % ------------------- CONSTRUCTOR --
      %DATASOURCE/DATASOURCE constructs a new DATASOURCE Object using the
      %property value paris provided as parameters to the constructor
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'DataSource') || isa(obj,'Connection') || isa(obj,'struct')
          FN = fieldnames(self);
          for iFN = 1:length(FN)
            self.(char(FN(iFN))) = obj.(char(FN(iFN)));
          end
          self.IsConnected = false;
        elseif isa(obj,'char')
          self.conn_id = obj;
        elseif isa(obj,'java.util.LinkedHashMap')
          self.constructFromYAML(obj);
        else
          error('CANARY:datasource:gdb:unknownConn','Unknown construction method: %s',class(self));
        end
      elseif nargin > 1
        args = varargin;
        while ~isempty(args)
          fld = char(args{1});
          val = args{2};
          try
            self.(fld) = val;
          catch ERR
            if DeBug, cws.errTrace(ERR); end
            warning off backtrace
            warning('CANARY:datasource:gdb:unkownOption','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
      % END OF CONSTRUCTOR ----------------------------------------------------
    end
    
    function self = connect(self)
      %CONNECT connect to the web, a database or a file
      %   This function connects an Object to the appropriate network asset, database,
      %   or file to be used by a CanaryInput, CanaryOutput or Messenger Object. This
      %   depends on the value of the CONN_TYPE property of the base Object. The
      %   acceptable values for CONN_TYPE are:
      %
      %       XML     - used to indicate a Connection via a website Connection
      %
      %       JDBC    - used to indicate a database that uses JDBC drivers
      %
      %       FILE    - This is a file Connection or internal stack (Messenger)
      %
      %  See also disconnect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      %
      %  Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      %       if self.IsConnected
      %         warning('CANARY:reconnect','Connection being terminated prior to reConnection');
      %         self.disconnect();
      %       end
      cws.logger('create jdbc connection');
      try
        if self.IsConnected,
          return;
        end
        if ~self.IsRegistered
          self.RegisterDriver();
        end
        if ~isempty(self.driver_datasource_class)
          ds = eval(self.driver_datasource_class);
          ds.setURL(self.conn_url);
          if DeBug,
            fprintf(1,'DEBUG: ds.getURL() => %s\n',char(ds.getURL()));
          end
          if self.conn_interactive && isempty(self.conn_password),
            prompt = {'Username:','Password:'};
            name = ['Login to ',self.conn_id];
            numlines=1;
            defaultanswer={'',''};
            answer = inputdlg(prompt,name,numlines,defaultanswer);
            self.conn_username = answer{1};
            self.conn_password = answer{2};
            user = java.lang.String(self.conn_username);
            pass = java.lang.String(self.conn_password);
            self.ConnID = ds.getConnection(user,pass);
            self.IsConnected = true;
            self.conn_interactive = false;
          else
            user = java.lang.String(self.conn_username);
            pass = java.lang.String(self.conn_password);
            self.ConnID = ds.getConnection(user,pass);
            self.IsConnected = true;
          end
        else
          self.ConnID = java.sql.DriverManager.getConnection(self.conn_url,...
            self.conn_username,self.conn_password);
          self.IsConnected = true;
        end
        cws.logger(sprintf('debug conn id %s',class(self.ConnID)));
        if DeBug,
          fprintf(2,'DEBUG: self.ConnID = %s\n',class(self.ConnID));
          self.ConnID
        end
      catch ERR
        cws.logger('jdbc  error in connection creation');
        if DeBug, cws.errTrace(ERR); end
        prompt = {'Database URL','Username:','Password:'};
        name = ['Login to ',self.conn_id];
        numlines=1;
        defaultanswer={self.conn_url,self.conn_username,self.conn_password};
        if self.conn_interactive && isempty(self.conn_password),
          answer = inputdlg(prompt,name,numlines,defaultanswer);
          self.conn_url = answer{1};
          ds.setURL(self.conn_url);
          self.conn_username = answer{2};
          self.conn_password = answer{3};
        else
          cws.trace('Trying to log in',[self.conn_url,' ',self.conn_username,' ','********']);
        end
        ds.setURL(self.conn_url);
        user = java.lang.String(self.conn_username);
        pass = java.lang.String(self.conn_password);
        try
          self.ConnID = ds.getConnection(user,pass);
          self.IsConnected = true;
          self.conn_interactive = false;
        catch ERR
          baseME = MException('CANARY:datasource:gdb:connectFailed','Connection failed for JDBC driver');
          newME = addCause(baseME,ERR);
          cws.errTrace(newME);
          throw(newME);
        end
      end
      
      % END OF CONNECT --------------------------------------------------------
    end
    
    function self = disconnect( self )
      %DISCONNECT Closes the Connection made previously
      %   disconnects a connected Object and displays any warning messages than may
      %   appear (such as disconnecting an already disconnected Object). This method
      %   may be overloaded in subclasses due to specific needs.
      %
      % See also connect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.IsConnected = false;
      try
        cws.logger('jdbc  disconnect');
        if ~isempty(self.ConnID)
          try
            self.ConnID.close();
          catch ERR
            cws.errTrace(ERR);
            self.ConnID = [];
          end
        end
        self.IsConnected = false;
      catch ERR
        if DeBug, cws.errTrace(ERR); end
        self.IsConnected = false;
        warning('CANARY:conndisconnect',ERR.message);
      end
      self.Isinitialized = false;
      self.addMessageCS = [];
      self.getMessageCS = [];
      % END OF DISCONNECT -----------------------------------------------------
    end
    
    function self = update( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('start datasource update');
      if ~self.isused, return ; end
      %       if sum(self.isActive) < 1 , return ; end
      %       usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj','Updating data','cont',datestr(now));
      %       disp(usrmsg);
      if self.IsInput,
        if DeBug,
          st1 = datestr(now(),30);
          fprintf(2,'- update from source: %s\n',self.conn_url);
        end
        switch lower(self.input_format)
          case {'eddies'}
            self.connect();
            self.read_eddies(varargin{:});
            self.disconnect();
          case {'rowbased','row_based','row-based','row based','custom'}
            self.connect();
            self.read_rowbased(varargin{:});
            self.disconnect();
          otherwise
            self.connect();
            self.read_table(varargin{:});
            self.disconnect();
        end
        
        if DeBug,
          st2 = datestr(now(),30);
          fprintf(2,'  update duration:   %s --> %s\n',st1,st2);
        end
      end
      cws.logger('exit  datasource update');
      % END OF UPDATE ---------------------------------------------------------
    end
    
    function self = postResult( self , idx , LOC , timestep , CDS )
      cws.logger('enter postResult');
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if self.IsOutput,
        self.connect();
        self.populate_db(idx,LOC,timestep);
        self.disconnect();
      end
      cws.logger('exit  postResult');
      % END OF POSTRESULT -----------------------------------------------------
    end
    
    function self = initializeInput( self , varargin )
      %INITIALIZE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Input'); end;
      if ~self.isused,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.input_type),
        self.input_type = self.conn_type;
      end
      self.initialize_db();
      self.IsInpInit = true;
      % END OF INITIALIZEINPUT ------------------------------------------------
    end
    
    function self = initializeOutput( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Output'); end;
      if ~self.isused,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.output_type)
        self.output_type = self.conn_type;
      end
      if self.IsOutInit,
        return;
      end
      self.initialize_db();
      switch lower(self.output_format)
        case {'extended'}
          self.sqlCreate = [ 'create table ', self.output_table , '('];
          self.sqlA = ['insert into ', self.output_table ,' ('];
          
          % INSTANCE ID
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_instanceID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA , self.db_wt_fn_instanceID ];
          
          % TIME_STEP
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_timestep, ' ',self.sqlDateDatatype,' not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_timestep ];
          
          % LOCATION_ID
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_stationID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_stationID ];
          
          % DETECTION_ALGORITHM
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_algorithmID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_algorithmID ];
          
          % DETECTION_INDICATOR double precision not null
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventCode, ' double precision not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventCode ];
          
          % DETECTION_PROBABILITY double precision
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventProb, ' double precision, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventProb ];
          
          % CONTRIBUTING_PARAMETERS character varying(100)
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventContrib, ' character varying(100), ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventContrib ];
          
          % ANALYSIS_COMMENTS character varying(100)
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_comments, ' character varying(100), ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_comments ];
          
          % MATCH_PATTERN_ID character varying(100)
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternID, ' character varying(100), ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_patternID ];

          % MATCH_PROBABILITY double precision
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternProb, ' double precision, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_patternProb ];
          
          self.sqlA = [ self.sqlA, ') values (''', self.canaryID, ''','];
          self.sqlCreate = [ self.sqlCreate, ' CONSTRAINT PK_', ...
                             self.output_table ,'  PRIMARY KEY (', ...
                             self.db_wt_fn_instanceID, ', ', ...
                             self.db_wt_fn_stationID, ', ', ...
                             self.db_wt_fn_timestep, '))'];
        case {'custom'}
          self.sqlCreate = [ 'create table ', self.output_table , '('];
          self.sqlA = ['insert into ', self.output_table ,' ('];
          
          % INSTANCE ID
          if self.db_wt_fn_instanceID,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_instanceID, ' character varying(50) not null, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_instanceID, ', ' ];
          end
          % TIME_STEP
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_timestep, ' ',self.sqlDateDatatype,' not null, ' ];
          self.sqlA = [ self.sqlA , self.db_wt_fn_timestep, ', ' ];
          % LOCATION_ID
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_stationID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA , self.db_wt_fn_stationID, ', ' ];
          
          % DETECTION_ALGORITHM
          if self.db_wt_fn_algorithmID,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_algorithmID, ' character varying(50) not null, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_algorithmID, ', ' ];
          end
          % PARAMETER_TYPE
          if self.db_wt_fn_parameterID,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_parameterID, ' character varying(10) not null, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_parameterID, ', ' ];
          end
          % PARAMETER_RESID
          if self.db_wt_fn_parameterResid,
            self.sqlCreate = [ self.sqlCreate , ...
                               self.db_wt_fn_parameterResid, ' double precision, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_parameterResid, ', ' ];
          end
          % PARAMETER_TAG
          if self.db_wt_fn_parameterTag,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_parameterTag, ' character varying(50), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_parameterTag, ', ' ];
          end
          % DETECTION_INDICATOR double precision not null
          if self.db_wt_fn_eventCode,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventCode, ' double precision not null, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_eventCode, ', ' ];
          end
          % DETECTION_PROBABILITY double precision
          if self.db_wt_fn_eventProb,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventProb, ' double precision, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_eventProb, ', ' ];
          end
          % CONTRIBUTING_PARAMETERS character varying(100)
          if self.db_wt_fn_eventContrib,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventContrib, ' character varying(100), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_eventContrib, ', ' ];
          end
          % ANALYSIS_COMMENTS character varying(100)
          if self.db_wt_fn_comments,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_comments, ' character varying(100), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_comments, ', ' ];
          end
          % MATCH_PATTERN_ID character varying(100)
          if self.db_wt_fn_patternID,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternID, ' character varying(100), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternID, ', ' ];
          end
          % MATCH_PROBABILITY double precision
          if self.db_wt_fn_patternProb,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternProb, ' double precision, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternProb, ', ' ];
          end
          % MATCH_PATTERN_ID2 character varying(100)
          if self.db_wt_fn_patternID2,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternID2, ' character varying(100), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternID2, ', ' ];
          end
          % MATCH_PROBABILITY2 double precision
          if self.db_wt_fn_patternProb2,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternProb2, ' double precision, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternProb2, ', ' ];
          end
          % MATCH_PATTERN_ID3 character varying(100)
          if self.db_wt_fn_patternID3,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternID3, ' character varying(100), ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternID3, ', ' ];
          end
          % MATCH_PROBABILITY3 double precision
          if self.db_wt_fn_patternProb3,
            self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_patternProb3, ' double precision, ' ];
            self.sqlA = [ self.sqlA , self.db_wt_fn_patternProb3, ', ' ];
          end
          % Fix final comma
          lensqlA = length(self.sqlA);
          self.sqlA = self.sqlA(1:lensqlA-2);
          
          self.sqlA = [ self.sqlA, ') values (' ];
          if self.db_wt_fn_instanceID,
              self.sqlA = [ self.sqlA, ' ''', self.canaryID, ''',' ];
          end
          self.sqlCreate = [ self.sqlCreate, ' CONSTRAINT PK_', ...
                             self.output_table ,'  PRIMARY KEY (', ]
          if self.db_wt_fn_instanceID,
              self.sqlCreate = [ self.sqlCreate,  self.db_wt_fn_instanceID, ', ' ]
          end
          self.sqlCreate = [ self.sqlCreate,  self.db_wt_fn_stationID, ', ' ]
          self.sqlCreate = [ self.sqlCreate, self.db_wt_fn_timestep, '))'];
          
        otherwise
          self.sqlCreate = [ 'create table ', self.output_table , '('];
          self.sqlA = ['insert into ', self.output_table ,' ('];
          % INSTANCE ID
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_instanceID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA , self.db_wt_fn_instanceID ];

          % TIME_STEP
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_timestep, ' ',self.sqlDateDatatype,' not null, ' ];
          self.sqlA = [ self.sqlA , ', ', self.db_wt_fn_timestep];
          
          % LOCATION_ID
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_stationID, ' character varying(50) not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_stationID ];
          
          % DETECTION_INDICATOR double precision not null
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventCode, ' double precision not null, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventCode];
          
          % DETECTION_PROBABILITY double precision
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventProb, ' double precision, ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventProb ];
          
          % CONTRIBUTING_PARAMETERS character varying(100)
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_eventContrib, ' character varying(100), ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_eventContrib ];
          
          % ANALYSIS_COMMENTS character varying(100)
          self.sqlCreate = [ self.sqlCreate , self.db_wt_fn_comments, ' character varying(100), ' ];
          self.sqlA = [ self.sqlA, ', ' , self.db_wt_fn_comments ];
          
          self.sqlA = [ self.sqlA, ') values (''', self.canaryID, ''','];
          self.sqlCreate = [ self.sqlCreate, ' CONSTRAINT PK_', ...
                             self.output_table ,'  PRIMARY KEY (', ...
                             self.db_wt_fn_stationID, ', ', ...
                             self.db_wt_fn_timestep, '))'];
      end
      if DeBug
          try
        fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
        fprintf(fid,'%s\n',self.sqlCreate);
        fclose(fid);
          catch
        fprintf(2,'%s\n',self.sqlCreate);
          end
      end
      try
        ci = self.ConnID.prepareCall(self.sqlCreate);
        ci.execute();
        ci.close();
      catch ERR
        if DeBug, cws.errTrace(ERR); end
        warning('CANARY:datasource:gdb:createOutputTableFailed','Table already exists: %s',self.output_table);
      end
      self.IsOutInit = true;
      % END OF INITIALIZEOUTPUT -----------------------------------------------
    end
    
    % END OF PUBLIC METHODS ===============================================
  end
  
  methods ( Access = 'private' ) % +++++++++++++++++++++++++++++++++++++++
    
    function self = populate_db ( self , idx , LOC , ts )
      if ~self.IsOutput,
        return;
      end;
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter populate_db');
      code = LOC.algs(end).eventcode(idx,end,end);
      if isempty(LOC.output_tag)
        loc_id = char(LOC);
      else
        loc_id = LOC.output_tag;
      end
      anl_comm = LOC.algs(end).comments{idx};
      alg_id = LOC.algs(end).type;
      if DeBug > 0,
        disp(['alg_id  ',alg_id]);
      end
      detec_indi = num2str(code);
      detec_prob = num2str(LOC.algs(end).eventprob(idx,end,end));
      paramTypes = {LOC.sigids{abs(LOC.algs(end).event_contrib(idx,:,end))==1}};
      cont_param = '';
      if LOC.algs(end).cluster_ids(idx,1,end) > 0
        pat_id = sprintf('%d',LOC.algs(end).cluster_ids(idx,1,end));
        pat_prob = sprintf('%f',LOC.algs(end).cluster_probs(idx,1,end));
      else
        pat_id = '';
        pat_prob = '0';
      end
      for p = 1:length(paramTypes),
        cont_param = [cont_param , paramTypes{p} , ' '];
      end
      cont_param = cont_param(1:min(end,100));
      switch lower(self.output_format)
        case {'extended'}
          sqlTotal = java.lang.String(self.sqlA);
          sqlTotal = sqlTotal.concat(self.sqlDateConvertA);
          sqlTotal = sqlTotal.concat(ts);
          sqlTotal = sqlTotal.concat(self.sqlDateConvertB);
          sqlTotal = sqlTotal.concat(self.conn_toDateFmt);
          sqlTotal = sqlTotal.concat(self.sqlDateConvertC);
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(loc_id);
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(alg_id);
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(detec_indi);
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(detec_prob);
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(anl_comm);
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(cont_param);
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(pat_id);
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(pat_prob);
          sqlTotal = sqlTotal.concat(')');
        case {'custom'}
          sqlTotal = java.lang.String(self.sqlA);
          
          sqlTotal = sqlTotal.concat(self.sqlDateConvertA);
          sqlTotal = sqlTotal.concat(ts);
          sqlTotal = sqlTotal.concat(self.sqlDateConvertB);
          sqlTotal = sqlTotal.concat(self.conn_toDateFmt);
          sqlTotal = sqlTotal.concat(self.sqlDateConvertC);

          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(loc_id);
          sqlTotal = sqlTotal.concat('''');
          
          % DETECTION_ALGORITHM
          if self.db_wt_fn_algorithmID,
              sqlTotal = sqlTotal.concat(',');
              sqlTotal = sqlTotal.concat('''');
              sqlTotal = sqlTotal.concat(alg_id);
              sqlTotal = sqlTotal.concat('''');
          end
          
          % PARAMETER_TYPE
          if self.db_wt_fn_parameterID,
          end
          
          % PARAMETER_RESID
          if self.db_wt_fn_parameterResid,
          end
          
          % PARAMETER_TAG
          if self.db_wt_fn_parameterTag,
          end

          % DETECTION_INDICATOR double precision not null
          if self.db_wt_fn_eventCode,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(detec_indi);
          end
          
          % DETECTION_PROBABILITY double precision
          if self.db_wt_fn_eventProb,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(detec_prob);
          end
          
          % CONTRIBUTING_PARAMETERS character varying(100)
          if self.db_wt_fn_eventContrib,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(cont_param);
          sqlTotal = sqlTotal.concat('''');          
          end
          
          % ANALYSIS_COMMENTS character varying(100)
          if self.db_wt_fn_comments,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(anl_comm);
          sqlTotal = sqlTotal.concat('''');
          end
          
          % MATCH_PATTERN_ID character varying(100)
          if self.db_wt_fn_patternID,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat('''');
          sqlTotal = sqlTotal.concat(pat_id);
          sqlTotal = sqlTotal.concat('''');
          end
          
          % MATCH_PROBABILITY double precision
          if self.db_wt_fn_patternProb,
          sqlTotal = sqlTotal.concat(',');
          sqlTotal = sqlTotal.concat(pat_prob);
          end
          
          % MATCH_PATTERN_ID character varying(100)
          if self.db_wt_fn_patternID2,
          end
          
          % MATCH_PROBABILITY double precision
          if self.db_wt_fn_patternProb2,
          end

          % MATCH_PATTERN_ID character varying(100)
          if self.db_wt_fn_patternID3,
          end

          % MATCH_PROBABILITY double precision
          if self.db_wt_fn_patternProb3,
          end
          
          sqlTotal = sqlTotal.concat(')');
        
        otherwise
          sqlTotal = [self.sqlA, self.sqlDateConvertA, ts, self.sqlDateConvertB, self.conn_toDateFmt, self.sqlDateConvertC, ',', '''',loc_id, '''', ',',detec_indi,',',detec_prob,',','''',anl_comm,'''',',','''',cont_param,'''',')'];
      end
      if DeBug
        try
          fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
          fprintf(fid,'%s\n',char(sqlTotal));
          fclose(fid);
        catch
          fprintf(2,'%s\n',char(sqlTotal));
        end
      end
      try
        ct = self.ConnID.prepareCall(sqlTotal);
        ct.execute();
        ct.close();
      catch err,
        if DeBug, cws.errTrace(err); end
        warning(err.identifier, 'Duplicate Entry!');   %add actual
                                                       %entry
        fprintf(2,'%s\n',char(sqlTotal));
        %txt = '';
      end
      cws.logger('exit  populate_db');
    end
    
    function self = initialize_db ( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter initialize_db');
      todateFunc = self.conn_toDateFunc;
      if isempty(strfind(todateFunc,'(')) && isempty(strfind(todateFunc,','))
        todateFunc = [todateFunc,'('];
      end
      if ~isempty(strfind(self.conn_url,'sqlserver'))
        if isempty(self.sqlDateConvertA),
          self.sqlDateConvertA = [todateFunc,''''];
        end
        if isempty(self.sqlDateConvertB),
          self.sqlDateConvertB = ''',';
        end
        if isempty(self.sqlDateConvertC),
          self.sqlDateConvertC = ') ';
        end
      else
          if isempty(self.sqlDateConvertA),
          self.sqlDateConvertA = [todateFunc,''''];
          end
          if isempty(self.sqlDateConvertB),
          self.sqlDateConvertB = ''',''';
          end
          if isempty(self.sqlDateConvertC),
          self.sqlDateConvertC = ''') ';
          end
      end
      
      if self.db_read_current,
      if ~isa(self.db_rt_fn_parameterQuality,'logical')
        self.sqlQueryA = ['SELECT ',self.db_rt_fn_timestep,', ',self.db_rt_fn_parameterTag,', ',self.db_rt_fn_parameterValue,', ',self.db_rt_fn_parameterQuality',...
          ' FROM ',...
          self.input_table,' WHERE ',self.db_rt_fn_parameterTag,' = '];          
      else
        self.sqlQueryA = ['SELECT ',self.db_rt_fn_timestep,', ',self.db_rt_fn_parameterTag,', ',self.db_rt_fn_parameterValue,...
          ' FROM ',...
          self.input_table,' WHERE ',self.db_rt_fn_parameterTag,' = '];          
      end
        self.sqlQueryB = [' ORDER BY ',self.timestep_field];
      
      else
      self.sqlQueryA = ['SELECT * ',...
        ' FROM ',self.input_table,' WHERE (',self.timestep_field,' > ', self.sqlDateConvertA ];
      if ~isa(self.db_rt_fn_parameterQuality,'logical')
        self.sqlQueryAA = ['SELECT ',self.db_rt_fn_timestep,',',self.db_rt_fn_parameterTag,',',self.db_rt_fn_parameterValue,',',db_rt_fn_parameterQuality,...
          ' FROM ',self.input_table,' WHERE (',self.timestep_field,' > ', self.sqlDateConvertA ];
      else
        self.sqlQueryAA = ['SELECT ',self.db_rt_fn_timestep,',',self.db_rt_fn_parameterTag,',',self.db_rt_fn_parameterValue,...
          ' FROM ',self.input_table,' WHERE (',self.timestep_field,' > ', self.sqlDateConvertA ];
      end
      self.sqlQueryB = [ self.sqlDateConvertB , self.conn_toDateFmt, self.sqlDateConvertC , ...
        ' AND ',self.timestep_field,' <= ', self.sqlDateConvertA ];
      sqlQuery = [self.sqlDateConvertB , self.conn_toDateFmt , self.sqlDateConvertC , ' )',...
        '  ORDER BY ',self.timestep_field,''];
      self.sqlQueryC = sqlQuery;
      sqlQuery = [self.sqlDateConvertB , self.conn_toDateFmt , self.sqlDateConvertC , ' AND ',self.db_rt_fn_parameterTag,' = '];
      self.sqlQueryD1 = sqlQuery;
      sqlQuery = [' )',...
        '  ORDER BY ',self.timestep_field,''];
      self.sqlQueryD2 = sqlQuery;
      end
      try
        sqlQuery = ['desc ',self.input_table,';'];
        if DeBug
          try
            fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
            fprintf(fid,'%s\n',sqlQuery);
            fclose(fid);
          catch
            fprintf(2,'%s\n',sqlQuery);
          end
        end
        sq = self.ConnID.prepareStatement(sqlQuery);
        sq.execute();
        rq = sq.getResultSet();
        rqCt = 0;
        while rq.next,
          rqCt = rqCt + 1;
          fields{rqCt} = char(rq.getString('Field'));
        end
        rq.close();
        self.input_fields = fields;
        sq.close();
      catch ERR
        self.input_fields = {};
      end
      if isnan(self.TimeDrift)
        try
          serverDatetime = self.get_server_date();
          if ~isempty(serverDatetime)
            clientDatetime = now();
            cdt = self.time.getDateIdx(clientDatetime,'yyyy-mm-dd HH:MM:SS.FFF');
            sdt = self.time.getDateIdx(serverDatetime,'yyyy-mm-dd HH:MM:SS.FFF');
            self.TimeDrift = sdt - cdt -1;
          end
        catch ERR
          self.TimeDrift = 0;
        end
      end
      cws.logger('exit  initialize_db');
    end
    
    function self = read_rowbased ( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter read_rowbased');
      if nargin < 3,
        error('CANARY:datasource:gdb',...
          'You must supply at least one date when reading row based data tables');
      end
      if strcmpi(self.run_mode,'batch') || strcmpi(self.run_mode,'batch_daily'),
        self.TimeDrift = 0;
      end
      dbfid = fopen([self.conn_id,'_debug.txt'],'w');
      CDS = varargin{1};
      if nargin < 3 || isempty(varargin{2}),
        % This is an update for 1 day
        idx = 1 + self.time.getDateIdx(now) + self.TimeDrift;
        if idx < 1, return; end;
        idx1 = max(idx,1);
        if length(CDS.timesteps) >= idx
          stopTime = char(CDS.timesteps{idx});
        else
          stopTime = self.time.getDateStr(idx);
        end
        idx = 1 + self.time.getDateIdx(now-1) + self.TimeDrift;
        if idx < 1, idx = 1; end;
        if length(CDS.timesteps) >= idx
          startTime = char(CDS.timesteps{idx});
        else
          startTime = self.time.getDateStr(idx);
        end
        idx0 = max(idx,1);
      elseif nargin < 4,
        stopTime = varargin{2};
        idx = self.time.getDateIdx(varargin{2});
        if idx < 1, return; end;
        idx = max(idx,1);
        if idx > length(CDS.timesteps),
          startTime = self.time.getDateStr(idx-10);
          CDS.timesteps{idx} = stopTime;
        else
          startTime = CDS.timesteps{idx-10};
        end
        idx1 = idx + self.TimeDrift;
        idx0 = idx + self.TimeDrift;
      else
        idx = 1 + self.time.getDateIdx(varargin{3}) + self.TimeDrift;
        if idx < 1, return; end;
        if length(CDS.timesteps)>= idx,
          stopTime = char(CDS.timesteps{idx});
        else
          stopTime = char(self.time.getDateStr(idx));
        end
        idx1 = max(idx,1);
        idx = self.time.getDateIdx(varargin{2}) + self.TimeDrift;
        if idx < 1, return; end;
        if length(CDS.timesteps) >= idx && idx > 0
          startTime = char(CDS.timesteps{idx});
        else
          startTime = self.time.getDateStr(idx);
        end
        idx0 = max(idx,1);
      end
      
      if idx0 == idx1,
        idx0 = idx1 - 5;
        idx1 = idx1 + 1;
        startTime = self.time.getDateStr(idx0);
        stopTime = self.time.getDateStr(idx1);
      end
      idx0 = max(idx0,1);
      idx1 = max(idx1,1);
      CDS.values(idx,1) = 0;
      switch lower(CDS.prov_type)
        case {'changes','changed','new values','new value'}
          new_value_db = true;
        otherwise
          new_value_db = false;
      end
      recCt = 0;
      for i = 1:length(CDS.scadatags)-1
        tag = CDS.scadatags{i+1};
        if CDS.fromConn(i+1) > 0 && CDS.fromConn(i+1) ~= self.conn_id_num,
          continue;
        end
        %            sqlQuery = [self.sqlQueryA,char(startTime),self.sqlQueryB,char(stopTime),self.sqlQueryD1,tag,sqlf.sqlQueryD2];
        sqlQuery = [self.sqlQueryAA,char(startTime),self.sqlQueryB,char(stopTime),self.sqlQueryD1,tag,self.sqlQueryD2];
        if DeBug
          fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
          fprintf(fid,'%s\n',sqlQuery);
          fclose(fid);
        end
        fprintf(dbfid,'%s\n',char(sqlQuery));
        cs = self.ConnID.prepareStatement(char(sqlQuery));
        cs.execute();
        self.clear_idle();
        rs = cs.getResultSet();
        prevTS = '';
        prevIDX = 0;
        %if self.db_read_current,
        %  prevIDX = idx;
        %end
        while rs.next,
          try
            recCt = recCt + 1;
            tstp = char(rs.getString(1));
            par = char(rs.getString(2));
            parNum = strmatch(par,CDS.scadatags,'exact');
            val = rs.getDouble(3);
            fprintf(dbfid,'%s %s %f\n',tstp,par,val);
            wasNull = false;
            try
              if rs.wasNull()
                wasNull = true;
              end
            catch E
            end
            if ~isa(self.db_rt_fn_parameterQuality,'logical')
              if ~isempty(self.db_rt_fn_parameterQuality)
                qty = char(rs.getString(4));
                if strcmpi(qty,'bad'),
                  val = nan;
                end
              end
            end
            if strcmpi(tstp,prevTS),
              idx = prevIDX;
            else
              idx = self.time.getDateIdx(tstp,'yyyy-mm-dd HH:MM:SS.FFF') - self.TimeDrift;
              % TODO: COPY PREVIOUS VALUES UP TO HERE IF THIS IS A
              % DIFFERENCING TYPE DATABASE
              if prevIDX ~= 0 && new_value_db && ~isempty(parNum),
                for pn = 1:length(parNum),
                  CDS.values(prevIDX+1:idx-1,parNum(pn)) = CDS.values(prevIDX,parNum(pn));
                end
              end
              prevIDX = idx;
              prevTS = tstp;
            end
            if isempty(parNum),
              continue;
            end
            if idx < 1, continue; end;
            for pn = 1:length(parNum),
              if CDS.sigtype(parNum(pn)) == 1,
                if ~wasNull,
                  CDS.values(idx:idx1,parNum(pn)) = val;
                  if val ~= 0,
                    CDS.fromConn(parNum(pn)) = self.conn_id_num;
                  end
                end
              elseif CDS.sigtype(parNum(pn)) == -1,
                va = str2double(CDS.alarmvalue{parNum(pn)});
                if val == va && ~wasNull,
                  CDS.values(idx,parNum(pn)) = nan;
                  CDS.fromConn(parNum(pn)) = self.conn_id_num;
                else
                  CDS.values(idx:idx1,parNum(pn)) = 0;
                end
              elseif CDS.sigtype(parNum(pn)) == 0,
                va = str2double(CDS.alarmvalue{parNum(pn)});
                if val == va && ~wasNull,
                  CDS.values(idx,parNum(pn)) = nan;
                  CDS.fromConn(parNum(pn)) = self.conn_id_num;
                else
                  CDS.values(idx:idx1,parNum(pn)) = 0;
                end
              elseif CDS.sigtype(parNum(pn)) == 2,
                if ~wasNull,
                  CDS.values(idx:idx1+1,parNum(pn)) = val;
                  %CDS.values(idx+1,parNum(pn)) = val;
                  CDS.fromConn(parNum(pn)) = self.conn_id_num;
                end
              else
                CDS.values(idx:idx1,parNum(pn)) = val;
                if val ~= 0,
                  CDS.fromConn(parNum(pn)) = self.conn_id_num;
                end
              end
            end
          catch DBErr
            if DeBug, cws.errTrace(DBErr); end
            rs.close();
            cs.close();
            rethrow(DBErr)
          end
        end
        rs.close();
        cs.close();
      end
      fclose(dbfid);
      numRows = recCt;
      self.evalComposites(CDS, idx0, idx1);
      cws.logger('exit  read_rowbased');
    end
    
    function self = read_table ( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter read_table');
      CDS = varargin{1};
      if strcmpi(self.run_mode,'batch') || strcmpi(self.run_mode,'batch_daily'),
        self.TimeDrift = 0;
      end
      if nargin < 3 || isempty(varargin{2}),
        % This is an update for 1 day
        idx = 1 + self.time.getDateIdx(now) + self.TimeDrift;
        if idx < 1, return; end;
        idx1 = max(idx,1);
        if length(CDS.timesteps) >= idx
          stopTime = char(CDS.timesteps{idx});
        else
          stopTime = self.time.getDateStr(idx);
        end
        idx = 1 + self.time.getDateIdx(now-1) + self.TimeDrift;
        if length(CDS.timesteps) >= idx
          startTime = char(CDS.timesteps{idx});
        else
          startTime = self.time.getDateStr(idx);
        end
        idx0 = max(idx,1);
      elseif nargin < 4,
        idx = 1 + self.time.getDateIdx(varargin{2}) + self.TimeDrift;
        if idx < 1, return; end;
        if length(CDS.timesteps) >= idx
          stopTime = char(CDS.timesteps{idx});
        else
          stopTime = self.time.getDateStr(idx);
        end
        idx1 = idx;
        idx = max(idx-2,1);
        if length(CDS.timesteps) >= idx
          startTime = char(CDS.timesteps{idx});
        else
          startTime = self.time.getDateStr(idx);
        end
        idx0 = max(idx,1);
      else
        idx = 1 + self.time.getDateIdx(varargin{3}) + self.TimeDrift;
        if idx < 1, return; end;
        if length(CDS.timesteps)>= idx,
          stopTime = char(CDS.timesteps{idx});
        else
          stopTime = char(self.time.getDateStr(idx));
        end
        idx1 = max(idx,1);
        idx = self.time.getDateIdx(varargin{2}) + self.TimeDrift;
        if idx < 1,
          idx = 1;
        end
        if length(CDS.timesteps) >= idx
          startTime = char(CDS.timesteps{idx});
        else
          startTime = self.time.getDateStr(idx);
        end
        idx0 = max(idx,1);
      end
      sqlQuery = [self.sqlQueryA,char(startTime),self.sqlQueryB,char(stopTime),self.sqlQueryC];
      if DeBug,
        fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
        fprintf(fid,'%s\n',char(sqlQuery));
        fclose(fid);
      end
      cs = self.ConnID.prepareStatement(char(sqlQuery));
      cs.execute();
      rs = cs.getResultSet();
      warn = cs.getWarnings();
      if DeBug,
        cws.trace('SQL=',sqlQuery);
        if ~isempty(warn),
          cws.trace('WARN=',warn.toString());
        end
      end
      if isempty(self.tableFldIDs),
        if isempty(self.input_fields),
          self.input_fields = {CDS.scadatags{2:end}};
        end
        parNums = zeros(size(self.input_fields));
        fldNums = zeros(size(self.input_fields));
        for fldCt = 1:length(self.input_fields)
          try
            parNums(fldCt) = fldCt + 1;
            fldNums(fldCt) = rs.findColumn(self.input_fields{fldCt});
          catch ERR
            fldNums(fldCt) = 0;
            parNums(fldCt) = 0;
            if isempty(strfind(ERR.message,'Invalid column name')) && ...
                ( isempty(strfind(ERR.message,'The column name')) || ...
                isempty(strfind(ERR.message,'is not valid')) )
              cws.errTrace(ERR)
              continue;
            end
          end
        end
        self.input_fields = self.input_fields(fldNums > 0);
        fldNums = fldNums(fldNums > 0);
        parNums = parNums(fldNums > 0);
        self.tableFldIDs = fldNums;
        self.tableParNum = fldNums;
      else
        fldNums = self.tableFldIDs;
        parNums = self.tableParNum;
      end
      recCt = 0;
      prevTS = '';
      prevIDX = 0;
      rsCt = 0;
      while rs.next,  % FOR EACH ROW
        rsCt = rsCt + 1;
        if DeBug,
          fprintf(2,'.');
          if mod(rsCt,64)==0,
            fprintf(2,' 0x%4x\n',rsCt-1);
          end
        end
        tstp = char(rs.getString(self.timestep_field));
        if strcmp(tstp,prevTS),
          idx = prevIDX;
        else
          idx = self.time.getDateIdx(tstp,'yyyy-mm-dd HH:MM:SS.FFF') - self.TimeDrift;
          prevIDX = idx;
          prevTS = tstp;
        end
        if idx < 1, continue; end;
        for fieldCt = 1:length(self.input_fields),
          try
            parNum = parNums(fieldCt);
            recCt = recCt + 1;
            val = rs.getDouble(CDS.scadatags{parNum});
            wasNull = false;
            try
              if rs.wasNull()
                wasNull = true;
              end
            catch E
            end
            if CDS.sigtype(parNum) == 1,
              CDS.values(idx,parNum) = val;
            elseif CDS.sigtype(parNum) == -1,
              va = str2double(CDS.alarmvalue{parNum});
              if val == va,
                CDS.values(idx,parNum) = nan;
              else
                CDS.values(idx,parNum) = 0;
              end
            elseif CDS.sigtype(parNum) == 0,
              va = str2double(CDS.alarmvalue{parNum});
              if val == va,
                CDS.values(idx,parNum) = nan;
              else
                CDS.values(idx,parNum) = 0;
              end
            elseif CDS.sigtype(parNum(pn)) == 2,
              if ~wasNull,
                CDS.values(idx,parNum(pn)) = val;
                CDS.values(idx+1,parNum(pn)) = val;
              end
            else
              CDS.values(idx,parNum) = val;
            end
          catch DBErr
            b_use_fields(fieldCt) = false;
          end
        end
      end
      if DeBug,
        fprintf(2,'\n');
      end
      rs.close();
      cs.close();
      self.evalComposites(CDS, idx0, idx1);
      %       if DeBug,
      %         disp(CDS.values(idx,:));
      %       end
      cws.logger('exit  read_table');
      % END OF READ_TABLE -----------------------------------------------------
    end
    
    function self = read_eddies ( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter read_eddies');
      if nargin < 3,
        error('CANARY:datasource:gdb',...
          'You must supply at least one date when Updating EDDIES Input Objects');
      end
      if strcmpi(self.run_mode,'batch') || strcmpi(self.run_mode,'batch_daily'),
        self.TimeDrift = 0;
      end
      CDS = varargin{1};
      if nargin < 4,
        stopTime = varargin{2};
        idx = self.time.getDateIdx(varargin{2});
        if idx < 0, return; end;
        idx = max(idx,1);
        if idx > length(CDS.timesteps),
          startTime = self.time.getDateStr(idx-1);
          CDS.timesteps{idx} = stopTime;
        else
          startTime = CDS.timesteps{idx-1};
        end
        idx1 = idx + self.TimeDrift;
        idx0 = idx + self.TimeDrift;
      else
        startTime = varargin{2};
        stopTime = varargin{3};
        idx = self.time.getDateIdx(stopTime);
        idx1 = idx + self.TimeDrift;
        idx0 = self.time.getDateIdx(startTime) + self.TimeDrift;
      end
      CDS.values(idx,1) = 0;
      
      sqlQuery = [self.sqlQueryA,char(startTime),self.sqlQueryB,char(stopTime),self.sqlQueryC];
      
      if DeBug
        fid = fopen([self.data_dir_path,filesep,'debug.sql'],'at');
        fprintf(fid,'%s\n',sqlQuery);
        fclose(fid);
      end
      
      cs = self.ConnID.prepareStatement(char(sqlQuery));
      cs.execute();
      self.clear_idle();
      rs = cs.getResultSet();
      recCt = 0;
      prevTS = '';
      prevIDX = 0;
      while rs.next,
        try
          recCt = recCt + 1;
          tstp = char(rs.getString(self.timestep_field));
          par = char(rs.getString('PARAMETER_ID'));
          parNum = strmatch(par,CDS.scadatags,'exact');
          val = rs.getDouble('SAMPLE_VALUE');
          wasNull = false;
          try
            if rs.wasNull()
              wasNull = true;
            end
          catch E
          end
          qty = char(rs.getString('SAMPLE_QUALITY'));
          if strcmpi(qty,'bad'),
            val = nan;
          end
          if strcmpi(tstp,prevTS),
            idx = prevIDX;
          else
            idx = self.time.getDateIdx(tstp,'yyyy-mm-dd HH:MM:SS.FFF') - self.TimeDrift;
            prevIDX = idx;
            prevTS = tstp;
          end
          if isempty(parNum),
            continue;
          end
          if idx < 1, continue; end;
          for pn = 1:length(parNum),
            if CDS.sigtype(parNum(pn)) == 1,
              if ~wasNull,
                CDS.values(idx,parNum(pn)) = val;
              end
            elseif CDS.sigtype(parNum(pn)) == -1,
              va = str2double(CDS.alarmvalue{parNum(pn)});
              if val == va && ~wasNull,
                CDS.values(idx,parNum(pn)) = nan;
              else
                CDS.values(idx,parNum(pn)) = 0;
              end
            elseif CDS.sigtype(parNum(pn)) == 0,
              va = str2double(CDS.alarmvalue{parNum(pn)});
              if val == va && ~wasNull,
                CDS.values(idx,parNum(pn)) = nan;
              else
                CDS.values(idx,parNum(pn)) = 0;
              end
            elseif CDS.sigtype(parNum(pn)) == 2,
              if ~wasNull,
                CDS.values(idx,parNum(pn)) = val;
                CDS.values(idx+1,parNum(pn)) = val;
              end
            else
              CDS.values(idx,parNum(pn)) = val;
            end
          end
        catch DBErr
          if DeBug, cws.errTrace(DBErr); end
          rs.close();
          cs.close();
          rethrow(DBErr)
        end
      end
      rs.close();
      cs.close();
      numRows = recCt;
      self.evalComposites(CDS, idx0, idx1);
      cws.logger('exit  read_eddies');
    end
    
    function self = RegisterDriver( self )
      %REGISTERDRIVER Method to register a JDBC driver, if necessary
      %   This method is somewhat obsolete, since newer JDBC drivers do not use the
      %   DriverManager, but use DataSources instead. The latter is by far the
      %   preferred method to connect to a JDBC database. For files or XML
      %   Connections, it does nothing but set the appropriate flags.
      %
      % See also connect and disconnect
      %
      % Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      switch lower(self.conn_type)
        case {'jdbc','db'} % This is a JDBC Connection
          try
            if ~isempty(self.driver_class)
              driver = eval(self.driver_class);
              javaMethod('registerDriver','java.sql.DriverManager',driver);
            end
            self.IsRegistered = true;
          catch CONERR
            cws.errTrace(CONERR);
            self.IsRegistered = false;
            error('CANARY:datasource:gdb:DriverRegFailed','Error registering driver: %s',self.driver_class);
          end
      end
      % END OF REGISTERDRIVER -------------------------------------------------
    end
    
  end
  
  % END OF CLASSDEF DATASOURCE ================================================
end
