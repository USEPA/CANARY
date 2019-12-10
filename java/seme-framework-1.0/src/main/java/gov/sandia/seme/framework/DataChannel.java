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

import java.util.ArrayList;

/**
 * @if doxyDev 
 * @page devDataChannel Developing Data Channels
 * 
 * @endif
 */
/**
 * Interface that describes a named data stream. The data channel provides
 * meta-data and structure around the values which are provided in Messages. The
 * data channel has internal workings that validate new values, control how many
 * values remain in memory, potentially modify values based on the values in
 * other channels, and that return either a double or string value back when
 * asked.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface DataChannel extends Describable {

    /**
     * Add a new value to the channel.
     *
     * @param value the value to be added at the index provided in the step
     * @param step the step that the value is aligned with
     */
    void addNewValue(Object value, Step step);

    /**
     * Add a value to the requires array.
     *
     * @param tag value to add to the requires array
     */
    void addRequires(String tag);

    void linkChannel(DataChannel chan);

    void unlinkChannel(DataChannel chan);

    /**
     * Configure the channel according to the descriptor.
     *
     * @param desc the configuration Descriptor
     */
    void configure(Descriptor desc);

    /**
     * Initialize all values and clear data.
     */
    void initialize();

    /**
     * Get the value of the implementing class
     *
     * @return the name of the implementing class
     */
    String getClassName();

    /**
     * Get the configuration in a Descriptor.
     *
     * @return the configuration
     */
    Descriptor getConfiguration();

    /**
     * Get the double value associated with an index.
     *
     * @param index integer Step index
     * @return the double representation of the value at index
     */
    double getDoubleValue(int index);

    /**
     * Get the integer value associated with an index.
     *
     * @param index integer Step index
     * @return the integer representation of the value at index
     */
    int getIntegerValue(int index);

    /**
     * Get the name of this data channel.
     *
     * @return the name of this data channel used in configuration files
     */
    String getName();

    /**
     * Set the name of this data channel.
     *
     * @param name the new value of name
     */
    void setName(String name);

    /**
     * Set the value of newDataStyle
     *
     * @param style the new value of newDataStyle
     */
    void setNewDataStyle(MissingDataPolicy style);

    /**
     * Get the list of required input channel tags.
     *
     * @return list of required input channel tags
     */
    ArrayList<String> getRequires();

    /**
     * Set the list of required input channel tags.
     *
     * @param requires the new value of requires
     */
    void setRequires(ArrayList<String> requires);

    /**
     * Get the value of status.
     *
     * @return the value of status
     */
    DataStatus getStatus();

    /**
     * Get the string value at a given index.
     *
     * @param index integer step index
     * @return the string value or representation at index
     */
    String getStringValue(int index);

    /**
     * Get the routing tag for this channel.
     *
     * @return the routing tag value
     */
    String getTag();

    /**
     * Set the value of the routing tag.
     *
     * @param tag the new value of the routing tag
     */
    void setTag(String tag);

    /**
     * Get the value of type.
     *
     * @return the channel type
     */
    ChannelType getType();

    /**
     * Get the value at a given step index.
     *
     * @param index integer Step index
     * @return the value at index as an Object
     */
    Object getValue(int index);

    /**
     * Remove a single tag from the list of requires.
     *
     * @param tag the tag to be removed
     */
    void removeRequires(String tag);
}
