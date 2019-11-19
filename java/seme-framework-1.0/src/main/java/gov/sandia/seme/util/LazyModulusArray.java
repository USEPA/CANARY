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

import gov.sandia.seme.framework.DataOutOfFrameException;
import java.io.Serializable;

/**
 * Statically allocated, lazy evaluation on get and set, double array. Not
 * thread safe, but data channels are internal to a single thread, so not a
 * problem.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class LazyModulusArray implements Serializable {

    boolean copyMissing;
    final double[] data;

    final int frameSize;
    int lastIndex;
    int lastModIndex;

    /**
     * <p>
     * @param size
     */
    public LazyModulusArray(int size) {
        if (size < 1) {
            size = 1;
        }
        this.copyMissing = false;
        this.lastIndex = -1;
        this.frameSize = size;
        this.data = new double[size];
        for (int i = 0; i < size; i++) {
            this.data[i] = Double.NaN;
        }
    }

    /**
     * Get data from a specific index.
     *
     * @param index the index to get data values from
     * @return the data value at the index provided
     * @throws DataOutOfFrameException
     */
    public double get(int index) throws DataOutOfFrameException {
        if (index > lastIndex) {
            // new data that shifts frame forward in time
            copyBackData(index);
            lastIndex = index;
            lastModIndex = index % frameSize;
            return data[index % frameSize];
        } else if (index > (lastIndex - frameSize)) {
            // If data in frame, we modify value
            return data[index % frameSize];
        } else {
            throw new DataOutOfFrameException("Attempt to read data at index "
                    + index + " that is out of frame (current frame from Step index "
                    + (lastIndex - frameSize + 1) + " to " + lastIndex + ")");
        }
    }

    /**
     * Get the setting for copyMissing.
     *
     * @return the value of copyMissing
     */
    public boolean getCopyMissing() {
        return copyMissing;
    }

    /**
     * Set the value for copyMissing.
     *
     * @param value the new value for copyMissing
     */
    public void setCopyMissing(boolean value) {
        copyMissing = value;
    }

    /**
     * Get the last index of the array.
     *
     * @return the last index with data
     */
    public int getFrameEnd() {
        return lastIndex;
    }

    /**
     * Get the frame size.
     *
     * @return the value of frameSize
     */
    public int getFrameSize() {
        return frameSize;
    }

    /**
     * Get the first index in the array.
     *
     * @return the first index of the array
     */
    public int getFrameStart() {
        int start = lastIndex - frameSize + 1;
        if (start < 0) {
            return 0;
        }
        return start;
    }

    /**
     * Add data to the array or set a value at an index.
     *
     * @param index the index of the data
     * @param value the data value
     * @throws DataOutOfFrameException
     */
    public void set(int index, double value) throws DataOutOfFrameException {
        if (index > lastIndex) {
            // new data that shifts frame forward in time
            copyBackData(index);
            data[index % frameSize] = value;
            lastIndex = index;
            lastModIndex = index % frameSize;
        } else if (index > (lastIndex - frameSize)) {
            // If data in frame, we modify value
            data[index % frameSize] = value;
        } else {
            throw new DataOutOfFrameException("Attempt to load data at index "
                    + index + " that has gone out of frame (current frame from Step index "
                    + (lastIndex - frameSize + 1) + " to " + lastIndex + ")");
        }
    }

    @Override
    public String toString() {
        String strData;
        strData = "[";
        for (int i = 0; i < frameSize; i++) {
            strData += data[i];
            strData += ", ";
        }
        strData += "]";
        return "LazyModulusArray{" + "frameSize=" + frameSize + ", data="
                + strData + ", lastIndex=" + lastIndex + ", copyMissing="
                + copyMissing + ", lastModIndex=" + lastModIndex + '}';
    }

    private void copyBackData(int index) {
        if (copyMissing) {
            for (int i = lastIndex + 1; i <= index; i++) {
                data[i % frameSize] = data[(i - 1) % frameSize];
            }
        } else {
            for (int i = lastIndex + 1; i <= index; i++) {
                data[i % frameSize] = Double.NaN;
            }
        }
    }
}
