%WRITECONFIG
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
function writeConfig(filepath, runMode,dataDir,logFile,iValues,inputCT, oValues, outputCT,messageOptions, dbDriver, timingOptions, signalArray, signalCT, algArray, algCT, locInfo, locCT)
  
  
  
  function comment(message)
    fprintf(fid,['<!--> \n' message '\n </-->']);
  end
  
  
  function writeOptionsField(varargin)  % writeField(FieldName, childName1, childValue1, childName2, childValue2...)
    
    fieldName = varargin{1};
    ct = 0;
    
    fprintf(fid,['\n  <' fieldName ]);
    
    for i = 1:((nargin-1)/2),
      ct = ct + 2;
      
      childName = varargin{ct};
      childVal = varargin{ct+1};
      
      if ~isempty(childVal),
        fprintf(fid,'\n   %s="%s"',childName,childVal);
      end
    end
    
    fprintf(fid, '   />\n');
    
    
  end
  
  function writeOptionsFieldnoslash(varargin)  % writeField(FieldName, childName1, childValue1, childName2, childValue2...)
    
    fieldName = varargin{1};
    ct = 0;
    
    fprintf(fid,'\n  <%s',fieldName);
    
    for i = 1:((nargin-1)/2),
      ct = ct + 2;
      
      childName = varargin{ct};
      childVal = varargin{ct+1};
      
      if ~isempty(childVal),
        fprintf(fid,'\n   %s="%s"',childName,childVal);
      end
    end
    
    fprintf(fid, '   >\n');
    fprintf(fid, '\n  </%s  >\n',fieldName);
    
    
  end
  
  
  
  function writeSingleField(fName, fValue)
    
    if  ~isempty(fValue),
      
      fprintf(fid,'\n <%s>%s</%s> \n',fName,fValue,fName);
      
    end
    
  end
  
  function writeParent(varargin)
    
    ct = 0;
    
    if nargin == 1,
      fprintf(fid,'\n  <%s>\n',varargin{1});
    else
      
      parentName = varargin{1};
      fprintf(fid,'\n  <%s', parentName );
      
      for i = 1:((nargin-1)/2),
        ct = ct +2;
        
        if ~isempty(varargin{ct+1}),
          fprintf(fid,' %s="%s"',varargin{ct},varargin{ct+1});
        end
      end
      
      fprintf(fid,'>\n');
      
    end
  end
  
  
  function multipleChild(name,valueList)
    whos
    for i =1:size(valueList,2),
      
      fprintf(fid,'\n   <%s="%s" />',name,valueList{i}); %fid
    end
    
    fprintf(fid,'\n');
    
  end
  
  
  fid = fopen(filepath, 'wt');
  
  
  
  
  fprintf(fid,'<canary-database>\n\n');
  
  writeSingleField('run-mode', runMode);
  
  writeSingleField('log-file', logFile);
  
  writeSingleField('data-dir', dataDir);
  
  
  
  for l = 1:inputCT,
    
    writeOptionsFieldnoslash('input-options', 'short-id', iValues{1,l}, 'type', iValues{2,l}, 'location', iValues{3,l}, 'table', iValues{4,l}, 'username', iValues{5,l}, 'password', iValues{6,l});
  end
  
  for m = 1:outputCT,
    
    writeOptionsFieldnoslash('output-options', 'short-id', oValues{1,m}, 'type', oValues{2,m}, 'location', oValues{3,m}, 'table', oValues{4,m}, 'username', oValues{5,m}, 'password', oValues{6,m});
  end
  
  writeOptionsFieldnoslash('messaging', 'type', messageOptions{1,1}, 'location', messageOptions{2,1}, 'username', messageOptions{3,1}, 'password', messageOptions{4,1});
  
  writeOptionsFieldnoslash('jdbc-driver', 'driver-class', dbDriver{1,1}, 'datasource-class', dbDriver{2,1}, 'classpath', dbDriver{3,1}, 'type', dbDriver{4,1}, 'to-date-func', dbDriver{5,1}, 'to-date-fmt', dbDriver{6,1});
  
  writeOptionsFieldnoslash('timing-options', 'data-interval', timingOptions{1,1}, 'poll-interval', timingOptions{2,1}, 'start-date', timingOptions{3,1}, 'end-date', timingOptions{4,1}, 'dynamic-start', timingOptions{5,1}, 'datetime-format', timingOptions{6,1});
  
  fprintf(fid, '\n <general-settings>\n\n');
  
  
  for n = 1:signalCT,
    
    
    if strcmp(signalArray{4, n} ,'WQ') || strcmp(signalArray{4,n}, 'OP'),
      
      writeOptionsFieldnoslash('signal', 'short-id', signalArray{1,n}, 'scada-id', signalArray{2,n}, 'parameter_type', signalArray{3,n}, 'signal-type', signalArray{4,n}, 'units', signalArray{5,n}, 'ignore_changes', signalArray{6,n}, 'description', signalArray{9,n}, 'precision', signalArray{10,n});
      
    elseif strcmp(signalArray{4, n} , 'ALM') || strcmp(signalArray{4,n} , 'CAL'),
      
      writeOptionsFieldnoslash('signal', 'short-id', signalArray{1,n}, 'scada-id', signalArray{2,n}, 'parameter_type', signalArray{3,n}, 'signal-type', signalArray{4,n}, 'alarm-scope', signalArray{5,n}, 'ignore_changes', signalArray{6,n}, 'normal-value' , signalArray{7,n}, 'bad-value', signalArray{8,n}, 'description', signalArray{9,n});
    end
    
  end
  
  for p = 1:algCT,
    
    writeOptionsFieldnoslash('algorithm', 'short-id', algArray{1,p}, 'mFile', algArray{2,p}, 'window', algArray{3,p}, 'threshold', algArray{4,p}, 'use-bed', algArray{5,p}, 'binom-win-min', algArray{6,p}, 'binom-win-max', algArray{7,p}, 'binom-p-value', algArray{8,p}, 'binom-threshold', algArray{9,p});
    
  end
  
  for q = 1:locCT,
    
    writeParent('location', 'short-id', locInfo{1,q}, 'scada-id', locInfo{2,q}, 'description', locInfo{3,q});
    
    %lst = locInfo{4,q}
    multipleChild('use-input id', locInfo{4,q});%lst, %length(lst));
    
    % lst2 = locInfo{5,q}
    multipleChild('use-output id',locInfo{5,q});%lst2, length(lst2));
    
    %lst3 = locInfo{7,q}
    multipleChild('use-signal id', locInfo{7,q});%lst3, length(lst3));
    
    % lst4 = locInfo{6,q}
    multipleChild('use-algorithm id', locInfo{6,q});%lst4, length(lst4));
    
    
    fprintf(fid, '  </location>\n\n');
    
  end
  
  fprintf(fid, ' </general-settings>\n\n')
  
  fprintf(fid, '</canary-database>\n');
  
  
  
end









