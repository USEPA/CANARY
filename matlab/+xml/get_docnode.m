function XDoc = get_docnode ( filename )
  % GET_DOCNODE retrieves an XML Document Node from an XML formatted file
  %   This helps with eliminating errors from XMLREAD when compiling code
  %
  % Example:
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
  if ~ischar(filename)
    error('xml:ReadErr',...
      'No file name specified');
  end
  try
    factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
    builder = factory.newDocumentBuilder();
    [path,name,ext] = fileparts(filename);
    if isempty(path), path = pwd; end;
    if path(1) == '.', path = [ pwd , filesep , path ]; end;
    if isempty(ext), ext = '.xml'; end;
    file = [ path filesep name ext ];
    javafile = java.io.File(file);
    xStr = builder.parse(javafile);
    XDoc = xStr.getDocumentElement;
    xStr = [];
  catch ERRcfg
    base_ME = MException('xml:ReadErr',...
      'Unable to load from file %s', filename);
    base_ME = addCause(base_ME, ERRcfg);
    throw(base_ME);
  end
  
end
