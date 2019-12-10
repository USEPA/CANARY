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
package org.canaryeds.base.datachannels;

import org.canaryeds.base.ChannelUsage;
import gov.sandia.seme.framework.ChannelType;
import gov.sandia.seme.framework.DataChannel;
import gov.sandia.seme.framework.DataStatus;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.MissingDataPolicy;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.framework.DataOutOfFrameException;
import gov.sandia.seme.util.LazyModulusArray;
import static java.lang.Math.max;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import org.apache.log4j.Logger;

/**
 * @if doxyUser
 * @page userSCADAChannel Configuration Details: Using datachannels.SCADAChannel
 *
 * @endif
 */
/**
 * Provides a simple value-based data channel. This type of data channel
 * provides real-number values which are used in event detection, or in pattern
 * recognition algorithms, or which are inputs to composite channels. Simple
 * values come with the following options:
 *
 * <b>Set points:</b> provide a range of values which are acceptable; when a
 * value falls outside the set-points, checking the status of this channel will
 * return a DataStatus.OUT_OF_CTL_LIMIT status value.
 *
 * <b>Valid range:</b> provides a range of values which are valid; for example,
 * a pH reading of 15 is a physical impossibility, and such a reading should not
 * be used. Values which fall outside the valid range will set the channel's
 * status to DataStatus.OUT_OF_VALID_RANGE.
 *
 * <b>Precision:</b> provides a minimum sigma value for event detection
 * algorithms. A value change that is less-than-or-equal-to the precision of a
 * channel is never considered an event (unless it places the value outside the
 * set points or valid range, which is a special case).
 *
 * <b>Units:</b> is for information purposes only; CANARY-EDS does <i>not</i>
 * do units conversion. Ever.
 *
 * @internal
 * @author dbhart
 * @author $LastChangedBy: dbhart $
 * @version $Rev: 4374 $, $Date: 2015-01-27 10:01:15 -0700 (Tue, 27 Jan 2015) $
 */
public class SCADAChannel implements DataChannel {

    private static final Logger LOG = Logger.getLogger(SCADAChannel.class);
    ArrayList<DataChannel> linkedChannels;
    final boolean copyMissing;
    int dataFrameSize;
    int almAbnormal;
    DataStatus currentStatus;
    LazyModulusArray dataValues;
    String name;
    HashMap options;
    ArrayList<String> requires;
    String tag;
    ChannelUsage usage = null;
    int currentIndex;
    boolean warnedNoStatus;
    double validRangeLow;
    double validRangeHigh;
    double setPointLow;
    double setPointHigh;
    final HashMap<String, Object> metaData;

    public SCADAChannel() {
        this.setPointHigh = Double.POSITIVE_INFINITY;
        this.setPointLow = Double.NEGATIVE_INFINITY;
        this.validRangeHigh = Double.POSITIVE_INFINITY;
        this.validRangeLow = Double.NEGATIVE_INFINITY;
        this.warnedNoStatus = false;
        this.currentStatus = DataStatus.MISSING;
        this.almAbnormal = Integer.MAX_VALUE;
        this.copyMissing = false;
        this.metaData = new HashMap();
        this.requires = new ArrayList();
        this.linkedChannels = new ArrayList();
        this.dataFrameSize = 100;
        this.metaData.put("precision", 0.0001);
    }

