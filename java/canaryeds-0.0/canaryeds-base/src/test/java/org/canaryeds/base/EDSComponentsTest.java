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
package org.canaryeds.base;

import org.canaryeds.base.EDSComponents;
import org.canaryeds.base.Workflow;
import gov.sandia.seme.framework.Controller;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Messagable;
import java.util.HashMap;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;

@Ignore
public class EDSComponentsTest {

    public EDSComponentsTest() {
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
     * Test of EDSComponents#newController method, of class EDSComponents.
     */
    @Test
    public void testNewController() throws Exception {
        System.out.println("newController");
        Descriptor desc = null;
        EDSComponents instance = new EDSComponents();
        Controller expResult = null;
        Controller result = instance.newController(desc);
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#newMessagable method, of class EDSComponents.
     */
    @Test
    public void testNewMessagable() throws Exception {
        System.out.println("newMessagable");
        Descriptor desc = null;
        EDSComponents instance = new EDSComponents();
        Messagable expResult = null;
        Messagable result = instance.newMessagable(desc);
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#newWorkflow method, of class EDSComponents.
     */
    @Test
    public void testNewWorkflow() throws Exception {
        System.out.println("newWorkflow");
        Descriptor desc = null;
        EDSComponents instance = new EDSComponents();
        Workflow expResult = null;
        Workflow result = instance.newWorkflow(desc);
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#getResultMessageDataKeys method, of class EDSComponents.
     */
    @Test
    public void testGetResultMessageDataKeys() {
        System.out.println("getResultMessageDataKeys");
        EDSComponents instance = new EDSComponents();
        String[] expResult = null;
        String[] result = instance.getResultMessageDataKeys();
        assertArrayEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#getValueMessageDataKeys method, of class EDSComponents.
     */
    @Test
    public void testGetValueMessageDataKeys() {
        System.out.println("getValueMessageDataKeys");
        EDSComponents instance = new EDSComponents();
        String[] expResult = null;
        String[] result = instance.getValueMessageDataKeys();
        assertArrayEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#getControlMessageDataKeys method, of class EDSComponents.
     */
    @Test
    public void testGetControlMessageDataKeys() {
        System.out.println("getControlMessageDataKeys");
        EDSComponents instance = new EDSComponents();
        String[] expResult = null;
        String[] result = instance.getControlMessageDataKeys();
        assertArrayEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of EDSComponents#getWorkflowDescriptors method, of class EDSComponents.
     */
    @Test
    public void testGetWorkflowDescriptors() throws Exception {
        System.out.println("getWorkflowDescriptors");
        HashMap config = null;
        EDSComponents instance = new EDSComponents();
        HashMap<String, Descriptor> expResult = null;
        HashMap<String, Descriptor> result = instance.getWorkflowDescriptors(
                config);
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

}
