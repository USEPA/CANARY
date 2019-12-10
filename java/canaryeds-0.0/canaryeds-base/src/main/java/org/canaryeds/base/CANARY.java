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

import org.canaryeds.base.util.CustomResolver;
import gov.sandia.seme.framework.Components;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Engine;
import gov.sandia.seme.framework.Messagable;
import gov.sandia.seme.framework.ModelConnection;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.framework.InvalidComponentClassException;
import gov.sandia.seme.framework.RouterRegistrationException;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.ResourceBundle;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import net.sourceforge.argparse4j.ArgumentParsers;
import net.sourceforge.argparse4j.impl.Arguments;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.Namespace;
import org.apache.log4j.EnhancedPatternLayout;
import org.apache.log4j.FileAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;
import org.yaml.snakeyaml.representer.Representer;

/**
 * @if doxyDev
 * @page devCanaryLibrary Using CANARY-EDS as a Library
 *
 * @endif
 */
/**
 * Provides the main engine for the CANARY software and the programmatic API
 * entry points for using CANARY-EDS as a library. Responsible for parsing and
 * creating the objects necessary for the CANARY-EDS application to
 * startExecution. Also used as the API-access to pass commands to Stations,
 * Connectors, and the Router. Even the Controller object should use the CANARY
 * object to make its calls.
 *
 * @test Tested in CANARYTest#testShortMVNN. Runs a full test on the
 * configuration file.
 *
 * @test Tested in CANARYTest#testShortLPCF. Runs a full test on the
 * configuration
 *
 * @remarks The following features are not fully implemented in the beta
 * release.
 * @li
 *
 * @htmlonly
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 4372 $, $Date: 2014-07-31 09:27:28 -0600 (Thu, 31 Jul 2014) $
 * @endhtmlonly
 */
public final class CANARY extends Engine implements Serializable {

    private static final Logger LOG = Logger.getLogger(CANARY.class);
    private static final ResourceBundle messages = java.util.ResourceBundle.getBundle(
            "org.canaryeds.base.app");
    static final long serialVersionUID = 5022341466097556437L;

    /**
     * Adds arguments to an ArgumentParser that are CANARY-EDS specific. Adds
     * the following options to a command-line argument parser:
     *
     * @li <tt>-\-verbose, -v </tt> increase log level
     * @li <tt>-\-quiet, -q </tt> decrease log level
     * @li <tt>-\-nw </tt> run without GUI
     * @li <tt>-\-run, -r </tt> run automatically (implied with \c\-\-nw )
     *
     * @param parser the parser to update
     * @return the completed parser
     */
    public static ArgumentParser addArguments(ArgumentParser parser) {
        parser.addArgument("configfile").metavar("FILE").nargs("?").help(
                "the configuration file to use (YAML/JSON formatted)");
        parser.addArgument("--verbose", "-v").type(Integer.class).action(
                Arguments.count()).setDefault(0).help(
                        "increase the logging detail");
        parser.addArgument("--quiet", "-q").type(Integer.class).action(
                Arguments.count()).setDefault(0).help(
                        "decrease the logging detail");
        parser.addArgument("--nw").type(Boolean.class).action(
                Arguments.storeTrue()).setDefault(false).help(
                        "run the file specified without showing any GUI windows (implies --run)");
        parser.addArgument("--run", "-r").type(Boolean.class).action(
                Arguments.storeTrue()).setDefault(false).help(
                        "start running on the configuration file immediately");
        return parser;
    }

    /**
     * Get a new ArgumentParser set up for the CANARY-EDS application.
     *
     * @return a new parser
     */
    public static ArgumentParser getNewParser() {
        ArgumentParser parser = ArgumentParsers.newArgumentParser("canary-eds")
                .description("CANARY-EDS "
                        + messages.getString("application.version")
                        + " Event Detection Software").version(
                        messages.getString("application.version")
                        + " " + messages.getString("application.buildNumber")
                        + " " + messages.getString("application.sourceRev")).epilog(
                        messages.getString("application.copyright"));
        return parser;
    }

