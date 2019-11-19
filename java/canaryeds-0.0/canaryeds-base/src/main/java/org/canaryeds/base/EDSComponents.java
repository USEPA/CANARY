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
package org.canaryeds.base;

import org.canaryeds.base.workflows.LPCF_BED;
import org.canaryeds.base.workflows.MVNN_BED;
import gov.sandia.seme.framework.Controller;
import gov.sandia.seme.framework.DataChannel;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Messagable;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InvalidComponentClassException;
import java.util.HashMap;
import java.util.Iterator;
import org.apache.log4j.Logger;

/**
 * Provides factory methods for both CANARY-EDS specific and SeMe Framework components.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class EDSComponents extends gov.sandia.seme.framework.Components {

    private static final Logger LOG = Logger.getLogger(EDSComponents.class);

    /**
     * Factory method to create a new Controller object.
     * @test Tested in EDSComponentsTest#testNewController
     *
     * @param desc configuration for the controller
     * @return new Controller object
     * @throws InvalidComponentClassException the class is missing or of the wrong type
     * @throws ConfigurationException the configuration options are invalid
     */
    @Override
    public Controller newController(Descriptor desc)
            throws InvalidComponentClassException, ConfigurationException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        Controller rc = null;
        Class o;
        try {
            try {
                o = Class.forName(
                        "org.canaryeds.base." + className);
                Logger.getLogger(Workflow.class.getName()).debug(
                        "Using CANARY-EDS core component: " + className);
            } catch (ClassNotFoundException e) {
                return super.newController(desc);
            }
            rc = (Controller) o.newInstance();
            rc.configure(desc);
        } catch (ClassCastException classCastException) {
            LOG.error("Error creating new controller: ", classCastException);
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "ClassCastException");
        } catch (InstantiationException instantiationException) {
            LOG.error("Error creating new controller: ", instantiationException);
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "InstantiationException");
        } catch (IllegalAccessException illegalAccessException) {
            LOG.error("Error creating new controller: ", illegalAccessException);
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "IllegalAccessException");
        }
        return rc;
    }

    /**
     * Factory method to create a new Messagable object. Creates monitoring stations
     * and InputConnection and OutputConnection objects.
     * @test Tested in EDSComponentsTest#testNewMessagable
     *
     * @param desc configuration for messagable
     * @return new Messagable object
     * @throws InvalidComponentClassException the class is missing or of the wrong type
     * @throws ConfigurationException the configuration options are invalid
     */
    @Override
    public Messagable newMessagable(Descriptor desc) throws InvalidComponentClassException, ConfigurationException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        Messagable rc;
        Class o;
        try {
            switch (className.toLowerCase()) {
                case "station":
                case "monitorstation":
                case "monitoringstation":
                case "monitoring station":
                    rc = new Station(desc);
                    break;
                default:
                    try {
                        o = Class.forName(
                                "org.canaryeds.base." + className);
                        Logger.getLogger(Workflow.class.getName()).debug(
                                "Using CANARY-EDS core component: " + className);
                    } catch (ClassNotFoundException e) {
                        return super.newMessagable(desc);
                    }
                    rc = (Messagable) o.newInstance();
                    break;
            }
            rc.configure(desc);
            return rc;
        } catch (ClassCastException classCastException) {
            LOG.error("Error creating new Messagable: ", classCastException);
            throw new InvalidComponentClassException("Messagable", className,
                    "ClassCastException");
        } catch (InstantiationException ex) {
            LOG.error("Error creating new Messagable: ", ex);
            throw new InvalidComponentClassException("Messagable", className,
                    "InstantiationException");
        } catch (IllegalAccessException ex) {
            LOG.error("Error creating new Messagable: ", ex);
            throw new InvalidComponentClassException("Messagable", className,
                    "IllegalAccessException");
        }
    }

    /**
     * Factory method to create a new DataChannel object.
     *
     * @test Tested in EDSComponentsTest#testNewDataChannel
     *
     * @param desc configuration for data channel
     * @return new DataChannel object
     * @throws InvalidComponentClassException the class is missing or of the wrong type
     */
    @Override
    public DataChannel newDataChannel(Descriptor desc) throws InvalidComponentClassException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        DataChannel rc = null;
        Class o;
        try {
            try {
                o = Class.forName(
                        "org.canaryeds.base." + className);
                Logger.getLogger(Workflow.class.getName()).debug(
                        "Using CANARY-EDS core component: " + className);
            } catch (ClassNotFoundException e) {
                return super.newDataChannel(desc);
            }
            rc = (DataChannel) o.newInstance();
            rc.configure(desc);
        } catch (ClassCastException classCastException) {
            LOG.error("Error creating new DataChannel: ", classCastException);
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "ClassCastException");
        } catch (InstantiationException instantiationException) {
            LOG.error("Error creating new DataChannel: ", instantiationException);
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "InstantiationException");
        } catch (IllegalAccessException illegalAccessException) {
            LOG.error("Error creating new DataChannel: ", illegalAccessException);
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "IllegalAccessException");
        }
        return rc;
    }

    /**
     * Factory method to create a new Workflow.
     *
     * @test Tested in EDSComponentsTest#testNewWorkflow.
     * Test creates a new workflow from various different configurations.
     *
     * @param desc Descriptor containing the configuration
     * @return the new Workflow object, configured
     * @throws InvalidComponentClassException the class is missing or is of the incorrect type
     * @throws ConfigurationException the workflow failed to be configured with the options provided
     */
    public Workflow newWorkflow(Descriptor desc)
            throws InvalidComponentClassException, ConfigurationException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        Workflow rc;
        LOG.debug("Creating new workflow '" + className + "', config=" + cfg);
        try {
            switch (className) {
                case "MVNN_BED":
                    rc = new MVNN_BED();
                    break;
                case "LPCF_BED":
                    rc = new LPCF_BED();
                    break;
                default:
                    /*
                     * If this is a fully qualified class name, go ahead and
                     * create it via reflection. If the cast fails, we will
                     * catch it and create an exception that says "Everything is
                     * Dead"
                     */
                    Class o;
                    try {
                        o = Class.forName(
                                "org.canaryeds.base." + className);
                        Logger.getLogger(Workflow.class.getName()).debug(
                                "Using CANARY-EDS core component: " + className);
                    } catch (ClassNotFoundException e) {
                        Logger.getLogger(Workflow.class.getName()).info(
                                "Using 3rd-party extension: " + className);
                        o = Class.forName(className);
                    }
                    rc = (Workflow) o.newInstance();
                    break;
            }
            rc.configure(desc);
            return rc;
        } catch (ClassCastException classCastException) {
            LOG.error("Error creating new Workflow: ", classCastException);
            throw new InvalidComponentClassException("WORKFLOW", className,
                    "ClassCastException");
        } catch (ClassNotFoundException classNotFoundException) {
            LOG.error("Error creating new Workflow: ", classNotFoundException);
            throw new InvalidComponentClassException("WORKFLOW", className,
                    "ClassNotFoundException");
        } catch (InstantiationException instantiationException) {
            LOG.error("Error creating new Workflow: ", instantiationException);
            throw new InvalidComponentClassException("WORKFLOW", className,
                    "instantiationException");
        } catch (IllegalAccessException illegalAccessException) {
            LOG.error("Error creating new Workflow: ", illegalAccessException);
            throw new InvalidComponentClassException("WORKFLOW", className,
                    "illegalAccessException");
        }
    }

    /**
     * Provides a list of result message data keys.
     * @test Tested in EDSComponentsTest#testGetResultMessageDataKeys.
     *
     * @return a list of keys
     */
    @Override
    public String[] getResultMessageDataKeys() {
        return new String[]{
            "step", "tag",
            "eventCode",
            "eventProbability",
            "contribParameters",
            "workflowName",
            "message",
            "total items",
            "eventIdentifierName",
            "eventIdentifierId",
            "eventIdentifierProbability",
            "byChannelResiduals"};
    }

    /**
     * Provides a list of value message data keys.
     *
     * @test Tested in EDSComponentsTest#testGetValueMessageDataKeys.
     *
     * @return a list of keys
     */
    @Override
    public String[] getValueMessageDataKeys() {
        return new String[]{"step", "tag", "value", "quality"};
    }

    /**
     * Provides a list of control message data keys.
     * @test Tested in EDSComponentsTest#testGetControlMessageDataKeys.
     *
     * @return a list of keys
     */
    @Override
    public String[] getControlMessageDataKeys() {
        return new String[]{"step", "tag", "status", "message", "exception"};
    }

    /**
     * Parse configuration dictionary to get a HashMap of
     * name:descriptor for the workflows in the configuration.
     *
     * @test Tested in EDSComponentsTest#testGetWorkflowDescriptors
     *
     * @param config HashMap containing the configuration options
     * @return a HashMap of Descriptors
     * @throws ConfigurationException the section is missing or contains invalid entries
     */
    public HashMap<String, Descriptor> getWorkflowDescriptors(HashMap config) throws ConfigurationException {
        LOG.trace("-> getWorkflowDescriptors");
        String className;
        HashMap<String, Descriptor> hash = new HashMap();
        if (config == null) {
            LOG.fatal("Major error in configuration file: trying to create a non-existant workflow");
            throw new ConfigurationException("Trying to configure a non-existant workflow!");
        }
        for (Iterator it = config.keySet().iterator(); it.hasNext();) {
            Object k = it.next();
            String id = (String) k;
            HashMap subConf = (HashMap) config.get(k);
            Object[] keys = subConf.keySet().toArray();
            HashMap cfg;
            if (keys.length == 1) {
                className = (String) keys[0];
                cfg = (HashMap) subConf.get(keys[0]);
            } else if (subConf.containsKey("className")) {
                className = (String) subConf.get("className");
                cfg = subConf;
            } else {
                LOG.fatal(
                        "Error in \"workflow: section of configuration, entry: \"" + config.toString() + "\"");
                throw new ConfigurationException(
                        "Error in 'workflow:' section of configuration file. Please see the documentation");
            }
            String compType;
            compType = "SUBCOMPONENT";
            Descriptor description = new Descriptor(compType, id, className, cfg);
            description.setGeneratingClass(this.getClass().getName());
            description.setTag((String) cfg.get("tag"));
            hash.put(id, description);
        }
        return hash;
    }

}
