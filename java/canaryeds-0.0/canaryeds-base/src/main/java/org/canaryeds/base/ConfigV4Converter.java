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

import gov.sandia.seme.framework.ChannelType;
import gov.sandia.seme.framework.ConfigurationException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import org.apache.log4j.Logger;
import org.json.simple.JSONObject;
import org.yaml.snakeyaml.Yaml;

/**
 * @if doxyUser
 * @page userConvert Converting v4 Configuration Files to v5 Format
 * 
 * @endif
 */
/**
 * Provides configuration file reads and conversion from v4 to v5 formats.
 * Converts version 4 configuration files into version 5 objects, and also
 * creates the Descriptor hashes used by the Factory objects to create the
 * actual controller, connector, channel, work flow and monitoring station
 * objects. The CANARY-EDS configuration file (version 4) is defined in the
 * CANARY-EDS user manual. The following describes the new format of
 * configuration files, and the reasoning behind those changes.
 *
 * The previous version of CANARY-EDS was written in MATLAB(R), mixed with Java.
 * While this was great for the rapid development of CANARY, it also brought
 * limitations when it came to extending custom interfaces to databases, etc.
 * While the old, v4 configuration files continue to be valid -- and for many
 * users the old format will provide everything they need -- the flexibility of
 * a pure Java software package means that certain elements will do better if
 * they are restructured.
 *
 * First of all, the CANARY-EDS v5+ will accept either YAML or JSON formatted
 * configuration files. As JSON is a standard method of encoding objects, like
 * configurations, within web-interface and other applications, this addition
 * means that CANARY-EDS configuration files can be more easily saved, stored in
 * databases, and/or configured on the fly than using YAML. YAML is still much
 * more human readable, and is the preferred method when editing configurations
 * by hand (and since the authors are not providing a web interface at this
 * time, there will likely be a lot of that).
 *
 * The most obvious change is that some of the tags have been renamed. As has
 * been pointed out by a number of users (and within the development team!) the
 * name "Signals" has a very specific computer science connotation -- and it
 * isn't the one that was meant by "signals" in the configuration file. So the
 * old "signals" section has been renamed "channels," as "data channels" more
 * accurately describes both what CANARY's "signals" and how they are used. The
 * next change is that "data sources" has been changed to "connectors" -- again,
 * this is a more accurate description of what a "connector" does (it connects
 * CANARY-EDS to an outside data source/sink) and it is simpler to say and write
 * than "data sources and sinks." Following in this vein, the "algorithms"
 * section has been renamed "workflows," highlighting the fact that we define
 * not only event detection algorithms, but also pattern matching and multiple
 * algorithm paths, and the "monitoring stations" section has been shortened to
 * just "stations." Just to reiterate - the old format files still work, but you
 * can't mix and match! We've added a "version" tag to differentiate between
 * them, and remind the user editing the files which style is in use. All tags
 * go inside a parent "canary:" tag in the new format.
 *
 * <table border="1">
 * <tr>
 * <th>Version 4 section title</th>
 * <th>Version 5 section title</th>
 * </tr>
 * <td></td>
 * <td><code>version</code> <i>{new configuration file version
 * indicator}</i></td>
 * </tr>
 * <tr>
 * <td><code>canary</code>, <code>timing options</code></td>
 * <td><code>controller</code> <i>{these two now combined in v5}</i></td>
 * </tr>
 * <tr>
 * <td><code>data sources</code></td>
 * <td><code>connectors</code></td>
 * </tr>
 * <tr>
 * <td><code>signals</code></td>
 * <td><code>channels</code></td>
 * </tr>
 * <tr>
 * <td><code>algorithms</code></td>
 * <td><code>workflows</code></td>
 * </tr>
 * <tr>
 * <td><code>monitoring stations</code></td>
 * <td><code>stations</code></td>
 * </tr>
 * </table>
 *
 * Another obvious change is in the style used to configure individual elements.
 * Where, previously, lists were used within the main headings (see the example
 * below), we are now using the object's ID, or name, as the title. This
 * provides two benefits -- first, it is easier to get at a list of just the
 * names through code folding, and second, it means there is built-in error
 * checking for repeat names. The next change is that the Java class for the
 * object is specified after the name. In the example below, the channel "PH_1"
 * is declared to be a <code>SimpleValue</code> object. We will discuss what
 * that means later. The following example shows the differences:
 *
 * <table>
 * <tr>
 * <th>Version 4, example signals</th>
 * <th>Version 5, example channels</th>
 * </tr>
 * <tr>
 * <td><code>data sources:</code></td>
 * <td><code>channels:</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;- id: PH_1</code></td>
 * <td><code>&nbsp;&nbsp;"PH_1":</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;#</code><i>no equivalent</i></td>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;SimpleValue:</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;tag: P_0x45256</code></td>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tag: P_0x45256</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;...</code></td>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;...</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;- id: CL_2</code></td>
 * <td><code>&nbsp;&nbsp;"CL_2":</code></td>
 * </tr>
 * <tr>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;...</code></td>
 * <td><code>&nbsp;&nbsp;&nbsp;&nbsp;...</code></td>
 * </tr>
 * </table>
 *
 * @htmlonly
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 4363 $, $Date: 2014-06-16 10:01:49 -0600 (Mon, 16 Jun 2014) $
 * @endhtmlonly
 */
