function bValue = bool ( strValue )
  % EVALBOOL Evaluates text as a boolean value
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
  % Evaluates a text string as true or false based on checking that the
  % string contains one of the following: 0, "false", or "no". Any string
  % containing one of these substrings, or which is completely empty,
  % evaluates to a boolean value of false. Any other string evaluates to a
  % boolean value of true.
  %
  % Example:
  %     bVal = evalBool ( 'FaLsE' )
  %     bVal = evalBool ( mystring )
  %
  if ~iscell(strValue) && ~ischar(strValue),
    bValue = strValue;
    return;
  end
  str = char(strValue);
  if isempty(str),
    bValue = [];
    return;
  end
  switch lower(str)
    case {'0','false','no','none','off'}
      bValue = false;
    otherwise
      bValue = true;
  end
