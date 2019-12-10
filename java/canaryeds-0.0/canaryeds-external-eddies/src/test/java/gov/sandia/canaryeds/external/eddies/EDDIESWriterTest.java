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

import gov.sandia.seme.framework.Step;
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
public class EDDIESWriterTest {
    
    public EDDIESWriterTest() {
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
     * Test of consumeMessagesAndWriteOutput method, of class EDDIESWriter.
     */
    @Test
    public void testConsumeMessagesAndWriteOutput_0args() {
        System.out.println("consumeMessagesAndWriteOutput");
        EDDIESWriter instance = new EDDIESWriter();
        int expResult = 0;
        int result = instance.consumeMessagesAndWriteOutput();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of consumeMessagesAndWriteOutput method, of class EDDIESWriter.
     */
    @Test
    public void testConsumeMessagesAndWriteOutput_Step() {
        System.out.println("consumeMessagesAndWriteOutput");
        Step stepPar = null;
        EDDIESWriter instance = new EDDIESWriter();
        int expResult = 0;
        int result = instance.consumeMessagesAndWriteOutput(stepPar);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of isOutputConstrainedToCurrentStep method, of class EDDIESWriter.
     */
    @Test
    public void testIsOutputConstrainedToCurrentStep() {
        System.out.println("isOutputConstrainedToCurrentStep");
        EDDIESWriter instance = new EDDIESWriter();
        boolean expResult = false;
        boolean result = instance.isOutputConstrainedToCurrentStep();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of setOutputConstrainedToCurrentStep method, of class EDDIESWriter.
     */
    @Test
    public void testSetOutputConstrainedToCurrentStep() {
        System.out.println("setOutputConstrainedToCurrentStep");
        boolean constrain = false;
        EDDIESWriter instance = new EDDIESWriter();
        instance.setOutputConstrainedToCurrentStep(constrain);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of getDestinationLocation method, of class EDDIESWriter.
     */
    @Test
    public void testGetDestinationLocation() {
        System.out.println("getDestinationLocation");
        EDDIESWriter instance = new EDDIESWriter();
        String expResult = "";
        String result = instance.getDestinationLocation();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of setDestinationLocation method, of class EDDIESWriter.
     */
    @Test
    public void testSetDestinationLocation() {
        System.out.println("setDestinationLocation");
        String location = "";
        EDDIESWriter instance = new EDDIESWriter();
        instance.setDestinationLocation(location);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }
    
}