public class ConfigV4Converter {

    private static final Logger LOG = Logger.getLogger(ConfigV4Converter.class);

    /**
     * Convert a version 4 configuration file to a version 5 configuration
     * object.
     *
     * @test Tested in ConfiguratorTest#testConvertV4toV5 by converting a configuration file that has all the different possible sections needing conversion.
     *
     * @param config configuration dictionary (v4-)
     * @return configuration dictionary (v5+)
     * @throws ConfigurationException two components have the same name/id
     */
    public static HashMap convertV4toV5(HashMap config) throws ConfigurationException {
        HashMap v5config = new HashMap();
        LOG.info(
                "Converting version 4.x configuration to version 5.x configuration");
        HashMap ctrl = (HashMap) config.get("canary");
        HashMap time = (HashMap) config.get("timing options");
        ArrayList iods = (ArrayList) config.get("data sources");
        ArrayList sigs = (ArrayList) config.get("signals");
        ArrayList algs = (ArrayList) config.get("algorithms");
        ArrayList mons = (ArrayList) config.get("monitoring stations");

        HashMap controls = convertV4MainToController(ctrl, time);
        LOG.debug("New \"controllers\" section: " + controls);
        HashMap connectors = convertDataSourcesToConnectors(iods);
        LOG.debug("New \"connections\" section: " + connectors);
        HashMap channels = convertSignalsToChannels(sigs);
        LOG.debug("New \"data channels\" section: " + channels);
        HashMap workflows = convertAlgorithmsToWorkflows(algs);
        LOG.debug("New \"model components: workflows\" section: " + workflows);
        HashMap stations = convertMonitoringStationsToStations(mons, workflows);
        LOG.debug("New \"models\" section: " + stations);
        connectors.putAll(stations);
        v5config.put("controllers", controls);
        v5config.put("data channels", channels);
        v5config.put("connections", connectors);
        v5config.put("canary workflows", workflows);
        v5config.put("canary stations", stations);
        v5config.put("CANARY-EDS", 5);

        String yamlString = printYAMLMap(v5config);
        LOG.info(
                "Printing configuration to log as YAML\n---\n" + yamlString + "...\n");
        return v5config;
    }

    /**
     * Print an arbitrary configuration object as a JSON string.
     *
     * @param config configuration dictionary
     * @return JSON formatted string representing configuration
     */
    public static String printJSONMap(HashMap config) {
        String jsonString = JSONObject.toJSONString(config);
        return jsonString;
    }

