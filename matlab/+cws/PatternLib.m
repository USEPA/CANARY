classdef PatternLib < handle % ++++++++++++++++++++++++++++++++++++++++++++
  %CLUSTERLIB provides "known event" clustering capabilities to algorithms
  %
  % CANARY-EDS Continuous Analysis of Netowrked Array of Sensors for Event Detection
  % Copyright 2007-2012 Sandia Corporation.
  % This source code is distributed under the LGPL License.
  % Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
  % the U.S. Government retains certain rights in this software.
  
  % PROPERTIES
  
  % * PUBLIC PROPERTIES
  properties
    
  end
  
  % METHODS
  
  % * PUBLIC METHODS
  methods
    function [ isCluster , probs ] = matchWindow( self , CDS , LOC , idx , algIdx)
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function createPattern( name )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function configure( obj )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function addEvent( patName , eventObj )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
    
    function addEventFromFile( patname , filename )
      error('CANARY:datasource','Using base class method when overloaded method required: %s',self.conn_id);
    end
   
  end
  
  % * PRIVATE METHODS
  methods ( Access = private )
    
  end
    
  % * STATIC METHODS
  methods ( Static = true )
    
  end
  
end
