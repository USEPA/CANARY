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
 * The generic CANARY-compatible interface for evend detection system algorithms.
 * @author dbhart, Sandia National Laboratories
 */
public interface Algorithm {

    /**
     * Configure the algorithm using a text String.
     * @param XMLString    XML structured configuration text
     */
    public void configure(String XMLString);

    /**
     * Configure the algorithm using an XML DOM object.
     * @param DOMObject   processed XML configuration object
     */
    public void configure(Object DOMObject);

    /**
     * Set a configuration parameter by name.
     * @param name   parameter to set
     * @param value  value of the parameter
     */
    public void set_config_parameter(String name, String value);

    /**
     * Read a configuration parameter by name.
     * @param name  parameter to querry
     * @return      value of the parameter
     */
    public String get_config_parameter(String name);


    /**
     * Initialize the algorithm with a certain number of signals.
     * @param n_Sig  number of signals used by this instance of the algorithm
     */
    public void initialize(int n_Sig);


    /**
     * Set the number of signals for this instance of the algorithm.
     * @param n_Sig  number of signals used by this instance of the algorithm
     */
    public void set_num_signals(int n_Sig);

    /**
     * Read the number of signals this algorithm was configured with.
     * @return      number of signals used by this instance of the algorithm
     */
    public int get_num_signals();

    /**
     * Set the length of the history window for this algorithm.
     * @param n_Hist  the length of the history window in time steps
     */
    public void set_history_window_size(int n_Hist);

    /**
     * Querry the length of the history window for this algorithm.
     * @return   the length of the history window in time steps
     */
    public int get_history_window_size();

    /**
     * Set the outlier threshold for this algorithm - a single, normalized value that
     * applies to all signals individually, or to a multivariate evaluation, and
     * residuals with a magnitude greater than this value cause the algorithm to
     * report a status of {@link StatusEnum#OUTLIER OUTLIER}.
     * @param tau_out   the threshold in standard deviations or the algorithm specific definition
     */
    public void set_outlier_threshold(double tau_out);

    /**
     * Get the outlier threshold for this algorithm.
     * @return  the threshold in standard deviations or the algorithm specific definition
     */
    public double get_outlier_threshold();

    /**
     * Set the probability threshold for this algorithm - a value used to determine
     * when the status value changes from <code>OUTLIER</code> to
     * {@link StatusEnum#EVENT EVENT}.
     * @param tau_prob  the probability threshold for this algorithm
     */
    public void set_probability_threshold(double tau_prob);

    /**
     * Get the probability threshold for this algorithm.
     * @return the probability threshold for this algorithm
     */
    public double get_probability_threshold();



    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(RegisterEnum register, double[] data);

    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(String register, double[] data);

    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(RegisterEnum register, int[] data);

    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(String register, int[] data);

    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(RegisterEnum register, boolean[] data);

    /**
     * Set the values for a particular data register based on the register name.
     * @param register the register to assign data into
     * @param data the data to be assigned
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public void set_data_register(String register, boolean[] data);



    /**
     * Querry the algorithm to see if it uses or provides the named data register.
     * @param register the register name to be querried
     * @return True if the register exists and is used, false if the register is
     * unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public boolean uses_register(RegisterEnum register);

    /**
     * Querry the algorithm to see if it uses or provides the named data register.
     * @param register the register name to be querried
     * @return True if the register exists and is used, false if the register is
     * unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public boolean uses_register(String register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public double[] get_data_register(RegisterEnum register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public double[] get_data_register(String register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public int[] get_data_register_int(RegisterEnum register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public int[] get_data_register_int(String register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public boolean[] get_data_register_bool(RegisterEnum register);

    /**
     * Get the values associated with a particular data register, if it exists.
     * @param register the name of the register to querry
     * @return the values stored in the register, or null if the register is unused
     * @exception IllegalArgumentException if the name is not a valid RegisterEnum
     */
    public boolean[] get_data_register_bool(String register);



    /**
     * Set the data link rule to a valid member of the RulesEnum constants.
     * The allowed constants are listed below; CANARY always acts as if it was
     * given LINK_USE_RAW; other options must be handled internally by the algorithm.
     * @param rule  the input data link rule
     * @see Algorithm#keep_by_rule() 
     * @see RulesEnum#LINK_USE_RAW LINK_USE_RAW
     * @see RulesEnum#LINK_USE_PREDICTIONS LINK_USE_PREDICTIONS
     * @see RulesEnum#LINK_USE_CONTRIBUTING LINK_USE_CONTRIBUTING
     * @see RulesEnum#LINK_USE_RESIDUALS LINK_USE_RESIDUALS
     * @see Algorithm#configure(java.lang.Object) 
     */
    public void set_data_rule(RulesEnum rule);

    /**
     * Get the data link rule that is associated with this algorithm.
     * @return  the current data-link rule for this algorithm
     * @see Algorithm#set_data_rule(org.teva.canary.lib.RulesEnum) 
     * @see Algorithm#keep_by_rule()
     */
    public RulesEnum get_data_rule();

    /**
     * Adds to the history window based on the "Keep" rules, as defined in the
     * {@link RulesEnum} constants. This function should be implemented in
     * such a way that it will choose to keep the correct window data based on
     * the rule corresponding to the current detection status. If this function
     * is not implemented, it must throw the appropriate exception -- CANARY
     * will then use its default window handling methods to call one of the
     * helper keep functions.
     * @see Algorithm#keep_current
     * @see Algorithm#keep_predicted
     * @see Algorithm#keep_last
     * @see Algorithm#keep_nans
     * @see Algorithm#keep_zeros
     * @see RulesEnum
     * @see Algorithm#set_data_rule
     * @see Algorithm#get_data_rule
     * @throws UnsupportedOperationException
     */
    public void keep_by_rule();

    /**
     *
     */
    public void keep_current();

    /**
     *
     */
    public void keep_predicted();

    /**
     *
     */
    public void keep_last();

    /**
     *
     */
    public void keep_nans();

    /**
     *
     */
    public void keep_zeros();



    /**
     *
     * @param window
     */
    public void set_history_window_data(double[][] window);

    /**
     *
     * @return
     */
    public double[][] get_history_window_data();



    /**
     *
     */
    public void evaluate();



    /**
     *
     * @param data
     */
    public void set_current_data(double[] data);

    /**
     *
     * @param data
     */
    public void set_current_data(int[] data);

    /**
     *
     * @return
     */
    public double[] get_current_data();

    /**
     *
     * @param good_quality
     */
    public void set_current_usable(boolean[] good_quality);

    /**
     *
     * @return
     */
    public boolean[] get_current_usable();

    /**
     *
     * @param inCalib
     */
    public void set_calibration_status(boolean inCalib);



    /**
     *
     * @return
     */
    public StatusEnum get_detection_status();

    /**
     *
     * @return
     */
    public double get_current_probability();

    /**
     *
     * @return
     */
    public int[] get_contributing_signals();

    /**
     *
     * @return
     */
    public String get_message();

    /**
     *
     * @return
     */
    public double[] get_current_residuals();

    /**
     *
     * @return
     */
    public double[] get_current_predictions();

    /**
     *
     * @return
     */
    public double[] get_d_contributing_signals();

}
