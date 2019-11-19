/* 
 * Copyright 2014 Sandia Corporation.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation, the U.S.
 * Government retains certain rights in this software.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
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
package gov.sandia.seme.framework;

/**
 * @if doxyDev
 * @page devOutputConnections Developing Output Connections
 * 
 * @endif
 */
/**
 * Interface that extends the Messagable class to provide data output
 * functionality. Specifically, OutputConnectionss consume VALUE and RESULT type
 * Messages which are read from the MessageRouter. OutputConnections can be tied
 * to the current Step. If constrained to the current Step, then only messages
 * that fall in the current bin will be read from the router and written to
 * output. If not, then all messages, regardless of their Step value, will be
 * processed and written to output.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface OutputConnection extends Messagable {

    /**
     * Process all available messages.
     *
     * @return number of messages processed
     */
    public int consumeMessagesAndWriteOutput();

    /**
     * Process messages with a specific Step value.
     *
     * @param stepPar minimum Step must have to be processed
     * @return number of messages processed
     */
    public int consumeMessagesAndWriteOutput(Step stepPar);

    /**
     * Get the step constraint setting.
     *
     * @return constraint status
     */
    public boolean isOutputConstrainedToCurrentStep();

    /**
     * Limit processing to messages up to the current step.
     *
     * @param constrain true or false
     */
    public void setOutputConstrainedToCurrentStep(boolean constrain);

    /**
     * Get the String representation for the target of the write.
     *
     * @return file or URL (or other data source location) string
     */
    public String getDestinationLocation();

    /**
     * Set the target of the output to the specified location.
     *
     * @param location string representation of the path/file/URL
     */
    public void setDestinationLocation(String location);
}
