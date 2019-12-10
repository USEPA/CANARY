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

import gov.sandia.seme.framework.Components;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.MessagableImpl;
import java.util.ArrayList;
import java.util.concurrent.PriorityBlockingQueue;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import org.junit.*;

/**
 * Test the implementation of the MessageableImpl class.
 * Utilizes the dummy connection for implementation testing.
 * @author nprackl
 */
public class MessageableImplTest {
    
    MessagableImpl instance;
    
    public MessageableImplTest() {
    }

    @BeforeClass
    public static void setUpClass() {
    }

    @AfterClass
    public static void tearDownClass() {
    }

    @Before
    public void setUp() {
      instance = new DummyGenericConnection("TEST", 0);
    }

    @After
    public void tearDown() {
    }

    /**
     * Test of MessagableImpl#setComponentFactory and MessagableImpl#getComponentFactory methods.
     */
    @Test
    public void testComponentFactory() {
        //ToDo: Do we need to test anything else here?
        
        System.out.println("Test Component Factory");
        Components componentFactory = new Components();
        instance.setComponentFactory(componentFactory);
        assertEquals(instance.componentFactory, componentFactory);
        assertEquals(instance.getComponentFactory(), componentFactory);
    }


    /**
     * Test of MessagableImpl#initialize method.
     */
    @Ignore
    @Test
    public void testInitialize() throws Exception {
        System.out.println("initialize");
        instance.initialize();
        // TODO Initialization is not supported yet in the implementation.
    }

    /**
     * Test of MessagableImpl#NullStepOkay methods, of class MEssagableImpl.
     */
    @Test
    public void testNullStepOkay(){
        System.out.println("Test NullStepOkay");
        System.out.println(" False Case");
        instance.setNullStepOkay(false);
        assertFalse(instance.nullStepOkay);
        System.out.println(" True Case");
        instance.setNullStepOkay(true);
        assertTrue(instance.nullStepOkay);
    }
    
    /**
     * Test the prerequisites functions of class MessagableImpl.
     */
    @Ignore
    @Test
    public void testPrerequisites(){
        //ToDo: Fixme. Are we handling the null case properly here?
        ArrayList<String> prerequisites = null;
        /*System.out.println("Set and Get Prerequisites (null case)");
        instance.setPrerequisites(prerequisites);        
        ArrayList<String> result = instance.getPrerequisites();
        assertEquals(prerequisites, result);*/
        
        System.out.println(" Set and Get Prerequisites (value case)");
        prerequisites = new ArrayList();
        prerequisites.add("TEST1");
        prerequisites.add("TEST2");
        
        ArrayList<String> prerequisites2 = new ArrayList();
        prerequisites2.add("TEST1");
        prerequisites2.add("TEST2");
        assertEquals(prerequisites, prerequisites2);
        
        System.out.println(" Verify list to add.");
        instance.setPrerequisites(prerequisites);
        assertEquals(prerequisites, instance.getPrerequisites());
        
        System.out.println(" Add Prerequisites (new value case)");
        instance.addPrerequisite("TEST3");
        prerequisites2.add("TEST3");
        assertEquals(prerequisites2, instance.getPrerequisites());
        
        System.out.println("Remove Prerequisites (single value case)");
        instance.removePrerequisite("TEST3");
        prerequisites2.remove("TEST3");
        assertEquals(prerequisites2, instance.getPrerequisites());      
        
        System.out.println(" Add Prerequisites (duplicate value case)");
        instance.addPrerequisite("TEST2");
        assertEquals(prerequisites2, instance.getPrerequisites());
  
        System.out.println(" Add Prerequisites (null add)");
        instance.addPrerequisite(null);        
        assertEquals(prerequisites2, instance.getPrerequisites());
        
        System.out.println(" Remove Prerequisites (null remove)");
        instance.removePrerequisite(null);
        assertEquals(prerequisites2, instance.getPrerequisites());
    }

    /**
     * Test of MessagableImpl#setName and getName methods.
     */
    @Test
    public void testSetGetName() {
        System.out.println("Set and Get Name");
        String name = "SYSTEM01";
        instance.setName(name);
        assertEquals(instance.getName(), name);
    }

