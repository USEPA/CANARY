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

import java.io.Serializable;

/**
 * Provides methods for handling meta-data attributes attached to an object. The
 * underlying implementation left to the user, this interface defines methods
 * for setting and retrieving key:value pairs of information for a given object.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface Describable extends Serializable {

    /**
     * Get a named option.
     *
     * @param name the key name
     * @return the value
     */
    Object getOpt(String name);

    /**
     * Set a named option.
     *
     * @param name the key name
     * @param val the new value
     */
    void setOpt(String name, Object val);

    /**
     * Get a named option as a double.
     *
     * @param name the key name
     * @return the value
     */
    double getDoubleOpt(String name);

    /**
     * Set a named option from a double.
     *
     * @param name the key name
     * @param val the new value
     */
    void setDoubleOpt(String name, double val);

    /**
     * Get a named option as a string.
     *
     * @param name the key name
     * @return the value
     */
    String getStringOpt(String name);

    /**
     * Set the named option as a string.
     *
     * @param name the key name
     * @param val the new value
     */
    void setStringOpt(String name, String val);

    /**
     * Get a named option as an integer.
     *
     * @param name the key name
     * @return the value
     */
    int getIntegerOpt(String name);

    /**
     * Set the named option as an integer.
     *
     * @param name the key name
     * @param val the new value
     */
    void setIntegerOpt(String name, int val);

    /**
     * Get a named option as a double array.
     *
     * @param name the key name
     * @return the value array
     */
    double[] getDoubleArrayOpt(String name);

    /**
     * Set the named option to an array of doubles.
     *
     * @param name the key name
     * @param values the new list of values
     */
    void setDoubleArrayOpt(String name, double[] values);

    /**
     * Get a named option as a string array.
     *
     * @param name the key name
     * @return the value array
     */
    String[] getStringArrayOpt(String name);

    /**
     * Set the named option to an array of Strings.
     *
     * @param name the key name
     * @param values the new list of values
     */
    void setStringArrayOpt(String name, String[] values);

    /**
     * Get a named option as an integer array.
     *
     * @param name the key name
     * @return the value array
     */
    int[] getIntegerArrayOpt(String name);

    /**
     * Set the named option to an array of integers.
     *
     * @param name the key name
     * @param values the new list of values
     */
    void setIntegerArrayOpt(String name, int[] values);

    /**
     * Set the underlying meta-data obeject.
     *
     * @param metaData the new meta-data object
     */
    void setMetaData(Object metaData);

    /**
     * Get the underlying meta-data storage object.
     *
     * @return the underlying meta-data storage object
     */
    Object getMetaData();

    /**
     * Get a list of all key names.
     *
     * @return the list of all key names
     */
    String[] getOptKeys();

}
