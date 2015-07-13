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
classdef test_Message < mlunit.test_case
  
  properties
    msg1 = []
    msg2 = []
    msg3 = []
    msg4 = []
  end
  
  methods
    function self = test_Message(varargin)
      self = self@mlunit.test_case(varargin{:});
    end
    
    function self = set_up(self)
      import cws.Message;
      
      self.msg1 = Message('to','MLUNIT','from','test','subj','Test Normal','cont','Is Content');
      self.msg2 = Message('to','mlunit','from','test','subj','Test Warn','warn','Is Warning');
      self.msg3 = Message('to','mlunit','from','test','subj','Test Error','error','Is Error');
      self.msg4 = Message('to','MLUNIT','from','test','subj','Test Normal','cont','Is Content','warn','Is Warning');
    end

    function self = tear_down(self)
      self.msg1 = [];
      self.msg2 = [];
      self.msg3 = [];
    end

    function self = test_normal_message_format(self)
      mlunit.assert_equals('Info:  Is Content MLUNIT Test Normal',char(self.msg1));
    end
    
  end

end
