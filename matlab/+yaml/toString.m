function s = toString(x, varargin)
  if nargin > 1,
    fmt = varargin{1};
    switch lower(fmt)
      case {'quoted','"'}
        quoted = true;
      otherwise
        quoted = false;
    end
  else
    quoted = false;
  end
  global DEBUG_LEVEL
  if DEBUG_LEVEL > 0
    fprintf(2,'YAML:  %s  ',class(x))
    disp(x)
  end
  if islogical(x)
    s = yaml.bool2str(x, varargin{:});
    return;
  elseif isnumeric(x)
    s = yaml.num2str(x,varargin{:});
    return
  elseif isempty(x)
    s = 'null';
    return
  elseif isa(x,'java.lang.String')
    s = char(x);
  elseif isjava(x)
    s = char(x.toString());
  elseif strcmpi(x,'nan')
    s = '.nan';
  elseif strcmpi(x,'inf')
    s = '.inf';
  elseif strcmpi(x,'-inf')
    s = '-.inf';
  else
    s = char(x);
  end
  if quoted,
    s = ['"',s,'"'];
  end