    /**
     * Test of MessagableImpl#addMessageToInbox method.
     */
    @Test
    public void testAddMessageToInbox() {
        System.out.println("Add Messages to Inbox");
        DummyGenericConnection d = new DummyGenericConnection("test", 0);
        assertEquals(0, instance.inbox.size());
        /*
        System.out.println(" Null insertion verification...");
        Message msg = null;
        instance.addMessageToInbox(msg);
        assertEquals(0, instance.inbox.size());
        */
        System.out.println(" Standard insertion verification...");
        Message msg = d.getCounterMessage();
        instance.addMessageToInbox(msg);
        assertTrue(instance.inbox.contains(msg));
        assertEquals(1, instance.inbox.size());
        
        System.out.println(" Duplicate insertion verification...");
        instance.addMessageToInbox(msg);
        assertEquals(2, instance.inbox.size());
    }
    /**
     * Test of MessagableImpl#setProduces, getProduces, addProduces and removeProduces methods, of class MessageableImpl.
     */
    @Ignore
    @Test
    public void testProduces(){
        //ToDo: Fixme. Are we handling the null case properly here?
        ArrayList<String> produces = null;
        /*System.out.println("Set and Get Produces (null case)");
        instance.setProduces(produces);        
        ArrayList<String> result = instance.getProduces();
        assertEquals(produces, result);*/
        
        System.out.println(" Set and Get Consumes (value case)");
        produces = new ArrayList();
        produces.add("TEST1");
        produces.add("TEST2");
        
        ArrayList<String> produces2 = new ArrayList();
        produces2.add("TEST1");
        produces2.add("TEST2");
        assertEquals(produces, produces2);
        
        System.out.println(" Verify list to add.");
        instance.setProduces(produces);
        assertEquals(produces, instance.getProduces());
        
        System.out.println(" Add Produces (new value case)");
        instance.addProduces("TEST3");
        produces2.add("TEST3");
        assertEquals(produces2, instance.getProduces());
        
        System.out.println("Remove Produces (single value case)");
        instance.removeProduces("TEST3");
        produces2.remove("TEST3");
        assertEquals(produces2, instance.getProduces());      
        
        System.out.println(" Add Produces (duplicate value case)");
        instance.addProduces("TEST2");
        assertEquals(produces2, instance.getProduces());
  
        System.out.println(" Add Produces (null add)");
        instance.addProduces(null);        
        assertEquals(produces2, instance.getProduces());
        
        System.out.println(" Remove Produces (null remove)");
        instance.removeProduces(null);
        assertEquals(produces2, instance.getProduces());
    }
    
    /**
     * Test of MessagableImpl#setConsumes, getConsumes, addConsumes and removeConsumes methods.
     */
    @Ignore
    @Test
    public void testConsumes() {
        
        ArrayList<String> consumes = null;
        System.out.println("Set and Get Consumes (null case)");
        instance.setConsumes(consumes);        
        ArrayList<String> result = instance.getConsumes();
        assertEquals(consumes, result);
        
        System.out.println(" Set and Get Consumes (value case)");
        consumes = new ArrayList();
        consumes.add("TEST1");
        consumes.add("TEST2");
        
        ArrayList<String> consumes2 = new ArrayList();
        consumes2.add("TEST1");
        consumes2.add("TEST2");
        assertEquals(consumes, consumes2);
        
        System.out.println(" Verify list to add.");
        instance.setConsumes(consumes);
        assertEquals(consumes2, instance.getConsumes());
        
        System.out.println(" Add Consumes (new value case)");
        instance.addConsumes("TEST3");
        consumes2.add("TEST3");
        assertEquals(consumes2, instance.getConsumes());
        
        System.out.println("Remove Consumes (single value case)");
        instance.removeConsumes("TEST3");
        consumes2.remove("TEST3");
        assertEquals(consumes2, instance.getConsumes());      
        
        System.out.println(" Add Consumes (duplicate value case)");
        instance.addConsumes("TEST2");
        assertEquals(consumes2, instance.getConsumes());
  
        System.out.println(" Add Consumes (null add)");
        instance.addConsumes(null);        
        assertEquals(consumes2, instance.getConsumes());
        
        System.out.println(" Remove Consumes (null remove)");
        instance.removeConsumes(null);
        assertEquals(consumes2, instance.getConsumes());
    }


    /**
     * Test of MessagableImpl#getInboxHandle method.
     */
    @Test
    public void testGetInboxHandle() {
        System.out.println("getInboxHandle");
        PriorityBlockingQueue expResult = instance.inbox;
        PriorityBlockingQueue result = instance.getInboxHandle();
        assertEquals(expResult, result);
    }

    /**
     * Test of MessagableImpl#getMessageFromOutbox method.
     */
    @Test
    public void testGetMessageFromOutbox() {
        //TODO Check if we need secondary message pull test for empty outbox handling.
        System.out.println("Test Get Message From Outbox");
        DummyGenericConnection d = new DummyGenericConnection("test", 0);
        Message m = d.getCounterMessage();
        
        //Basic test.
        instance.pushMessageToOutbox(m);
        Message result = instance.getMessageFromOutbox();
        assertEquals(m, result);
        
        //Null pull test.
        result = instance.getMessageFromOutbox();
        assertEquals(null, result);
        
    }

    /**
     * Test of MessagableImpl#getOutboxHandle method.
     */
    @Test
    public void testGetOutboxHandle() {
        System.out.println("Test Get Outbox Handle");
        PriorityBlockingQueue result = instance.getOutboxHandle();
        assertEquals(instance.outbox, result);
    }



    /**
     * Test of MessagableImpl#pollMessageFromInbox method.
     */
    @Test
    public void testPollMessageFromInbox_0args() {
        //TODO - Check to see if we even need the null poll test.
        System.out.println("Test Poll Message From Inbox 0 Args");
        DummyGenericConnection d = new DummyGenericConnection("test", 0);
        Message m = d.getCounterMessage();
        
        //Basic test.
        instance.addMessageToInbox(m);
        Message result = instance.pollMessageFromInbox();
        assertEquals(m, result);
        
        //Null poll test.
        result = instance.pollMessageFromInbox();
        assertEquals(null, result);        
    }

