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
package org.canaryeds.base.util;

import static org.apache.commons.math3.util.FastMath.sqrt;

/**
 * Some basic utility functions for dealing with NaNs that are missing in
 * commons-math3.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class NaNMath {

    /**
     * Calculate the mean, omitting any values which are NaN.
     *
     * @param values the values to use in the calculation
     * @return the mean of the values
     */
    public static double nanmean(double[] values) {
        double sum = 0;
        int count = 0;
        double temp;
        for (int i = 0; i < values.length; i++) {
            temp = values[i];
            if (!Double.isNaN(temp)) {
                sum += temp;
                count++;
            }
        }
        if (count == 0) {
            return Double.NaN;
        }
        return sum / count;
    }

    /**
     * Calculate the sample standard deviation, omitting any values which are
     * NaN.
     *
     * @param values the values to use in the calculation
     * @param mean the mean of the values
     * @return the standard deviation without NaNs
     */
    public static double nanstd(double[] values, double mean) {
        double SSE = 0;
        int count = 0;
        double temp;
        for (int i = 0; i < values.length; i++) {
            temp = values[i];
            if (!Double.isNaN(temp)) {
                SSE += ((temp - mean) * (temp - mean));
                count++;
            }
        }
        if (count < 2) {
            return 0;
        }
        return sqrt(SSE / (count - 1));
    }

}
