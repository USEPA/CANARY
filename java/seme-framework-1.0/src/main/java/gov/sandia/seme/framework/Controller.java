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
 * @if doxyDev
 * @page devControllers Writing %Controller Classes
 * 
 * @endif
 */
/**
 * Interface that defines how Steps are processed and controls the Engine. The
 * Controller proceeds from a start step to a final step incrementally in the
 * run method. Where the %Engine provides the API methods for configuring the
 * framework, the Controller provides the API methods for running the model or
 * application which uses the framework.
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface Controller extends Describable, Runnable {

    /**
     * Configure the controller.
     *
     * @param desc configuration in a Descriptor object
     * @throws ConfigurationException if there are errors in the configuration options
     */
    void configure(Descriptor desc) throws ConfigurationException;

    /**
     * Get a new descriptor of the current configuration.
     */
    public Descriptor getConfiguration();

    /**
     * Get the global MissingDataPolicy dataStyle.
     */
    public MissingDataPolicy getDataStyle();

    /**
     * Set the global MissingDataPolicy dataStyle.
     */
    public void setDataStyle(MissingDataPolicy dataStyle);

    /**
     * Set the link to the engine.
     */
    void setEngine(Engine engine);

    /**
     * Get the polling rate (in milliseconds).
     */
    long getPollRate();

    /**
     * Set the polling rate (in milliseconds).
     */
    void setPollRate(long pollRate);

    /**
     * Get the value of the step base.
     */
    Step getStepBase();

    /**
     * Set the value of the step base.
     */
    void setStepBase(Step step);

    /**
     * Get the value of the initial step.
     */
    Step getStepStart();

    /**
     * Set the value of the initial step.
     */
    void setStepStart(Step step);

    /**
     * Get the value of the final step.
     */
    Step getStepStop();

    /**
     * Set the value of the final step.
     */
    void setStepStop(Step step);

    /**
     * Get the value of dynamic stepping.
     */
    boolean isDynamic();

    /**
     * Set the value of dynamic stepping.
     */
    void setDynamic(boolean dynamic);

    /**
     * Get the controller's 'paused' status.
     */
    boolean isPaused();

    /**
     * Set the controller's 'paused' status.
     */
    void setPaused(boolean paused);

    /**
     * Get the controller's 'running' status.
     */
    boolean isRunning();

    /**
     * Set the controller's 'running' status.
     */
    void setRunning(boolean running);

    /**
     * Load a formerly saved state of execution.
     */
    void loadState();

    /**
     * Pause the execution of the SeMe framework components.
     */
    void pauseExecution();

    /**
     * Resume the execution of the SeMe framework components.
     */
    void resumeExecution();

    /**
     * Save the execution state for later load.
     */
    void saveState();

    /**
     * Stop the execution of the SeMe framework components and exit the run
     * method.
     */
    void stopExecution();

    /**
     * Get the controller's name.
     */
    String getName();

    /**
     * Set the controller's name.
     */
    void setName(String n);

}
