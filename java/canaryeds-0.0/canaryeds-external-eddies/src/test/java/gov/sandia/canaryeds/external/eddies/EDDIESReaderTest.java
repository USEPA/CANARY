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
public class EDDIESReaderTest {
    
    public EDDIESReaderTest() {
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
     * Test of readInputAndProduceMessages method, of class EDDIESReader.
     */
    @Test
    public void testReadInputAndProduceMessages_0args() {
        System.out.println("readInputAndProduceMessages");
        EDDIESReader instance = new EDDIESReader();
        int expResult = 0;
        int result = instance.readInputAndProduceMessages();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of readInputAndProduceMessages method, of class EDDIESReader.
     */
    @Test
    public void testReadInputAndProduceMessages_Step() {
        System.out.println("readInputAndProduceMessages");
        Step stepPar = null;
        EDDIESReader instance = new EDDIESReader();
        int expResult = 0;
        int result = instance.readInputAndProduceMessages(stepPar);
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of isInputConstrainedToCurrentStep method, of class EDDIESReader.
     */
    @Test
    public void testIsInputConstrainedToCurrentStep() {
        System.out.println("isInputConstrainedToCurrentStep");
        EDDIESReader instance = new EDDIESReader();
        boolean expResult = false;
        boolean result = instance.isInputConstrainedToCurrentStep();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of setInputConstrainedToCurrentStep method, of class EDDIESReader.
     */
    @Test
    public void testSetInputConstrainedToCurrentStep() {
        System.out.println("setInputConstrainedToCurrentStep");
        boolean contrain = false;
        EDDIESReader instance = new EDDIESReader();
        instance.setInputConstrainedToCurrentStep(contrain);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of getSourceLocation method, of class EDDIESReader.
     */
    @Test
    public void testGetSourceLocation() {
        System.out.println("getSourceLocation");
        EDDIESReader instance = new EDDIESReader();
        String expResult = "";
        String result = instance.getSourceLocation();
        //assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }

    /**
     * Test of setSourceLocation method, of class EDDIESReader.
     */
    @Test
    public void testSetSourceLocation() {
        System.out.println("setSourceLocation");
        String location = "";
        EDDIESReader instance = new EDDIESReader();
        instance.setSourceLocation(location);
        // TODO review the generated test code and remove the default call to fail.
        //fail("The test case is a prototype.");
    }
    
}
