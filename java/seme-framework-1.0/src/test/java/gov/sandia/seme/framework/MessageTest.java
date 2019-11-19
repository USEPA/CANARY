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
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.IntegerStep;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class MessageTest {

    public MessageTest() {
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
     * Test of Message#compareTo method.
     */
    @Test
    public void testCompareTo() {
        System.out.println("compareTo");
        Step step1 = new IntegerStep(0, 3, 15, "#");
        Step step2 = new IntegerStep(0, 3, 18, "#");
        Step step3 = new IntegerStep(0, 3, 21, "#");
        Object arg0 = new Message(MessageType.VALUE, "", null, step2);
        Message instance = new Message(MessageType.VALUE, "", null, step2);
        int expResult = 0;
        int result = instance.compareTo(arg0);
        assertEquals(expResult, result);
        expResult = -1;
        instance = new Message(MessageType.VALUE, "", null, step1);
        result = instance.compareTo(arg0);
        assertEquals(expResult, result);
        expResult = 1;
        instance = new Message(MessageType.VALUE, "", null, step3);
        result = instance.compareTo(arg0);
        assertEquals(expResult, result);
    }

}
