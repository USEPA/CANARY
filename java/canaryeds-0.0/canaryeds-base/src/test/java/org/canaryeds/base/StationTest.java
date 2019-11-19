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
package org.canaryeds.base;

import org.canaryeds.base.Station;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.Step;
import java.util.ArrayList;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;

public class StationTest {

    public StationTest() {
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
     * Test of Station#configure method.
     */
    @Test
    @Ignore
    public void testConfigure() throws ConfigurationException {
        System.out.println("configure");
        Descriptor conf = null;
        Station instance = null;
        instance.configure(conf);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#initialize method.
     */
    @Test
    @Ignore
    public void testInitialize() throws Exception {
        System.out.println("initialize");
        Station instance = null;
        instance.initialize();
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#evaluateModel method.
     */
    @Test
    @Ignore
    public void testEvaluateModel() {
        System.out.println("evaluateModel");
        Station instance = null;
        int expResult = 0;
        int result = instance.evaluateModel();
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#getConfiguration method.
     */
    @Test
    @Ignore
    public void testGetConfiguration() {
        System.out.println("getConfiguration");
        Station instance = null;
        Descriptor expResult = null;
        Descriptor result = instance.getConfiguration();
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#getRecvdStatusForCurrentStep method.
     */
    @Test
    @Ignore
    public void testGetRecvdStatusForCurrentStep() {
        System.out.println("getRecvdStatusForCurrentStep");
        Station instance = null;
        boolean[] expResult = null;
        boolean[] result = instance.getRecvdStatusForCurrentStep();
        //assertArrayEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#setRecvdStatusForCurrentStep method.
     */
    @Test
    @Ignore
    public void testSetRecvdStatusForCurrentStep() {
        System.out.println("setRecvdStatusForCurrentStep");
        boolean[] recvdStatusForCurrentStep = null;
        Station instance = null;
        instance.setRecvdStatusForCurrentStep(recvdStatusForCurrentStep);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#getSynchronizeToTags method.
     */
    @Test
    @Ignore
    public void testGetSynchronizeToTags() {
        System.out.println("getSynchronizeToTags");
        Station instance = null;
        ArrayList<String> expResult = null;
        ArrayList<String> result = instance.getSynchronizeToTags();
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#setSynchronizeToTags method.
     */
    @Test
    @Ignore
    public void testSetSynchronizeToTags() {
        System.out.println("setSynchronizeToTags");
        ArrayList<String> synchronizeToTags = null;
        Station instance = null;
        instance.setSynchronizeToTags(synchronizeToTags);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#pollMessageFromInbox method.
     */
    @Test
    @Ignore
    public void testPollMessageFromInbox() {
        System.out.println("pollMessageFromInbox");
        Step step = null;
        Station instance = null;
        Message expResult = null;
        Message result = instance.pollMessageFromInbox(step);
        assertEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Station#parseStatusCode method.
     */
    @Test
    @Ignore
    public void testParseStatusCode() {
        System.out.println("parseStatusCode");
        int code = 0;
        Station instance = null;
        String[] expResult = null;
        String[] result = instance.parseStatusCode(code);
        assertArrayEquals(expResult, result);
        /// @todo review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

}
