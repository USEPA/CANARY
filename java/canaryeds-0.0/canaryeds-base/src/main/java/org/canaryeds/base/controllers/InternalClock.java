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
package org.canaryeds.base.controllers;

import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.ControllerImpl;

/**
 * @if doxyUser
 * @page userInternalClock Configuration Details: Using controllers.InternalClock
 * 
 * @endif
 */
/**
 * Provides Controller for a run in real-time mode. This increments the
 * steps from a start step (or the current date/time) until a termination point
 * is reached. Termination can either be based on a literal stop step, a maximum
 * number of steps, or an event/signal is received.
 * 
 * @internal
 * @author dbhart
 * @author $LastChangedBy: nprackl $
 * @version $Rev: 4364 $, $Date: 2014-06-18 18:32:06 -0600 (Wed, 18 Jun 2014) $
 */
public class InternalClock extends ControllerImpl {

    /**
     * Get the configuration. Currently not supported.
     * @return The current configuration.
     */
    @Override
    public Descriptor getConfiguration() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Run the current program. Currently not supported.
     */
    @Override
    public void run() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Set the current save state. Currently not supported.
     */
    @Override
    public void saveState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Set the current load state. Currently not supported.
     */
    @Override
    public void loadState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Configure the current object with a given descriptor. Currently not supported.
     * @param controls The descriptor to use for configuring current object.
     */
    @Override
    public void configure(Descriptor controls) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Set the step start value.
     * @param step The step start value.
     */
    @Override
    public void setStepStart(Step step) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Get the step start value.
     * @return The step start value.
     */
    @Override
    public Step getStepStart() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Set the step stop value.
     * @param step The step stop value.
     */
    @Override
    public void setStepStop(Step step) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Get the step stop value.
     * @return The step stop value.
     */
    @Override
    public Step getStepStop() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Set the step base value.
     * @param step The value to set.
     */
    @Override
    public void setStepBase(Step step) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Get the step base value.
     * @return 
     */
    @Override
    public Step getStepBase() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
}
