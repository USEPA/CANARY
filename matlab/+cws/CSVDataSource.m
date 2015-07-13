classdef CSVDataSource < handle & cws.DataSource % ++++++++++++++++++++++++
  % DATASOURCE class definition
  %
  % CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
  % Copyright 2007-2012 Sandia Corporation.
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
  
  methods % PUBLIC METHODS + OVERLOADED METHODS +++++++++++++++++++++++++++
    
    function self = CSVDataSource( varargin ) % --------- CONSTRUCTOR --
      %DATASOURCE/DATASOURCE constructs a new DATASOURCE Object using the
      %property value paris provided as parameters to the constructor
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin == 1,
        obj = varargin{1};
        if isa(obj,'DataSource') || isa(obj,'Connection') || isa(obj,'struct')
          FN = fieldnames(self);
          for iFN = 1:length(FN)
            self.(char(FN(iFN))) = obj.(char(FN(iFN)));
          end
          self.IsConnected = false;
        elseif isa(obj,'char')
          self.conn_id = obj;
        elseif isa(obj,'java.util.LinkedHashMap')
          self.constructFromYAML(obj);
        else
          error('CANARY:datasource:csv','Unknown construction method: %s',class(self));
        end
      elseif nargin > 1
        args = varargin;
        while ~isempty(args)
          fld = char(args{1});
          val = args{2};
          try
            self.(fld) = val;
          catch ERR
            if DeBug, cws.errTrace(ERR); end
            warning off backtrace
            warning('CANARY:datasource:csv:UnknownOption','''%s'' is not a recognized option',fld);
          end
          args = {args{3:end}};
        end
      end
      % END OF CONSTRUCTOR ----------------------------------------------------
    end
    
    function self = connect(self)
      %CONNECT connect to the web, a database or a file
      %   This function connects an Object to the appropriate network asset, database,
      %   or file to be used by a CanaryInput, CanaryOutput or Messenger Object. This
      %   depends on the value of the CONN_TYPE property of the base Object. The
      %   acceptable values for CONN_TYPE are:
      %
      %       XML     - used to indicate a Connection via a website Connection
      %
      %       JDBC    - used to indicate a database that uses JDBC drivers
      %
      %       FILE    - This is a file Connection or internal stack (Messenger)
      %
      %  See also disconnect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      %
      %  Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.IsConnected = true;
    end
    
    function self = disconnect( self )
      %DISCONNECT Closes the Connection made previously
      %   disconnects a connected Object and displays any warning messages than may
      %   appear (such as disconnecting an already disconnected Object). This method
      %   may be overloaded in subclasses due to specific needs.
      %
      % See also connect, RegisterDriver and CanaryInput, CanaryOutput, Messenger
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.IsConnected = false;
      self.addMessageCS = [];
      self.getMessageCS = [];
      % END OF DISCONNECT -----------------------------------------------------
    end
    
    function self = update( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      cws.logger('start datasource update');
      if ~self.isused, return ; end
      %       if sum(self.isActive) < 1 , return ; end
      %       usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj','Updating data','cont',datestr(now));
      %       disp(usrmsg);
      if self.IsInput
        if DeBug,
          st1 = datestr(now(),30);
          fprintf(2,'- update from source: %s\n',self.conn_url);
        end
        try
          self.read_csvfile(varargin{1});
        catch E
          cws.errTrace(E);
          rethrow(E);
        end
        if DeBug,
          st2 = datestr(now(),30);
          fprintf(2,'  update duration: %s --> %s\n',st1,st2);
        end
      end
      cws.logger('exit  datasource update');
      % END OF UPDATE ---------------------------------------------------------
    end
    
    function self = postResult( self , idx , LOC , timestep , CDS )
      cws.logger('enter postResult');
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if self.IsOutput
        try
          self.append_location_csv_file(idx,LOC,timestep,CDS);
        catch ERR
          if DeBug, cws.errTrace(ERR); end
          fprintf(2,'Location: %s\t\tFailed to write to output files!\n',LOC.name);
          fprintf(2,'          %s',ERR.message);
        end
      end
      cws.logger('exit  postResult');
      % END OF POSTRESULT -----------------------------------------------------
    end
    
    function self = initialize_files( self , LOC , CDS)
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      PFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.prb.csv']);
      EFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.evt.csv']);
      RFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.res.csv']);
      DFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.raw.csv']);
      CFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.cls.csv']);
      
      if ~strcmpi(self.output_type,'file') && ~strcmpi(self.output_type,'files'),
        return;
      end
      PFID = fopen(PFilename,'wt');
      fprintf(PFID,'%s','TIME_STEP');
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(PFID,',{%s}_{%d}(%f) BED(%d)(%f)_{%f}^{%d}',LOC.algs(iAlg).type,...
            LOC.algs(iAlg).n_h,LOC.algs(iAlg).tau_out(iTau),...
            LOC.algs(iAlg).n_bed,LOC.algs(iAlg).p_out,LOC.algs(iAlg).tau_evt,...
            LOC.algs(iAlg).n_eto);
        end
      end
      fprintf(PFID,'\n');
      fprintf(PFID,'%s',LOC.name);
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(PFID,',%s','PROBABILITY');
        end
      end
      fprintf(PFID,'\n');
      fclose(PFID);
      
      EFID = fopen(EFilename,'wt');
      fprintf(EFID,'%s','TIME_STEP');
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(EFID,',{%s}_{%d}(%f) BED(%d)(%f)_{%f}^{%d}',LOC.algs(iAlg).type,...
            LOC.algs(iAlg).n_h,LOC.algs(iAlg).tau_out(iTau),...
            LOC.algs(iAlg).n_bed,LOC.algs(iAlg).p_out,LOC.algs(iAlg).tau_evt,...
            LOC.algs(iAlg).n_eto);
        end
      end
      fprintf(EFID,'\n');
      fprintf(EFID,'%s',LOC.name);
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(EFID,',%s','EVENT CODE');
        end
      end
      fprintf(EFID,'\n');
      fclose(EFID);
      
      CFID = fopen(EFilename,'wt');
      fprintf(CFID,'%s','TIME_STEP');
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(CFID,',{%s}_{%d}(%f) BED(%d)(%f)_{%f}^{%d},,,,,',LOC.algs(iAlg).type,...
            LOC.algs(iAlg).n_h,LOC.algs(iAlg).tau_out(iTau),...
            LOC.algs(iAlg).n_bed,LOC.algs(iAlg).p_out,LOC.algs(iAlg).tau_evt,...
            LOC.algs(iAlg).n_eto);
        end
      end
      fprintf(CFID,'\n');
      fprintf(CFID,'%s',LOC.name);
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(CFID,',CLUSTID1,CLUSTID2,CLUSTID3,CLUSTP1,CLUSTP2,CLUSP3');
        end
      end
      fprintf(CFID,'\n');
      fclose(CFID);
      
      RFID = fopen(RFilename,'wt');
      fprintf(RFID,'%s','TIME_STEP');
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(RFID,',{%s}_{%d}(%f) BED(%d)(%f)_{%f}^{%d}',LOC.algs(iAlg).type,...
            LOC.algs(iAlg).n_h,LOC.algs(iAlg).tau_out(iTau),...
            LOC.algs(iAlg).n_bed,LOC.algs(iAlg).p_out,LOC.algs(iAlg).tau_evt,...
            LOC.algs(iAlg).n_eto);
          for iSig = 2:length(LOC.sigids)
            fprintf(RFID,',');
          end
        end
      end
      fprintf(RFID,'\n');
      fprintf(RFID,'%s',LOC.name);
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          for iSig = 1:length(LOC.sigids)
            fprintf(RFID,',%s',char(LOC.sigids{iSig}));
          end
        end
      end
      fprintf(RFID,'\n');
      fclose(RFID);
      
      DFID = fopen(DFilename,'wt');
      fprintf(DFID,'%s','TIME_STEP');
      for iSig = 1:length(LOC.sigids)
        fprintf(DFID,',%s',char(CDS.scadatags{LOC.sigs(iSig)}));
      end
      fprintf(DFID,'\n');
      fprintf(DFID,'%s',LOC.name);
      for iSig = 1:length(LOC.sigids)
        fprintf(DFID,',%s',char(LOC.sigids{iSig}));
      end
      fprintf(DFID,'\n');
      fclose(DFID);
      % END OF INITIALIZEFILES ------------------------------------------------
    end
    
    function self = initializeInput( self , varargin )
      %INITIALIZE Summary of this function goes here
      %   Detailed explanation goes here
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Input'); end;
      if ~self.isused,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.input_type),
        self.input_type = self.conn_type;
      end
      [path,file,ext] = fileparts(self.conn_url);
      try
        finfo(fullfile(path,[file ext]));
      catch E1
        path = fullfile(self.data_dir_path,path);
        try
          finfo(fullfile(path,[file ext]));
        catch E2
          error('CANARY:datasource:csv','Cannot find file! %s',[path,file,ext]);
        end
      end
      self.conn_url = fullfile(path , [ file , ext]);
      self.IsInpInit = true;
      % END OF INITIALIZEINPUT ------------------------------------------------
    end
    
    function self = initializeOutput( self , varargin )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if DeBug, cws.trace('','Initializing Output'); end;
      if ~self.isused || ~self.IsOutput,
        if DeBug, cws.trace('DataSource','Unused - exiting'); end;
        return;
      end
      if ~self.IsConnected,
        self.connect();
      end
      if isempty(self.output_type)
        self.output_type = self.conn_type;
      end
      if self.IsOutInit,
        return;
      end
      [path,file,ext] = fileparts(self.conn_url);
      if isempty(path) || isempty(self.conn_url),
        path = self.data_dir_path;
      end
      if ~isdir(path) && isdir(fullfile(self.data_dir_path,path))
        path = fullfile(self.data_dir_path,path);
      end
      if ~isdir(path) && ~isempty(path),
        mkdir(path)
      end
      self.data_dir_path = path;
      if ~isempty(file)
        self.conn_url = [file '.'];
      else
        self.conn_url = '';
      end
      self.IsOutInit = true;
      % END OF INITIALIZEOUTPUT -----------------------------------------------
    end
    
    % END OF PUBLIC METHODS ===============================================
  end
  
  methods ( Access = 'private' ) % +++++++++++++++++++++++++++++++++++++++
    
    function append_location_csv_file( self , idx , LOC , ts , CDS )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      PFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.prb.csv']);
      EFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.evt.csv']);
      RFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.res.csv']);
      DFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.raw.csv']);
      CFilename = fullfile(self.data_dir_path,[self.conn_url LOC.name '.cls.csv']);
      
      PFID = fopen(PFilename,'at');
      EFID = fopen(EFilename,'at');
      RFID = fopen(RFilename,'at');
      DFID = fopen(DFilename,'at');
      CFID = fopen(CFilename,'at');
      
      fprintf(PFID,'%s',ts);
      fprintf(EFID,'%s',ts);
      fprintf(RFID,'%s',ts);
      fprintf(DFID,'%s',ts);
      fprintf(CFID,'%s',ts);
      nSigs = length(LOC.sigids);
      fmt = repmat(',%f',[1 nSigs]);
      
      for iAlg = 1:length(LOC.algs)
        for iTau = 1:length(LOC.algs(iAlg).tau_out)
          fprintf(PFID,',%f',LOC.algs(iAlg).eventprob(idx,1,iTau));
          fprintf(EFID,',%d',LOC.algs(iAlg).eventcode(idx,1,iTau));
          fprintf(CFID,',%d,%d,%d,%f,%f,%f',LOC.algs(iAlg).cluster_ids(idx,1),...
            LOC.algs(iAlg).cluster_ids(idx,2),...
            LOC.algs(iAlg).cluster_ids(idx,3),...
            LOC.algs(iAlg).cluster_probs(idx,1),...
            LOC.algs(iAlg).cluster_probs(idx,2),...
            LOC.algs(iAlg).cluster_probs(idx,3));
          fprintf(RFID,fmt,LOC.algs(iAlg).residuals(idx,:,iTau));
        end
      end
      fprintf(DFID,fmt,CDS.values(idx,LOC.sigs));
      
      fprintf(PFID,'\n');
      fprintf(EFID,'\n');
      fprintf(RFID,'\n');
      fprintf(DFID,'\n');
      fprintf(CFID,'\n');
      
      fclose(PFID);
      fclose(EFID);
      fclose(RFID);
      fclose(DFID);
      fclose(CFID);
      % END OF APPEND_LOCATION_CSV_FILE ---------------------------------------
    end
    
    function self = read_csvfile ( self , varargin )
      %READ_CSVFILE Input data from a CSV file input source
      %   This function reads two different types of CSV formatted data files as input
      %   to canary. It relies on the specific location LocData, which is the main
      %   CData.(LOCATION) data structure. The format is determined by the content of
      %   the first entry in the CSV file. The two different data formats are
      %   column-based and row-based.
      %
      %   Column-based entries are of the following format:
      %     TIME_STEP            SCADA_ID1  SCADA_ID2  SCADA_ID3  SCADA_ID4 ...
      %     yyyy-mm-dd HH:MM:SS  5.43        92.484    1.1        9.32      ...
      %         ...                ...        ...        ...        ...     ...
      %
      %   Where the SCADA_IDs must match with the IDs listed in the configuration
      %   file.  There is one exception, and that is an ID called "TRUE_EVENT", which
      %   is ignored by CANARY, and is added to the events section rather than the
      %   data section. It is only used in post-processing.
      %
      % See also
      %
      % Example
      %
      % Copyright 2008 Sandia Corporation
      %
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin<3,
        filename = self.conn_url;
      else
        filename = varargin{2};
      end
      cws.logger('enter read_csvfile');
      CDS = varargin{1};
      if strcmpi(self.run_mode,'batch')
        if isempty(self.fileCache)
          b_readData = true;
          b_saveData = true;
        else
          b_readData = false;
          b_saveData = false;
        end
      else
        b_readData = true;
        b_saveData = false;
      end
      if b_readData
        % Open the file and verify that it has a header line
        fid = fopen(filename);
        if fid < 1,
          [fid,message] = fopen(fullfile(self.data_dir_path,[filename,'csv']));
          if fid < 1,
            error('CANARY:datasource:csv','%s: %s',message,filename);
          end
        end
        hline = fgetl(fid);
        fclose(fid);
        % data = CDS % This is a handle to the SignalData Object
        % tcfg = self.time % This is a handle to the cws.Timing Object
        % Process header line
        formatstr = '';
        params = textscan(hline,'%s','Delimiter',',');
        params = params{1};
        NF = length(params);
        tsfield = self.timestep_field;
        fldID = 1;
        fldDetect = 0;
        fldProb = 0;
        spltDateTime = false;
        fldDateTime = 0;
        fldDate = 0;
        fldTime = 0;
        NewDataFlds = [];
        ColIDs = [];
        ColDataIDs = {};
        fldKnownEvent = 0;    % known event field index, if it exists
        cols(1:NF) = struct('n','','cid',[]);
        for i = 1:NF,
          switch lower(params{i})
            case {'time_step'}
              spltDateTime = false;
              formatstr = [formatstr,'%s'];
              fldDateTime = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            case {'date'}
              spltDateTime = true;
              formatstr = [formatstr,'%s'];
              fldDate = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            case {'time'}
              spltDateTime = true;
              formatstr = [formatstr,'%s'];
              fldTime = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            case {'event'}
              % This case added by S. Martin, 1/10/2008
              % The purpose of this case is to create a new .e.known
              % substructure for data with known results, to be used
              % for assessing various event detection algorithms
              formatstr = [formatstr,'%f'];
              fldKnownEvent = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            case {'analysis_comments'}
              formatstr = [formatstr,'%*s'];
            case {'contributing_parameters'}
              formatstr = [formatstr,'%s'];
              fldID = fldID + 1;
            case {'detection_indicator'}
              formatstr = [formatstr,'%n'];
              fldDetect = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            case {'detection_probability'}
              formatstr = [formatstr,'%n'];
              fldProb = fldID;
              cols(fldID).n = params{i};
              cols(fldID).cid = inf;
              fldID = fldID + 1;
            otherwise
              if strcmp(params{i},tsfield),
                spltDateTime = false;
                formatstr = [formatstr,'%s'];
                fldDateTime = fldID;
                cols(fldID).n = params{i};
                cols(fldID).cid = inf;
                fldID = fldID + 1;
              else
                par = char(params{i});
                cid = CDS.getSignalID(par);
                %             if ~isempty(cid)
                %               cid = cid(1);
                %             end
                fids = repmat(fldID,size(cid));
                if isempty(cid);
                  usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj',...
                    'Unknown signal in CSV file','warn',par);
                  %disp(usrmsg);
                  formatstr = [formatstr,'%*f'];
                else
                  formatstr = [formatstr,'%f'];
                  NewDataFlds = [ NewDataFlds , fids' ];
                  ColIDs = [ ColIDs , cid' ];
                  cols(fldID).n = par;
                  cols(fldID).cid = cid;
                  fldID = fldID + 1;
                end
              end
          end
        end
        % Read in the data
        fid = fopen(filename);
        if fid < 1,
          [fid,message] = fopen(fullfile(self.data_dir_path,[filename,'csv']));
          if fid < 1,
            error('CANARY:datasource:csv','%s: %s',message,filename);
          end
        end
        newData = textscan(fid,formatstr, ...
          'Delimiter',    ',', ...
          'TreatAsEmpty', {'NA','na','null'}, ...
          'EmptyValue',   0 ,...
          'HeaderLines',  1 );
        fclose(fid);
        date_fmt = self.conn_toDateFmt;
        if spltDateTime
          tsDLst = newData{fldDate};
          tsTLst = newData{fldTime};
          tsNums = floor(datenum(tsDLst));
          tsNums = tsNums + rem(datenum(tsTLst),1);
        elseif ~isempty(date_fmt)
          tsList = newData{fldDateTime};
          tsNums = datenum(tsList,date_fmt);
        else
          tsList = newData{fldDateTime};
          try
            tsNums = datenum(tsList);
          catch ERR
            tsNums = datenum(tsList,self.time.date_fmt);
          end
        end
      else % We have data in the file cache
        date_fmt = self.conn_toDateFmt;
        tsNums = self.fileCache.tsNums;
        newData = self.fileCache.newData;
        ColIDs = self.fileCache.ColIDs;
        NewDataFlds = self.fileCache.NewDataFlds;
      end
      
      if b_saveData,
        self.fileCache = struct('tsNums',{tsNums},'newData',{newData},...
          'ColIDs',{ColIDs},'NewDataFlds',{NewDataFlds});
      end
      
      if isempty(self.time.date_start)
        self.time.set_date_start(tsNums(1));
      end
      if isempty(date_fmt), date_fmt = self.conn_toDateFmt; end;
      if isempty(date_fmt), date_fmt = self.time.date_fmt; end
      if isempty(date_fmt), date_fmt = 'yyyy-mm-dd HH:MM:SS'; end;
      if ~isempty(self.time.date_end) && min(tsNums) > self.time.date_end
        usrmsg = cws.Message('to',upper(self.input_id),'from','INPUT','subj',...
          'Terminating CSV read','warn','Data times out of range');
        disp(usrmsg);
        tsNums = self.time.date_end;
        RowIDs = 1 + round((tsNums - self.time.date_start).*self.time.date_mult);
        CDS.values(RowIDs,ColIDs) = nan;
        timesteps = (0:size(CDS.values,1)-1) ./ self.time.date_mult;
        timesteps = timesteps + self.time.date_start;
        CDS.timesteps = cellstr(datestr(timesteps,date_fmt));
        return
      end
      maxRowID = 1 + round((self.time.date_end - self.time.date_start).*self.time.date_mult);
      RowIDs = 1 + round((tsNums - self.time.date_start).*self.time.date_mult);
      SelRows = RowIDs(RowIDs>0&RowIDs<maxRowID);
      for ii = 1:length(ColIDs);
        Did = ColIDs(ii);
        Fid = NewDataFlds(ii);
        if ~isempty(CDS.alarmvalue{Did})
          va = str2double(CDS.alarmvalue{Did});
          vn = str2double(CDS.alarmnormal{Did});
          vals = newData{Fid};
          vals(vals==va) = nan;
          vals(~isnan(vals)) = 0;
          vals(vals==vn) = 0;
          newData{Fid} = vals;
        end
      end
      vals = [newData{NewDataFlds}];
      CDS.values(SelRows,ColIDs) = vals(RowIDs>0&RowIDs<maxRowID,:);
      idx0 = max(min(RowIDs),1);
      idx1 = min(max(RowIDs),maxRowID);
      self.evalComposites(CDS, idx0, idx1);
      cws.logger('exit  read_csvfile');
    end
    
    % END OF PRIVATE METHODS ==============================================
  end
  
  % END OF CLASSDEF DATASOURCE ============================================
end
