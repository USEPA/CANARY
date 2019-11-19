/*
 * Copyright 2007-2010 Sandia Corporation.
 * This source code is distributed under the LGPL License.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
 * the U.S. Government retains certain rights in this software.
 * This software was written as part of an Inter-Agency Agreement between
 * Sandia National Laboratories and the US EPA NHSRC.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version. This library is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */
package org.teva.canary.lib;

/**
 * Status symbols returned to the tool by CANARY
 *
 * @author dbhart, Sandia National Laboratories
 * @version 0.9
 */
public enum StatusEnum {

    /**
     * The algorithm has not been initialized or fully configured.
     */
    UNINITIALIZED,

    /**
     * The algorithm has not fully filled the history window at least one time.
     */
    MISSINGHIST,

    /**
     * There is no event or outlier detected.
     */
    NORMAL,

    /**
     * The evaluation of the current timestep is that an outlier has occurred.
     */
    OUTLIER,

    /**
     * The evaluation of the current timestep is that an event has occurred.
     */
    EVENT,

    /**
     * The current time series matches a known event of some kind.
     */
    MATCH,

    /**
     * The calibration mode flag has been set and the algorithm was processed accordingly.
     */
    CALIBRATION,

    /**
     * No data was available or no data provided to the algorithm.
     */
    NODATA;

}
