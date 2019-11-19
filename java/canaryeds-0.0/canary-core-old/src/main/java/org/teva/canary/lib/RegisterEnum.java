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
 * Describes the different types of data registers for CANARY.
 * All of these types must at least be handled by an engine or algorithm
 * implementation through the {@link Algorithm#set_data_register set_data_register} methods.
 * Some of the per-time-step methods are also handled directly, such as through the
 * {@link Algorithm#get_contributing_signals() get_contributing_signals} or the
 * {@link Algorithm#set_current_usable(boolean[]) set_current_usable} methods.
 * @author dbhart
 */
public enum RegisterEnum {

    /**
     * Eliminate certain signals from analysis automatically.
     * 
     * This register is used to indicate that ceratin data streams are not to be
     * analized by this engine/algorithm for some reason. A typical use is to
     * remove operational data from analysis, especially on/off indicators. This
     * can also be useful when debugging as certain information may be of
     * informational benefit while not being of use for event detection. This
     * register is set by CANARY during the configuration of a station, when the
     * algorithm is initially instantiated.
     */
    AUTO_IGNORE,

    /**
     * Limit change detection to a minimum absolute value for each signal.
     *
     * This is an absolute -- not relative -- minimum change that must occur in
     * a signal before an event or outlier can be detected in this signal. This
     * register is set by CANARY during the configuration of a station, when the
     * algorithm is initially instantiated.
     */
    DELTA_MIN,

    /**
     * Eliminate data below this limit as it is always invalid.
     * 
     * This register is a lower bound for data, below which the data is obviously
     * erroneous. For example, setting a chlorine data minimum to 0.0 would be
     * useful, as a negative concentration is a physical impossibility. However,
     * setting a value for chlorine of 0.2 ppm because "it just doesn't happen"
     * would be a poor choice, since the goal of event detection is to find
     * exactly such an event, and there are clearly contaminants that could make
     * chlorine drop to 0.0 ppm. In the case where a lower limit to <i>probable</i>
     * values is desired, see {@link #SETPOINT_LIM_LOW}. This register is set by
     * CANARY during the configuration of a station, when the algorithm is
     * initially instantiated.
     * @see #DATA_LIM_HIGH
     */
    DATA_LIM_LOW,

    /**
     * Eliminate data above this limit as it is always invalid.
     *
     * The upper bound register for data. See {@link #DATA_LIM_LOW} for a
     * full discussion of this type of register. This register is set by CANARY
     * during the configuration of a station, when the algorithm is initially
     * instantiated.
     * @see #DATA_LIM_LOW
     */
    DATA_LIM_HIGH,

    /**
     * Data below this limit is always an outlier or event.
     *
     * This register is a set-point lower bound for values of data signals during normal
     * operations. If values fall below this limit, the engine or algorithm
     * should indicate it by changing the status code. See also {@link #DATA_LIM_LOW}
     * for a discussion of absolute data value limits. This register is set by
     * CANARY during the configuration of a station, when the algorithm is
     * initially instantiated.
     * @see #SETPOINT_LIM_HIGH
     */
    SETPOINT_LIM_LOW,

    /**
     * Data above this limit is always an outlier or event.
     *
     * The upper bound register for set-point analysis. See {@link #SETPOINT_LIM_LOW}
     * for a full discussion of this type of register. This register is set by
     * CANARY during the configuration of a station, when the algorithm is
     * initially instantiated.
     * @see #SETPOINT_LIM_LOW
     */
    SETPOINT_LIM_HIGH,

    /**
     * Eliminate certain signals from any clustering or matching activities.
     *
     * This register contains indicators of whether a signal should be used in
     * clustering or pattern matching algorithms. Signals that are {@link #AUTO_IGNORE ignored}
     * can still be clusterizable. This register is set by CANARY during the
     * configuration of a station, when the algorithm is initially instantiated.
     */
    CLUSTERIZABLE,

    /**
     * Quality flags for the current data.
     *
     * This is an input register to modify the current time step's data signals
     * based on SCADA quality tags or linked alarm tags. A "good" value is true,
     * a "bad" value is passed as false; how these are handled internally is up
     * to the algorithm. This register is set by CANARY at every time step.
     */
    CURRENT_USEABLE,

    /**
     * Signals that contributed to an event status at the current time step.
     *
     * An output register for reading contributing signals. By convention, any
     * non-zero value is considered a contributing signal, but values of +/- 1
     * are typically used to indicate an observed value that is above (+) the
     * predicted value or below (-) the predicted value. This register is read
     * by CANARY at every time step.
     */
    CURRENT_CONTRIBUTORS,

    /**
     * Values predicted by the algorithm at the current time step.
     *
     * For algorithms that use predicted values, this output register can be
     * used to access those predictions. CANARY's engine does not currently
     * read these values in.
     */
    CURRENT_PREDICTIONS,

    /**
     * Residuals between the current values and predicted values.
     *
     * The error in prediction is stored in this output register. CANARY does
     * not require the residuals to be defined as (PREDICTED - OBSERVED) or
     * (OBSERVED - PREDICTED); it is up to the algorithm to define the residual
     * calculation. This register is read by CANARY at every time step.
     */
    CURRENT_RESIDUALS;
    
}
