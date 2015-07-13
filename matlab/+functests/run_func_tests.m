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
function run_func_tests ( outpath , command )
  FILES = dir('test_*.edsx');
  runner = mlunit.xml_test_runner(fullfile(outpath,'TEST_options.xml'));
  for i = 1:length(FILES)
    [testpath testname ext ver] = fileparts(FILES(i).name);
    testname = testname(6:end);
    testname = strrep(testname,'_','.');
    testclass = ['functests.' testname];
    if ~isempty(command),
      cmdstr = ['!' command ' ' FILES(i).name];
      eval(cmdstr);
    end
    runner.run(testclass);
  end
end