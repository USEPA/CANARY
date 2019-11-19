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
import gov.sandia.seme.framework.InputConnection;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.MessageType;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.DateTimeStep;
import gov.sandia.seme.util.MessagableImpl;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.logging.Level;
import org.apache.log4j.Logger;

/**
 * SeMe TableReader class.
 * @author nprackl
 */
public class TableReader extends MessagableImpl implements InputConnection {
    
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
    
    /**
     * Configure the current station using a given descriptor.
     * @param config A descriptor containing current configuration information.
     * @throws ConfigurationException 
     */
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
     * Basic constructor, taking a label and initial delay.
     * @param label The label.
     * @param delay The initial delay.
     */
    public TableReader(String label, int delay) {
        super(label, delay);
    }

    /**
     * Currently retrieves entire connection string.
     * Note - could be accessed by external modules. Consider stripping the username and password information for security.
     * @return 
     */
    @Override
    public String getSourceLocation() {
        return this.db.getSourceString();
    }

    /**
     * Attempts basic parsing of source location string. Consider using the parameterized version.
     * @param location 
     */
    @Override
    public void setSourceLocation(String location) {
        this.db.parseSourceString(location);
    }
    
    /**
     * Parameterized server settings. This is the recommended method.
     * @param server The connection server.
     * @param database The database to connect to.
     * @param username The connection username.
     * @param password The connection password.
     */
    public void setSourceLocation(String server, String database, String username, String password){
        this.db.setConnectionInfo(server, database, username, password);
    }
    
    /**
     * Directly query the database for message results. Generates necessary messages and pushes them to the outbox queue.
     * @return The number of messages generated.
     */
    private int getValueMessagesFromDB(){
        this.db.connect();
        String[] cols;
        int messageCount = 0;
        //Naming of columns to query. Can be expanded to support other columns and column types.
        if(this.paramQualEnabled){
            cols = new String[4];
            cols[0] = this.timeStepName;
            cols[1] = this.parameterTag;
            cols[2] = this.parameterValue;
            cols[3] = this.parameterQuality;
        }else{
            cols = new String[3];
            cols[0] = this.timeStepName;
            cols[1] = this.parameterTag;
            cols[2] = this.parameterValue;
        }
        ArrayList<String> tags = this.produces;                                     //Generate queries for each tag.
        for(int i=0;i<tags.size();i++){                                             //Query each tag that the reader will produce.
            String tag = tags.get(i);
            String whs = " WHERE " + this.parameterTag + " = `" + tag + "`";        //Query conditional statements.
            String query = this.db.selectQuery("", cols, whs );                     //Generate SQL query string.
            String[] keys = this.getComponentFactory().getValueMessageDataKeys();   //Get the keys for generating new value message components.
            
            ///todo: Add additional support for other data values.
            ///todo: Time Shift?
            ///todo: Any additional fixes or changes needed for the Value Message Data Keys?
                    
            //Run the query.
            ResultSet result = db.queryResult(query);
            try {
                if(result.first()){                                                             //Set the pointer to the first element in the result set. Skip rest of code if no results returned.
                    do{                                                                         //Begin iterating through result set rows.
                        Date timestep = result.getTimestamp(timeStepName);                      //Get the time step tag. No need to waste operations grabbing anything else unless this gets processed.
                        //Analyze the result set and extract messages based on time stamp.
                        //If the date is greater than current and less than limiting step or there is no limiting on end step.
                        if((timestep.compareTo((Date) this.getCurrentStep().getValue()) >= 0)&&((this.limitEndStep==false)||(timestep.compareTo(this.limitEndStepDate) <= 0))){   
                            //Here we generate and process our message.   
                            HashMap<String, Object> data = new HashMap();                       //Create a HashMap to contain result data.
                            String tagname  = result.getString(parameterTag);                   //Get the tag name (should be the same, since querying by tag).
                            Double value    = result.getDouble(parameterValue);                 //Get the parameter value.
                            data.put(keys[2], value);                                           //Grab the value key.
                            if(this.paramQualEnabled){
                                String qual = result.getString(parameterQuality);               //Get the quality row value if enabled.
                                data.put(keys[3], qual);
                            } 
                            //Generate messages and put in outbox.
                            DateTimeStep ns = new DateTimeStep((DateTimeStep) this.baseStep);   //Generate the new DateTimeStep.
                            ns.setValue(timestep);                                              //Set the new date.
                            Message m = new Message(MessageType.VALUE, tagname, data, ns);      //Generate the actual message.                            
                            this.pushMessageToOutbox(m);                                        //Push the message to the outbox.
                            messageCount++;                                                     //Increment the message counter.
                        }   
                    }while(result.next());                                                      //Repeat while there are still rows.
                }else{
                    LOG.warn("No results returned.");
                }
            } catch (SQLException ex) {
                LOG.warn("SQL Exception thrown: " + ex.toString());
            }
        }        
        this.db.disconnect();
        return messageCount;
    }
    
    /**
     * Parameterized server settings.
     * @param location Full location string for database on server.
     * @param username The connection username.
     * @param password The connection password.
     */
    public void setSourceLocation(String location, String username, String password){
        this.db.setSimpleSourceString(location, username, password);
    }

    /**
     * Check to see if values are constrained to the current step.
     * @return True always, as we are always constrained to current step.
     */
    public boolean isInputConstrainedToCurrentStep() {
        return true;
    }

    /**
     * Set if the input is constrained to the current step. Technically not supported as implementation is always constrained to current step.
     * @param contrain Boolean defining constraint.
     */
    public void setInputConstrainedToCurrentStep(boolean contrain) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
        //sets above? 
        //Not currently supported, as all versions are constrained to the current step.
    }

    /**
     * Reads everything greater than last step value, put all in queue, even if future step number.
     * Read all Columns from Database, generates list of all rows AFTER current step, generate messages and push to outbox queue.
     * @return The number of messages generated.
     */
    public int readInputAndProduceMessages() {
        this.limitEndStep = false;
        return getValueMessagesFromDB();
    }

    /**
     * Read messages based on last time step, up to current time step
     * @param stepPar The step to limit the query to. This should be a DateTimeStep.
     * @return The number of messages generated.
     */
    public int readInputAndProduceMessages(Step stepPar) {
        this.limitEndStep = true;
        this.limitEndStepDate = (Date) stepPar.getValue();
        return getValueMessagesFromDB();
    }

}
