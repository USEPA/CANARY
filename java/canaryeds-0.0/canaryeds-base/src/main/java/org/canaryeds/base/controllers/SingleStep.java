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

import gov.sandia.seme.framework.ComponentType;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.util.ControllerImpl;
import gov.sandia.seme.util.DateTimeStep;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userSingleStep Configuration Details: Using controllers.SingleStep
 *
 * @endif
 */
/**
 * Provides Controller to run on a single step. The controller will then
 * serialize the Engine to a continuation file and exit. This is typically only
 * used when the application de-serializes or loads state prior to running the
 * controller.
 *
 * @internal
 * @author dbhart
 * @author $LastChangedBy: nprackl $
 * @version $Rev: 4364 $, $Date: 2014-06-18 18:32:06 -0600 (Wed, 18 Jun 2014) $
 */
public class SingleStep extends ControllerImpl {

    private static final Logger LOG = Logger.getLogger(Batch.class);

    static final long serialVersionUID = 4082133680255940892L;
    private int curIndex = -1;

    /**
     * Configure the single step controller.
     * @param desc The descriptor containing configuration data.
     * @throws ConfigurationException 
     */
    @Override
    public void configure(Descriptor desc) throws ConfigurationException {
        LOG.info("Configuring controller");
        super.configure(desc); //To change body of generated methods, choose Tools | Templates.
        if (this.dynamic) {
            throw new ConfigurationException(
                    "Single step mode runs cannot use dynamic step start/final values.");
        }
        if (this.stepStart.getValue() == null) {
            throw new ConfigurationException(
                    "Single step runs must have a starting step value specified.");
        }
    }

    /**
     * Retrieve a descriptor containing the configuration information for the current controller.
     * @return 
     */
    @Override
    public Descriptor getConfiguration() {
        Descriptor d = new Descriptor();
        d.setName(this.getName());
        d.setClassName(this.getClass().getCanonicalName());
        d.setComponentType("CONTROLLER");
        d.setType(ComponentType.CONTROLLER);
        return d;
    }

    /**
     * Verify current load state. Currently not supported.
     */
    @Override
    public void loadState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Run the current batch controller.
     */
    @Override
    public void run() {
        running = true;
        LOG.debug("Entering run() method of the Batch Controlelr");
        while (this.paused) {
            try {
                Thread.currentThread().wait(pauseDelay);
            } catch (InterruptedException ex) {
                LOG.error("Interrupted thread exception", ex);
            }
        }
        curIndex += 1;
        Class c = stepBase.getClass();
        Step batchStep;
        try {
            batchStep = (Step) c.newInstance();
        } catch (InstantiationException | IllegalAccessException ex) {
            LOG.fatal("Failed to create new Step of type " + c.getName());
            batchStep = new DateTimeStep();
        }
        batchStep.setOrigin(stepBase.getOrigin());
        batchStep.setStepSize(stepBase.getStepSize());
        batchStep.setValue(stepBase.getOrigin());
        batchStep.setFormat(stepBase.getFormat());
        batchStep.setIndex(curIndex);
        LOG.debug("Running Step(" + batchStep.toString()
                + ")");
        engine.setCurrentStep(batchStep);
        engine.call();
        running = false;
    }

    /**
     * Check the current save state. Not currently supported.
     */
    @Override
    public void saveState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

}
