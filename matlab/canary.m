%CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
%
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
% CANARY is a software package that allows developers to test different
% algorithms and settings on both off- and on-line water-quality data sets.
% Data can come from database or text file sources.
%
% This software was written as part of an Inter-Agency Agreement between
% Sandia National Laboratories and the US EPA NHSRC.

function canary ( varargin )
  if isdeployed
    javaaddpath(fullfile(ctfroot(),'canary','snakeyaml.jar'));
    LIBPATH = getenv('CANARY_LIB');
    if ~isempty(LIBPATH)
      D = dir(fullfile(LIBPATH,'*.jar'));
      for i = 1:length(D)
        javaaddpath(fullfile(LIBPATH,D(i).name));
      end
    end
  end
  global VERSION;
  global DEBUG_LEVEL;
  myver = print_version();
  VERSION = myver;
  %warning on verbose
  warning off backtrace
  warning off stats:pdist:APIChanged
  DEBUG_LEVEL = 0;
  DeBug = 0;
  b_configfile = false;
  b_logfile = false;
  b_datadir = false;
  b_continue = false;
  tic;
  
  config = cws.getCmdlineConfig();
  [opts, args] = argparse(config,varargin{1:end});
  
  if opts.version,
    return;
  end
  if opts.convert,
    convertCanaryData(args{1:end});
    return;
  end
  if opts.clusterize,
    clusterize(args{1:end});
    return;
  end
  if opts.combine,
    combineEdsdFiles(args{1:end});
    return;
  end
  if opts.graph,
    graphCanaryData(args{1:end});
    return;
  end
  if opts.print_cluster,
    graphClusterData(args{1:end});
    return;
  end
  if opts.pattern_editor,
    if isempty(args),
      uiwait(cgui_cluster_editor());
    else
      uiwait(cgui_cluster_editor([],args{1:end}));
    end
    return;
  end
  if opts.help,
    canary_help;
    return;
  end
  if opts.debug > 0,
    DEBUG_LEVEL = DEBUG_LEVEL + 1;
    DeBug = DEBUG_LEVEL;
    warning on verbose;
    warning on backtrace;
  end
  keepalive = opts.daemonize;
  b_interactive = opts.interactive;
  fn_configfile = opts.configfile;
  fn_logfile = opts.logfile;
  fn_datadir = opts.datadir;
  b_continue = opts.continue;
  
  if opts.eddies,
    sep = filesep;
    fn_configfile = ['.' , sep , 'eddies.edsy'];
    FID = fopen(fn_configfile,'r');
    if FID == -1,
      fn_configfile = ['.' , sep , 'eddies.edsx'];
    else
      fclose(FID);
    end
    b_configfile = true;
  end
  if ~isempty(fn_configfile),
    b_configfile = true;
  end
  if ~isempty(fn_logfile),
    b_logfile = true;
  end
  if ~isempty(fn_datadir),
    b_datadir = true;
  end
  
  % opts.restart
  
  if ~isempty(args) && ~b_configfile,
    fn_configfile = args{1};
    b_configfile = true;
  end
  
  
  if isempty(fn_configfile),
    A = questdlg('What would you like to do?','CANARY','Run Event Detection','Graph Results','Convert Files','Run Event Detection');
    switch A,
      case {'Run Event Detection'}
        b_interactive = true;
      case {'Graph Results'}
        graphCanaryData(varargin{2:end});
        return;
      case {'Convert Files'}
        convertCanaryData(varargin{2:end});
        return;
    end
  end
  if b_interactive || isempty(fn_configfile)
    try
      [FileName,PathName] = uigetfile('*.edsx;*.xml;*.edsy;*.yaml;*.yml','Select Configuration File');
      filename = [PathName,FileName];
    catch UIerr
      disp(['No GUI> ',UIerr.message]);
      filename = char(input('Configuration file to use? ','s'));
    end
    b_configfile = true;
    fn_configfile = filename;
  end
  if ~b_configfile,
    error('CANARY:config','No configuration file specified!');
  end
  [PathName,FileName,Ext] = fileparts(fn_configfile);
  if b_logfile,
    [PathName,FileName,Ext] = fileparts(fn_logfile);
  end
  if isempty(PathName),
    PathName = pwd;
  end
  if ~b_datadir,
    fn_datadir = PathName;
  end
  if ~b_logfile,
    sep = filesep();
    fn_logfile = [ PathName , sep , FileName , '.log' ];
  end
  if DeBug,
    fid = fopen(fullfile(PathName,'debug.sql'),'wt');
    fclose(fid);
  end
  try
    fclose(fopen(fn_logfile,'wt'));
  catch Err
    fprintf(2,'(ERROR) Write Permission Denied: "%s"\n',fn_logfile);
    pause(5);
    rethrow(Err);
  end
  diary(fn_logfile)
  diary on
  oncethru = true;
  restart_count = 0;
  
  ObjEDS = cws.CanaryEDS();
  ObjEDS.configFile = fn_configfile;
  [lfDir,lfPref] = fileparts(fn_logfile);
  ObjEDS.logfilePrefix = [lfDir, filesep(), lfPref];
  ObjEDS.logfileDirectory = lfDir;
  ObjEDS.runDirectory = fn_datadir;
  ObjEDS.debugLevel = DEBUG_LEVEL;
  ObjEDS.useContinue = b_continue;
  %   while (keepalive || oncethru) && restart_count < 25
  try
    %       restart_count = restart_count + 1;
    %       oncethru = false;
    %       fprintf(1,'--- # CANARY Log\n- Version: %s\n',VERSION);
    fprintf(1,'- Startup Timestamp: %s\n',datestr(now(),30));
    ret = cws.main(ObjEDS);
    % ret = canary_main(fn_configfile,fn_datadir,fn_logfile,DEBUG_LEVEL);
    diary off
    %       if ret == -1,
    %         keepalive = false;
    %         break;
    %       end
  catch ERR
    if strcmp(ERR.identifier,'xmlmessenger:datamismatch') && keepalive
      fprintf(1,'\n--- # REBOOT: xmlmessenger error \n- Error Timestamp: %s\n',datestr(now(),30));
      return;
    elseif keepalive
      fprintf(1,'\n--- # Unknown error \n- Error Timestamp: %s\n',datestr(now(),30));
      cws.errTrace(ERR);
      fprintf(1,'\n--- # REBOOT: \n- Timestamp: %s\n',datestr(now(),30));
      return;
    else
      fprintf(1,'\n--- # ExitOnError\n- Error Timestamp: %s\n',datestr(now(),30));
      cws.errTrace(ERR);
      diary off
      %fprintf(2,'Error occurred - press any key to exit');
      %pause
      return;
    end
  end
  diary off
  return;
end

function canary_help ( )
  disp('Usage:  canary [OPTIONS] [FILE]')
  disp(' ')
  disp('"canary" without options, or with only a filename will launch CANARY-EDS');
  disp(' ')
  disp('    --graph              Launch the CANARY graphing utilities')
  disp(' ')
  disp('    --convert            Convert a file to CSV (spreadsheet) format')
  disp(' ')
  disp('    --keepalive          Run as a server - CANARY will restart itself on error or on exit')
  disp(' ')
  disp('    --patterns           Launch the pattern library editor');
  disp(' ')
  disp('    --printcluster       Print a cluster information');
  disp(' ')
  disp('    --clusterize         Launch the clustering/training routine on')
  disp('                         output of previous CANARY runs')
  disp(' ')
  disp('    --debug, -d          Increase verbosity of debugging output')
  disp(' ')
  disp('    --eddies, -o         Use EDDIES specific settings')
  disp(' ')
  disp('    --help, -h           Print this message')
  disp(' ')
  input('Press <ENTER> to exit...','s');
  return;
end
