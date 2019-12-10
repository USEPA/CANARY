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

import gov.sandia.seme.util.DummyGenericConnection;
import gov.sandia.seme.util.DummyInputConnection;
import gov.sandia.seme.util.DummyModelConnection;
import gov.sandia.seme.util.DummyOutputConnection;
import gov.sandia.seme.util.IntegerStep;
import java.util.ArrayList;
import java.util.HashMap;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class MessageRouterTest {

    MessageRouter instance;

    public MessageRouterTest() {
    }

    @BeforeClass
    public static void setUpClass() {
    }

    @AfterClass
    public static void tearDownClass() {
    }

    @Before
    public void setUp() {
        this.instance = new MessageRouter();
    }

    @After
    public void tearDown() {
    }

    /**
     * Test of MessageRouter#addNode and removeNode methods.
     */
    @Test
    public void testAddAndRemoveNode() {
        System.out.println("Test Node Insertion and Deletion");

        //Test null node. Will error out if not trapped.
        System.out.println(" Generating test nodes...");
        Messagable node = null;
        Messagable node1 = new DummyGenericConnection("DummyGenericConnection01",
                0);
        Messagable node2 = new DummyGenericConnection("DummyGenericConnection02",
                0);

        System.out.println("  Current node count: " + instance.nodeCount());
        System.out.println(
                " Attempting insertion of null node (does not insert, does not throw an exception)...");
        instance.addNode(node);
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 0);

        //Test insertion of generic nodes.
        System.out.println(" Attempting insertion of generic nodes 1 and 2...");
        instance.addNode(node1);
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 1);
        assertTrue(instance.containsNode(node1));
        instance.addNode(node2);
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 2);
        assertTrue(instance.containsNode(node2));

        //Test duplicate insertion of generic node.
        System.out.println(
                " Attempting duplicate insertion of generic node 1 (does not insert, does not throw an exception)...");
        instance.addNode(node1);
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 2);
        assertTrue(instance.containsNode(node1));

        //Test removal of generic nodes.
        System.out.println(" Attempting removal of generic nodes 1 and 2...");
        instance.removeNode(node1.getName());
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 1);
        assertFalse(instance.containsNode(node1));
        instance.removeNode(node2.getName());
        System.out.println("  Current node count: " + instance.nodeCount());
        assertEquals(instance.nodeCount(), 0);
        assertFalse(instance.containsNode(node2));

        //Test removal of nonexistent node.
        System.out.println(" Attempting removal of nonexistent node...");
        instance.removeNode(node1.getName());
        assertEquals(instance.nodeCount(), 0);
        System.out.println("  Current node count: " + instance.nodeCount());

        System.out.println(" Attempting removal of null node...");
        instance.removeNode(null);
        assertEquals(instance.nodeCount(), 0);
        System.out.println("  Current node count: " + instance.nodeCount());

        ///! @bug What about re-insertion of a node following deletion? Should this be allowed?
    }

    /**
     * Test of MessageRouter#clearRoutes method.
     */
    @Test
    public void testClearRoutes() {
        System.out.println("Test Route Clearing");
        System.out.println("  Generating nodes...");
        Messagable node1 = new DummyGenericConnection("Node01", 0);
        Messagable node2 = new DummyGenericConnection("Node02", 0);
        Messagable node3 = new DummyGenericConnection("Node03", 0);
        node2.addConsumes("Node01");
        node3.addConsumes("Node02");
        System.out.println("  Current number of routes: " + instance.routeSize());
        assertEquals(0, instance.routeSize());
        System.out.println("  Registering nodes with MessageRouter...");
        try {
            instance.register(node1);
            instance.register(node2);
            instance.register(node3);
        } catch (Exception e) {
            System.out.println("Failed to register nodes. " + e.toString());
            fail();
        }
        System.out.println("  Current number of routes: " + instance.routeSize());
        assertEquals(2, instance.routeSize());
        System.out.println("  Attempting to clear routes...");
        instance.clearRoutes();
        System.out.println("  Current number of routes: " + instance.routeSize());
        assertEquals(0, instance.routeSize());
    }

    /**
     * Test of MessageRouter#setIterations and getIterations methods.
     */
    @Test
    public void testIterations() {
        System.out.println("Test Iteration Counters");
        long iterations = 1000;
        instance.setIterations(iterations);
        assertEquals(iterations, instance.getIterations());
    }

    /**
     * Test of MessageRouter#setPauseDelay and getPauseDelay methods.
     */
    @Test
    public void testPauseDelay() {
        System.out.println("Testing Pause Delay");
        int pauseDelay = 500;
        instance.setPauseDelay(pauseDelay);
        assertEquals(pauseDelay, instance.getPauseDelay());
    }

    /**
     * Test of MessageRouter#getRouterName and setRouterName methods.
     */
    @Test
    public void testRouterNaming() {
        System.out.println("Router Naming Tests");
        String routerName = "NEW ROUTER";
        instance.setRouterName(routerName);
        assertEquals(routerName, instance.getRouterName());
    }

    /**
     * Test the pause methods of class MessageRouter.
     */
    @Test
    public void testIsPaused() {
        System.out.println("Pause System Test");
        instance.pause();
        assertTrue(instance.isPaused());
        instance.unpause();
        assertFalse(instance.isPaused());
    }

    /**
     * Test the message routing methods routeMessageFromNode,
     * routeMessageFromNodes, and routeMessageToNodes.
     */
    @Test
    public void testMessageRouting() {
        System.out.println("Message Routing Test");
        //String name = "";
        System.out.println("  Generating nodes...");
        DummyGenericConnection node1 = new DummyGenericConnection("Node01", 0);
        DummyGenericConnection node2 = new DummyGenericConnection("Node02", 0);
        DummyGenericConnection node3 = new DummyGenericConnection("Node03", 0);
        node2.addConsumes("Node01");
        node3.addConsumes("Node02");
        System.out.println("  Current number of routes: " + instance.routeSize());
        assertEquals(0, instance.routeSize());
        System.out.println("  Registering nodes with MessageRouter...");
        try {
            instance.register(node1);
            instance.register(node2);
            instance.register(node3);
        } catch (Exception e) {
            System.out.println("Failed to register nodes. " + e.toString());
            fail();
        }
        System.out.println("  Current number of routes: " + instance.routeSize());
        assertEquals(2, instance.routeSize());

        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        node1.generateCounterMessage();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        node1.moveInboxToOutbox();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Attempt routing from Node 1 to Node 2
        System.out.println("  Routing message from n1 to n2...");
        instance.routeMessageFromNode("Node01");
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Verify current state.
        assertEquals(0, node1.getInboxSize());
        assertEquals(0, node1.getOutboxSize());
        assertEquals(1, node2.getInboxSize());
        assertEquals(0, node2.getOutboxSize());
        assertEquals(0, node3.getInboxSize());
        assertEquals(0, node3.getOutboxSize());

        node2.moveInboxToOutbox();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Attempt routing from Node 2 to Node 3
        System.out.println("  Routing message from n2 to n3...");
        instance.routeMessageFromNode("Node02");
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Verify current state.
        assertEquals(0, node1.getInboxSize());
        assertEquals(0, node1.getOutboxSize());
        assertEquals(0, node2.getInboxSize());
        assertEquals(0, node2.getOutboxSize());
        assertEquals(1, node3.getInboxSize());
        assertEquals(0, node3.getOutboxSize());

        node1.clearBoxes();
        node2.clearBoxes();
        node3.clearBoxes();

        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        node1.generateCounterMessage();
        node2.generateCounterMessage();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        node1.moveInboxToOutbox();
        node2.moveInboxToOutbox();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        System.out.println("  Adding additional route from Node01 to Node03");
        //Test routing from multiple nodes.
        instance.routeMessageFromNodes();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Verify current state.
        assertEquals(0, node1.getInboxSize());
        assertEquals(0, node1.getOutboxSize());
        assertEquals(1, node2.getInboxSize());
        assertEquals(0, node2.getOutboxSize());
        assertEquals(1, node3.getInboxSize());
        assertEquals(0, node3.getOutboxSize());

        node1.clearBoxes();
        node2.clearBoxes();
        node3.clearBoxes();

        System.out.println("  Routing one message to multiple inboxes...");
        this.instance = new MessageRouter();
        node1.generateCounterMessage();
        node2.generateCounterMessage();
        node3.generateCounterMessage();

        //Move messages to outboxes.
        node1.moveInboxToOutbox();
        node2.moveInboxToOutbox();
        node3.moveInboxToOutbox();

        //Update the routes.
        node3.addConsumes("Node01");
        //node3.addConsumes("Node02");

        try {
            instance.register(node1);
            instance.register(node2);
            instance.register(node3);
        } catch (Exception e) {
            System.out.println("Failed to reregister nodes. " + e.toString());
            fail();
        }
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        instance.routeMessageFromNodes();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        node2.moveInboxToOutbox();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        instance.routeMessageFromNodes();
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Verify current state.
        assertEquals(0, node1.getInboxSize());
        assertEquals(0, node1.getOutboxSize());
        assertEquals(0, node2.getInboxSize());
        assertEquals(0, node2.getOutboxSize());
        assertEquals(3, node3.getInboxSize());
        assertEquals(0, node3.getOutboxSize());

        //RouteMessageToNodes
        System.out.println("  Route Message To Nodes Test");
        node1.clearBoxes();
        node2.clearBoxes();
        node3.clearBoxes();
        HashMap<String, Integer> cntr = new HashMap();
        int value = 7;
        cntr.put("handmade", value);
        Message msg = new Message(MessageType.VALUE, "Router", cntr);
        msg.setStep(new IntegerStep(0, 1, value, null));
        ArrayList destinations = new ArrayList<String>();
        destinations.add("Node01");
        destinations.add("Node02");
        destinations.add("Node03");
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());
        instance.routeMessageToNodes(msg, destinations);
        System.out.println("   " + node1.reportBoxSize() + " " + node2.reportBoxSize() + " " + node3.reportBoxSize());

        //Verify current state.
        assertEquals(1, node1.getInboxSize());
        assertEquals(0, node1.getOutboxSize());
        assertEquals(1, node2.getInboxSize());
        assertEquals(0, node2.getOutboxSize());
        assertEquals(1, node3.getInboxSize());
        assertEquals(0, node3.getOutboxSize());
    }

    /**
     * Test of MessageRouter#register and MessageRouter#deregister and
     * registered connection list retrieval methods of class MessageRouter.
     */
    @Test
    public void testRegisterDeregister() throws Exception {
        System.out.println("Testing Registration and Deregistration.");
        Messagable inputnode, outputnode, modelnode, genericnode, node;

        System.out.println("  Generating dummy nodes.");

        inputnode = new DummyInputConnection("DummyInputConnection01", 0);
        outputnode = new DummyOutputConnection("DummyOutputConnection01", 0);
        modelnode = new DummyModelConnection("DummyModelConnection01", 0);
        genericnode = new DummyGenericConnection("DummyGenericConnection01", 0);
        node = null;

        //Attempt to add a connection of each type.
        //Test for connections currently in router.
        System.out.println(" Verifying that system does not contain nodes...");

        //Test inputconnection
        System.out.println(
                "  System Contains Dummy Input Connection: " + instance.getRegisteredInputConnections().contains(
                        inputnode));
        System.out.println(
                "  System Contains Dummy Output Connection: " + instance.getRegisteredOutputConnections().contains(
                        outputnode));
        System.out.println(
                "  System Contains Dummy Model Connection: " + instance.getRegisteredModels().contains(
                        modelnode));
        System.out.println(
                "  System Contains Dummy Generic Connection: " + instance.getRegisteredUnknownNodes().contains(
                        genericnode));

        System.out.println(" Checking Node Count...");
        int icc = instance.getRegisteredInputConnections().size();
        int occ = instance.getRegisteredOutputConnections().size();
        int mcc = instance.getRegisteredModels().size();
        int gcc = instance.getRegisteredUnknownNodes().size();

        System.out.println("  Input Connection Count:   " + icc);
        System.out.println("  Output Connection Count:  " + occ);
        System.out.println("  Model Connection Count:   " + mcc);
        System.out.println("  Generic Connection Count: " + gcc);

        //Test Assertions
        assertFalse(instance.getRegisteredInputConnections().contains(
                inputnode));
        assertFalse(instance.getRegisteredOutputConnections().contains(
                outputnode));
        assertFalse(instance.getRegisteredModels().contains(
                modelnode));
        assertFalse(instance.getRegisteredUnknownNodes().contains(genericnode));

        //Add the nodes to the router.
        System.out.println(" Adding Dummy Nodes...");
        instance.register(inputnode);
        instance.register(outputnode);
        instance.register(modelnode);
        instance.register(genericnode);

        //Test for connections currently in router.
        System.out.println(" Verifying that system contains nodes...");
        System.out.println(
                "  System Contains Dummy Input Connection: " + instance.getRegisteredInputConnections().contains(
                        inputnode));
        System.out.println(
                "  System Contains Dummy Output Connection: " + instance.getRegisteredOutputConnections().contains(
                        outputnode));
        System.out.println(
                "  System Contains Dummy Model Connection: " + instance.getRegisteredModels().contains(
                        modelnode));
        System.out.println(
                "  System Contains Dummy Generic Connection: " + instance.getRegisteredUnknownNodes().contains(
                        genericnode));

        //Checking node count.
        System.out.println(" Checking Node Count...");
        icc = instance.getRegisteredInputConnections().size();
        occ = instance.getRegisteredOutputConnections().size();
        mcc = instance.getRegisteredModels().size();
        gcc = instance.getRegisteredUnknownNodes().size();

        System.out.println("  Input Connection Count:   " + icc);
        System.out.println("  Output Connection Count:  " + occ);
        System.out.println("  Model Connection Count:   " + mcc);
        System.out.println("  Generic Connection Count: " + gcc);

        //Add duplicate nodes to the router.
        System.out.println(" Adding Duplicate Nodes...");
        try {
            try {
                instance.register(inputnode);
                System.out.println(
                        "  Failed to catch duplicate InputConnection insertion.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println(
                        "  Caught duplicate InputConnection insertion.");
            }
            try {
                instance.register(outputnode);
                System.out.println(
                        "  Failed to catch duplicate OutputConnection insertion.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println(
                        "  Caught duplicate OutputConnection insertion.");
            }
            try {
                instance.register(modelnode);
                System.out.println(
                        "  Failed to catch duplicate ModelConnection insertion.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println(
                        "  Caught duplicate ModelConnection insertion.");
            }
            try {
                instance.register(genericnode);
                System.out.println(
                        "  Failed to catch duplicate generic node insertion.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println("  Caught duplicate generic node insertion.");
            }

        } catch (Exception e) {
            System.out.println(
                    "  An error occurred during the duplicate node insertion test.");
            fail();
        }

        System.out.println(" Checking Node Count...");
        icc = instance.getRegisteredInputConnections().size();
        occ = instance.getRegisteredOutputConnections().size();
        mcc = instance.getRegisteredModels().size();
        gcc = instance.getRegisteredUnknownNodes().size();

        System.out.println("  Input Connection Count:   " + icc);
        System.out.println("  Output Connection Count:  " + occ);
        System.out.println("  Model Connection Count:   " + mcc);
        System.out.println("  Generic Connection Count: " + gcc);

        //Test Assertions
        assertTrue(instance.getRegisteredInputConnections().contains(
                inputnode));
        assertTrue(instance.getRegisteredOutputConnections().contains(
                outputnode));
        assertTrue(instance.getRegisteredModels().contains(
                modelnode));
        assertTrue(instance.getRegisteredUnknownNodes().contains(genericnode));

        //Remove the nodes to the router.
        System.out.println(" Removing Dummy Nodes...");
        instance.deregister(inputnode);
        instance.deregister(outputnode);
        instance.deregister(modelnode);
        instance.deregister(genericnode);

        //Test inputconnection
        System.out.println(
                "  System Contains Dummy Input Connection: " + instance.getRegisteredInputConnections().contains(
                        inputnode));
        System.out.println(
                "  System Contains Dummy Output Connection: " + instance.getRegisteredOutputConnections().contains(
                        outputnode));
        System.out.println(
                "  System Contains Dummy Model Connection: " + instance.getRegisteredModels().contains(
                        modelnode));
        System.out.println(
                "  System Contains Dummy Generic Connection: " + instance.getRegisteredUnknownNodes().contains(
                        genericnode));

        //Checking node count.
        System.out.println(" Checking Node Count...");
        icc = instance.getRegisteredInputConnections().size();
        occ = instance.getRegisteredOutputConnections().size();
        mcc = instance.getRegisteredModels().size();
        gcc = instance.getRegisteredUnknownNodes().size();

        System.out.println("  Input Connection Count:   " + icc);
        System.out.println("  Output Connection Count:  " + occ);
        System.out.println("  Model Connection Count:   " + mcc);
        System.out.println("  Generic Connection Count: " + gcc);

        //Test Assertions
        assertFalse(instance.getRegisteredInputConnections().contains(
                inputnode));
        assertFalse(instance.getRegisteredOutputConnections().contains(
                outputnode));
        assertFalse(instance.getRegisteredModels().contains(
                modelnode));
        assertFalse(instance.getRegisteredUnknownNodes().contains(genericnode));

        //Attempt to remove node that is not in router.
        System.out.println(" Attempting to remove nonexistent nodes...");

        try {
            //Attempt nonexistent InputConnection node removal.
            try {
                instance.deregister(inputnode);
                System.out.println(
                        "  Failed to catch nonexistent InputConnection removal.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println(
                        "  Caught nonexistent InputConnection removal.");
            }

            //Attempt nonexistent OutputConnection node removal.
            try {
                instance.deregister(outputnode);
                System.out.println(
                        "  Failed to catch nonexistent OutputConnection removal.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println(
                        "  Caught nonexistent OutputConnection removal.");
            }

            //Attempt nonexistant ModelConnection node removal.
            try {
                instance.deregister(modelnode);
                System.out.println(
                        "  Failed to catch nonexistent ModelConnection removal.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println("  Caught  ModelConnection removal.");
            }

            //Attempt nonexistant Generic node removal.
            try {
                instance.deregister(genericnode);
                System.out.println(
                        "  Failed to catch generic connection removal.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println("  Caught generic connection removal.");
            }
            //Test null pointer
            //Trap a failure to register a null.
            try {
                instance.register(node);
                System.out.println("  Failed to catch null pointer insertion.");
                fail();
            } catch (RouterRegistrationException e) {
                //This is expected.
                System.out.println("  Caught null pointer insertion.");
            }
        } catch (Exception e) {
            System.out.println(
                    "  An error occurred during the nonexistent node removal and null pointer tests.");
            fail();
        }

        //Checking node count.
        System.out.println(" Checking Node Count...");
        icc = instance.getRegisteredInputConnections().size();
        occ = instance.getRegisteredOutputConnections().size();
        mcc = instance.getRegisteredModels().size();
        gcc = instance.getRegisteredUnknownNodes().size();

        System.out.println("  Input Connection Count:   " + icc);
        System.out.println("  Output Connection Count:  " + occ);
        System.out.println("  Model Connection Count:   " + mcc);
        System.out.println("  Generic Connection Count: " + gcc);
    }

}
