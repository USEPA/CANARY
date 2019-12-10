/* 
 * Copyright 2014 Sandia Corporation.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation, the U.S.
 * Government retains certain rights in this software.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This software was written as part of an Inter-Agency Agreement between Sandia
 * National Laboratories and the US EPA NHSRC.
 */
package org.canaryeds.base.database;

import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.OutputConnection;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.MessagableImpl;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import org.apache.log4j.Logger;

/**
 * SeMe TableWriter Class.
 * @author nprackl
 */
public class TableWriter extends MessagableImpl implements OutputConnection {
    
    HashMap<String, Object> timestepOpts;
    HashMap<String, Object> databaseOpts;
    HashMap<String, Object> login;

    private String type                 = "db";
    private String location             = "jdbc:mysql://localhost/database";
    private String className            = "com.mysql.jdbc.Driver";              //Default JDBC conneciton class name.
    private boolean enabled             = false;
    private String promptForLogin       = "no";                                 //This is false by default. SeMe is a multi-threaded console application.
    private String username             = "";
    private String password             = "";
    private String inputTable           = "";
    private String outputTable          = "";    

    private String timeDrift            = "";
    private String configFile           = "";
    
    
    private String timeStepName         = "TIME_STEP";                          //Time step column name.
    private String timeStepFormat       = "";
    private String timeStepConvertFunc  = "";
    
    private String parameterTag         = "TAG_NAME";                           //Tag column name.
    private String parameterValue       = "VALUE";                              //Value column name.
    private String parameterQuality     = "QUALITY";                            //Quality column name.
    private boolean paramQualEnabled    = true;    
    
    private boolean limitEndStep        = false;                                //State of limiting end step.
    private Date    limitEndStepDate    = null;                                 //Date value for limiting end step.
        
       
    private DatabaseConnectionHandler db = new DatabaseConnectionHandler();
    private static final Logger LOG = Logger.getLogger(TableReader.class);
    
    private boolean extendedFormat = false;
   
    //Default Format Column Names.
    private String timeStep                 = "TIME_STEP";
    private String instanceID               = "INSTANCE_ID";             // Always CANARY
    private String stationID                = "LOCATION_ID";             // Which should this be?
    private String eventCode                = "DETECTION_INDICATOR";     //
    private String eventProbability         = "DETECTION_PROBABILITY";   //
    private String contributingParameters   = "CONTRIBUTING_PARAMETERS"; //
    
    private String comments                 = "ANALYSIS_COMMENTS";

    //Extended format Column Names.
    private String algorithmID              = "DETECTION_ALGORITHM";
    private String patternMatchID           = "MATCH_PATTERN_ID";
    private String patternMatchProbability  = "MATCH_PROBABILITY";

    //Relative column indexes into the data key array.
    private int stationIDi                  = 1;
    private int eventCodei                  = 2;
    private int eventProbabilityi           = 3;
    private int contributingParametersi     = 4;
    private int algorithmIDi                = 5;
    private int commentsi                   = 6;
    private int patternMatchIDi             = 9;
    private int patternMatchProbabilityi    = 10;
    
    private String canaryID                 = "CANARY";
    
    //No current bindings exist yet for indexes 7, 8, and 11 ("total items", "eventIdentifierName", and "byChannelResiduals")

    /**
     * Check to verify if current station is extended format or not.
     * @return Boolean value defining extended format status.
     */
    public boolean isExtendedFormat() {
        return extendedFormat;
    }

    /**
     * Set if current station is extended format or not.
     * @param extendedFormat The extended format status.
     */
    public void setExtendedFormat(boolean extendedFormat) {
        this.extendedFormat = extendedFormat;
    }
    
    /**
     * Set the database connection information.
     * @param url The URL to connect to.
     * @param db The database to connect to.
     * @param username The database username.
     * @param password The database password.
     */
    public void setConnectionInfo(String url, String db, String username, String password){
        this.db.setConnectionInfo(url, db, username, name);
    }
    
    /**
     * Initialize the connection variables of the database object.
     */
    public void initializeDatabaseConnection(){
        this.db.connect();
    }
    
    /**
     * Set the database connection information and automatically establish a connection to the database object.
     * @param url The URL to connect to.
     * @param db The database to connect to.
     * @param username The database username.
     * @param password The database password.
     */
    public void setConnectionInfoAndConnect(String url, String db, String username, String password){
        this.setConnectionInfo(url, db, username, password);
        this.initializeDatabaseConnection();
    }
    

