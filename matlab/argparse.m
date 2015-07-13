function [opts, args] = argparse( config, varargin )
opts = struct();
args = {};
allOpts = fieldnames(config);
for i = 1:length(allOpts)
  opt_name = allOpts{i};
  optDef = config.(opt_name);
  if length(optDef) ~= 3
    warning('argparse:badConfig','WARNING The "%s" field of the config object does not have the appropriate form: {dest, type, default}',opt_name);
  else
    opts.(optDef{1}) = optDef{3};
  end
end
inOpt = false;
curOpt = '';
for i = 1:nargin-1
  if inOpt,
    val = varargin{i};
    opts.(curOpt) = val;
  else
    curOpt = varargin{i};
    if curOpt(1) == '-'
      curOpt = curOpt(2:end);
      inOpt = true;
    end
    if curOpt(1) == '-'
      curOpt = curOpt(2:end);
      inOpt = true;
    end
    if inOpt,
      if isfield(config,curOpt)
        optDef = config.(curOpt);
        switch (lower(optDef{2}))
          case {'store_true'}
            inOpt = false;
            opts.(optDef{1}) = true;
          case {'store_false'}
            inOpt = false;
            opts.(optDef{1}) = false;
          case {'count'}
            inOpt = false;
            curVal = opts.(optDef{1});
            opts.(optDef{1}) = curVal + 1;
        end
      else
        warning('argparse:badOption','WARNING The "%s" option is unrecognized. Did you forget to separate the option and value? Did you use an "=" sign instead of a space?',curOpt);
      end
    else
      args{end+1} = curOpt;
    end
  end
end
