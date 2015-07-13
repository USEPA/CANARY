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
function create_config_file( filename , DSRCS , MSGR , SIGS , runmode , datadir , extras )
  FID = fopen( filename , 'wt' );
  fprintf(FID,'<canary>\n');
  fprintf(FID,' <run-mode>%s</run-mode>\n',upper(runmode));
  if isempty(datadir)
      
  else
      if datadir(end)==filesep,
        datadir = datadir(1:end-1);
      end
  end
  fprintf(FID,' <data-dir>%s</data-dir>\n',datadir);
  for i = 1:length(extras),
    fprintf(FID,' <classpath>%s</classpath>\n',extras{i});
  end
  for i = 1:length(DSRCS),
    fprintf(FID,'%s\n',DSRCS(i).handle.PrintDataSourceAsXML());
  end
  fprintf(FID,'%s\n',MSGR.PrintMessengerAsXML());
  fprintf(FID,'%s\n',SIGS.time.PrintTimingAsXML());
  SList = SIGS.PrintAsXML();
  AList = SIGS.algorithms.PrintAsXML();
  for i = 1:length(SList),
    fprintf(FID,'%s\n',SList{i});
  end
  for i = 1:length(AList),
    fprintf(FID,'%s\n',AList{i});
  end
  fprintf(FID,' <general-settings>\n');
  for i = 1:length(SIGS.locations)
    LOC = SIGS.locations(i).handle;
    if ~isempty(LOC.name)
      LList = LOC.PrintAsXML(SIGS,DSRCS);
      for j = 1:length(LList),
        fprintf(FID,'%s\n',LList{j});
      end
    end
  end
  fprintf(FID,' </general-settings>\n');
  fprintf(FID,'</canary>\n');
  fclose(FID);
end
