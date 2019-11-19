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
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.MessageType;
import gov.sandia.seme.framework.OutputConnection;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.util.MessagableImpl;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userCSVWriter Configuration Details: Using text.CSVWriter
 * 
 * @endif
 */
/**
 * Write RESULT type Messages to a CSV-formatted file.
 *
 * The following tags are recognized configuration tags:
 * <table><tr><th>Option tag</th><th>Type (in bold) and description</th></tr>
 * <tr><td>location</td><td><b>String</b>: URL or file location.</td></tr>
 * <tr><td>columnKeys</td><td><b>List of Strings</b>: an ordered list of keys
 * that should be read from the message and output by columns in the specified
 * order. The key "step" will output the step value of the message; A key of
 * "tag" will output the message id.<p>
 * If this entry is omitted, the default keys, as defined by the framework or
 * program's components object, will be queried and used.</td></tr>
 * <tr><td>columnHeaders</td><td><b>List of Strings</b>: an ordered list of
 * column headers. This is optional, and the output key is the default
 * header.</td></tr>
 * <tr><td>columnFormats</td><td><b>List of Strings</b>: an ordered list of
 * formats that should be used (C/C++ printf-style codes). If this is omitted,
 * then all key-values will be be output as the default toString()
 * values.</td></tr>
 * <tr><td> </td><td><b> </b>: </td></tr>
 * </table>
 * 
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class CSVWriter extends MessagableImpl implements OutputConnection {

    private static final Logger LOG = Logger.getLogger(CSVWriter.class);
    private String[] resultKeyList;
    private String[] resultKeyHeaders;
    private String resultFormatString;
    private int messagesWritten;

    public CSVWriter() {
        this.messagesWritten = -1;
        this.resultFormatString = null;
        this.resultKeyHeaders = null;
        this.resultKeyList = null;
    }

    @Override
    public void configure(Descriptor config) throws ConfigurationException {
        super.configure(config);
        HashMap options = config.getOptions();
        this.location = (String) options.get("location");
    }

    @Override
    public int consumeMessagesAndWriteOutput(Step step) {
        int count = 0;
        Message newData;
        newData = this.pollMessageFromInbox(step);
        while (newData != null) {
            LOG.trace(newData);
            count = count + 1;
            messagesWritten += 1;
            if (this.location != null) {
                if (newData.getType() == MessageType.RESULT) {
                    try {
                        String formatString;
                        if (messagesWritten == 0) {
                            formatString = this.initHeadersAndFormat(
                                    newData.getData());
                        } else {
                            formatString = this.resultFormatString;
                        }
                        File loc = new File(location).getAbsoluteFile();
                        FileWriter outFile;
                        PrintWriter out;
                        outFile = new FileWriter(loc, true);
                        out = new PrintWriter(outFile);
                        Object[] outputObjectArray = new Object[this.resultKeyList.length];
                        int i = 0;
                        for (String key : this.resultKeyList) {
                            switch (key) {
                                case "step":
                                    outputObjectArray[i] = newData.getStep().toString();
                                    break;
                                case "tag":
                                    outputObjectArray[i] = newData.getTag();
                                    break;
                                default:
                                    Object val = newData.getData().get(key);
                                    if (val != null) {
                                        outputObjectArray[i] = val.toString();
                                    } else {
                                        outputObjectArray[i] = null;
                                    }
                                    break;
                            }
                            i++;
                        }
                        out.printf(formatString, outputObjectArray);
                        out.flush();
                        out.close();
                    } catch (IOException ex) {
                        LOG.error(
                                "Problem writing to output file ''" + this.location + "''",
                                ex);
                    }
                } else if (newData.getType() == MessageType.VALUE) {
                }
            }
            if (step == null) {
                newData = this.pollMessageFromInbox();
            } else {
                newData = this.pollMessageFromInbox(step);
            }
        }
        LOG.debug(
                "Consumed and wrote " + count + " RESULT messages for Step=" + step + ".");
        return count;
    }

    @Override
    public Descriptor getConfiguration() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void initialize() throws InitializationException {
        try {
            File loc = new File(location).getAbsoluteFile();
            FileWriter outFile;
            PrintWriter out;
            outFile = new FileWriter(loc);
            out = new PrintWriter(outFile);
            this.resultKeyList = new String[]{
                "step", "tag",
                "eventCode",
                "eventProbability",
                "contribParameters",
                "workflowName",
                "message",
                "eventIdentifierName",
                "eventIdentifierId",
                "eventIdentifierProbability",
                "byChannelResiduals"};
            out.printf("Output from CANARY-EDS 5.0\n");
            out.flush();
            out.close();
        } catch (IOException ex) {
            LOG.fatal("fatal error initializing " + this.name + "for output", ex);
            throw new InitializationException(
                    "error initializing " + this.name + "for output use");
        }
    }

    /**
     * Generate headers for the CSV file and create the format string.
     *
     * @param data a data message to use as a template
     * @return format string for the
     */
    private String initHeadersAndFormat(HashMap data) {
        try {
            String[] headers = new String[]{
                "Step", "Tag",
                "Status",
                "Probability of Event",
                "Contributing Parameters",
                "Workflow Name",
                "Message",
                "Event Identifier",
                "Event Id (Name or ID)",
                "Event Id (Probability)",
                "Residuals" + data.get("byChannelParameters")};
            String format;
            File loc = new File(location).getAbsoluteFile();
            FileWriter outFile;
            PrintWriter out;
            outFile = new FileWriter(loc, true);
            out = new PrintWriter(outFile);
            format = "";
            for (String resultKeyHeader : headers) {
                out.printf("%s,", resultKeyHeader);
                format += "%s,";
            }
            format += "\n";
            out.printf("\n");
            out.flush();
            out.close();
            this.resultKeyHeaders = headers;
            this.resultFormatString = format;
            return format;
        } catch (IOException ex) {
            LOG.fatal("fatal error initializing " + this.name + "for output", ex);
            return null;
        }
    }

    /**
     *
     * @return
     */
    @Override
    public int consumeMessagesAndWriteOutput() {
        return consumeMessagesAndWriteOutput(null);
    }

    /**
     *
     * @return
     */
    @Override
    public boolean isOutputConstrainedToCurrentStep() {
        return true;
    }

    /**
     *
     * @param constrain
     */
    @Override
    public void setOutputConstrainedToCurrentStep(boolean constrain) {
        // TODO: fixme
    }

    /**
     *
     * @return
     */
    @Override
    public String getDestinationLocation() {
        return location;
    }

    /**
     *
     * @param location
     */
    @Override
    public void setDestinationLocation(String location) {
        this.location = location;
    }

}
