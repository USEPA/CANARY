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

import java.util.logging.Level;
import org.apache.log4j.Logger;
import java.io.IOException;
import java.net.URL;
import java.net.URLClassLoader;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.logging.Level;

/**
 *
 * @author nprackl
 */


public class DatabaseConnectionHandler {
  static final Logger LOG = Logger.getLogger(DatabaseConnectionHandler.class);
  private String connectionURL = "localhost";
  private String connectionDB  = null;
  private String dbUname       = "root";
  private String dbPass        = "";
  private Connection conn      = null;  
  private boolean connected  = false;
  private boolean initialized = false;
  private String sourceString = "";
  private ResultSet results = null;
  private ResultSetMetaData resultsMetaData = null;
   
  private String connectionString = "";
  private String className = "com.mysql.jdbc.Driver";

  /**
   * Get the current class name.
   * @return The current class name.
   */
    public String getClassName() {
        return className;
    }

    /**
     * Set the current class name.
     * @param className The current class name.
     */
    public void setClassName(String className) {
        this.className = className;
    }
  
    /**
     * Default constructor. Sets base values to uninitialized.
     */
    DatabaseConnectionHandler(){
      this.initialized = false;
    }  
  /**
   * Constructor. Create a database connection object with the provided parameters.
   * @param url The server location.
   * @param database The database to connect to.
   * @param user The connection username.
   * @param pass The connection password.
   */
  DatabaseConnectionHandler(String url, String database, String user, String pass){
      this.connectionURL = url;
      this.connectionDB  = database;
      this.dbUname       = user;
      this.dbPass        = pass;
      this.initialized = true;
  }    
  
  /**
   * Returns the latest successful result set.
   * @return The result set from the latest query.
   */
  public ResultSet getLatestResults(){
      return this.results;
  }
  
  /**
   * Returns the Meta Data for the latest successful result set.
   * @return The Meta Data from the latest query.
   */
  public ResultSetMetaData getLatestResultsMetaData(){
      return this.resultsMetaData;
  }
  
  /**
   * Returns a list of the rows of data from the latest successful result set.
   * The rows are a Hash Map of Column Name -> Object
   * @return The results
   */
  public ArrayList<HashMap> getLatestResultList(){
      try {
          ArrayList<HashMap> rows = new ArrayList();
          ArrayList<String> cols = new ArrayList();
          for(int i=0;i<this.resultsMetaData.getColumnCount();i++){             //Begin by extracting column headers.
              cols.add(this.resultsMetaData.getColumnName(i));                  //Build list of column names.
          }
          this.results.first();                                                 //Set the pointer to the first element in the result set.
          do{                                                                   //Begin iterating through result set rows.
            HashMap<String, Object> row = new HashMap();                        //Create new HashMap for each row.
            String rval = "";
            for(int i=0;i<this.resultsMetaData.getColumnCount();i++){           //Iterate through the columns of each row.
                row.put(cols.get(i), this.results.getObject(i));                //Create the HashMap<String, Object> from each Column Name to row.
            }
            rows.add(row);                                                      //Add the row to the list of rows.
          }while(this.results.next());                                          //Repeat while there are still rows.
          return rows;                                                          //Return list of rows.
      } catch (SQLException ex) {
          LOG.warn("SQL Exception Thrown: " + ex.toString());
      }
      return null;
  }
  
  
  /**
   * Generate the JDBC connection string.
   */
  private void genSourceString(){
      this.sourceString =   "jdbc:mysql://" +  this.connectionURL + "/" + this.connectionDB + "?" + "user=" + this.dbUname + "&password=" + this.dbPass;
  }

  /**
   * Generate the JDBC connection string.
   */
  public void setSimpleSourceString(String source, String username, String password){
      this.sourceString =   source + "?" + "user=" + this.dbUname + "&password=" + this.dbPass;
      this.initialized = true;
  }

  
  /**
   * Naive connection string parser. Handles only most basic MySQL connection string.
   * It is highly suggested that direct values be set in implementation.
   * @param source The connection string.
   */
  public void parseSourceString(String source){
      try{
        String src = "";
        if (source.substring(0,13).toLowerCase().equals("jdbc:mysql://")) src = source.substring(13);
        else src = source;
        String delims = "[=&?]";
        String[] tokens = src.split(delims);
        int idx = tokens[0].lastIndexOf("/");
        String server = tokens[0].substring(0, idx);
        String db = tokens[0].substring(idx+1);
        String username = tokens[1];
        String password = tokens[3];

        this.connectionURL = server;
        this.connectionDB = db;
        this.dbUname = username;
        this.dbPass = password;
      }catch(Exception e){
          LOG.warn("There was a problem parsing the source string. Please check if conneciton errors occur.");
          LOG.warn(e.toString());
      }finally{
          this.setSourceString(source);
          this.initialized = true;
      }      
  }
  
  /**
   * Set the JDBC connection string.
   * @param source The string to set.
   */
  public void setSourceString(String source){
      this.sourceString = source;
  }
  
  /**
   * Get the current connection source string.
   * @return The source string.
   */
  public String getSourceString(){
      return this.sourceString;
  }
  
  /**
   * Set the connection information for the database.
   * @param url The server location.
   * @param database The database to connect to.
   * @param user The connection username.
   * @param pass The connection password.
   */
  public void setConnectionInfo(String url, String database, String user, String pass){
      this.connectionURL = url;
      this.connectionDB  = database;
      this.dbUname       = user;
      this.dbPass        = pass;
      this.genSourceString();
      this.initialized = true;
  }  
  
