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
 * Provides algorithm handling rules to the engine.
 * <p>
 * There are three types of rules defined in this enumerated constant class. The
 * first are Register Activation Rules, which define which inputs and outputs
 * should be used by the algorithm. How these are implemented is left to the
 * algorithm author.
 * <p>
 * The second type are Window Storage Rules, or "Keep" rules.
 * These rules tell the algorithm how to add to the moving history window, and
 * define the behavior of the {@link Algorithm#keep_by_rule() } function. If this
 * function throws an {@link UnsupportedOperationException} exception, then CANARY
 * will use its default logic to call one of the other <code>keep</code> functions.
 * <p>
 * The last type are Linker Rules. These rules are used in the {@link org.teva.canary.algs.MultiAlgorithmLinker MultiAlgorithmLinker}
 * algorithm, and can be used to tell an algorithm or engine how to link together
 * multiple detection algorithms. However, these rules are *not* used by CANARY
 * itself - they must be implemented by the algorithm author, such as in the
 * <code>MultiAlgorithmLinker</code> class.
 * <p>
 * The options specified here as enumerated constants are specified using the
 * configuration XML code during setup. The default values for each register, and
 * whether the register exists or does not exist by default are defined by the
 * algorithm, not by CANARY. These options are used to override the defualt
 * settings, and if the defaults are acceptable, then none of these need to be
 * specified during configuration. The options are specified using the "rule-option"
 * tag, with the enum constant name as the text content of the tag.
 * <p>
 * All algorithms must be able to handle these options during configuration
 * without throwing an exception, even the algorithm simply ignores these options during
 * the {@link Algorithm#configure(java.lang.Object) configure} call.
 *
 * @version 0.9
 * @author dbhart
 */
public enum RulesEnum {

    /**
     * All input registers are turned on. Assignments will store data in the
     * register if it exists, querries will return the stored data or null.
     */
    REG_INPUTS_ON,
    /**
     * All input registers are turned off. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_INPUTS_OFF,
    /**
     * The {@link RegisterEnum#AUTO_IGNORE AUTO_IGNORE} register is active. Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_AUTO_IGNORE_ON,
    /**
     * The <code>AUTO_IGNORE</code> register is inactive or does not exist. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_AUTO_IGNORE_OFF,
    /**
     * The {@link RegisterEnum#CLUSTERIZABLE CLUSTERIZABLE} register is active. Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_CLUSTERIZABLE_ON,
    /**
     * The <code>CLUSTERIZABLE</code> register is inactive. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_CLUSTERIZABLE_OFF,
    /**
     * The {@link RegisterEnum#DATA_LIM_LOW DATA_LIM_LOW} and {@link RegisterEnum#DATA_LIM_HIGH}
     * registers are active. Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_DATA_LIM_ON,
    /**
     * The <code>DATA_LIM_LOW</code> and <code>DATA_LIM_HIGH</code> registers are inactive. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_DATA_LIM_OFF,
    /**
     * The {@link RegisterEnum#SETPOINT_LIM_LOW SETPOINT_LIM_LOW} and
     * {@link RegisterEnum#SETPOINT_LIM_HIGH SETPOINT_LIM_HIGH}
     * registers are active. Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_SETPOINT_LIM_ON,
    /**
     * The <code>SETPOINT_LIM_LOW</code> and <code>SETPOINT_LIM_HIGH</code>
     * registers are inactive. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_SETPOINT_LIM_OFF,
    /**
     * The {@link RegisterEnum#DELTA_MIN DELTA_MIN} register is active.
     * Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_DELTA_MIN_ON,
    /**
     * The <code>DELTA_MIN</code> register is inactive. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_DELTA_MIN_OFF,
    /**
     * The {@link RegisterEnum#CURRENT_USEABLE CURRENT_USEABLE} register is active.
     * Assignments will store data in the
     * register if it exists, querries will return the stored data.
     */
    REG_CURRENT_USEABLE_ON,
    /**
     * The <code>CURRENT_USEABLE</code> register is inactive. Assignments will be ignored by the
     * algorithm, and querries will return null.
     */
    REG_CURRENT_USEABLE_OFF,
    /**
     * Store all outputs from this algorithm in its internal memory.
     */
    REG_OUTPUTS_ON,
    /**
     * Do not store any outputs from this algorithm in its internal memory.
     */
    REG_OUTPUTS_OFF,
    /**
     * Store residuals from this algorithm when complete, possibly
     * overwriting existing stored residuals.
     */
    REG_CURRENT_RESIDUALS_ON,
    /**
     * Do not overwrite or store residuals from this algorithm in the engine.
     */
    REG_CURRENT_RESIDUALS_OFF,
    /**
     * Store predictions from this algorithm when complete, possibly
     * overwriting existing stored predictions.
     */
    REG_CURRENT_PREDICTIONS_ON,
    /**
     * Do not overwrite or store predictions from this algorithm in the engine.
     */
    REG_CURRENT_PREDICTIONS_OFF,
    /**
     * Store contributing parameters from this algorithm when complete, possibly
     * overwriting existing stored contributing parameters.
     */
    REG_CURRENT_CONTRIBUTORS_ON,
    /**
     * Do not overwrite or store current contributing signals from this algorithm.
     */
    REG_CURRENT_CONTRIBUTORS_OFF,
    
    /**
     * Use the raw data as input to this algorithm. This is always the information
     * that CANARY will provide, using the other link methods requires user
     * implementation within the algorithm. See the {@link org.teva.canary.algs.MultiAlgorithmLinker MultiAlgorithmLinker}
     * class for an example of how to implement a linked algorithm.
     */
    LINK_USE_RAW,
    /**
     * Use the last algorithm's residuals as input to this algorithm.
     */
    LINK_USE_RESIDUALS,
    /**
     * Use the last algorithm's predictions as input to this algorithm.
     */
    LINK_USE_PREDICTIONS,
    /**
     * Use the list of contributing signals as input to this algorithm.
     */
    LINK_USE_CONTRIBUTING,

    /**
     * Add the current raw data to the window when detection status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_NORMAL_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NORMAL_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NORMAL_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NORMAL_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NORMAL_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is NORMAL.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NORMAL_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_OUTLIER_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_OUTLIER_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_OUTLIER_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_OUTLIER_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_OUTLIER_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is OUTLIER.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_OUTLIER_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_EVENT_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_EVENT_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_EVENT_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_EVENT_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_EVENT_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is EVENT.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_EVENT_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_MISSING_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MISSING_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MISSING_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MISSING_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MISSING_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is MISSINGHIST.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MISSING_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NODATA_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NODATA_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_NODATA_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NODATA_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NODATA_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is NODATA.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_NODATA_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_CALIB_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_CALIB_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_CALIB_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_CALIB_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_CALIB_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is CALIBRATION.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_CALIB_KEEP_CONTRIB,

    /**
     * Add the current raw data to the window when detection status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     * Default rule in the {@link org.teva.canary.algs.BaseAlgorithm} abstract class.
     */
    ON_MATCH_KEEP_CURRENT,
    /**
     * Add the predicted values in the window when detection status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MATCH_KEEP_PREDICT,
    /**
     * Add a row of NaN's in the window when detection status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MATCH_KEEP_NANS,
    /**
     * Repeat the last row of data (or, alternately, don't shift the window) when
     * detection status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MATCH_KEEP_LAST,
    /**
     * Add a row of zeros (0) in the window when detection status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MATCH_KEEP_ZEROS,
    /**
     * Add the contributing signal indicators to the window when status is MATCH.
     * This applies when using the {@link Algorithm#keep_by_rule() } function.
     */
    ON_MATCH_KEEP_CONTRIB,
}
