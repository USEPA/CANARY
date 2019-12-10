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
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.PriorityQueue;
import java.util.logging.Level;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userCSVReaderWide Configuration Details: Using text.CSVReaderWide
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
 * flags and CSVReaderWide specific:
 * <p>
 *
 * <ul>
 * <li><b>location:</b> string, defines the filename, URI or URL where the data
 * is location; if a filename is provided, it must be in the same directory as
 * the configuration file or be a fully defined path</li>
 * <li><b>field separator:</b> string, defines the field separation character to
 * be used; default is ","</li>
 * <li><b>header lines:</b> integer, defines the number of header lines before
 * the data starts; the last header line must contain the tag names for the
 * values in each column, therefore, the default value if this option is omitted
 * is 1, and when provided, this value must be greater than 0</li>
 * <li><b>step field:</b> string or integer, defines column where the time step
 * is contained, either by name (case insensitive) or by number, starting at 1
 * for the first column; </li>
 * <li><b>key:</b> type, description</li>
 * <li><b>key:</b> type, description</li>
 * </ul>
 * <p>
 * An example of the options as set out in a YAML configuration file is shown
 * below.
 * <p>
 * <table border=1>
 * <tr><td>
 * <code>
 * connections:<br>
 * &nbsp;&nbsp;# ... other definitions<br>
 * &nbsp;&nbsp;<i>connection name</i><br>
 * &nbsp;&nbsp;&nbsp;&nbsp;text.CSVReaderWide:<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;location: Tutorial_Station_B.csv<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;enabled: true<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;use for: input<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;steps are synchronized: true<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;step field: timestep<br>
 * &nbsp;&nbsp;# ... more definitions<br>
 * </code>
 * </td></tr></table>
 * 
 * @htmlonly
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 3902 $, $Date: 2013-11-01 10:06:41 -0600 (Fri, 01 Nov 2013) $
 * @endhtmlonly
 */
public class CSVReaderWide extends MessagableImpl implements InputConnection {

    private static final Logger LOG = Logger.getLogger(CSVReaderWide.class);
    private PriorityQueue<Message> csvalues = new PriorityQueue();
    private final int format = 1;
    private String dateFormat = null;
    private InputStream inStream = null;
    private InputStreamReader reader = null;
    private boolean isDynamic = false;
    private Step stepStart = null;
    private Step stepFinal = null;
    private String sepChar = ",";

