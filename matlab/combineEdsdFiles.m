%
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
%
% Example:
%
function CDS = combineEdsdFiles ( startFile , endFile , noSave )
  if nargin < 3,
    noSave = false;
  end
  if nargin < 1,
    [Path,File] = uigetfile('*.edsd;*.mat','Select the FIRST raw data file to combine');
    startFile = fullfile(File,Path);
  end
  if nargin < 2,
    [Path,File] = uigetfile('*.edsd;*.mat','Select the LAST raw data file to combine');
    endFile = fullfile(File,Path);
  end    
  [ filepath , strfname , ext ] = fileparts(startFile);
  [ filepath , endfname , ext ] = fileparts(endFile);
  filename = fullfile(filepath , [strfname ext ]);
  [ dummy , strfname , stdateend  ] = fileparts(strfname);
  [ dummy , strfname , thru  ] = fileparts(strfname);
  [ dummy , name , startDate  ] = fileparts(strfname);
  [ dummy , endfname , endDate  ] = fileparts(endfname);

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
  
  CDS.loadFiles(startFile,startDate,endDate);
  if ~noSave,
    save(fullfile(filepath,[name,startDate,'.combined',endDate,'.edsd']),'CDS','-MAT','-V7');
  end
  
end