    /**
     * Establish a database connection with the server.
     */
    public void connect() {
        //Trap missing connection information errors.
        if(this.initialized==false){
            LOG.warn("Database connection variables have not been initialized.");
            return;
        }
        if(connectionURL==null) {
            LOG.warn("You must provide a server location.");
            return;
        }        
        if(connectionDB==null){
            LOG.warn("You must provide a database to connect to.");
            return;
        }        
        if(dbUname==null){
            LOG.warn("You must provide a database username.");
            return;            
        }
        
        try {            
            //Do we need interactive mode for logging in?
            Class.forName(this.className).newInstance();
            LOG.warn("Database connection established.");
            try {
                this.conn = DriverManager.getConnection(this.sourceString);
                this.connected = true;
            } catch (SQLException ex) {                // handle any errors
                LOG.warn("SQLException: " + ex.getMessage());
                LOG.warn("SQLState: " + ex.getSQLState());
                LOG.warn("VendorError: " + ex.getErrorCode());
            }
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException ex) {  
            LOG.warn("There was an error connecting to the specified database.");  // handle the error
        }
    }
    
    /**
     * Disconnect from the database server.
     */
    public void disconnect(){
      try {
        this.conn.close();
        this.connected = false;
        LOG.warn("Database connection closed.");
      } catch (Exception ex) {
        LOG.warn("There was an error disconnecting from the database.");
      }
    }
    
    /**
     * Executes a query without returning a result object.
     * @param query The query to execute.
     */
    public void queryNoResult(String query){
      try (CallableStatement ci = conn.prepareCall(query)) {
          ci.execute();
      } catch (SQLException ex) {
          LOG.warn("There was a problem executing the query.");
      }
    }

    /**
     * Queries the database and returns an integer of the number of rows affected. Typically used for INSERT, UPDATE, or DELETE statements.
     * @param query The SQL query to run.
     * @return The number of rows affected.
     */
    public int queryCount(String query){
      try (Statement ci = conn.createStatement()) {
          return ci.executeUpdate(query);
      } catch (SQLException ex) {
          LOG.warn("There was a problem executing the query.");
      }
      return 0;
    }
    
    /**
     * Executes a query and returns a result object.
     * @param query
     * @return The result set.
     */
    public ResultSet queryResult(String query){
        try (CallableStatement sq = conn.prepareCall(query)) {
            sq.execute();
            try (ResultSet rq = sq.getResultSet()) {
                this.results = rq;
                this.resultsMetaData = rq.getMetaData();
                return rq;
            }catch(Exception e){
                LOG.warn("Could not obtain query results.");
            }
        }catch (SQLException ex) {
            LOG.warn("There was a problem executing the query.");
        }
      return null;
    }
    
    /**
     * Takes a list of values and generates a String representation with or without quotes.
     * @param list The list of values.
     * @param quotes True if you want quotes. Otherwise False.
     * @return 
     */
    public String genList(String list[], boolean quotes){
        String retVal = "";
        for(int i=0;i<list.length;i++){
            if(quotes) retVal += "\'" + list[i] + "\'";
            else retVal += list[i];
            if(i!=(list.length-1)) retVal += ", ";
            else retVal += " ";
        }
        return retVal;
    }
    
    /**
     * Generates a basic SELECT SQL query.
     * @param table
     * @param cols
     * @param extra
     * @return 
     */
    public String selectQuery(String table, String cols[], String extra){
        String colVals = genList(cols, false);
        return "SELECT " + colVals + "FROM " + table + " " + extra;
    }
    
    /**
     * Generate a basic INSERT SQL query.
     * @param table
     * @param cols
     * @param vals
     * @param extra
     * @return 
     */
    public String insertQuery(String table, String cols[], String vals[], String extra){
        String colVals = genList(cols, false);
        String valVals = genList(vals, true);
        return "INSERT INTO " + table + " ( " + colVals + ") VALUES " + "( " + valVals + ")" + " " + extra;
    }
    
    
    /**
     * Check if there is a current connection to a database.
     * @return True if connected, False if not connected.
     */
    public boolean isConnected(){
        return this.connected;
    }

    /**
     * Check to see if the database has been initialized.
     * @return True if initialized, false otherwise.
     */
    public boolean isInitialized(){
        return this.initialized;
    }
    
    /**
     * Set the URL to connect to.
     * @param url The URL of the connection.
     */
    public void setConnectionURL(String url){
        this.connectionURL = url;
    }
    
    /**
     * Set the database to connect to.
     * @param db The name of the database.
     */
    public void setConnectionDB(String db){
      this.initialized = true;
      this.connectionDB = db;
      this.genSourceString();
    }
    /**
     * Set the database connection username.
     * @param name The username to set.
     */
    public void setConnectionUsername(String name){
        this.dbUname = name;
    }
    /**
     * Set the database connection password.
     * @param pass The password to set.
     */
    public void setConnectionPassword(String pass){
        this.dbPass = pass;
    }
    
    /**
     * Get the database connection URL.
     * @return 
     */
    public String getConnectionURL(){
        return this.connectionURL;
    }
    
    /**
     * Get the connection database.
     * @return 
     */
    public String getConnectionDB(){
        return this.connectionDB;
    }
    
    /**
     * Get the database connection username.
     * @return 
     */
    public String getConnectionUsername(){
        return this.dbUname;
    }
    
    /**
     * Get the database connection password.
     * @return 
     */
    public String getConnectionPassword(){
        return this.dbPass;
    }

}
