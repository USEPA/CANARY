classdef MessageCenter < handle
  %MESSAGECENTER definition goes here
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
  properties
    LastTxID = -1;
    LastRxID = -1;
    NextTxID = 0;
    NextRxID = 0;
    ToRead = cws.MessageList();
    ToProcess = cws.MessageList();
    ToSend = cws.MessageList();
    Read = cws.MessageList();
    Processed = cws.MessageList();
    Sent = cws.MessageList();
  end
  
  methods
    function print( self , filename )
      cws.trace('XMLMESSAGE','Writing debug XML file');
      global VERSION;
      FID = fopen(filename,'wt');
      fprintf(FID,'<CanaryDebug version="%s" timestamp="%s">\n',VERSION,datestr(now()));
      fprintf(FID,' <ProcessedMessages>\n');
      fprintf(FID,'  <Received number="%d">\n',self.Read.nMsg);
      next = self.Read.head;
      while ~isempty(next)
        str = next.toString();
        fprintf(FID,'   %s\n',str);
        next = next.next;
      end
      fprintf(FID,'  </Received>\n');
      fprintf(FID,'  <Sent number="%d">\n',self.Sent.nMsg);
      next = self.Sent.head;
      while ~isempty(next)
        str = next.toString();
        fprintf(FID,'   %s\n',str);
        next = next.next;
      end
      fprintf(FID,'  </Sent>\n');
      fprintf(FID,' </ProcessedMessages>\n');
      fprintf(FID,' <QueuedMessages>\n');
      fprintf(FID,'  <Unread number="%d">\n',self.ToRead.nMsg);
      next = self.ToRead.head;
      while ~isempty(next)
        str = next.toString();
        fprintf(FID,'   %s\n',str);
        next = next.next;
      end
      fprintf(FID,'  </Unread>\n');
      fprintf(FID,'  <ToProcess number="%d">\n',self.ToProcess.nMsg);
      next = self.ToProcess.head;
      while ~isempty(next)
        str = next.toString();
        fprintf(FID,'   %s\n',str);
        next = next.next;
      end
      fprintf(FID,'  </ToProcess>\n');
      fprintf(FID,'  <ToSend number="%d">\n',self.ToSend.nMsg);
      next = self.ToSend.head;
      while ~isempty(next)
        str = next.toString();
        fprintf(FID,'   %s\n',str);
        next = next.next;
      end
      fprintf(FID,'  </ToSend>\n');
      fprintf(FID,' </QueuedMessages>\n');
      fprintf(FID,'</CanaryDebug>\n');
      fclose(FID);
    end
    
    function self = MessageCenter( varargin )
      return;
    end
    
    function self = EnqueueResults( self , xmlObj )
      if ~isempty(xmlObj)
        self.ToSend.append(xmlObj);
      end
    end
    
    function self = EnqueueReceived( self , xmlObj )
      if ~isempty(xmlObj)
        self.ToRead.append(xmlObj);
      end
    end
    
    function self = EnqueueReply( self , xmlObj )
      if ~isempty(xmlObj)
        self.ToSend.push(xmlObj);
      end
    end
    
    function msg = ProcessMsg( self )
      msg = self.ToProcess.pop();
    end
    
    function self = WasProcessed( self , xmlObj )
      global DEBUG_LEVEL,
      if DEBUG_LEVEL > 0,
        if ~isempty(xmlObj)
          self.Read.append(xmlObj);
        else
          clear xmlObj;
        end
      end
    end
    
    function [ status , ackMsg ] = ReadReceived( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      msg = self.ToRead.pop();
      if ~isempty(msg),
        if msg.MsgID == self.NextRxID,
          status = 0; % No error in expected error number
          self.LastRxID = msg.MsgID;
          self.NextRxID = mod(msg.MsgID + 1,256);
        elseif self.LastRxID == msg.MsgID
          status = 1;
          ackMsg = [];
          if DeBug,
            cws.trace('CWS:Messenger:RepeatMessage','Dropping repeat message');
          end
          return;
        else
          status = 7; % Wrong Message ID;
          msg.addError(7);
          msg.Type = 'N';
        end
        ackMsg = msg.getAckMessage();
        if isempty(ackMsg),
          if DeBug,
            self.Read.append(msg);
          else
            clear msg;
          end
        else
          switch msg.Type
            case {'DATA','DBUPDATE_RESP'}
              self.ToProcess.append(msg);
            otherwise
              if DeBug,
                self.Read.append(msg);
              else
                clear msg;
              end
          end
        end
      else
        status = 2;
        ackMsg = [];
      end
    end
    
    function [ msg , isLast ] = GetNextMsg(self)
      msg = self.ToSend.pop();
      if self.ToSend.nMsg == 0,
        isLast = true;
      else
        isLast = false;
      end
    end
    
    function self = PostedMessage( self , xmlObj )
      global DEBUG_LEVEL;
      if DEBUG_LEVEL > 0,
        self.Sent.append(xmlObj);
      end
      self.LastTxID = xmlObj.MsgID;
      self.NextTxID = mod(xmlObj.MsgID + 1, 256);
    end
    
  end
  
end