    /**
     * Parse arguments --quiet and --verbose to set the log level
     *
     * @param args results of Argparse4j parseArgs
     * @return an log4j log level
     */
    public Level setup(Namespace args) {
        Integer verbose = args.getInt("verbose");
        Integer quiet = args.getInt("quiet");
        int level;
        if (verbose != null && quiet != null) {
            level = quiet.intValue() - verbose.intValue();
        } else if (verbose != null) {
            level = 0 - verbose.intValue();
        } else if (quiet != null) {
            level = quiet.intValue();
        } else {
            level = 0;
        }
        if (level < -3) {
            level = -3;
        } else if (level > 4) {
            level = 4;
        }
        Level eLevel = Level.ALL;
        switch (level) {
            case -3:
                eLevel = (Level.ALL);
                break;
            case -2:
                eLevel = (Level.TRACE);
                break;
            case -1:
                eLevel = (Level.DEBUG);
                break;
            case 0:
                eLevel = (Level.INFO);
                break;
            case 1:
                eLevel = (Level.WARN);
                break;
            case 2:
                eLevel = (Level.ERROR);
                break;
            case 3:
                eLevel = (Level.FATAL);
                break;
            case 4:
                eLevel = (Level.OFF);
                break;
        }
        this.setLogLevel(eLevel);
        return eLevel;
    }

    /**
     * Set the log level.
     * @param level The level to set.
     */
    public void setLogLevel(Level level) {
        Logger.getRootLogger().setLevel(level);
    }

    /**
     * Generic CANARY constructor.
     */
    public CANARY() {
        super();
        super.setComponentFactory(new EDSComponents());
    }

