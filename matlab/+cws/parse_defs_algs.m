%PARSE_DEFS_SIGS configures using the new Signals/Signal XML code
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
function maxWinSize = parse_defs_algs( src , ALGS )
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL;
  % Load the Source
  if ischar(src),
    if DeBug, cws.trace( 'config:load' , src); end;
    try
      xDoc = xml.get_docnode(src);
    catch ERRcfg
      base_ME = MException('CANARY:ConfigErr',...
        'Unable to load configuration file %s', src);
      base_ME = addCause(base_ME, ERRcfg);
      throw(base_ME);
    end
    if DeBug, cws.trace( 'config:load' , 'Success!' ); end;
    xalgList = xml.get_child( xDoc , 'Algorithms' );
  else
    xDoc = [];
    xalgList = src;
  end;
  xalgs = xml.get_child( xalgList , 'Algorithm' );
  nalg = length(xalgs);
  maxWinSize = 0;
  
  % For each algorithm
  for i = 1:nalg
    algid = xml.get_attribute( xalgs(i) , 'name' );
    type  = xml.get_attribute( xalgs(i) , 'type' );
    norm_window = round(str2double(xml.get_attribute( xalgs(i) , 'history-window-TS' )));
    maxWinSize = max([maxWinSize, norm_window]);
    tau_out = xml.get_attribute( xalgs(i) , 'outlier-threshold-SD' );
    tau_outlier = eval(['[',tau_out,']']);
    tau_event   = str2double(xml.get_attribute( xalgs(i) , 'event-threshold-P' ));
    event_timeout = round(str2double(xml.get_attribute( xalgs(i) , 'event-timeout-TS' )));
    xBED = xml.get_child( xalgs(i) , 'BED' );
    if isempty(xBED),
      useBED = false;
      p_outlier = 0.5;
      bed_window = norm_window;
    else
      useBED = true;
      bed_window = round(str2double(xml.get_attribute( xBED , 'bed-window-TS' )));
      p_outlier = str2double(xml.get_attribute( xBED , 'bed-P-outlier' ));
      xBED = [];
    end
    xUseAlgs = xml.get_child( xalgs(i) , 'UseAlgorithm' );
    nAlgIn = length(xUseAlgs);
    algs_in = cell(nAlgIn,1);
    for j = 1:nAlgIn,
      algs_in{j} = xml.get_attribute( xUseAlgs(j) , 'name' );
    end
    xUseAlgs = [];
    xJavaClass = xml.get_child( xalgs(i) , 'ExternalAlgorithm' );
    javaClass = {xml.get_attribute( xJavaClass , 'class' ),[]};
    if ~isempty(javaClass)
      xJavaConfig = xml.get_child( xJavaClass , 'javaConfig' );
      javaClass{2} = xJavaConfig;
    end
    xJavaClass = [];
    xUseClust = xml.get_child( xalgs(i) , 'Clustering' );
    if isempty(xUseClust)
      library = [];
    else
      loadFile = xml.get_attribute(xUseClust , 'load-from-file');
      if ~isempty(loadFile),
        library = loadFile;
      else
        library = struct();
        p_thresh = str2double(char(xml.get_attribute(xUseClust(1) , 'cluster-at-P')));
        if ~isnan(p_thresh), library.p_thresh = p_thresh; end;
        r_order = str2double(char(xml.get_attribute(xUseClust(1) , 'cluster-order-N')));
        if ~isnan(r_order), library.r_order = r_order; end;
        n_rpts = str2double(char(xml.get_attribute(xUseClust(1) , 'cluster-window-size-TS')));
        if ~isnan(n_rpts), library.n_rpts = n_rpts; end;
        p_level = str2double(char(xml.get_attribute(xUseClust(1) , 'cluster-fit-threshold-P')));
        if ~isnan(p_level), library.p_level = p_level; end;
      end
    end
    xUseClust = [];
    try
      ALGS.addAlgorithmDef('short_id',algid,...
        'mfile',type,...
        'type',type,...
        'tau_out',tau_outlier,...
        'n_h',norm_window,...
        'use_bed',useBED,...
        'n_bed',bed_window,...
        'p_out',p_outlier,...
        'tau_evt',tau_event,...
        'n_eto',event_timeout,...
        'algs_in',algs_in,...
        'library',library,...
        'javaClass',javaClass     );
    catch ERR
      cws.errTrace(ERR);
    end
  end
  xalgList = [];
  xalgs = [];
  xDoc = [];
  
