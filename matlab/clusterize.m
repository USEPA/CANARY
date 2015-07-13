%CLUSTERIZE Create pattern library from CANARY output file
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
%      clusterize( input_mat_file , output_suffix , window_size , p_thresh)
%
% Example:
%      canary '--clusterize' 'myOutput.mat' 'cluster' 400 0.88
%
function clusterize( main_filename , output_filename , window_size , p_thresh , r_order, p_fit)
  if nargin < 2,
    [filename, pathname] = uigetfile('*.mat;*.edsd', 'Pick a CANARY output file');
    if isequal(filename,0) || isequal(pathname,0)
       disp('User pressed cancel')
       return;
    else
       main_filename = fullfile(pathname, filename);
    end
  end
  if nargin < 5,
    prompt={'Please enter the P(event) threshold to use:',...
      'Please enter the cluster window size to use:',...
      'Please enter the regression order to use:',...
      'Please enter the fit level threshold:'};
    name='Clusterization Options';
    defaultanswer={'0.9','90','3','0.5'};
    answer = inputdlg(prompt,name,1,defaultanswer);
    window_size = str2double(answer{2});
    p_thresh = str2double(answer{1});
    r_order = str2double(answer{3});
    p_level = str2double(answer{4});
  end
  data = load(main_filename,'-MAT');
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
  PromptString = {'By default, all signals are included in the clustering. If this is not desired, either because a ';...
    'signal is constant or because it is not relevant to the desired clusters, please select it from the ';...
    'following list. The signals selected below will be EXCLUDED from the clustering algorithm, ';...
    'and you should make the appropriate changes in the configuration file.'};
  OKString = 'Remove Selected';
  CancelString = 'Cancel/Remove None';
  
  for iLoc = 1:length(CDS.locations),
    LOC = CDS.locations(iLoc).handle;
    NAM = CDS.locations(iLoc).name;
    ListString = {CDS.names{CDS.locations(iLoc).handle.sigs}};
    [filename, pathname] = uiputfile('*.edsc', ['Output cluster file for the ' NAM ' station.']);
    if isequal(filename,0) || isequal(pathname,0)
       disp('User pressed cancel')
       return;
    else
       output_filename = fullfile(pathname, filename);
    end
    Name = ['Choose signals to exclude from the ' NAM ' station.'];

    [IDS,OK] = listdlg('Name',Name,'PromptString',PromptString,...
      'OKString',OKString,'CancelString',CancelString,...
      'ListString',ListString,'ListSize',[500 300]);
    if OK ~= 0,
      CDS.locations(iLoc).handle.libsigs(IDS) = 0;
    end
    if isempty(CDS.locations(iLoc).handle.algs(end).library)
      MyCluster = cws.ClusterLib;
      MyCluster.p_thresh = p_thresh;
      MyCluster.n_rpts = window_size;
      MyCluster.r_order = r_order;
      MyCluster.p_level = p_level;
    else
      MyCluster = CDS.locations(iLoc).handle.algs(end).library;
      MyCluster.p_thresh = p_thresh;
      MyCluster.n_rpts = window_size;
      MyCluster.r_order = r_order;
      MyCluster.p_level = p_level;
    end
    MyCluster.clusterize(CDS,LOC,true);
    % MyCluster.clusterize(CDS,LOC,false);
%     OF = [output_filename(1:end-4),'.edsc'];
    save(output_filename,'MyCluster','-MAT');
  end