    /**
     * Configures CANARY-EDS using a HashMap of configuration options. Parses
     * the options and creates the appropriate Descriptors. These descriptors
     * are used by the #initialize method.
     *
     * @internal \begin{algorithmic}[0]
     * \Procedure{configure}{$config$}\Comment{configure from a HashMap} \If{old
     * format} \State $config \gets $ \Call{convertV4toV5}{$config$} \EndIf
     * \State $descControllers \gets $ \Call{getControllerDescriptors}{$config
     * \ni$ controllers} \State $descConnections \gets $
     * \Call{getConnectionDescriptors}{$config \ni$ connections} \EndProcedure
     * \end{algorithmic}
     * @endinternal
     *
     * @test Tested in CANARYTest#testConfigure. Tests the parsing of a
     * configuration file.
     *
     * @param config configuration dictionary (probably from a file)
     * @throws ConfigurationException there are errors in the configuration
     */
    public void configure(HashMap config) throws ConfigurationException {
        super.setComponentFactory(new EDSComponents());
        HashMap v5config;
        if (config.containsKey("monitoring stations")
                || config.containsKey("timing options")
                || config.containsKey("data sources")
                || config.containsKey("signals")
                || config.containsKey("algorithms")) {
            v5config = ConfigV4Converter.convertV4toV5(config);
        } else {
            v5config = config; //(HashMap) config.get("canary");
        }
        // done converting to v5 configuration object
        //HashMap tempHash = new HashMap();
        //tempHash.put("canary", v5config);
        //Configurator.printYAMLMap(tempHash);
        /*
         * parse the configuration options and return the Descriptor objects
         * that can be better used for factories and passing around.
         */
        Components factory = this.getComponentFactory();
        try {
            descControllers = factory.getControllerDescriptors(
                    (HashMap) v5config.get("controllers"));
        } catch (ConfigurationException ex) {
            LOG.fatal("Error in configuration file - 'controllers' section is badly formed.");
            throw ex;
        }
        try {
            descMessagables = factory.getConnectionDescriptors(
                    (HashMap) v5config.get("connections"));
        } catch (ConfigurationException ex) {
            LOG.fatal("Error in configuration file - 'connections' section is badly formed.");
            throw ex;
        }
        try {
            descDataChannels = factory.getChannelDescriptors((HashMap) v5config.get(
                    "data channels"));
        } catch (ConfigurationException ex) {
            LOG.fatal("Error in configuration file - 'data channels' section is badly formed.");
            throw ex;
        }
//        descSubComponents = factory.getWorkflowDescriptors(
//                (HashMap) v5config.get("workflows"), "WORKFLOW");
//        descMessagables.putAll(factory.getConnectionDescriptors(
//                (HashMap) v5config.get("canary stations")));

        Descriptor myControl = null;
        if (descControllers.keySet().size() != 1) {
            LOG.fatal(
                    "You cannot have more than one controller specified in CANARY-EDS!");
            LOG.fatal(
                    "You defined " + descControllers.keySet().size() + " controllers.");
            throw new ConfigurationException(
                    "Invalid number of controllers defined (" + descControllers + ")");
        } else {
            Object[] keys = descControllers.keySet().toArray();
            if (keys.length > 0) {
                String controllerName = (String) keys[0];
                myControl = descControllers.get(controllerName);
                descControllers.get(controllerName).setUsed(true);
                this.setUsedControllerName(controllerName);
            }
        }
        if (myControl == null) {
            LOG.fatal(
                    "You cannot have more than one controller specified in CANARY-EDS!");
            LOG.fatal(
                    "You defined " + descControllers.keySet().size() + " controllers.");
            throw new ConfigurationException(
                    "Invalid number of controllers defined (" + descControllers + ")");
        }
        /*
         * //Debugging for (String k : this.cfgController.keySet()) {
         * Descriptor od = (Descriptor) this.cfgController.get(k);
         * System.out.println(od); }
         */
        for (String k : descDataChannels.keySet()) {
            /*
             Traverse all data channels and find alarm signals. When there is an
             alarm signal, look at its scope, and try to find the name in the
             data channels list. If it is there, add the alarm signal's name as a "required"
             to the value channel.
             */
            Descriptor chanDesc = descDataChannels.get(k);
            String scope = (String) chanDesc.getOptions().get("scope");
            if (scope != null) {
                for (String k2 : descDataChannels.keySet()) {
                    Descriptor d2 = descDataChannels.get(k2);
                    if (d2.getTag().equalsIgnoreCase(scope)) {
                        d2.addToRequiresComponents(chanDesc);
                        LOG.debug(
                                "Adding " + chanDesc.getName() + " to channel " + d2.getName());
                    }
                }
            }
            /*
             Traverse all the data channels again, but this time drill down any composite signals,
             and make sure that the appropriate required names are added.
             */
        }

        for (String k : descMessagables.keySet()) {
            Descriptor stnDesc = descMessagables.get(k);
            String className = stnDesc.getClassName();
            if (!className.equalsIgnoreCase("station")) {
                continue;
            }
            stnDesc.addToProducesTags(stnDesc.getTag());
            ArrayList myChannels;
            ArrayList myInputs;
            ArrayList myOutputs;
            ArrayList myWorkflows;
            myInputs = (ArrayList) stnDesc.getOptions().get("inputs");
            myOutputs = (ArrayList) stnDesc.getOptions().get("outputs");
            myChannels = (ArrayList) stnDesc.getOptions().get("channels");
            HashMap myWorkflow = (HashMap) stnDesc.getOptions().get("workflow");
            Boolean isEnabled = (Boolean) stnDesc.getOptions().get("enabled");
            if (isEnabled == null) {
                stnDesc.setUsed(true);
            } else {
                stnDesc.setUsed(isEnabled);
            }
            if (myChannels != null) {
                /*
                 * for each of the channels I am configured to use:
                 *
                 */
                for (Iterator it = myChannels.iterator(); it.hasNext();) {
                    String ch = (String) it.next();
                    if (ch != null) {
                        /*
                         * Set the fact that I consume this channel, and tell
                         * its descriptor that it is used.
                         */
                        Descriptor myChannel = descDataChannels.get(ch);
                        if (myChannel == null) {
                            LOG.warn("Trying to add non-existant data channel '" + ch + "'!");
                            continue;
                        }
                        stnDesc.addToConsumesTags(myChannel.getTag());
                        stnDesc.addToRequiresComponents(myChannel);
                        myChannel.setUsed(true);
                        if (!myChannel.getRequiresComponents().isEmpty()) {
                            // then I need to add the required components, too
                            // and I need to add the tags of those components to
                            // the list of consumes tags
                            for (Descriptor reqChannel : myChannel.getRequiresComponents()) {
                                stnDesc.addToConsumesTags(reqChannel.getTag());
                                stnDesc.addToRequiresComponents(reqChannel);
                                reqChannel.setUsed(true);
                                LOG.debug(
                                        "Adding subordinate channel: " + reqChannel.getName() + "/" + reqChannel.getTag());
                            }
                        }
                        /*
                         * for each input, add the channels I consume to the
                         * list of tags they produce
                         */
                        for (Iterator itIn = myInputs.iterator(); itIn.hasNext();) {
                            Object inp = itIn.next();
                            if (inp != null) {
                                Descriptor thisInput = descMessagables.get(
                                        inp);
                                thisInput.setUsed(true);
                                thisInput.addToProducesTags((String) ch);
                                thisInput.getOptions().put("stepDynamic",
                                        myControl.getOptions().get("stepDynamic"));
                                //this.cfgConnectors.get((String) inp).addToConsumesTags(od.getName() + "_STATUS");
                                //this.cfgConnectors.get((String) inp).addToSynchronizeToTags(od.getName() + "_STATUS");
                                stnDesc.addToConsumesTags(descMessagables.get(
                                        inp).getName() + "_STATUS");
                            }
                        }
                    }
                }
            }
            /*
             * for each output, add my tag name + "_results" to the list of tags
             * that it consumes. Add my own tag name to the list of tags I
             * produce
             */
            if (myOutputs != null) {
                for (Iterator itOut = myOutputs.iterator(); itOut.hasNext();) {
                    Object out = itOut.next();
                    if (out != null && descMessagables.get(out) != null) {
                        descMessagables.get(out).setUsed(true);
                        descMessagables.get(out).addToConsumesTags(
                                stnDesc.getProducesTags());
                    }
                }
            }
            /*
             * add the workflows that I am using to my configuration data
             */
            descSubComponents = ((EDSComponents) factory).getWorkflowDescriptors(
                    myWorkflow);
            for (Iterator itWf = myWorkflow.keySet().iterator(); itWf.hasNext();) {
                Object key = itWf.next();
                Object out = myWorkflow.get(key);
                if (out != null) {
                    descSubComponents.get(key).setUsed(true);
                    stnDesc.addToRequiresComponents(descSubComponents.get(
                            key));
                }
            }
        }
    }

