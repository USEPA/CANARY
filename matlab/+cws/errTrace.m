function errTrace( ERR )
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
  str = sprintf('\n');
  str = sprintf('%s- Error:\n',str);
  str = sprintf('%s    timestamp:%s\n',str,datestr(now,30));
  str = sprintf('%s%s',str,errInfo(ERR,2));
  if ~isempty(ERR.cause),
    for i = 1:length(ERR.cause)
      str = sprintf('%s%s',str,errCauseTrace(ERR.cause{i},2));
    end
  end
  str = sprintf('%s%s',str,errStackTrace(ERR.stack,2));
  fprintf(2,'%s\n',str);
end

function str = errInfo(ERR, indent)
  pad = repmat(' ',1,indent);
  str = sprintf('%s  identifier: "%s"\n%s  message: "%s"\n',pad,ERR.identifier,pad,regexprep(ERR.message,'\n','\\n'));
end

function str = errStackTrace(stack, indent )
  str = '';
  if ~isempty(stack)
    pad = repmat(' ',1,indent);
    str = sprintf('%s  Stack:\n',pad);
    for iS = 1:length(stack)
      str = sprintf('%s  %s - %s @ %d\n',str,pad,stack(iS).name,stack(iS).line);
    end
  end
end

function str = errCauseTrace( cause, indent )
    pad = repmat(' ',1,indent);
    str = sprintf('%s  Cause:\n%s',pad,errInfo(cause,indent+2));
    str = sprintf('%s  %s',str,errStackTrace(cause.stack,indent+2));
    if ~isempty(cause.cause)
      for i = 1:length(cause),
        str = sprintf('%s  %s',str,errCauseTrace(cause.cause{i},indent+2));
      end
    end
end
