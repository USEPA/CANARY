classdef Message
  %COMMANDMSG Summary of this class goes here
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
  properties
    to = '';
    from = '';
    subj = '';
    cont = '';
    number = 0;
    date = '';
    error = '';
    warn = '';
    obj = [];
  end
  
  methods
    function str = char ( obj )
      str = sprintf('- message:\n');
      str = sprintf('%s    timestamp:%s\n',str,datestr(now,30));
      if ~isempty(obj.to)
        str = sprintf('%s    to:       %s\n',str,obj.to);
      end
      str = sprintf('%s    from:     %s\n',str,obj.from);
      str = sprintf('%s    subject:  %s\n',str,obj.subj);
      if ~isempty(obj.cont),
        str = sprintf('%s    content:  %s\n',str,obj.cont);
      end
      if ~isempty(obj.error),
        str = sprintf('%s    ERROR:    %s\n',str,obj.error);
      end
      if ~isempty(obj.warn),
        str = sprintf('%s    Warning:  %s\n',str,obj.warn);
      end
    end
    
    function obj = Message ( varargin )
      args = varargin;
      while ~isempty(args)
        fld = char(args{1});
        val = char(args{2});
        try
          obj.(fld) = val;
        catch ERR
          disp(ERR.message);
          warning('CANARY:unknownOption','''%s'' is not a recognized option',fld);
        end
        args = {args{3:end}};
      end
    end
    
    function display( obj )
      obj.disp();
    end
    
    function disp( obj )
      if ~isempty(obj.error),
        fprintf(2,'%s\n',char(obj));
      else
        fprintf(1,'%s\n',char(obj));
      end
    end
        
    function str = char_old ( obj )
      if ~isempty(obj.error)
        str = sprintf('ERROR: %s %s %s',obj.subj,obj.to,obj.error);
      elseif ~isempty(obj.warn)
        str = sprintf('WARN:  %s %s %s',obj.subj,obj.to,obj.warn);
      else
        str = sprintf('Info:  %s %s %s',obj.cont,obj.to,obj.subj);
      end
    end

  end
end