    @Override
    public void addNewValue(Object value, Step step) {
        double val = ((Number) value).doubleValue();
        int idx = step.getIndex();
        try {
            this.dataValues.set(idx, val);
        } catch (DataOutOfFrameException ex) {
            LOG.error(this.name + ": out of frame exception, "
                    + "please set or increase the frameSize option.", ex);
        }
        this.currentIndex = max(this.dataValues.getFrameEnd(), idx);
        double currentValue = Double.NaN;
        try {
            currentValue = this.dataValues.get(currentIndex);
        } catch (DataOutOfFrameException ex) {
            currentStatus = DataStatus.INVALID;
        }
        if (currentValue > this.validRangeHigh
                || currentValue < this.validRangeLow) {
            currentStatus = DataStatus.OUT_OF_VALID_RANGE;
        } else if (currentValue > this.setPointHigh
                || currentValue < this.setPointLow) {
            currentStatus = DataStatus.OUT_OF_CTL_LIMIT;
        } else if (Double.isNaN(currentValue)) {
            currentStatus = DataStatus.MISSING;
        } else if (Double.isInfinite(currentValue)) {
            currentStatus = DataStatus.INVALID;
        } else if (this.usage == ChannelUsage.CHANNEL_ALARM) {
            if (((Number) value).intValue() == this.almAbnormal) {
                this.currentStatus = DataStatus.FLAGGED_BAD_QUALITY;
            } else {
                this.currentStatus = DataStatus.NORMAL;
            }

        } else {
            currentStatus = DataStatus.NORMAL;
        }
    }

    @Override
    public void addRequires(String tag) {
        if (this.requires.contains(tag)) {
            return;
        }
        this.requires.add(tag);
    }

    @Override
    public void configure(Descriptor desc) {
        this.name = desc.getName();
        this.tag = desc.getTag();
        this.options = desc.getOptions();
        for (Descriptor req : desc.getRequiresComponents()) {
            this.addRequires(req.getTag());
        }
        for (Iterator it = options.keySet().iterator(); it.hasNext();) {
            String key = (String) it.next();
            Object val = options.get(key);
            if (val == null) {
                LOG.error("No value was provided for SCADAChannel option '"+key+"'");
                this.metaData.put(key, null);
                continue;
            }
            switch (key) {
                case "name":
                case "tag":
                case "type":
                case "className":
                    break;
                case "parameter":
                case "description":
                case "usage":
                case "units":
                    this.metaData.put(key, val.toString());
                    break;
                case "setPointHigh":
                case "setPointLow":
                case "validRangeHigh":
                case "validRangeLow":
                case "precision":
                    this.metaData.put(key, ((Number)val).doubleValue());
                    break;
                case "usageType":
                case "usage type":
                    if (val instanceof String) {
                        this.usage = ChannelUsage.valueOf((String) val);
                    } else if (val instanceof ChannelUsage) {
                        this.usage = (ChannelUsage) val;
                    }
                    this.metaData.put("usageType", this.usage);
                    break;
                case "set points":
                    if (val instanceof Object[]) {
                        this.metaData.put("setPointLow", ((Object[]) val)[0]);
                        this.metaData.put("setPointHigh", ((Object[]) val)[1]);
                    } else if (val instanceof ArrayList) {
                        this.metaData.put("setPointLow", ((ArrayList) val).get(0));
                        this.metaData.put("setPointHigh", ((ArrayList) val).get(1));
                    }
                    break;
                case "valid range":
                    if (val instanceof Object[]) {
                        this.metaData.put("validRangeLow", ((Object[]) val)[0]);
                        this.metaData.put("validRangeHigh", ((Object[]) val)[1]);
                    } else if (val instanceof ArrayList) {
                        this.metaData.put("validRangeLow",  ((ArrayList) val).get(0));
                        this.metaData.put("validRangeHigh", ((ArrayList) val).get(1));
                    }
                    break;
                case "frameSize":
                    this.dataFrameSize = (int) ((Number) options.get(key)).intValue();
                    break;
                case "newDataStyle":
                    this.setNewDataStyle((MissingDataPolicy) options.get(key));
                    break;
                case "value when active":
                case "valueForAbnormalStatus":
                    this.almAbnormal = (int) ((Number) val).intValue();
                    break;
                default:
                    this.metaData.put(key, val);
                    LOG.warn(
                            this.name + ": unknown option (" + key + " = " + options.get(
                                    key).toString() + "})");
                    break;
            }
        }
        if (this.usage == null) {
            if (this.getOpt("usage") != null) {
                if (this.getOpt("usage") instanceof String) {
                    String myUsage = (String) this.getOpt("usage");
                    switch (myUsage.toLowerCase()) {
                        case "wq":
                        case "quality":
                        case "water quality":
                            this.usage = ChannelUsage.QUALITY;
                            break;
                        case "op":
                        case "ops":
                        case "operations":
                        case "operational":
                            this.usage = ChannelUsage.OPERATIONS;
                            break;
                        case "alm":
                        case "alarm":
                        case "channel_alarm":
                            this.usage = ChannelUsage.CHANNEL_ALARM;
                            break;
                        case "cal":
                        case "calibrations":
                        case "station_calib":
                        case "station_alarm":
                            this.usage = ChannelUsage.STATION_CALIB;
                            break;
                        case "info":
                        case "information":
                        case "informational":
                        case "ignore":
                            this.usage = ChannelUsage.INFORMATION;
                            break;
                        case "composite":
                        case "composite step":
                        case "composite_nq":
                            this.usage = ChannelUsage.COMPOSITE_NQ;
                            break;
                        default:
                            this.usage = ChannelUsage.INFORMATION;
                            LOG.warn(
                                    "Unknown channel usage type: " + myUsage + "; setting to INFORMATION and continuing.");
                            break;
                    }
                }
                this.setOpt("usageType", this.usage);
            } else {
                this.usage = ChannelUsage.QUALITY;
                LOG.warn("Channel type not specified; setting to QUALITY and continuing.");
                this.setOpt("usageType", ChannelUsage.QUALITY);
            }
        }
    }

