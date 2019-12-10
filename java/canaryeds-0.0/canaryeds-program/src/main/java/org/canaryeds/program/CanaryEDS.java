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
package org.canaryeds.program;

import org.canaryeds.base.CANARY;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.framework.Controller;
import gov.sandia.seme.util.ControllerImpl;
import java.io.File;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.ResourceBundle;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.ArgumentParserException;
import net.sourceforge.argparse4j.inf.Namespace;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

/**
 * This is the main CANARY-EDS program, which reads the command line arguments
 * and which then launches the CANARY event detection software. This main class
 * will (TODO) start a simple GUI thread with simple controls. However, this is
 * not the highest priority right now.
 * <p>
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 4363 $, $Date: 2014-06-16 10:01:49 -0600 (Mon, 16 Jun 2014) $
 */
public class CanaryEDS {

    private static final Logger LOG = Logger.getLogger("org.canaryeds");
    private static final ResourceBundle messages = java.util.ResourceBundle.getBundle(
            "org.canaryeds.base.app");

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        System.err.println("CANARY-EDS "
                + messages.getString("application.version") + ". "
                + messages.getString("application.copyright"));
        System.err.println(messages.getString("application.license"));
        System.err.println();
        LOG.info("CANARY-EDS starting up");
        LOG.debug("Version " + messages.getString("application.version"));
        LOG.debug(messages.getString("application.buildNumber"));
        LOG.debug(messages.getString("application.sourceRev"));
        try {
            // TODO create a GUI to start/stop/save CANARY

            // Set command line options and configuration file on eds object
            //   loading configuration file returns a org.canaryeds.core.ControllerImpl
            //   object
            ArgumentParser parser = CANARY.getNewParser();
            parser = CANARY.addArguments(parser);
            Namespace res = parser.parseArgs(args);
            boolean noGui = false;
            if (!res.getBoolean("nw")) {
                AppMain.main(args);
            } else {
                CANARY eds = new CANARY();
                ControllerImpl control;
                Level eLevel = eds.setup(res);
                LOG.setLevel(eLevel);
                Logger.getRootLogger().setLevel(eLevel);
                File configFile;
                String cmdLineCfgFile = res.getString("configfile");
                if (cmdLineCfgFile != null) {
                    configFile = new File(cmdLineCfgFile);
                    //This is where a real application would open the file.
                    LOG.info(
                            "Opening configuration file specified on command line: " + configFile.getName() + ".");
                    HashMap config = eds.parseConfigFile(
                            configFile.getAbsolutePath());
                    if (config == null) {
                        throw new ConfigurationException(
                                "Failed to load the configuration file: " + configFile.getName());
                    } else {
                        eds.configure(config);
                    }
                    eds.initialize();
                    Controller ctrl = eds.getController();
                    ctrl.run();
                    eds.shutdown();
                    LOG.info(messages.getString("exit.success"));
                } else {
                    LOG.fatal("No configuration file specified, and --nw option selected. Exiting.");
                }
            }
        } catch (ConfigurationException ex) {
            LOG.fatal(messages.getString("err.config"), ex);
            LOG.info(messages.getString("exit.failure"));
        } catch (InitializationException ex) {
            LOG.fatal(messages.getString("exit.failure"));
        } catch (ArgumentParserException ex) {
            LOG.fatal(messages.getString("exit.failure"));
        }
    }
}
