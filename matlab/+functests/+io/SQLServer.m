classdef SQLServer < mlunit.test_case

  properties 
    testObj = [];
    baseObj = [];
  end
  
  methods

    function test_obj = SQLServer(varargin)
      test_obj = test_obj@mlunit.test_case(varargin{:});
    end
    
    function self = set_up( self )
      % Load baseline data
      BASE = load(fullfile('baselines','baseline_IO_SQLServer.mat'),'-MAT');
      self.baseObj.CDS = BASE.CDS;
      % Run CANARY
      FILE = dir(fullfile('test_io_SQLServer.edsd'));
      if isempty(FILE),
        canary('test_io_SQLServer.edsx');
      end
      % Load output data
      TEST = load(fullfile('test_io_SQLServer.edsd'),'-MAT');
      self.testObj.CDS = TEST.CDS;
    end
    
    function self = tear_down( self )
      % Do nothing
    end
    
    % Public Unit Tests
    function self = test_raw_data_read( self )
      mlunit.assert_equals(size(self.baseObj.CDS.values),size(self.testObj.CDS.values));
      err = nansum(nansum(abs(self.testObj.CDS.values - self.baseObj.CDS.values)));
      mlunit.assert_equals(0,err);
    end
    
  end
  
end