    /**
     * Print an arbitrary configuration object as a YAML string.
     *
     * @param config configuration dictionary
     * @return YAML formatted string representing configuration
     */
    public static String printYAMLMap(HashMap config) {
        return new Yaml().dump(config);
    }

    /**
     * Converts a v4.3 'algorithms' section to a 'workflows' section.
     *
     * @param config v4.3 'algorithms' section
     * @return v5.x 'workflows' section
     */
    private static HashMap convertAlgorithmsToWorkflows(ArrayList config) {
        LOG.trace("-> convertAlgorithmsToWorkflows");
        HashMap v5config = new HashMap();
        for (Object h : config) {
            HashMap nc = new HashMap();
            HashMap hm = (HashMap) h;
            HashMap newConnCfg = new HashMap();
            String id = (String) hm.get("id");
            hm.remove("id");
            String className;
            String oldType = (String) hm.get("type");
            hm.remove("type");
            if (oldType.equalsIgnoreCase("LPCF")) {
                className = "workflows.LPCF_BED";
            } else if (oldType.equalsIgnoreCase("MVNN")) {
                className = "workflows.MVNN_BED";
            } else if (oldType.equalsIgnoreCase("SPPE")
                    || oldType.equalsIgnoreCase("SPPB")) {
                className = "workflows.SetPointProximity";
            } else if (oldType.equalsIgnoreCase("CAVE")
                    || oldType.equalsIgnoreCase("CMAX")) {
                className = "CombinedAverage";
            } else {
                className = "BasicWorkflow";
            }
            newConnCfg.put("name", id);
            //newConnCfg.put("className", className);
            nc.put(className, hm);
            v5config.put(id, nc);
        }
        return v5config;
    }

    /**
     * Converts v4.3 'data sources' options to 'connectors' options.
     *
     * @param config v4.3 'data sources' section
     * @return v5.x 'connectors' section
     */
    private static HashMap convertDataSourcesToConnectors(ArrayList config) {
        LOG.trace("-> convertDataSourcesToConnectors");
        HashMap v5config = new HashMap();
        for (Object h : config) {
            HashMap nc = new HashMap();
            HashMap hm = (HashMap) h;
            HashMap newConnCfg = new HashMap();
            String id = (String) hm.get("id");
            hm.remove("id");
            String className;
            String oldType = (String) hm.get("type");
            if (oldType.equalsIgnoreCase("CSV")) {
                className = "text.CSVReaderWide";
            } else if (oldType.equalsIgnoreCase("FILE")) {
                className = "text.CSVWriter";
            } else if (oldType.equalsIgnoreCase("DB")
                    || oldType.equalsIgnoreCase("JDBC")) {
                className = "database.TableReader";
            } else if (oldType.equalsIgnoreCase("EDDIES")) {
                className = "EDDIES";
            } else if (oldType.equalsIgnoreCase("XML")) {
                className = "XML";
            } else {
                className = oldType;
            }
            if (hm.containsKey("timestepOpts")) {
                HashMap tsOpt = (HashMap) hm.get("timestep options");
                for (Object key : tsOpt.keySet()) {
                    hm.put("step" + key, tsOpt.get(key));
                }
                hm.remove("timestepOpts");
            }
            if (hm.containsKey("timestep options")) {
                HashMap tsOpt = (HashMap) hm.get("timestep options");
                for (Object key : tsOpt.keySet()) {
                    hm.put("step" + key, tsOpt.get(key));
                }
                hm.remove("timestep options");
            }
            newConnCfg.put("name", id);
            //newConnCfg.put("className", className);
            nc.put(className, hm);
            v5config.put(id, nc);
        }
        return v5config;
    }

