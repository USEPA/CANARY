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

import org.canaryeds.base.CANARY;
import gov.sandia.seme.framework.ComponentType;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.ModelConnection;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.util.ControllerImpl;
import java.util.concurrent.CopyOnWriteArrayList;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userBatch Configuration Details: Using controllers.Batch
 * 
 * @endif
 */
/**
 * Provides a controller for a run in a batch mode. This increments the
 * steps from a start step to a stop step with no delay.
 * 
 * @internal
 * @author dbhart
 * @author $LastChangedBy: nprackl $
 * @version $Rev: 4364 $, $Date: 2014-06-18 18:32:06 -0600 (Wed, 18 Jun 2014) $
 */
public final class Batch extends ControllerImpl {

    private static final Logger LOG = Logger.getLogger(Batch.class);

    static final long serialVersionUID = 4082333680955970892L;

    /**
     * Default constructor.
     */
    public Batch() {
    }

    /**
     * Configure the current batch mode.
     * @param desc The descriptor used to configure the batch mode.
     * @throws ConfigurationException 
     */
    @Override
    public void configure(Descriptor desc) throws ConfigurationException {
        LOG.info("Configuring controller");
        super.configure(desc); //To change body of generated methods, choose Tools | Templates.
        if (this.dynamic) {
            throw new ConfigurationException(
                    "Batch mode runs cannot use dynamic step start/final values.");
        }
        if (this.stepStart.getValue() == null) {
            throw new ConfigurationException(
                    "Batch mode runs must have a starting step value specified.");
        }
        if (this.stepStop.getValue() == null) {
            throw new ConfigurationException(
                    "Batch mode runs must have a final step (stopping point) specified.");
        }
    }

    /**
     * Retrieve a descriptor containing the current configuration information.
     * @return A descriptor of the current configuration information.
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
     * Check the current load state. Currently unsupported.
     */
    @Override
    public void loadState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Run batch-mode event detection. This controller runs event detection on
     * all available data from a start step to a final step as fast as possible.
     *
     * @latexonly
     * \begin{algorithmic}
     * \For{$i=Step_0 : Step_n$}
     * \State $batchStep \rightarrow$ \Call{setIndex}{$i$}
     * \State $engine \rightarrow$ \Call{setCurrentStep}{$batchStep$}
     * \State $engine \rightarrow$ \Call{call}{}
     * \EndFor
     * \State CANARY $\rightarrow$ \Call{outputEventSummaries}{$stations$}
     * \end{algorithmic}
     * @endlatexonly
     */
    @Override
    public void run() {
        running = true;
        LOG.debug("Entering run() method of the Batch Controlelr");
        // for each CONNECTOR, STATION
        // send INIT command
        // for thisStep between startStep and stopStep
        LOG.info("Beginning Batch run from Step(" + stepStart.toString()
                + ") to Step(" + stepStop.toString() + ")");
        for (int i = stepStart.getIndex(); i <= stepStop.getIndex(); i += 1) {
            if (!running) {
                break;
            }
            while (this.paused) {
                try {
                    Thread.currentThread().wait(pauseDelay);
                } catch (InterruptedException ex) {
                    LOG.error("Interrupted thread exception", ex);
                }
            }
            Class c = stepBase.getClass();
            Step batchStep = null;
            try {
                batchStep = (Step) c.newInstance();
            } catch (InstantiationException | IllegalAccessException ex) {
                LOG.fatal("Failed to create new Step of type "+c.getName());
            }
            batchStep.setOrigin(stepBase.getOrigin());
            batchStep.setStepSize(stepBase.getStepSize());
            batchStep.setValue(stepBase.getOrigin());
            batchStep.setFormat(stepBase.getFormat());
            batchStep.setIndex(i);
            engine.setCurrentStep(batchStep);
            engine.call();
            if (i % 1000 == 0) {
                LOG.info("Processed through " + batchStep.toString());
            }
        }
        running = false;
        LOG.info("The Batch run has completed. Writing summary files");
        // write the summaries
        CopyOnWriteArrayList<ModelConnection> stations = engine.getRegisteredModels();
        CANARY.outputEventSummaries(stations);
    }

    /**
     * Set the current save state. Currently unsupported.
     */
    @Override
    public void saveState() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

}
