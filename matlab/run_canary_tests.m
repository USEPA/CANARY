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
function run_canary_tests ( testpath , outpath , command )
  if nargin < 3,
    command = '';
  end
  if nargin < 2
    outpath = '.';
  end
  if nargin < 1
    testpath = '.';
  end
  srcDir = cd();
  if ~isdeployed,
    addpath(cd);
    profile on;
  end
  cd(testpath);
  try
    unit.run_unit_tests(outpath);
    functests.run_func_tests(outpath,command);
  catch ERR
    cws.errTrace(ERR);
  end
  if ~isdeployed,
    profile off;
    profInfo = profile('info');
    save(fullfile(cd(),outpath,'canary.mpf'),'-MAT','profInfo');
    mlcovr.coveragerptxml(srcDir,...
      fullfile(testpath,outpath,'coverage.xml'),...
      {'+mlunit','+mlcovr','+unit','+functests','cgui_','canary_gui',...
      'canary_config','dummy','canaryDummy','canaryClient','send_WFR',...
      'testingServer'});
    W = warning('off','all');
    mkdir(fullfile(testpath,outpath,'html'));
    warning(W);
    mlcovr.coveragerpthtml('BaseDir',srcDir,'HtmlDir',fullfile(testpath,outpath,'html'),...
      'OmitList', {'+mlunit','+mlcovr','+unit','+functests','cgui_','canary_gui',...
      'canary_config','dummy','canaryDummy','canaryClient','send_WFR',...
      'testingServer'});
    % profsave(profInfo,fullfile(testpath,outpath,'html'));
  end
end
