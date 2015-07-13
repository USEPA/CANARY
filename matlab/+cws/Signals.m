classdef Signals < handle
  %SIGNALDATA Contains all raw data for CANARY
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
  % CANARY is a software package that allows developers to test different
  % algorithms and settings on both off- and on-line water-quality data sets.
  % Data can come from database or text file sources.
  %
  % This software was written as part of an Inter-Agency Agreement between
  % Sandia National Laboratories and the US EPA NHSRC.
  %
  %   Because the amount of data used by CANARY can become quite large, this class
  %   has been developed to help limit the amount of data replication needed
  %   throughout CANARY. Specifically, this class can be used to save chunks of
  %   raw data that can then be purged from memory to free up space. These purges
  %   can take place at a regular interval in real-time mode, if so desired.
  %
  %   This data structure keeps all the signal definitions from the configuration
  %   file along with all raw data read in during CANARY operation. It does not
  %   keep any results information - raw data only. Associated results will be
  %   purged at the same times as the raw data, so raw dat and results can be kept
  %   in the same file, even though they will be in separate objects.
  %
  %   The primary functions are listed in the "See also" section.
  %
  % Examples
  %   SD = Signals
  %
  %   SD.addSignalDef('name','MySignal','scada_id','P_0x0831A43F','sigtype','WQ',
  %                   'partype','CL2','precision','0.01')
  %
  %   SD.modSignalDef('MySignal','setpoint_high','3.0','setpoint_low','0.1')
  %
  %   SD.delSignalDef('MySignal')
  %
  % See also addSignalDef, modSignalDef, delSignalDef, addLocationDef,
  %   ModLocationDef, DelLocationDef
  %
  
  properties
    nsigs = 0; % Integer telling the number of signals
    nlocs = 0; % Integer telling the number of locaitons
    names = {}; % Cell array of short names size <n>
    scadatags = {}; % Cell array of SCADA tags size <n>
    timesteps = {}; % Vector of datenums size <t>
    descriptions = {};
    values  % Matrix of values size <n x t>
    quality % Matrix of values size <n x t>
    precision = []; % Vector of precision modifires size <n>
    sigtype = []; % Vector of integer type IDs size <n>
    partype = {};% Cell array of parameter types size <n>
    ignore = []; % Vector of integer ignore values size <n>
    set_pt_lo = []; % Vector of doubles min set points size <n>
    set_pt_hi = []; % Vector of doubles max set points size <n>
    valid_min = []; % Vector of min data value possible size <n>
    valid_max = []; % Vector of max data value possible size <n>
    roc_lim_dec = []; % UNUSED YET
    roc_lim_inc = []; % UNUSED YET
    roc_period = []; % UNUSED YET
    offline_val = [];
    otl_chg_lim = []; % UNUSED YET
    frozen_lim = []; % UNUSED YET
    is_initialized = 0;
    last_new = [];
    units = {}; % Cell array of units <n>
    datacol = []; % Vector of integer signal IDs telling which column to store data in
    alarm = []; % Vector of integer signal IDs associating alarms size <n>
    alarmscope = {}; %
    alarmvalue = {}; %
    alarmnormal = {}; %
    tracking_lag = [];
    time = []; % Class cws.Timing handle
    locations = struct('name','','handle',0,'stationNum',0); % struct(size(L)) with fields name, handle
    algorithms = []; % Class cws.Algorithms handle
    idLookUp = [];
    idStation = [];
    idPointNr = [];
    filepath = '.';
    case_prefix = '';
    configfile = '';
    composite_signal = {};
    composite_signal_list = [];
    combined_filenames = {};
    fn_logfile = '';
    parameters = struct();
    data_status = [];
    prov_type = 'all';
    fromConn = [];
  end
  
  
  
  methods
    
    function list = PrintAsXML( self )
      list = cell(self.nsigs+1,1);
      list(1) = {' <Signals>'};
      for i = 2:self.nsigs
        list(i) = {self.PrintSignalAsXML(i)};
      end
      list(end) = {' </Signals>'};
    end
    
    function str = printAllYAML( self )
      str = sprintf('signals:\n');
      for i = 2:self.nsigs
        str = sprintf('%s%s\n',str,self.printYAML(i));
      end
    end
    
    function str = PrintSignalAsXML( self , sid )
      name = self.names{sid};
      scada_tag = self.scadatags{sid};
      signal_type = cws.Signals.EvalType(self.sigtype(sid));
      paramter_type = self.partype{sid};
      precision = self.precision(sid);
      units = self.units{sid};
      data_min = self.valid_min(sid);
      data_max = self.valid_max(sid);
      alarm_scope = self.alarmscope{sid};
      bad_value = self.alarmvalue{sid};
      composite = self.composite_signal{sid};
      data_ignore = self.ignore(sid);
      if isnan(data_ignore),
        data_ignore = 'all';
      elseif data_ignore == 1,
        data_ignore = 'increases';
      elseif data_ignore == -1,
        data_ignore = 'decreases';
      elseif data_ignore == 2,
        data_ignore = 'both';
      else
        data_ignore = 'none';
      end
      tracking_lag = self.tracking_lag(sid);
      setpt_high = self.set_pt_hi(sid);
      setpt_low = self.set_pt_lo(sid);
      str = sprintf('  <Signal name="%s" scada-tag="%s" signal-type="%s" parameter="%s" ignore-changes="%s" >\n',...
        name,scada_tag,signal_type,paramter_type,data_ignore);
      switch signal_type
        case {'wq','op','info'}
          str = sprintf('%s   <DataType precision="%f" units="%s" data-min="%f" data-max="%f" set-point-min="%f" set-point-max="%f" />\n',...
            str,precision,units,data_min,data_max,setpt_low,setpt_high);
          if tracking_lag > 0,
            str = sprintf('%s   <AlarmType tracking-lag="%d" />\n',...
              str,tracking_lag);
          end
        case {'cal','alm'}
          str = sprintf('%s   <AlarmType alarm-scope="%s" active="%s" tracking-lag="%d" />\n',...
            str,alarm_scope,bad_value,tracking_lag);
      end
      if ~isempty(composite),
        str = sprintf('%s   <CompositeSignal>\n',str);
        n_comp_elem = length(composite.rp_signal_names);
        for kElem = 1:n_comp_elem,
          if isnumeric(composite.rp_signal_names{kElem})
            str = sprintf('%s    <Entry const="%d" />\n',str,composite.rp_signal_names{kElem}(1));
          elseif isempty(composite.rp_signal_names{kElem}),
            str = sprintf('%s    <Entry cmd="%s" />\n',str,composite.rp_commands{kElem});
          elseif composite.rp_row_shift(kElem) > 0,
            str = sprintf('%s    <Entry var="%s" shift="%d" />\n',str,composite.rp_signal_names{kElem},composite.rp_row_shift(kElem));
          else
            str = sprintf('%s    <Entry var="%s" />\n',str,composite.rp_signal_names{kElem});
          end
        end
        str = sprintf('%s   </CompositeSignal>\n',str);
      end
      str = sprintf('%s  </Signal>',str);
    end
    
    function str = printYAML( self , sid )
      name = self.names{sid};
      scada_tag = self.scadatags{sid};
      signal_type = cws.Signals.EvalType(self.sigtype(sid));
      paramter_type = self.partype{sid};
      precision = self.precision(sid);
      units = self.units{sid};
      data_min = self.valid_min(sid);
      data_max = self.valid_max(sid);
      alarm_scope = self.alarmscope{sid};
      bad_value = self.alarmvalue{sid};
      composite = self.composite_signal{sid};
      descr = self.descriptions{sid};
      data_ignore = self.ignore(sid);
      if isnan(data_ignore),
        data_ignore = 'all';
      elseif data_ignore == 1,
        data_ignore = 'increases';
      elseif data_ignore == -1,
        data_ignore = 'decreases';
      elseif data_ignore == 2,
        data_ignore = 'both';
      else
        data_ignore = 'none';
      end
      tracking_lag = self.tracking_lag(sid);
      setpt_high = self.set_pt_hi(sid);
      setpt_low = self.set_pt_lo(sid);
      str = sprintf('- id: %s\n  SCADA tag: %s\n  evaluation type: %s\n  parameter type: %s\n  ignore changes: %s\n',...
        name,scada_tag,signal_type,paramter_type,data_ignore);
      if tracking_lag > 0,
        str = sprintf('%s  tracking lag: %d\n',str,tracking_lag);
      end
      switch signal_type
        case {'wq','op','info'}
          str = sprintf('%s  data options:\n    precision: %s\n    units: ''%s''\n    valid range: [%s, %s]\n    set points: [%s, %s]\n',...
            str,yaml.num2str(precision),units,yaml.num2str(data_min),yaml.num2str(data_max),yaml.num2str(setpt_low),yaml.num2str(setpt_high));
        case {'cal','alm'}
          str = sprintf('%s  alarm options:\n    value when active: %s\n',...
            str,bad_value);
          if ~isempty(alarm_scope),
            str = sprintf('%s    scope: %s\n',str,alarm_scope);
          end
      end
      if ~isempty(descr),
        str = sprintf('%s  description: %s\n',str,char(descr));
      end
      if ~isempty(composite),
        str = sprintf('%s  composite rules: |\n',str);
        n_comp_elem = length(composite.rp_signal_names);
        for kElem = 1:n_comp_elem,
          if isnumeric(composite.rp_signal_names{kElem})
            str = sprintf('%s    (%d)\n',str,composite.rp_signal_names{kElem}(1));
          elseif isempty(composite.rp_signal_names{kElem}),
            str = sprintf('%s    %s\n',str,composite.rp_commands{kElem});
          else
            str = sprintf('%s    @%s[%d]\n',str,composite.rp_signal_names{kElem},composite.rp_row_shift(kElem));
          end
        end
      end
    end
    
    
    function values = evalCompositeSignals( self , kompIdx , idx0 , idx1 )
      cws.logger('enter evalCompositeSignals');
      values = nan(idx1,1);
      origIdx0 = idx0;
      idx0 = max([idx0,self.composite_signal{kompIdx}.function{2}]);
      try
        values(idx0:idx1) = eval(self.composite_signal{kompIdx}.function{1});
      catch ERR %#ok<*NASGU>
        values(idx0:idx1) = nan;
      end
      values = values(origIdx0:idx1);
      if self.sigtype(kompIdx) < 1,
        alarmVal = str2double(self.alarmvalue{kompIdx});
        values(values==alarmVal) = nan;
      end
      cws.logger('exit  evalCompositeSignals');
    end
    
    function setupCompositeSignals( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      for i = 1:length(self.composite_signal);
        if isempty(self.composite_signal{i})
          continue;
        elseif ~isstruct(self.composite_signal{i})
          continue;
        else
          % composite_signal = ...
          %  struct('rp_signal_names',{},'rp_value_cols',[],'rp_row_shift',...
          %  [],'rp_commands',{},'function',{});
          composite = self.composite_signal{i};
          nElem = length(composite.rp_signal_names);
          stack = {};
          prettyStack = {};
          sNum = {};
          maxShift = 0;
          lineNum = 0;
          for k = 1:nElem;
            sigid = composite.rp_value_cols(k);
            shift = composite.rp_row_shift(k);
            lineNum = lineNum + 1;
            if DeBug,
              fprintf(2,'\t%s\t%d: %s\n',self.names{i},lineNum,sigid);
            end
            switch sigid
              case {0} % Index by name
                signm = self.getSignalID(composite.rp_signal_names{k});
                sigid = self.datacol(signm);
                var = sprintf('self.values(idx0-%d:idx1-%d,%d)',shift,shift,sigid);
                maxShift = max([maxShift,shift+1]);
                composite.rp_value_cols(k) = sigid;
                stack{end+1} = var; %#ok<*AGROW>
                sNum{end+1} = lineNum;
                prettyName = composite.rp_signal_names{k};
                prettyVar = sprintf('%.3d:  %s[i-%d]',lineNum,prettyName,shift);
                prettyStack{end+1} = prettyVar;
              case {-1} % Constant expression
                var = composite.rp_signal_names{k};
                composite.rp_signal_names{k} = str2double(var);
                stack{end+1} = var;
                sNum{end+1} = lineNum;
                prettyStack{end+1} = sprintf('%.3d:  %s',lineNum,var);
              case {-2} % Command
                cmd = composite.rp_commands{k};
                switch cmd
                  case {'*'}
                    var = sprintf('times(%s,%s)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d * L%d ',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'+'}
                    var = sprintf('plus(%s,%s)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d + L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'-'}
                    if length(stack) == 1,
                      prettyVar = sprintf('%.3d:  -L%d',lineNum,sNum{end});
                      var = sprintf('uminus(%s)',stack{end});
                      stack = {stack{1:end-1}};
                    else
                      prettyVar = sprintf('%.3d:  L%d - L%d',lineNum,sNum{end-1},sNum{end});
                      var = sprintf('minus(%s,%s)',stack{end-1},stack{end});
                      stack = {stack{1:end-2}};
                    end
                    stack{end+1} = var;
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'/'}
                    var = sprintf('rdivide(%s,%s)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d / L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'<','lt'}
                    var = sprintf('(0+lt(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d < L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'>','gt'}
                    var = sprintf('(0+gt(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d > L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'|','or'}
                    var = sprintf('(0+or(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d | L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'&','and'}
                    var = sprintf('(0+and(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d & L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'<=','le'}
                    var = sprintf('(0+le(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d <= L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'>=','ge'}
                    var = sprintf('(0+ge(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d >= L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'==','eq'}
                    var = sprintf('(0+eq(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d == L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'!=','ne','~=','<>'}
                    var = sprintf('(0+ne(%s,%s))',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d != L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'max'}
                    var = sprintf('max([%s,%s],[],2)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  max(L%d,L%d)',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'min'}
                    var = sprintf('min([%s,%s],[],2)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  min(L%d,L%d)',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'nanmax'}
                    var = sprintf('nanmax([%s,%s],[],2)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  nanmax(L%d,L%d)',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'nanmin'}
                    var = sprintf('nanmin([%s,%s],[],2)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  nanmin(L%d,L%d)',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'ddt','ddx'}
                    var = sprintf('minus(%s,%s)',stack{end},regexprep(regexprep(stack{end},'idx0','idx0-1'),'idx1','idx1-1'));
                    maxShift = maxShift+1;
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  d/dt L%d ',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'**','^','pow'}
                    var = sprintf('power(%s,%s)',stack{end-1},stack{end});
                    stack = {stack{1:end-2}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  L%d^L%d',lineNum,sNum{end-1},sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-2}};
                    sNum{end+1} = lineNum;
                  case {'abs'}
                    var = sprintf('abs(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  abs(L%d)',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'~','not','!'}
                    var = sprintf('not(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  not(L%d)',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'e','exp'}
                    var = sprintf('exp(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  e^L%d',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'sqrt'}
                    var = sprintf('sqrt(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  sqrt(L%d)',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'log','ln'}
                    var = sprintf('log(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  ln(L%d)',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  case {'log10'}
                    var = sprintf('log10(%s)',stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  log10(L%d)',lineNum,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                  otherwise
                    warning('CANARY:CompositeSignal','You have used an unsupported command entry "%s". This is the only warning you will recieve',cmd);
                    var = sprintf('%s(%s)',cmd,stack{end});
                    stack = {stack{1:end-1}};
                    stack{end+1} = var;
                    prettyVar = sprintf('%.3d:  %s(L%d)',lineNum,cmd,sNum{end});
                    prettyStack{end+1} = prettyVar;
                    sNum = {sNum{1:end-1}};
                    sNum{end+1} = lineNum;
                end
              otherwise % Direct sigid already given
                signm = sigid;
                sigid = self.datacol(sigid);
                var = sprintf('self.values(idx0-%d:idx1-%d,%d)',shift,shift,sigid);
                maxShift = max([maxShift,shift+1]);
                stack{end+1} = var;
                sNum{end+1} = lineNum;
                prettyName = self.names{signm};
                prettyVar = sprintf('%.3d:  %s[i-%d]',(prettyName),shift);
                prettyStack{end+1} = prettyVar;
            end
          end
          funcstr = stack{end};
          if DeBug,
            fprintf(2,'\t%s\tFinal: ',self.names{i});
            fprintf(2,'%s\n',funcstr);
          end
          composite.function{1} = funcstr;
          composite.function{2} = maxShift;
          composite.function{3} = prettyStack;
          if length(composite.function)<4,
            composite.function{4} = -1;
          end
          self.composite_signal_list(end+1) = i;
          self.composite_signal{i} = composite;
        end
      end
    end
    
    
    function self = Signals(varargin)
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'java.util.ArrayList'),
          sigs = obj.toArray();
          for i = 1:length(sigs);
            self.configureSignal(sigs(i));
          end
        elseif isa(obj,'java.util.HashMap')
          self.configureSignal(obj);
        elseif isa(obj,'Signals') || isa(obj,'struct')
          FN = fieldnames(obj);
          for iFN = 1:length(FN)
            self.(char(FN(iFN))) = obj.(char(FN(iFN)));
          end
        else
          error('cws:Signals','Unknown construction method: %s',class(obj));
        end
      elseif nargin > 1
        args = varargin;
        while ~isempty(args)
          fld = char(args{1});
          val = char(args{2});
          try
            conn.(fld) = val;
          catch ERR
            disp(ERR.message);
            warning('cws:Signals','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
      self.addSignalDef('name','zeros','scada_id','zeros','signal_type','alm',...
        'parameter_type','alm');
      self.values(1,1) = 0;
      self.is_initialized = false;
    end
    
    function colID = getSignalID(self,tag)
      colID = strmatch(tag,self.names,'exact');
      if isempty(colID),
        colID = strmatch(tag,self.scadatags,'exact');
      end
    end
    
    function self = addLocationDef(self,id,h)
      self.nlocs = self.nlocs + 1;
      self.locations(self.nlocs).name = id;
      self.locations(self.nlocs).handle = h;
      self.locations(self.nlocs).stationNum = h.stationNum;
    end
    
    function [ self ] = modSignalDef( self , name , varargin )
      %MODSIGNALDEF Summary of this function goes here
      %   Detailed explanation goes here
      try
        MyID = strmatch(name,self.names,'exact');
        if isempty(MyID),
          error('cws:Signals','No such signal to modify: %s',name);
        end
        args = varargin;
        while ~isempty(args) && length(args) >= 2
          fld = char(args{1});
          if ~isstruct(args{2})
            val = char(args{2});
          else
            val = args{2};
          end
          switch lower(fld)
            case {'name'}
              self.names{MyID} = val;
            case {'scada_id'}
              self.scadatags{MyID} = val;
            case {'signal_type'}
              self.sigtype(MyID) = cws.Signals.EvalType(val);
            case {'parameter_type'}
              self.partype{MyID} = val;
            case {'precision'}
              self.precision(MyID) = str2double(val);
            case {'data_min'}
              self.valid_min(MyID) = str2double(val);
            case {'data_max'}
              self.valid_max(MyID) = str2double(val);
            case {'setpoint_high'}
              self.set_pt_hi(MyID) = str2double(val);
            case {'setpoint_low'}
              self.set_pt_lo(MyID) = str2double(val);
            case {'units'}
              self.units{MyID} = val;
            case {'alarm_scope'}
              self.alarmscope{MyID} = val;
            case {'alarm_value'}
              self.alarmvalue{MyID} = val;
            case {'normal_value'}
              self.alarmnormal{MyID} = val;
            case {'tracking_lag'}
              self.tracking_lag(MyID) = str2double(val);
            case {'ignore'}
              switch lower(val)
                case{'none'}, self.ignore(MyID) = 0;
                case{'increases'}, self.ignore(MyID) = 1;
                case{'decreases'}, self.ignore(MyID) = -1;
                case{'both'}, self.ignore(MyID) = 2;
                case{'all'}, self.ignore(MyID) = nan;
                otherwise
                  warning('cws:Signals','Unknown ignore type: %s',val);
              end
            case {'tracks_signal'}
              
            case {'column_number'}
              
            case {'input_id'}
              
            case {'duplicate_from'}
              
            case {'composite_signal'}
              self.composite_signal{MyID} = val;
            otherwise
              error('cws:Signals','Unknown signal options: %s',fld);
          end
          args = {args{3:end}};
        end
      catch ERR
        rethrow(ERR)
      end
    end
    
    function saveAs(self, filename, format)
      if nargin < 1,
        filename = '';
        format = '';
      elseif nargin < 2,
        format = '';
      end
      if isempty(filename)
        filename = self.case_prefix;
      end
      if isempty(format)
        format = 'csv';
      end
      % Print the raw data table
      fout = fopen([filename,'raw_data.csv'],'wt');
      fprintf(fout,'TIME_STEP,');
      for i = 1:self.nsigs
        fprintf(fout,'%s,',char(self.names{i}));
      end
      fprintf(fout,'\n');
      if ~iscell(self.timesteps)
        self.timesteps = cellstr(self.timesteps);
      end
      for j = 1:length(self.timesteps)
        fprintf(fout,'"%s",',char(self.timesteps{j}));
        for i = 1:self.nsigs
          fprintf(fout,'%f,',self.values(j,i));
        end
        fprintf(fout,'\n');
      end
      fclose(fout);
      % Print each locaiton
      for i = 1:self.nlocs
        LOC = self.locations(i).handle;
        LOC.createSummaryYAML( self, [filename,LOC.name,'.summary.yml'] , 'a' )
        LOC.saveAs(filename, format, self.timesteps);
      end
    end
    
    function f = plot( self , h , idx , window , name )
      if nargin < 2,
        self.GraphData();
        f = [];
      else
        iLoc = strmatch(name,{self.locations.name},'exact');
        f = h;
        self.GraphData( iLoc , window , '' , '' , 'prb' , h , idx );
      end
    end
    
    function GraphData( self , locs , window , fpath , prefix , prbOrRes , HFIG , XRange )
      %GRAPHDATA Summary of this function goes here
      %   This is used by the graphCanaryData function / --graph functions
      if nargin < 7
        HFIG = [];
        XRange = [];
      end
      if nargin < 6,
        prbOrRes = questdlg('Graph events with residuals or with probability of event?','Result type','Residuals','Probability','Probability');
      end
      if nargin < 2 || isempty(locs),
        AllLocs = {self.locations.name};
        [locs,ok] = listdlg('Name','Graph data','PromptString','Please select one or more locations to plot','ListString',AllLocs);
        if ok==0, return; end;
      end
      nLoc = length(locs);
      if nargin < 3
        S = {'Events Only','All','Quarterly','Monthly','Weekly','Daily'};
        [select,ok] = listdlg('Name','Graph scale','PromptString','Please select a time frame','ListString',S,'SelectionMode','single');
        if ok==0, return; end;
        window = S{select};
        switch lower(window)
          case 'events only'
            for iL = 1:nLoc
              iLoc = locs(iL);
              locData = self.locations(iLoc).handle;
              locData.printEvents();
            end
            return;
          case 'all'
            winlist = {'monthly','weekly','daily'};
          otherwise
            winlist = {window};
        end
      elseif isempty(window),
        S = {'Daily','Hourly','Weekly','Monthly','Quarterly','All','Events Only'};
        [select,ok] = listdlg('Name','Graph scale','PromptString',...
          'Please select a time frame','ListString',S,...
          'SelectionMode','single');
        if ok==0, return; end;
        window = S{select};
        switch lower(window)
          case 'events only'
            for iL = 1:nLoc
              iLoc = locs(iL);
              locData = self.locations(iLoc).handle;
              locData.printEvents();
            end
            return;
          case 'all'
            winlist = {'monthly','weekly','daily'};
          otherwise
            winlist = {window};
        end
      elseif isnumeric(window)
        wLen = window(1);
        winlist = {'entry'};
      else
        winlist = {window};
      end
      if nargin < 4 || isempty(fpath)
        fpath = ['.',filesep];
      end
      if nargin < 5 || isempty(prefix)
        prefix = 'grfx';
      end
      for iWin = 1:length(winlist)
        window = winlist{iWin};
        switch lower(window)
          case 'hourly'
            wLen = 1/3;
            tIntvl = 1/48;
          case 'monthly'
            wLen = 28;
            tIntvl = 2;
          case 'weekly'
            wLen = 7;
            tIntvl = 1;
          case 'daily'
            wLen = 1;
            tIntvl = 1/24;
          case 'quarterly'
            wLen = 92;
            tIntvl = 7;
          case 'entry'
            wLen = wLen * 3/2 / self.time.date_mult;
            tIntvl = wLen / 3;
          otherwise
            wLen = ceil(datenum(self.timesteps{end},self.time.date_fmt)...
              - datenum(self.timesteps{1},self.time.date_fmt));
            tIntvl = 14;
        end
        dIntvl = self.time.date_mult;
        for iL = 1:nLoc
          iLoc = locs(iL);
          X = datenum(self.timesteps,self.time.date_fmt);
          if length(XRange)>1,
            firstPt = XRange(1);
            lastPt = XRange(2);
          elseif ~isempty(XRange)
            firstPt = max([XRange(1)-2*tIntvl*self.time.date_mult+1,1]);
            lastPt = min([XRange(1)+tIntvl*self.time.date_mult,length(self.timesteps)]);
          else
            firstPt = 1;
            lastPt = length(X);
          end
          firstPt = round(firstPt);
          lastPt = round(lastPt);
          t0 = datevec(X(1));
          t1 = datenum(t0(1),0,0,0,0,0);
          t0 = X(1) - t1;% + 1;
          locData = self.locations(iLoc).handle;
          locName = self.locations(iLoc).name;
          nSig = length(locData.sigs);
          nAlg = length(locData.algs);
          II = 0;
          if isempty(HFIG)
            f = figure('PaperPositionMode','manual',...
              'PaperSize',[8.5,1*(nSig+nAlg)],...
              'PaperOrientation','portrait',...
              'PaperUnits','inches',...
              'PaperPosition',[0.0,0.0,8.5,1*(nSig+nAlg)]);
          else
            f = HFIG;
          end
          for i0 = firstPt:round(dIntvl*wLen):lastPt;
            axs = [];
            II = II + 1;
            XLim = [ t0+i0/dIntvl , t0+wLen+i0/dIntvl ];
            i1 = round(min(i0+dIntvl*wLen,lastPt));
            XX = t0+(i0:1:i1)./dIntvl;
            usedSigs = ~isnan(self.ignore(locData.sigs));
            for iSig = 1:nSig
              subplot(nAlg+nSig,1,iSig);
              sigid = locData.sigs(iSig);
              if ~isempty(self.composite_signal{sigid})
                composite = self.composite_signal{sigid};
                if length(composite.function) > 3 && composite.function{4} > 0,
                  sigid = self.composite_signal{sigid}.function{4};
                end
              end
              datid = self.datacol(sigid);
              almid = self.alarm(sigid);
              calid = locData.calib;
              if isempty(calid), calid = 1; end;
              partype = char(self.partype{sigid});
              partype = regexprep(partype,'_',' ');
              scada = char(self.scadatags{sigid});
              scada = regexprep(scada,'_VAL$','');
              scada = regexprep(scada,[locName,'_'],'');
              scada = regexprep(scada,'H2Ox','');
              scada = regexprep(scada,'H2O_','');
              scada = regexprep(scada,[partype,'_'],'','ignorecase');
              scada = regexprep(scada,'[_]',' ');
              units = char(self.units{sigid});
              if ~isempty(units), units = ['(',units,')']; end;
              descr = char(self.descriptions{sigid});
              if ~isempty(descr)
                lbl = {descr;scada;[partype,' ',units]};
              else
                lbl = {scada;[partype,' ',units]};
              end
              Sdata = self.values(:,datid) + self.values(:,almid) .* (1-(isnan(self.values(:,calid(1)))+0));
              SSdata = self.values(:,datid) .* (1-(isnan(self.values(:,calid(1)))+0));
              SSdata(SSdata< self.valid_min(sigid))=nan;
              SSdata(SSdata> self.valid_max(sigid))=nan;
              YMid = nanmedian(SSdata(i0:i1));
              DMax = nanmax(SSdata(i0:i1));
              DMin = nanmin(SSdata(i0:i1));
              DStd = nanstd(SSdata(i0:i1));
              precs = self.precision(sigid);
              if isnan(YMid), YMid = 0; end;
              %               switch lower(partype)
              %                 case {'cl2','ph'}
              %                   YMin = YMid-1;
              %                   YMax = YMid+1;
              %                 case {'turb'}
              %                   YMin = YMid-0.5;
              %                   YMax = YMid+0.5;
              %                 case {'orp','cond'}
              %                   YMin = YMid-150;
              %                   YMax = YMid+150;
              %                 case {'evnt'}
              %                   YMin = 0;
              %                   YMax = 1;
              %                 otherwise
              YMin = nanmin(SSdata)-.001;
              YMax = nanmax(SSdata)+.001;
              %               end
              YMin = nanmax(YMin,DMin)-precs;
              YMax = nanmin(YMax,DMax)+precs;
              if isnan(YMin), YMin = 0; end;
              if isnan(YMax), YMax = YMin + 1; end;
              %           if ~isinf(self.valid_min(sigid)),
              %             YMin = self.valid_min(sigid);
              %           end
              if ~isinf(self.set_pt_lo(sigid)),
                if ~isinf(self.valid_min(sigid)),
                  YMin = max([self.valid_min(sigid),self.set_pt_lo(sigid)]);
                else
                  YMin = self.set_pt_lo(sigid);
                end
              end
              %           if ~isinf(self.valid_max(sigid)),
              %             YMax = self.valid_max(sigid);
              %           end
              if ~isinf(self.set_pt_hi(sigid)),
                if ~isinf(self.valid_max(sigid)),
                  YMax = min([self.valid_max(sigid),self.set_pt_hi(sigid)]);
                else
                  YMax = self.set_pt_hi(sigid);
                end
              end
              if YMin == YMax, YMax = YMax + 0.001; end;
              YLim = [YMin,YMax];
              %             if ~strcmp(partype,'EVNT') && DStd < 2;
              %               Sdata(Sdata==0)=nan;
              %             end
              
              Sdata = Sdata(i0:i1);
              Cdata = self.values(:,sigid) .* isnan(self.values(:,calid(1)));
              Cdata(Cdata==0)=nan;
              Cdata = Cdata(i0:i1);
              Adata = self.values(:,sigid) .* isnan(self.values(:,almid));
              Adata(Adata==0)=nan;
              Adata = Adata(i0:i1);
              HIdata = (Sdata>YMax).*YMax;
              LOdata = (Sdata<YMin).*YMin;
              HIdata(HIdata==0)=nan;
              LOdata(LOdata==0)=nan;
              Sname = self.scadatags{sigid};
              linspec = '-';
              if ~usedSigs(iSig) && self.sigtype(sigid) ~= 2
                fill([0,XX(end)*2,XX(end)*2,0],[YMin-YMin,YMin-YMin,YMax*2,YMax*2],[.9 .9 .9])
                hold on;
              end
              if ~strcmp(partype,'EVNT')
                plot(XX,Sdata,['k',linspec],'DisplayName',Sname);
              else
                plot(XX,Sdata,['k.',linspec],'DisplayName',Sname);
                YLim = [0,1];
              end
              hold on;
              plot(XX,Adata,['y.',linspec],'DisplayName',[Sname,' ALM']);
              plot(XX,Cdata,['g.',linspec],'DisplayName',[Sname,' CAL']);
              if ~strcmp(partype,'EVNT') && self.sigtype(sigid) ~= 2;
                plot(XX,HIdata,'m^');
                plot(XX,LOdata,'mv');
              end
              hold off;
              if ~usedSigs(iSig),
                set(gca,'YLim',YLim,'XTick',(t0+i0/dIntvl:tIntvl:t0+wLen+i0/dIntvl),'XTickLabel',{},'XGrid','on','YGrid','on','FontSize',8,'Color',[.8 .8 .8]);
                ylabel(lbl,'FontSize',8,'Rotation',0.0,'HorizontalAlignment','right','Color',[0 0 0.5]);
              elseif self.sigtype(sigid) == 2
                set(gca,'YLim',YLim,'XTick',(t0+i0/dIntvl:tIntvl:t0+wLen+i0/dIntvl),'XTickLabel',{},'XGrid','on','YGrid','on','FontSize',8);
                ylabel(lbl,'FontSize',8,'Rotation',0.0,'HorizontalAlignment','right','Color',[0 0.5 0]);
              else
                if isnan(YLim(1))
                  YLim(1) = 0;
                end
                if isnan(YLim(2))
                  YLim(2) = YLim(1) + 1;
                end
                if YLim(1)>YLim(2),
                  tmp = YLim(2);
                  YLim(2) = YLim(1);
                  YLim(1) = tmp;
                end;
                if YLim(1) == YLim(2),
                  YLim(2) = YLim(1) + 1;
                  YLim(1) = YLim(1) - 1;
                end
                set(gca,'YLim',YLim,'XTick',(t0+i0/dIntvl:tIntvl:t0+wLen+i0/dIntvl),'XTickLabel',{},'XGrid','on','YGrid','on','FontSize',8);
                ylabel(lbl,'FontSize',8,'Rotation',0.0,'HorizontalAlignment','right');
              end
              axs(iSig) = gca;
            end
            markers = { '.' , '+' , 'x' , 'o' , '.' , '+' , 'x' , 'o' , '.' , '+' , 'x' , 'o' , '.' , '+' , 'x' , 'o' };
            for iAlg = 1:nAlg
              subplot(nAlg+nSig,1,iAlg+nSig);
              try
                  % FIXME: NEED TRY CATCH HERE!!!!!
              catch ERRor
                  disp(HashMap.toString());
                  cws.errTrace(ERR);                  
              end
              Edata = 0+(locData.algs(iAlg).eventcode(i0:i1,1,:)==1);
              Edata(Edata==0) = nan;
              CLdata = locData.algs(iAlg).cluster_ids(i0:i1,1,:);
              lbl = {};
              for iTau = 1:length(locData.algs(iAlg).tau_out)
                lbl{iTau} = ['\tau: ',num2str(locData.algs(iAlg).tau_out(iTau))];
                Edata(:,iTau) = Edata(:,iTau) *0.5 + (iTau - 1)*(0.5/length(locData.algs(iAlg).tau_out));
              end
              
              switch lower(prbOrRes)
                case {'prb','prob','probability'}
                  Pdata = locData.algs(iAlg).eventprob(i0:i1,1,:);
                  PYLim  = [0 1];
                case {'res','resid','residuals'}
                  Pdata = locData.algs(iAlg).residuals(i0:i1,:,:);
                  %PYLim = [0 5];
                  PYLim = [];
              end
              hold on
              ah = area(XX,squeeze(CLdata),'FaceColor','y','EdgeColor','none');
              hAnnotation = get(ah,'Annotation');
              hLegendEntry = get(hAnnotation,'LegendInformation');
              set(hLegendEntry,'IconDisplayStyle','off');
              plot(XX,squeeze(Pdata),'DisplayName',lbl);
              legend(lbl,'FontSize',6,'Location','NorthWest','Orientation','horizontal');
              legend('boxoff');
              plot(XX,squeeze(Edata),markers{iAlg})
              patIDs = find((CLdata-circshift(CLdata,[1 0]))>0);
              if ~isempty(patIDs)
                for iPat = 1:length(patIDs)
                  text(XX(1,patIDs(iPat)),0.25,num2str(CLdata(patIDs(iPat),1,1)));
                end
              end
              hold off;
              if ~isempty(PYLim)
                set(gca,'YLim',PYLim);
              end
              set(gca,'XTick',(t0+i0/dIntvl:tIntvl:t0+wLen+i0/dIntvl),'XTickLabel',{},'XGrid','on','YGrid','on','FontSize',8);
              ylabel({locData.algs(iAlg).type,['n_{\ith}=',num2str(locData.algs(iAlg).n_h)]},'FontSize',12);
              axs(nSig+iAlg) = gca;
              for iSig = 1:nSig
                % Add appropriate dots on other graphs (contributing factors)
                subplot(nAlg+nSig,1,iSig);
                YLim = get(gca,'YLim');
                EdataPrime = Edata .* repmat((abs(double(locData.algs(iAlg).event_contrib(i0:i1,iSig,:)))>0),[1 1 1]);
                EdataPrime = ( EdataPrime .* ( YLim(2) - YLim(1) ) + YLim(1) - (0.1 * ( YLim(2) - YLim(1) ) ) );
                hold on;
                plot(XX,squeeze(EdataPrime),markers{iAlg})
                hold off;
              end
            end
            linkaxes(axs,'x');
            set(axs(1),'XLim',XLim(1:2));
            XTickVals = X(i0):tIntvl:X(i0)+wLen+1/self.time.date_mult ;
            str1 = datestr(X(i0),29);
            str2 = datestr(X(ceil(i1))-1/self.time.date_mult,29);
            tstr1 = datestr(X(i0),31);
            tstr2 = datestr(X(ceil(i1))-1/self.time.date_mult,31);
            ttloc = ['{',locName,'}'];
            ttloc = regexprep(ttloc,'_','}_{');
            ttloc = regexprep(ttloc,' ','} {');
            title(axs(1),[ttloc,' ',tstr1,' to ',tstr2],'FontSize',12);
            gf = fullfile(fpath,[prefix,'.',locName,'.',str1,'.thru.',str2,'.png']);
            if strcmpi(window,'daily')
              gf = fullfile(fpath,[prefix,'.',locName,'.daily.',str1,'.png']);
              %datetick('x','HH:MM','keeplimits','keepticks');
              XTickLabel = datestr(XTickVals,'HH');
            elseif strcmpi(window,'hourly')
              gf = fullfile(fpath,[prefix,'.',locName,'.',str1,'.',datestr(X(i0),'HHMM'),'.png']);
              %datetick('x','dd-mmm HH:MM','keeplimits','keepticks');
              XTickLabel = datestr(XTickVals,'HH:MM');
            elseif strcmpi(window,'entry')
              %datetick('x','dd-mmm HH:MM','keeplimits','keepticks');
              XTickLabel = datestr(XTickVals,'dd-mmm HH:MM');
              XTickLabel2 = {'' '' 'Event To Classify' ''};
              set(axs(end),'XTickLabel',XTickLabel2);
            else
              %datetick('x','dd-mmm','keeplimits','keepticks');
              XTickLabel = datestr(XTickVals,'dd-mmm');
            end
            if length(XTickLabel) < wLen / tIntvl + 1,
              for III = length(XTickLabel)+1:wLen/tIntvl + 1
                XTickLabel(III,1) = ' ';
              end
            end
            for iAxs = 1:length(axs),
              set(axs(iAxs),'XTickLabel',XTickLabel);
            end
            if isempty(HFIG)
              print(f,'-dpng',gf);
              %          print(f,'-dpdf','-append',gf);
              clf(f);
            end
          end
          if isempty(HFIG)
            close(f);
          end
        end
      end
    end
    
    function [ self ] = delSignalDef( self, name )
      %DELSIGNALDEF Summary of this function goes here
      %   Detailed explanation goes here
      try
        MyID = strmatch(name,self.names,'exact');
        if isempty(MyID),
          error('cws:Signals','No such signal to modify: %s',name);
        end
        Range = [ 1:(MyID-1),(MyID+1):self.nsigs];
        flds = fieldnames(self);
        for i = 1:length(flds)
          fld = flds(i);
          switch char(fld)
            case {'names','partype','units','scadatags','alarmscope','alarmvalue','alarmnormal','descriptions'}
              self.(char(fld)) = {self.(char(fld)){Range}};
            case {'locations','nsigs','nlocs'}
            case {'values','quality'}
              self.(char(fld)) = self.(char(fld))(:,Range);
            otherwise
              self.(char(fld)) = self.(char(fld))(Range);
          end
        end
        self.nsigs = self.nsigs - 1;
      catch ERR
        rethrow(ERR)
      end
    end
    
    function MyID = configureSignal(self, HashMap)
      try
        if HashMap.containsKey('id')
          id = HashMap.get('id');
        else
          error('tevaCanary:yamlConfig:missingField',...
            'Error - the following entry was missing the "id" field.\n  %s',...
            char(HashMap.toString()));
        end
        MyID = self.addSignal(id);
        if MyID < 1,
          error('tevaCanary:yamlConfig:missingField',...
            'Error - the following entry has an invalid "id" field: %s\n  %s',...
            id,char(HashMap.toString()));
        end
        keys = HashMap.keySet().toArray();
        for i = 1:length(keys)
          key = char(keys(i));
          val = HashMap.get(key);
          switch key
            case 'id'
              self.names{MyID} = char(val);
            case {'SCADATag','scada tag','SCADA tag'}
              if ~isempty(strmatch(val,self.scadatags,'exact'))
                did = strmatch(val,self.scadatags,'exact');
                self.datacol(MyID) = did(1);
              end
              self.scadatags{MyID} = char(val);
            case {'type','evaluation type'}
              switch lower(char(val))
                case {'wq','water quality','quality'}, self.sigtype(MyID) = 1;
                case {'op','operations','supplemental'}, self.sigtype(MyID) = 2;
                case {'alm','alarm','hardware alarm'}, self.sigtype(MyID) = -1;
                case {'cal','calibration'}, self.sigtype(MyID) = 0;
                case {'info','information'}, self.sigtype(MyID) = nan;
                otherwise
                  warning('tevaCanary:yamlConfig:invalidValue',...
                    'Unknown value for signal:%s::type: %s',...
                    id,char(val));
              end
            case {'parameter','parameter type'}
              self.partype{MyID} = char(val);
            case {'ignore','ignoreChanges','ignore changes'}
              switch lower(val)
                case{'none'}, self.ignore(MyID) = 0;
                case{'increases'}, self.ignore(MyID) = 1;
                case{'decreases'}, self.ignore(MyID) = -1;
                case{'both'}, self.ignore(MyID) = 2;
                case{'all'}, self.ignore(MyID) = nan;
                otherwise
                  warning('tevaCanary:yamlConfig:invalidValue',...
                    'Unknown value for signal:%s::ignoreChanges: %s',...
                    id,char(val));
              end
            case {'trackingLag','tracking lag'}
              self.tracking_lag{MyID} = val;
            case {'description'}
              self.descriptions{MyID} = char(val);
            case {'dataType','data options'}
              sKeyList = cell(val.keySet().toArray());
              for iSub = 1:length(sKeyList)
                sKey = sKeyList{iSub};
                switch sKey
                  case {'precision'}
                    self.precision(MyID) = val.get(sKey);
                    self.otl_chg_lim(MyID) = val.get(sKey);
                  case {'RoC limit decreasing'}
                    self.roc_lim_dec(MyID) = val.get(sKey);
                  case {'RoC limit increasing'}
                    self.roc_lim_inc(MyID) = val.get(sKey);
                  case {'RoC period'}
                    self.roc_period(MyID) = val.get(sKey);
                  case {'value when offline'}
                    self.offline_val(MyID) = val.get(sKey);
                  case {'frozen value limit'}
                    self.frozen_lim(MyID) = val.get(sKey);
                  case {'units'}
                    self.units{MyID} = char(val.get(sKey));
                  case {'validRange','valid range'}
                    range = val.get(sKey).toArray();
                    if length(range) ~= 2,
                      warning('tevaCanary:yamlConfig:invalidValue',...
                        'Unknown key/value for signal:%s::dataType:validRange: %s',...
                        id,char(val.get(sKey).toString()));
                    else
                      self.valid_min(MyID) = range(1);
                      self.valid_max(MyID) = range(2);
                    end
                  case {'setPoints','set points','set-points'}
                    range = val.get(sKey).toArray();
                    if length(range) ~= 2,
                      warning('tevaCanary:yamlConfig:invalidValue',...
                        'Unknown key/value for signal:%s::dataType:validRange: %s',...
                        id,char(val.get(sKey).toString()));
                    else
                      self.set_pt_lo(MyID) = range(1);
                      self.set_pt_hi(MyID) = range(2);
                    end
                  otherwise
                    warning('tevaCanary:yamlConfig:invalidField',...
                      'Unknown key for signal[%s] => %s => %s',...
                      id,key,sKey);
                end
              end
            case {'alarmType','alarm options'}
              sKeyList = cell(val.keySet().toArray());
              for iSub = 1:length(sKeyList)
                sKey = sKeyList{iSub};
                switch sKey
                  case {'scope'}
                    self.alarmscope{MyID} = char(val.get(sKey));
                    SrcID = strmatch(val,self.scadatags,'exact');
                    if ~isempty(SrcID),
                      self.alarm(SrcID) = MyID;
                    end
                  case {'value when active','valueWhenActive'}
                    vwa = val.get(sKey);
                    self.alarmvalue{MyID} = num2str(vwa);
                  otherwise
                    warning('tevaCanary:yamlConfig:invalidField',...
                      'Unknown key for signal[%s] => %s => %s',...
                      id,key,sKey);
                end
              end
            case {'compositeType','composite rules','composite operations'}
              composite_string = val;
              composite_list = textscan(composite_string,'%s');
              composite_list = composite_list{1};
              composite_signal = struct('rp_signal_names',{ {} },'rp_value_cols',{ [] },'rp_row_shift',{ [] },'rp_commands',{ {} },'function',{ {} });
              for iE = 1:length(composite_list)
                val = composite_list{iE};
                if isempty(val), break; end;
                composite_signal.rp_signal_names{iE} = '';
                composite_signal.rp_value_cols(iE) = 0;
                composite_signal.rp_row_shift(iE) = 0;
                composite_signal.rp_commands{iE} = '';
                switch val(1)
                  case '@'
                    val2 = regexprep(val,'@|\[|\]',' ');
                    val3 = textscan(val2,'%s %d');
                    sig_name = char(val3{1});
                    sig_shift = val3{2};
                    if isempty(sig_shift) || isnan(sig_shift),
                      sig_shift = 0;
                    end;
                    composite_signal.rp_signal_names{iE} = sig_name;
                    composite_signal.rp_row_shift(iE) = sig_shift;
                  case '('
                    val2 = regexprep(val,'\(|\)','');
                    composite_signal.rp_signal_names{iE} = val2;
                    composite_signal.rp_value_cols(iE) = -1;
                  otherwise
                    composite_signal.rp_commands{iE} = val;
                    composite_signal.rp_value_cols(iE) = -2;
                end
              end
              self.composite_signal{MyID} = composite_signal;
            otherwise
              warning('tevaCanary:yamlConfig:invalidField',...
                'Unknown key/value for signal[%s] => %s',...
                id,key);
          end
        end
      catch ERR
        disp(HashMap.toString());
        cws.errTrace(ERR);
        rethrow(ERR)
      end
    end
    
    function MyID = addSignal(self,id)
      if ~isempty(strmatch(id,self.names,'exact')) && isempty(strmatch(id,'zeros','exact'))
        MyID = strmatch(id,self.names,'exact');
      elseif ~isempty(strmatch(id,'zeros','exact'))
        MyID = -1;
      else
        MyID = self.nsigs + 1;
        self.nsigs = self.nsigs + 1;
        self.names{MyID} = id;
        self.descriptions{MyID} = [];
        self.scadatags{MyID} = '';
        self.values(:,MyID) = nan;
        self.quality(:,MyID) = 0;
        self.precision(MyID) = 1e-4;
        self.sigtype(MyID) = nan;
        self.partype{MyID} = '';
        self.ignore(MyID) = 0;
        self.tracking_lag(MyID) = 0;
        self.set_pt_lo(MyID) = -inf;
        self.set_pt_hi(MyID) = inf;
        self.valid_min(MyID) = -inf;
        self.valid_max(MyID) = inf;
        self.roc_lim_dec(MyID) = -inf;
        self.roc_lim_inc(MyID) = inf;
        self.roc_period(MyID) = 10;
        self.offline_val(MyID) = nan;
        self.otl_chg_lim(MyID) = 1e-2;
        self.frozen_lim(MyID) = inf;
        self.last_new(MyID) = 0;
        self.units{MyID} = '';
        self.alarm(MyID) = 1;
        self.datacol(MyID) = MyID;
        self.alarmscope{MyID} = '';
        self.alarmnormal{MyID} = '';
        self.alarmvalue{MyID} = '';
        self.fromConn(MyID) = 0;
        self.composite_signal{MyID} = [];
      end
    end
    
    function MyID = addSignalDef(self,varargin)
      %ADDSIGNALDEF inserts a signal into the Signals class
      %
      % Example
      %   SD.addSignalDef('name','MySIG_1','SCADA_ID','0x9384',...)
      %
      % See also modSignalDef, delSignalDef, Signals
      %
      % Copyright 2008 Sandia Corporation
      try
        MyID = self.nsigs + 1;
        self.nsigs = self.nsigs + 1;
        self.names{MyID} = '';
        self.scadatags{MyID} = '';
        self.descriptions{MyID} = [];
        self.values(:,MyID) = nan;
        self.quality(:,MyID) = 0;
        self.precision(MyID) = 1e-4;
        self.sigtype(MyID) = nan;
        self.partype{MyID} = '';
        self.ignore(MyID) = 0;
        self.tracking_lag(MyID) = 0;
        self.set_pt_lo(MyID) = -inf;
        self.set_pt_hi(MyID) = inf;
        self.valid_min(MyID) = -inf;
        self.valid_max(MyID) = inf;
        self.roc_lim_dec(MyID) = -inf;
        self.roc_lim_inc(MyID) = inf;
        self.roc_period(MyID) = 10;
        self.offline_val(MyID) = nan;
        self.otl_chg_lim(MyID) = 1e-2;
        self.frozen_lim(MyID) = inf;
        self.last_new(MyID) = 0;
        self.units{MyID} = '';
        self.alarm(MyID) = 1;
        self.datacol(MyID) = MyID;
        self.alarmscope{MyID} = '';
        self.alarmnormal{MyID} = '0';
        self.alarmvalue{MyID} = '1';
        self.composite_signal{MyID} = [];
        args = varargin;
        while ~isempty(args) && length(args) >= 2
          fld = char(args{1});
          val = args{2};
          switch lower(fld)
            case {'name'}
              if ~isempty(strmatch(val,self.names,'exact')) && isempty(strmatch(val,'zeros','exact'))
                %error('cws:Signals',...
                %'Signal "%s" already definied. use "modSignalDef(''%s'',...)" to modify.',...
                %char(val),char(val));
                self.modSignalDef(varargin{:});
                return;
              end
              self.names{MyID} = char(val);
            case {'scada_id'}
              if ~isempty(strmatch(val,self.scadatags,'exact'))
                did = strmatch(val,self.scadatags,'exact');
                self.datacol(MyID) = did(1);
              end
              self.scadatags{MyID} = char(val);
            case {'signal_type'}
              self.sigtype(MyID) = cws.Signals.EvalType(char(val));
            case {'parameter_type'}
              self.partype{MyID} = char(val);
            case {'tracking_lag'}
              self.tracking_lag(MyID) = val;
            case {'precision'}
              self.precision(MyID) = val;
            case {'data_min'}
              self.valid_min(MyID) = val;
            case {'data_max'}
              self.valid_max(MyID) = val;
            case {'setpoint_high'}
              self.set_pt_hi(MyID) = val;
            case {'setpoint_low'}
              self.set_pt_lo(MyID) = val;
            case {'units'}
              self.units{MyID} = char(val);
            case {'description'}
              self.descriptions{MyID} = char(val);
            case {'alarm_scope'}
              self.alarmscope{MyID} = char(val);
              SrcID = strmatch(val,self.scadatags,'exact');
              if ~isempty(SrcID),
                self.alarm(SrcID) = MyID;
              end
            case {'alarm_value'}
              self.alarmvalue{MyID} = char(val);
            case {'normal_value'}
              self.alarmnormal{MyID} = char(val);
            case {'ignore'}
              switch lower(char(val))
                case{'none'}, self.ignore(MyID) = 0;
                case{'increases'}, self.ignore(MyID) = 1;
                case{'decreases'}, self.ignore(MyID) = -1;
                case{'both'}, self.ignore(MyID) = 2;
                case{'all'}, self.ignore(MyID) = nan;
                otherwise
                  warning('cws:Signals','Unknown ignore type: %s',char(val));
              end
            case {'tracks_signal'}
              
            case {'column_number'}
              
            case {'input_id'}
              
            case {'duplicate_from'}
              
            case {'composite_signal'}
              self.composite_signal{MyID} = val;
            otherwise
              error('cws:Signals','Unknown signal options: %s',fld);
          end
          args = {args{3:end}};
        end
      catch ERRSD
        self.nsigs = self.nsigs - 1;
        flds = fieldnames(self);
        for i = 1:length(flds)
          fld = flds(i);
          switch char(fld)
            case {'names','partype','units','scadatags','alarmscope','alarmvalue','alarmnormal'}
              if size(self.(char(fld)),2) > self.nsigs,
                self.(char(fld)) = {self.(char(fld)){1:self.nsigs}};
              end
            case {'locations','nsigs','nlocs'}
            case {'values','quality'}
              if size(self.(char(fld)),2) > self.nsigs,
                self.(char(fld)) = self.(char(fld))(:,1:self.nsigs);
              end
            otherwise
              if size(self.(char(fld)),2) > self.nsigs,
                self.(char(fld)) = self.(char(fld))(1:self.nsigs);
              end
          end
        end
        rethrow(ERRSD);
      end
    end
    
    function self = evalCompSigsAtIdx( self , idx )
      cws.logger('enter evalCompSigsAtIdx');
      for k = 1:length(self.composite_signal_list)
        kompIdx = self.composite_signal_list(k);
        try
          self.values(idx,kompIdx) = eval(self.composite_signal{kompIdx}.function{1});
          % self.values(idx,kompIdx) = self.composite_signal{kompIdx}.function{2}(idx);
          % self.values(idx,kompIdx) = self.compositeSignalValue(kompIdx,idx);
          if self.sigtype(kompIdx) < 1,
            if self.values(idx,kompIdx) == str2double(self.alarmvalue{kompIdx}),
              self.values(idx,kompIdx) = nan;
            end
          end
        catch ERR
          self.values(idx,kompIdx) = nan;
          cws.logger('error evalCompSigsAtIdx');
        end
      end
      cws.logger('exit  evalCompSigsAtIdx');
    end
    
    function self = shiftDate( self , shift , MSG)
      if nargin < 3,
        MSG = [];
      end
      cws.logger('enter shiftDate');
      shiftIdx = shift * self.time.date_mult;
      self.time.set_date_start(self.time.date_start - shift);
      self.time.set_date_end(self.time.date_end - shift);
      self.time.current_index = self.time.current_index + shiftIdx;
      if ~isempty(MSG)
        MSG.cur_ts = MSG.cur_ts + shiftIdx;
      end
      self.values = circshift(self.values,[shiftIdx 0]);
      self.quality = circshift(self.quality,[shiftIdx 0]);
      self.data_status = circshift(self.data_status,[shiftIdx 0]);
      self.timesteps = cellstr(self.time.getDateStr(1:(self.time.date_end-self.time.date_start)*self.time.date_mult));
      for iL = 1:self.nlocs
        self.locations(iL).handle.shiftDate(shiftIdx);
      end
      self.values(min([end end+shiftIdx+2]):end,:) = 0;
      self.quality(min([end end+shiftIdx+2]):end,:) = 0;
      self.data_status(min([end end+shiftIdx+2]):end,:) = 0;
      cws.logger('exit  shiftDate');
    end
    
    function filename = saveCurrent(self, idx, data_dir_path, superscript)
      global DEBUG_LEVEL
      DeBug = DEBUG_LEVEL;
      cws.logger('enter saveCurrent');
      if DeBug > 0
        if ispc; memory, end;
      end
      % Setup
      if nargin < 4,
        superscript = '';
      end
      warning off MATLAB:Java:ConvertFromOpaque;
      warning off MATLAB:structOnObject;
      saveDateEnd = self.time.date_end;
      tsOld = self.timesteps;
      self.time.set_date_end(min([self.time.date_start+((idx-2)/self.time.date_mult) saveDateEnd]));
      self.timesteps = cellstr(self.time.getDateStr(1:((self.time.date_end-self.time.date_start)*self.time.date_mult)-1));
      % Save
      str1 = datestr(self.time.date_start,29);
      str2 = datestr(self.time.date_start+((idx-2)/self.time.date_mult),29);
      filename = fullfile(data_dir_path,[self.case_prefix,...
        str1,'.thru.',str2,superscript,'.edsd']);
      try
        save(filename,'self','-MAT');
      catch ERR
        cws.logger('error saveCurrent')
        cws.errTrace(ERR);
      end
      % Restore
      self.time.set_date_end(saveDateEnd);
      self.timesteps = tsOld;
      self.combined_filenames{end+1} = filename;
      cws.logger('exit  saveCurrent');
    end
    
    function filename = saveContinue(self, idx, data_dir_path) %#ok<INUSL,MANU>
      cws.logger('enter saveContinue');
      warning off MATLAB:Java:ConvertFromOpaque;
      warning off MATLAB:structOnObject;
      % Save
      filename = fullfile(data_dir_path,'continue.edsd');
      try
        save(filename,'self','-MAT');
      catch ERR
        cws.logger('error saveContinue')
        cws.errTrace(ERR);
      end
      % Restore
      cws.logger('exit  saveContinue');
    end
    
    function self = loadFiles( self , filename , startDate , endDate )
      if iscell(filename)
        if ~isempty(filename),
          newData = load(filename{1},'-MAT');
          self.deepCopy(newData.self);
        end
        for i = 2:length(filename),
          newData = load(filename{i},'-MAT');
          self.loadData(newData.self);
        end
      else
        [ path , name , ext  ] = fileparts(filename);
        [ dummy , name , date  ]  = fileparts(name);
        [ dummy , name , thru  ]  = fileparts(name);
        [ dummy , name , date  ]  = fileparts(name);
        dirstr = strcat( name , '.*', thru , '.*' , ext );
        MyDir = dir(dirstr);
        fileList = sort({MyDir.name}'); %#ok<UDIM>
        idx0 = 0;
        idx1 = 0;
        for i = 1:length(fileList)
          if strfind(fileList{i},[startDate thru]);
            idx0 = i+1;
          end
          if strfind(fileList{i},[thru endDate]);
            idx1 = i;
            break;
          end
        end
        for i = idx0:idx1
          disp(['Loading from ',fileList{i}]);
          data = load(fullfile(path,fileList{i}),'-MAT');
          self.loadData(data.self);
        end
      end
      Vdatenum = self.time.date_start + (0:size(self.values,1)-1)./self.time.date_mult;
      self.timesteps = datestr(Vdatenum,self.time.date_fmt);
    end
    
    function self = loadData( self , newData )
      MyStart = self.time.date_start;
      AddStart = newData.time.date_start;
      MyEnd = self.time.date_end;
      AddEnd = newData.time.date_end;
      MyLastIdx = round((MyEnd - MyStart) * self.time.date_mult - 1);
      AddStartIdx = round((MyEnd - AddStart) * self.time.date_mult - 1);
      AddLastIdx = round((AddEnd - AddStart) * self.time.date_mult);
      self.values = [ self.values(1:MyLastIdx,:) ; newData.values(AddStartIdx:AddLastIdx,:) ];
      self.quality = [ self.quality(1:MyLastIdx,:) ; newData.quality(AddStartIdx:AddLastIdx,:) ];
      self.data_status = [ self.data_status(1:MyLastIdx,:) ; newData.data_status(AddStartIdx:AddLastIdx,:) ];
      for iLoc = 1:self.nlocs
        LOC = self.locations(iLoc).handle;
        NewLoc = newData.locations(iLoc).handle;
        LOC.loadData( NewLoc , MyLastIdx , AddStartIdx, AddLastIdx  );
      end
      self.time.set_date_end(newData.time.date_end);
    end
    
    function self = deepCopy( self , newData )
      self.is_initialized = true;
      self.time.set_date_start(newData.time.date_start);
      self.time.set_date_end(newData.time.date_end);
      self.values = newData.values;
      self.quality = newData.quality;
      self.data_status = newData.data_status;
      self.timesteps = newData.timesteps;
      self.locations = newData.locations;
      self.nlocs = newData.nlocs;
      self.combined_filenames = {};
    end
    
    function idx = procAlgsAtIdx( self , idx , OUTPUTS , MSG )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('enter procAlgsAtIdx',4);
      if ~MSG.IsConnected,
        MSG.ts_to_backfill = MSG.ts_to_backfill + 1;
        msg = cws.Message('from','EDS','to','',...
          'subj','Communications offline!','warn',['at: ',datestr(now())]);
        disp(msg);
        return
      end
      if idx > size(self.timesteps,1)
        self.timesteps{idx} = self.time.getDateStr(idx);
      end
      
      if idx > size(self.values,1)
        msg = cws.Message('from','EDS','to','',...
          'subj','Data not yet received for timestep:','error',['at index #',num2str(idx)]);
        disp(msg);
        return
      end
      if strcmpi(MSG.run_mode,'realtime')
        switch lower(self.prov_type)
          case {'changes','changed','new values','new value'}
            self.values(idx+1,:) = self.values(idx,:);
          case {'all','every value','every'}
            self.values(idx+1,:) = 0;
          otherwise
            fprintf(2,'WARNING - unknown data provisioning type: %s\nresetting to "all"\n',self.prov_type);
            self.prov_type = 'all';
        end
      end
      if isempty(self.timesteps{idx}),
        self.timesteps{idx} = self.time.getDateStr(idx);
      end
      
      if ~MSG.IsBatch && mod(idx,self.time.date_mult)==1
        msg = cws.Message('from','EDS','to','',...
          'subj','completed processing to this date and time','cont',self.timesteps{idx});
        disp(msg);
        minHistKeep = ceil(MSG.ts_to_backfill / MSG.time.date_mult);
        if (idx >= self.time.date_mult*(1+minHistKeep)) && ~MSG.IsBatch
          msg = cws.Message('from','EDS','to','',...
            'subj','Processing daily shifting','cont',self.timesteps{idx});
          disp(msg);
          self.saveCurrent(idx,MSG.data_dir_path);
          self.shiftDate(-1,MSG);
          idx = idx - self.time.date_mult;
          logfile = self.fn_logfile;
          fprintf(2,'Switching logging to new file: %s.%s.log\n',logfile,datestr(now,'yyyy-mm-dd'));
          diary off;
          fn_logfile = sprintf('%s.%s.log',logfile,datestr(now,'yyyy-mm-dd'));
          diary(fn_logfile)
          diary on
          MSG.resetLogFile();
          cws.logger('logger_truncate',0,'',true);
          fprintf(2,'Logging %s starting: %s\n',logfile,datestr(now,'yyyy-mm-dd HH:MM:SS'));
        end
        
        for iLoc = 1:length(self.locations)
          LOC = self.locations(iLoc).handle;
          if isempty(LOC.algs),
            fprintf(2,'WARNING: Did you forget to add an algorithm to <location> %s?\n',LOC.name);
          elseif ~isa(LOC.algs(end).library,'ClusterLib') && ~isempty(LOC.algs(end).library)
            readClustFile = fullfile(MSG.data_dir_path,[self.case_prefix LOC.name,'.edsc']);
            clustFile = fullfile(MSG.data_dir_path,[self.case_prefix 'CUR_',LOC.name,'.edsc']);
            FInfoCF = dir(readClustFile);
            FInfoCI = dir(fullfile(MSG.data_dir_path,[self.case_prefix 'PATT_LIST_',LOC.name,'.txt']));
            if ~isempty(FInfoCF) && ~isempty(FInfoCI)
              if FInfoCF.datenum > FInfoCI.datenum
                fprintf(1,'UpdateSettings: %s <-- %s\n',LOC.name,readClustFile);
                dd = load(readClustFile,'-MAT');
                LOC.algs(end).library = dd.MyCluster;
              end
            end
            MyCluster = LOC.algs(end).library;
            save(clustFile,'MyCluster','-MAT');
            filename = [self.case_prefix 'PATT_LIST_',LOC.name,'.txt'];
            if isempty(MyCluster.patListDir),
              MyCluster.PrintPatternListFile(filename,MSG.data_dir_path);
            else
              MyCluster.PrintPatternListFile(filename);
            end
          end
        end
      end
      for iLoc = 1:length(self.locations)
        LOC = self.locations(iLoc).handle;
        if LOC.isstarted,
          if isempty(LOC.useOutputIds),
            OUTS = OUTPUTS;
          else
            OUTS = OUTPUTS(LOC.useOutputIds);
          end
          try
            cws.evaluate_timestep(idx, self, LOC , OUTS);
          catch ERRmsg
            fprintf(2,'??? %s\n',ERRmsg.message);
            for iS = 1:length(ERRmsg.stack)
              fprintf(2,'    %s: %d\n',ERRmsg.stack(iS).name,ERRmsg.stack(iS).line) ;
            end
            msg = cws.Message('from','CANARY','to','CONTROL',...
              'subj',['TIMESTEP FAILED ',LOC.name],'cont',self.timesteps{idx});
            MSG.send(msg);
          end
        end
      end
      cws.logger('exit  procAlgsAtIdx',4);
    end
    
    function self = initialize( self , force)
      if nargin < 2,
        force = false;
      end
      try
        if ~isempty(self.time.getEndDate),
          nData = self.time.getDateIdx(self.time.getEndDate);
        else
          nData =10000;
        end
        if self.is_initialized && ~force,
          fprintf(2,'WARNING! Signals data seems to be populated already!\n');
          fprintf(2,'         Not initializing data values!\n');
        elseif ~self.is_initialized || force,
          self.values = zeros(nData,self.nsigs);
          self.quality = zeros(nData,self.nsigs);
          self.data_status = zeros(nData,self.nsigs);
          date_fmt = self.time.date_fmt;
          if isempty(date_fmt), date_fmt = 'yyyy-mm-dd HH:MM:SS'; end;
          timesteps = (0:size(self.values,1)-1) ./ self.time.date_mult;
          timesteps = timesteps + self.time.date_start;
          self.timesteps = cellstr(datestr(timesteps,date_fmt));
        end
      catch ERR
        cws.errTrace(ERR);
      end
      self.is_initialized = true;
    end
    
    function str = toString( self )
      str = sprintf('<cwsSignals name="%s">\n',inputname(1));
      str = sprintf('%s <Dates start="%s" stop="%s" />\n',str,self.time.getstartDate,self.time.getEndDate);
      str = sprintf('%s <Parameters number="%s" />\n',str,num2str(length(self.scadatags)));
      str = sprintf('%s <Timesteps number="%s" />\n',str,num2str(length(self.timesteps)));
      str = sprintf('%s <Locations number="%s">\n',str,num2str(length(self.locations)));
      for i = 1:length(self.locations)
        str = sprintf('%s  <Location name="%s" nsigs="%d" nalgs="%d" curidx="%s" />\n',str,self.locations(i).name,...
          length(self.locations(i).handle.sigs),...
          length(self.locations(i).handle.algs),...
          self.time.getDateStr(self.locations(i).handle.lastIdxEvaluated));
      end
      str = sprintf('%s </Locations>\n</cwsSignals>\n',str);
      % END OF TOSTRING -------------------------------------------------------
    end
    
    function str = char( self )
      str = self.toString();
    end
    
  end
  
  methods (Static = true)
    function self = loadobj( obj )
      % Add Timing and Location data conversion to this as well
      if isa(obj,'cws.Signals'),
        self = obj;
      else
        self = cws.Signals(obj);
      end
      if size(self.values,1) ~= size(self.quality,1),
        self.quality(size(self.values,1),1) = 0;
      end
      if size(self.values,1) ~= size(self.data_status,1),
        self.data_status(size(self.values,1),1) = 0;
      end
      if size(self.values,2) ~= size(self.quality,2),
        self.quality(1,size(self.values,2)) = 0;
      end
      if size(self.values,2) ~= size(self.data_status,2),
        self.data_status(1,size(self.values,2)) = 0;
      end
    end
    
    function val = EvalType(arg)
      if isnumeric(arg)
        switch arg
          case 0
            val = 'CAL';
          case 1
            val = 'WQ';
          case -1
            val = 'ALM';
          case 2
            val = 'OP';
          otherwise
            val = 'INFO';
        end
      else
        switch lower(char(arg))
          case {'cal'}
            val = 0;
          case {'wq'}
            val = 1;
          case {'alm'}
            val = -1;
          case {'op'}
            val = 2;
          otherwise
            val = nan;
        end
      end
    end
    
    function num = WQ( )
      num = 1;
    end
    
    function num = OP( )
      num = 2;
    end
    
    function num = ALM( )
      num = -1;
    end
    
    function num = CAL( )
      num = 0;
    end
    
    function num = INFO( )
      num = nan;
    end
    
    function val = getParameterNumericValue( str )
      switch lower(str)
        case {'cl','cl2','clm','clmx','trc','trcx','cl2x'}
          val = 1;
        case {'cond','cdty','sc','ec'}
          val = 3;
        case {'ph','phxx'}
          val = 5;
        case {'ftur','filt'}
          val = 7;
        case {'mtur','turb'}
          val = 9;
        case {'toc','tocx'}
          val = 11;
        case {'do','fl','fl2','flor','orp'}
          val = 13;
        otherwise
          val = 15;
      end
    end
  end
  
end
