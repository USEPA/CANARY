classdef MSGRDataSource < handle & cws.DataSource % ++++++++++++++++++++++++++++++++++++++++++++++++
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
    
    function self = MSGRDataSource( varargin ) % ------------------- CONSTRUCTOR --
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
          error('CANARY:unknownConn','Unknown construction method: %s',class(self));
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
            warning('CANARY:unkownOption','''%s'' is not a recognized option',fld);
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
      self.IsConnected = true;
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
      if self.LogFID > 0,
        fprintf(self.LogFID,'- messenger shutdown: "%s"\n',datestr(now(),30));
        fclose(self.LogFID);
        self.LogFID = 0;
      end
      self.Isinitialized = false;
      self.addMessageCS = [];
      self.getMessageCS = [];
      % END OF DISCONNECT -----------------------------------------------------
    end
    
    function message = read( self )
      %READMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('enter read');
      message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
      if ~self.Isinitialized,
        try
          self.initialize();
        catch ERR
          if DeBug, cws.errTrace(ERR); end
          self.disconnect();
          self.Isinitialized = false;
          self.IsCtlInit = false;
          baseME = MException('CANARY:messageReadFailed','Failed to read messages');
          switch upper(self.msgr_type)
            case {'EXTERNAL','INTERNAL'}
              if ~isempty(self.queue),
                message = self.queue(1).m;
                self.queue = self.queue(2:end);
              else
                message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
              end
              return
            otherwise
              newME = addCause(baseME,ERR);
              throw(newME);
          end
        end
      end
      if ~self.IsConnected,
        try
          self.connect();
        catch ERR
          if DeBug, cws.trace(ERR.stack(1).name,num2str(ERR.stack(1).line)); end
          self.disconnect();
          %self.Isinitialized = false;
          %self.IsCtlInit = false;
          baseME = MException('CANARY:messageReadFailed','Failed to read messages');
          switch upper(self.msgr_type)
            case {'EXTERNAL','INTERNAL'}
              if ~isempty(self.queue),
                message = self.queue(1).m;
                self.queue = self.queue(2:end);
              else
                message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
              end
              return
            otherwise
              newME = addCause(baseME,ERR);
              throw(newME);
          end
        end
      end
      try
        if ~isempty(self.queue),
          message = self.queue(1).m;
          self.queue = self.queue(2:end);
        else
          message = cws.Message('to','CANARY','error','no message found');
        end
        t = timerfind('Tag','tsUpdate');
        if ~isempty(t),
          if strcmp(t.Running,'off'),
            start(t);
          end
        end
      catch ERR
        cws.errTrace(ERR);
        baseME = MException('CANARY:messageReadFailed','Failed to read messages');
        if ~isempty(self.queue),
          message = self.queue(1).m;
          self.queue = self.queue(2:end);
        else
          message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
        end
        return
      end
      if DeBug && ~strcmpi(message.error,'no message found'),
        disp(message);
      elseif DeBug,
        %        fprintf(2,'.');
      end
      if ~strcmpi(message.error,'no message found')
        if self.LogFID > 0,
          fprintf(self.LogFID,'%s\n',char(message));
        else
          self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'at');
          if self.LogFID > 0,
            fprintf(self.LogFID,'%s\n',char(message));
          else
            fprintf(2,'%s\n',char(message));
          end
        end
      end
      if ~isempty(message.error) && ~strcmpi(message.error,'no message found')
        fprintf(2,'%s\n',char(message));
      end
      cws.logger('exit  read');
      % END OF READ -----------------------------------------------------------
    end
    
    function errortext = send( self , message )
      %SENDMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('enter send');
      if ~self.Isinitialized,
        warning('CANARY:messengerNotinitialized',...
          'The messenger was not yet initialized when a send requested');
        try
          self.initialize();
        catch ERR
          if strcmpi(message.to,'canary')
            self.queue(end+1).m = message;
          end
        end
      end
      if ~isa(message,'cws.Message')
        error('CANARY:noMessage','Your message is an invalid Object');
      end
      if ~isempty(message.error),
        fprintf(2,'%s\n',char(message));
      end
      if strcmpi(message.to,'canary')
        self.queue(end+1).m = message;
      end
      if self.LogFID > 0,
        fprintf(self.LogFID,'%s\n',char(message));
      else
        self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'at');
        if self.LogFID > 0,
          fprintf(self.LogFID,'%s\n',char(message));
        else
          fprintf(2,'%s\n',char(message));
        end
      end
      cws.logger('exit  send');
      % END OF SEND -----------------------------------------------------------
    end
    
    function self = initialize_files( self , LOC , CDS)
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      warning('CANARY:datasource','Using Base Class for Unanticipated Overloaded Method');
    end
    
    function self = initializeControl( self , varargin )
      %INITIALIZE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('INITIALIZATION','Initializing Control'); end;
      if isempty(varargin),
        locations = [];
      else
        locations = varargin{1};
      end
      if ~self.IsConnected,
        self.connect();
        if ~self.IsConnected,
          ME = MException('CWS:DataSource:Control','Failure to connect during initialization');
          throw(ME);
        end
      end
      self.IsConnected = true;
      self.state = 1;
      self.IsCtlInit = true;
      self.queue(1).m = cws.Message('to','CANARY','from','CONTROL',...
        'subj','WELCOME','cont',datestr(now()));
      if nargin >=2
        for iL = 1:length(locations)
          loc = char(locations{iL});
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj',['START ',loc],'cont','');
        end
      end
      switch lower(self.run_mode)
        
        case {'batch_daily'}
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','TIMESTEP START','cont',self.time.getstartDate());
          d1 = self.time.date_start;
          d2 = self.time.date_end;
          for iDate = d1+2:1:d2
            self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
              'subj','TIMESTEP CONTINUE','cont',datestr(iDate,self.time.date_fmt));
          end
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','TIMESTEP CONTINUE','cont',datestr(d2,self.time.date_fmt));
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','TIMESTEP END','cont','');
          if nargin >=2
            for iL = 1:length(locations)
              loc = char(locations{iL});
              self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
                'subj',['STOP ',loc],'cont','');
            end
          end
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','SHUTDOWN','cont','');
          
          self.IsCtlInit = true;
          
          
        case {'batch','training'}
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','TIMESTEP START','cont',self.time.getstartDate());
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','TIMESTEP END','cont',self.time.getEndDate());
          if strcmpi(self.run_mode,'training'),
            self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
              'subj','CLUSTERIZE','cont','');
          end
          if nargin >=2
            for iL = 1:length(locations)
              loc = char(locations{iL});
              self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
                'subj',['STOP ',loc],'cont','');
            end
          end
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','SHUTDOWN','cont','');
          
          self.IsCtlInit = true;
          
        case {'saveonly'}
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','UPDATE','cont','');
          if nargin >=2
            for iL = 1:length(locations)
              loc = char(locations{iL});
              self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
                'subj',['STOP ',loc],'cont','');
            end
          end
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','SHUTDOWN','cont','');
          
          self.IsCtlInit = true;
          
        otherwise
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj','UPDATE','cont','');
          self.IsCtlInit = true;
      end
      self.IsCtlInit = true;
      
      self.LogFID = fopen([self.log_path,self.conn_id,'.msg.log'],'wt');
      fprintf(self.LogFID,'# Messenger startup: %s\n',datestr(now(),30));
      % END OF INITIALIZECONTROL ----------------------------------------------
    end
    
    % END OF PUBLIC METHODS ===============================================
  end
  
  methods ( Access = 'private' ) % +++++++++++++++++++++++++++++++++++++++
    
    function msg = group_output( self , idx , LOC , timestep )
      warning('CANARY:datasource','Using Base Class for Unanticipated Overloaded Method');
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if idx < 2,
        msg = [];
        return;
      end
      msg = cws.Message('to',[LOC.name,' -'],'cont',timestep);
      try
        genCode = LOC.algs(end).eventcode(idx,1,1);
        %        if DeBug,
        %          fprintf(2,'%s\n',toString(self.create_results_xml(idx,LOC)));
        %        end
        if genCode == 2
          if LOC.algs(end).eventcode(idx-1,1,1) ~= 2,
            msg.subj = timestep;
            msg.warn = 'Location in calibration mode';
          end
        elseif genCode == 3
          if LOC.algs(end).eventcode(idx-1,1,1) ~= 3,
            msg.subj = timestep;
            msg.error = 'All sensors are off-line';
          end
        elseif genCode == 4
          msg.subj = timestep;
          msg.warn = 'Location out of calibration mode';
        else
          if LOC.algs(end).eventcode(idx-1,1,1) == 3,
            msg.subj = timestep;
            msg.warn = 'Some sensors back on-line';
          else
            for iA = 1:length(LOC.algs),
              if LOC.algs(iA).report == false,
                continue;
              end
              for iT = 1:length(LOC.algs(iA).tau_out)
                if LOC.algs(iA).eventcode(idx,1,iT) == 1
                  prob = LOC.algs(iA).eventprob(idx,1,iT);
                  msg.subj = timestep;
                  msg.from = 'EVENT';
                  msg.warn = [msg.warn,LOC.algs(iA).type,'{',num2str(LOC.algs(iA).tau_out(iT),'%.1f'),'}:(',num2str(prob*100-0.1,'%4.1f'),'%)    '];
                elseif LOC.algs(iA).eventcode(idx,1,iT) == -1
                  msg.subj = timestep;
                  msg.from = 'EVENT';
                  msg.warn = [msg.warn,LOC.algs(iA).type,'{',num2str(LOC.algs(iA).tau_out(iT),'%.1f'),'}:( BLC )    '];
                  %             elseif sum(LOC.algs(iA).eventcode(idx,1,:) == -2) > 0
                  %               msg.subj = timestep;
                  %               msg.from = 'EVENT';
                  %               msg.warn = [msg.warn,LOC.algs(iA).type,'( N/A )  '];
                elseif LOC.algs(iA).cluster_ids(idx,1,iT) ~= 0 && ~isempty(LOC.algs(iA).library)
                  msg.subj = timestep;
                  msg.from = 'EVENT';
                  msg.warn = [msg.warn,LOC.algs(iA).library.clust.cluster_ids{1}{LOC.algs(iA).cluster_ids(idx,1,iT)},':(',...
                    num2str(100*LOC.algs(iA).cluster_probs(idx,1,iT),'%.1f'),'%)    '];
                else
                  msg.warn = [msg.warn,LOC.algs(iA).type,'{',num2str(LOC.algs(iA).tau_out(iT),'%.1f'),'}:(  -  )    '];
                end
              end
            end
          end
        end
      catch
      end
      if isempty(msg.subj),
        msg = [];
      end
    end
    
  end
  
  % END OF CLASSDEF DATASOURCE ================================================
end
