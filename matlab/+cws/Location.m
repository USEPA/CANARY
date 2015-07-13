classdef Location < handle
  %LOCATIONDATA Handle subclass that stores location specific data (results, etc.)
  %
  % CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
  %
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
  %
  %   Each location has different data that is unique only to itself,
  %   specifically, the algorithms it uses and the results from those algorithms.
  %   The raw data may actually be used in more than one location, especially in
  %   terms of operational data. Therefore, the raw data values are not stored in
  %   this LOCATIONDATA object, but in the SIGNALDATA object that references it.
  %
  %   Because this class is a HANDLE subclass, it is refered to by reference, and
  %   only one copy will exist inside CANARY's view at any one time. Conversely,
  %   the data it references will not be deleted due to a "RESTART location"
  %   message, but will instead be cleared (but not deallocated).
  %
  %   The LOCATIONDATA class also has very little in terms of processing methods.
  %   Most methods associated with this class are for adding or updating
  %   configurations, while algorithm processing is more closely aligned to the
  %   SIGNALDATA class.
  %
  % See also LocationData/start, LocationData/restart, LocationData/stop,
  %       LocationData/addSignal, LocationData/addAlgorithm,
  %       LocationData/addOutputID, LocationData/addInputID
  %
  % Copyright 2008 Sandia Corporation
  
  properties % Public properties
    name = '';% Name of this location
    state = -1;% Current state (see evaluate_timestep)
    sigs % Array of signal ID numbers
    sigids = {};
    calib % Array of calibration signal ID numbers
    algs = struct(); % Algorithm data structure
    algids = []; % Algorithm ID strings
    lastIdxEvaluated = 0; % Last point evaluated
    lastIdxPosted = 0;
    isstarted = false; % Have we received a "START location" message?
    isstopped = false; % Have we received a "STOP location" message?
    useInputIds = []; % Which inputs does this location use?
    useOutputIds = []; % Which outputs does this location use?
    stationNum = 0;
    output_tag = '';
    output_ptnum = 0;
    libsigs = [];
    curTSIdx = -1;
    curIdxDate = '';
    output_sigs = [1 1 1 1 1 1 1 1 1];
    sigvals = [];
    loc_state = 'enabled';
    eventList = {};
    patListDir = 'PatternList';
    patGrfxDir = 'Patterns';
    deltasLib = [];
    libraryFile = '';
    p_warn_thresh = 0.5;
    quality = [];
  end
  
  methods % Public methods
    
    function printEvents( self)
      for i = 1:length(self.eventList)
        self.eventList{i}.plotEvent();
      end
    end
    
    function saveAs( self, filename, format, timesteps)
      filename = strcat(filename,self.name);
      switch lower(format)
        case {'csv'}
          FID = fopen([filename,'-summary.csv'],'wt');
          fprintf(FID,'TIME_STEP,IDX,');
          for i = 1:length(self.algs)
            fprintf(FID,'ALG_%d-P_Event,ALG_%d-Status,',i,i);
          end
          fprintf(FID,'\n');
          for j = 1:min(self.lastIdxEvaluated,length(timesteps))
            fprintf(FID,'%s,%d,',char(timesteps(j,:)),j);
            for i = 1:length(self.algs)
              fprintf(FID,'%f,%d,',self.algs(i).eventprob(j),self.algs(i).eventcode(j));
            end
            fprintf(FID,'\n');
          end
          fclose(FID);
          for i = 1:length(self.algs)
            FID = fopen(sprintf('%s-details-alg_%d.csv',filename,i),'wt');
            fprintf(FID,'TIME_STEP,IDX,P_Event,Status,');
            fprintf(FID,'Clust_ID-1,Clust_Prob-1,Clust_ID-2,Clust_Prob-2,Clust_ID-3,Clust_Prob-3,');
            for k = 1:length(self.sigids)
              fprintf(FID,'"Contrib_{%s}",',self.sigids{k});
            end
            for k = 1:length(self.sigids)
              fprintf(FID,'"Resid_{%s}",',self.sigids{k});
            end
            fprintf(FID,'"Comments",\n');
            for j = 1:length(timesteps)
              fprintf(FID,'"%s",%d,%f,%d,',char(timesteps(j,:)),j,self.algs(i).eventprob(j),self.algs(i).eventcode(j));
              if self.algs(i).use_cluster
                for k = 1:3
                  fprintf(FID,'%d,%f,',self.algs(i).cluster_ids(j,k),self.algs(i).cluster_probs(j,k));
                end
              else
                fprintf(FID,'nan,nan,nan,nan,nan,nan,');
              end
              for k = 1:length(self.sigids)
                fprintf(FID,'%d,',self.algs(i).event_contrib(j,k));
              end
              for k = 1:length(self.sigids)
                fprintf(FID,'%f,',self.algs(i).residuals(j,k));
              end
              if length(self.algs(i).comments) >= j,
              fprintf(FID,'"%s",\n',self.algs(i).comments{j});
              else
              fprintf(FID,'"%s",\n','');
              end
            end
            fclose(FID);
          end
      end
    end
    
    function str = printYAML(self, SIGS, DSRCS)
      if strcmpi(self.output_tag,'')
        self.output_tag = self.name;
      end
      str = sprintf('- id: %s\n  station id number: %s\n  station tag name: %s\n  location id number: %d\n  enabled: %s\n',...
        self.name, self.output_ptnum, self.output_tag, self.stationNum, ...
        yaml.bool2str(strcmpi(self.loc_state,'enabled'),'yn'));
      if ~isempty(self.libraryFile)
        str = sprintf('%s  pattern library: %s\n',self.libraryFile);
      end
      str = sprintf('%s  inputs:\n',str);
      for i = 1:length(self.useInputIds)
        str = sprintf('%s    - id: %s\n',str,DSRCS(self.useInputIds(i)).handle.conn_id);
      end
      str = sprintf('%s  outputs:\n',str);
      for i = 1:length(self.useOutputIds)
        str = sprintf('%s    - id: %s\n',str,DSRCS(self.useOutputIds(i)).handle.conn_id);
      end
      str = sprintf('%s  signals:\n',str);
      for i = 1:length(self.calib)
        str = sprintf('%s    - id: %s\n',str,SIGS.names{self.calib(i)});
      end
      for i = 1:length(self.sigs)
        if self.libsigs(i) == 1,
          str = sprintf('%s    - id: %s\n',str,SIGS.names{self.sigs(i)});
        else
          str = sprintf('%s    - id: %s\n      cluster: no\n',str,SIGS.names{self.sigs(i)});
        end
      end
      str = sprintf('%s  algorithms:\n',str);
      for i = 1:length(self.algids)
        str = sprintf('%s    - id: %s\n',str,SIGS.algorithms.short_id{self.algids(i)});
      end
    end
    
    function list = PrintAsXML( self , SIGS , DSRCS )
      list = cell(length(self.sigs)+length(self.calib)+length(self.algids)+...
        length(self.useInputIds)+length(self.useOutputIds)+2,1);
      list(1) = {self.PrintLocationAsXML()};
      list(end) = {'  </location>'};
      ct = 2;
      for i = 1:length(self.useInputIds)
        list(ct) = {sprintf('   <use-input id="%s" />',DSRCS(self.useInputIds(i)).handle.conn_id)};
        ct = ct + 1;
      end
      for i = 1:length(self.useOutputIds)
        list(ct) = {sprintf('   <use-output id="%s" />',DSRCS(self.useOutputIds(i)).handle.conn_id)};
        ct = ct + 1;
      end
      for i = 1:length(self.calib)
        list(ct) = {sprintf('   <use-signal id="%s" />',SIGS.names{self.calib(i)})};
        ct = ct + 1;
      end
      for i = 1:length(self.sigs)
        if self.libsigs(i) == 1,
          list(ct) = {sprintf('   <use-signal id="%s" />',SIGS.names{self.sigs(i)})};
        else
          list(ct) = {sprintf('   <use-signal id="%s" no-cluster="true" />',SIGS.names{self.sigs(i)})};
        end
        ct = ct + 1;
      end
      for i = 1:length(self.algids)
        list(ct) = {sprintf('   <use-algorithm id="%s" />',SIGS.algorithms.short_id{self.algids(i)})};
        ct = ct + 1;
      end
    end
    
    
    function self = shiftDate( self , shift )
      %SHIFTDATE( shift )
      % Moves all data back by one SHIFT amount
      %
      % self.lastIdxEvaluated = self.lastIdxEvaluated <-- shift
      % self.curTSIdx = self.curTSIdx <-- shift
      % foreach alg in self.algs
      %  alg.residuals <-- shift
      %  alg.eventprob <-- shift
      %  alg.eventcode <-- shift
      %  alg.event_contrib <-- shift
      %  alg.comments <-- shift
      %  alg.cluster_probs <-- shift
      %  alg.cluster_ids <-- shift
      %
      cws.logger('enter Location.shiftDate');
      Cshift = [shift 0 0 ];
      for iA = 1:length(self.algs)
        self.algs(iA).residuals = circshift(self.algs(iA).residuals,Cshift);
        self.algs(iA).eventprob = circshift(self.algs(iA).eventprob,Cshift);
        self.algs(iA).eventcode = circshift(self.algs(iA).eventcode,Cshift);
        self.algs(iA).event_contrib = circshift(self.algs(iA).event_contrib,Cshift);
        % self.algs(iA).comments = circshift(self.algs(iA).comments,shift);
        self.algs(iA).cluster_probs = circshift(self.algs(iA).cluster_probs,Cshift);
        self.algs(iA).cluster_ids = circshift(self.algs(iA).cluster_ids,Cshift);
        self.algs(iA).residuals(max(end+shift+1,1):end,:,:) = 0;
        self.algs(iA).eventprob(max(end+shift+1,1):end,:,:) = 0;
        self.algs(iA).eventcode(max(end+shift+1,1):end,:,:) = 0;
        self.algs(iA).event_contrib(max(end+shift+1,1):end,:,:) = 0;
        self.algs(iA).cluster_probs(max(end+shift+1,1):end,:,:) = 0;
        self.algs(iA).cluster_ids(max(end+shift+1,1):end,:,:) = 0;
      end
      self.lastIdxEvaluated = self.lastIdxEvaluated + shift;
      self.curTSIdx = self.curTSIdx + shift;
      cws.logger('exit  Location.shiftDate');
    end
    
    function self = loadData( self , NewLoc , MyLastIdx , AddStartIdx, AddLastIdx )
      for iA = 1:length(self.algs)
        self.algs(iA).residuals = cat(1,self.algs(iA).residuals(1:MyLastIdx,:,:),NewLoc.algs(iA).residuals(AddStartIdx:AddLastIdx,:,:));
        self.algs(iA).eventprob = cat(1,self.algs(iA).eventprob(1:MyLastIdx,:,:),NewLoc.algs(iA).eventprob(AddStartIdx:AddLastIdx,:,:));
        self.algs(iA).eventcode = cat(1,self.algs(iA).eventcode(1:MyLastIdx,:,:),NewLoc.algs(iA).eventcode(AddStartIdx:AddLastIdx,:,:));
        self.algs(iA).cluster_probs = cat(1,self.algs(iA).cluster_probs(1:MyLastIdx,:,:),NewLoc.algs(iA).cluster_probs(AddStartIdx:AddLastIdx,:,:));
        self.algs(iA).cluster_ids = cat(1,self.algs(iA).cluster_ids(1:MyLastIdx,:,:),NewLoc.algs(iA).cluster_ids(AddStartIdx:AddLastIdx,:,:));
        self.algs(iA).event_contrib = cat(1,self.algs(iA).event_contrib(1:MyLastIdx,:,:),NewLoc.algs(iA).event_contrib(AddStartIdx:AddLastIdx,:,:));
      end
      self.eventList = NewLoc.eventList;
      self.lastIdxEvaluated = MyLastIdx + AddLastIdx - AddStartIdx;
      self.curTSIdx = MyLastIdx + AddLastIdx - AddStartIdx;
    end
    
    function str = PrintLocationAsXML( self )
      str = sprintf('  <location scada-id="%s" output_Station="%d" output_TagName="%s" output_PointNr="%s" state="%s" patListDir="%s" patGraphicsDir="%s" >',...
        self.name, self.stationNum, self.output_tag, self.output_ptnum, ...
        self.loc_state, self.patListDir, self.patGrfxDir);
    end
    
    function printPatternListFile( self , filename )
      if nargin < 2, filename = ['PATT_LIST_',self.name,'.txt'];
      end
      FID = fopen(filename,'wt');
      
      fclose(FID);
    end
    
    function createSummaryStats( self , CDS , filename , mode )
      if nargin < 3,
        mode = 'wt';
        filename = [self.name,'.txt'];
      elseif nargin < 4,
        mode = 'wt';
      end
      if length(mode) < 2,
	mode = [mode 't'];
      end
      FID = fopen(filename,mode);
      % Configuration Details
      fprintf(FID,'= Run Report = \n');
      fprintf(FID,'\n=== Configuration === \n');
      fprintf(FID,'%s\t%s\n',' * StationName:',self.name);
      fprintf(FID,'%s\t%s\n',...
        ' * NumAlgorithms:',num2str(size(self.algs,2)));
      for i = 1:size(self.algs,2)
        fprintf(FID,'%s\t%-5s\t%s\n',...
          ' * Algorithm:',self.algs(i).type,CDS.algorithms.short_id{self.algids(i)});
      end
      fprintf(FID,'%s\t%s\n',...
        ' * NumSignals:',num2str(size(self.sigs,2)));
      for i = 1:size(self.sigs,2)
        fprintf(FID,'%s\t%-5s\t%s\n',...
          ' * Signal:',self.sigids{i},CDS.names{self.sigs(i)});
      end
      % Summary Statistics
      fprintf(FID,'\n=== Summary === \n');
      EL = [ self.eventList{:} ];
      fprintf(FID,' * %s\t%d days %.2f hours\n','RunDuration:',floor((CDS.time.date_end+1/CDS.time.date_mult) - CDS.time.date_start),mod((CDS.time.date_end+1/CDS.time.date_mult) - CDS.time.date_start,1)*24);
      if isempty(EL),
        fprintf(FID,' * %s\t%d\n','TotalEvents:',0);
      else
        ETO = strcmp({EL.termCause},'ETO');
        RTN = strcmp({EL.termCause},'RTN');
        PAT = strcmp({EL.termCause},'PAT');
        EFP = strcmp({EL.termCause},'EFP');
        fprintf(FID,' * %s\t%d\n','TotalEvents:',sum(ETO)+sum(RTN)+sum(EFP)+sum(PAT));
        fprintf(FID,' * %s\t%d\n','TotalEventAlarms:',sum(ETO)+sum(RTN)+sum(EFP));
        if sum(RTN) == 0,
          durRTN = [];
        else
          durRTN = [EL(RTN).duration];
        end
        if sum(ETO) == 0,
          durETO = [];
        else
          durETO = [EL(ETO).duration];
        end
        if sum(EFP) == 0,
          durEFP = [];
        else
          durEFP = [EL(EFP).duration];
        end
        if sum(PAT) == 0,
          durPAT = [];
        else
          durPAT = [EL(PAT).duration];
        end
        fprintf(FID,' * %s\t%.1f minutes\n','AveAlarmDuration:',...
          mean([durRTN durETO durEFP]+1)*24*60/CDS.time.date_mult);
        fprintf(FID,' * %s\t%d\n','UnmatchedEventAlarms:',sum(ETO)+sum(RTN));
        fprintf(FID,' * %s\t%d\n','AlarmsBecomeMatches:',sum(EFP));
        fprintf(FID,' * %s\t%.1f minutes\n','AveAlarmToMatchTime:',...
          mean(durEFP+1)*24*60/CDS.time.date_mult);
        fprintf(FID,' * %s\t%d\n','AlarmsBecomeTimeouts:',sum(ETO));
        fprintf(FID,' * %s\t%d\n','MatchedBeforeAlarm:',sum(PAT));
        fprintf(FID,' * %s\t%.1f minutes\n','AveMatchDuration:',...
          mean(durPAT+1)*24*60/CDS.time.date_mult);
        % Algorithm/PatterLibrary Specifics
        for i = 1:size(self.algs,2)
          algnum = self.algids(i);
          algid = CDS.algorithms.short_id{algnum};
          fprintf(FID,'\n----\n\n== Algorithm Specific == \n');
          fprintf(FID,' * Algorithm:\t%s\n',algid);
          EVTS = strcmp({EL.algDefID},algid);
          el2 = {self.eventList{EVTS}};
          EL2 = [self.eventList{EVTS}];
          if ~isempty(EL2)
            if ~isempty(self.algs(i).library) && isa(self.algs(i).library,'cws.ClusterLib')
              fprintf(FID,'\n=== Pattern Matching === \n');
              LIB = self.algs(i).library;
              nPat = LIB.clust.n_clusters{1};
              fprintf(FID,' * NumPatterns:\t%d\n',nPat);
              for j = 1:nPat
                fprintf(FID,' * Pattern%.3d:\t%s\t%3d matches\n',j,...
                  LIB.clust.cluster_ids{1}{j},...
                  sum(([EL2(:).patternId] == j)));
              end
            end
            fprintf(FID,'\n=== Contributing Signals === \n');
            nSig = size(self.sigs,2);
            for j = 1:nSig
              outlid = 1:length(EL2)*nSig;
              outliers = [EL2.outliers];
              incl = mod(outlid,nSig)==j;
              if j==nSig,
                incl = mod(outlid,nSig)==0;
              end
              if ~isempty(outliers)
                fprintf(FID,' * Signal%.3d:\t%s\t%3d events\n',...
                  j,self.sigids{j},sum(outliers(incl)>0));
              else
                fprintf(FID,' * Signal%.3d:\t%s\t%3d events\n',...
                  j,self.sigids{j},0);
              end
            end
            fprintf(FID,'\n=== Event Details and Contributing Signals === \n');
            fprintf(FID,'%s\n',EL2(1).getHeader());
            for j = 1:length(el2)
              fprintf(FID,'%s\n',el2{j}.toString(j));
            end
          end
        end
        % Event Details
      end
      fclose(FID);
    end

    function createSummaryYAML( self , CDS , filename , mode )
      if nargin < 3,
        mode = 'wt';
        filename = [self.name,'.yml'];
      elseif nargin < 4,
        mode = 'wt';
      end
      if length(mode) < 2,
          mode = [mode 't'];
      end
      FID = fopen(filename,mode);
      % Configuration Details
      fprintf(FID,'--- # Run Report\n');
      fprintf(FID,'configuration:\n');
      fprintf(FID,'  location id number: %d\n',self.stationNum);
      fprintf(FID,'  station tag name: %s\n',self.output_tag);
      fprintf(FID,'  station id number: %s\n',self.output_ptnum);
      fprintf(FID,'  algorithms:\n');
      for i = 1:size(self.algs,2)
        fprintf(FID,'  - id: %s\n',CDS.algorithms.short_id{self.algids(i)});
        fprintf(FID,'    type: %s\n',self.algs(i).type);
        fprintf(FID,'    history window: %d\n',self.algs(i).n_h);
        fprintf(FID,'    outlier threshold: %s\n',yaml.num2str(self.algs(i).tau_out));
        if self.algs(i).use_bed,
            fprintf(FID,'    BED:\n');
            fprintf(FID,'      windows: %s\n',yaml.num2str(self.algs(i).n_bed));
            fprintf(FID,'      outlier probability: %s\n',yaml.num2str(self.algs(i).tau_out));
        end
        fprintf(FID,'    event threshold: %s\n',yaml.num2str(self.algs(i).tau_evt));
        fprintf(FID,'    event timeout: %d\n',self.algs(i).n_eto);
        if self.algs(i).use_cluster
            fprintf(FID,'    clustering: on\n');
        end
        fprintf(FID,'    event window save: %d\n',self.algs(i).back_save);
      end
      fprintf(FID,'  signals:\n');
      for i = 1:size(self.sigs,2)
        fprintf(FID,'  - id: %s\n',CDS.names{self.sigs(i)});
        fprintf(FID,'    parameter type: %s\n',self.sigids{i});
      end
      % Summary Statistics
      fprintf(FID,'summary results:\n');
      EL = [ self.eventList{:} ];
      fprintf(FID,'  run duration: %d days %.2f hours\n',floor((CDS.time.date_end+1/CDS.time.date_mult) - CDS.time.date_start),mod((CDS.time.date_end+1/CDS.time.date_mult) - CDS.time.date_start,1)*24);
      if isempty(EL),
        fprintf(FID,'  total events: %d\n',0);
      else
        ETO = strcmp({EL.termCause},'ETO');
        RTN = strcmp({EL.termCause},'RTN');
        PAT = strcmp({EL.termCause},'PAT');
        EFP = strcmp({EL.termCause},'EFP');
        fprintf(FID,'  total events: %d # Including pattern matches\n',sum(ETO)+sum(RTN)+sum(EFP)+sum(PAT));
        if sum(RTN) == 0,
          durRTN = [];
        else
          durRTN = [EL(RTN).duration];
        end
        if sum(ETO) == 0,
          durETO = [];
        else
          durETO = [EL(ETO).duration];
        end
        if sum(EFP) == 0,
          durEFP = [];
        else
          durEFP = [EL(EFP).duration];
        end
        if sum(PAT) == 0,
          durPAT = [];
        else
          durPAT = [EL(PAT).duration];
        end
        fprintf(FID,'  total events duration: %.1f minutes # excluding started as match\n',...
          sum([durRTN durETO durEFP]+1)*24*60/CDS.time.date_mult);
        fprintf(FID,'  events by type:\n');
        fprintf(FID,'    ended by return to normal:\n');
        fprintf(FID,'      number: %d\n',sum(RTN));
        fprintf(FID,'      average duration (minutes): %.1f\n',mean(durRTN+1)*24*60/CDS.time.date_mult);
        fprintf(FID,'    ended by timeout:\n');
        fprintf(FID,'      number: %d\n',sum(ETO));
        fprintf(FID,'    changed to match:\n');
        fprintf(FID,'      number: %d\n',sum(EFP));
        fprintf(FID,'      average duration (minutes): %.1f\n',mean(durEFP+1)*24*60/CDS.time.date_mult);
        fprintf(FID,'    started as match:\n');
        fprintf(FID,'      number: %d\n',sum(PAT));
        fprintf(FID,'      average duration (minutes): %.1f\n',mean(durPAT+1)*24*60/CDS.time.date_mult);
        % Algorithm/PatterLibrary Specifics
        fprintf(FID,'algorithm specific results:\n');
        for i = 1:size(self.algs,2)
          algnum = self.algids(i);
          algid = CDS.algorithms.short_id{algnum};
          fprintf(FID,'- id: %s\n',algid);
          EVTS = strcmp({EL.algDefID},algid);
          el2 = {self.eventList{EVTS}};
          EL2 = [self.eventList{EVTS}];
          if ~isempty(EL2)
            if ~isempty(self.algs(i).library) && isa(self.algs(i).library,'cws.ClusterLib')
              fprintf(FID,'  pattern matching:\n');
              LIB = self.algs(i).library;
              nPat = LIB.clust.n_clusters{1};
              fprintf(FID,'    total number of matches: %d\n',nPat);
              for j = 1:nPat
                fprintf(FID,'    pattern %s: %3d\n',j,...
                  LIB.clust.cluster_ids{1}{j},...
                  sum(([EL2(:).patternId] == j)));
              end
            end
            fprintf(FID,'  signals contributed to n events:\n');
            nSig = size(self.sigs,2);
            for j = 1:nSig
              outlid = 1:length(EL2)*nSig;
              outliers = [EL2.outliers];
              incl = mod(outlid,nSig)==j;
              if j==nSig,
                incl = mod(outlid,nSig)==0;
              end
              if ~isempty(outliers)
                fprintf(FID,'    %s: %3d\n',...
                  self.sigids{j},sum(outliers(incl)>0));
              else
                fprintf(FID,'    %s: %3d\n',...
                  self.sigids{j},0);
              end
            end
            fprintf(FID,'  event summaries:\n');
            fprintf(FID,'  %s\n',EL2(1).getYmlHeader());
            for j = 1:length(el2)
              fprintf(FID,'  %s\n',el2{j}.toShortYAML(j));
            end
          end
        end
        % Event Details
      end
      fclose(FID);
    end

    
    function configureStation(self, HashMap, SIGS, DSRCS)
      if nargin < 3,
        noSigs = true;
        noDsrcs = true;
      elseif nargin < 4,
        noSigs = isempty(SIGS);
        noDsrcs = true;
      else
        noSigs = isempty(SIGS);
        noDsrcs = isempty(DSRCS);
      end
      try 
        if HashMap.containsKey('id')
          id = char(HashMap.get('id'));
        else
          error('tevaCanary:yamlConfig:missingField',...
            'Error - the following entry was missing the "id" field.\n  %s',...
            char(HashMap.toString()));
        end
        if ~strcmp(id,self.name),
          error('tevaCanary:yamlConfig:conflictingValue',...
            'Error - the following id value conflicts with the value of %s\n  %s',...
            self.name,char(HashMap.toString()));
        end
        keys = HashMap.keySet().toArray();
        for i = 1:length(keys)
          key = char(keys(i));
          val = HashMap.get(key);
          switch key
            case 'id'
            case {'StationNr','station location id','location id number'}
              num = HashMap.get(key);
              self.stationNum = num;
            case {'outputTag','station tag name'}
              self.output_tag = char(HashMap.get(key));
            case {'PointNr','station id number'}
              self.output_ptnum = num2str(HashMap.get(key));
            case {'enabled'}
              state = HashMap.get(key);
              if state,
                self.loc_state = 'enabled';
              else
                self.loc_state = 'disabled';
                warning('tevaCanary:yamlConfig:stationDisabled',...
                  'Warning - the following station was disabled: %s\n  %s',...
                  self.name,char(HashMap.toString()));
              end
            case {'patListDir','pattern directory'}
              self.patListDir = char(HashMap.get(key));
            case {'patGraphicsDir','pattern graphics'}
              self.patGrfxDir = char(HashMap.get(key));
            case {'pattern library'}
              self.libraryFile = char(HashMap.get(key));    
              self.deltasLib = cws.DeltasLibrary();
              self.deltasLib.configureFromFile(self.libraryFile);
              
            case {'signals'}
              if ~noSigs
                if ~isempty(HashMap.get(key))
                  ySigs = HashMap.get(key).toArray();
                  for ii = 1:length(ySigs)
                    sig = ySigs(ii);
                    if sig.containsKey('id');
                      sigId = char(sig.get('id'));
                    else
                      continue;
                    end
                    if sig.containsKey('cluster');
                      clustOff = ~(sig.get('cluster'));
                    else
                      clustOff = false;
                    end
                    self.addSignal(SIGS, sigId, clustOff);
                  end
                end
              end
            case {'algorithms'}
              if ~isempty(HashMap.get(key))
                yAlgs = HashMap.get(key).toArray();
                for ii = 1:length(yAlgs)
                  alg = yAlgs(ii);
                  if alg.containsKey('id');
                    algId = char(alg.get('id'));
                  else
                    continue;
                  end
                  self.addAlgorithm(SIGS, algId);
                end
              end
              
            case {'inputs'}
              if ~noDsrcs,
                if ~isempty(HashMap.get(key));
                  yInps = HashMap.get(key).toArray();
                  for ii = 1:length(yInps)
                    inp = yInps(ii);
                    if inp.containsKey('id')
                      inpnm = char(inp.get('id'));
                    end
                    inpid = strmatch(inpnm,{DSRCS(:).name},'exact');
                    if isempty(inpid),
                      inpid = [inpnm,'_in']; 
                      inpid = strmatch(inpid,{DSRCS(:).name},'exact');
                    end
                    if isempty(inpid),
                      warning('tevaCanary:yamlConfig:invalidValue',...
                        'Warning - the following station::input: value is invalid %s\n  %s',...
                        char(inpnm),char(HashMap.toString()));
                      continue
                    end
                    self.addInputID(inpid);
                    DSRCS(inpid).handle.useAsInput();
                    DSRCS(inpid).handle.use();
                  end
                end
              end
            case {'outputs'}
              if ~noDsrcs,
                if ~isempty(HashMap.get(key));
                  yOuts = HashMap.get(key).toArray();
                  for ii = 1:length(yOuts)
                    out = yOuts(ii);
                    if out.containsKey('id')
                      outnm = char(out.get('id'));
                    end
                    outid = strmatch(outnm,{DSRCS(:).name},'exact');
                    if isempty(outid),
                      outid = [outnm,'_in'];
                      outid = strmatch(outid,{DSRCS(:).name},'exact');
                    end
                    if isempty(outid),
                      warning('tevaCanary:yamlConfig:invalidValue',...
                        'Warning - the following station::output: value is invalid %s\n  %s',...
                        char(outnm),char(HashMap.toString()));
                      continue
                    end
                    self.addOutputID(outid);
                    DSRCS(outid).handle.useAsOutput();
                    DSRCS(outid).handle.use();
                  end
                end
              end
          end
        end
      catch ERR
        cws.errTrace(ERR);
        rethrow(ERR)
      end      
    end
    
    function self = Location( name )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin > 0,
        self.name = name;
      else
        name = '';
      end
      self.output_tag = [name, '_CNRY'];
      self.algs = struct('type','',...
        'mFile','','n_h',1,'tau_out',0,...
        'use_bed',true,'n_bed',1,'p_out',0.5,'tau_evt',1.0,'n_eto',1,...
        'window',[],'residuals',[],'eventprob',[],'eventcode',[],'bedwin',[],...
        'event_ct',[],'event_contrib',[],'setPtViol',[],'back_save',30,'comments',{},'report',false,...
        'use_cluster',false,'library','','cluster_probs',[],'cluster_ids',[],...
        'algs_in',[],'algJ',{});
      self.algs = self.algs(2:end);
    end
    
    
    function self = start( self , nData )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin < 2
        nData = 10000;
      end
      self.isstarted = true;
      self.isstopped = false;
      self.lastIdxEvaluated = 0;
      self.state = -1;
      self.quality = zeros(size(self.sigs));
      for iAlg = 1:length(self.algs)
        nSigs = length(self.sigs);
        nTaus = length(self.algs(iAlg).tau_out);
        if iAlg == length(self.algs),
          if ~isempty(self.deltasLib)
            self.algs(iAlg).use_cluster = true;
            self.algs(iAlg).library = self.deltasLib;
          end
        end
        if self.algs(iAlg).use_cluster,
          nSigsLoc = sum(self.libsigs);
          try
          nSigsLib = self.algs(iAlg).library.n_sigs;
          if nSigsLoc ~= nSigsLib,
            self.isstarted = true;
          %  self.algs(iAlg).use_cluster = false;
            warning('CANARY:librarysignalsmismatch',...
              'Number of signals in Library and Location do not match!\nLocation: %s\n',...
              self.name);
          end
          catch
          end
        end
        self.algs(iAlg).window = zeros(1,nSigs,nTaus);
        self.algs(iAlg).bedwin = zeros(self.algs(iAlg).n_bed,1,nTaus);
        self.algs(iAlg).residuals = zeros(nData,nSigs,nTaus);
        self.algs(iAlg).eventprob = zeros(nData,1,nTaus);
        self.algs(iAlg).cluster_probs = zeros(nData,3,nTaus);
        self.algs(iAlg).cluster_ids = zeros(nData,3,nTaus);
        self.algs(iAlg).eventcode = zeros(nData,1,nTaus,'int8');
        self.algs(iAlg).event_ct = zeros(1,1,nTaus);
        self.algs(iAlg).event_contrib = zeros(nData,nSigs,nTaus,'int8');
        self.algs(iAlg).setPtViol = zeros(1,nSigs,1,'int8');
        self.algs(iAlg).comments = cell(nData,1,1);
      end
    end
    
    
    function self = restart( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if ~self.isstarted || self.isstopped,
        self.start();
      else
        self.lastIdxEvaluated = 0;
        self.state = -1;
        for iAlg = 1:length(self.algs)
          nData = size(self.algs(iAlg).residuals,1);
          if nData < 10000, nData = 10000; end;
          nSigs = length(self.sigs);
          nTaus = length(self.algs(iAlg).tau_out);
          self.algs(iAlg).window = zeros(1,nSigs,nTaus);
          self.algs(iAlg).bedwin = zeros(self.algs(iAlg).n_bed,1,nTaus);
          self.algs(iAlg).residuals = zeros(nData,nSigs,nTaus);
          self.algs(iAlg).eventprob = zeros(nData,1,nTaus);
          self.algs(iAlg).cluster_probs = zeros(nData,3,nTaus);
          self.algs(iAlg).cluster_ids = zeros(nData,3,nTaus,'int8');
          self.algs(iAlg).eventcode = zeros(nData,1,nTaus,'int8');
          self.algs(iAlg).event_ct = zeros(1,1,nTaus);
          self.algs(iAlg).event_contrib = zeros(nData,nSigs,nTaus,'int8');
          self.algs(iAlg).setPtViol = zeros(1,nSigs,1,'int8');
          self.algs(iAlg).comments = cell(nData,1,1);
        end
      end
    end
    
    
    function self = stop( self )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      self.isstarted = false;
      self.isstopped = true;
      self.state = -2;
    end
    
    
    function self = addSignal( self, data, SigName , noClust )
      if nargin < 4, noClust = false; end;
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      SigID = data.getSignalID(SigName);
      if ~isempty(SigID)
        Type = data.sigtype(SigID);
        switch Type
          case {0}
            self.calib = [ self.calib , SigID ];
          case {1}
            self.sigs = [ self.sigs , SigID ];
            self.quality = [ self.quality , 0 ];
            self.sigids{end+1} = data.partype{SigID};
            self.sigvals(end+1) = data.getParameterNumericValue(data.partype{SigID});
            self.libsigs = [ self.libsigs , ~noClust ] ;
          case {2}
            self.sigs = [ self.sigs , SigID ];
            self.quality = [ self.quality , 0 ];
            self.sigids{end+1} = data.partype{SigID};
            self.sigvals(end+1) = data.getParameterNumericValue(data.partype{SigID});
            self.libsigs = [ self.libsigs , ~noClust ];
          otherwise
            warning('cws:Location',...
              'You do not need to list ALARM signals in <location> blocks');
        end
        if DeBug, cws.trace('',['Added signal: ',SigName,' to ',self.name]); end;
      else
        error('cws:Location',...
          'The signal "%s" is not a recognized signal.',SigName);
      end
    end
    
    
    function [ self , algid ] = addAlgorithm( self, data, short_id , report )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin < 4, report = true; end
      try
        [ alg , algid ] = data.algorithms.getAlgorithm(short_id,length(self.sigs));
        if ~isempty(alg.algJ) && (strcmpi(alg.type,'java') || strcmpi(alg.type,'external'))
          alg.algJ.set_data_register('AUTO_IGNORE',~(data.sigtype(self.sigs)==1));
          alg.algJ.set_data_register('SETPOINT_LIM_LOW',data.set_pt_lo(self.sigs));
          alg.algJ.set_data_register('SETPOINT_LIM_HIGH',data.set_pt_hi(self.sigs));
          alg.algJ.set_data_register('DATA_LIM_LOW',data.valid_min(self.sigs));
          alg.algJ.set_data_register('DATA_LIM_HIGH',data.valid_max(self.sigs));
          alg.algJ.set_data_register('CLUSTERIZABLE',self.libsigs==1);
          alg.algJ.set_data_register('DELTA_MIN',data.precision(self.sigs));
        end
        if ~any(self.algids==algid),
          prealgs = data.algorithms.getPreReqAlgs(short_id);
          if DeBug && ~isempty(prealgs), disp(prealgs); end;
          if ~isempty(alg)
            if ~isempty(prealgs),
              prealgs = cellstr(prealgs);
              for ii = 1:length(prealgs)
                [self,pid] = self.addAlgorithm(data,char(prealgs{ii}),false);
                alg.algs_in(end+1) = find(self.algids==pid,1);
              end
            end
            alg.report=report;
            self.algs(end+1) = alg;
            self.algids(end+1) = algid;
          end
        end
        if DeBug, cws.trace('',['Added algorithm: ',short_id,' to ',self.name]); end;
      catch ERR
        base_ME = MException('CANARY:errorAddingAlgorithm','Error occurred adding algorithm "%s"',short_id);
        new_ME = addCause(base_ME,ERR);
        cws.errTrace(new_ME);
        throw(new_ME);
      end
    end
    
    
    function self = updateConfig( self , data , filename )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin < 3, return; end;
      if isempty(filename), return; end;
      try
        fid  = fopen(filename,'r');
        if fid < 0,
          fprintf(2,'Error opening EDDIES parameter file: %s',filename);
          fprintf(1,'UpdateSettings: %s <-- %s\n',self.name,'FAILED');
          return;
        end
        fprintf(1,'UpdateSettings: %s <-- %s\n',self.name,filename);
        ct = 0;
        while 1
          line = fgetl(fid);
          if ~ischar(line),
            break
          else
            ct = ct + 1;
          end
          if DeBug, cws.trace('LINEIN',line);end
          pat = '\s*(?<tok>[^,]+)\s*,\s*(?<val>[^,]+)\s*';
          try
            dat = regexp(line,pat,'names');
            switch lower(dat.tok)
              case {'algorithm'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'type',dat.val );
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'mfile',dat.val );
              case {'threshold'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'tau_out',str2double(dat.val));
              case {'windowsize'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'n_h',str2double(dat.val) );
              case {'usebed'}
                dat.val = xml.bool(dat.val);
                if isnan(dat.val), data.val = 1; end;
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'use_bed',dat.val );
              case {'bed-windowmin'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'n_bed',str2double(dat.val) );
              case {'bed-windowmax'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'n_eto',str2double(dat.val) );
              case {'bed-proboutlier'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'p_out',str2double(dat.val) );
              case {'bed-probthresh'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'tau_evt',str2double(dat.val) );
              case {'clusterfile'}
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'use_cluster',true);
                data.algorithms.ModAlgorithmDef(['EDDIES_',self.name] , 'library',char(dat.val));
              otherwise
                warning('CANARY:updateConfigFromFile','Invalid parameter,value pairing: "%s" in file "%s:%d"',line,filename,ct);
            end
          catch
            warning('CANARY:updateConfigFromFile','Invalid parameter,value pairing: "%s" in file "%s:%d"',line,filename,ct);
          end
        end
        fclose(fid);
        [ alg , algid ] = data.algorithms.getAlgorithm(['EDDIES_',self.name]);
        MyAlgID = find(self.algids,algid,'first');
        if isempty(MyAlgID),
          self.algids(end+1) = algid;
          self.algs(end+1) = alg;
        else
          self.algids(MyAlgID) = algid;
          self.algs(MyAlgID) = alg;
        end
        msg = cws.Message('to','CANARY','subj','updated configuration from: ',...
          'from',self.name,'cont',filename);
        disp(msg);
      catch UPDerr
        base_ME = MException('CANARY:errorUpdatingFromFile','Error updating location "%s" from file "%s"',self.name,filename);
        cause_ME = MException('CANARY:errorUpdatingLocation','Error occurred modifying algorithm "%s" to location "%s"',['EDDIES_',self.name],self.name);
        new_ME = addCause(base_ME,cause_ME);
        new_ME = addCause(new_ME,UPDerr);
        cws.errTrace(new_ME);
        throw(new_ME);
      end
    end
    
    
    function self = addOutputID( self , idnum )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if isempty(self.useOutputIds)
        self.useOutputIds = idnum;
      else
        self.useOutputIds(end+1) = idnum;
      end
    end
    
    
    function self = addInputID( self , idnum )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if isempty(self.useInputIds)
        self.useInputIds = idnum;
      else
        self.useInputIds(end+1) = idnum;
      end
    end
    
  end
  
  
  methods % Conversion and builtins overloading
    %      function obj = saveobj( self )
    %        obj = struct(self);
    %      end
    
    
    function val = char( obj )
      val = char(obj.name);
    end
    
    
    function val = logical( obj )
      val = obj.isstarted;
    end
    
    
    function val = double( obj )
      val = obj.lastIdxEvaluated;
    end
    
    
    function F = plot( obj , algid )
      global DEBUG_LEVEL;
      DeBug = DEBUG_LEVEL;
      if nargin < 2
        algid = 1;
      end
      F = figure;
      subplot(2,1,1);
      plot(obj.algs(algid).eventprob(:,1,1));
      subplot(2,1,2);
      nv = size(obj.algs(algid).event_contrib,1);
      vv = repmat((-1:-1:0-length(obj.sigs)),[nv,1,1]);
      vv = vv .* abs(double(obj.algs(algid).event_contrib));
      a = plot(vv,'.','DisplayName',obj.sigids);
      legend(a,'Location','NorthOutside','Orientation','horizontal');
    end
  end
  % 
  %    methods (Static = true)
  %      function self = loadobj( obj )
  %        self = cws.Location(obj);
  %      end
  %    end
  
end