    /**
     * Initializes the messaging system and all threaded objects.
     *
     * @pre The system must be configured prior to initialization.
     *
     * @throws ConfigurationException there are errors in the configuration file
     * @throws InitializationException there are errors in the initialization
     */
    @Override
    public void initialize() throws ConfigurationException, InitializationException {
        // Add in configuration using ioConnectorName
        try {
            Descriptor ctrlDesc = descControllers.get(usedControllerName);
            controller = componentFactory.newController(ctrlDesc);
            controller.setEngine(this);
        } catch (InvalidComponentClassException ex) {
            LOG.fatal("error creating controller " + usedControllerName, ex);
            InitializationException ex2 = new InitializationException("Fatal error in configuration; controller initialization failed.");
            ex2.addSuppressed(ex);
            throw ex2;
        } catch (NullPointerException ex) {
            LOG.fatal("failed to register name of controller to be used");
            InitializationException ex2 = new InitializationException("Fatal error in configuration - are you missing a 'controllers' section?");
            ex2.addSuppressed(ex);
            throw ex2;
        }
        this.workerService = Executors.newFixedThreadPool(maxThreads);
        LOG.debug("Created controllers");
        String connName;
        for (Iterator<String> it = descMessagables.keySet().iterator(); it.hasNext();) {
            connName = it.next();
            Descriptor connDesc = descMessagables.get(connName);
            try {
                connDesc.getOptions().put("stepStart", controller.getStepStart());
                connDesc.getOptions().put("stepFinal", controller.getStepStop());
                Messagable conn = componentFactory.newMessagable(connDesc);
                conn.setComponentFactory(this.getComponentFactory());
                conn.setBaseStep(controller.getStepBase());
                conn.initialize();
                Messagables.add(conn);
                router.register(conn);
                LOG.trace("added Messagable(" + conn.toString() + ")");
            } catch (InvalidComponentClassException ex) {
                LOG.fatal("error creating Messagable (" + connName + ")");
                InitializationException ex2 = new InitializationException("Fatal error in configuration; controller initialization failed.");
                ex2.addSuppressed(ex);
                throw ex2;
            } catch (RouterRegistrationException ex) {
                LOG.error("Registration error: ", ex);
            }
        }
        this.routerTask = this.routerService.scheduleWithFixedDelay(router, 0, 1,
                TimeUnit.MICROSECONDS);
    }

