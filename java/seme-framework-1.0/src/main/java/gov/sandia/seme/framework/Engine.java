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

import java.io.File;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.ResourceBundle;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import org.apache.log4j.Logger;

/**
 * @if (doxyDev && !doxyDevSemeNoModel)
 * @page devExtendingEngine Extending the Engine
 * 
 * @endif
 */
/**
 * Provides API functionality for using the SeMe Framework. This class can (read
 * as should) be extended to add the configure() command that parses the
 * application specific configuration dictionary. However, to ensure consistent
 * functionality that will behave as programmers expect, certain methods are
 * declared as final.
 * 
 * This class is the primary reason that SeMe requires Java 7 or later, as it
 * uses the java.util.concurrent package, specifically the
 * java.util.concurrent.ExecutorService thread controls. The
 * MessageRouter class is virtually invisible to the applications that use the
 * framework; this is deliberate. In addition, the MessageRouter also has a
 * dedicated, single-thread ScheduledExecutorService (SES). The default timing
 * for this SES is a one microsecond delay between routing runs.
 * 
 * The worker tasks are created from Messagable *-Connection objects, and are
 * submitted to the workerService by the Engine's call() function. The call
 * function needs to be called once per step by the ControllerImpl. The call
 * function submits tasks in order: first InputConnection objects, then
 * ModelConnections, and finally OutputConnection objects. Because an object can
 * implement more than one of these interfaces at the same time, any Messagable
 * *-Connection objects <b>should not</b> implement Runnable or Callable; the
 * Engine will create new Callable task objects from specialized private classes
 * that wrap the *-Connection specific functions (see 
 * InputConnection#readInputAndProduceMessages,
 * ModelConnection#evaluateModel and
 * OutputConnection#consumeMessagesAndWriteOutput).
 * 
 * The Messagable objects are run in order -- all InputConnection tasks are
 * allowed to complete, followed by ModelConnection tasks, and then finally
 * OutputConnection tasks are submitted. Any Messagable objects that are created
 * that do not implement one of the *-Connection interfaces are submitted to the
 * worker ES first, however, in this case the objects <b>should</b> be either
 * Runnable or Callable; the jobs will be submitted without any monitoring, and
 * InputConnection tasks will be submitted immediately after these other tasks
 * (for the *-Connection tasks, how the Engine waits for and controls the tasks
 * is configurable).
 * 
 * As discussed above, the routerService starts during the initialize method. It
 * is terminated in the shutdown method, as is the workerService. The number of
 * threads that are used by the workerService for its tasks is configurable via
 * API or through the configuration file in the "driver" section.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class Engine implements Serializable {

    private static final Logger LOG = Logger.getLogger(Engine.class);
    private static final ResourceBundle messages = java.util.ResourceBundle.getBundle(
            "gov.sandia.seme.app");
    static final long serialVersionUID = 5022341466097556437L;

    protected Components componentFactory;
    protected Controller controller;
    protected Step currentStep;
    protected int maxThreads = 4;
    protected final ArrayList<Messagable> Messagables;
    protected final MessageRouter router;
    protected final ScheduledExecutorService routerService;
    protected ScheduledFuture routerTask;
    protected String usedControllerName;
    protected ExecutorService workerService;

    public CopyOnWriteArrayList<ModelConnection> getRegisteredModels() {
        return router.getRegisteredModels();
    }

    /**
     * Configuration hash map for the entire engine.
     */
    protected HashMap config;

    /**
     * HashMap of Name:Descriptor for the Controller object(s).
     */
    protected HashMap<String, Descriptor> descControllers;

    /**
     * HashMap of Name:Descriptor for the DataChannel objects.
     */
    protected HashMap<String, Descriptor> descDataChannels;

    /**
     * HashMap of Name:Descriptor for the Messagable objects. This includes all
     * InputConnection, ModelConnection, and OutputConnection objects.
     */
    protected HashMap<String, Descriptor> descMessagables;

    /**
     * HashMap of descriptors for the any type of Describable objects.
     */
    protected HashMap<String, Descriptor> descSubComponents;

    /**
     * Constructor for a new, null configuration.
     */
    public Engine() {
        this.routerService = Executors.newSingleThreadScheduledExecutor();
        this.config = new HashMap();
        this.controller = null;
        this.router = new MessageRouter();
        this.Messagables = new ArrayList();
        this.componentFactory = new Components();
    }

    /**
     * Constructor for a new, null configuration with a specific Components
     * implementation object.
     *
     * @param factory Components factory class object
     */
    public Engine(Components factory) {
        this.routerService = Executors.newSingleThreadScheduledExecutor();
        this.config = new HashMap();
        this.controller = null;
        this.router = new MessageRouter();
        this.Messagables = new ArrayList();
        this.componentFactory = factory;
    }

    /**
     * Add a new connection to the router.
     *
     * @param m connection to be added
     */
    public void addConnection(Messagable m) {
        String n = m.getName();
        this.Messagables.add(m);
        try {
            this.router.register(m);
        } catch (RouterRegistrationException ex) {
            LOG.error("Failure adding connection '" + n + "'", ex);
        }
    }

    /**
     * Add a new controller to the Engine.
     *
     * @param c controller to be added
     */
    public void addController(Controller c) {
        String n = c.getName();
    }

    /**
     * Add a new data channel definition to the Engine.
     *
     * @param dc data channel to be added
     */
    public void addDataChannel(DataChannel dc) {
        String n = dc.getName();
    }

    /**
     * Submits all the Input-, Model-, and OutputConnections for execution on
     * the current step.
     *
     * @return true if all tasks were successful, false if failures occurred
     */
    public boolean call() {
    // We get a new list of all connection objects during each call - this
        //  is necessary, since it is possible that in periodic iterations the
        //  engine will have had new connections added.
        CopyOnWriteArrayList<InputConnection> regInputs;
        CopyOnWriteArrayList<OutputConnection> regOutputs;
        CopyOnWriteArrayList<ModelConnection> regModels;
        CopyOnWriteArrayList<Messagable> regUnknowns;

        // Define new results maps
        HashMap<String, Future<String>> inputTasks;
        HashMap<String, Future<String>> outputTasks;
        HashMap<String, Future<String>> modelTasks;
        HashMap<String, Future<String>> unknownTasks;

        // Get the connections from the router
        regInputs = this.router.getRegisteredInputConnections();
        regOutputs = this.router.getRegisteredOutputConnections();
        regModels = this.router.getRegisteredModels();
        regUnknowns = this.router.getRegisteredUnknownNodes();

        // Initialize the new tasks maps
        inputTasks = new HashMap();
        outputTasks = new HashMap();
        modelTasks = new HashMap();
        unknownTasks = new HashMap();

        boolean allDone;
        long routerExecutions;

        LOG.debug("Running on current step: " + currentStep);

    // For each of the input connections registered in the router,
        //  set the current step
        //  create a new input task object
        //  submit the new input task object
        //  register the result Future in the results map
        for (InputConnection task : regInputs) {
            String taskName = task.getName();
            task.setCurrentStep(currentStep);
            //task.step(currentStep);
            Future<String> result;
            result = this.workerService.submit(Components.newInputTask(task));
            inputTasks.put(taskName, result);
            LOG.trace("Submitted input task: " + taskName);
        }
        allDone = false;
        routerExecutions = this.router.getIterations();
    // Wait for at least one router execution after all submitted tasks have
        //  completed execution
        while (!allDone) {
            allDone = true;
            for (String key : inputTasks.keySet()) {
                Future<String> result = inputTasks.get(key);
                allDone = allDone && result.isDone();
            }
            allDone = allDone && (routerExecutions < this.router.getIterations());
        }
    // Read the results from each of the input tasks and log the result if
        //  the debug level is set high enough
        for (String key : inputTasks.keySet()) {
            Future<String> result = inputTasks.get(key);
            try {
                LOG.trace("Result from input task " + key + " = " + result.get());
            } catch (InterruptedException | ExecutionException ex) {
                LOG.error(null, ex);
            }
        }

    // For each of the model connections registered in the router,
        //  set the current step
        //  create a new model task object
        //  submit the new model task object
        //  register the result Future in the results map
        for (ModelConnection task : regModels) {
            String taskName = task.getName();
            task.setCurrentStep(currentStep);
            //task.step(currentStep);
            Future<String> result;
            result = this.workerService.submit(Components.newModelTask(task));
            modelTasks.put(taskName, result);
            LOG.trace("Submitted model task: " + taskName);
        }
        allDone = false;
        routerExecutions = this.router.getIterations();
    // Wait for at least one router execution after all submitted tasks have
        //  completed execution
        while (!allDone) {
            allDone = true;
            for (String key : modelTasks.keySet()) {
                Future<String> result = modelTasks.get(key);
                allDone = allDone && result.isDone();
            }
            allDone = allDone && (routerExecutions < this.router.getIterations());
        }
        for (String key : modelTasks.keySet()) {
            Future<String> result = modelTasks.get(key);
            try {
                LOG.trace("Result from model task " + key + " = " + result.get());
            } catch (InterruptedException | ExecutionException ex) {
                LOG.error(null, ex);
            }
        }

    // For each of the output connections registered in the router,
        //  set the current step
        //  create a new output task object
        //  submit the new output task object
        //  register the result Future in the results map
        for (OutputConnection task : regOutputs) {
            String taskName = task.getName();
            task.setCurrentStep(currentStep);
            //task.step(currentStep);
            Future<String> result;
            result = this.workerService.submit(Components.newOutputTask(task));
            outputTasks.put(taskName, result);
            LOG.trace("Submitted output task: " + taskName);
        }
        allDone = false;
        routerExecutions = this.router.getIterations();
    // Wait for at least one router execution after all submitted tasks have
        //  completed execution
        while (!allDone) {
            allDone = true;
            for (String key : outputTasks.keySet()) {
                Future<String> result = outputTasks.get(key);
                allDone = allDone && result.isDone();
            }
            allDone = allDone && (routerExecutions < this.router.getIterations());
        }
    // Read the results from each of the input tasks and log the result if
        //  the debug level is set high enough
        for (String key : outputTasks.keySet()) {
            Future<String> result = outputTasks.get(key);
            try {
                LOG.trace(
                        "Result from output task " + key + " = " + result.get());
            } catch (InterruptedException | ExecutionException ex) {
                LOG.error(null, ex);
            }
        }

        // TODO: actually check results for success or failure
        return true;
    }

    /**
     * Get the handle to the components factory object.
     *
     * @return handle to the components factory object
     */
    public Components getComponentFactory() {
        return this.componentFactory;
    }

    /**
     * Set the componentFactory object.
     *
     * @param factory the new componentFactory object
     */
    public void setComponentFactory(Components factory) {
        this.componentFactory = factory;
    }

    /**
     * Get the handle to the controller object.
     *
     * @return handle to controller
     */
    public Controller getController() {
        return this.controller;
    }

    /**
     * Get the current step value
     *
     * @return the current step
     */
    public Step getCurrentStep() {
        return currentStep;
    }

    /**
     * Set the current step value
     *
     * @param currentStep the new value for the current step
     */
    public void setCurrentStep(Step currentStep) {
        this.currentStep = currentStep;
    }

    /**
     * Get the maximum number of worker threads
     *
     * @return max number of worker threads
     */
    public int getMaxThreads() {
        return maxThreads;
    }

    /**
     * Set the maximum number of worker threads
     *
     * @param maxThreads new value of the maximum number of threads
     */
    public void setMaxThreads(int maxThreads) {
        this.maxThreads = maxThreads;
    }

    /**
     * Get the value of usedControllerName.
     *
     * @return name of the controller that was used
     */
    public String getUsedControllerName() {
        return usedControllerName;
    }

    /**
     * Set the value of usedControllerName.
     *
     * @param usedControllerName new value of usedControllerName
     */
    public void setUsedControllerName(String usedControllerName) {
        this.usedControllerName = usedControllerName;
    }

    /**
     * Initializes the messaging system and all threaded objects.
     *
     * @throws ConfigurationException one of the components fails to configure
     * @throws InitializationException the engine or one of the components fails to initialize
     */
    public void initialize() throws ConfigurationException, InitializationException {
        // Add in configuration using ioConnectorName
        try {
            Descriptor ctrlDesc = descControllers.get(usedControllerName);
            controller = componentFactory.newController(ctrlDesc);
            controller.setEngine(this);
        } catch (InvalidComponentClassException ex) {
            LOG.fatal("error creating controller " + usedControllerName, ex);
            throw new InitializationException(
                    "Fatal error in configuration; controller initialization failed.");
        } catch (NullPointerException ex) {
            LOG.fatal("failed to register name of controller to be used");
            throw ex;
        }
        this.workerService = Executors.newFixedThreadPool(maxThreads);
        LOG.debug("Created controllers");
        String connName;
        for (Iterator<String> it = descMessagables.keySet().iterator(); it.hasNext();) {
            connName = it.next();
            Descriptor connDesc = descMessagables.get(connName);
            try {
                Messagable conn = componentFactory.newMessagable(connDesc);
                conn.setComponentFactory(this.getComponentFactory());
                conn.setBaseStep(controller.getStepBase());
                conn.initialize();
                Messagables.add(conn);
                router.register(conn);
                LOG.trace("added Messagable(" + conn.toString() + ")");
            } catch (InvalidComponentClassException ex) {
                LOG.fatal("error creating Messagable (" + connName + ")", ex);
                throw new InitializationException(
                        "Fatal error in configuration; controller initialization failed.");
            } catch (RouterRegistrationException ex) {
                LOG.error("Registration error: ", ex);
            }
        }
        this.routerTask = this.routerService.scheduleWithFixedDelay(router, 0, 1,
                TimeUnit.MICROSECONDS);
    }

    /**
     * Shutdown the ExecutionService objects.
     */
    public void shutdown() {
        try {
            this.routerService.shutdown();
            this.workerService.shutdown();
            this.routerService.awaitTermination(1, TimeUnit.SECONDS);
            this.workerService.awaitTermination(1, TimeUnit.SECONDS);
        } catch (InterruptedException ex) {
            LOG.error("Interrupted during shutdown", ex);
        }
    }

    /**
     * Set the current environment variable for user directory.
     *
     * @param directory_name the new value for user.dir
     * @return the result status of setting the system property
     */
    public static boolean setCurrentDirectory(String directory_name) {
        boolean result = false; // Boolean indicating whether directory was set
        File directory;    // Desired current working directory

        directory = new File(directory_name).getAbsoluteFile();
        if (directory.exists() || directory.mkdirs()) {
            result = (System.setProperty("user.dir", directory.getAbsolutePath()) != null);
        }

        return result;
    }

}
