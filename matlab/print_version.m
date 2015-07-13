% Get the version number
function myver = print_version()

  myver = 'CANARY #GlobalRev#';
  cmpver = ['CANARY', ' #', 'GlobalRev', '#'];
  if strcmp(myver,cmpver)
    myver = 'CANARY 4.3.2+ interactive build';
  end
  fprintf(2,'%s\n',myver);
  fprintf(2,'Copyright 2007-2013 Sandia Corporation.\n');
  fprintf(2,'Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,\n');
  fprintf(2,'the U.S. Government retains certain rights in this software.\n\n')
	v = char(version());
	fprintf(2,'Built using: \nMATLAB %s\n',v);
  fprintf(2,'Copyright The Mathworks, Inc. 1984-2013.\n');
  fprintf(2,'Redistribution of MATLAB compiler runtime (MCR) libraries by end user\n');
  fprintf(2,'is NOT allowed per the deployment addendum of MCR license (see deploy.txt)\n');
  fprintf(2,'and the CANARY-binary license\n\n');
end
