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
function run_unit_tests ( outpath )
  if nargin < 1, outfile = 1; 
  else
    outfile = fullfile(outpath,'TEST_cws.xml');
  end
  runner = mlunit.xml_test_runner(outfile);
  runner.run('unit.test_Algorithms');
  runner.run('unit.test_ClusterLib');
  runner.run('unit.test_DataSource');
  runner.run('unit.test_ErrorCodes');
  runner.run('unit.test_Event');
  runner.run('unit.test_Location');
  runner.run('unit.test_Message');
  runner.run('unit.test_MessageCenter');
  runner.run('unit.test_MessageList');
  runner.run('unit.test_Timing');
  runner.run('unit.test_Signals');
  runner.run('unit.test_XMLMessage');
end
