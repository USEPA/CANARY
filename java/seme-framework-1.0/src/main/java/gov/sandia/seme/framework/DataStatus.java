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
 * Provides status values for data channels. The status codes determine how the
 * the data within a given channel should be used by a ModelConnection
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @see gov.sandia.seme.framework.DataChannel
 * @endhtmlonly
 */
public enum DataStatus {

    /**
     * The channel is operating normally, and the value is valid.
     */
    NORMAL,
    /**
     * The last expected value was missing.
     */
    MISSING,
    /**
     * The value has been the same for too long, and is unreliable.
     */
    FROZEN,
    /**
     * The value was of an invalid type (Text instead of a Number) or was NaN.
     */
    INVALID,
    /**
     * The value is outside the control limits (set points) specified for this channel.
     */
    OUT_OF_CTL_LIMIT,
    /**
     * The value is outside the valid range for values on this channel.
     */
    OUT_OF_VALID_RANGE,
    /**
     * The channel has been flagged as being "offline," and values should not be
     * used.
     */
    FLAGGED_OFFLINE,
    /**
     * The channel has been flagged as being in calibration mode, and values
     * should not be used.
     */
    FLAGGED_CALIBRATION,
    /**
     * The channel has been flagged as having incorrect values or other quality
     * concerns, and the values should not be used.
     */
    FLAGGED_BAD_QUALITY

}
