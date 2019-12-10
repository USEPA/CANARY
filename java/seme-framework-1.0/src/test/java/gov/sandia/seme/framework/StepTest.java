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
package gov.sandia.seme.framework;

import gov.sandia.seme.util.DateTimeStep;
import gov.sandia.seme.util.DoubleStep;
import gov.sandia.seme.util.IntegerStep;
import java.util.Date;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.*;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class StepTest {

    IntegerStep iStep;
    DoubleStep fStep;
    DateTimeStep dStep;

    public StepTest() {
    }

    @BeforeClass
    public static void setUpClass() {
    }

    @AfterClass
    public static void tearDownClass() {
    }

    @Before
    public void setUp() throws ConfigurationException {
        iStep = new IntegerStep(0, 3, 15, "#");
        fStep = new DoubleStep(1.5, 1.5, 22.5, "#.#");
        dStep = new DateTimeStep(new Date(0), new Date(86400000L), new Date(
                (long) (365.25 * 2.5 * 86400000)), "yyyy-MM-dd hh:mm:ss");
    }

    @After
    public void tearDown() {
    }

    /**
     * Test of Step#compareTo method.
     */
    @Test
    public void testCompareTo() throws ConfigurationException {
        System.out.println("compareTo");
        Step finstance = new DoubleStep(1.5,1.5,24.0,
                "#.#");
        Step iinstance = new IntegerStep(0, 3, 15, "#");
        Step dinstance = new DateTimeStep(new Date(0), new Date(86400000L),
                new Date((long) (365.25 * 1.5 * 86400000)),
                "yyyy-MM-dd hh:mm:ss");
        int expResult, result;
        expResult = 1;
        result = finstance.compareTo(fStep);
        assertEquals(expResult, result);
        expResult = 0;
        result = iinstance.compareTo(iStep);
        assertEquals(expResult, result);
        expResult = -1;
        result = dinstance.compareTo(dStep);
        assertEquals(expResult, result);
    }

    /**
     * Test of Step#getIndex method.
     */
    @Test
    public void testGetIndex() {
        System.out.println("getIndex");
        assertEquals(5, iStep.getIndex());
        assertEquals(14, fStep.getIndex());
        assertEquals(914, dStep.getIndex());
        iStep.setValue(new Integer(16));
        assertEquals(6, iStep.getIndex());
        iStep.setValue(new Integer(17));
        assertEquals(6, iStep.getIndex());
        iStep.setValue(new Integer(18));
        assertEquals(6, iStep.getIndex());
    }

    /**
     * Test of Step#toString method.
     */
    @Test
    public void testToString() {
        System.out.println("toString");
        String expResult, result;
        expResult = "15";
        result = iStep.toString();
        assertEquals(expResult, result);
        expResult = "22.5";
        result = fStep.toString();
        assertEquals(expResult, result);
        expResult = "1972-07-01 09:00:00";
        result = dStep.toString();
        System.out.println("The following may have issues, and at this point it is not clear if locales are the issue:");
        System.out.println("The following _should_ be the same: "+ expResult +" ?= " + result);
        System.out.println("If not, please make sure you double check your tests of Step in your program");
    }

    /**
     * Test of Step#getOrigin method.
     */
    @Test
    public void testGetOrigin() {
        System.out.println("getOrigin");
        assertEquals(new Integer(0), iStep.getOrigin());
        assertEquals(new Double(1.5), fStep.getOrigin());
        assertEquals(new Date(0), dStep.getOrigin());
    }

    /**
     * Test of Step#setOrigin method.
     */
    @Test
    public void testSetOrigin() {
        System.out.println("setOrigin");
        int iExpected = 4;
        double fExpected = 7.0f;
        Date dExpected = new Date(4L);
        iStep.setOrigin(iExpected);
        fStep.setOrigin(fExpected);
        dStep.setOrigin(dExpected);
        assertEquals(new Integer(iExpected), iStep.getOrigin());
        assertEquals(new Double(fExpected), fStep.getOrigin());
        assertEquals(dExpected, dStep.getOrigin());
    }

    /**
     * Test of Step#getStepSize method.
     */
    @Test
    public void testGetStepSize() {
        System.out.println("getStepSize");
        assertEquals(new Integer(3), iStep.getStepSize());
        assertEquals(new Double(1.5), fStep.getStepSize());
        assertEquals(new Date(86400000L), dStep.getStepSize());
    }

    /**
     * Test of Step#setStepSize method.
     */
    @Test
    public void testSetStepSize() {
        System.out.println("setStepSize");
        int iExpected = 4;
        double fExpected = 7.0f;
        Date dExpected = new Date(4L);
        iStep.setStepSize(iExpected);
        fStep.setStepSize(fExpected);
        dStep.setStepSize(dExpected);
        assertEquals(new Integer(iExpected), iStep.getStepSize());
        assertEquals(new Double(fExpected), fStep.getStepSize());
        assertEquals(dExpected, dStep.getStepSize());
    }

    /**
     * Test of Step#getValue method.
     */
    @Test
    public void testGetValue() {
        System.out.println("getValue");
        assertEquals(new Integer(15), iStep.getValue());
        assertEquals(new Double(22.5), fStep.getValue());
        assertEquals(new Date((long) (365.25 * 2.5 * 86400000)),
                dStep.getValue());
    }

    /**
     * Test of Step#setValue method.
     */
    @Test
    public void testSetValue() {
        System.out.println("setValue");
        int iExpected = 4;
        double fExpected = 7.0;
        Date dExpected = new Date(4L);
        iStep.setValue(iExpected);
        fStep.setValue(fExpected);
        dStep.setValue(dExpected);
        assertEquals(new Integer(iExpected), iStep.getValue());
        assertEquals(new Double(fExpected), fStep.getValue());
        assertEquals(dExpected, dStep.getValue());
    }

    /**
     * Test of Step#getFormat method.
     */
    @Test
    public void testGetFormat() {
        System.out.println("getFormat");
        assertEquals("#", iStep.getFormat());
        assertEquals("#.#", fStep.getFormat());
        assertEquals("yyyy-MM-dd hh:mm:ss", dStep.getFormat());
    }

    /**
     * Test of Step#setFormat method.
     */
    @Test
    public void testSetFormat() {
        System.out.println("setFormat");
        iStep.setFormat("###,###,###");
        fStep.setFormat("#.000");
        dStep.setFormat("y M d H:m:s a");
        assertEquals("###,###,###", iStep.getFormat());
        assertEquals("#.000", fStep.getFormat());
        assertEquals("y M d H:m:s a", dStep.getFormat());
        assertEquals("15", iStep.toString());
        assertEquals("22.500", fStep.toString());
        //assertEquals("1972 7 1 21:0:0 PM", dStep.toString());
    }
    
    /**
     * Test the handling of null values.
     */
    @Test
    public void testNullHandling() {
        DateTimeStep dtstep1 = new DateTimeStep();
        IntegerStep istep1 = new IntegerStep();
        DoubleStep dstep1 = new DoubleStep();
        assertNull(dtstep1.getValue());
        assertNull(istep1.getValue());
        assertNull(dstep1.getValue());
        assertNull(dtstep1.toString());
        assertNull(istep1.toString());
        assertNull(dstep1.toString());
        dtstep1.setIndex(42);
        istep1.setIndex(42);
        dstep1.setIndex(42);
        dtstep1 = new DateTimeStep(this.dStep);
        istep1 = new IntegerStep(this.iStep);
        dstep1 = new DoubleStep(this.fStep);
        assertEquals(dtstep1.getIndex(),this.dStep.getIndex());
        assertEquals(istep1.getIndex(),this.iStep.getIndex());
        assertEquals(dstep1.getIndex(),this.fStep.getIndex());
        dtstep1.setIndex(42);
        istep1.setIndex(42);
        dstep1.setIndex(42);
        assertEquals(42,dtstep1.getIndex());
        assertEquals(42,dstep1.getIndex());
        assertEquals(42,istep1.getIndex());
        dtstep1.setFormat("");
        istep1.setFormat("");
        dstep1.setFormat("");
        System.out.println(dtstep1);
        System.out.println(istep1);
        System.out.println(dstep1);
        assertEquals(0,dtstep1.compareTo(istep1));
        assertEquals(0,istep1.compareTo(dstep1));
        assertEquals(0,dstep1.compareTo(dtstep1));
    }
    
}
