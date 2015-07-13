classdef ErrorCodes
  %ERRORCODES Summary of this class goes here
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
  properties ( SetAccess = 'private' , GetAccess = 'private' )
    codeList = {}
    qualityList = {}
  end
  
  methods
    function self = ErrorCodes( varargin )
      self.codeList(1) = {'XML Error'};
      self.codeList(2) = {'Missing Type'};
      self.codeList(3) = {'Invalid Type'};
      self.codeList(4) = {'Unexpected Type'};
      self.codeList(5) = {'Missing MsgID'};
      self.codeList(6) = {'Invalid MsgID'};
      self.codeList(7) = {'MsgID not incrementing'};
      self.codeList(8) = {'Unmatched MsgID'};
      self.codeList(9) = {'Missing MsgErrCode'};
      self.codeList(10) = {'Invalid error code'};
      self.codeList(11) = {'Missing Station'};
      self.codeList(12) = {'Invalid Station'};
      self.codeList(13) = {'Missing TotalPoint'};
      self.codeList(14) = {'Invalid TotalPoint'};
      self.codeList(15) = {'Incorrect TotalPoint'};
      self.codeList(16) = {'Missing PointNr'};
      self.codeList(17) = {'Invalid PointNr'};
      self.codeList(18) = {'Missing SrcTime'};
      self.codeList(19) = {'Invalid SrcTime'};
      self.codeList(20) = {'Future SrcTime'};
      self.codeList(21) = {'Missing Value'};
      self.codeList(22) = {'Invalid Value'};
      self.codeList(23) = {'Missing Status'};
      self.codeList(24) = {'Invalid Status'};
      self.codeList(25) = {'Missing Quality'};
      self.codeList(26) = {'Invalid Quality'};
      self.codeList(27) = {'Invalid Pmember'};
      self.codeList(28) = {'Invalid Cause'};
      self.codeList(29) = {'Missing ErrCode'};
      self.codeList(30) = {'Invalid ErrCode'};
      self.codeList(31) = {'Unexpected Error'};
      self.codeList(128) = {'No Calculation'};
      self.codeList(129) = {'Insufficient History'};
      self.codeList(130) = {'Sensors Off-Line'};
      self.codeList(131) = {'Baseline Change'};
      self.codeList(132) = {'Pattern Recognition Failed'};
      self.codeList(133) = {'Algorithm Calculation Failed'};
      self.codeList(134) = {'Unknown Error'};
      self.qualityList(1) = {'ManSet'};
      self.qualityList(2) = {'Blocked'};
      self.qualityList(8) = {'Telemetry Fail'};
    end
    
    function str = getCode( self, int )
      if int == 0, str = 'No Error';
      elseif int < 0 || int > length(self.codeList),
        str = 'Unknown Error Code';
      else str = char(self.codeList{int});
      end
    end
    
    function str = getQuality( self, int )
      if int == 0, str = 'Good';
      elseif int < 0 || int > length(self.qualityList),
        str = 'Unknown Quality Code';
      else str = char(self.qualityList{int});
      end
    end    
    
  end
end
