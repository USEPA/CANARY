classdef XMLDataSource < handle & cws.DataSource % ++++++++++++++++++++++++++++++++++++++++++++++++
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
  % Patch: r3527 - John Knoll, TetraTech, 5/21/2010
  
  methods % PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    function self = XMLDataSource( varargin ) % ------------------- CONSTRUCTOR --
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
          error('CANARY:datasource:xml:unknownConn','Unknown construction method: %s',class(self));
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
            warning('CANARY:datasource:xml:unkownOption','''%s'' is not a recognized option',fld);
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
      try
        if isempty(self.conn_port),
          self.ConnID = fopen(self.conn_url,'wt');
          fprintf(self.ConnID,'<MessageList>\n');
          self.IsConnected = true;
          %               fclose(self.ConnID);
          %               self.ConnID = -1;
        else
          if ischar(self.conn_port)
            self.conn_port = str2double(self.conn_port);
          end
          if ~isa(self.ConnID,'java.net.Socket'),
            self.ConnID = java.net.Socket(self.conn_ipaddress,self.conn_port);
          else
            if self.ConnID.isConnected() && ~self.ConnID.isClosed(),
              self.IsConnected = true;
              return;
            else
              self.ConnID.close();
            end
          end
          
          if ~(self.ConnID.isConnected) || self.ConnID.isClosed,
            self.ConnID.close();
            self.ConnID = java.net.Socket(self.conn_ipaddress,self.conn_port);
          end
          if ~(self.ConnID.isClosed),
            self.inputStrm = self.ConnID.getInputStream();
            self.outputStrm = self.ConnID.getOutputStream();
            self.IsConnected = true;
          else
            warning('CANARY:datasource:xml:connection','Connection to <%s:%s> unavailable at this time.', ...
              self.conn_ipaddress,num2str(self.conn_port));
            self.disconnect()
            pause(10);
          end
        end
      catch e
        if DeBug, cws.errTrace(e); end;
        if ~isempty(strfind(e.message,'java.net.ConnectException: Connection refused')),
          warning('CANARY:datasource:xml:connection','Connection to <%s:%s> unavailable at this time.', ...
            self.conn_ipaddress,num2str(self.conn_port));
          self.disconnect()
          pause(10);
        else
          warning('CANARY:datasource:xml:connection','Connection error: %s',e.message);
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
        cws.logger('xmlmsgr disconnect');
        if ~isempty(self.inputStrm),
          try
            self.inputStrm.close();
          catch ERR
            cws.errTrace(ERR);
            self.inputStrm = [];
          end
        end
        if ~isempty(self.outputStrm),
          try
            self.outputStrm.close();
          catch ERR
            cws.errTrace(ERR);
            self.outputStrm = [];
          end
        end
        if ~isempty(self.ConnID)
          try
            self.ConnID.close();
          catch ERR
            cws.errTrace(ERR);
            self.ConnID = [];
          end
        end
        if self.IsControl,
          self.IsCtlInit = false;
          self.Isinitialized = false;
          self.dbUpdated = false;
          self.dbUpdateDone = 0;
          self.haveGotData = 0;
        end
        self.CurrMsgID = 0;
        self.messageCenter.NextTxID = 0;
        self.messageCenter.NextRxID = 0;
        self.IsConnected = false;
      catch ERR
        if DeBug, cws.errTrace(ERR); end
        self.IsConnected = false;
        warning('CANARY:datasource:xml:conndisconnect',ERR.message);
      end
      %if self.LogFID > 0,
      %  fprintf(self.LogFID,'Shutdown: "%s"\n',datestr(now(),30));
      %  fclose(self.LogFID);
      %  self.LogFID = 0;
      %end
      self.Isinitialized = false;
      self.addMessageCS = [];
      self.getMessageCS = [];
      % END OF DISCONNECT -----------------------------------------------------
    end
    
    function self = update( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('xmlmsgr update');
      if ~self.isused, return ; end
      %       if sum(self.isActive) < 1 , return ; end
      %       usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj','Updating data','cont',datestr(now));
      %       disp(usrmsg);
      if ~self.IsInput, return; end;
      if DeBug,
        st1 = datestr(now(),30);
        fprintf(2,'- update from source: %s\n',self.conn_url);
      end
      try
        self.read_xmldata(varargin{:});
      catch ERR
        cws.errTrace(ERR);
      end
      self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont','-1');
      if DeBug,
        st2 = datestr(now(),30);
        fprintf(2,'  update duration:  %s --> %s\n',st1,st2);
      end
      
      % END OF UPDATE ---------------------------------------------------------
    end
    
    
    % ------ MESSENGER/CONTROL SPECIFIC FUNCTIONS -----------------------------
    
    function message = read( self )
      %READMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('xmlmsgr read',0);
      message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
      if ~self.Isinitialized,
        try
          self.initialize();
        catch ERR
          if DeBug, cws.errTrace(ERR); end
          self.disconnect();
          self.Isinitialized = false;
          self.IsCtlInit = false;
          baseME = MException('CANARY:datasource:xml:messageReadFailed','Failed to read messages');
          if ~isempty(self.queue),
            message = self.queue(1).m;
            self.queue = self.queue(2:end);
          else
            message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
          end
          return
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
          baseME = MException('CANARY:datasource:xml:messageReadFailed','Failed to read messages');
          if ~isempty(self.queue),
            message = self.queue(1).m;
            self.queue = self.queue(2:end);
          else
            message = cws.Message('to','CANARY','from','CONTROL','subj','PAUSE','cont','no content');
          end
          return
        end
      end
      try
        str = '';
        try
          if ~self.Isinitialized || ~self.IsConnected
            ME = MException('CANARY:datasource:xml:read','Read while unitialized');
            throw(ME);
          end
          if self.CurrMsgID == 0,
            self.RecievedQueue = self.RecievedQueue(1:min(end,2));
            self.SentQueue = self.SentQueue(1:min(end,2));
          end
          msg = cws.XMLMessage();
          if ~isempty(self.extraMessage)
            str = self.extraMessage;
            self.extraMessage = '';
          else
            in = java.io.BufferedInputStream(self.inputStrm);
            %                 if DeBug, cws.trace('READING','Checking Availibility'); end
            if in.available(),
              str = '';
              while(in.available())
                character = in.read();
                str = [str character]; %#ok<*AGROW>
              end
            end
            clear in;
          end
          if ~isempty(str)
            cws.logger(' found message',0);
            numMessages = findstr(str, '</Message>');
            if length(numMessages) > 1
              self.extraMessage = str(numMessages(1)+10:length(str));
              str = str(1:numMessages(1)+9);
            end
            if ~isempty(numMessages)
              if ~isequal(str(length(str)), sprintf('\n'))
                str = [str sprintf('\n')];
              end
              msg.parseString(str);
              if self.RcvdNewData,
                self.AverageDataProcessingDelay = mean([self.IdleCount self.AverageDataProcessingDelay]);
              end
              self.IdleCount = 0;
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Now use messageCenter instead
              if DeBug > 0,
                fprintf(2,'Received Message:\n');
                fprintf(2,msg.json);
              end;
              self.messageCenter.EnqueueReceived(msg);
              [ status , ack ] = self.messageCenter.ReadReceived();
              if status ~= 0,
                fprintf(2,'Wrong Rx MsgID\nMessage Received Follows:\n');
                fprintf(2,msg.json);
                fprintf(2,'Last Message Sent to XML client:\n');
                if ~isempty(self.messageCenter.sent)
                  if ~isempty(self.messageCenter.sent.tail)
                    fprintf(2,self.messageCenter.sent.tail.json);
                  end
                end
                fprintf(2,'**** DISCONNECTED ****\n');
                self.disconnect()
                error('xmlmessenger:datamismatch','Wrong RX MsgID - forced reboot');
              end
              if ~isempty(ack)
                self.messageCenter.EnqueueReply( ack );
              end
              % We don't want to timestep ahead of receiving all data -
              % this should keep things from going all to heck now.
              if DeBug > 0
                fprintf(2,'DEBUG: FOUND ResWait = %d\n',msg.ResWait);
              end
              switch msg.Type
                case {'DATA'}
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','UPDATE','cont',num2str(msg.MsgID));
                  self.haveGotData = 1;
                  self.RcvdNewData = true;
                  self.LastDateTimeSeen = msg.Station(1).Points(1).SrcTime;
                  self.msgs_clear = now;
                  if isempty(msg.ResWait),
                    self.data_done = false;
                  else
                    self.data_done = 1-max(msg.ResWait);
                  end
                case {'DBUPDATE_RESP'}
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','UPDATE','cont',num2str(msg.MsgID));
                  self.msgs_clear = now;
                  self.data_done = false;
                case {'DBUPDATE_END'}
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont',num2str(msg.MsgID));
                  self.state = 1;
                  self.dbUpdateDone = 1;
                  self.data_done = false;
                  fprintf(2,'DEBUG: FOUND ResWait = %d\n',msg.ResWait);
                case {'N'}  % N should be impossible, but just in case...
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont',num2str(msg.MsgID));
                  self.state = 1;
                  self.data_done = false;
                case {'LIFECHECK'}  % N should be impossible, but just in case...
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont',num2str(msg.MsgID));
                  self.state = 1;
                  self.data_done = false;
                  self.msgs_clear = now;
                  %                       t = timerfind('Tag','tsUpdate');
                  %                       if ~isempty(t) && self.haveGotData > 0,
                  %                         if strcmp(t.Running,'off'),
                  %                           start(t);
                  %                         end
                  %                       end
                case {'NACK'}
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont',num2str(msg.MsgID));
                  self.data_done = false;
                case {'DBUPDATE_ACK'}
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','INFO','cont','Started DB Update');
                  if  msg.MsgErrCode > 0 && msg.MsgErrCode < 10,
                    cws.trace('DBUPDATE_ERR',['Failed with message code = ',num2str(msg.MsgErrCode)]);
                    self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont',num2str(msg.MsgID));
                  end
                  self.data_done = false;
                case {'DATA_ACK'}
                  self.IsWaiting = false;
                  self.data_done = false;
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont','-1');
                case {'LIFECHECK_ACK'}
                  self.IsWaiting = false;
                  self.data_done = false;
                  self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont','-1');
              end
              if DeBug > 0
                fprintf(2,'DEBUG: SET DataDone = %d\n',self.data_done);
              end
            else
              self.extraMessage = [self.extraMessage , str];
            end
          end
          clear msg;
        catch ERR
          if strcmp(ERR.identifier,'xmlmessenger:datamismatch')
            rethrow(ERR)
          end
          if DeBug, cws.errTrace(ERR); end
          self.disconnect();
          self.Isinitialized = false;
          self.IsCtlInit = false;
          baseME = MException('CANARY:datasource:xml:messageReadFailed','Failed to read messages');
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
        if ~isempty(self.queue),
          message = self.queue(1).m;
          self.queue = self.queue(2:end);
        else
          message = cws.Message('to','CANARY','error','no message found');
        end
      catch ERR
        if strcmp(ERR.identifier,'xmlmessenger:datamismatch')
          rethrow(ERR)
        end
        cws.errTrace(ERR);
        baseME = MException('CANARY:datasource:xml:messageReadFailed','Failed to read messages');
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
      %cws.logger('exit  read');
      % END OF READ -----------------------------------------------------------
    end
    
    function errortext = post( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.IsConnected,
        try
          self.connect();
        catch ERR
          warning('CANARY:datasource:xml:notConnected','Connection to host failed');
          return;
        end
        if ~self.IsConnected,
          warning('CANARY:datasource:xml:notConnected','Connection to host failed');
          return;
        end
      end
      if ~self.Isinitialized,
        self.initialize();
      end
      if ~strcmpi(self.conn_type,'xml') || ~self.IsOutput,
        errortext = 'Wrong type of datasource for a POST command';
        return;
      end
      if self.IsWaiting,
        if ~isempty(self.messageCenter.ToSend.head)
          switch self.messageCenter.ToSend.head.Type,
            case {'DBUPDATE_ACK','DATA_ACK','LIFECHECK_ACK','NACK'}
              errortext = 'Receiving mixed messages';
            otherwise
              errortext = 'Waiting on response from datasource';
              return;
          end
        end
      end
      
      msgID = self.messageCenter.NextTxID;
      [ xmlMessage , isLast ] = self.messageCenter.GetNextMsg();
      if ~isempty(xmlMessage),
        type = xmlMessage.Type ;
        errortext = ['ID=',num2str(msgID),', TYPE=',type];
        if DeBug, cws.trace('POSTING',errortext); end;
        xmlMessage.MsgID = msgID;
        if isLast,
          xmlMessage.ResWait = 0;
        else
          xmlMessage.ResWait = 1;
        end
        if self.dbUpdateDone && strcmp(xmlMessage.Type,'DBUPDATE_ACK')
          self.dbUpdateDone = 2;
        end
        if DeBug,
          fprintf(2,'Transmit:\n');
          fprintf(2,xmlMessage.json);
        end;
        try
          if ~isempty(msgID),
            str = xmlMessage.toString();
            out = java.io.BufferedWriter(java.io.OutputStreamWriter(self.outputStrm));
            for i=1:length(str)
              out.write(str(i));
            end
            out.flush();
            clear out str;
          else
            errortext = 'No data given to post';
          end
        catch ERR
          self.disconnect();
        end
        switch type
          case {'DATA'}
            self.IsWaiting = true;
          otherwise
            self.IsWaiting = false;
        end
        self.messageCenter.PostedMessage( xmlMessage );
        clear xmlMessage;
      end
      % END OF POST -----------------------------------------------------------
    end
    
    function errortext = send( self , message )
      %SENDMESSAGE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      errortext = '';
      DeBug = DEBUG_LEVEL;
      if ~self.IsControl, return; end;
      cws.logger('xmlmsgr send');
      if ~self.Isinitialized,
        warning('CANARY:datasource:xml:messengerNotinitialized',...
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
        error('CANARY:datasource:xml:noMessage','Your message is an invalid Object');
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
      %cws.logger('exit  send');
      % END OF SEND -----------------------------------------------------------
    end
    
    
    % ------ OUTPUT SPECIFIC FUNCTIONS ----------------------------------------
    
    function self = postResult( self , idx , LOC , timestep , CDS )
      cws.logger('xmlmsgr postResult');
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      %TODO: XML postResult information (add to OutputQueue, add Message to
      xMsg = cws.XMLMessage.create_results_xml( idx, LOC );
      if LOC.output_sigs == -1,
        xMsg.Station(1).Points(1).PatText{3} = 'MANSET/BLOCK';
        xMsg.Station(1).Points(1).Quality(3) = 1;
        xMsg.Station(1).Points(1).Pmember(3) = 1;
      elseif LOC.output_sigs == -2,
        xMsg.Station(1).Points(1).PatText{1} = 'OFFLINE';
        xMsg.Station(1).Points(1).Quality(1) = 1;
        xMsg.Station(1).Points(1).Pmember(1) = 1;
        xMsg.Station(1).Points(1).PatText{2} = 'OFFLINE';
        xMsg.Station(1).Points(1).Quality(2) = 1;
        xMsg.Station(1).Points(1).Pmember(2) = 1;
        xMsg.Station(1).Points(1).PatText{3} = 'OFFLINE';
        xMsg.Station(1).Points(1).Quality(3) = 1;
        xMsg.Station(1).Points(1).Pmember(3) = 1;
      end
      self.messageCenter.EnqueueResults( xMsg );
      self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL','subj','POSTMESSAGE','cont','-1');
      %cws.logger('exit  postResult');
      clear xMsg;
      % END OF POSTRESULT -----------------------------------------------------
    end
    
    
    % END OF PUBLIC METHODS ===================================================
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
      %warning('CANARY:input','XML connections in TESTING mode (input)');
      self.RecievedQueue = cws.XMLMessage();
      self.RecievedQueue = self.RecievedQueue(1:0);
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
      %warning('CANARY:DataSource:Output','XML connections in TESTING mode (output)');
      self.SentQueue = cws.XMLMessage();
      self.SentQueue = self.SentQueue(1:0);
      if isempty(self.OutputQueue),
        self.OutputQueue = cws.XMLMessage();
        self.OutputQueue = self.SentQueue(1:0);
      end
      self.IsOutInit = true;
      % END OF INITIALIZEOUTPUT -----------------------------------------------
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
      if ~self.IsControl,
        return
      end
      if ~self.IsConnected,
        self.connect();
        if ~self.IsConnected,
          ME = MException('CANARY:datasource:xml:Control','Failure to connect during initialization');
          throw(ME);
        end
      end
      self.queue(1).m = cws.Message('to','CANARY','from','CONTROL',...
        'subj','WELCOME','cont',datestr(now()));
      if nargin >=2
        for iL = 1:length(locations)
          loc = char(locations{iL});
          self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
            'subj',['START ',loc],'cont','');
        end
      end
      self.queue(end+1).m = cws.Message('to','CANARY','from','CONTROL',...
        'subj','POSTMESSAGE','cont','-1');
      self.SentQueue = cws.XMLMessage();
      self.OutputQueue = self.SentQueue(1:0);
      msg = cws.XMLMessage();
      msg.Type = 'DBUPDATE_REQ';
      msg.MsgID = 0;
      if ~isempty(self.LastDateTimeSeen),
        self.ts_to_backfill = ( now() - datenum(self.LastDateTimeSeen,self.time.date_fmt) ) * self.time.date_mult;
      end
      msg.NumHours = ceil(self.ts_to_backfill * ( 24 / self.time.date_mult ));
      self.ts_to_backfill = 0;
      if self.dbUpdateDone == 0,
        self.messageCenter.ToSend.clear();
        if ~isempty(self.messageCenter.Sent.head),
          msg.NumHours = self.messageCenter.Sent.head.NumHours;
        end
      else
        self.messageCenter.ToSend.clear();
      end
      self.messageCenter.EnqueueReply(msg);
      clear msg;
      self.IsCtlInit = true;
      self.LogFID = fopen([self.log_path,self.conn_id,datestr(now(),'yyyymmddTHHMMSS'),'.msg.log'],'wt');
      fprintf(self.LogFID,'# Messenger startup: %s\n',datestr(now(),30));
      % END OF INITIALIZECONTROL ----------------------------------------------
    end
    
    % END OF PUBLIC METHODS ===============================================
  end
  
  methods ( Access = 'private' ) % +++++++++++++++++++++++++++++++++++++++
    
    function strm = getInputStream( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if strcmpi(self.conn_type,'xml') && ~isempty(self.ConnID),
        strm = self.ConnID.getInputStream();
      else
        strm = [];
      end
      % END OF GETINPUTSTREAM -------------------------------------------------
    end
    
    function strm = getOutputStream( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if strcmpi(self.conn_type,'xml') && ~isempty(self.ConnID),
        strm = self.ConnID.getOutputStream();
      else
        strm = [];
      end
      % END OF GETOUTPUTSTREAM ------------------------------------------------
    end
    
    function self = read_xmldata ( self , varargin )
      EC = cws.ErrorCodes;
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug,
        cws.trace('Reading XML Data','');
      end
      try
        CDS = varargin{1};
        msg = self.messageCenter.ProcessMsg();
        dateIDX = 0;
        if ~isempty(msg),
          for stN = 1:length(msg.Station),
            stID = msg.StationNumbers(stN);
            for ptN = 1:length(msg.Station(stN).Points)
              ptID = msg.Station(stN).Points(ptN).PointNr;
              tag = msg.Station(stN).Points(ptN).TagName;
              qual = msg.Station(stN).Points(ptN).Quality;
              if isempty(qual)
                qual = 0;
              else
                qual = qual(1);
              end
              colIDX = CDS.getSignalID(tag);
              almIDX = CDS.alarm(colIDX);
              nCol = length(colIDX);
              srcTime = msg.Station(stN).Points(ptN).SrcTime;
              if ~isempty(srcTime),
                dateIDX = CDS.time.getDateIdx(srcTime,'dd/mm/yyyy HH:MM:SS');
              end
              CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),1);
              LtoUse = find([CDS.locations(:).stationNum] == stID);
              %if ~isempty(LtoUse),
              CDS.timesteps{dateIDX} = srcTime;
              for LID = 1:length(CDS.locations),
                %%% LID = LtoUse(L);
                CDS.locations(LID).handle.curTSIdx = dateIDX;
              end
              val = msg.Station(stN).Points(ptN).Value;
              if isempty(val),
                val = nan;
                CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),32);
              end
              stat = msg.Station(stN).Points(ptN).Status;
              if ~isempty(stat)
                if stat ~= 0,
                  CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),2);
                  val = nan;
                end
              end
              switch qual
                case {8}
                  if ~isempty(LtoUse),
                    LID = LtoUse(1);
                    if ~isempty(CDS.locations(LID).handle.calib)
                      calIDX = CDS.locations(LID).handle.calib(end);
                      if calIDX > 1,
                        CDS.values(dateIDX,calIDX) = nan;
                        CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),128);
                      end
                    end
                    CDS.locations(LID).handle.algs(end).comments{dateIDX} = ...
                      EC.getQuality(qual);
                  end
                case {1,2} % Find a way to keep track of MANSET and BLOCK
                  val = nan;
                  CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),4);
                  if ~isempty(CDS.locations(LID).handle.calib)
                    calIDX = CDS.locations(LID).handle.calib(end);
                    if calIDX > 1,
                      CDS.values(dateIDX,calIDX) = 2;
                    end
                  end
              end
              %                 if DeBug,
              %                   cws.trace(['At: ',srcTime],['Values for ',tag,' are: TS=',...
              %                     num2str(dateIDX),', SIG=',num2str(colIDX),', VAL=',...
              %                     num2str(val),' ALM=',num2str(qual)]);
              %                 end
              if dateIDX > 0,
                CDS.values(dateIDX,colIDX) = repmat(val,[1 nCol 1]);
                CDS.quality(dateIDX,colIDX) = repmat(qual,[1 nCol 1]);
              end
              %               else
              %                 val = msg.Station(stN).Points(ptN).Value;
              %                 if isempty(val),
              %                   val = nan;
              %                   CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),32);
              %                 end
              %                 stat = msg.Station(stN).Points(ptN).Status;
              %                 if ~isempty(stat)
              %                   if stat ~= 0,
              %                     CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),2);
              %                     val = nan;
              %                   end
              %                 end
              %                 switch qual
              %                   case {1,2} % Find a way to keep track of MANSET and BLOCK
              %                     val = nan;
              %                     CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),4);
              %                 end
              % %                 if DeBug,
              % %                   cws.trace(['At: ',srcTime],['Values for ',tag,' are: TS=',...
              % %                     num2str(dateIDX),', SIG=',num2str(colIDX),', VAL=',...
              % %                     num2str(val),' ALM=',num2str(qual)]);
              % %                 end
              %                 if dateIDX > 0,
              %                   CDS.values(dateIDX,colIDX) = repmat(val,[1 nCol 1]);
              %                   CDS.quality(dateIDX,colIDX) = repmat(qual,[1 nCol 1]);
              %                 end
              %               end
              if DeBug,
                fprintf(2,'.');
              end
            end
            if DeBug,
              fprintf(2,'+');
            end
          end
          if DeBug,
            fprintf(2,'|\n');
          end
          self.messageCenter.WasProcessed(msg);
        end
        idx0 = dateIDX;
        idx1 = dateIDX;
        for k = 1:length(CDS.composite_signal_list)
          kompIdx = CDS.composite_signal_list(k);
          try
            CDS.values(idx0:idx1,kompIdx) = CDS.evalCompositeSignals( kompIdx , idx0 , idx1 );
          catch ERR
            CDS.data_status(dateIDX,colIDX) = bitor(CDS.data_status(dateIDX,colIDX),32768);
            CDS.values(idx0:idx1,kompIdx) = nan;
          end
        end
        clear msg;
      catch XMLErr
        cws.errTrace(XMLErr);
        rethrow(XMLErr);
      end
      % END OF READ_XMLDATA ---------------------------------------------------
    end
    
    
    % END OF PRIVATE METHODS ==================================================
  end
  
  % END OF CLASSDEF DATASOURCE ================================================
end
