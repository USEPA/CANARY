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

import gov.sandia.seme.framework.Engine;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;

@Ignore
public class EngineTest {

    public EngineTest() {
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
     * Test of Engine#call method.
     */
    @Test
    public void testCall() {
        System.out.println("call");
        Engine instance = new Engine();
        boolean expResult = false;
        boolean result = instance.call();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#getControllerImpl method.
     */
    @Test
    public void testGetController() {
        System.out.println("getController");
        Engine instance = new Engine();
        Controller expResult = null;
        Controller result = instance.getController();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#getUsedControllerImplName method.
     */
    @Test
    public void testGetUsedControllerName() {
        System.out.println("getUsedControllerName");
        Engine instance = new Engine();
        String expResult = "";
        String result = instance.getUsedControllerName();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#setUsedControllerImplName method.
     */
    @Test
    public void testSetUsedControllerName() {
        System.out.println("setUsedControllerName");
        String usedControllerName = "";
        Engine instance = new Engine();
        instance.setUsedControllerName(usedControllerName);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#initialize method.
     */
    @Test
    public void testInitialize() throws Exception {
        System.out.println("initialize");
        Engine instance = new Engine();
        instance.initialize();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#shutdown method.
     */
    @Test
    public void testShutdown() {
        System.out.println("shutdown");
        Engine instance = new Engine();
        instance.shutdown();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#getCurrentStep method.
     */
    @Test
    public void testGetCurrentStep() {
        System.out.println("getCurrentStep");
        Engine instance = new Engine();
        Step expResult = null;
        Step result = instance.getCurrentStep();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#setCurrentStep method.
     */
    @Test
    public void testSetCurrentStep() {
        System.out.println("setCurrentStep");
        Step currentStep = null;
        Engine instance = new Engine();
        instance.setCurrentStep(currentStep);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#setComponentFactory method.
     */
    @Test
    public void testSetComponentFactory() {
        System.out.println("setComponentFactory");
        Components factory = null;
        Engine instance = new Engine();
        instance.setComponentFactory(factory);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Engine#getComponentFactory method.
     */
    @Test
    public void testGetComponentFactory() {
        System.out.println("getComponentFactory");
        Engine instance = new Engine();
        Components expResult = null;
        Components result = instance.getComponentFactory();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

}
