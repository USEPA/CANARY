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

import gov.sandia.seme.framework.Engine;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Step;
import org.junit.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

@Ignore
public class ControllerImplTest {

    public ControllerImplTest() {
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
     * Test of ControllerImpl#configure method.
     */
    @Test
    public void testConfigure() throws Exception {
        System.out.println("configure");
        Descriptor desc = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.configure(desc);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setEngine method.
     */
    @Test
    public void testSetEngine() {
        System.out.println("setCanary");
        Engine engine = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setEngine(engine);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#getDataStyle method.
     */
    @Test
    public void testGetDataStyle() {
        System.out.println("getDataStyle");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
gov.sandia.seme.framework.MissingDataPolicy expResult = null;
gov.sandia.seme.framework.MissingDataPolicy result = instance.getDataStyle();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setDataStyle method.
     */
    @Test
    public void testSetDataStyle() {
        System.out.println("setDataStyle");
gov.sandia.seme.framework.MissingDataPolicy style = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setDataStyle(style);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#getPollRate method.
     */
    @Test
    public void testGetPollRate() {
        System.out.println("getPollRate");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        long expResult = 0L;
        long result = instance.getPollRate();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setPollRate method.
     */
    @Test
    public void testSetPollRate() {
        System.out.println("setPollRate");
        long rate = 0L;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setPollRate(rate);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#getStepBase method.
     */
    @Test
    public void testGetStepBase() {
        System.out.println("getStepBase");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        Step expResult = null;
        Step result = instance.getStepBase();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setStepBase method.
     */
    @Test
    public void testSetStepBase() {
        System.out.println("setStepBase");
        Step step = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setStepBase(step);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#getStepStart method.
     */
    @Test
    public void testGetStepStart() {
        System.out.println("getStepStart");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        Step expResult = null;
        Step result = instance.getStepStart();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setStepStart method.
     */
    @Test
    public void testSetStepStart() {
        System.out.println("setStepStart");
        Step step = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setStepStart(step);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#getStepStop method.
     */
    @Test
    public void testGetStepStop() {
        System.out.println("getStepStop");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        Step expResult = null;
        Step result = instance.getStepStop();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setStepStop method.
     */
    @Test
    public void testSetStepStop() {
        System.out.println("setStepStop");
        Step step = null;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setStepStop(step);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#isDynamic method.
     */
    @Test
    public void testIsDynamic() {
        System.out.println("isDynamic");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        boolean expResult = false;
        boolean result = instance.isDynamic();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setDynamic method.
     */
    @Test
    public void testSetDynamic() {
        System.out.println("setDynamic");
        boolean dynamic = false;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setDynamic(dynamic);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#isPaused method.
     */
    @Test
    public void testIsPaused() {
        System.out.println("isPaused");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        boolean expResult = false;
        boolean result = instance.isPaused();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setPaused method.
     */
    @Test
    public void testSetPaused() {
        System.out.println("setPaused");
        boolean paused = false;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setPaused(paused);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#isRunning method.
     */
    @Test
    public void testIsRunning() {
        System.out.println("isRunning");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        boolean expResult = false;
        boolean result = instance.isRunning();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#setRunning method.
     */
    @Test
    public void testSetRunning() {
        System.out.println("setRunning");
        boolean running = false;
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.setRunning(running);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#loadState method.
     */
    @Test
    public void testLoadState() {
        System.out.println("loadState");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.loadState();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#run method.
     */
    @Test
    public void testRun() {
        System.out.println("run");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.run();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#saveState method.
     */
    @Test
    public void testSaveState() {
        System.out.println("saveState");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.saveState();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#pauseExecution method.
     */
    @Test
    public void testPauseExecution() {
        System.out.println("pauseExecution");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.pauseExecution();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#resumeExecution method.
     */
    @Test
    public void testResumeExecution() {
        System.out.println("resumeExecution");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.resumeExecution();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of ControllerImpl#stopExecution method.
     */
    @Test
    public void testStopExecution() {
        System.out.println("stopExecution");
        gov.sandia.seme.util.ControllerImpl instance = new ControllerImpl();
        instance.stopExecution();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    private class ControllerImpl extends gov.sandia.seme.util.ControllerImpl {

        @Override
        public Descriptor getConfiguration() {
            return null;
        }

        @Override
        public void loadState() {
        }

        @Override
        public void run() {
        }

        @Override
        public void saveState() {
        }
    }

}
