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
package org.canaryeds.base.workflows;

import org.canaryeds.base.EventStatus;
import static org.canaryeds.base.util.NaNMath.nanmean;
import static org.canaryeds.base.util.NaNMath.nanstd;
import org.canaryeds.base.util.WorkflowImpl;
import gov.sandia.seme.framework.DataChannel;
import gov.sandia.seme.framework.DataStatus;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import java.util.HashMap;
import org.apache.commons.math3.stat.descriptive.rank.Min;
import static org.apache.commons.math3.util.FastMath.abs;
import static org.apache.commons.math3.util.FastMath.max;
import org.apache.commons.math3.util.MathArrays;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userMVNN_BED Configuration Details: Using workflows.MVNN_BED
 * 
 * @endif
 */
/**
 * Provides a workflow based on the MVNN (multivariate nearest neighbor)
 * approach. Calculates the minimum <i>n</i>-space mulutivariate distance
 * between the current observation point and the points within the history
 * window. There are three methods for how to calculate the multivariate
 * distance: the L<sub>1</sub> distance calculates the sum of the absolute
 * distances in each dimension; the L<sub>2</sub> distance, or the Euclidean
 * distance, calculates the square root of the sum of squared distances; and
 * L<sub>&infin;</sub>
 * distance is the maximum of the absolute distance for each dimension. The
 * outlier threshold (see below) is compared to the multivariate
 * distance, not the individual dimension distances. The
 * L<sub>2</sub> Euclidean distance method is used by default
 * Please see
 * @cite klise2006water
 * and
 * @cite klise2006multivariate
 * for more details regarding the algorithm's underlying math.
 *
 * When defining a workflow descriptor using this class, the className
 * should be set to "workflows.MVNN_BED". The following configuration options
 * are available for this workflow (shown in a key:value mapping format):
 *
 * <ul>
 * <li><b>history window:</b> integer, defines the number of steps of values to
 * keep in the calculation history</li>
 * <li><b>outlier threshold:</b> double, defines the prediction error (in
 * standard deviations) for the status to become {@code OUTLIER_DETECTED}</li>
 * <li><b>distance type:</b> string, defines the multivariate distance
 * calculation method. Valid strings are: {@code L1}, {@code L2} or
 * {@code Euclidean}, and {@code Linf}; see description above for meanings, if
 * omitted, the {@code Linf} method is used</li>
 * <li><b>BED:</b> mapping, of the following keys (defines the BED options,
 * which determine probability)</li>
 * <ul>
 * <li><b>window:</b> integer, defines the number of steps in the binomial event
 * discriminator</li>
 * <li><b>outlier probability:</b> double, defines the shape of the event curve,
 * default setting is 0.5</li>
 * </ul>
 * <li><b>event threshold:</b> double, defines the value which the probability
 * must equal or exceed for the status to become {@code POSSIBLE_EVENT}</li>
 * <li><b>event timeout:</b> integer, defines the number of steps with a status
 * of {@code POSSIBLE_EVENT} before the status is changed to
 * {@code EVENT_TIMEOUT}, and the history window is reset to include
 * outliers</li>
 * <li><b>event window save:</b> integer, defines the number of steps
 * <i>prior</i>
 * to the start of an event to save as context for the event</li>
 * </ul>
 * <p>
 * An example of the options as set out in a YAML configuration file is shown
 * below.
 * <p>
 * <table border=1>
 * <tr><td>
 * <code>
 * canary workflows:<br>
 * &nbsp;&nbsp;# ... other definitions<br>
 * &nbsp;&nbsp;<i>workflowName</i>:<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;workflows.MVNN_BED:<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;history window: 72<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;outlier threshold: 0.8<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;event threshold: 0.85<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;event timeout: 12<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;event window save: 30<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;distance type: euclidean<br>
 * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;BED: {window: 6, outlier probability:
 * 0.5}<br>
 * &nbsp;&nbsp;# ... more definitions<br>
 * </code>
 * </td></tr></table>
 * <br>
 *
 * @ingroup grpWorkflows
 * @internal
 * @author dbhart
 */
public class MVNN_BED extends WorkflowImpl {

    private static final Logger LOG = Logger.getLogger(MVNN_BED.class);

    private int distanceType = 2;

    /**
     * General constructor for MVNN_BED.
     */
    public MVNN_BED() {
        super();
    }

