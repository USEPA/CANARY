function print(level, msg, varargin)
  global DEBUG_LEVEL
  global LOG_FILE
  if level >= DEBUG_LEVEL || bitand(level,DEBUG_LEVEL) == level,
    prefix = num2str(level);
    logfile = LOG_FILE;
    fid = fopen(logfile,'at');
    fprintf(fid,[prefix,': ',msg],varargin{:});
    fclose(fid);
  end
  