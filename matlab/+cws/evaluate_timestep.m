%EVALUATE_TIMESTEP Execute the event detection algorithms
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
% Usage:
%       evaluate_timestep( index , SignalsObj , LocationObj , OutputList )
%
% Example:
%       evaluate_timestep( 1722 , CDS , CDS.locations(1).handle , OUTS )
%
function evaluate_timestep( idx , DATA , LOC , OUTPUTS )
  cws.logger('enter evaluate_timestep');
  warning off MATLAB:nearlySingularMatrix;
  cws.logger('CANARY',-1,'heartbeat.dat',true);
  global DEBUG_LEVEL;
  DeBug = DEBUG_LEVEL;
  import cws.*;
  if DeBug,
    %cws.trace('EVAL',['Entering Eval Timestep: ',num2str(idx)]);
  end
  PrevStatus = LOC.state;
  if PrevStatus == -2, return; end
  if idx < LOC.lastIdxEvaluated, return; end
  if LOC.lastIdxEvaluated < 1,
    LOC.lastIdxEvaluated = idx-1;
  end
  if LOC.curTSIdx > 0
    if idx > LOC.curTSIdx,
      cws.trace('CANARY:evaluateTimestep:noData',['Data for this location/date has not been received: ',LOC.name]);
      return;
    elseif LOC.lastIdxEvaluated < idx-1,
      cws.trace('CANARY:evaluateTimestep:catchup',['Data for this location needs catchup processing or you are using an EDSD as input: ',LOC.name]);
      for catchUpIdx = LOC.lastIdxEvaluated + 1:idx-1
        cws.evaluate_timestep( catchUpIdx , DATA , LOC , OUTPUTS )
        if mod(catchUpIdx,DATA.time.date_mult)==1,
          msg = cws.Message('from','EDS','to','',...
            'subj',['Processing old data for ',LOC.name,' @ ',DATA.timesteps{catchUpIdx}]);
          fprintf(2,'%s\n',char(msg));
        end
      end
    end
  end
  % use the new data to set the boolean state variables and to set up the new data
  % arrays for this timestep.  Do only once for all algorithms.
  newData = DATA.values(idx,DATA.datacol(LOC.sigs));
  if idx>1,
  lastData = DATA.values(idx-1,DATA.datacol(LOC.sigs));
  else
  lastData = DATA.values(idx,DATA.datacol(LOC.sigs));
  end
  delData = newData - lastData;
  newAlms = DATA.values(idx,DATA.alarm(LOC.sigs));
  newAlms(~(isnan(newAlms))) = 0;
  newCals = sum(DATA.values(idx,LOC.calib));
  newPrec = DATA.precision(1,LOC.sigs);
  suffChg = (abs(delData) >= newPrec)+0.0;
  newQual = DATA.quality(idx,LOC.sigs);
  LOC.quality = newQual;
  newIgnr = DATA.ignore(1,LOC.sigs);
  isOpData = DATA.sigtype(LOC.sigs) == 2;
  incIgnr = newIgnr;
  decIgnr = newIgnr;
  incIgnr(newIgnr == 2) = 1;
  decIgnr(newIgnr == 2) = -1;
  newIgnr(newIgnr == 2) = nan;
  % Clean out data that is out of hardware range, or is decreasing/increasing
  % inappropriately
  dataMin = DATA.valid_min(1,LOC.sigs);
  dataMax = DATA.valid_max(1,LOC.sigs);
  setptMin = DATA.set_pt_lo(1,LOC.sigs);
  setptMax = DATA.set_pt_hi(1,LOC.sigs);
  setPtOutlier = newData .* 0.0;
  setPtOutlier(newData > setptMax) = 1;
  setPtOutlier(newData < setptMin) = -1;
  setPtOutlier(newData<dataMin | newData>dataMax) = 0;
  
  newData(newData<dataMin | newData>dataMax) = nan;
  newAlms(isnan(newIgnr)) = nan;
  newAlms(isOpData) = nan;
  dataAve = newData .* 0;
  for iiTL = 1:length(LOC.sigs)
    tl = DATA.tracking_lag(LOC.sigs(iiTL));
    i1 = max([idx-5-tl 1]);
    i2 = max([idx-tl-1 1]);
    dataAve(1,iiTL) = nanmean(DATA.values(i1:i2,DATA.datacol(LOC.sigs(iiTL))));
  end
  dataDir = sign(newData - dataAve);
  dataDir( abs(newData - dataAve) <= newPrec(1,:,1) ) = 0;
  dataDir(dataDir==0) = nan;
  b_operationsEvent = (sum(dataDir == incIgnr)+sum(dataDir == decIgnr))>0;
  
  b_Calibration = isnan(newCals);
  missing = (newData == 0)+0;
  missing(missing==1) = nan;
  if isnan(nansum(newAlms+missing+newData)) || nansum(newAlms+missing+newData) == 0,
    b_AllSensMiss = true;
    DATA.values(idx,DATA.datacol(LOC.sigs)) = nan;
  else
    b_AllSensMiss = false;
  end
  if b_Calibration,
    newAlms(:) = nan;
  end
  save_AllSensMiss = b_AllSensMiss;
  
  % BEGIN PER-ALGORITHM LOOP
  for iAlg = 1:length(LOC.algs)
    % Create the nan'd outputs for the current timestep and this algorithm (we
    % will fill them in later if necessary).
    algSetPtOutlier = setPtOutlier;
    b_IsConsensusType = false;
    b_AllSensMiss = save_AllSensMiss;
    stillGoing = (algSetPtOutlier == LOC.algs(iAlg).setPtViol) + 0;
    stillGoing(algSetPtOutlier == 0) = 0;
    % algSetPtOutlier = ~stillGoing .* algSetPtOutlier;
    LOC.algs(iAlg).setPtViol = int8(stillGoing) .* int8(LOC.algs(iAlg).setPtViol);
    n_sig = length(LOC.sigs);
    n_tau = length(LOC.algs(iAlg).tau_out);
    aType = lower(LOC.algs(iAlg).type);
    LOC.algs(iAlg).residuals(idx,:,:) = zeros(1,n_sig,n_tau);
    LOC.algs(iAlg).eventprob(idx,:,:) = zeros(1,1,n_tau);
    LOC.algs(iAlg).eventcode(idx,:,:) = zeros(1,1,n_tau,'int8');
    LOC.algs(iAlg).event_contrib(idx,:,:) = zeros(1,n_sig,n_tau,'int8');
    LOC.algs(iAlg).cluster_probs(idx,:,:) = 0;
    LOC.algs(iAlg).cluster_ids(idx,:,:) = int8(0);
    window = LOC.algs(iAlg).window;
    lastData = window(end,:);
    absDiff = abs(newData - lastData);
    inTol = (absDiff <= newPrec) | (isnan(absDiff));
    switch lower(aType)
      case 'external' % NEW JAVA-BASED CANARYS CORE ENGINE
        for iTau = 1:n_tau
          % Set the current information for the algorithm
          LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
          LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
          LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
          % Run the algorithm
          LOC.algs(iAlg).algJ(iTau).evaluate();
          try
            LOC.algs(iAlg).algJ(iTau).keep_by_rule();
          catch ERR
            if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
              status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
              switch char(status)
                case {'EVENT','OUTLIER'}
                  LOC.algs(iAlg).algJ(iTau).keep_nans();
                otherwise
                  LOC.algs(iAlg).algJ(iTau).keep_current();
              end
            else
              rethrow(ERR);
            end
          end
          % Read the results from the Java Algorithm
          status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
          switch char(status)
            case {'EVENT'}
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(1);
            case {'OUTLIER'}
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
            case {'NORMAL'}
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
            case {'MISSINGHIST'}
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(-2);
            case {'CALIBRATION'}
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(2);
          end
          prob = LOC.algs(iAlg).algJ(iTau).get_current_probability();
          LOC.algs(iAlg).eventprob(idx,:,iTau) = prob;
          % Store the important probability and event code information
          try % Set the less important information separately
            resid = LOC.algs(iAlg).algJ(iTau).get_current_residuals();
            contrib = LOC.algs(iAlg).algJ(iTau).get_contributing_signals();
            msg = LOC.algs(iAlg).algJ(iTau).get_message();
            if ~isempty(resid),
              LOC.algs(iAlg).residuals(idx,:,iTau) = resid';
            end;
            if ~isempty(contrib)
              LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
            end
            if ~isempty(msg)
              LOC.algs(iAlg).comments{idx,1,1} = char(msg);
            end
          catch ERR
            cws.errTrace(ERR);
          end
        end
        
      otherwise % ORIGINAL PROGRAMMING LOGIC
        switch lower(aType)
          case {'lpcfr','mvnnr'}
            useRes = LOC.algs(iAlg).algs_in;
            if LOC.algs(useRes).n_h > size(LOC.algs(useRes).window,1),
              b_AllSensMiss = true;
            end
            calData = repmat((LOC.algs(useRes).residuals(idx,:,1)),[1,1,n_tau]);
          otherwise
            if LOC.algs(iAlg).n_h > size(LOC.algs(iAlg).window,1),
              b_NeedsHistory = true;
            else
              b_NeedsHistory = false;
            end
            calData = repmat((newData+newAlms),[1,1,n_tau]);
        end
        if idx > 1
            lastContrib = sum(abs(LOC.algs(iAlg).event_contrib(idx-1,:,:)),3);
        else
            lastContrib = sum(abs(LOC.algs(iAlg).event_contrib(idx,:,:)),3);
        end
        if LOC.algs(iAlg).eventcode(max([idx-1,1]),:,1) ~= -1
            suffChg = (suffChg + (lastContrib ~= 0))>0;
        end
        % Do analysis of the current state and new data status and do a switch based
        % on these boolean variables: calibration, needs-history, all-sensors-out,
        % and the integer current state
        if ~b_Calibration && PrevStatus == 2, %% BEGIN STATUS SWITCH
          % --- *END-OF-CALIBRATION MODE*---------------------------------
          LOC.algs(iAlg).comments{idx,1,1} = 'Exiting calibration mode';
          LOC.state = 0;
          LOC.algs(iAlg).comments{idx,1,1} = 'Exiting calibration- insufficient history';
          oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
          %oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
          oldVals = oldData ;%+ oldAlms;
          for iTau = 1:n_tau,
            window(1:size(oldVals,1),:,iTau) = oldVals;
          end
          switch aType
            case {'java'}
              try
                LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                LOC.algs(iAlg).algJ(iTau).evaluate();
                LOC.algs(iAlg).algJ(iTau).keep_current();
              catch ERR
                if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                  status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                  switch char(status)
                    case {'EVENT','OUTLIER'}
                      LOC.algs(iAlg).algJ(iTau).keep_last();
                    otherwise
                      LOC.algs(iAlg).algJ(iTau).keep_current();
                  end
                else
                  rethrow(ERR);
                end
              end
          end
          LOC.algs(iAlg).window = window;
          % --------------
        elseif b_Calibration && ~b_AllSensMiss
          % --- *CALIBRATION MODE* ---------------------------------------------
          LOC.algs(iAlg).comments{idx,1,1} = 'In hardware/auto calibration mode';
          LOC.state = 2;
          LOC.algs(iAlg).eventcode(idx,:,:) = ones(1,1,n_tau,'int8').*2;
          oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
          %oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
          oldVals = oldData ;%+ oldAlms;
          for iTau = 1:n_tau,
            window(1:size(oldVals,1),:,iTau) = oldVals;
            LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
            LOC.algs(iAlg).bedwin(:,:,iTau) = 0;
          end
          switch aType
            case {'java'}
              try
                LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                LOC.algs(iAlg).algJ(iTau).evaluate();
                LOC.algs(iAlg).algJ(iTau).keep_current();
              catch ERR
                if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                  status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                  switch char(status)
                    case {'EVENT','OUTLIER'}
                      LOC.algs(iAlg).algJ(iTau).keep_last();
                    otherwise
                      LOC.algs(iAlg).algJ(iTau).keep_current();
                  end
                else
                  rethrow(ERR);
                end
              end
          end
          LOC.algs(iAlg).window = window;
          % --------------
        elseif b_operationsEvent,
          % --- *OPERATIONS CLEANING* ------------------------------------------
          LOC.algs(iAlg).comments{idx,1,1} = 'Operational Event Indicated: ';
          IDS=DATA.partype(find((dataDir == newIgnr))); %#ok<FNDSB>
          for iIDS = 1:length(IDS),
            LOC.algs(iAlg).comments{idx,1,1} = [LOC.algs(iAlg).comments{idx,1,1},...
              ' ',IDS{iIDS}];
          end
          LOC.state = 0;
          LOC.algs(iAlg).eventcode(idx,:,:) = ones(1,1,n_tau,'int8').*0;
          if b_NeedsHistory,
            window(end+1,:,:) = calData;
          else
            win = window(2:end,:,:);
            window = win;
            window(end+1,:,:) = calData;
          end
          switch aType
            case {'java'}
              try
                LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                LOC.algs(iAlg).algJ(iTau).evaluate();
                LOC.algs(iAlg).algJ(iTau).keep_current();
              catch ERR
                if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                  status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                  switch char(status)
                    case {'EVENT','OUTLIER'}
                      LOC.algs(iAlg).algJ(iTau).keep_last();
                    otherwise
                      LOC.algs(iAlg).algJ(iTau).keep_current();
                  end
                else
                  rethrow(ERR);
                end
              end
          end
          LOC.algs(iAlg).window = window;
          % --------------
        elseif b_AllSensMiss
          LOC.algs(iAlg).comments{idx,1,1} = 'All sensors missing- unable to predict';
          LOC.state = 3;
          LOC.algs(iAlg).eventcode(idx,:,:) = ones(1,1,n_tau,'int8').*3;
          % --------------
        elseif PrevStatus == -1, % We are processing initial start-up timestep
          if idx > 10, % This is for realtime startup, or priming the system
            if DeBug, cws.trace('evaluation','startup');end;
            LOC.algs(iAlg).comments{idx,1,1} = 'Starting up by filling window';
            LOC.state = 0;
            window = [];
            for iii = max(idx-LOC.algs(iAlg).n_h,1):idx
              newData = DATA.values(iii,LOC.sigs);
              newAlms = DATA.values(iii,DATA.alarm(LOC.sigs));
              newCals = sum(DATA.values(iii,LOC.calib));
              newPrec = DATA.precision(1,LOC.sigs);
              newIgnr = DATA.ignore(1,LOC.sigs);
              newAlms(isnan(newIgnr)) = nan;
              if isnan(newCals), continue; end;
              oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
              oldAlms = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,DATA.alarm(LOC.sigs));
              oldVals = oldData + oldAlms;
              for iCol = 1:size(oldVals,2)
                tmp = oldVals(:,iCol);
                tmp(tmp>setptMax(iCol)) = nan;
                tmp(tmp<setptMin(iCol)) = nan;
                oldVals(:,iCol) = tmp;
              end
              if ~isnan(nanmax(newData))
                for iTau = 1:n_tau,
                  window(1:size(oldVals,1),:,iTau) = oldVals;
                end
                switch aType
                  case {'java'}
                    try
                      LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                      LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                      LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                      LOC.algs(iAlg).algJ(iTau).evaluate();
                      LOC.algs(iAlg).algJ(iTau).keep_current();
                    catch ERR
                      if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                        status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                        switch char(status)
                          case {'EVENT','OUTLIER'}
                            LOC.algs(iAlg).algJ(iTau).keep_last();
                          otherwise
                            LOC.algs(iAlg).algJ(iTau).keep_current();
                        end
                      else
                        rethrow(ERR);
                      end
                    end
                end
              else
                for iTau = 1:n_tau,
                  window(end,:,iTau) = newData + nan;
                end
              end
            end
          else % This is for (generally) batch modes where we don't start with data
            LOC.algs(iAlg).comments{idx,1,1} = 'Insufficient history- unable to predict';
            LOC.state = 0;
            oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
            oldAlms = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,DATA.alarm(LOC.sigs));
            oldVals = oldData + oldAlms;
            oldVals = oldData + oldAlms;
            for iCol = 1:size(oldVals,2)
              tmp = oldVals(:,iCol);
              tmp(tmp>setptMax(iCol)) = nan;
              tmp(tmp<setptMin(iCol)) = nan;
              oldVals(:,iCol) = tmp;
            end
            for iTau = 1:n_tau,
              window(1:size(oldVals,1),:,iTau) = oldVals;
            end
            switch aType
              case {'java'}
                try
                  LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                  LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                  LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                  LOC.algs(iAlg).algJ(iTau).evaluate();
                  LOC.algs(iAlg).algJ(iTau).keep_current();
                catch ERR
                  if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                    status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                    switch char(status)
                      case {'EVENT','OUTLIER'}
                        LOC.algs(iAlg).algJ(iTau).keep_last();
                      otherwise
                        LOC.algs(iAlg).algJ(iTau).keep_current();
                    end
                  else
                    rethrow(ERR);
                  end
                end
            end
          end
          LOC.algs(iAlg).window = window;
          LOC.algs(iAlg).eventcode(idx,:,:) = ones(1,1,n_tau,'int8').*-2;
          % --------------
        elseif b_NeedsHistory
          % --- *ADD TO HISTORY* - Generally bach mode after initial startup ------
          LOC.algs(iAlg).comments{idx,1,1} = 'Insufficient history- unable to predict';
          LOC.state = 0;
          %oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
          %oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
          %oldVals = oldData ;%+ oldAlms;
          window(end+1,1,1) = NaN;
          if ~isnan(nanmax(newData))
            for iTau = 1:n_tau,
              window(end,:,iTau) = newData + newAlms;
            end
            switch aType
              case {'java'}
                try
                  LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                  LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                  LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                  LOC.algs(iAlg).algJ(iTau).evaluate();
                  LOC.algs(iAlg).algJ(iTau).keep_current();
                catch ERR
                  if ~isempty(findstr(ERR.message,'java.lang.UnsupportedOperationException'))
                    status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                    switch char(status)
                      case {'EVENT','OUTLIER'}
                        LOC.algs(iAlg).algJ(iTau).keep_last();
                      otherwise
                        LOC.algs(iAlg).algJ(iTau).keep_current();
                    end
                  else
                    rethrow(ERR);
                  end
                end
            end
          else
            for iTau = 1:n_tau,
              window(end,:,iTau) = newData + nan;
            end
          end
          LOC.algs(iAlg).window = window;
          LOC.algs(iAlg).eventcode(idx,:,:) = ones(1,1,n_tau,'int8').*-2;
          % --------------
        else
          % --- *PROCESS ALGORITHMS* ----------------------------------------------
          LOC.algs(iAlg).comments{idx,1,1} = '';
          cmbRes(1:n_tau) = 0;
          
          switch aType
            case {'lpcfr','mvnnr'}
              useRes = LOC.algs(iAlg).algs_in;
              %           precisStd  = repmat(newPrec,[1,1,n_tau]);
              %           windowMean = repmat(nanmean(window),[LOC.algs(iAlg).n_h+1,1,1]);
              %           windowStd  = repmat(nanmax(nanstd( window),precisStd),[LOC.algs(iAlg).n_h+1,1,1]);
              normWindow = window;
              normWindow(end+1,:,:) = calData;
              %           normWindow = ( normWindow - windowMean ) ./ windowStd;
              % Problem with n_use signals using inTol - DBH 10/3/2011
              %useSigs = find( ~isnan(calData(1,:,1)) & ~inTol);
              useSigs = find( ~isnan(calData(1,:,1)));
              nuseSigs = length(useSigs);
              normWindow(isnan(normWindow)) = 0;
            otherwise
              precisStd  = repmat(newPrec,[1,1,n_tau]);
              for iTau = 1:n_tau,
                  tau_out = LOC.algs(iAlg).tau_out(iTau);
                  if tau_out < 1.0
                      precisStd(:,:,iTau) = (1.05 * precisStd(:,:,iTau)) ./ tau_out;
                  end
              end
              windowMean = repmat(nanmean(window),[LOC.algs(iAlg).n_h+1,1,1]);
              windowStd  = repmat(nanmax(nanstd( window),precisStd),[LOC.algs(iAlg).n_h+1,1,1]);
              normWindow = window(max(1,end-LOC.algs(iAlg).n_h+1):end,:,:);
              normWindow(end+1,:,:) = calData;
              normWindow = ( normWindow - windowMean ) ./ windowStd;
              % Problem with n_use signals using inTol - DBH 10/3/2011
              %useSigs = find( ~isnan(calData(1,:,1)) & ~inTol);
              useSigs = find( ~isnan(calData(1,:,1)));
              nuseSigs = length(useSigs);
              normWindow(isnan(normWindow)) = 0;
          end
          setptProx = false;
          if isempty(useSigs),
            for iTau = 1:n_tau,
              cmbRes(iTau) = 0;
            end
          else % ALGORITHM TYPE SWITCH GOES HERE ==============================
            switch aType
              case {'lpc','lpcf','lpcfr','changedetect_lpc'}
                a = lpc(normWindow(:,useSigs,:));
                for iTau = 1:n_tau,
                  res = LOC.algs(iAlg).residuals(idx,:,iTau);
                  for iSig = 1:length(useSigs),
                    AA = [0,-a(iSig+(iTau-1)*nuseSigs,2:end)];
                    est1_x = filter( AA, 1, normWindow(:,useSigs(iSig),iTau) );
                    res(1,useSigs(iSig),1) = normWindow(end,useSigs(iSig),iTau) - est1_x(end);
                  end
                  LOC.algs(iAlg).residuals(idx,:,iTau) = res;% .* suffChg;
                  cmbRes(iTau) = nanmax(abs(res).*suffChg);
                end
              case {'mvnn','mvnnr','changedetect_mv_nn'}
                pointDist = normWindow(:,useSigs,:) - repmat(normWindow(end,useSigs,:),[LOC.algs(iAlg).n_h+1,1,1]);
                pointDist = pointDist .^ 2;
                pDist = sqrt(nansum(pointDist,2));
                for iTau = 1:n_tau,
                  dataPt = find(pDist(:,:,iTau) == nanmin(pDist(1:end-1,:,iTau)),1,'first');
                  if isempty(dataPt), dataPt = 1; end;
                  res = normWindow(end,useSigs,iTau) - normWindow(dataPt,useSigs,iTau);
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;
                  cmbRes(iTau) = pDist(dataPt,1,iTau);
                end
              case {'inc','changedetect_inc','d_dt','ddt'}
                for iTau = 1:n_tau,
                  res = diff(normWindow(:,useSigs,iTau),1,1);
                  res = res(end,:,:);
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;% .* suffChg;
                  cmbRes(iTau) = nanmax(abs(res).*suffChg);
                end
              case {'d2_dt2','d2dt2'}
                for iTau = 1:n_tau,
                  res = diff(normWindow(:,useSigs,iTau),2,1);
                  res = res(end,:,:);
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;% .* suffChg;
                  cmbRes(iTau) = nanmax(abs(res).*suffChg);
                end
              case {'d3_dt3','d3dt3'}
                for iTau = 1:n_tau,
                  res = diff(normWindow(:,useSigs,iTau),3,1);
                  res = res(end,:,:);
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;% .* suffChg;
                  cmbRes(iTau) = nanmax(abs(res).*suffChg);
                end
              case {'consensus','consensus-events','css-e','css_e','csse'}
                b_IsConsensusType = true;
                for iTau = 1:n_tau,
                  res = 1;
                  contrib = LOC.algs(LOC.algs(iAlg).algs_in(1)).event_contrib(idx,:,iTau).*0;
                  for iUA = 1:length(LOC.algs(iAlg).algs_in)
                    res = abs(0+LOC.algs(LOC.algs(iAlg).algs_in(iUA)).eventcode(idx,:,iTau)==1) * res;
                    contrib = contrib + LOC.algs(LOC.algs(iAlg).algs_in(iUA)).event_contrib(idx,:,iTau);
                  end
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;
                  contrib(contrib<0)=-1;
                  contrib(contrib>0)= 1;
                  LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
                  cmbRes(iTau) = res;
                end
              case {'consensus-outliers','css-o','csum','csso'}
                b_IsConsensusType = true;
                for iTau = 1:n_tau,
                  res = 0;
                  contrib = LOC.algs(LOC.algs(iAlg).algs_in(1)).event_contrib(idx,:,iTau).*0;
                  for iUA = 1:length(LOC.algs(iAlg).algs_in)
                    icAlg = LOC.algs(iAlg).algs_in(iUA);
                    contrib = contrib + LOC.algs(icAlg).event_contrib(idx,:,iTau)/2^iUA;
                    res = res + LOC.algs(icAlg).bedwin(end,1,iTau);
                  end
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;
                  contrib(contrib<0)=-1;
                  contrib(contrib>0)= 1;
                  LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
                  cmbRes(iTau) = res;
                  bedwin = LOC.algs(iAlg).bedwin(2:end,:,iTau);
                  bedwin(bedwin>0) = 1;
                  LOC.algs(iAlg).bedwin(:,:,iTau) = [bedwin;res];
                end
              case {'consensus-probability','css-p','cave','cssp'}
                b_IsConsensusType = true;
                for iTau = 1:n_tau,
                  res = 0;
                  contrib = LOC.algs(LOC.algs(iAlg).algs_in(1)).event_contrib(idx,:,iTau).*0;
                  for iUA = 1:length(LOC.algs(iAlg).algs_in)
                    res = res + LOC.algs(LOC.algs(iAlg).algs_in(iUA)).eventprob(idx,:,iTau);
                    contrib = contrib + LOC.algs(LOC.algs(iAlg).algs_in(iUA)).event_contrib(idx,:,iTau);
                  end
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res / length(LOC.algs(iAlg).algs_in);
                  contrib(contrib<0)=-1;
                  contrib(contrib>0)= 1;
                  LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
                  cmbRes(iTau) = res / length(LOC.algs(iAlg).algs_in);
                end
              case {'consensus-max','css-m','cmax','cssm'}
                b_IsConsensusType = true;
                for iTau = 1:n_tau,
                  res = 0;
                  contrib = LOC.algs(LOC.algs(iAlg).algs_in(1)).event_contrib(idx,:,iTau).*0;
                  for iUA = 1:length(LOC.algs(iAlg).algs_in)
                    res = max(res,LOC.algs(LOC.algs(iAlg).algs_in(iUA)).eventprob(idx,:,iTau));
                    contrib = contrib + LOC.algs(LOC.algs(iAlg).algs_in(iUA)).event_contrib(idx,:,iTau);
                  end
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res;
                  contrib(contrib<0)=-1;
                  contrib(contrib>0)= 1;
                  LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
                  cmbRes(iTau) = res;
                end
              case {'java'}
                for iTau = 1:n_tau
                  % Set the current information for the algorithm
                  LOC.algs(iAlg).algJ(iTau).set_calibration_status(b_Calibration);
                  LOC.algs(iAlg).algJ(iTau).set_current_data(newData);
                  LOC.algs(iAlg).algJ(iTau).set_current_usable(~isnan(newAlms));
                  % Run the algorithm
                  LOC.algs(iAlg).algJ(iTau).evaluate();
                  % Read the results from the Java Algorithm
                  prob = LOC.algs(iAlg).algJ(iTau).get_current_probability();
                  % Store the important probability and event code information
                  try % Set the less important information separately
                    resid = LOC.algs(iAlg).algJ(iTau).get_current_residuals();
                    contrib = LOC.algs(iAlg).algJ(iTau).get_contributing_signals();
                    msg = LOC.algs(iAlg).algJ(iTau).get_message();
                    if ~isempty(resid),
                      LOC.algs(iAlg).residuals(idx,:,iTau) = resid';% .* suffChg;
                    end;
                    if ~isempty(contrib)
                      LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
                    end
                    if ~isempty(msg)
                      LOC.algs(iAlg).comments{idx,1,1} = char(msg);
                    end
                    status = LOC.algs(iAlg).algJ(iTau).get_detection_status();
                    switch char(status)
                      case {'EVENT','OUTLIER'}
                        cmbRes(iTau) = LOC.algs(iAlg).tau_out(iTau);
                      otherwise
                        cmbRes(iTau) = 0;
                    end
                    p_bed = prob;
                  catch ERR
                    cws.errTrace(ERR);
                  end
                end
              case {'stp1','stp2','sppe','sppb'}
                for iTau = 1:n_tau,
                  [ res, err_code ] = cws.set_point_proximity(newData(useSigs),...
                    newPrec(useSigs),setptMin(useSigs),setptMax(useSigs),...
                    LOC.algs(iAlg).tau_out(iTau),aType); %#ok<*NASGU>
                  LOC.algs(iAlg).residuals(idx,useSigs,iTau) = res .* LOC.algs(iAlg).tau_out(iTau) ./ LOC.algs(iAlg).tau_evt;
                  p_bed = nanmax(abs(res));
                  cmbRes(iTau) = p_bed * LOC.algs(iAlg).tau_out(iTau) / LOC.algs(iAlg).tau_evt;
                  LOC.algs(iAlg).eventprob(idx,:,iTau) = p_bed;
                  setptProx = true;
                end
              otherwise
                error('CANARY:DETECT','Unknown Algorithm!  %s',LOC.algs(iAlg).type);
            end % Algorithm type switch
          end
          setPointExceeded = sum(sum(abs(setPtOutlier)));
          if DeBug && setPointExceeded > 0,
            cws.trace('EVAL','setPointExceeded');
          end
          % Binomial Event Discriminator / Outlier Detection
          for iTau = 1:n_tau
            if b_IsConsensusType == true,
              
            elseif cmbRes(iTau) >= LOC.algs(iAlg).tau_out(iTau) || setPointExceeded > 0,
              % We have an outlier
              bedwin = LOC.algs(iAlg).bedwin(2:end,:,iTau);
              LOC.algs(iAlg).bedwin(:,:,iTau) = [bedwin;1];
              isPart = (abs(LOC.algs(iAlg).residuals(idx,:,iTau)) >= LOC.algs(iAlg).tau_out(iTau)) + 0;
              parSign = sign(LOC.algs(iAlg).residuals(idx,:,iTau));
              contrib = (isPart .* parSign .* suffChg) + (algSetPtOutlier .* 0.5);
              contrib(isnan(contrib)) = 0;
              LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
              switch aType
                case {'java'}
                  LOC.algs(iAlg).algJ(iTau).keep_last();
              end
            elseif setptProx
              isPart = (abs(LOC.algs(iAlg).residuals(idx,:,iTau)) >= 1.0) + 0;
              parSign = sign(LOC.algs(iAlg).residuals(idx,:,iTau));
              contrib = isPart .* parSign .* suffChg;
              contrib(isnan(contrib)) = 0;
              p_bed = LOC.algs(iAlg).eventprob(idx,:,iTau);
              if p_bed<LOC.p_warn_thresh,
                LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib.*0);
              else
                LOC.algs(iAlg).event_contrib(idx,:,iTau) = int8(contrib);
              end
              bedwin = LOC.algs(iAlg).bedwin(2:end,:,iTau);
              bb = (p_bed>=LOC.p_warn_thresh) + 0;
              LOC.algs(iAlg).bedwin(:,:,iTau) = [bedwin;bb];
            else
              % We don't have an outlier, add to window
              bedwin = LOC.algs(iAlg).bedwin(2:end,:,iTau);
              LOC.algs(iAlg).bedwin(:,:,iTau) = [bedwin;0];
              LOC.algs(iAlg).window(:,:,iTau) = [ window(2:end,:,iTau); calData(:,:,iTau)];
              switch aType
                case {'java'}
                  LOC.algs(iAlg).algJ(iTau).keep_current();
              end
            end
            % Evaluate BED
            p_bed = cmbRes(iTau);
            if LOC.algs(iAlg).use_bed,
              p_bed = binocdf(min([sum(LOC.algs(iAlg).bedwin(:,:,iTau)) LOC.algs(iAlg).n_bed]),LOC.algs(iAlg).n_bed,LOC.algs(iAlg).p_out);
            elseif setptProx,
              p_bed = LOC.algs(iAlg).eventprob(idx,:,iTau);
            end
            LOC.algs(iAlg).eventprob(idx,:,iTau) = p_bed;
            
            event_add = size(LOC.algs(iAlg).bedwin(:,:,iTau),1);
            
            % If above BED \tau, then check against library (if available)
            if p_bed >= LOC.algs(iAlg).tau_evt/2 && p_bed < LOC.algs(iAlg).tau_evt && LOC.algs(iAlg).use_cluster,
                [ yes , probs ] = LOC.algs(iAlg).library.matchWindow( DATA , LOC , idx , iAlg);
                LOC.algs(iAlg).cluster_probs(idx,:,iTau) = probs(1,:);
                LOC.algs(iAlg).cluster_ids(idx,:,iTau) = probs(2,:);
                if yes,
                  fprintf(2,'Cluster recognized\n');
                  LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
                  LOC.algs(iAlg).bedwin(:,:,iTau) = 0;
                  oldData = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,LOC.sigs);
                  oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
                  oldVals = oldData + oldAlms;
                  window(1:size(oldVals,1),:,iTau) = oldVals;
                  LOC.algs(iAlg).window(:,:,iTau) = window(:,:,iTau);
                  if LOC.algs(iAlg).event_ct(1,1,iTau) == 0,
                    thisEvent = cws.Event;
                    thisEvent.patternId = probs(2,1);
                    thisEvent.patternProb = probs(1,1);
                    thisEvent.location = LOC.name;
                    thisEvent.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
                    thisEvent.startIdx = idx;
                    thisEvent.startDate = DATA.timesteps{thisEvent.startIdx};
                    thisEvent.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
                    thisEvent.termCause = 'PAT';
                    thisEvent.eventProb = LOC.algs(iAlg).eventprob(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
                    winSave = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
                    winAlms = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
                    thisEvent.rawData = winSave + winAlms;
                    thisEvent.sigIds = LOC.sigids;
                    thisEvent.sigNames = DATA.names(LOC.sigs);
                    thisEvent.outliers = sum(abs(LOC.algs(iAlg).event_contrib(thisEvent.startIdx-event_add:idx,:,iTau))>0,1);
                    LOC.eventList{end+1} = thisEvent;
%                     thisEvent.printYAML();
                  end
                  LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(1);
                  LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
                end
            end
            if p_bed >= LOC.algs(iAlg).tau_evt
              % Check against cluster library if available
              if LOC.algs(iAlg).use_cluster,
                [ yes , probs ] = LOC.algs(iAlg).library.matchWindow( DATA , LOC , idx , iAlg);
                LOC.algs(iAlg).cluster_probs(idx,:,iTau) = probs(1,:);
                LOC.algs(iAlg).cluster_ids(idx,:,iTau) = probs(2,:);
                if yes,
                  fprintf(2,'Cluster recognized\n');
                  LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
                  LOC.algs(iAlg).bedwin(:,:,iTau) = 0;
                  oldData = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,LOC.sigs);
                  oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
                  oldVals = oldData + oldAlms;
                  window(1:size(oldVals,1),:,iTau) = oldVals;
                  LOC.algs(iAlg).window(:,:,iTau) = window(:,:,iTau);
                  if LOC.algs(iAlg).event_ct(1,1,iTau) == 0,
                    thisEvent = cws.Event;
                    thisEvent.patternId = probs(2,1);
                    thisEvent.patternProb = probs(1,1);
                    thisEvent.location = LOC.name;
                    thisEvent.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
                    thisEvent.startIdx = idx;
                    thisEvent.startDate = DATA.timesteps{thisEvent.startIdx};
                    thisEvent.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
                    winSave = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
                    winAlms = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
                    thisEvent.rawData = winSave + winAlms;
                    thisEvent.eventProb = LOC.algs(iAlg).eventprob(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
                    thisEvent.termCause = 'PAT';
                    thisEvent.sigIds = LOC.sigids;
                    thisEvent.sigNames = DATA.names(LOC.sigs);
                    thisEvent.outliers = sum(abs(LOC.algs(iAlg).event_contrib(thisEvent.startIdx-event_add:idx,:,iTau))>0,1);
                    LOC.eventList{end+1} = thisEvent;
%                     thisEvent.printYAML();
                    LOC.algs(iAlg).event_ct(1,1,iTau) = -length(LOC.eventList);
                  elseif LOC.algs(iAlg).event_ct(1,1,iTau) > 0,
                    thisEvent = cws.Event;
                    thisEvent.location = LOC.name;
                    thisEvent.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
                    thisEvent.patternId = probs(2,1);
                    thisEvent.patternProb = probs(1,1);
                    thisEvent.startIdx = idx - LOC.algs(iAlg).event_ct(1,1,iTau);
                    thisEvent.startDate = DATA.timesteps{thisEvent.startIdx};
                    thisEvent.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
                    winSave = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
                    winAlms = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
                    thisEvent.rawData = winSave + winAlms;
                    thisEvent.eventProb = LOC.algs(iAlg).eventprob(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
                    thisEvent.termCause = 'EFP';
                    thisEvent.sigIds = LOC.sigids;
                    thisEvent.sigNames = DATA.names(LOC.sigs);
                    thisEvent.outliers = sum(abs(LOC.algs(iAlg).event_contrib(thisEvent.startIdx-event_add:idx,:,iTau))>0,1);
                    LOC.eventList{end+1} = thisEvent;
%                     thisEvent.printYAML();
                    LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
                  else
                    evtIdx = -LOC.algs(iAlg).event_ct(1,1,iTau);
                    LOC.eventList{evtIdx}.duration = idx - LOC.eventList{evtIdx}.startIdx;
                    LOC.eventList{evtIdx}.outliers = ...
                      sum(abs(LOC.algs(iAlg).event_contrib(LOC.eventList{evtIdx}.startIdx:idx,:,iTau))>0,1);
                    winSave = DATA.values(LOC.eventList{evtIdx}.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
                    winAlms = DATA.values(LOC.eventList{evtIdx}.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
                    LOC.eventList{evtIdx}.rawData = winSave + winAlms;
                    LOC.eventList{evtIdx}.eventProb = LOC.algs(iAlg).eventprob(LOC.eventList{evtIdx}.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
                  end
                elseif LOC.algs(iAlg).event_ct(1,1,iTau) < 0,
                  LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(1);
                  LOC.algs(iAlg).event_ct(1,1,iTau) = 1;
                else
                  LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(1);
                  LOC.algs(iAlg).event_ct(1,1,iTau) = LOC.algs(iAlg).event_ct(1,1,iTau) + 1;
                end
              else
                LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(1);
                LOC.algs(iAlg).event_ct(1,1,iTau) = LOC.algs(iAlg).event_ct(1,1,iTau) + 1;
                LOC.algs(iAlg).cluster_probs(idx,:,iTau) = 0;
                LOC.algs(iAlg).cluster_ids(idx,:,iTau) = 0;
              end
            elseif p_bed <= 0.5 && LOC.algs(iAlg).event_ct(1,1,iTau) > 0
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
              thisEvent = cws.Event;
              if LOC.algs(iAlg).use_cluster, thisEvent.patternId = 0;
              else thisEvent.patternId = -1; end
              thisEvent.location = LOC.name;
              thisEvent.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
              thisEvent.startIdx = idx - LOC.algs(iAlg).event_ct(1,1,iTau);
              thisEvent.startDate = DATA.timesteps{thisEvent.startIdx};
              thisEvent.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
              winSave = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
              winAlms = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
              thisEvent.rawData = winSave + winAlms;
              thisEvent.eventProb = LOC.algs(iAlg).eventprob(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
              thisEvent.termCause = 'RTN';
              thisEvent.sigIds = LOC.sigids;
              thisEvent.sigNames = DATA.names(LOC.sigs);
              thisEvent.outliers = sum(abs(LOC.algs(iAlg).event_contrib(thisEvent.startIdx-event_add:idx,:,iTau))>0,1);
              LOC.eventList{end+1} = thisEvent;
%               thisEvent.printYAML();
              LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
            elseif LOC.algs(iAlg).event_ct(1,1,iTau) < 0;
              LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
            else
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(0);
            end
            % Check for event timeout
            if LOC.algs(iAlg).event_ct(1,1,iTau) >= LOC.algs(iAlg).n_eto,
              LOC.algs(iAlg).eventcode(idx,:,iTau) = int8(-1);
              LOC.algs(iAlg).bedwin(:,:,iTau) = 0;
              LOC.algs(iAlg).setPtViol = int8(setPtOutlier);
              oldData = DATA.values(max([1,idx-LOC.algs(iAlg).n_h+1]):idx,LOC.sigs);
              %oldAlms = DATA.values(idx-LOC.algs(iAlg).n_h+1:idx,DATA.alarm(LOC.sigs));
              oldVals = oldData ;%+ oldAlms;
              window(1:size(oldVals,1),:,iTau) = oldVals;
              if b_IsConsensusType,
                for iiAlg = 1:length(LOC.algs(iAlg).algs_in)
                  icAlg = LOC.algs(iAlg).algs_in(iiAlg);
                  LOC.algs(icAlg).event_ct(1,1,:) = LOC.algs(icAlg).n_eto;
                end
              end
              thisEvent = cws.Event;
              thisEvent.location = LOC.name;
              if LOC.algs(iAlg).use_cluster, thisEvent.patternId = 0;
              else thisEvent.patternId = -1; end
              thisEvent.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
              thisEvent.startIdx = idx - LOC.algs(iAlg).event_ct(1,1,iTau);
              thisEvent.startDate = DATA.timesteps{thisEvent.startIdx};
              thisEvent.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
              winSave = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,LOC.sigs);
              winAlms = DATA.values(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,DATA.alarm(LOC.sigs));
              thisEvent.rawData = winSave + winAlms;
              thisEvent.eventProb = LOC.algs(iAlg).eventprob(thisEvent.startIdx-LOC.algs(iAlg).back_save+1:idx,:,iTau);
              thisEvent.termCause = 'ETO';
              thisEvent.sigIds = LOC.sigids;
              thisEvent.sigNames = DATA.names(LOC.sigs);
              thisEvent.outliers = sum(abs(LOC.algs(iAlg).event_contrib(thisEvent.startIdx-event_add:idx,:,iTau))>0,1);
              LOC.eventList{end+1} = thisEvent;
%               thisEvent.printYAML();
              try
                LOC.algs(iAlg).window(:,:,iTau) = window(:,:,iTau);
                switch aType
                  case {'java'}
                    LOC.algs(iAlg).algJ(iTau).set_history_window_data(window(:,:,iTau));
                end
              catch ERR
                fprintf(2,'ERROR: ETO caused size mismatch @%d for algorithm #%d. Size:Window[ %s ] != Size:LOC.window[ %s ]\n',idx,iAlg,num2str(size(window(:,:,iTau))),num2str(size(LOC.algs(iAlg).window(:,:,iTau))));
                %cws.errTrace(ERR);
              end
              LOC.algs(iAlg).event_ct(1,1,iTau) = 0;
            end
          end
        end
    end
  end
  LOC.lastIdxEvaluated = idx;
  % END PER-ALGORITHM LOOP AND PROCESS OUTPUTS
  if ~isempty(OUTPUTS)
    for iOut = 1:length(OUTPUTS)
      OUTPUTS(iOut).handle.postResult(idx,LOC,DATA.timesteps{idx},DATA);
    end
  end
  % Exit call
  cws.logger('exit  evaluate_timestep');
end
