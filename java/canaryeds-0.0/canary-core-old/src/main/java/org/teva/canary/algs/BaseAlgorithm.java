/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.teva.canary.algs;

import java.io.IOException;
import java.io.StringReader;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.teva.canary.lib.Algorithm;
import org.teva.canary.lib.RegisterEnum;
import org.teva.canary.lib.RulesEnum;
import org.teva.canary.lib.StatusEnum;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 *
 * @author dbhart
 */
public abstract class BaseAlgorithm implements Algorithm {

    /**
     *
     */
    public BaseAlgorithm() {
        this.detection_status = StatusEnum.UNINITIALIZED;
        this.threshold = Double.NaN;
        this.tau_prob = Double.NaN;
        this.data_rule = RulesEnum.LINK_USE_RAW;
        this.on_event = RulesEnum.ON_EVENT_KEEP_NANS;
        this.on_missing = RulesEnum.ON_MISSING_KEEP_CURRENT;
        this.on_normal = RulesEnum.ON_NORMAL_KEEP_CURRENT;
        this.on_outlier = RulesEnum.ON_OUTLIER_KEEP_NANS;
        this.on_nodata = RulesEnum.ON_NODATA_KEEP_NANS;
        this.on_calib = RulesEnum.ON_CALIB_KEEP_CURRENT;
        this.on_match = RulesEnum.ON_MATCH_KEEP_CURRENT;
        this.data_register_usage = new boolean[RegisterEnum.values().length];
        for (int i = 0; i < this.data_register_usage.length; i++) {
            this.data_register_usage[i] = true;
        }
    }
    protected int history_window_size;
    protected int num_signals;
    protected double[] data_lim_high;
    protected double[] data_lim_low;
    protected double[] setpt_lim_high;
    protected double[] setpt_lim_low;
    protected boolean[] clusterizable;
    protected boolean[] auto_ignore_signals;
    protected double[] sigma_lim;
    protected boolean[] usable_signals;
    protected int[] contributing_parameters;
    protected double[][] history_window;
    protected StatusEnum detection_status;
    protected double[] tau_out;
    protected double tau_prob;
    protected double threshold;
    protected double[] data;
    protected double[] predictions;
    protected double[] residuals;
    protected double probability;
    protected double probability2;
    protected RulesEnum on_normal;
    protected RulesEnum on_event;
    protected RulesEnum on_outlier;
    protected RulesEnum on_missing;
    protected RulesEnum on_nodata;
    protected RulesEnum on_calib;
    protected RulesEnum on_match;
    protected RulesEnum data_rule;
    protected double[] cur_sum;
    protected int[] cur_count;
    protected double[] cur_sigma;
    protected String cur_message;
    protected boolean[] data_register_usage;
    protected boolean inCalibration;

    private void set_uses_register(RegisterEnum register, boolean value) {
        this.data_register_usage[register.ordinal()] = value;
    }

    private void set_uses_register(String register, boolean value) {
        this.data_register_usage[RegisterEnum.valueOf(register).ordinal()] = value;
    }

    public boolean uses_register(RegisterEnum register) {
        return this.data_register_usage[register.ordinal()];
    }

    public boolean uses_register(String register) {
        return this.data_register_usage[RegisterEnum.valueOf(register).ordinal()];
    }

