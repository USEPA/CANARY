%VERIFY_CONNECTION Reset connection if no comms in certain timeperiod
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
%
function verify_connection( obj, event, MSG )
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL;
  ctMax = min([(MSG.time.date_mult / MSG.time.poll_int) 120000]);
  if MSG.msgs_clear,
    CurDelay = (now - MSG.msgs_clear) * 86400; % in seconds
  else
    CurDelay = inf;
  end
  if MSG.IdleCount >= ctMax,
    MSG.disconnect();
    MSG.connect();
    if MSG.IsConnected,
      MSG.clear_idle();
    else
      if DeBug,
        cws.trace('connect:failed','Connect to datasource failed');
      end
      pause(5);
    end
  elseif MSG.RcvdNewData && MSG.data_done && ( CurDelay >= MSG.clear_delay )
    message = cws.Message('to', 'canary', 'from', 'control', 'subj', 'timestep', 'cont', MSG.LastDateTimeSeen);
    MSG.send(message);
  elseif MSG.IdleCount < ctMax,
    MSG.idle();
  end
end
