%CURRENTTIME Issue a "TIMESTEP" command to the messenger
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
function currentTime(obj, event, MSG)
  import cws.*
  if MSG.state == 0,
    return;
  end
  if ~strcmpi(MSG.msgr_type,'INTERNAL')
    return;
  end
  
  %%% THIS IS NOT THE CODE YOU ARE LOOKING FOR !!!
  %%% XML- MESSENGER CODE IS IN VERIFY_CONNECTION !!!
  
  delay = MSG.clear_delay / 86400;
  cur_time = floor(((now()-delay)-MSG.time.date_start)*MSG.time.date_mult);
  cws.logger(sprintf('%d >? %d',cur_time,MSG.cur_ts));
  if ~MSG.msgs_clear,
      clear_messages = true;
  else
      delay = (now - MSG.msgs_clear) * 86400;
      if delay >= MSG.clear_delay, clear_messages = true;
      else clear_messages = false;
      end
  end
  if cur_time > MSG.cur_ts && clear_messages, 
    % We need to have messages finished - XML messages sent a "ResWait" 
    % status that the list is complete. If not, we need to hold off a 
    % little longer
    date = datestr((round(now()*MSG.time.date_mult-1))/MSG.time.date_mult, MSG.time.date_fmt);
    message = cws.Message('to', 'canary', 'from', 'control', 'subj', 'timestep', 'cont', date);
    if MSG.IsConnected,
      try
        MSG.send(message);
        cws.trace('TIMESTEP',['Timestep sent: ' date]);
        MSG.ts_to_backfill = 0;
        MSG.cur_ts = cur_time;
      catch ERR
        MSG.ts_to_backfill = MSG.ts_to_backfill + 1;
      end
    else
      MSG.ts_to_backfill = MSG.ts_to_backfill + 1;
    end
  end
end