    @Override
    public void configure(Descriptor config) throws ConfigurationException {
        super.configure(config);
        HashMap options = config.getOptions();

        try {
            if (options.get("location") instanceof URL) {
                this.location = options.get("location").toString();
                inStream = ((URL) options.get("location")).openStream();
            } else {
                this.location = (String) options.get("location");
                File loc = new File(location);
                FileInputStream inFile;
                inFile = new FileInputStream(loc.getAbsoluteFile());
                inStream = inFile;
            }
        } catch (IOException ex) {
            java.util.logging.Logger.getLogger(CSVReaderWide.class.getName()).log(
                    Level.SEVERE, null, ex);
        }

        if (options.get("stepFormat") != null) {
            this.dateFormat = ((String) options.get("stepFormat"));
        }
        if (this.getStringOpt("stepField") != null) {
            this.setStringOpt("step field", this.getStringOpt(
                    "stepField"));
        }
        if (options.get("stepStart") != null) {
            this.stepStart = (Step) options.get("stepStart");
        }
        if (options.get("stepFinal") != null) {
            this.stepFinal = (Step) options.get("stepFinal");
        }
        if (options.get("stepDynamic") != null) {
            this.isDynamic = (Boolean) options.get("stepDynamic");
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
            reader = new InputStreamReader(inStream);
            String line = null;                 //The line currently being read.
            String[] labels = null;             //The labels from the first line.
            int lineNum = -1;
            int timesteps = 0;
            if (this.getBaseStep() != null && this.dateFormat == null) {
                this.dateFormat = this.getBaseStep().getFormat();
            }
            int numHeaderLines = 1;
            if (this.getOpt("header lines") != null) {
                numHeaderLines = this.getIntegerOpt("header lines");
            }
            BufferedReader buff = new BufferedReader(reader);
            String sepCharObj = this.getStringOpt("field separator");
            if (sepCharObj != null) {
                sepChar = sepCharObj;
            }
            Object stepFieldObj = this.getOpt("stepfield");
            LOG.trace(stepFieldObj);
            if (stepFieldObj == null) {
                stepFieldObj = this.getOpt("step field");
            }
            LOG.trace(stepFieldObj);
            int stepFieldNum = -1;
            String stepFieldName = null;
            while ((line = buff.readLine()) != null) {
                lineNum++;  //Increment line number.
                //Different formats require different processing.
                if (lineNum < numHeaderLines - 1) {
                    LOG.info("Skipping header line: " + line);
                } else if (lineNum == numHeaderLines - 1) {
                    stepFieldNum = -1;
                    if (stepFieldObj == null) {
                        stepFieldName = "TIME_STEP";
                    } else if (stepFieldObj instanceof Number) {
                        stepFieldNum = ((Number) stepFieldObj).intValue() - 1;
                        stepFieldName = "Column " + (stepFieldNum + 1);
                    } else {
                        stepFieldName = (String) stepFieldObj;
                        if (stepFieldName.isEmpty()) {
                            stepFieldName = "TIME_STEP";
                        }
                    }
                    labels = line.split(sepChar);        //Get labels for first line.
                    LOG.debug(labels);
                    if (stepFieldNum < 0) {
                        for (int iLabel = 0; iLabel < labels.length; iLabel++) {
                            LOG.trace(
                                    iLabel + " " + labels[iLabel] + " " + stepFieldName);
                            if (labels[iLabel].toString().equalsIgnoreCase(
                                    stepFieldName)) {
                                stepFieldNum = iLabel;
                                break;
                            }
                        }
                        if (stepFieldNum < 0) {
                            LOG.fatal(
                                    "Unable to find a step field named '" + stepFieldName + "'! Exiting.");
                            throw new InitializationException(
                                    "Unable to find a step field named '" + stepFieldName + "'!");
                        }
                    }
                } else {                                           //Processing for all additional lines.
                    timesteps = lineNum;
                    String[] lineValues = line.split(",");   //Split the input string into components.
                    Date myDate = new Date(stepFieldNum);
                    try {
                        myDate = (new SimpleDateFormat(this.dateFormat)).parse(
                                lineValues[stepFieldNum]);
                    } catch (ParseException ex) {
                        LOG.error(
                                "Failed to parse date \'" + lineValues[stepFieldNum] + "\' using format \'" + dateFormat + "\'",
                                ex);
                    }
                    Step step;
                    step = new DateTimeStep((DateTimeStep) getBaseStep());
                    step.setValue(myDate);
                    boolean goodLine = false;
                    if (isDynamic) {
                        goodLine = true;
                    } else if (stepStart != null && stepFinal != null) {
                        if (step.compareTo(stepStart) >= 0 && step.compareTo(
                                stepFinal) < 1) {
                            goodLine = true;
                        }
                    } else if (stepStart == null || stepFinal == null) {
                        goodLine = true;
                    }
                    if (goodLine) {
                        for (int i = 0; i < lineValues.length; i++) {  //Iterate through the internal values.
                            if (i == stepFieldNum) {
                                continue;
                            }
                            if (lineValues[i].length() != 0) {
                                HashMap val = new HashMap();
                                val.put("value", Double.parseDouble(
                                        lineValues[i]));
                                Message msg = new Message(MessageType.VALUE,
                                        labels[i], val, step);
                                this.pushMessageToOutbox(msg);
                                LOG.trace(lineNum + " : " + msg);
                            }
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

    @Override
    public boolean isInputConstrainedToCurrentStep() {
        return true;
    }

    @Override
    public void setInputConstrainedToCurrentStep(boolean contrain) {
        // TODO: fixme
    }

    @Override
    public String getSourceLocation() {
        return location;
    }

    @Override
    public void setSourceLocation(String location) {
        this.location = location;
    }

}
