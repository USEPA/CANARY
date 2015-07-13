function logger(status_value, level, logfile, overwrite)
  global LOGLEVEL 
  global DEBUG_LEVEL
  if nargin < 4,
    overwrite = false;
  end
  if nargin < 3,
    logfile = '';
  end
  if ischar(status_value)
      if ~isempty(strfind(status_value,'exit  '))
          LOGLEVEL = LOGLEVEL - 1;
      end
  end
  if nargin < 2,
    level = LOGLEVEL;
  end
  if ischar(status_value)
      if ~isempty(strfind(status_value,'enter '))
          LOGLEVEL = LOGLEVEL + 1;
      end
  end
  if DEBUG_LEVEL < level; return; end;
  if level > 0
    prefix = repmat('.',[1 level]);
  else
    prefix = '';
  end
  global LOG_FILE
  if isempty(logfile),
    logfile = LOG_FILE;
  end
  try
    if overwrite
      fid = fopen(logfile,'wt');
    else
      fid = fopen(logfile,'at');
    end
  catch
    fid = 2;
  end
  if ischar(status_value)
    fprintf(fid,'%s %s %s\n',datestr(now()),prefix,status_value);
  else  
    fprintf(fid,'%s 0x%.4x %s\n',datestr(now()),status_value,prefix);
  end
  if fid > 2,
    fclose(fid);
  end