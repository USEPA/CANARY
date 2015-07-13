classdef XMLMessage < handle
  %XMLMESSAGE Summary of this class goes here
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
  % CANARY is a software package that allows developers to test different
  % algorithms and settings on both off- and on-line water-quality data sets.
  % Data can come from database or text file sources.
  %
  % This software was written as part of an Inter-Agency Agreement between
  % Sandia National Laboratories and the US EPA NHSRC.
  
  
  properties ( Constant = true ,  GetAccess = 'public' )
    FunctionCodes = { 'DBUPDATE_REQ', 'DBUPDATE_ACK', 'DBUPDATE_RESP', ...
      'DBUPDATE_END', 'DATA', 'DATA_ACK', 'LIFECHECK', 'LIFECHECK_ACK', 'NACK', 'N'}
    HeaderTags = { 'MsgID', 'ResWait', 'MsgErrCode', 'NumHours' }
    BodyTags = { 'Station', 'TotalPoint', 'PointNr' , 'PatLibOn'}
    PointTags = { 'TagName', 'SrcTime', 'Value', 'Status', 'Quality', ...
      'Pmember', 'PatText', 'ErrCode' ,'PatLibOn'}
  end
  
  properties ( SetAccess = 'private', GetAccess = 'private' ) % +++++++++++++++
    FunctionCodesStr
    inStream
    builder
  end
  
  properties % PUBLIC PROPERTIES ++++++++++++++++++++++++++++++++++++++++++++++
    ParseErrorCodes = []
    Type = ''
    MsgID = []
    ResWait = []
    MsgErrCode = 0
    NumHours = 0
    StationNumbers = []
    Station = struct('Num',0,'PatLibOn',0,...
      'Points',struct('PointNr',-1,'TagName','','SrcTime','31/12/2000 13:00:00',...
      'Value',nan,'Status',[],'Quality',[],'Cause',[],'Pmember',[],'PatText',{'' '' ''},...
      'ErrCode',[]));
    next = [];
  end
  
  methods % PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    function self = XMLMessage( varargin ) % CONSTRUCTOR ----------------------
      self.clear;
      self.FunctionCodesStr = strvcat(self.FunctionCodes);
      self.inStream = [];
      % END OF CONSTRUCTOR ----------------------------------------------------
    end
    
    function self = clear ( self )
      self.Type = '';
      self.MsgID = [];
      self.ResWait = [];
      self.MsgErrCode = [];
      self.NumHours = [];
      self.StationNumbers = [];
      self.Station(1).PatLibOn = 0;
      self.Station(1).Num = -1;
      self.Station(1).Points = repmat(struct('PointNr',[],'TagName','','SrcTime','',...
        'Value',[],'Status',[],'Quality',[],'Cause',[],'Pmember',[],'PatText',[],...
        'ErrCode',[]),0,0);
      self.Station = self.Station(1:0);
      % END OF CLEAR ----------------------------------------------------------
    end
    %
    %     function self = set.Type( self , value )
    %       if ~ischar(value),
    %         error('CANARY:xmlMessage','You must use a valid string for a message type!');
    %       end
    %       if ~isempty(strmatch(value,self.FunctionCodesStr,'exact'))
    %         self.Type = value;
    %       elseif ~isempty(strmatch(upper(value),self.FunctionCodesStr,'exact'))
    %         warning('CANARY:xmlMessage',...
    %           'You should always capatilze your message type codes: %s',value);
    %         self.Type = value;
    %       else
    %         disp('Valid message types are:')
    %         disp(self.FunctionCodesStr)
    %         error('CANARY:xmlMessage','Invalid message type string: %s',value);
    %       end
    %       % END OF SET.TYPE -------------------------------------------------------
    %     end
    
    function self = parse( self , in , varargin )
      % XMLMESSAGE/PARSE converts an XML message into a structured object
      % Set up initial variables and args[]
      expMsgID = 0;
      expType = '';
      args = varargin;
      while ~isempty(args)
        arg = args{1};
        switch arg
          case {'MsgID'}
            expMsgID = args{2};
            args = args{3:end};
          case {'Type'}
            expType = char(args{2});
            args = args{3:end};
          otherwise
            args = args{2:end};
        end
      end
      % Try building and parsing the XML document structure
      factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
      builder = factory.newDocumentBuilder();
      inStream  = org.xml.sax.InputSource();
      inStream.setCharacterStream( in );
      try
        if ~isempty(self.inStream),
          xmlDoc = builder.parse(self.inStream);
        else
          xmlDoc = builder.parse(inStream);
        end
      catch e
        %warning(e.identifier,e.message);
        if isempty(strfind(e.message,'SAXParseException')),
          self.Type = 'N';
          self.ParseErrorCodes(end+1) = 31;
          rethrow(e);
        else
          self.Type = 'N';
          self.ParseErrorCodes(end+1) = 1;
          self.MsgID = -1;
        end
        return
      end
      xmlHead = xmlDoc.getElementsByTagName('Header').item(0);
      xmlBody = xmlDoc.getElementsByTagName('Body').item(0);
      clear xmlDoc;
      try
        Type = xmlHead.getAttribute('Type');
        self.Type = char(Type);
      catch e
        warning(e.identifier,e.message);
        self.ParseErrorCodes(end+1) = 3;
        clear xmlHead xmlBody;
        return
      end
      if isempty(strmatch(Type,self.FunctionCodes,'exact'))
        self.ParseErrorCodes(end+1) = 2;
        clear xmlHead xmlBody;
        error('CANARY:xmlMessage',...
          'Unknown message recieved of type: %s',Type);
      end
      if ~isempty(expType) && ~strcmp(expType,Type)
        self.ParseErrorCodes(end+1) = 4;
        clear xmlHead xmlBody;
        error('CANARY:xmlMessage',...
          'Unexpected message type: %s, expected: %s',Type,expType);
      end
      % Process the message header
      ch = xmlHead.getFirstChild;
      while ~isempty(ch)
        val = ch.getTextContent;
        nm = ch.getNodeName;
        switch char(nm)
          case {'MsgID'}
            try
              self.MsgID = str2double(val);
            catch
              self.ParseErrorCodes(end+1) = 6;
            end
          case {'ResWait'}
            try
              self.ResWait = str2double(val);
              if isnan(self.ResWait)
                self.ResWait = 0;
              end
            catch
              self.ParseErrorCodes(end+1) = 32;
            end
          case {'MsgErrCode'}
            try
              self.MsgErrCode = str2double(val);
            catch
              self.ParseErrorCodes(end+1) = 10;
            end
          case {'NumHours'}
            self.NumHours = str2double(val);
        end
        ch = ch.getNextSibling;
      end
      if isempty(self.MsgID) || ~isnumeric(self.MsgID)
        self.ParseErrorCodes(end+1) = 5;
      end
      if expMsgID ~= self.MsgID && expMsgID ~= 0,
        self.ParseErrorCodes(end+1) = 8;
      end
      switch self.Type
        case {'DBUPDATE_ACK','DATA_ACK','LIFECHECK_ACK','NACK'}
          if isempty(self.MsgErrCode),
            self.ParseErrorCodes(end+1) = 9;
          end
          if self.MsgErrCode < -2,
            self.ParseErrorCodes(end+1) = 10;
          end
      end
      % Now process the body of the message
      if ~isempty(xmlBody),
        ch = xmlBody.getFirstChild;
        curStationIdx = [];
        curStation = 0;
        totPoint = 0;
        ptNumIdx = 0;
        qualIdx1 = 0;
        qualIdx2 = 0;
        qualIdx3 = 0;
        curSrcTime = '';
        while ~isempty(ch)
          val = ch.getTextContent;
          nm = ch.getNodeName;
          try
            switch char(nm)
              case {'Station'}
                curStation = str2double(val);
                curStationIdx = find(self.StationNumbers == curStation,1);
                if isempty(curStationIdx),
                  self.addStation(curStation);
                  curStationIdx = find(self.StationNumbers == curStation,1);
                end
                if isempty(curStationIdx),
                  error('CANARY:xmlMessage',...
                    'Failed to add station %d to the list of stations!',curStation)
                end
              case {'TotalPoint'}
                totPoint = str2double(val);
                if isnan(totPoint) || isinf(totPoint) || totPoint < 0,
                  self.ParseErrorCodes(end+1) = 14;
                end
                if totPoint == 0,
                  self.Station = [];
                  fprintf(2,'WARNING: XML-SERVER ERROR: NO DATA PROVIDED IN XML MESSAGE FOR STATION %d\n',curStation);
                  break;
                elseif totPoint > 0
                  self.Station(curStationIdx).Points = repmat(struct('PointNr',[],'TagName','','SrcTime','',...
                    'Value',[],'Status',[],'Quality',[],'Cause',[],'Pmember',[],'PatText',{},'ErrCode',[]),totPoint,1);
                end
              case {'PointNr'}
                ptNumIdx = ptNumIdx+1;
                qualIdx1 = 0;
                qualIdx2 = 0;
                qualIdx3 = 0;
                if totPoint <= 0, self.ParseErrorCodes(end+1) = 13; end;
                self.Station(curStationIdx).Points(ptNumIdx).PointNr = str2double(val);
                self.Station(curStationIdx).Points(ptNumIdx).PatText = {' ' ' ' ' '};
                self.Station(curStationIdx).Points(ptNumIdx).Quality = [0 0 0];
                self.Station(curStationIdx).Points(ptNumIdx).Pmember = [0 0 0];
              case {'TagName'}
                self.Station(curStationIdx).Points(ptNumIdx).TagName = char(val);
              case {'SrcTime'}
                curSrcTime = char(val);
                % self.Station(curStationIdx).Points(ptNumIdx).SrcTime = curSrcTime;
              case {'Value'}
                self.Station(curStationIdx).Points(ptNumIdx).SrcTime = curSrcTime;
                self.Station(curStationIdx).Points(ptNumIdx).Value = str2double(val);
              case {'Status'}
                self.Station(curStationIdx).Points(ptNumIdx).Status = str2double(val);
              case {'PatLibOn'}
                self.Station(curStationIdx).PatLibOn = str2double(val);
              case {'Cause'}
                self.Station(curStationIdx).Points(ptNumIdx).Cause = str2double(val);
              case {'Quality'}
                qualIdx1 = qualIdx1+1;
                self.Station(curStationIdx).Points(ptNumIdx).Quality(qualIdx1) = str2double(val);
                if qualIdx1 >= 3
                  qualIdx1 = 0;
                end
              case {'Pmember'}
                qualIdx2 = qualIdx2+1;
                self.Station(curStationIdx).Points(ptNumIdx).Pmember(qualIdx2) = str2double(val);
                if qualIdx2 >= 3
                  qualIdx2 = 0;
                end
              case {'PatText'}
                qualIdx3 = qualIdx3+1;
                self.Station(curStationIdx).Points(ptNumIdx).PatText{qualIdx3} = char(val);
                if qualIdx3 >= 3
                  qualIdx3 = 0;
                end
              case {'ErrCode'}
                self.Station(curStationIdx).Points(ptNumIdx).ErrCode = str2double(val);
            end
            ch = ch.getNextSibling;
          catch e
            switch e.identifier
              case {'MATLAB:badsubscript'}
                if isempty(curStationIdx),
                  self.ParseErrorCodes(end+1) = 11;
                else
                  self.ParseErrorCodes(end+1) = 16;
                end
              otherwise
                cws.errTrace(e)
            end
          end
        end
        if ptNumIdx ~= totPoint, self.ParseErrorCodes(end+1) = 15; end;
      end
      clear builder xmlHead xmlBody ch inStream;
      self.inStream = [];
      self.builder = [];
      % END OF PARSE ----------------------------------------------------------
    end
    
    function self = addError( self , val )
      self.ParseErrorCodes(end+1) = val;
    end
    
    function str = prettyPrint( self )
      str = char(self);
      str = regexprep(str,'><','>\n<');
    end
    
    function str = toString( self )
      str = char(self);
      % END OF TOSTRING -------------------------------------------------------
    end
    
    function str = char( self )
      % CHAR(XMLMESSAGE) produces an XML chunk that encapsulates the data
      % represented in the XMLMessage object. This format is used when sending
      % XML chunks across the network to the server.
      global DEBUG_LEVEL;
      str = '<Message>';
      switch self.Type
        case {'LIFECHECK'}
          str = [str, '<Header Type="LIFECHECK">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '</Header>'];
        case {'LIFECHECK_ACK'}
          str = [str, '<Header Type="LIFECHECK_ACK">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '<MsgErrCode>',num2str(self.MsgErrCode),'</MsgErrCode>'];
          str = [str, '</Header>'];
        case {'NACK','N'}
          if isempty(self.MsgErrCode), MsgErrCode = self.ParseErrorCodes;
          else MsgErrCode = self.MsgErrCode;
          end
          str = [str, '<Header Type="NACK">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '<MsgErrCode>',num2str(MsgErrCode),'</MsgErrCode>'];
          str = [str, '</Header>'];
        case {'DBUPDATE_REQ'}
          str = [str, '<Header Type="DBUPDATE_REQ">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          if DEBUG_LEVEL > 0,
            fprintf(2,'WARNING: SETTING NumHours to 1 for DEBUGGING\n');
            str = [str, '<NumHours>',num2str(1),'</NumHours>'];
          else
            str = [str, '<NumHours>',num2str(self.NumHours),'</NumHours>'];
          end
          str = [str, '</Header>'];
        case {'DBUPDATE_END'}
          str = [str, '<Header Type="DBUPDATE_END">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '</Header>'];
        case {'DBUPDATE_ACK'}
          str = [str, '<Header Type="DBUPDATE_ACK">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '<MsgErrCode>',num2str(self.MsgErrCode),'</MsgErrCode>'];
          str = [str, '</Header>'];
        case {'DBUPDATE_RESP'}
          str = [str, '<Header Type="DBUPDATE_RESP">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '</Header>'];
          if ~isempty(self.Station)
            str = [str, '<Body>'];
            for idx = 1:length(self.Station)
              str = [str, '<Station>',num2str(self.Station(idx).Num),'</Station>']; %#ok<*AGROW>
              str = [str, '<TotalPoint>',num2str(length(self.Station(idx).Points)),'</TotalPoint>'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).PointNr),
                  str = [str, '<PointNr>',num2str(self.Station(idx).Points(i).PointNr),'</PointNr>'];
                  if ~isempty(self.Station(idx).Points(i).SrcTime),
                    str = [str, '<SrcTime>',self.Station(idx).Points(i).SrcTime,'</SrcTime>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).TagName),
                    str = [str, '<TagName>',self.Station(idx).Points(i).TagName,'</TagName>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Value),
                    str = [str, '<Value>',num2str(self.Station(idx).Points(i).Value,'%.5f'),'</Value>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Status),
                    str = [str, '<Status>',num2str(self.Station(idx).Points(i).Status),'</Status>'];
                  end
                  if ~isempty(self.Station(idx).PatLibOn)
                    str = [str, '<PatLibOn>',num2str(self.Station(idx).PatLibOn),'</PatLibOn>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Quality)
                    str = [str, '<Quality>',num2str(self.Station(idx).Points(i).Quality(1),'%d'),'</Quality>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Cause),
                    str = [str, '<Cause>',num2str(self.Station(idx).Points(i).Cause),'</Cause>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).ErrCode),
                    str = [str, '<ErrCode>',num2str(self.Station(idx).Points(i).ErrCode),'</ErrCode>'];
                  end
                end
              end
            end
            str = [str, '</Body>'];
          end
        case {'DATA'}
          str = [str, '<Header Type="DATA">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '</Header>'];
          if ~isempty(self.Station)
            str = [str, '<Body>'];
            for idx = 1:length(self.Station)
              str = [str, '<Station>',num2str(self.Station(idx).Num),'</Station>'];
              str = [str, '<TotalPoint>',num2str(length(self.Station(idx).Points)),'</TotalPoint>'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).PointNr),
                  str = [str, '<PointNr>',num2str(self.Station(idx).Points(i).PointNr),'</PointNr>'];
                  if ~isempty(self.Station(idx).Points(i).SrcTime),
                    str = [str, '<SrcTime>',self.Station(idx).Points(i).SrcTime,'</SrcTime>'];
                  end
                  str = [str, '<TagName>',self.Station(idx).Points(i).TagName,'</TagName>'];
                  if ~isempty(self.Station(idx).Points(i).Value),
                    str = [str, '<Value>',num2str(self.Station(idx).Points(i).Value,'%.5f'),'</Value>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Status),
                    str = [str, '<Status>',num2str(self.Station(idx).Points(i).Status),'</Status>'];
                  end
                  if ~isempty(self.Station(idx).PatLibOn)
                    str = [str, '<PatLibOn>',num2str(self.Station(idx).PatLibOn),'</PatLibOn>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Quality) ...
                      && ~isempty(self.Station(idx).Points(i).Pmember),
                    for j=1:length(self.Station(idx).Points(i).Quality)
                      str = [str, '<Quality>',num2str(self.Station(idx).Points(i).Quality(j),'%.3d'),'</Quality>'];
                      str = [str, '<Pmember>',num2str(self.Station(idx).Points(i).Pmember(j),'%.4f'),'</Pmember>'];
                      if ~isempty(self.Station(idx).Points(i).ErrCode) ...
                          && self.Station(idx).Points(i).ErrCode(1) == 130
                        patText = 'OFFLINE             ';
                      elseif self.Station(idx).Points(i).Quality(j) == 0 ...
                          && self.Station(idx).PatLibOn > 0 ...
                          && self.Station(idx).Points(i).Status == 2,
                        patText = 'NO PATTERN MATCH    ';
                      elseif self.Station(idx).Points(i).Quality(j) == 0
                        patText = '         -          ';
                      else
                        patText = sprintf('%-20s',self.Station(idx).Points(i).PatText{j});
                      end
                      if length(patText)>20,
                        patText = patText(1:20);
                      end
                      str = [str, '<PatText>',patText,'</PatText>'];
                    end
                  end
                  if ~isempty(self.Station(idx).Points(i).Cause),
                    str = [str, '<Cause>',num2str(self.Station(idx).Points(i).Cause),'</Cause>'];
                  end
                  if ~isempty(self.Station(idx).Points(i).ErrCode),
                    str = [str, '<ErrCode>',num2str(self.Station(idx).Points(i).ErrCode),'</ErrCode>'];
                  else
                    str = [str, '<ErrCode>0</ErrCode>'];
                  end
                end
              end
            end
            str = [str, '</Body>'];
          end
        case {'DATA_ACK'}
          str = [str, '<Header Type="DATA_ACK">'];
          str = [str, '<MsgID>',num2str(self.MsgID),'</MsgID>'];
          str = [str, '<ResWait>',num2str(self.ResWait),'</ResWait>'];
          str = [str, '<MsgErrCode>',num2str(self.MsgErrCode(end)),'</MsgErrCode>'];
          str = [str, '</Header>'];
          if ~isempty(self.Station)
            str = [str, '<Body>'];
            for idx = 1:length(self.Station)
              str = [str, '<Station>',num2str(self.Station(idx).Num),'</Station>'];
              str = [str, '<TotalPoint>',num2str(sum(length([self.Station(idx).Points.ErrCode]~=1))),'</TotalPoint>'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).ErrCode),
                  str = [str, '<PointNr>',num2str(self.Station(idx).Points(i).PointNr),'</PointNr>'];
                  str = [str, '<TagName>',self.Station(idx).Points(i).TagName,'</TagName>'];
                  str = [str, '<ErrCode>',num2str(self.Station(idx).Points(i).ErrCode(end)),'</ErrCode>'];
                end
              end
            end
            str = [str, '</Body>'];
          end
        otherwise
          error('CANARY:xmlMessage','Invalid type in XMLMessage: %s',self.Type);
      end
      str = [str, '</Message>'];
      % END OF CHAR -----------------------------------------------------------
    end
    
    function str = json( self )
      % CHAR(XMLMESSAGE) produces an XML chunk that encapsulates the data
      % represented in the XMLMessage object. This format is used when sending
      % XML chunks across the network to the server.
      str = '"message": {\n';
      switch self.Type
        case {'LIFECHECK'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  },\n'];
        case {'LIFECHECK_ACK'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  "MsgErrCode": ',num2str(self.MsgErrCode),',\n'];
          str = [str, '  },\n'];
        case {'NACK','N'}
          if isempty(self.MsgErrCode), MsgErrCode = self.ParseErrorCodes;
          else MsgErrCode = self.MsgErrCode;
          end
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  "MsgErrCode": ',num2str(MsgErrCode),',\n'];
          str = [str, '  },\n'];
        case {'DBUPDATE_REQ'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  "NumHours": ',num2str(self.NumHours),',\n'];
          str = [str, '  },\n'];
        case {'DBUPDATE_END'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  },\n'];
        case {'DBUPDATE_ACK'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  "MsgErrCode": ',num2str(self.MsgErrCode),',\n'];
          str = [str, '  },\n'];
        case {'DBUPDATE_RESP'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  },\n'];
          if ~isempty(self.Station)
            str = [str, ' "Body": [\n'];
            for idx = 1:length(self.Station)
              str = [str, '   { "Station": ',num2str(self.Station(idx).Num),',\n']; %#ok<*AGROW>
              str = [str, '     "TotalPoint": ',num2str(length(self.Station(idx).Points)),',\n'];
              str = [str, '     "_points": [\n'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).PointNr),
                  str = [str, '      {\n'];
                  str = [str, '        "PointNr": ',num2str(self.Station(idx).Points(i).PointNr),',\n'];
                  if ~isempty(self.Station(idx).Points(i).SrcTime),
                    str = [str, '        "SrcTime": "',self.Station(idx).Points(i).SrcTime,'",\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).TagName),
                    str = [str, '        "TagName": "',self.Station(idx).Points(i).TagName,'",\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Value),
                    str = [str, '        "Value": ',num2str(self.Station(idx).Points(i).Value,'%.5f'),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Status),
                    str = [str, '        "Status": ',num2str(self.Station(idx).Points(i).Status),',\n'];
                  end
                  if ~isempty(self.Station(idx).PatLibOn)
                    str = [str, '        "PatLibOn": ',num2str(self.Station(idx).PatLibOn),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Quality)
                    str = [str, '        "Quality": ',num2str(self.Station(idx).Points(i).Quality(1),'%d'),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Cause),
                    str = [str, '        "Cause": ',num2str(self.Station(idx).Points(i).Cause),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).ErrCode),
                    str = [str, '        "ErrCode": ',num2str(self.Station(idx).Points(i).ErrCode),',\n'];
                  end
                  str = [str, '      },\n'];
                end
              end
              str = [str, '    ],\n   },\n'];
            end
            str = [str, '  ],\n'];
          end
        case {'DATA'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  },\n'];
          if ~isempty(self.Station)
            str = [str, ' "Body": [\n'];
            for idx = 1:length(self.Station)
              str = [str, '   { "Station": ',num2str(self.Station(idx).Num),',\n']; %#ok<*AGROW>
              str = [str, '     "TotalPoint": ',num2str(length(self.Station(idx).Points)),',\n'];
              str = [str, '     "_points": [\n'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).PointNr),
                  str = [str, '      {\n'];
                  str = [str, '        "PointNr": ',num2str(self.Station(idx).Points(i).PointNr),',\n'];
                  if ~isempty(self.Station(idx).Points(i).SrcTime),
                    str = [str, '        "SrcTime": "',self.Station(idx).Points(i).SrcTime,'",\n'];
                  end
                  str = [str, '        "TagName": "',self.Station(idx).Points(i).TagName,'",\n'];
                  if ~isempty(self.Station(idx).Points(i).Value),
                    str = [str, '        "Value": ',num2str(self.Station(idx).Points(i).Value,'%.5f'),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Status),
                    str = [str, '        "Status": ',num2str(self.Station(idx).Points(i).Status),',\n'];
                  end
                  if ~isempty(self.Station(idx).PatLibOn)
                    str = [str, '        "PatLibOn": ',num2str(self.Station(idx).PatLibOn),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).Quality) ...
                      && ~isempty(self.Station(idx).Points(i).Pmember),
                    for j=1:length(self.Station(idx).Points(i).Quality)
                      str = [str, '<Quality>',num2str(self.Station(idx).Points(i).Quality(j),'%.3d'),'</Quality>'];
                      str = [str, '<Pmember>',num2str(self.Station(idx).Points(i).Pmember(j),'%.4f'),'</Pmember>'];
                      if ~isempty(self.Station(idx).Points(i).ErrCode) ...
                          && self.Station(idx).Points(i).ErrCode(1) == 130
                        patText = 'OFFLINE             ';
                      elseif self.Station(idx).Points(i).Quality(j) == 0 ...
                          && self.Station(idx).PatLibOn > 0 ...
                          && self.Station(idx).Points(i).Status == 2,
                        patText = 'NO PATTERN MATCH    ';
                      elseif self.Station(idx).Points(i).Quality(j) == 0
                        patText = '         -          ';
                      else
                        patText = sprintf('%-20s',self.Station(idx).Points(i).PatText{j});
                      end
                      if length(patText)>20,
                        patText = patText(1:20);
                      end
                      str = [str, '<PatText>',patText,'</PatText>'];
                    end
                  end
                  if ~isempty(self.Station(idx).Points(i).Cause),
                    str = [str, '        "Cause": ',num2str(self.Station(idx).Points(i).Cause),',\n'];
                  end
                  if ~isempty(self.Station(idx).Points(i).ErrCode),
                    str = [str, '        "ErrCode": ',num2str(self.Station(idx).Points(i).ErrCode),',\n'];
                  else
                    str = [str, '        "ErrCode": 0,\n'];
                  end
                  str = [str, '      },\n'];
                end
              end
              str = [str, '    ],\n   },\n'];
            end
            str = [str, '  ],\n'];
          end
        case {'DATA_ACK'}
          str = [str, ' "Header": {\n  "Type": "',self.Type,'",\n'];
          str = [str, '  "MsgID": ',num2str(self.MsgID),',\n'];
          str = [str, '  "ResWait": ',num2str(self.ResWait),',\n'];
          str = [str, '  "MsgErrCode": ',num2str(self.MsgErrCode),',\n'];
          str = [str, '  },\n'];
          if ~isempty(self.Station)
            str = [str, ' "Body": [\n'];
            for idx = 1:length(self.Station)
              str = [str, '   { "Station": ',num2str(self.Station(idx).Num),',\n']; %#ok<*AGROW>
              str = [str, '     "TotalPoint": ',num2str(length(self.Station(idx).Points)),',\n'];
              str = [str, '     "_points": [\n'];
              for i = 1:length(self.Station(idx).Points)
                if ~isempty(self.Station(idx).Points(i).ErrCode),
                  str = [str, '      {\n'];
                  str = [str, '        "PointNr": ',num2str(self.Station(idx).Points(i).PointNr),',\n'];
                  str = [str, '        "TagName": "',self.Station(idx).Points(i).TagName,'",\n'];
                  str = [str, '        "ErrCode": ',num2str(self.Station(idx).Points(i).ErrCode(end)),',\n'];
                  str = [str, '      },\n'];
                end
              end
              str = [str, '    ],\n   },\n'];
            end
            str = [str, '  ],\n'];
          end
        otherwise
          error('CANARY:xmlMessage','Invalid type in XMLMessage: %s',self.Type);
      end
      str = [str, '}\n'];
    end
    
    
    function self = setInputStream( self , in )
      inStream  = org.xml.sax.InputSource();
      self.inStream = inStream;
      self.inStream.setCharacterStream( in );
      % END OF SETINPUTSTREAM -------------------------------------------------
    end
    
    function self = parseSocket( self , inputStream )
      in = java.io.BufferedReader(java.io.InputStreamReader(inputStream));
      in2 = java.io.StringReader(in.readLine());
      self.parse(in2);
      clear in2 in;
      self.inStream = [];
      self.builder = [];
      % END OF PARSESOCKET ----------------------------------------------------
    end
    
    function self = parseString( self , xmlString )
      %so that parsing the XML doesn't throw an error if it encounters an '&'
      if (~isempty(findstr(xmlString, '&'))) && (isempty(regexp(xmlString, '&^a^m^p^;', 'once')))
        xmlString = regexprep(xmlString, '&', '&amp;');
      end
      in = java.io.StringReader(xmlString);
      self.parse(in);
      clear in;
      self.inStream = [];
      self.builder = [];
      % END OF PARSESTRING ----------------------------------------------------
    end
    
    function self = parseFile( self , filename )
      [path,name,ext] = fileparts(filename);
      if isempty(path), path = pwd; end;
      if path(1) == '.', path = [ pwd , filesep , path ]; end;
      if isempty(ext), ext = '.xml'; end;
      file = [ path filesep name ext ];
      javafile = java.io.File(file);
      in = java.io.FileReader(javafile);
      self.parse(in);
      clear in;
      self.inStream = [];
      self.builder = [];
      % END OF PARSEFILE ------------------------------------------------------
    end
    
    function newXML = getAckMessage( self )
      newXML = cws.XMLMessage();
      newXML.MsgID = self.MsgID;
      switch self.Type
        case {'N'}
          newXML.Type = 'NACK';
        case {'DATA'}
          newXML.Type = 'DATA_ACK';
        case {'DBUPDATE_REQ','DBUPDATE_RESP','DBUPDATE_END'}
          newXML.Type = 'DBUPDATE_ACK';
        case {'LIFECHECK'}
          newXML.Type = 'LIFECHECK_ACK';
        case {'DBUPDATE_ACK','DATA_ACK','LIFECHECK_ACK','NACK'}
          newXML = [];
          return % We don't ACK an ACK
        otherwise
          newXML.Type = 'NACK';
          if isempty(self.Type),
            newXML.MsgErrCode = 2;
          else
            newXML.MsgErrCode = 3;
          end
          return;
      end
      newXML.MsgErrCode = self.ParseErrorCodes;
      if isempty(newXML.MsgErrCode)
        newXML.MsgErrCode = 0;
      end
      % END OF GET ACK MESSAGE ------------------------------------------------
    end
    
    function self = initStation( self , station , numPts )
      self.addStation(station);
      if numPts < 1, return; end
      self.Station(end).Points(numPts) = struct('PointNr',[],'TagName','','SrcTime','',...
        'Value',[],'Status',[],'Quality',[],'Cause',[],'Pmember',[],'PatText',[],'ErrCode',[]);
      self.Station(end).Points(end).PatText = {'' '' ''};
      return
    end
    
    % END OF PUBLIC METHODS ===================================================
  end
  
  methods (Access = 'private') % PRIVATE METHODS ++++++++++++++++++++++++++++++
    
    function self = addStation( self , num )
      if ~isnumeric(num),
        error('CANARY:xmlMessage','You must use a valid station number (integer)');
      end
      idx = self.StationNumbers == num;
      if ~any(idx),
        self.StationNumbers(end+1) = num;
        self.Station(end+1).Num = num;
        self.Station(end).PatLibOn = 0;
      end
      % END OF ADDSTATION -----------------------------------------------------
    end
    
    % END OF PRIVATE METHODS ==================================================
  end
  
  methods (Access = 'public', Static = true )
    function xMsg = create_results_xml( idx , LOC )
      xMsg = cws.XMLMessage();
      xMsg.Type = 'DATA';
      xMsg.initStation(LOC.stationNum,1);
      % Need to get the output tag name somehow, too.
      xMsg.Station(1).Points(1).PointNr = LOC.output_ptnum;
      xMsg.Station(1).Points(1).TagName = LOC.output_tag;
      xMsg.Station(1).Points(1).SrcTime = datestr(now(),'dd/mm/yyyy HH:MM:SS');
      if size(LOC.algs(end).eventprob,1) < idx,
        xMsg.Station(1).Points(1).Value = 0.0;
        xMsg.Station(1).Points(1).ErrCode = 128;
        xMsg.Station(1).Points(1).Status = 0;
        xMsg.Station(1).Points(1).PatText = {'DUPLICATE STN' 'ID IN CONFIG:' LOC.name};
      else
        if LOC.algs(end).eventprob(idx,1,1) > 0.5,
          xMsg.Station(1).Points(1).Value = LOC.algs(end).eventprob(idx,1,1);
        else
          xMsg.Station(1).Points(1).Value = 0.0;
        end
        sIds = find(LOC.algs(end).event_contrib(idx,:,1)~=0);
        nCause = length(sIds);
        switch LOC.algs(end).eventcode(idx,1,1)
          case {1}
            xMsg.Station(1).Points(1).Status = 2;
          case {-1}
            xMsg.Station(1).Points(1).Status = 3;
            xMsg.Station(1).Points(1).ErrCode = 131;
            xMsg.Station(1).Points(1).PatText = {'' '' ''};
          case {3}
            xMsg.Station(1).Points(1).Status = 0;
            xMsg.Station(1).Points(1).ErrCode = 130;
            xMsg.Station(1).Points(1).PatText = {'' '' ''};
          case {-2}
            xMsg.Station(1).Points(1).Status = 0;
            xMsg.Station(1).Points(1).ErrCode = 129;
            xMsg.Station(1).Points(1).PatText = {'' '' ''};
          otherwise % case 0 - non event
            if nCause > 0 && xMsg.Station(1).Points(1).Value >= 0.5; % LOC.p_warn_thresh
              xMsg.Station(1).Points(1).Status = 1;
            else
              xMsg.Station(1).Points(1).Status = 0;
            end
        end
        if nCause > 0
          sIdsPos = ( LOC.algs(end).event_contrib(idx,:,1)> 0 ) + 0;
          sIdsNeg = ( LOC.algs(end).event_contrib(idx,:,1)< 0 ) + 0;
          CPos = ( ones([1,length(LOC.sigvals)]) * 2);
          CNeg = ( ones([1,length(LOC.sigvals)]) * 2);
          sIdsPos2 = sIdsPos .* CPos;
          sIdsNeg2 = sIdsNeg .* CNeg;
          CPos = sIdsPos .* (sIdsPos2 .^ (LOC.sigvals - 1));
          CNeg = sIdsNeg .* (sIdsNeg2 .^ LOC.sigvals);
          xMsg.Station(1).Points(1).Cause = uint16(sum(CPos) + sum(CNeg));
        else
          xMsg.Station(1).Points(1).Cause = 0;
        end
        if ~isempty(LOC.algs(end).library)
          xMsg.Station(1).Points(1).Quality = uint8(LOC.algs(end).cluster_ids(idx,:,1));
          xMsg.Station(1).Points(1).Pmember = double(LOC.algs(end).cluster_probs(idx,:,1));
          for iP = 1:3
            cid = uint8(LOC.algs(end).cluster_ids(idx,iP,1));
            if cid > 0
              xMsg.Station(1).Points(1).PatText{iP} = LOC.algs(end).library.clust.cluster_ids{1}{cid};
            else
              xMsg.Station(1).Points(1).PatText{iP} = '';
            end
          end
          xMsg.Station(1).PatLibOn = 1;
          
        elseif xMsg.Station(1).Points(1).Status >=1,
          xMsg.Station(1).PatLibOn = 0;
          if nCause >= 3,
            xMsg.Station(1).Points(1).Quality = [ (LOC.sigvals(sIds(1))+1)/2 , (LOC.sigvals(sIds(2))+1)/2 , (LOC.sigvals(sIds(3))+1)/2 ];
            xMsg.Station(1).Points(1).Pmember = [ 1.0/nCause , 1.0/nCause , 1.0/nCause ];
            xMsg.Station(1).Points(1).PatText = {LOC.sigids{sIds(1)} LOC.sigids{sIds(2)} LOC.sigids{sIds(3)}};
          elseif nCause == 2
            xMsg.Station(1).Points(1).Quality = [ (LOC.sigvals(sIds(1))+1)/2 , (LOC.sigvals(sIds(2))+1)/2 , 0 ];
            xMsg.Station(1).Points(1).Pmember = [ 0.5 , 0.5 , 0 ];
            xMsg.Station(1).Points(1).PatText = {LOC.sigids{sIds(1)} LOC.sigids{sIds(2)} ''};
          elseif nCause == 1
            xMsg.Station(1).Points(1).Quality = [ (LOC.sigvals(sIds(1))+1)/2 , 0, 0 ];
            xMsg.Station(1).Points(1).Pmember = [ 1.0, 0 , 0 ];
            xMsg.Station(1).Points(1).PatText = {LOC.sigids{sIds(1)} '' ''};
          else
            xMsg.Station(1).Points(1).Quality = [ 0 , 0 , 0 ];
            xMsg.Station(1).Points(1).Pmember = [ 0 , 0 , 0 ];
            xMsg.Station(1).Points(1).PatText = {'' '' ''};
          end
        else
          xMsg.Station(1).PatLibOn = 0;
          xMsg.Station(1).Points(1).Quality = [ 0 , 0 , 0 ];
          xMsg.Station(1).Points(1).Pmember = [ 0 , 0 , 0 ];
          xMsg.Station(1).Points(1).PatText = {'' '' ''};
        end
        if max(LOC.quality) > 0,
          xMsg.Station(1).Points(1).PatText{3} = sprintf('OFFLINE: %s',num2str(LOC.quality));
          xMsg.Station(1).Points(1).Quality(3) = 1;
          xMsg.Station(1).Points(1).Pmember(3) = 1;
        end
      end
    end
  end
  
  % END OF CLASSDEF XMLMESSAGE ================================================
end