    /**
     * Test of MessagableImpl#pushMessageToOutbox method.
     */
    @Test
    public void testPushMessageToOutbox() {
        System.out.println("Test Push Message to Outbox");
        
        //TODO Check if we need special null and duplicate insertion rules.
        
        DummyGenericConnection d = new DummyGenericConnection("test", 0);
        Message m = d.getCounterMessage();
        
        //Basic test.
        instance.pushMessageToOutbox(m);
        assertTrue(instance.outbox.contains(m));
                
        /*
        //Duplicate insertion test.
        int size = instance.outbox.size();
        instance.pushMessageToOutbox(m);
        assertEquals(size, instance.outbox.size());
        
        size = instance.outbox.size();
        //Null Insert Test - is this correct?
        m = null;
        instance.pushMessageToOutbox(m);
        assertEquals(size, instance.outbox.size());
        */
        
    }


    /**
     * Test of MessagableImpl#setCurrentStep method.
     */
    @Test
    public void testCurrentStep() {
        System.out.println("Test Set and Get Current Step");
        //ToDo: Fixme: Do we need null case handling here?
        
        //Step currentStep = null;        
        /*
        System.out.println(" Test Null Case.");
        instance.setCurrentStep(currentStep);
        assertEquals(currentStep, instance.getCurrentStep());
        */
        
        //System.out.println(" Test Value Case.");
        Step currentStep = new IntegerStep(0, 1, 1, null);
        instance.setCurrentStep(currentStep);
        assertEquals(instance.getCurrentStep(), currentStep);
    }

    /**
     * Test of MessagableImpl#configure method.
     */
    @Test
    public void testConfigure() throws ConfigurationException {
        System.out.println("Test Configure");
        
        System.out.println("  Generating Descriptor...");
        Descriptor config = new Descriptor();
        ArrayList<String> producesTags = new ArrayList();
        ArrayList<String> consumesTags = new ArrayList();
        producesTags.add("PA");
        producesTags.add("PB");
        producesTags.add("PC");
        consumesTags.add("CA");
        consumesTags.add("CB");
        consumesTags.add("CC");
        
        //Set values in descriptor.
        config.setName("TESTNAME");
        config.setProducesTags(producesTags);
        config.setConsumesTags(consumesTags);
        
        //Pass values and verify function is working properly.
        System.out.println(" Passing Descriptor to Configuration Script...");
        instance.configure(config);
        
        assertEquals(instance.name, "TESTNAME");
        assertEquals(instance.produces, producesTags);
        assertEquals(instance.consumes, consumesTags);
    }

    /**
     * Test of MessagableImpl#pollMessageFromInbox method.
     */
    @Test
    public void testPollMessageFromInbox_Step() {
        
        //TODO - Need to figure out the best way to test this.
        System.out.println("Poll Message From Inbox Test");

        System.out.println(" Generate Steps...");
        Step step = null;
        Step step2 = new DoubleStep(0.0, 1.0, 10.0, null);
        Step step3 = new DoubleStep(0.0, 1.0, 1.0, null);
        
        Message expResult = null;
        instance.nullStepOkay = false;
        
        //Step is null, null step not okay, return null.
        System.out.println(" Null Step Null Not Okay");
        Message result = instance.pollMessageFromInbox(step);
        assertEquals(expResult, result);
        
        instance.nullStepOkay = true;
        //Else temp null return null.
        System.out.println(" Null Step Null Okay Without Temp");
        result = instance.pollMessageFromInbox(step);
        assertEquals(expResult, result);
        
        DummyGenericConnection d = new DummyGenericConnection("test", 0);
        Message m = d.getCounterMessage();
        m.getStep().setIndex(5);
        instance.inbox.add(m);//
        
        //Else step null return temp.
        System.out.println(" Null Step Null Okay With Temp");
        result = instance.pollMessageFromInbox(step);
        assertEquals(m, result);
        
        //Else compare temp to step.
        System.out.println(" Basic Next Step");
        instance.inbox.add(m);
        result = instance.pollMessageFromInbox(step2);
        assertEquals(m, result);        
        
        //Else return null.
        System.out.println(" Basic Not Next Step");
        instance.inbox.add(m);
        result = instance.pollMessageFromInbox(step3);
        assertEquals(null, result);
    }

    /**
     * Test of MessagableImpl#setBaseStep and getBaseStep methods.
     */
    @Test
    public void testBaseStep(){
        System.out.println("Test Base Step");
        //ToDo: Fixme: Do we need null case handling here?
        
        //Step baseStep = null;        
        /*
        System.out.println(" Test Null Case.");
        instance.setBaseStep(baseStep);
        assertEquals(baseStep, instance.getBaseStep());
        */
        
        //System.out.println(" Test Value Case.");
        Step baseStep = new IntegerStep(0, 1, 1, null);
        instance.setBaseStep(baseStep);
        assertEquals(instance.getBaseStep(), baseStep);

    }

}