    /**
     * Converts a v4.3 'monitoring stations' section to a 'stations' section
     *
     * @param config v4.3 'monitoring stations' section
     * @return v5.x 'stations' section
     */
    private static HashMap convertMonitoringStationsToStations(ArrayList config,
            HashMap workflows) {
        LOG.trace("-> convertMonitoringStationsToStations");
        HashMap v5config = new HashMap();
        for (Object h : config) {
            HashMap newStnCfg = new HashMap();
            HashMap hm = (HashMap) h;
            String id = (String) hm.get("id");
            for (Iterator it = hm.keySet().iterator(); it.hasNext();) {
                String k = (String) it.next();
                Object v = hm.get(k);
                switch (k) {
                    case "inputs":
                        ArrayList inps = (ArrayList) v;
                        ArrayList<String> inputs = new ArrayList();
                        for (int i = 0; i < inps.size(); i++) {
                            String tmpId = (String) ((Map) inps.get(i)).get(
                                    "id");
                            inputs.add(tmpId);
                        }
                        newStnCfg.put("inputs", inputs);
                        break;
                    case "outputs":
                        ArrayList outs = (ArrayList) v;
                        ArrayList<String> outputs = new ArrayList();
                        if (outs != null) {
                            for (int i = 0; i < outs.size(); i++) {
                                String tmpId = (String) ((Map) outs.get(i)).get(
                                        "id");
                                outputs.add(tmpId);
                            }
                        } else {
                            outputs = null;
                        }
                        newStnCfg.put("outputs", outputs);
                        break;
                    case "signals":
                        ArrayList sigs = (ArrayList) v;
                        ArrayList<String> channels = new ArrayList();
                        for (int i = 0; i < sigs.size(); i++) {
                            String tmpId = (String) ((Map) sigs.get(i)).get(
                                    "id");
                            channels.add(tmpId);
                        }
                        newStnCfg.put("channels", channels);
                        break;
                    case "algorithms":
                        ArrayList algs = (ArrayList) v;
                        HashMap wkflws = new HashMap();
                        for (int i = 0; i < algs.size(); i++) {
                            String tmpId = (String) ((Map) algs.get(i)).get(
                                    "id");
                            wkflws.put(tmpId, workflows.get(tmpId));
                        }
                        newStnCfg.put("workflow", wkflws);
                        break;
                    case "station tag name":
                        newStnCfg.put("tagPrefix", v);
                        break;
                    case "station id number":
                        newStnCfg.put("idNumberStation", v);
                        break;
                    case "location id number":
                        newStnCfg.put("idNumberLocation", v);
                        break;
                    case "id":
                        break;
                    default:
                        newStnCfg.put(k, v);
                        break;
                }
            }
            newStnCfg.put("name", id);
            HashMap newStn2 = new HashMap();
            newStn2.put("Station", newStnCfg);
            v5config.put(id, newStn2);
        }
        return v5config;
    }

    /**
     * Converts v4.3 'signals' section to a channels section.
     *
     * @param config v4.3 'signals' section
     * @return v5.x 'channels' section
     * @throws ConfigurationException two or more signals have the same name/id
     */
    private static HashMap convertSignalsToChannels(ArrayList config) throws ConfigurationException {
        LOG.trace("-> convertSignalsToChannels");
        HashMap v5config = new HashMap();
        for (Object sig : config) {
            if (sig == null) {
                continue;
            }
            HashMap nc = new HashMap(); // create the new V5 HashMap
            HashMap sigConf = (HashMap) sig;
            HashMap newSigConf = new HashMap();
            String evalType = (String) sigConf.get("evaluation type");
            String paramType = (String) sigConf.get("parameter type");
            String ignoreChanges = (String) sigConf.get("ignore changes");
            String sigName = (String) sigConf.get("id");
            String scadaTag = (String) sigConf.get("SCADA tag");
            String className = null;
            HashMap dataOpts = (HashMap) sigConf.get("data options");
            HashMap flagOpts = (HashMap) sigConf.get("alarm options");
            HashMap options = new HashMap();
            Object compOpts = sigConf.get("composite rules");
            newSigConf.put("name", sigName);
            newSigConf.put("tag", scadaTag);
            newSigConf.put("parameter", paramType);
            className = "datachannels.SCADAChannel";
            newSigConf.put("className", className);
            options.put("usage", evalType);
            newSigConf.put("type", ChannelType.VALUE);
            if (compOpts != null) {
                newSigConf.put("className", className);
                options.put("compositeRules", compOpts);
                // newSigConf.put("options",dataOpts);
            }
            if (dataOpts != null) {
                for (Iterator it = dataOpts.keySet().iterator(); it.hasNext();) {
                    Object k = it.next();
                    Object v = dataOpts.get(k);
                    options.put(k, v);
                }
            }
            if (flagOpts != null) {
                for (Iterator it = flagOpts.keySet().iterator(); it.hasNext();) {
                    Object k = it.next();
                    Object v = flagOpts.get(k);
                    options.put(k, v);
                }
            }
            newSigConf.putAll(options);
            nc.put(className, newSigConf);
            if (v5config.containsKey(sigName)) {
                throw new ConfigurationException(
                        "ERROR: You have defined the signal '" + sigName + "' more than once!");
            }
            v5config.put(sigName, nc);
        }
        return v5config;
    }

