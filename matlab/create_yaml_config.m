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
function create_yaml_config( filename , DSRCS , MSGR , SIGS , runmode , datadir , extras )
  FID = fopen( filename , 'wt' );
  fprintf(FID,'--- # CANARY Config File\n# Auto generated - %s\n',datestr(now(),'yyyy-mm-ddTHH:MM:SS'));
  
  fprintf(FID,'\ncanary:\n');
  fprintf(FID,'  run mode: %s\n',upper(runmode));
  fprintf(FID,'  control type: %s\n',upper(MSGR.msgr_type));
  switch lower(MSGR.msgr_type)
    case {'internal'}
      fprintf(FID,'  control messenger: %s\n','null');
    otherwise
      fprintf(FID,'  control messenger: %s\n',MSGR.conn_id);
  end
  if ~isempty(extras)
    fprintf(FID,'  driver files:\n');
    for i = 1:length(extras),
      fprintf(FID,'  - %s\n',extras{i});
    end
  else
    fprintf(FID,'  driver files: null\n');
  end
  if MSGR.use_continue,
    fprintf(FID,'  use continue: yes\n');
  else
    fprintf(FID,'  use continue: no\n');
  end
  fprintf(FID,'  data provided: %s\n',upper(SIGS.prov_type));
  
  fprintf(FID,'\n# Enter the time step options below\n');
  fprintf(FID,'%s',SIGS.time.printYAML());
  
  fprintf(FID,'\n# Enter the list of data sources below\n');
  fprintf(FID,'data sources:\n');
  for i = 1:length(DSRCS),
    fprintf(FID,'%s\n',DSRCS(i).handle.printYAML());
  end
  
  fprintf(FID,'\n# Enter the list of SCADA/composite signals/parameters below\n');
  SList = SIGS.printAllYAML();
  fprintf(FID,'%s\n',SList);
  
  fprintf(FID,'# Enter the list of event detection algorithms below\n');
  AList = SIGS.algorithms.printAllYAML();
  fprintf(FID,'%s\n',AList);
  
  fprintf(FID,'# Enter the list of monitoring stations below\n');
  fprintf(FID,'monitoring stations:\n');
  for i = 1:length(SIGS.locations)
    LOC = SIGS.locations(i).handle;
    if ~isempty(LOC.name)
      LList = LOC.printYAML(SIGS,DSRCS);
      fprintf(FID,'%s\n',LList);
    end
  end
  fclose(FID);
  
end