    /**
     * General constructor, defining a new TableWriter with a given label and delay.
     * @param label The label for the station.
     * @param delay The initial delay.
     */
    public TableWriter(String label, int delay) {
        super(label, delay);
    }
    
    
    @Override
    public void configure(Descriptor config) throws ConfigurationException {
        super.configure(config); //To change body of generated methods, choose Tools | Templates.
        
        //This is where we grab all of the official values from the configuration file and establish our connection values for the database (including queries).

        //Parse general datasource options.
        this.timestepOpts           = (HashMap<String, Object>) this.metaData.get("timestepOpts");
        this.databaseOpts           = (HashMap<String, Object>) this.metaData.get("databaseOpts");
        this.login                  = (HashMap<String, Object>) this.databaseOpts.get("login");
        
        this.location               = (String) this.metaData.get("location");
        this.inputTable             = (String) this.databaseOpts.get("inputTable");
        this.outputTable            = (String) this.databaseOpts.get("outputTable");
        this.className              = (String) this.databaseOpts.get("className");
        this.timeDrift              = (String) this.databaseOpts.get("timeDrift");
        this.promptForLogin         = (String) this.login.get("promptForLogin");
        this.username               = (String) this.login.get("username");
        this.password               = (String) this.login.get("password");
        
        //Get the time step options.
        //time-step DateTime object.
        this.timeStepName           = (String) this.timestepOpts.get("field");
        this.timeStepFormat         = (String) this.timestepOpts.get("format");             //Is this relevant given result set typecasting?
        this.timeStepConvertFunc    = (String) this.timestepOpts.get("convertFunc");   //Is this relevant given result set typecasting?
        
        //Initialize database connection.
        this.db.setClassName(this.className);
        this.db.setSimpleSourceString(this.location, this.username, this.password);
    }    
    
    /**
     * Insert all current messages from inbox into the database.
     * @return the number of insertions made.
     */
    public int insertMessagesIntoDB(){
        ///todo: Custom fields. 
        
        int insertions = 0;
        this.db.connect();
        while(!this.inbox.isEmpty()){                                           //While there are messages in the inbox
            Message m = this.inbox.poll();                                      //Grab the next message in the queue for processing.
            String[] keys = this.getComponentFactory().getResultMessageDataKeys();
            
            //Query builder.            
            Date datestamp = (Date) m.getStep().getValue();
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");        //Simple date format for DATETIME stamp.
            String ts = "'" + df.format(datestamp) + "'";                       //We need to generate the time step here.
            
            //Protect Data
            String tag   = m.getTag();
            String algID = m.getData().get(keys[algorithmIDi]).toString();
                        
            //Insert Data Proteciton
            //if(algID=="") algID = "NULL";
            
            //Generate Insert Statement            
            String query =  "INSERT INTO " + this.outputTable + " (";
            query += this.instanceID             + ", ";
            query += this.timeStepName           + ", ";
            query += this.stationID              + ", ";
            query += this.algorithmID            + ", ";
            query += this.eventCode              + ", ";
            query += this.eventProbability       + ", ";         
            query += this.contributingParameters + ", ";
            query += this.comments               + ", ";
            query += this.patternMatchID         + ", ";
            query += this.patternMatchProbability;
            query += ") values (";
            query += "'" +  this.canaryID                                       + "',";
            query +=        ts                                                  + ", ";
            query += "'" +  m.getTag()                                          + "', ";
            query += "'" +  m.getData().get(keys[algorithmIDi])                 + "', "; 
            query +=        m.getData().get(keys[eventCodei])                   + ", ";
            query +=        m.getData().get(keys[eventProbabilityi])            + ", ";
            query +=        m.getData().get(keys[contributingParametersi])      + "', ";
            query += "'" +  m.getData().get(keys[commentsi])                    + "', ";
            query += "'" +  m.getData().get(keys[patternMatchIDi])              + "', ";
            query +=        m.getData().get(keys[patternMatchProbabilityi]);
            query += ")";                   
             
            //ATTEMPT INSERTION INTO DATABASE            
            insertions += db.queryCount(query);
        }
        this.db.disconnect();
        return insertions;
    }
    

    /**
     * Retrieves all messages from the inbox and outputs them to the database.
     * @return Number of records inserted..
     */
    @Override
    public int consumeMessagesAndWriteOutput() {
        return this.insertMessagesIntoDB(); //Dump all messages.
    }

    /**
     * Retrieves all messages from the inbox and outputs them to the database. Identical to other version of method.
     * @param stepPar
     * @return Number of records inserted.
     */
    @Override
    public int consumeMessagesAndWriteOutput(Step stepPar) {
        return this.insertMessagesIntoDB();//Dump all messages.
    }
    /**
     * Currently retrieves entire connection string.
     * Note - could be accessed by external modules. Consider stripping the username and password information for security.
     * @return 
     */
    @Override
    public String getDestinationLocation() {
        return this.db.getSourceString();
    }

    /**
     * Attempts basic parsing of source location string. Consider using the parameterized version.
     * @param location The database connection string.
     */
    @Override
    public void setDestinationLocation(String location) {
        this.db.parseSourceString(location);
    }
    
    /**
     * Parameterized server settings. This is the recommended method.
     * @param server The connection server.
     * @param database The database to connect to.
     * @param username The connection username.
     * @param password The connection password.
     */
    public void setDestinationLocation(String server, String database, String username, String password){
        this.db.setConnectionInfo(server, database, username, password);
    }

    /**
     * Always returns false because output is never constrained to current step.
     * @return False.
     */
    public boolean isOutputConstrainedToCurrentStep() {
        return false;
        //output everything, or equal to current step
    }

    /**
     * Does nothing in current implementation, as the output is never constrained to the current step.
     * @param constrain 
     */
    public void setOutputConstrainedToCurrentStep(boolean constrain) {
        //sets the above.
    }

}
