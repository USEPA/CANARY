function s = bool2str(x, varargin)
  if nargin > 1,
    fmt = varargin{1};
  else
    fmt = 'yesno';
  end
  if ~islogical(x)
    if ~isnumeric(x)
      s = x;
      return
    else
      s = yaml.num2str(x,varargin{:});
      return
    end
  end
  if x,
    switch lower(fmt),
      case {'yesno','yes/no','yes-no','yn'}
        s = 'yes';
      case {'truefalse','true/false','true-false','tf'}
        s = 'true';
      case {'onoff','on/off','on-off','oo'}
        s = 'on';
      otherwise
        s = num2str(x, varargin{:});
    end
  else
    switch lower(fmt),
      case {'yesno','yes/no','yes-no','yn'}
        s = 'no';
      case {'truefalse','true/false','true-false','tf'}
        s = 'false';
      case {'onoff','on/off','on-off','oo'}
        s = 'off';
      otherwise
        s = num2str(x, varargin{:});
    end
  end
