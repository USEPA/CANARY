function add_drivers( path )
  jarfiles = dir(fullfile(path,'*.jar'));
  for i = 1:length(jarfiles)
    javaaddpath(fullfile(path,jarfiles(i).name));
  end
