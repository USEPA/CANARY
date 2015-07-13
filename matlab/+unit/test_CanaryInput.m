classdef test_CanaryInput < mlunit.test_case
  properties 
    eddiesObj = CanaryInput('TEST_EDDIES');
    csvinpObj = CanaryInput('TEST_CSVINP');
  end
  
  methods
    % Constructor
    function self = test_CanaryInput(varargin)
      self = self@mlunit.test_case(varargin{:});
    end
    
    % Public Unit Tests
    function self = test_eddies_01_create( self )
      self.create_eddies();
      mlunit.assert(isa(self.eddiesObj,'CanaryInput'));
    end
    
    function self = test_eddies_02_connect( self )
      mlunit.assert_equals(0,self.eddiesObj.Isconnected);
      self.eddiesObj.connect();
      mlunit.assert_equals(1,self.eddiesObj.Isconnected);
    end
    
    function self = test_eddies_03_initialize( self )
      mlunit.assert_equals(0,self.eddiesObj.Isinitialized);
      self.eddiesObj.initialize();
      mlunit.assert_equals(0,self.eddiesObj.Isinitialized);
      self.eddiesObj.use();
      self.eddiesObj.initialize();
      mlunit.assert_equals(1,self.eddiesObj.Isinitialized);
    end      
    
    function self = test_eddies_04_read_data( self )
      self.eddiesObj.activate(1);
      self.eddiesObj.update('07/01/2007 12:38:00 AM','07/01/2007 06:00:00 AM');
      mlunit.assert(nansum(nansum(self.eddiesObj.data.values(:,:)))~=0);
    end

    function self = test_eddies_05_disconnect( self )
      mlunit.assert_equals(1,self.eddiesObj.Isconnected);
      self.eddiesObj.disconnect();
      mlunit.assert_equals(0,self.eddiesObj.Isconnected);
    end
    
    function self = test_csvinp_01_create( self )
      self.create_csvinput();
      mlunit.assert(isa(self.csvinpObj,'CanaryInput'));
    end
    
    function self = test_csvinp_02_connect( self )
      mlunit.assert_equals(0,self.csvinpObj.Isconnected);
      self.csvinpObj.connect();
      mlunit.assert_equals(1,self.csvinpObj.Isconnected);
    end

    function self = test_csvinp_03_initialize( self )
      mlunit.assert_equals(0,self.csvinpObj.Isinitialized);
      self.csvinpObj.initialize();
      mlunit.assert_equals(0,self.csvinpObj.Isinitialized);
      self.csvinpObj.use();
      self.csvinpObj.initialize();
      mlunit.assert_equals(1,self.csvinpObj.Isinitialized);
    end      

    function self = test_csvinp_04_read_data( self )
      self.csvinpObj.activate(1);
      self.csvinpObj.update('07/01/2007 12:38:00 AM','07/01/2007 06:00:00 AM');
      mlunit.assert(nansum(nansum(self.csvinpObj.data.values(:,:)))~=0);
    end
    
    function self = test_csvinp_05_disconnect( self )
      mlunit.assert_equals(1,self.csvinpObj.Isconnected);
      self.csvinpObj.disconnect();
      mlunit.assert_equals(0,self.csvinpObj.Isconnected);
    end
  end

  % Private Helper Functions
  methods ( Access = private )
    function self = create_eddies( self )
      T = TimeCfg();
      S = SignalData();
      self.eddiesObj.time = T;
      self.eddiesObj.data = S;
      self.eddiesObj.input_id = 'TEST_EDDIES';
      self.eddiesObj.input_type = 'eddies';
      self.eddiesObj.input_format = 'eddies';
      self.eddiesObj.conn_type = 'jdbc';
      self.eddiesObj.conn_url = 'jdbc:oracle:thin:@//localhost:1521/xe';
      self.eddiesObj.driver_class = 'oracle.jdbc.driver.OracleDriver';
      self.eddiesObj.driver_datasource_class = 'oracle.jdbc.pool.OracleDataSource';
      self.eddiesObj.driver_file = 'C:\Program Files\canary\ojdbc14.jar';
      self.eddiesObj.conn_username = 'CANARY';
      self.eddiesObj.conn_password = 'CANARY';
      self.eddiesObj.conn_todatefunction = 'To_Date';
      self.eddiesObj.conn_todateformat = 'MM/DD/YYYY HH:MI:SS PM';
      self.set_eddies_time();
      self.set_eddies_signals();
    end
    
    function self = create_csvinput( self )
      T = TimeCfg();
      S = SignalData();
      self.csvinpObj.time = T;
      self.csvinpObj.data = S;
      self.csvinpObj.input_id = 'TEST_CSVINPUT';
      self.csvinpObj.input_type = 'csv';
      self.csvinpObj.input_format = 'sheet';
      self.csvinpObj.conn_type = 'file';
      self.csvinpObj.conn_url = './test.csv';
      self.csvinpObj.driver_class = '';
      self.csvinpObj.driver_datasource_class = '';
      self.csvinpObj.driver_file = '';
      self.csvinpObj.conn_username = '';
      self.csvinpObj.conn_password = '';
      self.csvinpObj.conn_todatefunction = '';
      self.csvinpObj.conn_todateformat = '';
      self.set_csvinp_time();
      self.set_csvinp_signals();
    end
    
    function self = set_eddies_time( self )
      self.eddiesObj.time.date_fmt = 'mm/dd/yyyy HH:MM:SS PM';
      self.eddiesObj.time.date_mult = 720;
      self.eddiesObj.time.date_start = '07/01/2007 12:38:00 AM';
      self.eddiesObj.time.date_end = '07/01/2007 06:00:00 AM';
    end
    
    function self = set_eddies_signals( self )
      self.eddiesObj.data.addSignalDef('name','AIRY_H2OxHTCH_CL2x_V',...
        'scada_id','AIRY_H2OxHTCH_CL2x_V',...
        'signal_type','WQ',...
        'parameter_type','CL2',...
        'precision',0.035,...
        'units','mg/L',...
        'alarm_scope','',...
        'alarm_value','',...
        'normal_value',''  );
      self.eddiesObj.data.addSignalDef('name','AIRY_MONxHTCH_CL2x_ALM',...
        'scada_id','AIRY_MONxHTCH_CL2x_ALM',...
        'signal_type','ALM',...
        'parameter_type','CL2',...
        'precision',1,...
        'units','',...
        'alarm_scope','AIRY_H2OxHTCH_CL2x_V',...
        'alarm_value','0',...
        'normal_value','1'  );
      self.eddiesObj.data.addSignalDef('name','AIRY_MON_OSxx_CMD',...
        'scada_id','AIRY_MON_OSxx_CMD',...
        'signal_type','CAL',...
        'parameter_type','CAL',...
        'precision',1,...
        'units','',...
        'alarm_scope','location',...
        'alarm_value','0',...
        'normal_value','1'  );
      self.eddiesObj.data.addSignalDef('name','AIRY_H2OxHTCH_TEMP_V',...
        'scada_id','AIRY_H2OxHTCH_TEMP_V',...
        'signal_type','WQ',...
        'parameter_type','TEMP',...
        'precision',0.01,...
        'units','\deg C',...
        'alarm_scope','',...
        'alarm_value','',...
        'normal_value',''  );
      self.eddiesObj.data.time = self.eddiesObj.time;
      self.eddiesObj.data.initialize;
    end
    
    function self = set_csvinp_time( self )
      self.csvinpObj.time.date_fmt = 'mm/dd/yyyy HH:MM:SS PM';
      self.csvinpObj.time.date_mult = 720;
      self.csvinpObj.time.date_start = '07/01/2007 12:38:00 AM';
      self.csvinpObj.time.date_end = '07/01/2007 06:00:00 AM';
    end
    
    function self = set_csvinp_signals( self )
      self.csvinpObj.data.addSignalDef('name','AIRY_H2OxHTCH_CL2x_V',...
        'scada_id','AIRY_H2OxHTCH_CL2x_V',...
        'signal_type','WQ',...
        'parameter_type','CL2',...
        'precision',0.035,...
        'units','mg/L',...
        'alarm_scope','',...
        'alarm_value','',...
        'normal_value',''  );
      self.csvinpObj.data.addSignalDef('name','AIRY_MONxHTCH_CL2x_ALM',...
        'scada_id','AIRY_MONxHTCH_CL2x_ALM',...
        'signal_type','ALM',...
        'parameter_type','CL2',...
        'precision',1,...
        'units','',...
        'alarm_scope','AIRY_H2OxHTCH_CL2x_V',...
        'alarm_value','0',...
        'normal_value','1'  );
      self.csvinpObj.data.addSignalDef('name','AIRY_MON_OSxx_CMD',...
        'scada_id','AIRY_MON_OSxx_CMD',...
        'signal_type','CAL',...
        'parameter_type','CAL',...
        'precision',1,...
        'units','',...
        'alarm_scope','location',...
        'alarm_value','0',...
        'normal_value','1'  );
      self.csvinpObj.data.addSignalDef('name','AIRY_H2OxHTCH_TEMP_V',...
        'scada_id','AIRY_H2OxHTCH_TEMP_V',...
        'signal_type','WQ',...
        'parameter_type','TEMP',...
        'precision',0.01,...
        'units','\deg C',...
        'alarm_scope','',...
        'alarm_value','',...
        'normal_value',''  );
      self.csvinpObj.data.time = self.csvinpObj.time;
      self.csvinpObj.data.initialize;
    end
  end
  
end
