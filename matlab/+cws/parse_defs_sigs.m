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
function SIGS = parse_defs_sigs( src , SIGS )
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL;
  %% Load the Source
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
    xSigList = xml.get_child( xDoc , 'Signals' );
  else
    xDoc = [];
    xSigList = src;
  end;
  xSigs = xml.get_child( xSigList , 'Signal' );
  nSig = length(xSigs);
  for i = 1:nSig
    %% Do the basic configuration
    sigid = xml.get_attribute( xSigs(i) , 'name' );
    scada_tag = xml.get_attribute( xSigs(i) , 'scada-tag' );
    signal_type = xml.get_attribute( xSigs(i) , 'signal-type' );
    parameter_type = xml.get_attribute( xSigs(i) , 'parameter' );
    data_ignore = xml.get_attribute( xSigs(i) , 'ignore-changes' );
    %% Do DataType defaults and settings
    precision = 0.0001;
    units = '';
    data_min = -inf;
    data_max = inf;
    setpt_high = inf;
    setpt_low = -inf;
    xDataType = xml.get_child(xSigs(i), 'DataType');
    if ~isempty(xDataType),
      precision = str2double(xml.get_attribute( xDataType , 'precision' ));
      units = xml.get_attribute( xDataType , 'units' );
      data_min = str2double(xml.get_attribute( xDataType , 'data-min' ));
      data_max = str2double(xml.get_attribute( xDataType , 'data-max' ));
      setpt_high = str2double(xml.get_attribute( xDataType , 'set-point-max' ));
      setpt_low = str2double(xml.get_attribute( xDataType , 'set-point-min' ));
      if isnan(precision), precision = 0.0001; end;
      if isnan(data_min), data_min = -inf; end;
      if isnan(data_max), data_max = inf; end;
      if isnan(setpt_high), setpt_high = inf; end;
      if isnan(setpt_low), setpt_low = -inf; end;
      xDataType = [];
    end
    %% Do AlarmType defaults and settings
    alarm_scope = '';
    bad_value = '';
    normal_value = '';
    lag_steps = '';
    xAlarmType = xml.get_child(xSigs(i), 'AlarmType' );
    if ~isempty(xAlarmType);
      alarm_scope = xml.get_attribute( xAlarmType , 'alarm-scope' );
      bad_value = xml.get_attribute( xAlarmType , 'active' );
      lag_steps = xml.get_attribute( xAlarmType , 'tracking-lag' );
      xAlarmType = [];
    end
    if isempty(lag_steps), 
      lag_steps = 0;
    else
      lag_steps = round(str2double(lag_steps));
    end
    %% Do CompositeType settings and Defaults
    xCompositeType = xml.get_child(xSigs(i), 'CompositeSignal');
    if ~isempty(xCompositeType)
      composite_signal = struct('rp_signal_names',{ {} },'rp_value_cols',{ [] },'rp_row_shift',{ [] },'rp_commands',{ {} },'function',{ {} });
      graph_with = xml.get_attribute(xCompositeType,'graph-with');
      if ~isempty(graph_with),
        try
          graphId = SIGS.getSignalID(graph_with);
        catch ERR
          graphId = -1;
        end
        if graphId > 0,
          composite_signal.function{4} = graphId;
        end
      end
      xEntry = xml.get_child(xCompositeType,'Entry');
      for iE = 1:length(xEntry)
        composite_signal.rp_signal_names{iE} = char(xml.get_attribute(xEntry(iE),'var'));
        composite_signal.rp_value_cols(iE) = 0;
        idxShft = str2double(xml.get_attribute(xEntry(iE),'shift'));
        if isnan(idxShft), idxShft = 0; end;
        composite_signal.rp_row_shift(iE) = idxShft;
        cnst = char(xml.get_attribute(xEntry(iE),'const'));
        if ~isempty(cnst)
          composite_signal.rp_signal_names{iE} = cnst;
          composite_signal.rp_value_cols(iE) = -1;
        end
        cmd = char(xml.get_attribute(xEntry(iE),'cmd'));
        if ~isempty(cmd)
          composite_signal.rp_commands{iE} = cmd;
          composite_signal.rp_value_cols(iE) = -2;
        else
          composite_signal.rp_commands{iE} = '';
        end
      end
    else
      composite_signal = [];
    end
    %% Configure the signal in SIGS
    try
      SIGS.addSignalDef('name',sigid,...
        'scada_id',scada_tag,...
        'signal_type',signal_type,...
        'parameter_type',parameter_type,...
        'precision',precision,...
        'units',units,...
        'data_min',data_min,...
        'data_max',data_max,...
        'alarm_scope',alarm_scope,...
        'alarm_value',bad_value,...
        'normal_value',normal_value,...
        'tracking_lag',lag_steps,...
        'ignore',data_ignore,...
        'setpoint_high',setpt_high,...
        'setpoint_low',setpt_low,...
        'composite_signal',composite_signal);
    catch ERR
      cws.errTrace(ERR);
    end
  end
  xSigList = [];
  xSigs = [];
  xDoc = [];
  
