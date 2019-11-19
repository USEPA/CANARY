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

import java.util.HashMap;
import java.util.concurrent.Callable;
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
public class ComponentsTest {

    public ComponentsTest() {
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
     * Test of Components#newController method.
     */
    @Test
    public void testNewController() throws Exception {
        System.out.println("newController");
        Descriptor desc = null;
        Components instance = new Components();
        Controller expResult = null;
        Controller result = instance.newController(desc);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#newMessagable method.
     */
    @Test
    public void testNewMessagable() throws Exception {
        System.out.println("newMessagable");
        Descriptor desc = null;
        Components instance = new Components();
        Messagable expResult = null;
        Messagable result = instance.newMessagable(desc);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getChannelDescriptors method.
     */
    @Test
    public void testGetChannelDescriptors() throws Exception {
        System.out.println("getChannelDescriptors");
        HashMap config = null;
        Components instance = new Components();
        HashMap<String, Descriptor> expResult = null;
        HashMap<String, Descriptor> result = instance.getChannelDescriptors(
                config);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getMessagableDescriptors method.
     */
    @Test
    public void testGetConnectionDescriptors() throws Exception {
        System.out.println("getConnectionDescriptors");
        HashMap config = null;
        Components instance = new Components();
        HashMap<String, Descriptor> expResult = null;
        HashMap<String, Descriptor> result = instance.getConnectionDescriptors(
                config);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getControllerImplDescriptors method.
     */
    @Test
    public void testGetControllerDescriptors() throws Exception {
        System.out.println("getControllerDescriptors");
        HashMap config = null;
        Components instance = new Components();
        HashMap<String, Descriptor> expResult = null;
        HashMap<String, Descriptor> result = instance.getControllerDescriptors(
                config);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#newInputTask method.
     */
    @Test
    public void testNewInputTask() {
        System.out.println("newInputTask");
        InputConnection conn = null;
        Callable<String> expResult = null;
        Callable<String> result = Components.newInputTask(conn);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#newOutputTask method.
     */
    @Test
    public void testNewOutputTask() {
        System.out.println("newOutputTask");
        OutputConnection conn = null;
        Callable<String> expResult = null;
        Callable<String> result = Components.newOutputTask(conn);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#newModelTask method.
     */
    @Test
    public void testNewModelTask() {
        System.out.println("newModelTask");
        ModelConnection model = null;
        Callable<String> expResult = null;
        Callable<String> result = Components.newModelTask(model);
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getResultMessageDataKeys method.
     */
    @Test
    public void testGetResultMessageDataKeys() {
        System.out.println("getResultMessageDataKeys");
        Components instance = new Components();
        String[] expResult = null;
        String[] result = instance.getResultMessageDataKeys();
        assertArrayEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getValueMessageDataKeys method.
     */
    @Test
    public void testGetValueMessageDataKeys() {
        System.out.println("getValueMessageDataKeys");
        Components instance = new Components();
        String[] expResult = null;
        String[] result = instance.getValueMessageDataKeys();
        assertArrayEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Components#getControlMessageDataKeys method.
     */
    @Test
    public void testGetControlMessageDataKeys() {
        System.out.println("getControlMessageDataKeys");
        Components instance = new Components();
        String[] expResult = null;
        String[] result = instance.getControlMessageDataKeys();
        assertArrayEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

}
