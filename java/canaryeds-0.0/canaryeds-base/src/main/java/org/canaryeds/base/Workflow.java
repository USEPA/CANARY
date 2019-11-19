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
package org.canaryeds.base;

import gov.sandia.seme.framework.DataChannel;
import gov.sandia.seme.framework.Describable;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * @if doxyDev
 * @page devWofklows Developing %Workflow Classes for Event Detection Algorithms
 * 
 * @endif
 */
/**
 * Provides the algorithmic controls for the event detection process of the
 * CANARY-EDS program. The implementation classes include the basic algorithms
 * that were a part of previous versions of CANARY-EDS.
 *
 * @htmlonly
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 4363 $, $Date: 2014-06-16 10:01:49 -0600 (Mon, 16 Jun 2014) $
 * @endhtmlonly
 */
public interface Workflow extends Describable {

    /**
     * Link to a data channel instance from the monitoring station
     *
     * @param channel DataChannel to link
     */
    public void addChannel(DataChannel channel);

    /**
     * Remove link to a data channel
     *
     * @param name id of channel to remove
     */
    public void removeChannel(String name);

    /**
     * Get the data channel list
     *
     * @return the data channel list
     */
    public ArrayList<DataChannel> getChannels();

    /**
     * Run the workflow and generate results
     *
     * @param index step to evaluate
     * @return HashMap of results values
     */
    public HashMap evaluateWorkflow(int index);

    /**
     * Get the maximum window size needed to run this workflow.
     *
     * @return number of points to keep in memory
     */
    public int getMaxWindowNeeded();

    /**
     * Get the number of steps prior to an event to keep.
     *
     * @return number of steps prior to an event to keep
     */
    public int getPreEventHistoryCount();

    /**
     * Configure the workflow.
     *
     * @param desc the configuration options of the workflow
     * @throws ConfigurationException the workflow has invalid options
     */
    public void configure(Descriptor desc) throws ConfigurationException;

    /**
     * Initialize the workflow.
     *
     * @throws InitializationException the workflow failed during initialization
     */
    public void initialize() throws InitializationException;

    /**
     * Get the name of the workflow.
     *
     * @return name of the workflow
     */
    public String getName();

    /**
     * Set the name of the workflow
     *
     * @param name new value of the name
     */
    public void setName(String name);

    /**
     * Get the configuration.
     *
     * @return descriptor configuration object
     */
    public Descriptor getConfiguration();

    /**
     * Get the raw data on a channel-by-channel basis.
     *
     * @return array of channel raw data
     */
    public Double[] getChannelRawData();

    /**
     * Get the residuals on a channel-by-channel basis.
     *
     * @return array of channel residuals
     */
    public Double[] getChannelResiduals();

    /**
     * Get the control-limit violations on a channel=by-channel basis.
     *
     * @return array of violations
     */
    public Integer[] getChannelViolations();

    /**
     * Get the contributing factor settings on a channel-by-channel basis.
     *
     * @return array of contributing parameter
     */
    public Short[] getChannelContributed();

    /**
     * Get the parameters.
     *
     * @return array of the parameter names
     */
    public String[] getChannelParameters();

    /**
     * Get the tags of each of the channels.
     *
     * @return array of tag names
     */
    public String[] getChannelTags();

    /**
     * Get the probability of an event.
     *
     * @return probability that this is an event
     */
    public double getProbability();

    /**
     * Get the event status.
     *
     * @return status enumeration code
     */
    public EventStatus getStatus();

}