    @Override
    public void initialize() {
        LOG.debug(
                "Initializing channel " + this.name + " / " + this.tag + " / " + this.usage);
        this.dataValues = new LazyModulusArray(this.dataFrameSize);
        this.dataValues.setCopyMissing(this.copyMissing);
        if (this.metaData.containsKey("setPointLow")) {
            this.setPointLow = this.getDoubleOpt("setPointLow");
        }
        if (this.metaData.containsKey("setPointHigh")) {
            this.setPointHigh = this.getDoubleOpt("setPointHigh");
        }
        if (this.metaData.containsKey("validRangeLow")) {
            this.validRangeLow = this.getDoubleOpt("validRangeLow");
        }
        if (this.metaData.containsKey("validRangeHigh")) {
            this.validRangeHigh = this.getDoubleOpt("validRangeHigh");
        }
        if ((setPointLow >= setPointHigh) || (validRangeLow >= validRangeHigh) ) {
            LOG.fatal("Channel "+this.name+" / "+ this.tag + " has mismatched setPoint or validRange values (low > high)");
        }
    }

    @Override
    public String getClassName() {
        return "SimpleChannel";
    }

    @Override
    public Descriptor getConfiguration() {
        HashMap config = new HashMap();
        config.put("tag", this.getTag());
        config.put("className", this.getClassName());
        if (this.getStringOpt("parameter") != null) {
            config.put("parameter", this.getStringOpt("parameter"));
        }
        if (this.getStringOpt("description") != null) {
            config.put("description", this.getStringOpt("description"));
        }
        for (Iterator it = options.keySet().iterator(); it.hasNext();) {
            String key = (String) it.next();
            config.put(key, options.get(key).toString());
        }
        return null;
        //        return config;
    }

    @Override
    public double getDoubleValue(int index) {
        try {
            return this.dataValues.get(index);
        } catch (DataOutOfFrameException ex) {
            LOG.error(this.name + ": out of frame exception, "
                    + "please set or increase the frameSize option.", ex);
        }
        return Double.NEGATIVE_INFINITY;
    }

    @Override
    public int getIntegerValue(int index) {
        try {
            return (int) this.dataValues.get(index);
        } catch (DataOutOfFrameException ex) {
            LOG.error(this.name + ": out of frame exception, "
                    + "please set or increase the frameSize option.", ex);
        }
        return Integer.MIN_VALUE;
    }

    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Sets the MissingDataPolicy for this channel.
     *
     * @param style the new value of style
     */
    @Override
    public void setNewDataStyle(MissingDataPolicy style) {
        switch (style) {
            case TYPICAL:
                this.dataValues.setCopyMissing(false);
                break;
            case CHANGES:
                this.dataValues.setCopyMissing(true);
                break;
            default:
                this.dataValues.setCopyMissing(false);
                break;
        }
        this.options.put("newDataStyle", style.toString());
    }

