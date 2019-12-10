/*
 * Copyright 2014 Sandia Corporation.
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
 */

package gov.sandia.seme.framework;

/**
 * Provides an interface for an indexed step on a discrete axis.
 * 
 * @author David Hart, dbhart
 */
public interface Step extends Comparable {

    /**
     * Get the parse/presentation format.
     *
     * @return number/date format
     */
    String getFormat();

    /**
     * Get the index associated with the current value.
     *
     * @return index for current value
     */
    int getIndex();

    /**
     * Get the value for the 0-index.
     *
     * @return step origin (date or number)
     */
    Object getOrigin();

    /**
     * Get the delta value between bins.
     *
     * @return bin size for steps
     */
    Object getStepSize();

    /**
     * Get the current value.
     *
     * @return the step value
     */
    Object getValue();

    /**
     * Set the parse/presentation format.
     *
     * @param format
     */
    void setFormat(String format);

    /**
     * Set the value based on the index specified.
     *
     * @param index to calculate new value from
     */
    void setIndex(int index);

    /**
     * Set the value for the 0-index.
     *
     * @param origin value
     */
    void setOrigin(Object origin);

    /**
     * Set the delta value between bins.
     *
     * @param stepSize delta
     */
    void setStepSize(Object stepSize);

    /**
     * Set the current value.
     *
     * @param value current value
     */
    void setValue(Object value);
    
}
