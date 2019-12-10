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

import gov.sandia.seme.framework.Describable;
import java.util.HashMap;
import java.util.Map;

/**
 * Provides meta-data options that can be attached to an object.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class DescribableImpl implements Describable {

    /**
     * Configuration options and metadata.
     */
    protected final HashMap<String, Object> metaData = new HashMap();

    /**
     * Constructor for new blank describable.
     */
    public DescribableImpl() {
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
