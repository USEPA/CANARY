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

import java.util.ArrayList;
import java.util.HashMap;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;

@Ignore
public class DescriptorTest {

    public DescriptorTest() {
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
     * Test of Descriptor#getGeneratingClass method.
     */
    @Test
    public void testGetGeneratingClass() {
        System.out.println("getGeneratingClass");
        Descriptor instance = new Descriptor();
        String expResult = "";
        String result = instance.getGeneratingClass();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setGeneratingClass method.
     */
    @Test
    public void testSetGeneratingClass() {
        System.out.println("setGeneratingClass");
        String generatingClass = "";
        Descriptor instance = new Descriptor();
        instance.setGeneratingClass(generatingClass);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getComponentType method.
     */
    @Test
    public void testGetComponentType() {
        System.out.println("getComponentType");
        Descriptor instance = new Descriptor();
        String expResult = "";
        String result = instance.getComponentType();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setComponentType method.
     */
    @Test
    public void testSetComponentType() {
        System.out.println("setComponentType");
        String componentType = "";
        Descriptor instance = new Descriptor();
        instance.setComponentType(componentType);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#addToConsumesTags method.
     */
    @Test
    public void testAddToConsumesTags_String() {
        System.out.println("addToConsumesTags");
        String tag = "";
        Descriptor instance = new Descriptor();
        instance.addToConsumesTags(tag);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#addToConsumesTags method.
     */
    @Test
    public void testAddToConsumesTags_ArrayList() {
        System.out.println("addToConsumesTags");
        ArrayList<String> list = null;
        Descriptor instance = new Descriptor();
        instance.addToConsumesTags(list);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#addToProducesTags method.
     */
    @Test
    public void testAddToProducesTags_String() {
        System.out.println("addToProducesTags");
        String tag = "";
        Descriptor instance = new Descriptor();
        instance.addToProducesTags(tag);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#addToProducesTags method.
     */
    @Test
    public void testAddToProducesTags_ArrayList() {
        System.out.println("addToProducesTags");
        ArrayList<String> list = null;
        Descriptor instance = new Descriptor();
        instance.addToProducesTags(list);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#addToRequiresComponents method.
     */
    @Test
    public void testAddToRequiresComponents() {
        System.out.println("addToRequiresComponents");
        Descriptor obj = null;
        Descriptor instance = new Descriptor();
        instance.addToRequiresComponents(obj);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#clearRequiresComponents method.
     */
    @Test
    public void testClearRequiresComponents() {
        System.out.println("clearRequiresComponents");
        Descriptor instance = new Descriptor();
        instance.clearRequiresComponents();
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getClassName method.
     */
    @Test
    public void testGetClassName() {
        System.out.println("getClassName");
        Descriptor instance = new Descriptor();
        String expResult = "";
        String result = instance.getClassName();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setClassName method.
     */
    @Test
    public void testSetClassName() {
        System.out.println("setClassName");
        String className = "";
        Descriptor instance = new Descriptor();
        instance.setClassName(className);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getConsumesTags method.
     */
    @Test
    public void testGetConsumesTags() {
        System.out.println("getConsumesTags");
        Descriptor instance = new Descriptor();
        ArrayList<String> expResult = null;
        ArrayList<String> result = instance.getConsumesTags();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setConsumesTags method.
     */
    @Test
    public void testSetConsumesTags() {
        System.out.println("setConsumesTags");
        ArrayList<String> consumesTags = null;
        Descriptor instance = new Descriptor();
        instance.setConsumesTags(consumesTags);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getName method.
     */
    @Test
    public void testGetName() {
        System.out.println("getName");
        Descriptor instance = new Descriptor();
        String expResult = "";
        String result = instance.getName();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setName method.
     */
    @Test
    public void testSetName() {
        System.out.println("setName");
        String name = "";
        Descriptor instance = new Descriptor();
        instance.setName(name);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getOptions method.
     */
    @Test
    public void testGetOptions() {
        System.out.println("getOptions");
        Descriptor instance = new Descriptor();
        HashMap expResult = null;
        HashMap result = instance.getOptions();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setOptions method.
     */
    @Test
    public void testSetOptions() {
        System.out.println("setOptions");
        HashMap options = null;
        Descriptor instance = new Descriptor();
        instance.setOptions(options);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getProducesTags method.
     */
    @Test
    public void testGetProducesTags() {
        System.out.println("getProducesTags");
        Descriptor instance = new Descriptor();
        ArrayList<String> expResult = null;
        ArrayList<String> result = instance.getProducesTags();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setProducesTags method.
     */
    @Test
    public void testSetProducesTags() {
        System.out.println("setProducesTags");
        ArrayList<String> producesTags = null;
        Descriptor instance = new Descriptor();
        instance.setProducesTags(producesTags);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getRequiresComponents method.
     */
    @Test
    public void testGetRequiresComponents() {
        System.out.println("getRequiresComponents");
        Descriptor instance = new Descriptor();
        ArrayList<Descriptor> expResult = null;
        ArrayList<Descriptor> result = instance.getRequiresComponents();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setRequiresComponents method.
     */
    @Test
    public void testSetRequiresComponents() {
        System.out.println("setRequiresComponents");
        ArrayList<Descriptor> requires = null;
        Descriptor instance = new Descriptor();
        instance.setRequiresComponents(requires);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getTag method.
     */
    @Test
    public void testGetTag() {
        System.out.println("getTag");
        Descriptor instance = new Descriptor();
        String expResult = "";
        String result = instance.getTag();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setTag method.
     */
    @Test
    public void testSetTag() {
        System.out.println("setTag");
        String tag = "";
        Descriptor instance = new Descriptor();
        instance.setTag(tag);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#getType method.
     */
    @Test
    public void testGetType() {
        System.out.println("getType");
        Descriptor instance = new Descriptor();
        ComponentType expResult = null;
        ComponentType result = instance.getType();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setType method.
     */
    @Test
    public void testSetType_DescriptorComponentType() {
        System.out.println("setType");
        ComponentType type = null;
        Descriptor instance = new Descriptor();
        instance.setType(type);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setType method.
     */
    @Test
    public void testSetType_String() {
        System.out.println("setType");
        String type = "";
        Descriptor instance = new Descriptor();
        instance.setType(type);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#isUsed method.
     */
    @Test
    public void testIsUsed() {
        System.out.println("isUsed");
        Descriptor instance = new Descriptor();
        boolean expResult = false;
        boolean result = instance.isUsed();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#setUsed method.
     */
    @Test
    public void testSetUsed() {
        System.out.println("setUsed");
        boolean used = false;
        Descriptor instance = new Descriptor();
        instance.setUsed(used);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#removeFromConsumesTags method.
     */
    @Test
    public void testRemoveFromConsumesTags() {
        System.out.println("removeFromConsumesTags");
        String tag = "";
        Descriptor instance = new Descriptor();
        instance.removeFromConsumesTags(tag);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#removeFromProducesTags method.
     */
    @Test
    public void testRemoveFromProducesTags_String() {
        System.out.println("removeFromProducesTags");
        String tag = "";
        Descriptor instance = new Descriptor();
        instance.removeFromProducesTags(tag);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of Descriptor#removeFromProducesTags method.
     */
    @Test
    public void testRemoveFromProducesTags_ArrayList() {
        System.out.println("removeFromProducesTags");
        ArrayList<String> list = null;
        Descriptor instance = new Descriptor();
        instance.removeFromProducesTags(list);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

}
