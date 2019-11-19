/*
 * Copyright 2007-2010 Sandia Corporation.
 * This source code is distributed under the LGPL License.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
 * the U.S. Government retains certain rights in this software.
 * This software was written as part of an Inter-Agency Agreement between
 * Sandia National Laboratories and the US EPA NHSRC.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version. This library is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */

package org.teva.canary.algs;

import java.io.IOException;
import java.io.StringReader;
import java.util.Vector;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.teva.canary.lib.RegisterEnum;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.teva.canary.lib.Algorithm;
import org.teva.canary.lib.StatusEnum;
import org.teva.canary.lib.RulesEnum;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 *
 * @author dbhart, Sandia National Laboratories
 */
public class MultiAlgorithmLinker implements Algorithm {

    public void evaluate() {
        int nAlgs = this.algs.size();
        double[] temp = new double[this.current_data.length];
        for (int i = 0; i < this.current_data.length; i++) {
            temp[i] = current_data[i];
        }
        for (int i = 0; i < nAlgs; i++) {
            BaseAlgorithm A = (BaseAlgorithm) this.algs.get(i);
            BaseAlgorithm B;
            if (i < nAlgs - 1) {
                B = (BaseAlgorithm) this.algs.get(i+1);
            } else {
                B = A;
            }
            A.set_current_data(temp);
            A.set_current_usable(this.current_usable);
            A.evaluate();
            switch (B.get_data_rule()) {
                case LINK_USE_RAW:
                    temp = A.get_current_data();
                    break;
                case LINK_USE_PREDICTIONS:
                    temp = A.get_current_predictions();
                    break;
                case LINK_USE_RESIDUALS:
                    temp = A.get_current_residuals();
                    break;
                case LINK_USE_CONTRIBUTING:
                    temp = A.get_d_contributing_signals();
                    break;
            }
            this.probability_of_event = A.get_current_probability();
            this.detection_status = A.get_detection_status();
            if (A.uses_register(RegisterEnum.CURRENT_CONTRIBUTORS)) {
                this.current_contrib = A.get_contributing_signals();
            }
            if (A.uses_register(RegisterEnum.CURRENT_PREDICTIONS)) {
                this.current_pred = A.get_current_predictions();
            }
            if (A.uses_register(RegisterEnum.CURRENT_RESIDUALS)) {
                this.current_resid = A.get_current_residuals();
            }
        }
    }

