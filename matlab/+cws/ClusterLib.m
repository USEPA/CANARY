classdef ClusterLib < handle & cws.PatternLib % ++++++++++++++++++++++++++++++++++++++++++++
    %CLUSTERLIB provides "known event" clustering capabilities to algorithms
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
    % CANARY is a software package that allows developers to test different
    % algorithms and settings on both off- and on-line water-quality data sets.
    % Data can come from database or text file sources.
    %
    % This software was written as part of an Inter-Agency Agreement between
    % Sandia National Laboratories and the US EPA NHSRC.
    %
    %   The CLUSTERLIB class is a handle-based class that is used to create a
    %   library of known data anomolies, or "routine" events, as clusters. These
    %   clusters can then be used to compare real-time events to these "known"
    %   events and provide a likelihood of cluster membership.
    %
    % Code written by Eric Vugrin
    % Integrated into CANARY by David Hart
    % Other credits by function
    %
    % See also: cws.Signals, cws.DataSource, evaluate_timestep
    
    % PROPERTIES
    
    % * PUBLIC PROPERTIES
    properties
        p_thresh = 0.90;
        n_sigs = 1;
        r_order = 3;
        n_coeffs = [];
        n_rpts = 90;
        r_int = [1 2];
        n_libs = 1;
        n_clusters = 0;
        c_dist = 1;
        m_exp = 2;
        max_n_clust = 8;
        conv_crit = 0.1;
        iter_crit = 1000;
        p_level = 0.5;
        clust
        coeff_lib
        signal_ids = {}
        signal_grfmin = []
        signal_grfmax = []
        signal_units = {}
        type = 'poly'    % <--- New. Specifies the fitting curve type.
        n_future = 0     %      Needs to be added to the clustering dialog
        start_times = [] %      box.
        start_times_keepers = []
        raw_data = {};
        loc_name = '';
        alg_name = {};
        patListDir = '';
        patGrfxDir = '';
        mu_scale;
        S;
        
    end
    
    % METHODS
    
    % * PUBLIC METHODS
    methods

        function fixOldStyle(self)
            nEvents = length(self.raw_data);
            sEvents = size(self.raw_data{1});
            nRows = sEvents(1);
            nCols = sEvents(2);
            raw_data = zeros(nRows*nEvents,nCols);
            startTimes = [];
            for i = 1:length(self.raw_data)
               raw_data((i-1)*nRows+1:i*nRows,:) = self.raw_data{i};
               startTimes(end+1) = (i-1)*nRows+1;
            end
            self.makeLib(raw_data,startTimes);
        end
        
        function str = printYAML( self )
            str = sprintf('--- # CANARY Cluster File\n');
            str = sprintf('%snSigs: %d\nrOrder: %d\nnPts: %d\nrType: %s\npLevel: %f\n',...
                str, self.n_sigs, self.r_order(1), self.n_rpts(1), self.type, self.p_level);
            str = sprintf('%ssignals:\n',str);
            for i = 1:length(self.signal_ids)
                str = sprintf('%s- %s\n',str,self.signal_ids{i});
            end
            str = sprintf('%slibrary:\n',str);
            for i = 1:self.n_libs
                str = sprintf('%s- id: %d\n  pattern:\n',str,i);
                for j = 1:self.clust.n_clusters{i}
                    str = sprintf('%s  - id: %d\n',str,j);
                    str = sprintf('%s    means: [',str);
                    for k = 1:length(self.clust.means{i}(j,:))
                        str = sprintf('%s%f',str,self.clust.means{i}(j,k));
                        if k < length(self.clust.means{i}(j,:)),
                            str = sprintf('%s, ',str);
                        else
                            str = sprintf('%s]\n',str);
                        end
                    end
                    str = sprintf('%s    cov:\n',str);
                    for k = 1:length(self.clust.cov{i}(:,1,j))
                        str = sprintf('%s    - [',str);
                        for l = 1:length(self.clust.cov{i}(k,:,j))
                            str = sprintf('%s%f',str,self.clust.cov{i}(k,l,j));
                            if l < length(self.clust.cov{i}(k,:,j)),
                                str = sprintf('%s, ',str);
                            elseif k < length(self.clust.cov{i}(:,1,j))
                                str = sprintf('%s]\n',str);
                            else
                                str = sprintf('%s]\n',str);
                            end
                        end
                    end
                end
            end
        end
        
        
        % - -  PRINTCLUSTERASXML
        function str = PrintClusterAsXML( self )
            str = sprintf('<Clustering cluster-at-P="%f" cluster-order-N="%f" cluster-window-size-TS="%d" cluster-fit-threshold-P="%d" cluster-type="%s" />',...
                self.p_thresh, self.r_order, self.n_rpts, self.p_level , self.type );
        end
        
        
        % - -  PRINTPATTERLISTFILE
        function PrintPatternListFile( self , filename , dirname )
            try
                if nargin < 2,
                    dirname = tempdir;
                    filename = ['PATT_LIST_',self.loc_name,'.txt'];
                elseif nargin < 3
                    dirname = tempdir;
                end
                if ~isdir(dirname) && ~isempty(dirname),
                    mkdir(dirname);
                end
                fout = fullfile(dirname,filename);
                FID = fopen(fout,'w');
                fprintf(FID,'%-4s \t%-10s \t%-10s \t%-20s \t%-34s \t%s\n',...
                    'S/No','LocationId','QualityId','PatternCode',...
                    'FileName',...
                    'Description');
                fprintf(FID,'%-4s-\t%-10s-\t%-10s-\t%-20s-\t%-34s-\t%s\n',...
                    '----','----------','----------','-------------------',...
                    '----------------------------------',...
                    '----------------------------------');
                ct = 0;
                for k = 1:self.n_libs
                    for i = 1:self.clust.n_clusters{k}
                        ct = ct + 1;
                        fprintf(FID,'%-4d \t%-10s \t%-10d \t%-20s \t%-34s \t%s\n',...
                            ct,self.loc_name,ct,self.clust.cluster_ids{k}{i},...
                            [self.loc_name,'_PAT',num2str(ct,'%.3d'),'.png'],...
                            self.clust.cluster_desc{k}{i});
                    end
                end
                fclose(FID);
            catch ERR
                cws.errTrace(ERR);
            end
        end
        
        function PrintPatternGraphics( self , dirname )
            if nargin < 2,
                dirname = tempdir;
            end
            if ~isdir(dirname) && ~isempty(dirname),
                mkdir(dirname);
            end
            clust_per_page = 1;  % Number of clusters to plot on each page of regression plots
            % Get basic information
            order = self.r_order(1,1);
            [nevnts,ncoeff] = size(self.coeff_lib);
            nclust = max([self.clust.n_clusters{1}]);
            nsig = ncoeff/(order+1);
            xlimits(1).max = self.r_int(1,2);
            xlimits(1).min = self.r_int(1,1);
            xlimits(1).inc = (self.r_int(1,2) - self.r_int(1,1))/(self.n_rpts(1,1)-1);  % increment with fencepost problem
            % Plot the regression curves for every event by cluster and signal
            xx = xlimits(1).min:xlimits(1).inc:xlimits(1).max;  % Constant for all rgression plots
            n_rgr_page = ceil(nclust/clust_per_page);  % How many pages needed for regression plots?
            nplot = zeros(1,n_rgr_page);
            ct = 0;
            for k = 1:self.n_libs
                for i = 1:self.clust.n_clusters{k}
                    ct = ct + 1;
                    filename = fullfile(dirname,[self.loc_name,'_PAT',num2str(ct,'%.3d'),'.png']);
                    nplot(ct) = self.create_rgr_page(i,1,xx,order,nsig,1,filename);
                end
            end
        end
        
        % - - SETTYPE
        function self = setType(self)
            self.n_coeffs = self.r_order(1) + 1;
            if self.r_order < 0
                self.type = 'mixed';
                self.r_order = ones(size(self.r_order))*abs(self.r_order);
                self.n_coeffs = self.r_order + 2;
            else
                self.type = 'poly';
            end
            
