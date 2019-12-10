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

import gov.sandia.seme.util.ControllerImpl;
import java.util.HashMap;
import java.util.Iterator;
import java.util.concurrent.Callable;
import org.apache.log4j.Logger;

/**
 * Factory methods to create components based on reflection and introspection.
 * Also used to create new threads of various types during the Engine's call
 * function. This class can (read should) be extended by an application in order
 * to use application-local extensions of the Messagable, Controller,
 * DataChannel and SubComponent factories. This class also contains the default
 * data keys for the various message types, which the application will likely
 * want to override.
 *
 * The application (or driver parser using the SeMe framework) will create a
 * Components object in the Engine, which is why the factory methods are not
 * static (as static methods would require an extra reflection step during every
 * call step).
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class Components {

    private static final Logger LOG = Logger.getLogger(Components.class);

    /**
     * Factory to create a new Controller. This method should be overridden by
     * the application to limit classes available, but should still call
     * super.newController(desc)} as the "default" for the switch, unless the
     * SeMe base implementations are to be excluded.
     * <p>
     * @param desc Descriptor containing the configuration
     * @return the new Controller
     * @see ControllerImpl
     * @throws InvalidComponentClassException
     * @throws ConfigurationException
     */
    public Controller newController(Descriptor desc)
            throws InvalidComponentClassException, ConfigurationException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        Controller rc;
        try {
            Class o;
            try {
                o = Class.forName("gov.sandia.seme.impl." + className);
                Logger.getLogger(Controller.class.getName()).info(
                        "Using SeMe extension: " + className);
            } catch (ClassNotFoundException e) {
                Logger.getLogger(Controller.class.getName()).info(
                        "Using 3rd-party extension: " + className);
                o = Class.forName(className);
            }
            rc = (Controller) o.newInstance();
            rc.configure(desc);
            return rc;
        } catch (ClassCastException classCastException) {
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "ClassCastException");
        } catch (ClassNotFoundException classNotFoundException) {
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "ClassNotFoundException");
        } catch (InstantiationException instantiationException) {
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "instantiationException");
        } catch (IllegalAccessException illegalAccessException) {
            throw new InvalidComponentClassException("CONTROLLER", className,
                    "illegalAccessException");
        }
    }

    /**
     * Factory to create a new Messagable. This method should be overridden by
     * the application to limit classes available, but should still call
     * super.newMessagable(desc) as the "default" for the switch, unless the
     * SeMe base implementations are to be excluded.
     * <p>
     * @param desc Descriptor containing the configuration
     * @return the new Messagable
     * @see Messagable
     * @throws InvalidComponentClassException
     * @throws ConfigurationException
     */
    public Messagable newMessagable(Descriptor desc)
            throws InvalidComponentClassException, ConfigurationException {
        HashMap cfg = desc.getOptions();
        String className = desc.getClassName();
        String name = desc.getName();
        Messagable rc;
        try {
            Class o;
            try {
                o = Class.forName("gov.sandia.seme.impl." + className);
                Logger.getLogger(Messagable.class.getName()).info(
                        "Using SeMe extension: " + className);
            } catch (ClassNotFoundException e) {
                Logger.getLogger(Messagable.class.getName()).info(
                        "Using 3rd-party extension: " + className);
                o = Class.forName(className);
            }
            rc = (Messagable) o.newInstance();
            rc.configure(desc);
            return rc;
        } catch (ClassCastException classCastException) {
            LOG.fatal("ARGH!!!! ", classCastException);
            throw new InvalidComponentClassException("Messagable", className,
                    "ClassCastException");
        } catch (ClassNotFoundException classNotFoundException) {
            throw new InvalidComponentClassException("Messagable", className,
                    "ClassNotFoundException");
        } catch (InstantiationException instantiationException) {
            LOG.fatal("Instantiation exception", instantiationException);
            throw new InvalidComponentClassException("Messagable", className,
                    "instantiationException");
        } catch (IllegalAccessException illegalAccessException) {
            throw new InvalidComponentClassException("Messagable", className,
                    "illegalAccessException");
        }
    }

    /**
     * Factory to create a new DataChannel. This method should be overridden by
     * the application to limit classes available, but should still call
     * super.newDataChannel(desc) as the "default" for the switch, unless the
     * SeMe base implementations are to be excluded.
     *
     * @param channel configuration for the new channel
     * @return the new data channel
     * @throws InvalidComponentClassException
     */
    public DataChannel newDataChannel(Descriptor channel)
            throws InvalidComponentClassException {
        HashMap cfg = channel.getOptions();
        String className = channel.getClassName();
        String chName = channel.getName();
        DataChannel rc;
        try {
            Class o;
            try {
                o = Class.forName("gov.sandia.seme.impl." + className);
                Logger.getLogger(DataChannel.class.getName()).info(
                        "Using SeMe extension: " + className);
            } catch (ClassNotFoundException e) {
                Logger.getLogger(DataChannel.class.getName()).info(
                        "Using 3rd-party extension: " + className);
                o = Class.forName(className);
            }
            rc = (DataChannel) o.newInstance();
            rc.configure(channel);
            return rc;
        } catch (ClassCastException classCastException) {
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "ClassCastException " + channel.getName());
        } catch (ClassNotFoundException classNotFoundException) {
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "ClassNotFoundException " + channel.getName());
        } catch (InstantiationException instantiationException) {
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "instantiationException " + channel.getName());
        } catch (IllegalAccessException illegalAccessException) {
            throw new InvalidComponentClassException("DATACHANNEL", className,
                    "illegalAccessException " + channel.getName());
        }
    }

    /**
     * Parse configuration dictionary to get a HashMap of Descriptors for the
     * defined DataChannels. This method can be overridden for a specific
     * application, or used as is.
     * <p>
     * @param config HashMap containing the configuration options
     * @return a HashMap of Descriptors
     * @see DataChannel
     * @throws ConfigurationException
     */
    public HashMap<String, Descriptor> getChannelDescriptors(HashMap config)
            throws ConfigurationException {
        LOG.trace("-> getChannelDescriptors");
        String className;
        if (config == null) {
            throw new ConfigurationException("Trying to configure a non-existant workflow!");
        }
        HashMap<String, Descriptor> hash = new HashMap();
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
                        "Error in \"channels\" section of configuration, entry: \"" + config.toString() + "\"");
                throw new ConfigurationException(
                        "Error in 'channels:' section of configuration file. Please see the documentation");
            }
            Descriptor description = new Descriptor("DATACHANNEL", id, className,
                    cfg);
            description.setTag((String) cfg.get("tag"));
            description.setComponentType("DATACHANNEL");
            hash.put(id, description);
        }
        return hash;
    }

    /**
     * Parse configuration dictionary to get a HashMap of Descriptors for the
     * defined Messagables. This method can be overridden for a specific
     * application, or used as is.
     * <p>
     * @param config HashMap containing the configuration options
     * @return a HashMap of Descriptors
     * @see Messagable
     * @throws ConfigurationException
     */
    public HashMap<String, Descriptor> getConnectionDescriptors(HashMap config)
            throws ConfigurationException {
        LOG.trace("-> getConnectorDescriptors");
        String className;
        HashMap<String, Descriptor> hash = new HashMap();
        if (config == null) {
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
                        "Error in \"connectors\" section of configuration, entry: \"" + config.toString() + "\"");
                throw new ConfigurationException(
                        "Error in 'connectors:' section of configuration file. Please see the documentation");
            }
            Descriptor description = new Descriptor("MESSAGABLE", id, className,
                    cfg);
            String tagPref = (String) subConf.get("tagPrefix");
            if (tagPref != null) {
                description.setTag(tagPref);
            } else {
                tagPref = (String) subConf.get("tag");
                if (tagPref != null) {
                    description.setTag(tagPref);
                } else {
                    description.setTag(id);
                }
            }
            description.addToProducesTags(id + "_STATUS");
            description.setGeneratingClass(this.getClass().getName());
            description.setComponentType("CONNECTION");
            hash.put(id, description);
        }
        return hash;
    }

    /**
     * Parse configuration dictionary to get a HashMap of Descriptors for the
     * defined Controllers. This method can be overridden for a specific
     * application, or used as is.
     * <p>
     * @param config HashMap containing the configuration options
     * @return a HashMap of Descriptors
     * @see ControllerImpl
     * @throws ConfigurationException
     */
    public HashMap<String, Descriptor> getControllerDescriptors(HashMap config)
            throws ConfigurationException {
        LOG.trace("-> getControllerDescriptors");
        Descriptor description;
        String className;
        if (config == null) {
            throw new ConfigurationException("Trying to configure a non-existant workflow!");
        }
        HashMap<String, Descriptor> hash = new HashMap();
        for (Iterator it = config.keySet().iterator(); it.hasNext();) {
            Object k = it.next();
            String id = (String) k;
            HashMap subConf = (HashMap) config.get(k);
            Object[] keys = subConf.keySet().toArray();
            HashMap cfg;
            if (keys.length == 1) {
                className = (String) keys[0];
                cfg = (HashMap) subConf.get(className);
            } else if (config.containsKey("className")) {
                className = (String) subConf.get("className");
                cfg = config;
            } else {
                LOG.fatal(
                        "Error in \"control\" section of configuration, entry: " + config);
                throw new ConfigurationException(
                        "Error in 'control:' section of configuration file. Please see the documentation");
            }
            description = new Descriptor("CONTROLLER", id, className, cfg);
            description.setGeneratingClass(this.getClass().getName());
            description.setComponentType("CONTROLLER");
            hash.put(id, description);
        }
        return hash;
    }

    /**
     * Create a new Callable object out of an InputMessagable. This method is
     * final.
     * <p>
     * @param conn InputMessagable to become the base of the task
     * @return a new Callable object to submit
     * @see InputConnection
     */
    public final static Callable<String> newInputTask(InputConnection conn) {
        return new CallableInputConnection(conn);
    }

    /**
     * Create a new Callable object out of an OutputMessagable. This method is
     * final.
     * <p>
     * @param conn OutputMessagable to become the base of the task
     * @return a new Callable object to submit
     * @see OutputConnection
     */
    public final static Callable<String> newOutputTask(OutputConnection conn) {
        return new CallableOutputConnection(conn);
    }

    /**
     * Create a new Callable object out of an ModelConnection. This method is
     * final.
     * <p>
     * @param model ModelConnection to become the base of the task
     * @return a new Callable object to submit
     * @see ModelConnection
     */
    public final static Callable<String> newModelTask(ModelConnection model) {
        return new CallableModelConnection(model);
    }

    /**
     * Return a list of default keys in the data field of a RESULT type message.
     * This should be overridden in a model-specific Components class extension
     * to give the right keys needed for that model. The keys "step" and "tag"
     * are reserved key words referring to other fields in the Message.
     * <p>
     * @return list of keys
     */
    public String[] getResultMessageDataKeys() {
        return new String[]{"predicted", "observed", "residual", "mse", "status"};
    }

    /**
     * Return a list of default keys in the data field of a VALUE type message.
     * This should be overridden in a model-specific Components class extension
     * to give the right keys needed for that model. The keys "step" and "tag"
     * are reserved key words referring to other fields in the Message.
     * <p>
     * @return list of keys
     */
    public String[] getValueMessageDataKeys() {
        return new String[]{"value", "status"};
    }

    /**
     * Return a list of default keys in the data field of a CONTROL type
     * message. This can be overridden in a model-specific Components class
     * extension to give the right keys needed for that model, however, control
     * messages should always at least provide the keys "status", "message", and
     * "exception". The keys "step" and "tag" are reserved key words referring
     * to other fields in the Message.
     * <p>
     * @return list of keys
     */
    public String[] getControlMessageDataKeys() {
        return new String[]{"status", "message", "exception"};
    }

}