    public MultiAlgorithmLinker() {
        this.algs = new Vector<Algorithm>();
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
            Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
        } catch (IOException ex) {
            Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
        } catch (ParserConfigurationException ex) {
            Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
        }
    }
    
    public void configure(Object DOMObject) {
        Element Node = (Element) DOMObject;
        NodeList list = Node.getElementsByTagName("edsAlgorithm");
        int nPar = list.getLength();
        for (int i = 0; i < nPar; i++) {
            try {
                Element par = (Element) list.item(i);
                String className = par.getAttribute("type");
                Class c = Class.forName(className);
                Object o = c.newInstance();
                Algorithm A = (Algorithm) o;
                A.configure(par);
                this.add_algorithm(A);
            } catch (InstantiationException ex) {
                Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
            } catch (IllegalAccessException ex) {
                Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
            } catch (ClassNotFoundException ex) {
                Logger.getLogger(MultiAlgorithmLinker.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    public void initialize(int n_Sig) {
        this.sigma_lim = new double[n_Sig];
        this.data_lim_high = new double[n_Sig];
        this.data_lim_low = new double[n_Sig];
        this.clusterizable = new boolean[n_Sig];
        this.setpt_lim_high = new double[n_Sig];
        this.setpt_lim_low = new double[n_Sig];
        this.auto_ignore = new boolean[n_Sig];
        this.inCalibration = false;
        this.current_contrib = new int[n_Sig];
        this.current_data = new double[n_Sig];
        this.current_pred = new double[n_Sig];
        this.current_resid = new double[n_Sig];
        this.current_usable = new boolean[n_Sig];
        for (int iCol = 0; iCol < n_Sig; iCol++) {
            this.clusterizable[iCol] = true;
            this.data_lim_high[iCol] = Double.POSITIVE_INFINITY;
            this.setpt_lim_high[iCol] = Double.POSITIVE_INFINITY;
            this.data_lim_low[iCol] = Double.NEGATIVE_INFINITY;
            this.setpt_lim_low[iCol] = Double.NEGATIVE_INFINITY;
            this.auto_ignore[iCol] = false;
            this.sigma_lim[iCol] = 0.000001;
        }
        for (int i = 0; i < this.algs.size(); i++) {
            Algorithm A = (Algorithm) this.algs.get(i);
            A.initialize(n_Sig);
        }
    }

    public void add_algorithm(Algorithm A) {
        this.algs.add(A);
    }

    public void configure_algorithm(int Index, String XMLString) {
        Algorithm A = (Algorithm) this.algs.get(Index);
        A.configure(XMLString);
    }

    public void configure_algorithm(int Index, Object DOMObject) {
        Algorithm A = (Algorithm) this.algs.get(Index);
        A.configure(DOMObject);
    }

    public void configure_algorithm(int Index, String ParName, String ParValue) {
        Algorithm A = (Algorithm) this.algs.get(Index);
        A.set_config_parameter(ParName, ParValue);
    }

    public void remove_algorithm(int Index) {
        this.algs.remove(Index);
    }

    public void set_current_data(double[] data) {
        this.current_data = new double[data.length];
        for (int i = 0; i < data.length; i++) {
            this.current_data[i] = data[i];
        }
    }

    public void set_current_usable(boolean[] usable) {
        this.current_usable = new boolean[usable.length];
        for (int i = 0; i < usable.length; i++) {
            this.current_usable[i] = usable[i];
        }
    }

    public void set_history_window_data(int Index, double[][] window) {
        Algorithm A = this.algs.get(Index);
        A.set_history_window_data(window);
    }

    public double[][] get_history_window_data(int Index) {
        Algorithm A = this.algs.get(Index);
        return A.get_history_window_data();
    }

    public double get_current_probability() {
        return this.probability_of_event;
    }

    public String get_message() {
        return this.message;
    }

    public StatusEnum get_detection_status() {
        return this.detection_status;
    }

    public double[] get_current_predictions() {
        return this.current_pred;
    }

    public double[] get_current_residuals() {
        return this.current_resid;
    }

    public boolean uses_register(RegisterEnum register) {
        Algorithm A = this.algs.get(0);
        return A.uses_register(register);
    }

    public boolean uses_register(String register) {
        Algorithm A = this.algs.get(0);
        return A.uses_register(register);
    }

    public double[] get_data_register(RegisterEnum register) {
        Algorithm A = this.algs.get(0);
        return A.get_data_register(register);
    }

    public void set_data_register(RegisterEnum register, double[] data) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_data_register(register, data);
        }
    }

    public boolean[] get_data_register_bool(RegisterEnum register) {
        Algorithm A = this.algs.get(0);
        return A.get_data_register_bool(register);
    }

    public int[] get_data_register_int(RegisterEnum register) {
        Algorithm A = this.algs.get(0);
        return A.get_data_register_int(register);
    }

    public void set_data_register(RegisterEnum register, boolean[] data) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_data_register(register, data);
        }
    }

    public void set_data_register(RegisterEnum register, int[] data) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_data_register(register, data);
        }
    }

    public double[] get_data_register(String register) {
        return this.get_data_register(RegisterEnum.valueOf(register));
    }
    
    public void set_data_register(String register, double[] data) {
        this.set_data_register(RegisterEnum.valueOf(register),data);
    }

    public boolean[] get_data_register_bool(String register) {
        return this.get_data_register_bool(RegisterEnum.valueOf(register));
    }

    public int[] get_data_register_int(String register) {
        return this.get_data_register_int(RegisterEnum.valueOf(register));
    }

    public void set_data_register(String register, boolean[] data) {
        this.set_data_register(RegisterEnum.valueOf(register), data);
    }

    public void set_data_register(String register, int[] data) {
        this.set_data_register(RegisterEnum.valueOf(register), data);
    }

    public void set_config_parameter(String name, String value) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_config_parameter(name, value);
        }
    }

    public String get_config_parameter(String name) {
        Algorithm A = this.algs.get(0);
        return A.get_config_parameter(name);
    }

    public void set_num_signals(int n_Sig) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_num_signals(n_Sig);
        }
    }

    public int get_num_signals() {
        Algorithm A = this.algs.get(0);
        return A.get_num_signals();
    }

    public void set_history_window_size(int n_Hist) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_history_window_size(n_Hist);
        }
    }

    public int get_history_window_size() {
        Algorithm A = this.algs.get(0);
        return A.get_history_window_size();
    }

    public void set_outlier_threshold(double tau_out) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_outlier_threshold(tau_out);
        }
    }

    public double get_outlier_threshold() {
        Algorithm A = this.algs.get(0);
        return A.get_outlier_threshold();
    }

    public void set_probability_threshold(double tau_prob) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_probability_threshold(tau_prob);
        }
    }

    public double get_probability_threshold() {
        Algorithm A = this.algs.get(0);
        return A.get_outlier_threshold();
    }

    public void keep_by_rule() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_by_rule();
        }
    }

    public void keep_current() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_current();
        }
    }

    public void keep_predicted() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_predicted();
        }
    }

    public void keep_last() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_last();
        }
    }

    public void keep_nans() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_nans();
        }
    }

    public void keep_zeros() {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.keep_zeros();
        }
    }

    public void set_history_window_data(double[][] window) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public double[][] get_history_window_data() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public void set_current_data(int[] data) {
        this.current_data = new double[data.length];
        for (int i = 0; i < data.length; i++) {
            this.current_data[i] = (double)data[i];
        }
    }

    public double[] get_current_data() {
        double temp[] = new double[this.current_data.length];
        for (int i = 0; i < this.current_data.length; i++){
            temp[i] = (double)this.current_data[i];
        }
        return temp;
    }

    public boolean[] get_current_usable() {
        boolean temp[] = new boolean[this.current_usable.length];
        for (int i = 0; i < this.current_usable.length; i++){
            temp[i] = this.current_usable[i];
        }
        return temp;
    }

    public int[] get_contributing_signals() {
        int temp[] = new int[this.current_contrib.length];
        for (int i = 0; i < this.current_contrib.length; i++){
            temp[i] = (int)this.current_contrib[i];
        }
        return temp;
    }

    public double[] get_d_contributing_signals() {
        double temp[] = new double[this.current_contrib.length];
        for (int i = 0; i < this.current_contrib.length; i++){
            temp[i] = (double)this.current_contrib[i];
        }
        return temp;
    }

    public void set_data_rule(RulesEnum rule) {
        for (int Index = 0; Index < this.algs.size(); Index++) {
            Algorithm A = this.algs.get(Index);
            A.set_data_rule(rule);
        }
    }

    public RulesEnum get_data_rule() {
        Algorithm A = this.algs.get(0);
        return A.get_data_rule();
    }

    public void set_calibration_status(boolean inCalib) {
        this.inCalibration = inCalib;
    }

    protected Vector<Algorithm> algs;
    protected double [] current_data;
    protected boolean [] current_usable;
    protected double [] current_resid;
    protected double [] current_pred;
    protected int [] current_contrib;
    protected double probability_of_event;
    protected StatusEnum detection_status;
    protected String message;
    protected double [] sigma_lim;
    protected boolean [] auto_ignore;
    protected boolean [] clusterizable;
    protected double[] data_lim_high;
    protected double[] data_lim_low;
    protected double[] setpt_lim_high;
    protected double[] setpt_lim_low;
    protected boolean inCalibration;

}
