classdef CanaryEDS < handle
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    configFile
    runDirectory
    
    useContinue
    cfgControl = []
    cfgTiming = []
    cfgDatasources = []
    cfgParameters = []
    cfgSignals = []
    cfgAlgorithms = []
    cfgLibraries = []
    cfgStations = []
    
    dataSignals
    dataStations
    dataInOut
    dataMessenger
    dataTiming
    
    logfileStyle
    logfilePrefix
    logfileDirectory
    
    debugLevel
    daemonize
    
    orignalCommandLine
  end
  
  methods
  end
  
end

