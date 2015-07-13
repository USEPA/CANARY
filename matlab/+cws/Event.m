classdef Event
  %EVENT Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    location = ''
    algDefID = ''
    startIdx = -1
    startDate = ''
    duration = 0
    termCause = ''
    sigIds = {}
    sigNames = {}
    outliers = []
    patternId = -1
    patternProb = 0
    dateFmt = ''
    rawData = []
    eventProb = []
  end
  
  methods

    function plotEvent( self )
      nSigs = length(self.sigIds);
      if isempty(self.sigNames)
        Names = self.sigIds;
      else
        Names = self.sigNames;
      end
      evtDate = datestr(datenum(self.startDate,self.dateFmt),'yyyy-mm-dd_HHMM');
      filename = [self.location, '_', self.algDefID, '_', evtDate, '.png'];
      % rect = [100 50 3*250 (nsig+1)*180];  % dimensions of page of all plots [left bottom width height]
      F = figure('color','w','PaperType','C','PaperUnits','normalized','PaperOrientation','portrait');
      ax = subplot(nSigs+1,1,1);
      set(ax,'FontSize',8);
      plot(self.eventProb);
      ylabel('P_{Event}','FontSize',8);
      evpt = num2str(length(self.rawData(:,1))-self.duration);
      title(['Station: ',self.location,'; Algorithm: ',self.algDefID,'; Alarm At: ',self.startDate,' (',evpt,')'],'FontSize',12);
      for i = 1:nSigs
        ax = subplot(nSigs+1,1,i+1);
        set(ax,'FontSize',8);
        plot(self.rawData(:,i));
        grid on;
        ylabel(self.sigIds{i},'FontSize',8);
        title(Names{i},'FontSize',8,'Interpreter','none');
      end
      print(F,'-dpng',filename);
      close(F);
    end
    
    function str = printYAML( self, id)
      if nargin < 2, id = [self.location, '_', self.algDefID, '_',datestr(datenum(self.startDate,self.dateFmt),'yyyy-mm-dd_HHMM')]; end;
      outStr = sprintf('---\n');
      outStr = sprintf('%sevent id: %s\n',outStr,id);
      outStr = sprintf('%sstation id: %s\n',outStr,self.location);
      outStr = sprintf('%salgorithm id: %s\n',outStr,self.algDefID);
      outStr = sprintf('%sstart date: %s\n',outStr,self.startDate);
      outStr = sprintf('%sduration: %d\n',outStr,self.duration);
      outStr = sprintf('%sterm cause: %s\n',outStr,self.termCause);
      outStr = sprintf('%spattern match: %d\n',outStr,self.patternId);
      outStr = sprintf('%spattern prob: %f\n',outStr,self.patternProb);
      outStr = sprintf('%ssignals: [',outStr);
      for i = 1:length(self.sigIds)
        outStr = sprintf('%s''%s''',outStr,self.sigIds{i});
        if i < length(self.sigIds)
          outStr = sprintf('%s%s',outStr,', ');
        else
          outStr = sprintf('%s%s\n',outStr,']');
        end
      end
      outStr = sprintf('%scontributing: [',outStr);
      for i = 1:length(self.sigIds)
        if isempty(self.outliers)
          outStr = sprintf('%s %d',outStr,0);
        else
          outStr = sprintf('%s %d',outStr,self.outliers(i));
        end
        if i < length(self.sigIds)
          outStr = sprintf('%s%s',outStr,',');
        else
          outStr = sprintf('%s%s\n',outStr,']');
        end
      end
      outStr = sprintf('%shistory data: %d\n',outStr,length(self.rawData(:,1))-self.duration);
      outStr = sprintf('%sraw data:\n',outStr);
      for j = 1:length(self.rawData(:,1))
        outStr = sprintf('%s- [',outStr);
        for i = 1:length(self.sigIds)
          outStr = sprintf('%s%f',outStr,self.rawData(j,i));
          if i < length(self.sigIds)
            outStr = sprintf('%s%s',outStr,', ');
          else
            outStr = sprintf('%s%s\n',outStr,']');
          end
        end
      end
      str = sprintf('%s',outStr);
      fout = fopen(['event_',id,'.yml'],'wt');
      fprintf(fout,str);
      fclose(fout);
    end
    
    function str = toShortYAML( self, id )
      outStr = '- ';
      outStr = sprintf('%s%s.%-5d: [ ',outStr,self.location,id);
      outStr = sprintf('%s"%s", ',outStr,self.algDefID);
      outStr = sprintf('%s"%s", ',outStr,self.startDate);
      outStr = sprintf('%s%d, ',outStr,self.duration);
      outStr = sprintf('%s"%s", ',outStr,self.termCause);
      outStr = sprintf('%s%d, ',outStr,self.patternId);
      outStr = sprintf('%s%f, ',outStr,self.patternProb);
      outStr = sprintf('%s [',outStr);
      for i = 1:length(self.sigIds)
        if isempty(self.outliers)
          outStr = sprintf('%s %d',outStr,0);
        else
          outStr = sprintf('%s %d',outStr,self.outliers(i));
        end
        if i < length(self.sigIds)
          outStr = sprintf('%s%s',outStr,',');
        else
          outStr = sprintf('%s%s',outStr,']');
        end
      end
      str = sprintf('%s]',outStr);
    end
    
    function str = toString( self , id )
      if nargin < 2, id = 0; end;
      outStr = ' || ';
      for i = 1:length(self.sigIds),
        if isempty(self.outliers)
          outStr = sprintf('%s%5d || ',outStr,0);
        else
          outStr = sprintf('%s%5d || ',outStr,self.outliers(i));
        end
      end
      str = sprintf('|| %5d || %20s || %20s || %5d TS ||     %3s     || %5d     || %11.3f || %s',...
        id,self.algDefID,self.startDate,self.duration,...
        self.termCause,self.patternId,self.patternProb,...
        outStr);
    end
    
    function str = getHeader( self )
      outStr = ' || ';
      for i = 1:length(self.sigIds),
        outStr = sprintf('%s%5s || ',outStr,self.sigIds{i});
      end
      str = sprintf('|| Event || Alg ID               || Start Date           || Duration || Term. Cause || Match Pat || Match Prob. || %s',outStr);
    end

    function str = getYmlHeader( self )
      outStr = '';
      for i = 1:length(self.sigIds),
        outStr = sprintf('%s%s, ',outStr,self.sigIds{i});
      end
      str = sprintf('- headers: [ Alg ID, Start Date, Duration, Term. Cause, Match PatNum, Match Prob, [ %s ] ]',outStr);
    end

    function self = createEvent( self , idx , LOC , iAlg , iTau , cause )
      self.location = LOC.name;
      if LOC.algs(iAlg).use_cluster, 
        self.patternProb = LOC.algs(iAlg).cluster_probs(idx,1,iTau);
        self.patternId = LOC.algs(iAlg).cluster_ids(idx,1,iTau);
      end
      self.algDefID = DATA.algorithms.short_id{LOC.algids(iAlg)};
      self.startIdx = idx - LOC.algs(iAlg).event_ct(1,1,iTau);
      self.duration = LOC.algs(iAlg).event_ct(1,1,iTau);
      self.termCause = cause;
      self.sigIds = LOC.sigids;
      self.outliers = sum(abs(LOC.algs(iAlg).event_contrib(self.startIdx:idx,:,iTau))>0,1);
    end
    
  end
  
end

