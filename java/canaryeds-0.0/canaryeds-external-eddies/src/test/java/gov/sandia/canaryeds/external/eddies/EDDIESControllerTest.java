/*
 * Copyright 2014 Sandia National Laboratories.
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

package org.canaryeds.external.eddies;

import gov.sandia.seme.framework.Descriptor;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;
import org.junit.Ignore;

/**
 *
 * @author Sandia Corporation
 */
@Ignore
public class EDDIESControllerTest {
    
    public EDDIESControllerTest() {
    }
    
    @BeforeClass
    public static void setUpClass() {
    }
    
    @AfterClass
    public static void tearDownClass() {
    }
    
    @Before
    public void setUp() {
    }
    
    @After
    public void tearDown() {
    }

    /**
     * Test of getConfiguration method, of class EDDIESController.
     */
    @Test
    public void testGetConfiguration() {
        System.out.println("getConfiguration");
        EDDIESController instance = new EDDIESController();
        Descriptor expResult = null;
        Descriptor result = instance.getConfiguration();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of loadState method, of class EDDIESController.
     */
    @Test
    public void testLoadState() {
        System.out.println("loadState");
        EDDIESController instance = new EDDIESController();
        instance.loadState();
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of run method, of class EDDIESController.
     */
    @Test
    public void testRun() {
        System.out.println("run");
        EDDIESController instance = new EDDIESController();
        instance.run();
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of saveState method, of class EDDIESController.
     */
    @Test
    public void testSaveState() {
        System.out.println("saveState");
        EDDIESController instance = new EDDIESController();
        instance.saveState();
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }
    
}