    /**
     * Converts v4 'canary' and 'timing options' to 'controller' options.
     *
     * @param ctrl v4.3 'canary' section
     * @param time v4.3 'timing options' section
     * @return v5.x 'controller' section
     */
    private static HashMap convertV4MainToController(HashMap ctrl, HashMap time) {
        LOG.trace("-> convertV4MainToController");
        HashMap nc = new HashMap();
        String runMode = (String) ctrl.get("run mode");
        String ctrlType = (String) ctrl.get("control type");
        String ctrlMsgr = (String) ctrl.get("control messenger");
        nc.put("ioConnectorName", ctrlMsgr);
        nc.put("loadLastState", ctrl.get("use continue"));
        nc.put("globalDataStyle", ctrl.get("data provided"));
        if (time.containsKey("stepType")) {
            nc.put("stepType", time.get("stepType"));
        } else {
            nc.put("stepType", "Date");
        }
        nc.put("stepDynamic", time.get("dynamic start-stop"));
        String stepFormat = (String) time.get("date-time format");
        boolean isAmPm = false;
        if (stepFormat.contains("AM") || stepFormat.contains("PM")) {
            isAmPm = true;
        }
        if (isAmPm) {
            stepFormat = stepFormat.replace("AM", "a");
            stepFormat = stepFormat.replace("PM", "a");
            stepFormat = stepFormat.replace('H', 'h');
        }
        stepFormat = stepFormat.replace('m', 'N');
        stepFormat = stepFormat.replace('M', 'm');
        stepFormat = stepFormat.replace('N', 'M');
        stepFormat = stepFormat.replace('S', 's');
        stepFormat = stepFormat.replace('F', 'S');
        nc.put("globalStepFormat", stepFormat);
        nc.put("stepStart", time.get("date-time start"));
        nc.put("stepFinal", time.get("date-time stop"));
        nc.put("stepSize", time.get("data interval"));
        nc.put("pollRate", time.get("message interval"));
        if (runMode.equalsIgnoreCase("batch")) {
            nc.put("className", "controllers.Batch");
            runMode = "controllers.Batch";
        } else if (runMode.equalsIgnoreCase("realtime")
                && ctrlType.equalsIgnoreCase("internal")) {
            nc.put("className", "controllers.InternalClock");
            runMode = "controllers.InternalClock";
        } else if (runMode.equalsIgnoreCase("eddies")) {
            nc.put("className", "external.EDDIES.EDDIESController");
            runMode = "external.EDDIES.EDDIESController";
        } else if (runMode.equalsIgnoreCase("realtime")
                && ctrlType.equalsIgnoreCase("external")) {
            nc.put("className", "XMLSocketServer");
            runMode = "XMLSocketServer";
        } else {
            nc.put("className", runMode);
        }
        HashMap v5ctrl = new HashMap();
        HashMap v5config = new HashMap();
        v5ctrl.put(runMode, nc);
        v5config.put("canary-eds", v5ctrl);
        return v5config;
    }
}