    public void configure(String XMLString) {
        try {
            DocumentBuilderFactory factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            StringReader reader = new java.io.StringReader(XMLString);
            InputSource source = new org.xml.sax.InputSource(reader);
            Document doc = builder.parse(source);
            this.configure(doc.getDocumentElement());
        } catch (SAXException ex) {
            Logger.getLogger(BaseAlgorithm.class.getName()).log(Level.SEVERE, null, ex);
        } catch (IOException ex) {
            Logger.getLogger(BaseAlgorithm.class.getName()).log(Level.SEVERE, null, ex);
        } catch (ParserConfigurationException ex) {
            Logger.getLogger(BaseAlgorithm.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    public void configure(Object DOMObject) {
        Element Node = (Element) DOMObject;
        String temp = Node.getElementsByTagName("history-window").item(0).getTextContent();
        this.history_window_size = Integer.parseInt(temp);
        temp = Node.getElementsByTagName("outlier-threshold").item(0).getTextContent();
        this.threshold = Double.parseDouble(temp);
        temp = Node.getElementsByTagName("event-threshold").item(0).getTextContent();
        this.tau_prob = Double.parseDouble(temp);
        NodeList list = Node.getElementsByTagName("rule-option");
        int nEng = list.getLength();
        for (int i = 0; i < nEng; i++) {
            temp = list.item(i).getTextContent();
            RulesEnum rule = null;
            try {
                rule = RulesEnum.valueOf(temp);
                switch (rule) {
                    case LINK_USE_RAW:
                    case LINK_USE_RESIDUALS:
                    case LINK_USE_PREDICTIONS:
                    case LINK_USE_CONTRIBUTING:
                        this.data_rule = rule;
                        break;

                    case REG_OUTPUTS_ON:
                        this.set_uses_register(RegisterEnum.CURRENT_RESIDUALS, true);
                        this.set_uses_register(RegisterEnum.CURRENT_PREDICTIONS, true);
                        this.set_uses_register(RegisterEnum.CURRENT_CONTRIBUTORS, true);
                        break;
                    case REG_OUTPUTS_OFF:
                        this.set_uses_register(RegisterEnum.CURRENT_RESIDUALS, false);
                        this.set_uses_register(RegisterEnum.CURRENT_PREDICTIONS, false);
                        this.set_uses_register(RegisterEnum.CURRENT_CONTRIBUTORS, false);
                        break;
                    case REG_CURRENT_RESIDUALS_ON:
                        this.set_uses_register(RegisterEnum.CURRENT_RESIDUALS, true);
                        break;
                    case REG_CURRENT_RESIDUALS_OFF:
                        this.set_uses_register(RegisterEnum.CURRENT_RESIDUALS, false);
                        break;
                    case REG_CURRENT_PREDICTIONS_ON:
                        this.set_uses_register(RegisterEnum.CURRENT_PREDICTIONS, true);
                        break;
                    case REG_CURRENT_PREDICTIONS_OFF:
                        this.set_uses_register(RegisterEnum.CURRENT_PREDICTIONS, false);
                        break;
                    case REG_CURRENT_CONTRIBUTORS_ON:
                        this.set_uses_register(RegisterEnum.CURRENT_CONTRIBUTORS, true);
                        break;
                    case REG_CURRENT_CONTRIBUTORS_OFF:
                        this.set_uses_register(RegisterEnum.CURRENT_CONTRIBUTORS, false);
                        break;

                    case REG_DELTA_MIN_ON:
                        this.set_uses_register(RegisterEnum.DELTA_MIN, false);
                    case REG_DELTA_MIN_OFF:
                        this.set_uses_register(RegisterEnum.DELTA_MIN, true);
                    case REG_CURRENT_USEABLE_ON:
                        this.set_uses_register(RegisterEnum.CURRENT_USEABLE, true);
                    case REG_CURRENT_USEABLE_OFF:
                        this.set_uses_register(RegisterEnum.CURRENT_USEABLE, false);

                    case ON_NORMAL_KEEP_CURRENT:
                    case ON_NORMAL_KEEP_PREDICT:
                    case ON_NORMAL_KEEP_NANS:
                    case ON_NORMAL_KEEP_LAST:
                    case ON_NORMAL_KEEP_ZEROS:
                        this.on_normal = rule;
                        break;

                    case ON_OUTLIER_KEEP_CURRENT:
                    case ON_OUTLIER_KEEP_PREDICT:
                    case ON_OUTLIER_KEEP_NANS:
                    case ON_OUTLIER_KEEP_LAST:
                    case ON_OUTLIER_KEEP_ZEROS:
                        this.on_outlier = rule;
                        break;

                    case ON_EVENT_KEEP_CURRENT:
                    case ON_EVENT_KEEP_PREDICT:
                    case ON_EVENT_KEEP_NANS:
                    case ON_EVENT_KEEP_LAST:
                    case ON_EVENT_KEEP_ZEROS:
                        this.on_event = rule;
                        break;

                    case ON_MISSING_KEEP_CURRENT:
                    case ON_MISSING_KEEP_PREDICT:
                    case ON_MISSING_KEEP_NANS:
                    case ON_MISSING_KEEP_LAST:
                    case ON_MISSING_KEEP_ZEROS:
                        this.on_missing = rule;
                        break;

                    default:
                        System.out.println("Unknown or unhandled rule-option: " + rule);
                        break;
                }
            } catch (IllegalArgumentException ex) {
                Logger.getLogger(BaseAlgorithm.class.getName()).log(Level.WARNING, null, ex);
            }
        }
        list = Node.getElementsByTagName("parameter");
        int nPar = list.getLength();
        for (int i = 0; i < nPar; i++) {
            Element par = (Element) list.item(i);
            this.set_config_parameter(par.getAttribute("name"), par.getTextContent());
        }
    }

    public void set_data_register(String register, double[] data) {
        this.set_data_register(RegisterEnum.valueOf(register), data);
    }

    public void set_data_register(String register, int[] data) {
        this.set_data_register(RegisterEnum.valueOf(register), data);
    }

    public void set_data_register(String register, boolean[] data) {
        this.set_data_register(RegisterEnum.valueOf(register), data);
    }

    public double[] get_data_register(String register) {
        return this.get_data_register(RegisterEnum.valueOf(register));
    }

    public int[] get_data_register_int(String register) {
        return this.get_data_register_int(RegisterEnum.valueOf(register));
    }

    public boolean[] get_data_register_bool(String register) {
        return this.get_data_register_bool(RegisterEnum.valueOf(register));
    }

    public double[] get_data_register(RegisterEnum register) {
        if (this.uses_register(register)) {
            double[] values = new double[this.num_signals];
            switch (register) {
                case DATA_LIM_HIGH:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.data_lim_high[i];
                    }
                    break;
                case DATA_LIM_LOW:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.data_lim_low[i];
                    }
                    break;
                case DELTA_MIN:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.sigma_lim[i];
                    }
                    break;
                case SETPOINT_LIM_HIGH:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.setpt_lim_high[i];
                    }
                    break;
                case SETPOINT_LIM_LOW:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.setpt_lim_low[i];
                    }
                    break;
                default:
                    return null;
            }
            return values;
        } else {
            return null;
        }
    }

    public void set_data_register(RegisterEnum register, double[] data) {
        if (this.uses_register(register)) {
            switch (register) {
                case DATA_LIM_HIGH:
                    for (int i = 0; i < data.length; i++) {
                        this.data_lim_high[i] = data[i];
                    }
                    break;
                case DATA_LIM_LOW:
                    for (int i = 0; i < data.length; i++) {
                        this.data_lim_low[i] = data[i];
                    }
                    break;
                case DELTA_MIN:
                    for (int i = 0; i < data.length; i++) {
                        this.sigma_lim[i] = data[i];
                    }
                    break;
                case SETPOINT_LIM_HIGH:
                    for (int i = 0; i < data.length; i++) {
                        this.setpt_lim_high[i] = data[i];
                    }
                    break;
                case SETPOINT_LIM_LOW:
                    for (int i = 0; i < data.length; i++) {
                        this.setpt_lim_low[i] = data[i];
                    }
                    break;
                default:
            }
        }
    }

    public boolean[] get_data_register_bool(RegisterEnum register) {
        if (this.uses_register(register)) {
            boolean[] values = new boolean[this.num_signals];
            switch (register) {
                case AUTO_IGNORE:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.auto_ignore_signals[i];
                    }
                    break;
                case CLUSTERIZABLE:
                    for (int i = 0; i < values.length; i++) {
                        values[i] = this.clusterizable[i];
                    }
                    break;
                default:
                    return null;
            }
            return values;
        } else {
            return null;
        }
    }

    public int[] get_data_register_int(RegisterEnum register) {
        if (this.uses_register(register)) {
            //int[] values = new int[this.num_signals];
            switch (register) {
                default:
                    return null;
            }
            //return values;
        } else {
            return null;
        }
    }

    public void set_data_register(RegisterEnum register, boolean[] data) {
        if (this.uses_register(register)) {
            switch (register) {
                case AUTO_IGNORE:
                    for (int i = 0; i < data.length; i++) {
                        this.auto_ignore_signals[i] = data[i];
                    }
                    break;
                case CLUSTERIZABLE:
                    for (int i = 0; i < data.length; i++) {
                        this.clusterizable[i] = data[i];
                    }
                    break;
                default:
            }
        }
    }

    public void set_data_register(RegisterEnum register, int[] data) {
        if (this.uses_register(register)) {
            switch (register) {
                default:
            }
        }
    }

    /**
     * Normalize a history window according to each signal's mean and standard
     * deviation. 
     * @return the data normalized for each signal by mean and standard deviation
     */
    public double[][] normalize_window() {
        double[][] norm_window = new double[this.history_window_size][this.num_signals];
        double sigma = 0.0;
        double mean = 0.0;
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            double sum2 = 0;
            double val = 0.0;
            mean = this.cur_sum[iCol] / this.cur_count[iCol];
            for (int jRow = 0; jRow < this.history_window_size; jRow++) {
                val = this.history_window[jRow][iCol];
                if (!Double.isInfinite(val) && !Double.isNaN(val)) {
                    sum2 = sum2 + (val - mean) * (val - mean);
                }
            }
            sigma = Math.sqrt(sum2 / (this.cur_count[iCol] - 1));
            if (sigma < this.sigma_lim[iCol]) {
                sigma = this.sigma_lim[iCol] + Double.MIN_VALUE;
            }
            this.cur_sigma[iCol] = sigma;
            for (int jRow = 0; jRow < this.history_window_size; jRow++) {
                val = this.history_window[jRow][iCol];
                val = (val - mean) / sigma;
                norm_window[jRow][iCol] = val;
            }
        }
        return norm_window;
    }

    public void initialize(int n_Sig) {
        this.num_signals = n_Sig;
        this.auto_ignore_signals = new boolean[n_Sig];
        this.usable_signals = new boolean[n_Sig];
        this.history_window = new double[this.history_window_size][n_Sig];
        this.tau_out = new double[n_Sig];
        this.data = new double[n_Sig];
        this.inCalibration = false;
        this.predictions = new double[n_Sig];
        this.residuals = new double[n_Sig];
        this.sigma_lim = new double[n_Sig];
        this.data_lim_high = new double[n_Sig];
        this.data_lim_low = new double[n_Sig];
        this.clusterizable = new boolean[n_Sig];
        this.setpt_lim_high = new double[n_Sig];
        this.setpt_lim_low = new double[n_Sig];
        this.cur_count = new int[n_Sig];
        this.cur_sum = new double[n_Sig];
        this.cur_sigma = new double[n_Sig];
        this.contributing_parameters = new int[n_Sig];
        for (int iCol = 0; iCol < n_Sig; iCol++) {
            for (int jRow = 0; jRow < this.history_window_size; jRow++) {
                this.history_window[jRow][iCol] = Double.NaN;
            }
            this.auto_ignore_signals[iCol] = false;
            this.usable_signals[iCol] = true;
            this.contributing_parameters[iCol] = 0;
            this.tau_out[iCol] = this.threshold;
            this.data[iCol] = Double.NaN;
            this.predictions[iCol] = Double.NaN;
            this.residuals[iCol] = Double.NaN;
            this.sigma_lim[iCol] = 0.0;
            this.cur_sigma[iCol] = 0.0;
            this.cur_count[iCol] = 0;
            this.cur_sum[iCol] = 0;
            this.clusterizable[iCol] = true;
            this.data_lim_high[iCol] = Double.POSITIVE_INFINITY;
            this.setpt_lim_high[iCol] = Double.POSITIVE_INFINITY;
            this.data_lim_low[iCol] = Double.NEGATIVE_INFINITY;
            this.setpt_lim_low[iCol] = Double.NEGATIVE_INFINITY;
        }
        this.detection_status = StatusEnum.MISSINGHIST;
    }

    public void keep_by_rule() {
        switch (this.detection_status) {
            case UNINITIALIZED:
                break;
            case MISSINGHIST:
                switch (this.on_missing) {
                    case ON_MISSING_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_MISSING_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_MISSING_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_MISSING_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_MISSING_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case NORMAL:
                switch (this.on_normal) {
                    case ON_NORMAL_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_NORMAL_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_NORMAL_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_NORMAL_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_NORMAL_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case OUTLIER:
                switch (this.on_outlier) {
                    case ON_OUTLIER_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_OUTLIER_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_OUTLIER_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_OUTLIER_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_OUTLIER_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case EVENT:
                switch (this.on_event) {
                    case ON_EVENT_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_EVENT_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_EVENT_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_EVENT_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_EVENT_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case NODATA:
                switch (this.on_nodata) {
                    case ON_NODATA_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_NODATA_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_NODATA_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_NODATA_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_NODATA_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case CALIBRATION:
                switch (this.on_nodata) {
                    case ON_CALIB_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_CALIB_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_CALIB_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_CALIB_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_CALIB_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            case MATCH:
                switch (this.on_match) {
                    case ON_MATCH_KEEP_CURRENT:
                        this.keep_current();
                        break;
                    case ON_MATCH_KEEP_PREDICT:
                        this.keep_predicted();
                        break;
                    case ON_MATCH_KEEP_NANS:
                        this.keep_nans();
                        break;
                    case ON_MATCH_KEEP_LAST:
                        this.keep_last();
                        break;
                    case ON_MATCH_KEEP_ZEROS:
                        this.keep_zeros();
                        break;
                }
                break;
            default:
                throw new UnsupportedOperationException("Unknown Status: " + this.detection_status + ".");
        }
    }

    public void set_num_signals(int n_Sig) {
        this.num_signals = n_Sig;
    }

    public int get_num_signals() {
        return this.num_signals;
    }

    public void set_history_window_size(int n_Hist) {
        this.history_window_size = n_Hist;
    }

    public int get_history_window_size() {
        return this.history_window_size;
    }

    public void set_outlier_threshold(double tau_out) {
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            this.tau_out[iCol] = tau_out;
        }
    }

    public double get_outlier_threshold() {
        return this.tau_out[0];
    }

    public void set_probability_threshold(double tau_prob) {
        this.tau_prob = tau_prob;
    }

    public double get_probability_threshold() {
        return this.tau_prob;
    }

    public void set_data_rule(RulesEnum ruleID) {
        this.data_rule = ruleID;
    }

    public RulesEnum get_data_rule() {
        return this.data_rule;
    }

    protected void shift_window() {
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            double val = this.history_window[0][iCol];
            if (!Double.isNaN(val) && !Double.isInfinite(val)) {
                this.cur_sum[iCol] = this.cur_sum[iCol] - val;
                this.cur_count[iCol] = this.cur_count[iCol] - 1;
            }
        }
        for (int jRow = 1; jRow < this.history_window_size; jRow++) {
            for (int iCol = 0; iCol < this.num_signals; iCol++) {
                this.history_window[jRow - 1][iCol] = this.history_window[jRow][iCol];
            }
        }
    }

    public void keep_current() {
        double val;
        this.shift_window();
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            val = this.data[iCol];
            if (!this.usable_signals[iCol]) {
                val = Double.NaN;
            }
            this.history_window[this.history_window_size - 1][iCol] = val;
            if (!Double.isNaN(val) && !Double.isInfinite(val)) {
                this.cur_sum[iCol] = this.cur_sum[iCol] + val;
                this.cur_count[iCol] = this.cur_count[iCol] + 1;
            }
        }
    }

    public void keep_predicted() {
        double val;
        this.shift_window();
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            val = this.predictions[iCol];
            this.history_window[this.history_window_size - 1][iCol] = val;
            if (!Double.isNaN(val) && !Double.isInfinite(val)) {
                this.cur_sum[iCol] = this.cur_sum[iCol] + val;
                this.cur_count[iCol] = this.cur_count[iCol] + 1;
            }
        }
    }

    public void keep_last() {
        /*double val;
        this.shift_window();
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
        val = this.history_window[this.history_window_size-1][iCol];
        if (!Double.isNaN(val) && !Double.isInfinite(val)) {
        this.cur_sum[iCol] = this.cur_sum[iCol] + val;
        this.cur_count[iCol] = this.cur_count[iCol] + 1;
        }
        }*/
    }

    public void keep_nans() {
        double val;
        this.shift_window();
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            val = Double.NaN;
            this.history_window[this.history_window_size - 1][iCol] = val;
        }
    }

    public void keep_zeros() {
        double val;
        this.shift_window();
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            val = 0;
            this.history_window[this.history_window_size - 1][iCol] = val;
            if (!Double.isNaN(val) && !Double.isInfinite(val)) {
                this.cur_sum[iCol] = this.cur_sum[iCol] + val;
                this.cur_count[iCol] = this.cur_count[iCol] + 1;
            }
        }
    }

    public void set_history_window_data(double[][] window) {
        double val;
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            this.cur_sum[iCol] = 0.0;
            this.cur_count[iCol] = 0;
        }
        for (int jRow = 0; jRow < this.history_window_size; jRow++) {
            for (int iCol = 0; iCol < this.num_signals; iCol++) {
                val = window[jRow][iCol];
                this.history_window[jRow][iCol] = val;
                if (!Double.isNaN(val) && !Double.isInfinite(val)) {
                    this.cur_sum[iCol] = this.cur_sum[iCol] + val;
                    this.cur_count[iCol] = this.cur_count[iCol] + 1;
                }
            }
        }
    }

    public double[][] get_history_window_data() {
        return this.history_window;
    }

    public void set_current_data(double[] data) {
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            this.data[iCol] = data[iCol];
        }
    }

    public void set_current_data(int[] data) {
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            this.data[iCol] = (double) data[iCol];
        }
    }

    public double[] get_current_data() {
        double temp[] = new double[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = (double) this.data[i];
        }
        return temp;
    }

    public void set_current_usable(boolean[] usable) {
        for (int iCol = 0; iCol < this.num_signals; iCol++) {
            this.usable_signals[iCol] = usable[iCol];
        }
    }

    public boolean[] get_current_usable() {
        boolean temp[] = new boolean[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = this.usable_signals[i];
        }
        return temp;
    }

    public double[] get_current_predictions() {
        double temp[] = new double[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = this.predictions[i];
        }
        return temp;
    }

    public double[] get_current_residuals() {
        double temp[] = new double[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = (double) this.residuals[i];
        }
        return temp;
    }

    public double get_current_probability() {
        return this.probability;
    }

    public int[] get_contributing_signals() {
        int temp[] = new int[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = this.contributing_parameters[i];
        }
        return temp;
    }

    public double[] get_d_contributing_signals() {
        double temp[] = new double[this.num_signals];
        for (int i = 0; i < this.num_signals; i++) {
            temp[i] = (double) this.contributing_parameters[i];
        }
        return temp;
    }

    public StatusEnum get_detection_status() {
        return this.detection_status;
    }

    public String get_message() {
        return this.cur_message;
    }

    public void set_calibration_status(boolean inCalib) {
        this.inCalibration = inCalib;
    }
}
