classdef Timing < handle
  %TIMECFG Basic data/time data for CANARY
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
  %   This is a handle, so every object that has one uses the same copy (and we
  %   don't lose anything along the way).
  % Patch: r3527 - John Knoll, TetraTech, 5/21/2010
  
  properties
    date_start
    date_end
    date_fmt
    date_mult      % used to convert timesteps to dates: 720 = 720 timesteps / day
    poll_int = 10; % Default time to wait if no message is available (seconds)
    is_first = true; % First date
    dynamic = false;
    current_index = 0;
    current_timestep = '';
    date_start_hh = 0
    date_start_mm = 0
    date_start_ss = 0
  end
  
  methods
    
    function configure( self, yamlObj)
      dyn = false;
      sta_date = floor(now-1);
      end_date = ceil(now+1);
      sKeys = cell(yamlObj.keySet().toArray());
      for isKey = 1:length(sKeys)
        sKey = sKeys{isKey};
        switch sKey
          case {'dateFormat','date-time format','date format','time format'}
            fmt = yamlObj.get(sKey);
            self.set_date_fmt(fmt);
          case {'dynamicDates','dynamic start-stop'}
            dyn = logical(yamlObj.get(sKey));
          case {'date-time start','startDate'}
            sta_date = yamlObj.get(sKey);
          case {'date-time stop','stopDate'}
            end_date = yamlObj.get(sKey);
          case {'dataInterval','data interval'}
            data_int = yamlObj.get(sKey);
            self.set_date_mult(data_int);
          case {'readInterval','message interval','read interval'}
            msg_int = yamlObj.get(sKey);
            self.set_poll_int(msg_int);
        end
      end
      self.dynamic = dyn;
      if ~dyn
        self.set_date_start(sta_date);
        self.set_date_end(end_date);
      end
    end
    
    function set_dynamic( self, MSGR )
      if self.dynamic
        dist = ceil(1 + (MSGR.ts_to_backfill / self.date_mult));
        self.set_date_start(floor(now-dist));
        self.set_date_end(ceil(now+1));
      end
    end
    
    function str = printYAML( self )
      str = sprintf('timing options:\n');
      str = sprintf('%s  dynamic start-stop: %s\n',str,yaml.bool2str(self.dynamic,'oo'));
      str = sprintf('%s  date-time format: %s\n',str,self.date_fmt);
      if ~self.dynamic
        str = sprintf('%s  date-time start:  %s\n',str,datestr(self.date_start,self.date_fmt));
        str = sprintf('%s  date-time stop:   %s\n',str, datestr(self.date_end,self.date_fmt));
      end
      str = sprintf('%s  data interval: %s\n',str, ['00:',num2str(round(1440/self.date_mult),'%.2d'),':',num2str(round(mod(1440/self.date_mult,1)*60),'%.2d')]);
      str = sprintf('%s  message interval: %s\n',str, ['00:00:',num2str(self.poll_int,'%.2d')]);
    end
    
    function str = PrintTimingAsXML( self )
      str = sprintf(' <timing-options data-interval="%s" start-date="%s" stop-date="%s" datetime-format="%s" dynamic-start="%d" poll-interval="%s" />',...
        ['00:',num2str(round(1440/self.date_mult),'%.2d'),':',num2str(round(mod(1440/self.date_mult,1)*60),'%.2d')], datestr(self.date_start,self.date_fmt) , datestr(self.date_end,self.date_fmt) , self.date_fmt , self.dynamic , ['00:00:',num2str(self.poll_int,'%.2d')] );
    end
    
    function list = PrintAsXML( self )
      list = {self.PrintTimingAsXML()};
    end
    
    function self = Timing( varargin )
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'Timing') || isa(obj,'struct')
          FN = fieldnames(obj);
          for iFN = 1:length(FN)
            self.(char(FN(iFN))) = obj.(char(FN(iFN)));
          end
        else
          error('cws:Timing','Unknown construction method: %s',class(obj));
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
            warning('cws:Timing','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
    end
    
    function idx = getDateIdx(obj, date_str, date_fmt)
      if nargin<3,
        date_fmt = obj.date_fmt;
      end
      if isnumeric(date_str),
        date_num = date_str;
        [Y,MO,D,H,MI,S] = datevec(date_num);
      else
        date_num = datenum(date_str,date_fmt);
        [Y,MO,D,H,MI,S] = datevec(date_str, date_fmt);
      end
      date_ts = (floor(date_num) - floor(obj.date_start)) * 60 * 60 * 24;
      hrs = (H - obj.date_start_hh) * 60 * 60;
      mins = (MI - obj.date_start_mm) * 60;
      secs = (S - obj.date_start_ss);
      time_ts = floor((date_ts + hrs + mins + secs) / ((60*60*24)/obj.date_mult));
      idx = 1 + time_ts;
      %idx = 1 + round(( date_num - obj.date_start ) * obj.date_mult );
      idx2 = 1 + floor(( date_num - obj.date_start ) * obj.date_mult );
    end
    
    function date_str = getDateStr(obj, idx, date_fmt)
      date_num = ( (idx-1) / obj.date_mult ) + obj.date_start;
      if nargin>2,
        date_str = datestr(date_num,date_fmt);
      else
        date_str = datestr(date_num,obj.date_fmt);
      end
    end
    
    function obj = set_date_fmt(obj,value)
      if ~ischar(value)
        error('Unknown argument type: %s',class(value));
      else
        obj.date_fmt = value;
      end
    end
    
    function obj = set_date_mult(obj,value)
      if isempty(value)
        obj.date_mult = [];
        return
      end
      if isnumeric(value)
        if value < 0.0,
          error('Date multiplier must be a positive number');
        elseif value > 1.0,
          obj.date_mult = value;
        else
          obj.date_mult = round(1/value);
        end
      elseif ischar(value)
        n = datenum(value);
        obj.date_mult = round(1 / rem(n,1));
      elseif isa(value,'java.util.Date')
        n = datenum(char(value.toGMTString()));
        obj.date_mult = round(1 / rem(n,1));
      else
        error('Unknown argument type: %s',class(value));
      end
    end
    
    function obj = set_date_start(obj,value)
      if isempty(value)
        obj.date_start = [];
        return
      end
      if ischar(value)
        try
          if ~isempty(obj.date_fmt)
            obj.date_start = datenum(value,obj.date_fmt);
          else
            obj.date_start = datenum(value);
          end
        catch J
          warning('cws:BadDateFormat',J.message);
          try
            obj.date_start = datenum(value,'mm/dd/yyyy HH:MM PM');
            obj.date_fmt = 'mm/dd/yyyy HH:MM PM';
          catch J
            rethrow J
          end
        end
      elseif isnumeric(value)
        obj.date_start = value;
      elseif isa(value,'java.util.Date')
        disp(value);
        n = datenum(char(value.toGMTString()));
        obj.date_start = n;
      else
        error('Unknown argument type: %s',class(value));
      end
      [Y,MO,D,H,MI,S] = datevec(obj.date_start);
      obj.date_start_hh = H;
      obj.date_start_mm = MI;
      obj.date_start_ss = S;
    end
    
    function obj = set_startDate(obj,value)
      if isempty(value)
        obj.date_start = [];
        return
      end
      if ischar(value)
        try
          if ~isempty(obj.date_fmt)
            obj.date_start = datenum(value,obj.date_fmt);
          else
            obj.date_start = datenum(value);
          end
        catch J
          warning('cws:BadDateFormat',J.message);
          try
            obj.date_start = datenum(value,'mm/dd/yyyy HH:MM PM');
            obj.date_fmt = 'mm/dd/yyyy HH:MM PM';
          catch J
            rethrow J
          end
        end
      elseif isnumeric(value)
        obj.date_start = value;
      elseif isa(value,'java.util.Date')
        disp(value);
        n = datenum(char(value.toGMTString()));
        obj.date_start = n;
      else
        error('Unknown argument type: %s',class(value));
      end
      [Y,MO,D,H,MI,S] = datevec(obj.date_start);
      obj.date_start_hh = H;
      obj.date_start_mm = MI;
      obj.date_start_ss = S;
    end

    
    function obj = set_date_end(obj,value)
      if isempty(value)
        obj.date_end = [];
        return
      end
      if ischar(value)
        try
          if ~isempty(obj.date_fmt)
            obj.date_end = datenum(value,obj.date_fmt);
          else
            obj.date_end = datenum(value);
          end
        catch J
          warning('cws:BadDateFormat',J.message);
          try
            obj.date_end = datenum(value,'mm/dd/yyyy HH:MM PM');
            obj.date_fmt = 'mm/dd/yyyy HH:MM PM';
          catch J
            rethrow J
          end
        end
      elseif isnumeric(value)
        obj.date_end = value;
      elseif isa(value,'java.util.Date')
        disp(value);
        n = datenum(char(value.toGMTString()));
        obj.date_end = n;
      else
        error('Unknown argument type: %s',class(value));
      end
    end
    
    function obj = set_poll_int(obj,value)
      if isempty(value)
        obj.poll_int = 0;
        return
      end
      if ischar(value)
        n = datenum(value);
        obj.poll_int = round( rem(n,1) * 60 * 60 * 24 );
      elseif isnumeric(value);
        if value < 0.0,
          error('Message polling interval must be a positive number');
        else
          obj.poll_int = value;
        end
      end
      if obj.poll_int < 0.01,
        obj.poll_int = 0.01;
      end
    end
    
    function str = getstartDate(obj)
      if ~isempty(obj.date_fmt)
        if ~isempty(obj.date_start)
          str = datestr(obj.date_start,obj.date_fmt);
        else
          str = datestr(now(),obj.date_fmt);
        end
      else
        if ~isempty(obj.date_start)
          str = datestr(obj.date_start,'yyyy-mm-dd HH:MM:SS');
        else
          str = datestr(now,'yyyy-mm-dd HH:MM:SS');
        end
      end
    end
    
    function str = getEndDate(obj)
      if ~isempty(obj.date_fmt)
        if ~isempty(obj.date_end)
          str = datestr(obj.date_end,obj.date_fmt);
        else
          str = datestr(now(),obj.date_fmt);
        end
      else
        if ~isempty(obj.date_end)
          str = datestr(obj.date_end,'yyyy-mm-dd HH:MM:SS');
        else
          str = datestr(now,'yyyy-mm-dd HH:MM:SS');
        end
      end
    end
  end
end

