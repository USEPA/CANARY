function trace ( identifier , message , varargin )
  % TRACE is used with debuggers or a global DEBUG_LEVEL to provide trace
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
  % information on functions and also to provide a generic error/exception
  % handler/formatter.
  global DEBUG_LEVEL;
  if isempty(DEBUG_LEVEL) || DEBUG_LEVEL == 0,
    return;
  end
  [ ST, I ] = dbstack('-completenames',1);
  if nargin < 2, message = ''; end;
  if nargin < 1, identifier = ''; end;

  str = sprintf('- Trace:\n');
  str = sprintf('%s    timestamp:  %s\n',str,datestr(now(),30));
  str = sprintf('%s    line:      "%s @ %d"\n',str,ST(1).name,ST(1).line);
  if DEBUG_LEVEL > 0,
    str = sprintf('%s    identifier: %s\n',str,char(identifier));
    str = sprintf('%s    message:   "%s"\n',str,regexprep(message,'\n','\\n'));
  end
  fprintf(2,'%s\n',str);
end
