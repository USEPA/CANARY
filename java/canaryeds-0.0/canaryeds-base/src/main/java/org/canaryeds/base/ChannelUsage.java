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
package org.canaryeds.base;

/**
 * Provides usage types for DataChannel objects.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public enum ChannelUsage {

    /**
     * The channel is for quality data, used in event detection.
     */
    QUALITY,
    /**
     * The channel is for operations data, used in event identification
     * only.
     */
    OPERATIONS,
    /**
     * The channel is an alarm channel for another channel.
     */
    CHANNEL_ALARM,
    /**
     * The channel is a calibration flag for a station.
     */
    STATION_CALIB,
    /**
     * The channel is for informational purposes only, and is not used in
     * ED/EI.
     */
    INFORMATION,
    /**
     * The channel is a calculation step only.
     */
    COMPOSITE_NQ
}
