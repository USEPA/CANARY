/*
 * Copyright 2014 Sandia Corporation.
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
 */
package org.canaryeds.base.util;

import org.canaryeds.base.ChannelUsage;
import org.canaryeds.base.EventStatus;
import org.canaryeds.base.Workflow;
import gov.sandia.seme.framework.DataChannel;
import gov.sandia.seme.framework.DataStatus;
import gov.sandia.seme.framework.InitializationException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.distribution.BinomialDistribution;
import org.apache.commons.math3.linear.Array2DRowRealMatrix;
import org.apache.commons.math3.linear.ArrayRealVector;
import org.apache.commons.math3.linear.CholeskyDecomposition;
import org.apache.commons.math3.linear.DecompositionSolver;
import org.apache.commons.math3.linear.RealMatrix;
import org.apache.commons.math3.linear.RealVector;
import org.apache.commons.math3.stat.descriptive.summary.Sum;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;
import static org.apache.commons.math3.util.ArithmeticUtils.pow;
import static org.apache.commons.math3.util.FastMath.abs;
import org.apache.commons.math3.util.ResizableDoubleArray;
import org.apache.log4j.Logger;

/**
 * Provides an abstract base implementation for new workflow classes.
 * 
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public abstract class WorkflowImpl implements Workflow {

    private static final Logger LOG = Logger.getLogger(WorkflowImpl.class);

    protected String name;
    protected final ArrayList<DataChannel> channels;
    protected int sz_historyWindow;
    protected double outlierThreshold;
    protected double eventThreshold;
    protected int sz_eventTimeout;
    protected int sz_eventWindowSave;
    protected int sz_bedWindow;
    protected double bedOutlierProbability;
    protected double[] precisions;
    protected ResizableDoubleArray[] historyWindow;
    protected ResizableDoubleArray distances;
    protected ResizableDoubleArray bedWindow;
    protected BinomialDistribution BED;
    protected int ct_eventTimeout = 0;
    protected final ArrayList<Double> rawData;
    protected final ArrayList<Integer> violations;
    protected final ArrayList<Short> contributed;
    protected final ArrayList<Double> residuals;
    protected final ArrayList<String> parameters;
    protected final ArrayList<String> tags;
    protected double probability;
    protected EventStatus status;
    protected final HashMap<String, Object> metaData;

    public WorkflowImpl() {
        this.metaData = new HashMap();
        this.tags = new ArrayList();
        this.parameters = new ArrayList();
        this.residuals = new ArrayList<>();
        this.contributed = new ArrayList<>();
        this.violations = new ArrayList<>();
        this.rawData = new ArrayList<>();
        this.sz_historyWindow = -10;
        this.outlierThreshold = -1.0;
        this.eventThreshold = -1.0;
        this.sz_eventTimeout = -10;
        this.sz_eventWindowSave = -10;
        this.sz_bedWindow = -10;
        this.bedOutlierProbability = 0.5;
        this.channels = new ArrayList<>();
    }

    public boolean checkParams() {
        boolean allOkay = true;
        if (this.sz_historyWindow <= 0) { LOG.fatal("history window was not specified!"); allOkay = false;}
        if (this.outlierThreshold <= 0) { LOG.fatal("outlier threshold was not specified!"); allOkay = false;}
        if (this.eventThreshold <= 0) { LOG.fatal("event threshold was not specified!"); allOkay = false;}
        if (this.sz_eventTimeout <= 0) { LOG.fatal("event timeout window was not specified!"); allOkay = false;}
        if (this.sz_eventWindowSave <= 0) { LOG.fatal("event window save was not specified!"); allOkay = false;}
        if (this.sz_bedWindow  <= 0) { LOG.fatal("BED history window was not specified!"); allOkay = false;}
        return allOkay;
    }
    
    @Override
    public void addChannel(DataChannel channel) {
        ChannelUsage usageType = (ChannelUsage) channel.getOpt("usageType");
        if (usageType == ChannelUsage.QUALITY) {
            channels.add(channel);
            parameters.add(channel.getStringOpt("parameter"));
            tags.add(channel.getTag());
            LOG.debug(
                    "Added channel " + channel.getName() + " to workflow " + this.name);
        }
    }

    @Override
    public String[] getChannelParameters() {
        return this.parameters.toArray(new String[parameters.size()]);
    }

    @Override
    public String[] getChannelTags() {
        return this.tags.toArray(new String[tags.size()]);
    }

    @Override
    public ArrayList<DataChannel> getChannels() {
        return this.channels;
    }

    @Override
    public Short[] getChannelContributed() {
        return this.contributed.toArray(new Short[this.contributed.size()]);
    }

    @Override
    public Double[] getChannelRawData() {
        return this.rawData.toArray(new Double[this.rawData.size()]);
    }

    @Override
    public Double[] getChannelResiduals() {
        return this.residuals.toArray(new Double[this.residuals.size()]);
    }

    @Override
    public Integer[] getChannelViolations() {
        return this.violations.toArray(new Integer[this.violations.size()]);
    }

    @Override
    public double getProbability() {
        return this.probability;
    }

    @Override
    public EventStatus getStatus() {
        return this.status;
    }

    protected void doProcInitHistoryWindow(int index) {
        for (int i = 0; i < channels.size(); i++) {
            double val = channels.get(i).getDoubleValue(index);
            if (!Double.isNaN(val)) {
                historyWindow[i].addElement(val);
            } else {
                historyWindow[i].addElement(historyWindow[i].getElement(
                        historyWindow[i].getNumElements() - 1));
            }
        }
        for (DataChannel chan : channels) {
            this.rawData.add(chan.getDoubleValue(index));
            this.residuals.add(Double.NaN);
            this.contributed.add((short)0);
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
        }
        this.probability = Double.NaN;
        this.status = EventStatus.UNINITIALIZED;
    }

    protected void doProcMissingData(int index) {
        for (DataChannel chan : channels) {
            this.rawData.add(chan.getDoubleValue(index));
            this.residuals.add(Double.NaN);
            this.contributed.add((short)0);
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
        }
        this.probability = Double.NaN;
        this.status = EventStatus.DATA_MISSING;
    }

    protected int doCalcNZCount(int index) {
        int nzCount = 0;
        for (DataChannel chan : channels) {
            if (!Double.isNaN(chan.getDoubleValue(index)) && chan.getStatus() == DataStatus.NORMAL) {
                nzCount++;
            }
        }
        return nzCount;
    }

    protected double doCalcBEDProbability() {
        double n = bedWindow.compute(new Sum());
        double p = BED.cumulativeProbability((int) n);
        this.probability = p;
        if (p >= eventThreshold) {
            status = EventStatus.POSSIBLE_EVENT;
            ct_eventTimeout++;
        } else if (p <= 0.5) {
            ct_eventTimeout = 0;
        }
        return p;
    }

    protected boolean doCalcEventTimeout(int index) {
        if (ct_eventTimeout >= sz_eventTimeout) {
            for (int j = 0; j < historyWindow.length; j++) {
                historyWindow[j].clear();
                for (int i = sz_historyWindow - 1; i >= 0; i--) {
                    double val = channels.get(j).getDoubleValue(
                            index - i);
                    historyWindow[j].addElement(val);
                }
            }
            bedWindow.clear();
            for (int i = 0; i < sz_bedWindow; i++) {
                bedWindow.addElement(0);
            }
            ct_eventTimeout = 0;
            status = EventStatus.EVENT_TIMEOUT;
        }
        return (status == EventStatus.EVENT_TIMEOUT);
    }

    /**
     * Get the nearest power of 2 greater than or equal to the number.
     *
     * @param a value to check
     * @return smallest power of 2 &ge; a
     */
    protected int nextpow2(int a) {
        return (a == 0) ? 0 : 32 - Integer.numberOfLeadingZeros(a - 1);
    }

    /**
     * Linear Predictive Coefficients. Computes the LP coefficients of the data
     * using the autocorrelation method, using QR decomposition to solve the
     * system of equations.
     *
     * @param x time series data to use in LP coefficients calculation.
     * @param N number of coefficients to create (0 &lt; N &lt; x.length).
     * @return LP coefficients.
     */
    protected double[] lpc(double[] x, int N) {
        // Verify N != 0, N < x.length
        int s = nextpow2(2 * x.length - 1);
        double[] xZeros = new double[pow(2, s)];
        //        System.out.print("[");
        for (int i = 0; i < xZeros.length; i++) {
            xZeros[i] = (i < x.length) ? x[i] : 0;
            //            System.out.print(xZeros[i]+", ");
        }
        //        System.out.println("]");
        //        System.out.println(xZeros.length);
        Complex[] X;
        FastFourierTransformer fft = new FastFourierTransformer(
                DftNormalization.STANDARD);
        X = fft.transform(xZeros, TransformType.FORWARD);
        double[] X2 = new double[X.length];
        //        System.out.print("[");
        for (int i = 0; i < X.length; i++) {
            double tmp = X[i].abs();
            X2[i] = tmp * tmp;
            //            System.out.print(X2[i]+", ");
        }
        //        System.out.println("]");
        Complex[] R;
        R = fft.transform(X2, TransformType.INVERSE);
        double[] R2 = new double[R.length];
        //        System.out.print("[");
        for (int i = 0; i < R.length; i++) {
            //            System.out.print(R[i].divide(x.length)+", ");
            double tmp = R[i].divide(x.length).getReal();
            R2[i] = tmp;
        }
        //        System.out.println("]");
        //        System.out.print("[");
        //        for (int i = 0; i < R2.length; i++) {
        //            System.out.print(R2[i]+", ");
        //        }
        //        System.out.println("]");
        double[][] Y = new double[N][N];
        double[] b = new double[N];
        for (int i = 0; i < N; i++) {
            b[i] = -R2[i + 1];
            for (int j = 0; j < N; j++) {
                int ri = abs(i - j);
                Y[i][j] = R2[ri];
            }
        }
        //        System.out.println(Y.length);
        //        System.out.println(b.length);
        /* // The following uses the JBLAS solver
         DoubleMatrix coefficients = new DoubleMatrix(Y);
         DoubleMatrix constants = new DoubleMatrix(b.length, 1, b);
         DoubleMatrix solution = Solve.solveLeastSquares(coefficients, constants);
         return solution.data;
         */
        // The following uses the apache commons math solver instead of JBLAS
        RealMatrix coefficients = new Array2DRowRealMatrix(Y);
        DecompositionSolver solver = new CholeskyDecomposition(coefficients).getSolver();
        RealVector constants = new ArrayRealVector(b, false);
        RealVector solution = solver.solve(constants);
        return solution.toArray();
    }

    /**
     * Calculate the estimated value using LP coefficients.
     *
     * @param b lpc coefficients
     * @param x time series data
     * @return predicted value
     */
    protected double predEstim(double[] b, double[] x) {
        double sum = 0.0;
        int nb = b.length;
        int n = x.length;
        for (int i = 1; i < nb; i++) {
            sum -= b[i] * x[n - i - 1];
        }
        return sum;
    }

    @Override
    public int getMaxWindowNeeded() {
        return sz_bedWindow + sz_eventTimeout + sz_historyWindow;
    }

    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public void setName(String n) {
        this.name = n;
    }

    @Override
    public void initialize() throws InitializationException {
        LOG.debug(
                "Initializing workflow " + this.name + " with " + channels.size() + " channels.");
        historyWindow = new ResizableDoubleArray[channels.size()];
        precisions = new double[channels.size()];
        for (int i = 0; i < channels.size(); i++) {
            historyWindow[i] = new ResizableDoubleArray(sz_historyWindow);
            double stdDev;
            try {
                stdDev = channels.get(i).getDoubleOpt("precision");
            } catch (ClassCastException ex) {
                Integer temp = channels.get(i).getIntegerOpt("precision");
                stdDev = temp.doubleValue();
            }
            if (Double.isNaN(stdDev)) {
                stdDev = 0.0001;
            }
            precisions[i] = stdDev;
        }
        bedWindow = new ResizableDoubleArray(sz_bedWindow);
        for (int i = 0; i < sz_bedWindow; i++) {
            bedWindow.addElement(0.0);
        }
        distances = new ResizableDoubleArray(sz_historyWindow);
        BED = new BinomialDistribution(sz_bedWindow, bedOutlierProbability);
    }

    @Override
    public void removeChannel(String name) {
        for (DataChannel chan : channels) {
            if (name.contentEquals(chan.getName())) {
                channels.remove(chan);
            }
        }
    }

    @Override
    public int getPreEventHistoryCount() {
        return sz_eventWindowSave + sz_bedWindow;
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
