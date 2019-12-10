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
 * WIIntegerHOUInteger WARRANIntegerIES OR CONDIIntegerIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package gov.sandia.seme.util;

import gov.sandia.seme.framework.Step;
import static java.lang.Math.ceil;
import java.text.DecimalFormat;
import org.apache.log4j.Logger;

/**
 * Provides a discrete value step object. Underlying values are stored as 
 * Integer objects.
 * 
 * @htmlonly
 * @author David Hart, dbhart
 * @since 1.0
 * @endhtmlonly
 */
public class IntegerStep implements Step {

    static final long serialVersionUID = -8586292539083219916L;
    String format;
    int index;
    Integer origin;
    Integer stepSize;
    Integer value;

    /**
     * Create a new, blank step.
     */
    public IntegerStep() {
        index = Integer.MIN_VALUE;
        origin = null;
        stepSize = null;
        value = null;
        format = "";
        this.calculate();
    }

    /**
     * Create a new step with parameters.
     *
     * @param origin value for the 0-index
     * @param stepSize delta value between step bins
     * @param value current value of the step
     * @param format string parsing/presentation format
     */
    public IntegerStep(Integer origin, Integer stepSize, Integer value, String format) {
        this.origin = new Integer(origin);
        this.stepSize = new Integer(stepSize);
        this.value = new Integer(value);
        this.format = format;
        this.calculate();
    }

    /**
     * Create a new step from another step.
     *
     * @param step to copy
     */
    public IntegerStep(IntegerStep step) {
        this.origin = new Integer(step.origin);
        this.stepSize = new Integer(step.stepSize);
        this.value = new Integer(step.value);
        this.format = step.format;
        this.calculate();
    }

    /**
     * Calculate the integer index from the current value.
     */
    public final void calculate() {
        if (value == null) {
            return;
        }
        double tmp1, tmp2, tmp3;
        tmp1 = ((Number) value).doubleValue();
        tmp2 = ((Number) origin).doubleValue();
        tmp3 = ((Number) stepSize).doubleValue();
        if (tmp3 == 0) {
            return;
        }
        index = (int) ceil((tmp1 - tmp2) / tmp3);
    }

    /**
     * Compare two steps.
     *
     * @param s step to be compared
     * @return comparison (-1=less than, 0=equal, 1=greater than)
     */
    @Override
    public int compareTo(Object s) {
        int ret;
        try {
            ret = ((Integer) value).compareTo((int)((Step) s).getValue());
        } catch (ClassCastException ex) {
            Logger.getLogger("canaryeds").warn(
                    "Comparing different types of steps - now comparing based on index (" + value + "<>"
                    + ((Step) s).getValue() + ")");
            ret = (new Integer(this.getIndex())).compareTo(((Step) s).getIndex());
        }
        return ret;
    }

    /**
     * Get the parse/presentation format.
     *
     * @return number/date format
     */
    @Override
    public String getFormat() {
        return format;
    }

    /**
     * Set the parse/presentation format.
     *
     * @param format
     */
    @Override
    public void setFormat(String format) {
        this.format = format;
    }

    /**
     * Get the index associated with the current value.
     *
     * @return index for current value
     */
    @Override
    public int getIndex() {
        return index;
    }

    /**
     * Set the value based on the index specified.
     *
     * @param index to calculate new value from
     */
    @Override
    public void setIndex(int index) {
        if (value == null) {
            return;
        }
            double tmp2, tmp3;
            tmp2 = ((Number) origin).doubleValue();
            tmp3 = ((Number) stepSize).doubleValue();
            if (tmp3 == 0) {
                return;
            }
            value = (int) ceil((tmp2) + index * tmp3);
        this.calculate();
    }

    /**
     * Get the value for the 0-index.
     *
     * @return step origin (date or number)
     */
    @Override
    public Integer getOrigin() {
        return origin;
    }

    /**
     * Set the value for the 0-index.
     *
     * @param origin value
     */
    @Override
    public void setOrigin(Object origin) {
        this.origin = (Integer) origin;
        this.calculate();
    }

    /**
     * Get the delta value between bins.
     *
     * @return bin size for steps
     */
    @Override
    public Integer getStepSize() {
        return stepSize;
    }

    /**
     * Set the delta value between bins.
     *
     * @param stepSize delta
     */
    @Override
    public void setStepSize(Object stepSize) {
        this.stepSize = (Integer) stepSize;
        this.calculate();
    }

    /**
     * Get the current value.
     *
     * @return the step value
     */
    @Override
    public Integer getValue() {
        return value;
    }

    /**
     * Set the current value.
     *
     * @param value current value
     */
    @Override
    public void setValue(Object value) {
        if (value instanceof String) {
            Integer.getInteger((String) value);
        } else {
            this.value = (Integer) value;
        }
        this.calculate();
    }

    @Override
    public String toString() {
        if (this.value == null) {
            return null;
        }
        if (this.format.contentEquals("")) {
            return this.value.toString();
        }
        if (this.value instanceof Number) {
            return new DecimalFormat(format).format(this.value);
        }
        return this.value.toString();
    }
}