    /**
     * Configure the current workflow with a configuration descriptor.
     * @param desc The configuration descriptor.
     * @throws ConfigurationException 
     */
    @Override
    public void configure(Descriptor desc) throws ConfigurationException {
        /*
         * type: LPCF history window: 36 outlier threshold: 0.8 event threshold:
         * 0.85 event timeout: 12 event window save: 30 BED: {window: 6, outlier
         * probability: 0.5}
         */
        LOG.debug("Configuring MVNN plus BED");
        HashMap opts = desc.getOptions();
        this.name = desc.getName();
        for (Object k : opts.keySet()) {
            String key = ((String) k).toLowerCase();
            int tempInt;
            double tempDouble;
            String tempStr;
            if (opts.get(k) == null) {
                LOG.warn("Configuration Error - key '"+k.toString()+"' is null.");
                continue;
            }
            switch (key) {
                case "history window":
                    tempInt = ((Number) opts.get(k)).intValue();
                    this.sz_historyWindow = tempInt;
                    break;
                case "outlier threshold":
                    tempDouble = ((Number) opts.get(k)).doubleValue();
                    this.outlierThreshold = tempDouble;
                    break;
                case "event threshold":
                    tempDouble = ((Number) opts.get(k)).doubleValue();
                    this.eventThreshold = tempDouble;
                    break;
                case "event timeout":
                    tempInt = ((Number) opts.get(k)).intValue();
                    this.sz_eventTimeout = tempInt;
                    break;
                case "event window save":
                    tempInt = ((Number) opts.get(k)).intValue();
                    this.sz_eventWindowSave = tempInt;
                    break;
                case "distance type":
                    tempStr = (String) opts.get(k);
                    if (tempStr.equalsIgnoreCase("euclidean")
                            || tempStr.equalsIgnoreCase("L2")) {
                        distanceType = 2;
                    } else if (tempStr.equalsIgnoreCase("L1")) {
                        distanceType = 1;
                    } else {
                        distanceType = 0;
                    }
                    break;
                case "bed":
                    HashMap hmBED = (HashMap) opts.get(k);
                    tempInt = ((Number) hmBED.get("window")).intValue();
                    tempDouble = ((Number) hmBED.get("outlier probability")).doubleValue();
                    this.bedOutlierProbability = tempDouble;
                    this.sz_bedWindow = tempInt;
                    break;
                default:
                    LOG.warn("Configuration Error - key '"+k.toString()+"' is unrecognized.");
                    break;
            }
        }
        if (!this.checkParams()) {
            throw new ConfigurationException("Failed to configure the workflow!");
        }
    }

