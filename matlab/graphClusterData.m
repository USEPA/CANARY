%GRAPHCLUSTERDATA Produce PNG output graphs from CANARY outputs
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
% Usage:
%      graphCanaryData( filename , window , location_name )
%   Arguments are optional - dialog will appear if omitted
%
% Example:
%      canary '--plot-patterns'  'myFile.edsc'
%      canary '--plot-patterns'
%
function graphClusterData ( varargin )
  if length(varargin) < 1,
    [File,Path] = uigetfile('*.edsc;*.mat','Select the cluster data file');
    patGrfxDir = Path;
    patListDir = Path;
    patFile= fullfile(Path,File);
  elseif length(varargin) > 2,
    patGrfxDir = varargin{3};
    patListDir = varargin{2};
    patFile = varargin{1};
  elseif length(varargin) > 1;
    patGrfxDir = varargin{2};
    patListDir = varargin{2};
    patFile = varargin{1};
  else
    patGrfxDir = '';
    patListDir = '';
    patFile = varargin{1};
  end
  try
    data = load(patFile,'-MAT');
  catch ERR
    cws.errTrace(ERR);
    return;
  end
  fprintf('%s\n%s\n%s\n',patFile,patListDir,patGrfxDir);
  MyCluster = data.MyCluster;
  if ~isempty(patGrfxDir)
    MyCluster.patGrfxDir = patGrfxDir;
  end
  if ~isempty(patListDir)
    MyCluster.patListDir = patListDir;
  end
  MyCluster.PrintPatternListFile();
  MyCluster.PrintPatternGraphics();
  return;
end
  