%             fit_type = self.type;
%             switch lower(fit_type)
%                 case {'step'}
%                     self.r_order = 3;
%                 case {'piecewise'}
%                     self.r_order = 2;
%                 case {'mixed'}
%                     self.r_order = 3;
%                 otherwise
%                     self.type = fit_type;
%             end
        end
        
        
        % - -  CLUSTERIZE
        function self = clusterize( self , CDS , LOC , auto )
            if nargin < 4,
                auto = false;
            end
            self.loc_name = LOC.name;
            self.alg_name = {CDS.algorithms.short_id{LOC.algids}};
            if isempty(self.patListDir),
                self.patListDir = LOC.patListDir;
            end
            if isempty(self.patGrfxDir),
                self.patGrfxDir = LOC.patGrfxDir;
            end
            if auto,
                AutoBtn = questdlg('Do you want to hand-select events?','Yes','No');
                if strcmpi(AutoBtn,'No'),
                    auto = true;
                else
                    auto = false;
                end
            end
            try
                
                setType(self);              
                self.clusterTraject( CDS , LOC , auto , false);
                self.clusterAssign(  );
                simp_clust_plots(self);
            catch ERR
                f = errordlg(ERR.message,'Cluster Pattern Creation Failed');
                uiwait(f);
            end
            
            
            
        end
        % - - SIMP_CLUST_PLOT <--------- Created by RAA
        % Facilitates the viewing of the clustered, both the fitted curves
        % and the raw data.
        function simp_clust_plots(self)
                    hfig = figure(1);
                    clf
                    n_clstrs = max(self.clust.ind{1});
                    for k = 1:n_clstrs
                        for j = 1:self.n_sigs
                            subplot(n_clstrs,self.n_sigs,j+self.n_sigs*(k-1))
                            set(gca,'FontSize',10,'Xtick',0:5:self.n_rpts(j))
                            hold on
                            for i = 1:length(self.start_times);
                                if self.clust.ind{1}(i) == k
