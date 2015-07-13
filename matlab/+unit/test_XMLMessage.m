classdef test_XMLMessage < mlunit.test_case
  %TEST_XMLMESSAGE Summary of this class goes here
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

  properties ( SetAccess = 'private' , GetAccess = 'private' ) %+++++++++++++++
    lifecheck = '<Message><Header Type="LIFECHECK"><MsgID>4</MsgID><ResWait>0</ResWait></Header></Message>'
    lifecheck_ack = '<Message><Header Type="LIFECHECK_ACK"><MsgID>4</MsgID><ResWait>0</ResWait><MsgErrCode>0</MsgErrCode></Header></Message>'
    lifecheck_ack_err = '<Message><Header Type="LIFECHECK_ACK"><MsgID>4</MsgID><ResWait>0</ResWait><MsgErrCode>7</MsgErrCode></Header></Message>'
    data = '<Message><Header Type="DATA"><MsgID>2</MsgID></Header><Body><Station>1</Station><TotalPoint>4</TotalPoint><PointNr>1</PointNr><SrcTime>20/08/2008 10:31:24</SrcTime><TagName>RTU1-AIN-Pt1</TagName><Status>0</Status><Value>0.5</Value><ErrCode>0</ErrCode><PointNr>2</PointNr><SrcTime>20/08/2008 10:31:25</SrcTime><TagName>RTU1-AIN-Pt2</TagName><Status>1</Status><Value>0.24</Value><Quality>1</Quality><Pmember>0.1</Pmember><ErrCode>0</ErrCode><PointNr>3</PointNr><SrcTime>20/08/2008 10:31:27</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Status>4</Status><Value>0.31</Value><Cause>3</Cause><ErrCode>0</ErrCode><PointNr>4</PointNr><SrcTime>20/08/2008 10:31:28</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Status>9</Status><ErrCode>128</ErrCode></Body></Message>'
    data_ack = '<Message><Header Type="DATA_ACK"><MsgID>2</MsgID><ResWait>0</ResWait><MsgErrCode>0</MsgErrCode></Header></Message>'
    data_msgerr = '<Message><Header Type="DATA"><MsgID>2</MsgID></Header><Body><Station>1</Station><TotalPoint>3</TotalPoint><PointNr>1</PointNr><SrcTime>20/08/2008 10:31:24</SrcTime><TagName>RTU1-AIN-Pt1</TagName><Status>0</Status><Value>0.5</Value><ErrCode>0</ErrCode><PointNr>2</PointNr><SrcTime>20/08/2008 10:31:25</SrcTime><TagName>RTU1-AIN-Pt2</TagName><Status>1</Status><Value>0.24</Value><Quality>1</Quality><Pmember>0.1</Pmember><ErrCode>0</ErrCode><PointNr>3</PointNr><SrcTime>20/08/2008 10:31:27</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Status>4</Status><Value>0.31</Value><Cause>3</Cause><ErrCode>0</ErrCode><PointNr>4</PointNr><SrcTime>20/08/2008 10:31:28</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Status>9</Status><ErrCode>128</ErrCode></Body></Message>'
    data_ack_msgerr = '<Message><Header Type="DATA_ACK"><MsgID>2</MsgID><ResWait>0</ResWait><MsgErrCode>15</MsgErrCode></Header></Message>'
    data_ack_pterr = '<Message><Header Type="DATA_ACK"><MsgID>3</MsgID><ResWait>0</ResWait><MsgErrCode>-1</MsgErrCode></Header><Body><Station>3</Station><TotalPoint>3</TotalPoint><PointNr>1</PointNr><TagName>RTU3-DIN-Pt1</TagName><ErrCode>17</ErrCode><PointNr>2</PointNr><TagName>RTU3-DIN-Pt2</TagName><ErrCode>19</ErrCode><PointNr>3</PointNr><TagName>RTU4-DIN-Pt1</TagName><ErrCode>22</ErrCode></Body></Message>'
    data_out = '<Message><Header Type="DATA"><MsgID>2</MsgID><ResWait></ResWait></Header><Body><Station>1</Station><TotalPoint>4</TotalPoint><PointNr>1</PointNr><SrcTime>20/08/2008 10:31:24</SrcTime><TagName>RTU1-AIN-Pt1</TagName><Value>0.50000</Value><Status>0</Status><PatLibOn>0</PatLibOn><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><ErrCode>0</ErrCode><PointNr>2</PointNr><SrcTime>20/08/2008 10:31:25</SrcTime><TagName>RTU1-AIN-Pt2</TagName><Value>0.24000</Value><Status>1</Status><PatLibOn>0</PatLibOn><Quality>001</Quality><Pmember>0.1000</Pmember><PatText>                    </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><ErrCode>0</ErrCode><PointNr>3</PointNr><SrcTime>20/08/2008 10:31:27</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Value>0.31000</Value><Status>4</Status><PatLibOn>0</PatLibOn><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Cause>3</Cause><ErrCode>0</ErrCode><PointNr>4</PointNr><SrcTime>20/08/2008 10:31:28</SrcTime><TagName>RTU2-AIN-Pt1</TagName><Status>9</Status><PatLibOn>0</PatLibOn><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><Quality>000</Quality><Pmember>0.0000</Pmember><PatText>         -          </PatText><ErrCode>128</ErrCode></Body></Message>'
    dbupdate_req = '<Message><Header Type="DBUPDATE_REQ"><MsgID>1</MsgID><ResWait>0</ResWait><NumHours>1</NumHours></Header></Message>'
    dbupdate_resp = '<Message><Header Type="DBUPDATE_RESP"><MsgID>5</MsgID></Header><Body><Station>1</Station><TotalPoint>3</TotalPoint><PointNr>1</PointNr><SrcTime>20/12/2005 10:25:00</SrcTime><TagName>RTU1-AIN-Pt1</TagName><Value>50.00</Value><Quality>0</Quality><PointNr>2</PointNr><TagName>RTU1-DIN-Pt1</TagName><Status>1</Status><Quality>0</Quality><PointNr>3</PointNr><TagName>RTU1-DIN-Pt2</TagName><Status>2</Status><Quality>0</Quality></Body></Message>'
    dbupdate_ack = '<Message><Header Type="DBUPDATE_ACK"><MsgID>1</MsgID><ResWait>0</ResWait><MsgErrCode>0</MsgErrCode></Header></Message>'
    dbupdate_ack_err = '<Message><Header Type="DBUPDATE_ACK"><MsgID>1</MsgID><ResWait>0</ResWait><MsgErrCode>12</MsgErrCode></Header></Message>'
    dbupdate_end = '<Message><Header Type="DBUPDATE_END"><MsgID>20</MsgID><ResWait>0</ResWait></Header></Message>'
    malformed_xml = '<Message><Header Type="DBUPDATE_END"></Message>'
    nack = '<Message><Header Type="NACK"><MsgID>-1</MsgID><ResWait></ResWait><MsgErrCode>1</MsgErrCode></Header></Message>';

    message1 = []
  end

  methods %+++++++++++++++++++++++++++++++++++++++++++++++++++++ PUBLIC METHODS

    %= GENERAL SETUP FUNCTIONS ================================================
    function self = test_XMLMessage(varargin) %---------------------CONSTRUCTOR
      self = self@mlunit.test_case(varargin{:});
      self.message1 = cws.XMLMessage();
      self.message1.clear();
    end

    function self = set_up(self) %---------------------------------------SET_UP
      self.message1.clear();
    end

    function self = tear_down(self) %---------------------------------TEAR_DOWN
      %test_XMLMessage.tear_down deletes any objects as needed and does general
      %cleanup that applies to all tests
      %
      % See also: MLUNIT.TEST_CASE
    end

    %= ERROR HANDLING TESTS ===================================================
    function self = test_error_malformed_xml( self )
      self.message1.parseString(self.malformed_xml);
      c = char(self.message1);
      mlunit.assert_equals(self.message1.ParseErrorCodes,1);
      mlunit.assert_equals(self.nack,c);
    end

    %= MESSAGE PARSING TESTS ==================================================
    function self = test_parse_lifecheck( self )
      self.message1.parseString(self.lifecheck);
      c = char(self.message1);
      mlunit.assert_equals(self.lifecheck,c);
    end

    function self = test_parse_lifecheck_ack( self )
      self.message1.parseString(self.lifecheck_ack);
      c = char(self.message1);
      mlunit.assert_equals(self.lifecheck_ack,c);
      mlunit.assert_not_equals(self.lifecheck,c);
    end

    function self = test_parse_lifecheck_ack_err( self )
      self.message1.parseString(self.lifecheck_ack_err);
      c = char(self.message1);
      mlunit.assert_equals(self.lifecheck_ack_err,c);
    end

    function self = test_parse_data( self )
      self.message1.parseString(self.data);
      c = char(self.message1);
      mlunit.assert_equals(1,self.message1.Station(1).Points(1).PointNr);
      mlunit.assert_equals(3,self.message1.Station(1).Points(3).PointNr);
      mlunit.assert_equals(0.24,self.message1.Station(1).Points(2).Value);
      mlunit.assert_equals(4,self.message1.Station(1).Points(3).Status);
      mlunit.assert_equals(3,self.message1.Station(1).Points(3).Cause);
      %       mlunit.assert_equals('20/08/2008 10:31:24',...
      %         self.message1.Station(1).Points(4).SrcTime);
      %       mlunit.assert_equals(self.data_out,c);
    end

    function self = test_parse_data_ack( self )
      self.message1.parseString(self.data_ack);
      c = char(self.message1);
      mlunit.assert_equals(self.data_ack,c);
    end

    function self = test_parse_data_ack_msgerr( self )
      self.message1.parseString(self.data_ack_msgerr);
      c = char(self.message1);
      mlunit.assert_equals(self.data_ack_msgerr,c);
    end

    function self = test_parse_data_ack_pterr( self )
      self.message1.parseString(self.data_ack_pterr);
      c = char(self.message1);
      mlunit.assert_equals(self.data_ack_pterr,c);
    end

    function self = test_parse_dbupdate_req( self )
      self.message1.parseString(self.dbupdate_req);
      c = char(self.message1);
      mlunit.assert_equals(self.dbupdate_req,c);
    end

    function self = test_parse_dbupdate_resp( self )
      self.message1.parseString(self.dbupdate_resp);
      c = char(self.message1);
      mlunit.assert_equals(1,self.message1.Station(1).Points(1).PointNr);
      mlunit.assert_equals(3,self.message1.Station(1).Points(3).PointNr);
      mlunit.assert_equals(2,self.message1.Station(1).Points(3).Status);
      mlunit.assert_equals(50,self.message1.Station(1).Points(1).Value);
      mlunit.assert_equals('',self.message1.Station(1).Points(2).SrcTime);
    end

    function self = test_parse_dbupdate_ack( self )
      self.message1.parseString(self.dbupdate_ack);
      c = char(self.message1);
      mlunit.assert_equals(self.dbupdate_ack,c);
    end

    function self = test_parse_dbupdate_ack_err( self )
      self.message1.parseString(self.dbupdate_ack_err);
      c = char(self.message1);
      mlunit.assert_equals(self.dbupdate_ack_err,c);
    end

    function self = test_parse_dbupdate_end( self )
      self.message1.parseString(self.dbupdate_end);
      c = char(self.message1);
      mlunit.assert_equals(self.dbupdate_end,c);
    end

    %= AUTOPARSING AND ACKNOWLEDGEMENTS =======================================
    function self = test_getAckMessage_data( self )
      self.message1.parseString(self.data);
      ack = self.message1.getAckMessage();
      ack.ResWait = 0;
      c = char(ack);
      mlunit.assert_equals(self.data_ack,c);
    end
    
    function self = test_getAckMessage_lifecheck( self )
      self.message1.parseString(self.lifecheck);
      ack = self.message1.getAckMessage();
      ack.ResWait = 0;
      c = char(ack);
      mlunit.assert_equals(self.lifecheck_ack,c);
    end
    
    function self = test_getAckMessage_data_msgerr( self )
      self.message1.parseString(self.data_msgerr);
      ack = self.message1.getAckMessage();
      ack.ResWait = 0;
      c = char(ack);
      mlunit.assert_not_equals(self.data_ack,c);
      mlunit.assert_equals(self.data_ack_msgerr,c);
    end
    

  end
end