    /**
     * Evaluate the current workflow at a given index.
     * @param index The index to evaluate at.
     * @return 
     */
    @Override
    public HashMap evaluateWorkflow(int index) {
        HashMap res = new HashMap();
        double sum = 0.0;
        int nzCount = this.doCalcNZCount(index);
        distances.clear();
        this.rawData.clear();
        this.violations.clear();
        this.contributed.clear();
        this.residuals.clear();
        this.probability = Double.NaN;
        this.status = EventStatus.NORMAL;
        if (historyWindow[0].getNumElements() < sz_historyWindow) {
            this.doProcInitHistoryWindow(index);
        } else if (nzCount < 1) {
            this.doProcMissingData(index);
        } else {
            double pt1[] = new double[nzCount];
            double pt2[] = new double[nzCount];
            double norm1[] = new double[nzCount];
            double norm2[] = new double[nzCount];
            int ct = 0;
            int ct2 = 0;
            for (DataChannel chan : channels) {
                this.rawData.add(chan.getDoubleValue(index));
                if (chan.getStatus() == DataStatus.OUT_OF_CTL_LIMIT) {
                    this.violations.add(1);
                    this.status = EventStatus.CHANNELS_ALARMING;
                } else if (chan.getStatus() == DataStatus.OUT_OF_VALID_RANGE) {
                    this.violations.add(2);
                    this.status = EventStatus.CHANNELS_ALARMING;
                } else if (chan.getStatus() == DataStatus.FLAGGED_BAD_QUALITY) {
                    this.violations.add(3);
                    this.status = EventStatus.CHANNELS_ALARMING;
                } else {
                    this.violations.add(0);
                }
                if (!Double.isNaN(chan.getDoubleValue(index)) && chan.getStatus() == DataStatus.NORMAL) {
                    double tmpmean = nanmean(historyWindow[ct2].getElements());
                    double tmpstd = nanstd(historyWindow[ct2].getElements(),
                            tmpmean);
                    norm1[ct] = tmpmean;
                    norm2[ct] = tmpstd;
                    if (norm2[ct] < precisions[ct2] / (outlierThreshold)) {
                        norm2[ct] = 1.001 * precisions[ct2] / (outlierThreshold);
                    }
                    pt1[ct] = (chan.getDoubleValue(index) - norm1[ct]) / norm2[ct];
                    ct++;
                }
                ct2++;
            }
            double curMin = Double.POSITIVE_INFINITY;
            for (int i = 0; i < sz_historyWindow; i++) {
                ct = 0;
                ct2 = 0;

                for (DataChannel chan : channels) {
                    if (!Double.isNaN(chan.getDoubleValue(index)) && chan.getStatus() == DataStatus.NORMAL) {
                        pt2[ct] = (historyWindow[ct2].getElement(i) - norm1[ct]) / norm2[ct];
                        ct++;
                    }
                    ct2++;
                }
                double delt;
                if (distanceType == 0) {
                    delt = MathArrays.distanceInf(pt1, pt2);
                } else if (distanceType == 1) {
                    delt = MathArrays.distance1(pt1, pt2);
                } else {
                    delt = MathArrays.distance(pt1, pt2);
                }
                if (!Double.isNaN(delt)) {
                    distances.addElement(delt);
                    if (delt <= curMin) {
                        curMin = delt;
                        res.put("non-zero items", MathArrays.ebeSubtract(pt1,
                                pt2));
                    }
                }
            }
            double dist = distances.compute(new Min());
            ct = 0;
            if (dist < outlierThreshold) {
                for (DataChannel chan : channels) {
                    double val = chan.getDoubleValue(
                            index);
                    historyWindow[ct].addElementRolling(val);
                    ct++;
                }
                bedWindow.addElementRolling(0);
            } else {
                bedWindow.addElementRolling(1);
                this.status = EventStatus.OUTLIER_DETECTED;
                res.put("eventCode", EventStatus.OUTLIER_DETECTED);
            }

            /*
             * CALCULATE BED VALUES HERE
             */
            this.doCalcBEDProbability();
            /*
             * DO EVENT TIMEOUT HERE
             */
            this.doCalcEventTimeout(index);
            /*
             * DO CONTRIBUTING PARAMETER CALCULATIONS
             */
            res.put("sum", dist);
            Object nze = res.get("non-zero items");
            ct = 0;
            if (nze != null) {
                double[] resids = (double[]) res.get("non-zero items");
                double sumRes = 0.0;
                for (Double r : resids) {
                    sumRes += abs(r);
                }
                for (DataChannel chan : channels) {
                    if (!Double.isNaN(chan.getDoubleValue(index)) && chan.getStatus() == DataStatus.NORMAL) {
                        this.residuals.add(resids[ct]);
                        if (abs(resids[ct]) >= this.outlierThreshold
                                || (dist > outlierThreshold && abs(resids[ct]) > sumRes / (max(
                                        1.0, nzCount - 2)))) {
                            this.contributed.add((short)1);
                        } else {
                            this.contributed.add((short)0);
                        }
                        ct++;
                    } else if (chan.getStatus() == DataStatus.FLAGGED_BAD_QUALITY
                            || chan.getStatus() == DataStatus.OUT_OF_CTL_LIMIT
                            || chan.getStatus() == DataStatus.OUT_OF_VALID_RANGE) {
                        this.residuals.add(Double.POSITIVE_INFINITY);
                        this.contributed.add((short)2);
                    } else {
                        this.residuals.add(Double.NaN);
                        this.contributed.add((short)0);
                    }
                }
                String resString = "[";
                for (int jres = 0; jres < resids.length; jres++) {
                    resString += "" + resids[jres] + ", ";
                }
                resString += "]";
                res.put("non-zero items", resString);
            } else {
                for (DataChannel chan : channels) {
                    this.residuals.add(Double.NaN);
                    this.contributed.add((short)0);
                }
            }
        }
        res.put("eventProbability", this.probability);
        res.put("eventCode", this.status);
        return res;
    }

    /**
     * Get the current configuraiton. Not currently supported.
     * @return  The current configuration.
     */
    @Override
    public Descriptor getConfiguration() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    /**
     * Initialize the current system. Throws an exception if the parameter check fails.
     * @throws InitializationException
     */
    @Override
    public void initialize() throws InitializationException {
        LOG.debug("Initializing MVNN with BED");
        super.initialize();
        if (!this.checkParams()) {
            throw new InitializationException("Failed to configure all options on the workflow!");
        }        
    }

}