%                                     n_coeffs = self.r_order(j)+1;
                                    xwin = 1:self.n_rpts(j);
                                    y = self.funcEval(self.coeff_lib(i,...
                                        (j-1)*self.n_coeffs+1:j*self.n_coeffs),xwin);
                                    p_clust_mem = self.clust.probs{1}(i,k);
                                    p_member = max([min([(1 - p_clust_mem) 1]) 0]);
                                    plot(xwin,y,'k','LineWidth',1,'Color',...
                                        [p_member p_member p_member])
                                end
                            end
                            if k == 1
                                ht = title(self.signal_ids(j));
                                hx = xlabel('time-step');
                                set(ht,'FontSize',14)
                                set(hx,'FontSize',12)
                            else
                                hx = xlabel('time-step');
                                set(hx,'FontSize',12)
                            end
                            hold off
                        end
                    end
                    set(hfig,'Color',[1 1 1])
                    set(gcf, 'PaperPositionMode', 'auto');
                    
                    hfig = figure(2);
                    clf
                    n_clstrs = max(self.clust.ind{1});
                    for k = 1:n_clstrs
                        for j = 1:self.n_sigs
                            subplot(n_clstrs,self.n_sigs,j+self.n_sigs*(k-1))
                            set(gca,'FontSize',10,'Xtick',0:5:self.n_rpts(j))
                            hold on
                            for i = 1:length(self.start_times);
                                if self.clust.ind{1}(i) == k
                                    xwin = 1:self.n_rpts(j);
                                    y = self.raw_data{i}(:,j);
                                    p_clust_mem = self.clust.probs{1}(i,k);
                                    p_member = max([min([(1 - p_clust_mem) 1]) 0]);
                                    plot(xwin,y,'k','LineWidth',1,'Color',...
                                        [p_member p_member p_member])
                                end
                            end
                            if k == 1
                                ht = title(self.signal_ids(j));
                                hx = xlabel('time-step');
                                set(ht,'FontSize',14)
                                set(hx,'FontSize',12)
                            else
                                hx = xlabel('time-step');
                                set(hx,'FontSize',12)
                            end
                            hold off
                        end
                    end
                    set(hfig,'Color',[1 1 1])
                    set(gcf, 'PaperPositionMode', 'auto');
        end
              
        % - - CLUSTERTRAJECT
        function self = clusterTraject( self , CDS , LOC , auto , everything)
            if nargin < 5, everything = false; end;
            prob_from_CANARY = LOC.algs(1).eventprob(:,:,1);
            l_prob = length(prob_from_CANARY);
            l_data = size(CDS.values,1);
            l_prob = min([l_prob l_data]);
            prob_from_CANARY = prob_from_CANARY(1:l_prob,:,1);
            raw_data_ind = LOC.sigs(LOC.libsigs==1);
            self.signal_ids = CDS.partype(raw_data_ind);
            self.signal_units = CDS.units(raw_data_ind);
            self.signal_grfmin = max([CDS.valid_min(raw_data_ind);CDS.set_pt_lo(raw_data_ind)]);
            self.signal_grfmax = min([CDS.valid_max(raw_data_ind);CDS.set_pt_hi(raw_data_ind)]);
            
            
            
            self.n_sigs = length(raw_data_ind);
            data = CDS.values(1:l_prob,raw_data_ind); %raw data from water sensors
            
            self.r_int = repmat([1 self.n_rpts(1)],[self.n_sigs,1]);
            self.r_order = repmat(self.r_order(1),[1 self.n_sigs]);
            self.n_rpts = repmat(self.n_rpts(1),[1 self.n_sigs]);
            
            if everything
                start_times_init = self.n_rpts(1):l_prob;
            else
                start_times_init = self.findEvents( prob_from_CANARY,data );
            end
            
            if isempty(start_times_init)
                error('CANARY:patternLib:noEventsInFile',...
                    'There are no events in the data file loaded.');
            end
            
            starttimes = [];
            if auto,
                for iTime = 1:length(start_times_init),
                    row = start_times_init(iTime);
                    tmp_data = data((row-self.n_rpts(1)):(row+floor(self.n_rpts(1)/2)) , :);
                    X = tmp_data == 0;
                    if ~any(X),
                        starttimes = [ starttimes; start_times_init(iTime)];
                    end
                end
                %        start_times = start_times_init;
            else
                scrsz = get(0,'ScreenSize');
                h = figure('Position',[100 100 scrsz(3)-200 scrsz(4)-200]);
                for iTime = 1:length(start_times_init),
                    row = start_times_init(iTime);
                    tmp_data = data((row-self.n_rpts(1)):(row+floor(self.n_rpts(1)/2)) , :);
                    X = tmp_data == 0;
                    if ~any(X),
                        if auto,
                            starttimes = [ starttimes; start_times_init(iTime)];
                        else
                            try
                                h = CDS.plot(h,start_times_init(iTime),self.n_rpts,LOC.name);
                                Name = questdlg('Is this an operations event to "learn?"','Cluster Identification','Auto','Yes','No','Yes');
                            catch ERR
                                cws.errTrace(ERR)
                                Name = 'No';
                            end
                            if strcmp(Name,'Yes'),
                                starttimes = [ starttimes; start_times_init(iTime)];
                            elseif strcmp(Name,'Auto'),
                                auto = true;
                            end
                        end
                    end
                    clf;
                end
                close(h);
            end
            
            if isempty(starttimes), return; end;
            self.start_times = starttimes;
            
            % Process parameters for library creation and clustering steps
            n_alms = length(self.start_times); %# of events identified by find_times.m
            %             self.coeff_lib = zeros(n_alms,sum(self.r_order)+length(raw_data_ind),self.n_libs);
            
            % Make the libraries using makeLib_func.m and perform hierarchical clustering
            % using clusterdata Matlab function. We'll only keep the "good"
            % coefficents, i.e.  one created from signals which are
            % (singal_grfmin < signals < signal_grfmin) & signals ~= NaN.
            for k = 1:self.n_libs
                [coeff_mat,keepers] = self.makeLib( data, self.start_times);
                if self.n_sigs==1
                    keepers = [keepers zeros(size(keepers))];
                end
                self.coeff_lib(:,:,k) = coeff_mat(sum(keepers')==self.n_sigs,:);
            end
            
            % Collect the good raw events for graphing later on.
            for i = 1:n_alms
                if sum(keepers(i,:))==self.n_sigs
                    data1{i} = data(self.start_times(i)-self.n_rpts(1)+1:self.start_times(i),:);
                else
                    data1{i} = [];
                end
            end
            data1(cellfun(@isempty,data1))=[];
            self.raw_data = data1;
            
            % Ignore event start times for bad events.
            self.start_times_keepers = self.start_times(sum(keepers,2)'==self.n_sigs);
        end
        
        % - - CLUSTERASSIGN
        function self = clusterAssign( self )
            
            eval = self.coeff_lib;
            %             start_times = self.start_times;
            starttimes = self.start_times_keepers;
            if isempty(starttimes)
                error('CANARY:patternLib:noEventsInFile',...
                    'There were no events selected for pattern analysis.');
            end
            [n_alms] = size(eval,1);
            max_nClust = min([self.max_n_clust round(length(starttimes)/2)]);
            %sprintf('iter \t pbm \t xiebeni \t kwon \n')
            n_clust = zeros(1,self.n_libs);
            clust_ind = zeros(n_alms,self.n_libs);
            for k = 1:self.n_libs
                PBM = zeros(1,max_nClust);
                coeff_mat = self.coeff_lib(:,:,k);
                for n_c = 2:max_nClust
                    c_ind = clusterdata(eval,'maxclust',n_c,'distance','seuclidean');
                    UU1 = ones(n_c,n_alms)*0.2/(n_c-1);
                    
                    for j = 1:n_alms
                        i = c_ind(j);
                        UU1(i,j) = 0.8;
                    end
                    UU1 = UU1';
                    
                    PBM(n_c) = self.validateLib( eval,n_c,UU1 );
                end
                n_clust(k) = find(PBM == max(PBM));
                clust_ind(:,k) = clusterdata(coeff_mat,'maxclust',n_clust(k),'distance','seuclidean');
                starttimes = starttimes+ones(n_alms,1);
            end
            
            
            n_obs = size(self.coeff_lib(:,:,1),1);
            clear UU1
            for k = 1:self.n_libs
                if n_clust(k) == 1
                    UU1(:,:,k) = ones(1,n_obs);
                else
                    for i = 1:n_clust(k)
                        for j = 1:n_obs
                            if i == clust_ind(j,k)
                                UU1(i,j,k) = 0.8;
                            else
                                UU1(i,j,k) = 0.2/(n_clust(k)-1);
                            end
                        end
                    end
                end
            end
            UU1 = UU1';
            
            %cluster using fuzzy_cmeans_func.m and get cluster statistics using
            %self.calcStats.m.  It is assumed that the clusters are normally distributed
            %for self.calcStats.m.
            
            for k = 1:self.n_libs
                [mem_func,c_member,n_iter,udif,centroid] = ...
                    self.fuzzyCluster( self.coeff_lib(:,:,k),n_clust(k),clust_ind(:,k),UU1);
                good_fit = mem_func > 1.25/(n_clust(k));
                prob_max = max(mem_func .* good_fit,[],2);
                good_event = find(prob_max > 0);
                n_obs = length(good_event);
                if n_obs == 0,
                    f = errordlg('Error! One of your signals is a constant value within the clustering window at ALL EVENTS. Please remove it from the configuration of this station or set " clustering="false" " for this signal.','Bad signal in cluster!','modal');
                    error('CANARY:clusterizingfoundsingularmatrix','One of your signals is constant within the clustering windows at ALL EVENTS - please remove it from the clustering');
                end
                n_clust(k) = sum(sum(good_fit,1)>=2);
                self.start_times = self.start_times(good_event);
                coeff_mat = self.coeff_lib(good_event,:,:);
                self.coeff_lib = coeff_mat;
                clust_ind2(:,k) = clusterdata(coeff_mat,'maxclust',n_clust(k),'distance','seuclidean');
                clear 'UU1';
                if n_clust(k) == 1
                    UU1(:,:,k) = ones(1,n_obs);
                else
                    for i = 1:n_clust(k)
                        for j = 1:n_obs
                            if i == clust_ind2(j,k)
                                UU1(i,j,k) = 0.8;
                            else
                                UU1(i,j,k) = 0.2/(n_clust(k)-1);
                            end
                        end
                    end
                end
                UU1 = UU1';
                [mem_func,c_member,n_iter,udif,centroid] = ...
                    self.fuzzyCluster( coeff_mat(:,:,k),n_clust(k),clust_ind2(:,k),UU1);
                
                [means, covariances] = cws.ClusterLib.calcStats(self.coeff_lib(:,:,k),mem_func);
                self.clust.means{k} = means;
                self.clust.cov{k} = covariances;
                self.clust.ind{k} = c_member;
                self.clust.probs{k} = mem_func;
                self.clust.centroid{k} = centroid;
                self.clust.n_clusters{k} = n_clust(k);
                self.clust.cluster_ids{k} = cell(1,self.n_clusters);
                self.clust.cluster_desc{k} = cell(1,self.n_clusters);
                for jj = 1:self.clust.n_clusters{k}
                    self.clust.cluster_ids{k}{jj} = sprintf('PAT%.3d',jj);
                    self.clust.cluster_desc{k}{jj} = sprintf('Pattern %.3d - ',jj);
                end
            end
        
        end
        
        
        % - -  MATCHWINDOW
        function [ isCluster , probs ] = matchWindow( self , CDS , LOC , idx , algIdx)
            raw_data_ind = LOC.sigs(LOC.libsigs==1);
            data = CDS.values(:,raw_data_ind) + CDS.values(:,CDS.alarm(raw_data_ind));
            global DEBUG_LEVEL;
            DeBug = DEBUG_LEVEL > 0;
            
            start_times_init = idx;
            library_in = self.coeff_lib(:,:,1);
            n_clust_in = self.clust.n_clusters{1};
            clust_means_in = self.clust.means{1};
            clust_cov_in = self.clust.cov{1};
            
%             n_coeffs = self.r_order(1)+1;
            new_coeff = zeros(1,self.n_coeffs*self.n_sigs);
            
            % Fit coefficients to the event
            for j = 1:self.n_sigs
                ypts = data(start_times_init-self.n_rpts(j)+1:start_times_init,j);
                xpts = 1:size(ypts,1);
                [noz_xpts,noz_data] = cws.ClusterLib.cleanEvents(xpts,ypts');
                new_coeff(1+(j-1)*self.n_coeffs:j*self.n_coeffs)...
                    = self.funcSolv(j,noz_xpts,noz_data);
            end
            
            % Cross check fitting coefficients with the library
            [is_match,clust_probs,pctile] = ...
                cws.ClusterLib.clusterComp(new_coeff,library_in,n_clust_in,...
                clust_means_in,clust_cov_in);
            
            %      if n_clust_in==n_clust_out && max(clust_probs(end,:)) > 1 - self.p_level
            if is_match
                if DeBug, fprintf(2,'Event is similar to existing cluster and matches an existing cluster with %d%%\n',ceil(100*(1-pctile))); end;
                isCluster = true;
            else
                if DeBug, fprintf(2,'Event does not match existing cluster. Best is %d%%\n',ceil(100*(1-pctile))); end
                isCluster = false;
            end
            probs = zeros(2,3);
            for i = 1:3
                id = find(clust_probs==max(clust_probs));
                if isempty(id) || ~isCluster
                    probs(1,i) = 0;
                    probs(2,i) = 0;
                else
                    probs(1,i) = clust_probs(1,id(1));
                    probs(2,i) = id(1);
                    clust_probs(1,id(1)) = 0;
                end
            end

        end
        % - - graphClusterData
        function graphClusterData(self, patIdx, ax, sigIdx, type, minProbToPlot)
            ncpp = 1;
            i = 1;
            ii = patIdx;
            nsig = length(self.signal_ids);
            j = sigIdx;
%             order = self.r_order(j);
            idx = i+(ncpp*(ii-1));
            [probs,II] = sortrows(self.clust.probs{:},ii);
            pp = self.coeff_lib(II,:);
            dd = self.raw_data(II);
            membership = self.clust.ind{:}(II);
            nevnts = size(pp,1);
            xlimits(1).max = self.r_int(1,2);
            xlimits(1).min = self.r_int(1,1);
            xlimits(1).inc = (self.r_int(1,2) - self.r_int(1,1))/(self.n_rpts(1,1)-1);  % increment with fencepost problem
            % Plot the regression curves for every event by cluster and signal
            xx = xlimits(1).min:xlimits(1).inc:xlimits(1).max;  % Constant for all rgression plots
            n_clust = self.clust.n_clusters{:};
            if nargin < 6,
                minProbToPlot = 1.25/n_clust;
            end
            strt = (j-1)*(self.n_coeffs)+1;  % track through the coefficients for this signal
            stop = j*(self.n_coeffs);
            axes(ax);
            cla;
            switch type
                case 1 % Regression Curves
                    set(ax,'FontSize',8);
                    hold on;
                    yymin = zeros(nevnts,1);
                    yymax = zeros(nevnts,1);
                    for k=1:nevnts  % calculate and plot each trace
                        yy = self.funcEval(pp(k,strt:stop),xx);
                        yymax(k) = max(yy);
                        yymin(k) = min(yy);
                        p_clust_mem = probs(k,idx);
                        p_member = max([min([(1 - p_clust_mem) 1]) 0]);
                        if p_clust_mem >= minProbToPlot % || membership(k) == ii,
                            if membership(k) == ii,
                                plot(xx,yy,'-','Color',[p_member p_member p_member],'LineWidth',1.5)
                            else
                                plot(xx,yy,'-','Color',[p_member p_member p_member],'LineWidth',0.5)
                            end
                            yymax(k) = max(yy);
                            yymin(k) = min(yy);
                        else
                            yymax(k) = nan;
                            yymin(k) = nan;
                        end
                        
                    end
                    % Calcualte and plot the mean response
                    %avg = mean(pp(probs(:,ii)>1/n_clust,strt:stop),1);
                    avg = sum(pp(:,strt:stop) .* repmat(probs(:,ii),[1 stop-strt+1])) / sum(probs(:,ii));
                    %yy = polyval(avg,xx);
                    yy = self.funcEval(avg,xx);
                    plot(xx,yy,'-r','LineWidth',2.0)
                    % Improve look and feel of graphs
                    %ylabel([y_axes_txt(j).name],'FontSize',12)
                    if (j==nsig)
                        xlabel('Time Steps','FontSize',9)
                    end
                    if min(yymin) ~= max(yymax)
                        ylim([0.95*max([nanmin(yymin) self.signal_grfmin(j)]),...
                            1.05*min([nanmax(yymax) self.signal_grfmax(j)])]);
                        set(gca,'YLim',ylim);
                    end
                    box('on');
                    hold off;
                case 0 % Raw Data Curves
                    set(ax,'FontSize',8);
                    hold on;
                    yymin = zeros(nevnts,1);
                    yymax = zeros(nevnts,1);
                    %yymean = zeros(nevnts,1);
                    for k=1:nevnts  % calculate and plot each trace
                        yy = dd{k};
                        yy = yy(:,j);
                        yymax(k) = max(yy);
                        yymin(k) = min(yy);
                        p_clust_mem = probs(k,idx);
                        p_member = max([min([(1 - p_clust_mem) 1]) 0]);
                        if p_clust_mem >= minProbToPlot % || membership(k) == ii,
                            if membership(k) == ii,
                                plot(xx,yy,'-','Color',[p_member p_member p_member],'LineWidth',1.5)
                            else
                                plot(xx,yy,'-','Color',[p_member p_member p_member],'LineWidth',0.5)
                            end
                            yymax(k) = max(yy);
                            yymin(k) = min(yy);
                            %                             yymean(k) = mean(yy);
                        else
                            yymax(k) = nan;
                            yymin(k) = nan;
                            %                             yymean(k) = nan;
                        end
                        
                    end
                    % Calcualte and plot the mean response
                    avg = sum(pp(:,strt:stop) .* repmat(probs(:,ii),[1 stop-strt+1])) / sum(probs(:,ii));
                    %yy = polyval(avg,xx);
                    yy = self.funcEval(avg,xx);% + nanmean(yymean);
                    plot(xx,yy,'-r','LineWidth',2.0)
                    if min(yymin) ~= max(yymax)
                        ylim([0.95*max([nanmin(yymin) self.signal_grfmin(j)]),...
                            1.05*min([nanmax(yymax) self.signal_grfmax(j)])]);
                        set(gca,'YLim',ylim);
                    end
                    box('on');
                    hold off;
                    
            end
        end
        
        
        % - -  CLUSTER_VIEW
        function cluster_view(self)
            
            % Function to facilitate viewing clusters contained in the pattern library
            
            % Revised in March 2009 to read in both the "cluster" file and the main
            % output *.mat file and to reorder the plots onto pages
            
            % NEED TO CLEAN UP A LOT OF STUFF AND MAKE SURE THAT COMMENTS ARE CURRENT
            
            % External function calls and source
            % plot_rgr_models         SAM
            % plot_bxwh               SAM
            clust_per_page = 1;  % Number of clusters to plot on each page of regression plots
            % Get basic information
            order = self.r_order(1,1);
            [nevnts,ncoeff] = size(self.coeff_lib);
            nclust = max([self.clust.n_clusters{1}]);
            nsig = ncoeff/(self.n_coeffs);
            xlimits(1).max = self.r_int(1,2);
            xlimits(1).min = self.r_int(1,1);
            xlimits(1).inc = (self.r_int(1,2) - self.r_int(1,1))/(self.n_rpts(1,1)-1);  % increment with fencepost problem
            % Plot the regression curves for every event by cluster and signal
            xx = xlimits(1).min:xlimits(1).inc:xlimits(1).max;  % Constant for all rgression plots
            n_rgr_page = ceil(nclust/clust_per_page);  % How many pages needed for regression plots?
            nplot = zeros(1,n_rgr_page);
            for i = 1:nclust
                nplot(i) = self.create_rgr_page(i,1,xx,order,nsig,1);
            end
            % Make the box and whisker plots
            self.create_bxwh_page(nevnts,order+1,nsig,nclust)
        end
        
        
    end
    
    % * PRIVATE METHODS
    methods ( Access = private )
        % - -  FUNCEVAL: non-linear function evaluation for various types
        function y = funcEval( self , a , x )
            switch lower(self.type)
                case {'poly'}
                    y = polyval(a,x,self.S,self.mu_scale);
                case {'piecewise'}
%                     alm = self.n_rpts(1);
                    alm = 24;
%                     breakpoint = alm - binoinv(self.p_thresh,15,self.p_level);
                    breakpoint = 21;
                    x1 = x(1:breakpoint);
                    x2 = x(breakpoint:alm);
                    y1 = polyval([0 a(1)],x1);
                    y2 = polyval(a(2:3),x2);
                    y = [y1 y2(2:end) NaN*ones(1,self.n_rpts(1)-alm)];
                case {'step'}
                    y = cws.ClusterLib.stepFunc(a,x);
                case {'mixed'}
                    breakpoint = length(x)-9;
                    y = [polyval(a(1),x(1:breakpoint))...
                    polyval(a(2:end),x(breakpoint+1:end))];
                otherwise
                    y = x .* 0;
            end
            
        end
         
        % - -  FUNCSOLV: non-linear curve fitting for various types
        function a = funcSolv( self , j , x , y )
            if isempty(x),
                a = zeros(1,self.n_coeffs);
                return;
            end
            switch lower(self.type)
                case {'poly'}
                    % S and mu are not returned from funcSol because we 
                    % calculate it elsewhere. Hovever, polyfit needs 
                    % argout==3 to work properly.
                    [a S mu] = polyfit(x,y,self.r_order(j));
                    
                case {'step'}
                    a = lsqcurvefit(@cws.ClusterLib.stepFunc,ones(1,self.r_order(j)+1),x,y);
                    
                case {'piecewise'}
                    % Fit the event with a piecewise curve.
                    %
                    % f(x) = /
                    %        | ax + b , 1 <= x <= breakpoint
                    %        |
                    %        | cx + d , breakpoint <= x <= alarm
                    %        \
                    %
                    
%                     alm = self.n_rpts(1);
                    alm = 24;
%                     breakpoint = alm - binoinv(self.p_thresh,15,self.p_level);
                    breakpoint = 21;
                    x1 = x(1:breakpoint);
                    y1 = y(1:breakpoint);
                    x2 = x(breakpoint:alm);
                    y2 = y(breakpoint:alm);
                    a = [polyfit(x1,y1,1) polyfit(x2,y2,1)];
                    
                    % The slope term on the first piece will often be
                    % ~zero. For this reason we'll drop it from the
                    % clustering.
                    a = a(2:4);
                case {'mixed'}
                    breakpoint = length(x)-9;
                    a = [mean(y(1:breakpoint))...
                        polyfit(x(breakpoint:end),y(breakpoint:end),self.r_order(j))];
                otherwise
                    a = zeros(1,self.r_order(j)+1);
            end
        end
        
        % - -  CREATE_RGR_PAGE
        function nplot = create_rgr_page(self,ii,ncpp,xx,order,nsig,cols_this_page,filename)
            if nargin < 8,
                filename = '';
            end
            % Create a single page figure of regression plots that contain the
            % regression model for each member of the cluster and mean regression model
            % for the cluster.
            
            % Input arguments:
            %  ncpp     % number of clusters per page (number of cols on the page)
            %  nsig     % number of signals in each cluster (number of rows on the page)
            
            rect = [100 50 3*250 (nsig+1)*180];  % dimensions of page of all plots [left bottom width height]
            if ~isempty(filename)
                F = figure('color','w','PaperType','C','PaperUnits','normalized','PaperOrientation','portrait');
                nplot = 0;
            else
                F = figure ('color','w','Position',rect);
                nplot = 0;
            end
            nMaxProbHere = sum(self.clust.ind{:}==ii);
            for i = 1:cols_this_page  % local column index on this page
                n_clust = self.clust.n_clusters{:};
                minProbToGraph = 1.25/n_clust;
                for j=1:nsig
                    plt_num = i+(1+ncpp)*(j-1);
                    ax = subplot(nsig+1,ncpp+1,plt_num);  % Create a page with nsig plots arranged horizontally
                    set(ax,'FontSize',8);
                    self.graphClusterData(ii, ax, j, 1, minProbToGraph)
                    if (j==nsig)
                        xlabel('Time Steps','FontSize',9)
                    end
                    ylabel(self.signal_ids{j},'FontSize',8);
                    if (j==1)
                        ct = i+(ncpp*(ii-1));
                        txt2 = self.clust.cluster_ids{1}{ct};
                        title_txt = strcat(self.loc_name,'_',txt2);
                        title (title_txt,'FontSize',10,'Interpreter','none');
                    end
                    box('on');
                    nplot = nplot + 1;
                    
                    % NOW plot actual values
                    plt_num = i+(1+ncpp)*(j-1);
                    ax = subplot(nsig+1,ncpp+1,plt_num+1);  % Create a page with nsig plots arranged horizontally
                    set(ax,'FontSize',8);
                    self.graphClusterData(ii, ax, j, 0, minProbToGraph)
                    if (j==nsig)
                        xlabel('Time Steps','FontSize',9)
                    end
                    ylabel(strcat(self.signal_ids{j},' (raw)'),'FontSize',8);
                    if (j==1)
                        ct = i+(ncpp*(ii-1));
                        txt1 = num2str(i+(ncpp*(ii-1)),'%.3d');
                        title_txt = strcat('PAT',txt1);
                        title (title_txt,'FontSize',10,'Interpreter','none');
                    end
                    box('on');
                    nplot = nplot + 1;
                end
                clear 'idx';
            end
            ax = subplot(nsig+1,ncpp+1,plt_num+2);
            set(ax,'FontSize',8);
            axis off;
            CDtext = textscan(self.clust.cluster_desc{1}{ii},'%80s','delimiter','\n');
            CDtext{1} = {[self.clust.cluster_ids{1}{ii} ' has ' num2str(nMaxProbHere) ' members'] CDtext{:}{:}};
            text(0,1,CDtext{:},'VerticalAlignment','top');
            if ~isempty(filename)
                print(F,'-dpng',filename);
                close(F);
            end
            
            % ===================================================================
        end
        
        
        % - -  CREATE_BXWH_PAGE
        function create_bxwh_page(self,nevnts,ncoeff,nsig,nclust)
            
            rect = [100 50 ncoeff*220 nsig*180];  % dimensions of page of all plots [left bottom width height]
            figure ('color','w','Position',rect);
            
            clust_label = 1:1:nclust;
            
            for j=1:nsig
                for i=1:ncoeff  % local column index on this page
                    xx = repmat(NaN,nevnts,nclust);                   % pad matrix with NaN's
                    big_row = nsig*(j-1)+i;                           % current row in coeff matrix
                    
                    for l=1:nclust                                    % fill xx for this signal and coeff.
                        idx = find([self.clust.ind{:}] == l);
                        xx(1:length(idx),l) = self.coeff_lib(idx,big_row);
                    end
                    
                    plt_num = i+ncoeff*(j-1);
                    subplot(nsig,ncoeff,plt_num)  % Create a page with ncoeff plots arranged horizontally
                    hold on;
                    
                    boxplot(xx,'notch','on')
                    set(gca, 'FontSize',12);
                    set(gca, 'XTick', 1:1:nclust)
                    %txt = strcat(y_axes_txt(sig_idx).name(1:4),foo)
                    %ylabel(txt,'FontSize',12)
                    
                    if i==1
                        foo = self.signal_ids{j};
                        ylabel(foo,'FontSize',12)
                    end
                    if j==1                                           % Place titles on top row of plots
                        foo = sprintf('Coeff. %1d',i);
                        title(foo,'FontSize',12)
                    elseif j==nsig                                    % Place X-axis labels on bottom row of plots
                        set(gca, 'XTickLabel', clust_label,'FontSize',11);
                        % xlabel('Cluster ID','FontSize',12)
                    end
                    
                end  % end of i loop over ncoeff
                
                
            end  % end loop over nsig
            % ===================================================================
        end
        
        
        
        % - -  FINDEVENTS
        function start_times = findEvents(self, probs, data)
            %Objective: find the time step immediately preceding when the probability
            %           exceeds p_thresh.
            %Inputs
            %   probs: probability levels calculated by CANARY
            %   p_thresh: probability threshold that determines an "event" and the start
            %   times
            %Outputs:
            %   start_times: the time step immediately preceding when the probability
            %   exceeds p_level
            probs1 = probs;
            m_dat = max(abs(data'))';
            nd_ind = find(probs <= 1e-4 & m_dat == 0);
            if ~isempty(nd_ind),
                for i = 1:length(nd_ind)
                    yy = find(m_dat(1:nd_ind(i))~= 0, 1, 'last' );
                    if isempty(yy)
                        yy = nd_ind(i);
                    end
                    nd2_ind(i) = yy;
                end
                probs1(nd_ind) = probs(nd2_ind);
            end
            alm_t = find(probs1>self.p_thresh);  %Find the time indices during which alarm is sounding
            if numel(alm_t)==0,
                start_times = [];
                return;
            end
            init_alm_ind = find(alm_t(1:end-1)-alm_t(2:end) < -1)+1; %Find the first time index when the alarm sounds for an interval
            start_times = [alm_t(1)-1;alm_t(init_alm_ind)-1]; %list the immediately preceding timestep
            % ===================================================================
        end
        
        
        % - -  FUZZYCLUSTER
        function [mem_func,c_member,n_iter,udif,centroid] = fuzzyCluster(self,c_data,n_clust,c_ind,Umat)
            %Objective: perform fuzzy c-means clustering algorithm on data to calculate
            %cluster memberships
            %Input
            %c_data: contains data to be clustered: rows contain observations, columns
            %correspond variables
            %n_clust: number of clusters
            %m_exp: is exponent parameter in algorithm, must be <= 1
            %conv_crit:convergence criteria for the clustering algorithm
            %c_ind: initial guess for cluster memberships
            %iter_crit: maximum number of iterations allowed in algorithm
            %Umat: the initial guess for cluster mebership function.  rows
            %correspond to observations, columns correspond to cluster #
            %Output:
            %mem_func: membership function, rows correspond to observations,
            %columns correspond to cluster #
            %c_member: vector of length equal to number of observations.  Contains
            %the cluster number for which the observation has the largest
            %membership function value
            %n_iter: # of iterations performed for convergence
            %udif: difference in iterative membership functions
            %centroid: centroids of clusters.  centroid is a matrix which has
            %n_clust rows. Each entry in a row corresponds to a different variable.
            [n_obs,dimen] = size(c_data);
            UU1 = Umat';
            UU2 = zeros(size(UU1));
            n_iter = 0;
            udif = 100;
            sim_thresh = 0.001;
            cent_var = var(c_data);
            while (udif>self.conv_crit) && (n_iter<self.iter_crit)
                for i = 1:n_clust
                    denom = sum(UU1(i,:).^self.m_exp);
                    cent_ct2 = zeros(1,dimen);
                    for k = 1:n_obs
                        cent_ct2 = cent_ct2+UU1(i,k)^self.m_exp*c_data(k,:);
                    end
                    centroid(i,:) = cent_ct2/denom;
                end
                t5 = cputime;
                for i = 1:n_clust
                    for k = 1:n_obs
                        coeff_ct = 0;
                        v1 = c_data(k,:)-centroid(i,:);
                        num = (sum(v1.^2./cent_var))^(1/(self.m_exp-1));
                        if max(abs(c_data(k,:)-centroid(i,:)))<sim_thresh
                            UU2(:,k) = zeros(n_clust,1);
                            UU2(i,k) = 1;
                            break
                        else
                            for j = 1:n_clust
                                v2 = c_data(k,:)-centroid(j,:);
                                coeff_ct = coeff_ct+(sum(v2.^2./cent_var))^(-1/(self.m_exp-1));
                                %Note in the above step the algorithm should be:
                                % c_ct = c_ct+norm(c_d(k)-cent(i))/norm(c_dat(k)-cent(j))
                                % ^(2/self.m_exp-1).  To maximize code performance, we have
                                % re-written it as above.
                            end
                            UU2(i,k) = 1/(num*coeff_ct);
                        end
                    end
                end
                udif = norm(UU1-UU2,inf);
                UU1 = UU2;
                n_iter = n_iter+1;
            end
            mem_func = UU2';
            [y,c_member] = max(mem_func,[],2);
            % ===================================================================
        end
        
        
        % - -  MAKELIB
        function [coeff_mat,keepers] = makeLib(self, data, start_times)
            % Objective: create a library (matrix) of regression coefficients
            
            % Inputs
            %   raw_data: matrix containing dependent variable portion of regression data
            %   raw_data_ind: vector of length N containing indices of the signals that will be added to library
            %   start_times: vector containing times at which it was determined that the probability
            %   exceeded a user defined threshold.  This point corresponds to the last
            %   timestep of the regression data.
            %   r_order: vector of length N containing the order of the regression polynomials
            %   n_rpts: vector of length N containing the number of pts to be fit in regression
            %   r_int: matrix of size(N,2) that contains the start
            %   and end points of the intervals for the independent variables in the
            %   regression
            
            % Outputs:
            %   coeff_mat = a matrix of size
            %   (length(start_times),sum(r_order)+length(raw_data_ind)) containing the
            %   regression coefficients.
            %   coeff_mat(i,sum(r_order(1:j-1))+j:sum(r_order(1:j))+j) is the set of
            %   regression coefficients for the ith event.  For example, if there are 3
            %   signals (length(raw_data_ind) = 3) and the r_order = [1 2 1], then
            %   coeff_mat(i,1:2) are the regression coefficients corresponding to the
            %   1st signal, coeff_mat(i,3:5) are the coefficients for signal 2, and
            %   coeff_mat(i,6:7)are the coefficients for signal 3.  All for event i.
            
            % Define regression points for independent variable
            % we perform regression using evenly spaced points on interval [1,2]-
            % using this interval helps
            enddata = size(data,1);
            
            % # of alarms sounded
            n_alms = length(start_times);
            
            % These are needed to scale polyfit/polyval
            self.mu_scale = [mean(1:self.n_rpts) std(1:self.n_rpts)];
            self.S = cws.ClusterLib.polyfitcov(1:self.n_rpts,self.r_order(1));
            
            % Initialize the coeff_mat and keepers index
            coeff_mat = zeros(n_alms,(self.n_coeffs)*self.n_sigs);
            keepers = zeros(n_alms,self.n_sigs);
            
            % Parse the time series into alarmed events and fit the events
            for i = 1:n_alms
                for j = 1:self.n_sigs
                    data_pts = data(start_times(i)-self.n_rpts(j)+1:min([start_times(i)+self.n_future,enddata]),j);
                    x_pts = 1:size(data_pts,1);
                    [noz_rpts,noz_data,keep] = cws.ClusterLib.cleanEvents(x_pts',data_pts,...
                        [self.signal_grfmin(j) self.signal_grfmax(j)]);
                    keepers(i,j) = keep; % record whether to keep an event
                    [coeff_mat(i,(j-1)*self.n_coeffs+1:j*self.n_coeffs)]...
                        = self.funcSolv( j , noz_rpts , noz_data );
                end
            end
        end
        
        
        
        % - -  VALIDATELIB
        function pbm = validateLib(self, c_data,n_clust,UU1)
            %Objective: calculate the PBM cluster validity index as decsribed in
            %M.Pakhira et al. (2004) "Validity Index for Crisp and Fuzzy Clusters",
            %Pattern Recognition, (37) 2004. pp.487-501.
            %Input:
            %c_data: contains data to be clustered: rows contain observations, columns
            %correspond variables
            %n_clust: number of clusters
            %self.m_exp: is exponent parameter in algorithm, must be <= 1
            %conv_crit:convergence criteria for the clustering algorithm
            %iter_crit: maximum number of iterations allowed in algorithm
            %UU1: the initial guess for cluster mebership function.  rows
            %correspond to observations, columns correspond to cluster #
            %Output
            %pbm : PBM cluster validity index
            [n_obs] = size(c_data,1);
            cent = mean(c_data);
            data_var = var(c_data);
            E1 = 0;
            for i = 1:n_obs
                v1 = c_data(i,:)-cent;
                E1 = E1+sqrt((sum(v1.^2./data_var)));
            end
            [mem_func,c_member,n_iter,udif,centroid] = ...
                self.fuzzyCluster(c_data,n_clust,[],UU1);
            Ek = 0;
            for i = 1:n_clust
                for j = 1:n_obs
                    v1 = c_data(j,:)-centroid(i,:);
                    Ek = Ek+mem_func(j,i)*(sum(v1.^2./data_var));
                end
            end
            Dk = 0;
            for i = 1:n_clust
                if i<n_clust
                    for j = i+1:n_clust
                        v1 = centroid(i,:)-centroid(j,:);
                        dist = sqrt((sum(v1.^2./data_var)));
                        if Dk<dist
                            Dk = dist;
                        end
                    end
                end
            end
            pbm = (E1*Dk/Ek/n_clust)^2;
            % ===================================================================
        end
        
        
    end
    
    
    % * STATIC METHODS
    methods ( Static = true )
        % - -  CLUSTERCOMP
        function [is_match,clust_probs,pctile] = clusterComp(comp_pt,...
                library_in,n_clust_in,clust_means_in,clust_cov_in)
            %Objective: compare a pt (vector) with library of pts (or vectors). The library of pts has been
            %   clustered with Gaussian mixtures.  If the new pt falls within the user
            %   defined percentile of the multivariate Gaussian distribution of any
            %   cluster, then the new pt is considered to be a part of an exisiting
            %   cluster and is added to that cluster in the augmented library that
            %   includes the new pt.  The library is reclustered and statistics are updated.
            %   If not, a new cluster is added to the library. The mean of the new
            %   cluster is the new pt, and the covariance of the cluster is user
            %   defined.
            %
            %Inputs
            %   comp_pt: new pt (vector) to be compared with the library
            %   p_level: threshold percentile to compare against for inclusion in
            %   clusters
            %   library_in: library against which the pt is compared
            %   n_clust_in: number of previously identified clusters
            %   clust_means_in: means of the clusters as calculated by Gaussian
            %   mixtures clustering algorithm
            %   clust_cov_in: covariance matrices of the clusters as calculated by Gaussian
            %   mixtures clustering algorithm
            %   clust_ind_in: index of cluster membership for pts in library_in
            %   clust_probs_in:posterior probabilities for pts in library_in as calculated by Gaussian
            %   mixtures clustering algorithm
            %   def_cov: if the new pt does not belong to any existing clusters,
            %   def_cov is the covariance matrix of the new cluster that gets added
            %
            %Outputs
            %   library_out = augmented library that includes original library + comp_pt
            %   n_clust = number of clusters after comparison; = n_clust_in or
            %   n_clust_in+1, depending on whether comp_pt meets comparison criteria
            %   clust_means = means of clusters with the new pt.
            %   clust_cov = cov. of clusters with new pt.
            %   clust_ind = index of cluster membership for library_out
            %   clust_probs = posterior probabilities for cluster membership for clusters
            %   of library_out
            
            clust_probs = zeros(1,n_clust_in);
            [n_obs,dof] = size(library_in);
            pctile = -1;
            for i = 1:n_clust_in
                %P[(x-mu)*cov^-1*(x-mu)' <= chi^2(dof,alpha)] = 1-alpha so in the next
                %line, we calculate the corresponding chi^2 value
                chi2val = (comp_pt-clust_means_in(i,:))/clust_cov_in(:,:,i)*(comp_pt-clust_means_in(i,:))';
                %Finding percentile to which comp_pt corresponds
                p_calc = 1-chi2cdf(chi2val,dof); % upper tail probability
                clust_probs(1,i) = nanmax(1-p_calc,0);
                if (p_calc>pctile)
                    %Find which cluster the has the highest p-value
                    pctile = p_calc;
                end
            end
            
            if (pctile>0.05)
                is_match = true;
                % comp_pt belongs to an existing
            else
                is_match = false;
                % comp_pt does NOT belong to an existing
                % DO NOT add the pt to an exisiting cluster
            end
        end
       
        % - -  CALCSTATS
        function [means, covariances] = calcStats(c_data, probs)
            %Objective: Given data and probability of membership to clusters, calculate
            %the mean and variance of each cluster
            %Input
            %c_data: data comprising clusters
            %probs: probability or degree of membership to a cluster.  Rows
            %correspond to observation, columns to clusters
            %Output
            %means: means of clusters.  Each row contains the mean of a cluster.
            %covariances: covariances of cluster.  This variable is a 3-D matrix,
            %where (:,:,k) is the covairnce matrix for the k-th cluster.
            [n_obs,n_clust] = size(probs);
            dimen = length(c_data(1,:));
            sum_probs = sum(probs);
            for k = 1:n_clust
                means(k,:) = sum(diag(probs(:,k))*c_data)/sum_probs(k);
            end
            for k = 1:n_clust
                c_mat = zeros(dimen);
                for i = 1:n_obs
                    c_mat = c_mat+probs(i,k)*(c_data(i,:)-means(k,:))'*(c_data(i,:)-means(k,:));
                end
                covariances(:,:,k) = c_mat/sum_probs(k);
            end
        end
        
        % - -  STEPFUNC
        function y = stepFunc( a , x )
            y = a(1) .* tanh( a(2) .*  x + a(3) ) + a(4);
        end
        

        % - -  CLEANEVENTS <--------- Created by RAA
        % cleanEventsRA properly identifies value within each event that
        % are out of bounds, are sets them to NaN. This way, polyfit will
        % output NaNs for coefficients of any signal containing a NaN.
        % We also track the "keepers" so later on CANARY can ingnore the
        % bad events when clustering.
        %
        % - RAA
        
        function [x_out,y_out,keep_event] = cleanEvents(x_in,y_in,min_max_thresh)
            if nargin < 3
                sig_min = -inf;
                sig_max = +inf;
            else
                % Collect out of bounds thresholds.
                sig_min = min_max_thresh(1);
                sig_max = min_max_thresh(2);
            end
            
            if length(x_in)~= length(y_in)
                error('Different lengths')
            end
            
            y_out = y_in;
            x_out = x_in;
            
            % Set the Ys less then signal_grfmin to NaN;
            y_out(y_in < sig_min)=NaN;
            
            % Set the Ys greater then signal_grfmax to NaN;
            y_out(y_in > sig_max)=NaN;
            
            % Default to keeping the event
            keep_event = 1;
            
            % Decide whether to keep the event
            if sum(isnan(y_out)) > 0;
                keep_event = 0;
            end
            
        end
        % - - POLYFITCOV
        function S = polyfitcov(x,order)
            
            m = length(x);
            X = zeros(m,order+1);
            for i = 1:order+1
                X(:,i) = x.^(i-1);
            end
            X = fliplr(X);
            [Q,R] = qr(X,0);
            S.R = R;
            S.df = length(x)-(order+1);
            S.normr = [];
            
        end
        
    end
    
end
