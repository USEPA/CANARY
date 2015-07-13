classdef MessageList < handle
  %MESSAGELIST
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
  %
  properties ( SetAccess = protected , GetAccess = public )
    head = [];
    tail = [];
    nMsg = 0;
  end
  
  methods
    function msg = top( self )
      msg = self.head;
      return;
    end
    
    function self = MessageList( varargin )
      self.head = [];
      self.tail = [];
      self.nMsg = 0;
    end
    
    function msg = pop( self )
      if isempty(self.head)
        msg = self.head;
        return;
      end
      msg = self.head;
      self.head = msg.next;
      msg.next = [];
      self.nMsg = self.nMsg - 1;
      if isempty(self.head),
        self.tail = [];
      end
    end
    
    function push( self , msg )
      msg.next = self.head;
      if isempty(self.tail)
        self.tail = msg;
      end
      self.head = msg;
      self.nMsg = self.nMsg + 1;
    end
    
    function append( self , msg )
      msg.next = [];
      if isempty(self.head),
        self.head = msg;
      end
      self.tail.next = msg;
      self.tail = msg;
      self.nMsg = self.nMsg + 1;
    end
    
    function msg = last( self )
      msg = self.tail;
    end
    
    function self = clear( self )
      for i = 1:self.nMsg
        msg = self.pop();
      end
    end
    
  end
  
end
