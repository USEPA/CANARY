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
package org.canaryeds.base.text;

import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.InputConnection;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.MessageType;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.util.DateTimeStep;
import gov.sandia.seme.util.MessagableImpl;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.PriorityQueue;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userCSVReaderTall Configuration Details: Using text.CSVReaderTall
 * 
 * @endif
 */
/**
 * Use CSV files for data storage. The CSVReaderWide class reads
 * Comma-Separated-Values files that have been formatted so that each row
 * contains all values for a particular step. In other words, there is a single
 * column that contains Step values, and every other column is assumed to
 * represent a unique data stream where the column header is the tag for that
 * data stream.
 * <p>
 * The following are configuration options that are available, both general
 * flags and CSVReaderTall specific.
 * <p>
 * <table><tr><th>Option tag</th><th>Type (in bold) and description</th></tr>
 * <tr><td>location</td><td><b>String</b>: the file location or URL. Should
 * either be just a file name or a full (absolute) path.</td></tr>
 * <tr><td>fieldSeparator</td><td><b>String</b>: (optional) the field separator
 * character, if the default of "," is not desired. Use "\\t" for tabs or " "
 * for space.</td></tr>
 * <tr><td>stepColumn</td><td><b>String</b>: the column header which indicates
 * the Step data are contained in that column.<br><b>Integer</b>: the column
 * number for the column containing Step data; a value of 1 indicates the first
 * column (spreadsheet column A).</td></tr>
 * <tr><td>stepFormat</td><td> </td></tr>
 * <tr><td>tagColumn</td><td> </td></tr>
 * <tr><td>valueColumn</td><td> </td></tr>
 * <tr><td>qualityColumn</td><td> </td></tr>
 * <tr><td>qualityTextGoodData</td><td> </td></tr>
 * <tr><td>qualityTextBadData</td><td> </td></tr>
 * </table>
 *
 * @htmlonly
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 3902 $, $Date: 2013-11-01 10:06:41 -0600 (Fri, 01 Nov 2013) $
 * @endhtmlonly
 */
public class CSVReaderTall extends MessagableImpl implements InputConnection {

    private static final Logger LOG = Logger.getLogger(CSVReaderTall.class);
    private PriorityQueue<Message> csvalues = new PriorityQueue();
    private final int format = 1;
    private String dateFormat = null;

    @Override
    public void configure(Descriptor config) throws ConfigurationException {
        super.configure(config);
        HashMap options = config.getOptions();
        this.location = (String) options.get("location");
        if (options.get("stepFormat") != null) {
            this.dateFormat = ((String) options.get("stepFormat"));
        }
    }

    @Override
    public Descriptor getConfiguration() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * @author nprackl
     * @throws InitializationException
     */
    @Override
    public void initialize() throws InitializationException {
        try {
            File loc = new File(location);
            FileReader inFile;
            BufferedReader reader;
            inFile = new FileReader(loc.getAbsoluteFile());
            reader = new BufferedReader(inFile);
            String line = null;                 //The line currently being read.
            String[] labels = null;             //The labels from the first line.
            int lineNum = -1;
            int timesteps = 0;
            if (this.getBaseStep() != null && this.dateFormat == null) {
                this.dateFormat = this.getBaseStep().getFormat();
            }
            while ((line = reader.readLine()) != null) {
                lineNum++;  //Increment line number.
                //Different formats require different processing.
                if (lineNum == 0) {
                    labels = line.split(",");        //Get labels for first line.
                    LOG.debug(labels);
                } else {                                           //Processing for all additional lines.
                    timesteps = lineNum;
                    String[] lineValues = line.split(",");   //Split the input string into components.
                    Date myDate = new Date(0);
                    try {
                        myDate = (new SimpleDateFormat(this.dateFormat)).parse(
                                lineValues[0]);
                    } catch (ParseException ex) {
                        LOG.error(
                                "Failed to parse date \'" + lineValues[0] + "\' using format \'" + dateFormat + "\'",
                                ex);
                    }
                    Step step;
                    step = new DateTimeStep((DateTimeStep) getBaseStep());
                    step.setValue(myDate);
                    for (int i = 1; i < lineValues.length; i++) {  //Iterate through the internal values.
                        if (lineValues[i].length() != 0) {
                            HashMap val = new HashMap();
                            val.put("value", Double.parseDouble(lineValues[i]));
                            Message msg = new Message(MessageType.VALUE,
                                    labels[i], val, step);
                            csvalues.add(msg);
                            LOG.trace(lineNum + " : " + msg);
                        }
                    }
                }
            }
            LOG.debug("Timesteps Read: " + timesteps); //Output timesteps read in.
        } catch (FileNotFoundException ex) {
            LOG.fatal("fatal error initializing " + this.name
                    + "for input use (file not found: "
                    + location + ")", ex);
            throw new InitializationException("error initializing "
                    + this.name + "for input use (file not found: "
                    + location + ")");
        } catch (IOException ex) {
            LOG.fatal("fatal error initializing " + this.name
                    + "for input use (read error: "
                    + location + ")", ex);
            throw new InitializationException("error initializing "
                    + this.name + "for input use (read error: "
                    + location + ")");
        }
    }

    /**
     *
     * @param step
     * @return
     */
    @Override
    public int readInputAndProduceMessages(Step step) {
        Message msg = csvalues.peek();
        LOG.trace("Peek: " + msg);
        int count = 0;
        while (msg != null) {
            if (msg.getStep().compareTo(step) < 1) {
                count++;
                msg = csvalues.poll();
                LOG.trace("Send message: " + msg);
                this.pushMessageToOutbox(msg);
            } else {
                break;
            }
            msg = csvalues.peek();
        }
        LOG.debug(
                "Read and produced " + count + " DATA messages for Step=" + step + ".");
        return count;
    }

    /**
     *
     * @return
     */
    @Override
    public int readInputAndProduceMessages() {
        Message msg = csvalues.poll();
        int count = 0;
        while (msg != null) {
            count++;
            this.pushMessageToOutbox(msg);
        }
        LOG.debug("Read and produced " + count + " DATA messages.");
        return count;
    }

    /**
     *
     * @return
     */
    @Override
    public boolean isInputConstrainedToCurrentStep() {
        return true;
    }

    /**
     *
     * @param contrain
     */
    @Override
    public void setInputConstrainedToCurrentStep(boolean contrain) {
        // TODO: fixme
    }

    /**
     *
     * @return
     */
    @Override
    public String getSourceLocation() {
        return location;
    }

    /**
     *
     * @param location
     */
    @Override
    public void setSourceLocation(String location) {
        this.location = location;
    }

}
