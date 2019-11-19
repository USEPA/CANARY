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
package gov.sandia.seme.util;

import gov.sandia.seme.util.LazyModulusArray;
import gov.sandia.seme.framework.DataOutOfFrameException;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.junit.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

public class LazyModulusArrayTest {

    @BeforeClass
    public static void setUpClass() {
    }

    @AfterClass
    public static void tearDownClass() {
    }

    public LazyModulusArrayTest() {
    }

    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

    /**
     * Test of LazyModulusArray#get method.
     */
    @Test
    public void testGet() throws Exception {
        System.out.println("get");
        int index = 0;
        LazyModulusArray instance = new LazyModulusArray(20);
        double expResult = Double.NaN;
        double result = instance.get(index);
        assertEquals(expResult, result, Double.NaN);
        // set the values
        for (int i = 0; i < 50; i++) {
            instance.set(i, i);
        }
        // check the last values
        for (index = 30; index < 50; index++) {
            expResult = index;
            result = instance.get(index);
            assertEquals(expResult, result, 0.0);
        }
        // check getting data past end of array that has not been set yet using back copy
        instance.setCopyMissing(true);
        expResult = index - 1;
        result = instance.get(60);
        assertEquals(expResult, result, 0.0);
        result = instance.get(55);
        assertEquals(expResult, result, 0.0);
        // test getting data past end of frame that has not been set using back NaN
        instance.setCopyMissing(false);
        expResult = Double.NaN;
        result = instance.get(80);
        assertEquals(expResult, result, Double.NaN);
        result = instance.get(75);
        assertEquals(expResult, result, Double.NaN);
        // check get exception for out of frame (early)
        try {
            instance.get(29);
            fail("Failed to give exception");
        } catch (DataOutOfFrameException ex) {
            assertEquals(
                    "Attempt to read data at index 29 that is out of frame (current frame from Step index 61 to 80)",
                    ex.getMessage());
        }
    }

    /**
     * Test of LazyModulusArray#getCopyMissing method.
     */
    @Test
    public void testGetCopyMissing() {
        System.out.println("getCopyMissing");
        LazyModulusArray instance = new LazyModulusArray(20);
        boolean expResult = false;
        boolean result = instance.getCopyMissing();
        assertEquals(expResult, result);
    }

    /**
     * Test of LazyModulusArray#getFrameEnd method.
     */
    @Test
    public void testGetFrameEnd() {
        System.out.println("getFrameEnd");
        LazyModulusArray instance = new LazyModulusArray(20);
        int expResult = -1;
        int result = instance.getFrameEnd();
        assertEquals(expResult, result);
        try {
            instance.set(29, 4.3);
        } catch (DataOutOfFrameException ex) {
            Logger.getLogger(LazyModulusArrayTest.class.getName()).log(
                    Level.SEVERE, null, ex);
            fail("Data out of frame exception in test");
        }
        expResult = 29;
        result = instance.getFrameEnd();
        assertEquals(expResult, result);
    }

    /**
     * Test of LazyModulusArray#getFrameSize method.
     */
    @Test
    public void testGetFrameSize() {
        System.out.println("getFrameSize");
        LazyModulusArray instance = new LazyModulusArray(20);
        int expResult = 20;
        int result = instance.getFrameSize();
        assertEquals(expResult, result);
    }

    /**
     * Test of LazyModulusArray#getFrameStart method.
     */
    @Test
    public void testGetFrameStart() {
        System.out.println("getFrameStart");
        LazyModulusArray instance = new LazyModulusArray(20);
        int expResult = 0;
        int result = instance.getFrameStart();
        assertEquals(expResult, result);
        try {
            instance.set(29, 4.3);
        } catch (DataOutOfFrameException ex) {
            Logger.getLogger(LazyModulusArrayTest.class.getName()).log(
                    Level.SEVERE, null, ex);
            fail("Data out of frame exception in test");
        }
        expResult = 10;
        result = instance.getFrameStart();
        assertEquals(expResult, result);
    }

    /**
     * Test of LazyModulusArray#set method.
     */
    @Test
    public void testSet() throws Exception {
        System.out.println("set");
        int index = 0;
        LazyModulusArray instance = new LazyModulusArray(20);
        double expResult = Double.NaN;
        double result = instance.get(index);
        assertEquals(expResult, result, Double.NaN);
        // test setting the data in a loop
        for (int i = 0; i < 50; i++) {
            instance.set(i, i);
        }
        for (index = 30; index < 50; index++) {
            expResult = index;
            result = instance.get(index);
            assertEquals(expResult, result, 0.0);
        }
        // test setting data out a ways to see if back copy works
        instance.setCopyMissing(true);
        expResult = 12.5;
        instance.set(60, 12.5);
        result = instance.get(60);
        assertEquals(expResult, result, 0.0);
        result = instance.get(55);
        expResult = 49;
        assertEquals(expResult, result, 0.0);
        // test setting data out a ways to see if back NaN works
        instance.setCopyMissing(false);
        expResult = 19.333;
        instance.set(80, expResult);
        result = instance.get(80);
        assertEquals(expResult, result, 0.0);
        expResult = Double.NaN;
        result = instance.get(75);
        assertEquals(expResult, result, Double.NaN);
        // test setting data outside beginning of the frame
        try {
            instance.set(29, 4.3);
            fail("Failed to give exception");
        } catch (DataOutOfFrameException ex) {
            assertEquals(
                    "Attempt to load data at index 29 that has gone out of frame (current frame from Step index 61 to 80)",
                    ex.getMessage());
        }
    }

    /**
     * Test of LazyModulusArray#setCopyMissing method.
     */
    @Test
    public void testSetCopyMissing() {
        System.out.println("setCopyMissing");
        boolean value = true;
        LazyModulusArray instance = new LazyModulusArray(20);
        instance.setCopyMissing(value);
        assertEquals(instance.getCopyMissing(), true);
    }
}