    @Override
    public ArrayList<String> getRequires() {
        return this.requires;
    }

    @Override
    public void setRequires(ArrayList<String> requires) {
        this.requires.clear();
        this.requires.addAll(requires);
    }

    @Override
    public DataStatus getStatus() {
        for (DataChannel chan : this.linkedChannels) {
            if (chan.getStatus() != DataStatus.NORMAL) {
                return DataStatus.FLAGGED_BAD_QUALITY;
            }
        }
        return this.currentStatus;
    }

    @Override
    public String getStringValue(int index) {
        try {
            return new Double(this.dataValues.get(index)).toString();
        } catch (DataOutOfFrameException ex) {
            LOG.error(this.name + ": out of frame exception, "
                    + "please set or increase the frameSize option.", ex);
        }
        return null;
    }

    @Override
    public String getTag() {
        return this.tag;
    }

    @Override
    public void setTag(String tag) {
        this.tag = tag;
    }

    @Override
    public ChannelType getType() {
        return ChannelType.VALUE;
    }

    @Override
    public Object getValue(int index) {
        try {
            return this.dataValues.get(index);
        } catch (DataOutOfFrameException ex) {
            LOG.error(this.name + ": out of frame exception,"
                    + " please set or increase the frameSize option.", ex);
        }
        return null;
    }

    @Override
    public void removeRequires(String tag) {
        this.requires.remove(tag);
    }

    @Override
    public void linkChannel(DataChannel chan) {
        if (this.linkedChannels.add(chan)) {
            LOG.debug("Linked channels: " + this.name + " <-- " + chan.getName());
        } else {
            LOG.warn(
                    "FAILED to link channels: " + this.name + " <-- " + chan.getName());
        }
    }

    @Override
    public void unlinkChannel(DataChannel chan) {
        if (this.linkedChannels.remove(chan)) {
            LOG.debug(
                    "Unlinked channels: " + this.name + " <-- " + chan.getName());
        } else {
            LOG.warn(
                    "FAILED to unlink channels: " + this.name + " <-- " + chan.getName());
        }
    }

    @Override
    public double[] getDoubleArrayOpt(String name) {
        try {
            return (double[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public double getDoubleOpt(String name) {
        return ((Number) metaData.get(name)).doubleValue();
    }

    @Override
    public int[] getIntegerArrayOpt(String name) {
        try {
            return (int[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public int getIntegerOpt(String name) {
        return ((Number) metaData.get(name)).intValue();
    }

    @Override
    public Object getMetaData() {
        return new HashMap(this.metaData);
    }

    @Override
    public void setMetaData(Object metaData) {
        this.metaData.clear();
        this.metaData.putAll((Map) metaData);
    }

    @Override
    public Object getOpt(String name) {
        return metaData.get(name);
    }

    @Override
    public String[] getOptKeys() {
        return (String[]) metaData.keySet().toArray();
    }

    @Override
    public String[] getStringArrayOpt(String name) {
        try {
            return (String[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public String getStringOpt(String name) {
        return (String) metaData.get(name);
    }

    @Override
    public void setDoubleArrayOpt(String name, double[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setDoubleOpt(String name, double val) {
        metaData.put(name, val);
    }

    @Override
    public void setIntegerArrayOpt(String name, int[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setIntegerOpt(String name, int val) {
        metaData.put(name, val);
    }

    @Override
    public void setOpt(String name, Object val) {
        metaData.put(name, val);
    }

    @Override
    public void setStringArrayOpt(String name, String[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setStringOpt(String name, String val) {
        metaData.put(name, val);
    }

}
