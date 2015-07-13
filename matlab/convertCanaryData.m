%GRAPHCANARYDATA Produce PNG output graphs from CANARY outputs
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
%      canary '--graph'  'myFile.mat'  'daily'  'LocA'
%      canary '--graph'
%
function convertCanaryData ( filename )
  if nargin < 1,
    [File,Path] = uigetfile('*.edsd;*.mat','Select the raw data file','MultiSelect','on');
    if ~iscell(File),
      File = {File};
      filename = File{1};
    end
    [p,fname,fext] = fileparts(File{1});
  else
    [Path,fname,fext] = fileparts(filename);
    DD = dir(filename);
    File = {DD.name};
  end
  
  while ~isempty(fext)
    [p,fname,fext] = fileparts(fname);
  end
  
  if length(File) > 1,
    FileList = sort(File);
    CDS = combineEdsdFiles(fullfile(Path,FileList{1}),fullfile(Path,FileList{end}),true);
  elseif length(File) < 1,
    error('CANARY:loaddatafile','No such file: %s',filename);
  else
    [p,fname,fext] = fileparts(filename);
    while ~isempty(fext)
      [p,fname,fext] = fileparts(fname);
    end
    data = load(filename,'-MAT');
    if isfield(data,'CDS'),
      CDS = data.CDS;
    elseif isfield(data,'self'),
      CDS = data.self;
    elseif isfield(data,'V')
      CDS = data.V;
    elseif isfield(data,'SIGNALS')
      CDS = data.SIGNALS;
    else
      error('CANARY:loaddatafile','Unknown data structure in file: %s',filename);
    end
  end
  CDS.saveAs([fullfile(Path,fname),'.'],'csv');
end