    /**
     * Parse a CANARY-EDS v4 or v5 configuration file. Calls #parseYAMLStream or
     * #parseJSONStream depending on the file extension.
     *
     * @param configfile name of the configuration file
     * @return mapping of the configuration parameters
     * @throws ConfigurationException there are errors with the configuration
     * file
     */
    public HashMap parseConfigFile(String configfile)
            throws ConfigurationException {
        config = null;
        LOG.info("Setting up CANARY-EDS from: \"" + configfile + "\"");
        File cfgFile = new File(configfile);
        Engine.setCurrentDirectory(cfgFile.getAbsoluteFile().getParent());
        try {
            FileInputStream is = new FileInputStream(cfgFile.getAbsoluteFile());
            if (configfile.endsWith(".json") || configfile.endsWith(".edsj")) {
                return parseJSONStream(is);
            } else if (configfile.endsWith(".edsy") || configfile.endsWith(
                    ".yml")) {
                return parseYAMLStream(is);
            }
            // Create a log file in the same directory as the configuration file
            Logger.getRootLogger().addAppender(new FileAppender(
                    new EnhancedPatternLayout("%d{DATE} %-5p: %m%n"),
                    new File("canaryeds.log").getAbsolutePath(), false));
        } catch (IOException ex) {
            LOG.fatal("failed to open file \"" + configfile + "\"", ex);
            throw new ConfigurationException(
                    "failed to open file \"" + configfile + "\"");
        }
        return config;
    }

    /**
     * Parse a YAML formatted CANARY-EDS v4 or v5 configuration file.
     *
     * @param stream a YAML formatted input stream
     * @return mapping of the configuration parameters
     * @throws ConfigurationException there are errors in the YAML stream
     */
    public HashMap parseYAMLStream(InputStream stream) throws ConfigurationException {
        config = null;
        try {
            Yaml yaml = new Yaml(new Constructor(), new Representer(),
                    new DumperOptions(), new CustomResolver());
            config = (HashMap) yaml.load(stream);
            stream.close();
            LOG.debug("Parsed " + stream.toString());
            // Create a log file in the same directory as the configuration file
            Logger.getRootLogger().addAppender(new FileAppender(
                    new EnhancedPatternLayout("%d{DATE} %-5p: %m%n"),
                    new File("canaryeds.log").getAbsolutePath(), false));
        } catch (IOException ex) {
            LOG.fatal("failed to open stream", ex);
            throw new ConfigurationException(
                    "failed to open stream");
        }
        return config;
    }

    /**
     * Parse a JSON formatted CANARY-EDS v4 or v5 configuration file.
     *
     * @param stream a JSON formatted input stream
     * @return mapping of the configuration parameters
     * @throws ConfigurationException there are errors in the JSON stream
     */
    public HashMap parseJSONStream(InputStream stream) throws ConfigurationException {
        config = null;
        try {
            JSONParser parser = new JSONParser();
            config = (HashMap) parser.parse(new InputStreamReader(stream));
            LOG.debug("Parsed " + stream.toString());
            stream.close();
            // Create a log file in the same directory as the configuration file
            Logger.getRootLogger().addAppender(new FileAppender(
                    new EnhancedPatternLayout("%d{DATE} %-5p: %m%n"),
                    new File("canaryeds.log").getAbsolutePath(), false));
        } catch (IOException ex) {
            LOG.fatal("failed to open stream", ex);
            throw new ConfigurationException(
                    "failed to open stream");
        } catch (ParseException ex) {
            LOG.fatal("syntax error in stream ", ex);
            throw new ConfigurationException(
                    "syntax error in stream ");
        }
        return config;
    }

    /**
     * Write output summary files for each of the monitoring stations in a list.
     *
     * @param stations an CopyOnWriteArrayList<ModelConnection> of stations
     */
    public static void outputEventSummaries(
            CopyOnWriteArrayList<ModelConnection> stations) {
        for (Iterator<ModelConnection> it = stations.iterator(); it.hasNext();) {
            try {
                Station s = (Station) it.next();
                ArrayList<EventRecord> events = s.getEvents();
                try (PrintWriter writer = new PrintWriter(
                        s.getName() + "_summary.yml", "UTF-8")) {
                    if (events.size() > 0) {
                        writer.println("event summaries:");
                        writer.println(
                                " - headers: " + events.get(0).summarize().get(
                                        "headers"));
                    }
                    for (EventRecord e : events) {
                        for (Object k : e.summarize().keySet()) {
                            if (!((String) k).equalsIgnoreCase("headers")) {
                                writer.println(
                                        " - " + k + ": " + e.summarize().get(
                                                k));
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                LOG.warn(ex);
            }
        }

    }

}
