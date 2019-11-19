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

import java.util.ArrayList;

/**
 * Provide status enums for the result code from event detection.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public enum EventStatus {

    NORMAL(0),
    UNINITIALIZED(1),
    OUTLIER_DETECTED(2),
    POSSIBLE_EVENT(4),
    EVENT_TIMEOUT(8),
    EVENT_IDENTIFIED(16),
    DATA_MISSING(32),
    CHANNELS_ALARMING(64),
    STATION_CALIBRATING(128);

    private final int code;

    /**
     * Set the current code.
     * @param code The code value.
     */
    EventStatus(int code) {
        this.code = code;
    }

    /**
     * Get the value of the code.
     * @return The code.
     */
    public int code() {
        return code;
    }
    /**
     * Parse the provided code.
     * @param code The code to parse.
     * @return The parsed code array.
     */
    public static String[] parseCode(int code) {
        ArrayList<String> res = new ArrayList();
        res.add(Integer.toString(code));
        for (EventStatus s : EventStatus.values()) {
            if ((code & s.code()) > 0) {
                res.add(s.toString());
            }
        }
        String[] a = new String[res.size()];
        return res.toArray(a);
    }

}
