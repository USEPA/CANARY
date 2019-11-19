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

import org.teva.canary.lib.StatusEnum;

/**
 *
 * @author dbhart
 */
public class MVNN extends BaseAlgorithm {

    /**
     *
     */
    protected double tau_mvnn;
    /**
     *
     */
    protected int n_steps;

    /**
     *
     * @param tau_mvnn
     */
    public MVNN(double tau_mvnn) {
        this.tau_mvnn = tau_mvnn;
    }

    /**
     *
     */
    public MVNN() {
        this.tau_mvnn = Double.NaN;
    }


    @Override
    public void initialize(int n_Sig) {
        super.initialize(n_Sig);
        this.n_steps = 0;
        this.tau_mvnn = this.threshold;
        if (!Double.isNaN(this.tau_mvnn)) {
            for (int i = 0; i < n_Sig; i++) {
                this.tau_out[i] = Double.NaN;
            }
        }
    }


    /**
     *
     */
    public void evaluate() {
        int minIdx = -1;
        double min = Float.MAX_VALUE;
        double dist;
        int nGood = 0;
        int nOut = 0;
        this.probability2 = 0.0;
        this.probability = 0.0;
        if (this.detection_status == StatusEnum.MISSINGHIST) {
            this.n_steps = this.n_steps + 1;
            if (this.n_steps <= this.history_window_size) {
                return;
            }
            this.detection_status = StatusEnum.NORMAL;
        }
        this.detection_status = StatusEnum.NORMAL;
        double[][] norm_window = this.normalize_window();

        /* for (int iCol = 0; iCol < this.num_signals; iCol++) {
            System.out.println("[" + iCol + "]:" +
                    " IGN=" + this.auto_ignore_signals[iCol] +
                    " USE=" + this.usable_signals[iCol] +
                    " mean=" + this.cur_sum[iCol] / this.cur_count[iCol] +
                    " s=" + this.cur_sigma[iCol]);
        } */

        double mean = 0.0;
        double sigma = 0.0;
        double val = 0.0;
        double min_ndist = Double.POSITIVE_INFINITY;
        int min_idx = -1;
        double nDist = 0.0;
        double eDist = 0.0;
        for (int jRow = 0; jRow < this.history_window_size; jRow++) {
            int cNGood = 0;
            nDist = 0.0;
            for (int iCol = 0; iCol < this.num_signals; iCol++) {
                mean = this.cur_sum[iCol] / this.cur_count[iCol];
                sigma = this.cur_sigma[iCol];
                val = (this.data[iCol] - mean) / sigma;
                val = norm_window[jRow][iCol] - val;
                if (this.usable_signals[iCol] && !this.auto_ignore_signals[iCol] &&
                        !Double.isNaN(val)) {
                    nDist += val * val;
                    cNGood++;
                }
            }
            nDist = Math.sqrt(nDist);
            if (cNGood < 1) {
                nDist = Double.POSITIVE_INFINITY;
            }
            /* System.out.println("  ["+jRow+"]"+" DIST="+nDist+" N="+cNGood); */
            if (!Double.isNaN(nDist) && nDist < min_ndist) {
                min_ndist = nDist;
                min_idx = jRow;
                nGood = cNGood;
            }
        }
        //System.out.println("Nearest Neighbor: "+min_idx+" @ "+min_ndist+" / "+nGood);
        if (min_idx < 0) {
            for (int iCol = 0; iCol < this.num_signals; iCol++) {
                this.residuals[iCol] = Double.NaN;
                this.predictions[iCol] = this.data[iCol];
                this.contributing_parameters[iCol] = 0;
            }
        } else {
            eDist = Math.sqrt(this.tau_mvnn * this.tau_mvnn / (double)nGood);
            for (int iCol = 0; iCol < this.num_signals; iCol++) {
                mean = this.cur_sum[iCol] / this.cur_count[iCol];
                sigma = this.cur_sigma[iCol];
                val = (this.data[iCol] - mean) / sigma;
                val = norm_window[min_idx][iCol] - val;
                if (this.usable_signals[iCol] && !this.auto_ignore_signals[iCol] &&
                        !Double.isNaN(val)) {
                    this.residuals[iCol] = Math.abs(val);
                    if (val > eDist) {
                        this.contributing_parameters[iCol] = 1;
                        nOut++;
                    } else if (val < -eDist) {
                        this.contributing_parameters[iCol] = -1;
                        nOut++;
                    } else {
                        this.contributing_parameters[iCol] = 0;
                    }
                    this.predictions[iCol] = this.history_window[min_idx][iCol];
                } else {
                    this.residuals[iCol] = Double.NaN;
                    this.predictions[iCol] = this.history_window[min_idx][iCol];
                }
            }
        }
        this.probability = min_ndist;
        this.probability2 = min_idx;
        if (min_ndist > this.tau_mvnn) {
            this.detection_status = StatusEnum.OUTLIER;
            if (min_ndist >= this.tau_prob) {
                this.detection_status = StatusEnum.EVENT;
            }
        }
    }

    public void set_config_parameter(String name, String value) {
        if (name.compareToIgnoreCase("threshold") == 0) {
            this.tau_mvnn = Double.valueOf(value);
            for (int i = 0; i < this.num_signals; i++) {
                this.tau_out[i] = Double.NaN;
            }
        } else {
            throw new UnsupportedOperationException("Invalid configuration parameter: "+name+".");
        }
    }

    public String get_config_parameter(String name) {
        if (name.compareToIgnoreCase("threshold") == 0) {
            return Double.toString(this.tau_mvnn);
        } else {
            throw new UnsupportedOperationException("Invalid configuration parameter: "+name+".");
        }
    }

}
