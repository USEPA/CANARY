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
package gov.sandia.seme.util;

import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Controller;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Engine;
import gov.sandia.seme.framework.MissingDataPolicy;
import gov.sandia.seme.framework.Step;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import org.apache.log4j.Logger;

/**
 * An abstract controller that handles some of the basic configuration work.
 * This class is designed to provide some of the basic configuration options and
 * to provide a template for designing a custom controller.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public abstract class ControllerImpl implements Controller {

    private static final Logger LOG = Logger.getLogger(
            ControllerImpl.class.getName());

    /**
     * Contains configuration and metadata.
     */
    protected final HashMap<String, Object> metaData = new HashMap();

    /**
     * A link to the Engine this object controls.
     */
    protected Engine engine = null;

    /**
     * The name of the controller.
     */
    protected String name = null;

    /**
     * The base data style for new data received from inputs.
     */
    protected MissingDataPolicy dataStyle;

    /**
     * Is this controller based on the system clock.
     */
    protected boolean dynamic;

    /**
     * Is this controller currently paused.
     */
    protected volatile boolean paused;

    /**
     * The rate (in milliseconds) between steps for real-time processing.
     */
    protected long pollRate;

    /**
     * Is this controller currently running.
     */
    protected volatile boolean running;

    /**
     * A delay (in milliseconds) to use when paused.
     */
    protected int pauseDelay;

    /**
     * A minimum delay (in milliseconds) to use between step processing.
     */
    protected int delay;

    /**
     * A Step object representing the bin size.
     */
    protected Step stepBase;

    /**
     * A Step object representing the first bin to process.
     */
    protected Step stepStart;

    /**
     * A Step object representing the last bin to process.
     */
    protected Step stepStop;

    public ControllerImpl() {
    }

    @Override
    public void configure(Descriptor desc) throws ConfigurationException {
        /*
         * ControllerImpl stepType: Date stepDynamic: true stepStart: null
         * stepStop: null globalStepFormat: yyyy-mm-dd HH:MM:SS stepSize: null
         * globalDataStyle: null pollRate: 00:20
         */
        this.name = desc.getName();
        HashMap config = desc.getOptions();
        Object temp;
        temp = config.get("globalDataStyle");
        String dStyle = (String) temp;
        if (dStyle == null) {
            dStyle = "null";
        }
        switch (dStyle.toLowerCase()) {
            case "channel":
            case "channel based":
                this.dataStyle = MissingDataPolicy.CHANNEL;
                break;
            case "new":
            case "changes":
                this.dataStyle = MissingDataPolicy.CHANGES;
                break;
            case "every":
            case "all":
                this.dataStyle = MissingDataPolicy.TYPICAL;
                break;
            default:
                this.dataStyle = MissingDataPolicy.TYPICAL;
                break;
        }
        temp = config.get("stepDynamic");
        if (temp != null) {
            dynamic = (boolean) temp;
        }
        temp = config.get("stepType");
        if (temp == null) {
            temp = "date";
            LOG.warn("No stepType key specified in controller "
                    + "configuration, using default of 'date'.");
        }
        String stepType = (String) temp;
        String format = (String) config.get("globalStepFormat");
        switch (stepType.toLowerCase()) {
            case "date":
            case "date time":
            case "date/time":
            case "time":
                SimpleDateFormat tf = new SimpleDateFormat("H:m:s");
                SimpleDateFormat df = new SimpleDateFormat(format);
                Date size = new Date(0);
                Date start = new Date(0);
                Date stop = new Date(0);
                if (this.dynamic) {
                    start = new Date(System.currentTimeMillis());
                    stop = null;
                }
                temp = config.get("stepSize");
                if (temp instanceof Integer) {
                    size = new Date(new Long((long) temp));
                } else if (temp instanceof Date) {
                    size = (Date) temp;
                } else if (temp != null) {
                    try {
                        size = tf.parse((String) temp);
                        Date zero = tf.parse("0:0:0");
                        long diff = size.getTime() - zero.getTime();
                        Date tSize = new Date(diff);
                        size = tSize;
                    } catch (ParseException ex) {
                        LOG.fatal("You did not use the ''H:m:s'' "
                                + "format for your step interval, or your time "
                                + "step is misformed: ''" + temp + "''");
                        throw new ConfigurationException(
                                "Badly formed step size: '"
                                + temp + "'. Must be in 'H:m:s' format"
                                + " for Date/Time steps");
                    }
                }
                temp = config.get("stepStart");
                if (temp instanceof Integer) {
                    start = new Date((Long) temp);
                } else if (temp instanceof Date) {
                    start = (Date) temp;
                } else if (temp != null) {
                    try {
                        start = df.parse((String) temp);
                    } catch (ParseException ex) {
                        LOG.fatal("Your format does not match your "
                                + "date/time string!", ex);
                    }
                }
                temp = config.get("stepFinal");
                if (temp instanceof Integer) {
                    stop = new Date((Long) temp);
                } else if (temp instanceof Date) {
                    stop = (Date) temp;
                } else if (temp != null) {
                    try {
                        stop = df.parse((String) temp);
                    } catch (ParseException ex) {
                        LOG.error("Your format does not match your "
                                + "date/time string!", ex);
                    }
                }
                this.stepStart = new DateTimeStep(start, size, start, format);
                this.stepBase = new DateTimeStep(start, size, null, format);
                this.stepStop = new DateTimeStep(start, size, stop, format);
                break;
            case "number":
            case "double":
            case "float":
            case "real":
                Double dStart;
                Double dStop;
                Double dSize;
                if (format == null) {
                    format = "#.0#";
                }
                dStart = (Double) config.get("stepStart");
                dSize = (Double) config.get("stepSize");
                dStop = (Double) config.get("stepFinal");
                this.stepBase = new DoubleStep(dStart, dSize, null, format);
                this.stepStart = new DoubleStep(dStart, dSize, dStart, format);
                this.stepStop = new DoubleStep(dStart, dSize, dStop, format);
                break;
            case "steps":
            case "count":
            case "integer":
            case "int":
                Long iStart;
                Long iStop;
                Long iSize;
                if (format == null) {
                    format = "#";
                }
                iStart = (Long) config.get("stepStart");
                iSize = (Long) config.get("stepSize");
                iStop = (Long) config.get("stepFinal");
                this.stepBase = new IntegerStep(iStart.intValue(), iSize.intValue(), null, format);
                this.stepStart = new IntegerStep(iStart.intValue(), iSize.intValue(), iStart.intValue(), format);
                this.stepStop = new IntegerStep(iStart.intValue(), iSize.intValue(), iStop.intValue(), format);
                break;
            default:
                throw new ConfigurationException("Unknown stepType entry: '"
                        + stepType + "'");
        }
        temp = config.get("pollRate");
        SimpleDateFormat prf = new SimpleDateFormat("H:m:s");
        if (temp instanceof Number) {
            this.pollRate = ((Number) temp).longValue();
        } else {
            try {
                Date zero = prf.parse("0:0:0");
                Date rate = prf.parse((String) temp);
                long pRate = rate.getTime() - zero.getTime();
                this.pollRate = pRate;
            } catch (ParseException ex) {
                LOG.fatal(null, ex);
            }
        }
        HashMap options = desc.getOptions();
        if (options != null) {
            for (Object key : options.keySet()) {
                this.setOpt((String) key, options.get(key));
            }
        }
    }

    @Override
    public void setEngine(Engine engine) {
        this.engine = engine;
    }

    @Override
    public MissingDataPolicy getDataStyle() {
        return this.dataStyle;
    }

    @Override
    public void setDataStyle(MissingDataPolicy style) {
        this.dataStyle = style;
    }

    @Override
    public long getPollRate() {
        return this.pollRate;
    }

    @Override
    public void setPollRate(long rate) {
        this.pollRate = rate;
    }

    @Override
    public Step getStepBase() {
        return stepBase;
    }

    @Override
    public void setStepBase(Step step) {
        stepBase = step;
    }

    @Override
    public Step getStepStart() {
        return stepStart;
    }

    @Override
    public void setStepStart(Step step) {
        stepStart = step;
    }

    @Override
    public Step getStepStop() {
        return stepStop;
    }

    @Override
    public void setStepStop(Step step) {
        stepStop = step;
    }

    @Override
    public boolean isDynamic() {
        return dynamic;
    }

    @Override
    public void setDynamic(boolean dynamic) {
        this.dynamic = dynamic;
    }

    @Override
    public boolean isPaused() {
        return paused;
    }

    @Override
    public void setPaused(boolean paused) {
        this.paused = paused;
    }

    @Override
    public boolean isRunning() {
        return running;
    }

    @Override
    public void setRunning(boolean running) {
        this.running = running;
    }

    @Override
    public void pauseExecution() {
        paused = true;
    }

    @Override
    public void resumeExecution() {
        paused = false;
    }

    @Override
    public void stopExecution() {
        running = false;
    }

    @Override
    public void setName(String n) {
        this.name = n;
    }

    @Override
    public String getName() {
        return this.name;
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
