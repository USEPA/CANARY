/* 
 * Copyright 2014 Sandia Corporation.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation, the U.S.
 * Government retains certain rights in this software.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
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
import java.util.Iterator;
import java.util.concurrent.CopyOnWriteArrayList;
import org.apache.log4j.Logger;

/**
 * Handles the message passing between different Messagable or -Connection
 * objects. The MessageRouter needs to be executed in a
 * java.util.concurrent.ScheduledExecutorService, to ensure that it is
 * run continuously. The router tracks its own number of iterations, and each
 * iteration involves moving all waiting messages in each output queue to the
 * addressed input queue(s). The routing table is created and updated by
 * querying each Messagable's Descriptor object for consumed and produced tags.
 * When a Message is withdrawn from an output queue, the tag is looked up in the
 * routing table to determine which input queues it should be copied into.
 *
 * @htmlonly
 * @author Nathanael Rackley, nprackl
 * @endhtmlonly
 */
public final class MessageRouter implements Runnable {

    private boolean debug = false;
    private static final Logger LOG = Logger.getLogger(MessageRouter.class);
    private int delay = 1;                           //The execution nodes.
    private ArrayList<String> deletedNodes;                   //The list of nodes that have been deleted or removed.
    private long iterations = -1;                        //Iterations variable. Used for external runs and testing.
    private String logfile = "ROUTER.log";
    private boolean messagesWaiting;
    private HashMap<String, Messagable> nodeMap;                //The hash map of names to nodes for quick reference.

    //Here we declare the objects that the MessageRouter will be interacting with.
    private ArrayList<Messagable> nodes;                    //List of control message routes.
    private int pauseDelay = 1000;                       //Standard paused thread millisecond delay.
    private volatile boolean paused = false;					//Flag for currently paused thread or not.
    private String routerName = "ROUTER";                    //SCADA tag or name for MessageRouter.
    private HashMap<String, ArrayList<String>> routes;             //List of input Routes.
    private volatile boolean running;                      //Flag for currently running thread data.
    private ArrayList<InputConnection> inputNodes;
    private ArrayList<OutputConnection> outputNodes;
    private ArrayList<ModelConnection> ModelNodes;
    private ArrayList<Messagable> unknownNodes;

    /**
     * Router Generic empty constructor.
     */
    public MessageRouter() {
        this.nodes = new ArrayList();
        this.deletedNodes = new ArrayList();
        this.nodeMap = new HashMap();
        this.routes = new HashMap();
        this.inputNodes = new ArrayList();
        this.outputNodes = new ArrayList();
        this.ModelNodes = new ArrayList();
        this.unknownNodes = new ArrayList();
    }

    /**
     * Add a node to the router.
     *
     * @param node The node to add to the router.
     */
    public void addNode(Messagable node) {
        if (node == null) {
            //Do nothing upon attempted insertion of null node to MessageRouter.
            LOG.trace("Attempted insertion of null node to MessageRouter.");
        } else if (this.nodes.contains(node)) {
            //Do nothing upon attempted duplicate insertion of node to MessageRouter.
            LOG.trace("Attempted insertion of duplicate node to MessageRouter.");
        } else {
            this.nodes.add(node);                        //Add node to main directory
            nodeMap.put(node.getName(), node);                 //Add node to name index searcher
            LOG.debug("Adding " + node.getName() + " to the router which now contains " + this.nodes.size() + " nodes");
      //-----
            //Signal all executing threads to pauseExecution.
            //-----
            this.updateRoutes();
        }
    }

    /**
     * Returns the number of nodes currently in the MessageRouter.
     *
     * @return The number of nodes.
     */
    public int nodeCount() {
        return this.nodes.size();
    }

    /**
     * Check to see if a node is contained inside a router.
     *
     * @param node The node to check for.
     * @return True if the node is contained by the router. Otherwise False.
     */
    public boolean containsNode(Messagable node) {
        return this.nodes.contains(node);
    }

    /**
     * Remove all routes.
     */
    public void clearRoutes() {
        this.routes = new HashMap();
    }

    /**
     * Get the number of routes in the routes table.
     *
     * @return The number of routes in the routes table.
     */
    public int routeSize() {
        return this.routes.size();
    }

    /**
     * Get the number of iterations that the MessageRouter will be running.
     *
     * @return number of iterations
     */
    public long getIterations() {
        return iterations;
    }

    /**
     * Set the number of iterations that the Messagerouter will be running.
     *
     * @param iterations The number of iterations.
     */
    public void setIterations(long iterations) {
        this.iterations = iterations;
    }

    /**
     * Returns the current pause delay.
     *
     * @return pauseExecution delay (in milliseconds)
     */
    public int getPauseDelay() {
        return pauseDelay;
    }

    /**
     * Sets the current pause delay.
     *
     * @param pauseDelay The pauseExecution delay (in milliseconds)
     */
    public void setPauseDelay(int pauseDelay) {
        this.pauseDelay = pauseDelay;
    }

    /**
     * Get the current name of the router.
     *
     * @return The router name.
     */
    public String getRouterName() {
        return routerName;
    }

    /**
     * Set the current name of the router.
     *
     * @param routerName Router name to set.
     */
    public void setRouterName(String routerName) {
        this.routerName = routerName;
    }

    /**
     * Iterate through all nodes and populate the routing table with the routes
     * for each node.
     */
    public void getRoutes() {
        for (Messagable node : this.nodes) {
            this.getRoutes(node);
        }
    }

    /**
     * Check to see if the system is currently paused.
     *
     * @return pauseExecutiond state. True if paused, False if running.
     */
    public boolean isPaused() {
        return paused;
    }

    /**
     * Pause the system.
     */
    public void pause() {
        this.paused = true;
    }

    /**
     * Remove a node at runtime. Note - this is potentially dangerous at
     * runtime. It is highly suggested that users instead reboot the program
     * after reconfiguring
     *
     * @param name The name of the node to remove at runtime.
     */
    public void removeNode(String name) {
        if (name == null) {                           //Null removal error case.
            LOG.trace("Attempted removal of null node from router.");
        } else if (!this.nodeMap.containsKey(name)) {              //Nonexistent removal error case.
            LOG.trace("Attempted removal of nonexistent node from router.");
        } else if (deletedNodes.contains(name)) {                //Previously deleted node removal error case.
            LOG.trace("Attempted removal of node that has already been deleted.");
        } else {                                //Default execution case.
            Messagable n = this.nodeMap.get(name);               //Grab the reference to the execution node.
            LOG.debug("Removing " + name + " from the router");
            this.nodeMap.remove(name);                     //Remove the node from the listing.
            this.nodes.remove(n);                        //Remove secondary reference to the node.
            deletedNodes.add(n.getName());
        }
    }

    /**
     * Route message from outbox of all nodes into all other nodes.
     *
     * @param name the name of the producing node
     */
    public void routeMessageFromNode(String name) {
        if (debug) {
            System.out.println("Routing message from " + name);
        }
        if (this.nodeMap.containsKey(name)) {                  //If the system being routed from exists...
            if (debug) {
                System.out.println("The key \"" + name + "\" is contained in the node map table.");
            }
            Message msg = this.nodeMap.get(name).getMessageFromOutbox();    //Get message from source object.
            if (!this.nodeMap.get(name).getOutboxHandle().isEmpty()) {
                if (debug) {
                    System.out.println("Non-empty outbox of " + name);
                }
                LOG.trace("Non-empty outbox of " + name);
                this.messagesWaiting = true;
            }
            if (msg == null) {
                return;                      //Break upon null message.
            }
            try {
                if (debug) {
                    System.out.println("Attempting to route message to nodes...");
                }
                routeMessageToNodes(msg, this.routes.get(msg.getTag()));	// route it to all nodes waiting for a value by given input.
                if (debug) {
                    System.out.println(this.routes.get(msg.getTag()));
                }
            } catch (NullPointerException ex) {
                if (debug) {
                    System.out.println("Error routing: message with tag " + msg.getTag());
                }
                LOG.fatal("Error routing: message with tag " + msg.getTag(), ex);
            }
        } else {                                //There is nothing to be routed as there is nothing to route from.      
            if (debug) {
                System.out.println("Node \"" + name + "\" does not exist in the nodeMap table.");
            }
            LOG.trace("Node \"" + name + "\" does not exist in the nodeMap table.");
        }
    }

    /**
     * Route a message from the outbox of each node into all other nodes.
     */
    public void routeMessageFromNodes() {
        Iterator<Messagable> i = nodes.iterator();
        while (i.hasNext()) {                          //Iterate through all nodes.
            routeMessageFromNode(i.next().getName());              //Route messages to other nodes.
        }
    }

    /**
     * Route message from outbox of one node to inbox of several nodes.
     *
     * @param msg the message to be routed
     * @param destinations the destinations to search
     */
    public void routeMessageToNodes(Message msg, ArrayList<String> destinations) {
        if (destinations != null) {                       //If there are destinations to send to.
            Iterator<String> i = destinations.iterator();            //Initialize iterator for destinations.
            while (i.hasNext()) {                        //Begin iterating through available destinations.
                String nodeName = i.next();                   //Get name of node to route to.
                if (debug) {
                    System.out.println("Routing message to " + nodeName);
                }
                Messagable destination = this.nodeMap.get(nodeName);      //Get reference to destination node.																				//A little bit of garbage collecting....
                if (destination == null) {                   //If destination does not exist in mapping,
                    if (deletedNodes.contains(nodeName)) {           //If node has been deleted...
                        i.remove();                       //Remove from the destinations list. Pointer values should mean this gets removed from the main list as well.
                    }
                    if (debug) {
                        System.out.println("Null destination!");
                    }
                } else {                            //If destination does exist in mapping,
                    if (debug) {
                        System.out.println("Routing Now");
                    }
                    destination.addMessageToInbox(msg);             //Put message in the inbox of the existing node.
                }
            }
        }
    }

    /**
     * The main running thread. Essentially this just executes the messages
     * passing back and forth.
     */
    @Override
    public void run() {
        this.running = true;
        do {
            this.messagesWaiting = false;
            this.routeMessageFromNodes();
        } while (this.messagesWaiting);
        this.iterations++;
        this.running = false;
    }

    /**
     * Signal router shutdown.
     */
    public void stopExecution() {
        this.running = false;                          //Signal this thread to end execution.
    }

    /**
     * Check to see if the system is running.
     *
     * @return True if running, false if not.
     */
    public boolean isExecuting() {
        return this.running;
    }

    /**
     * Resume excecution on the current system.
     */
    public void unpause() {
        this.paused = false;
    }

    /**
     * This is the method that updates all routes.
     */
    public void updateRoutes() {
        LOG.debug("Updating messaging routes.");
        this.getRoutes();                            //Get fresh routes from all current nodes.
    }

    /**
     * Checks the list of nodes that the current node retrieves data from and
     * sets appropriate routes within the system.
     *
     * @param node to query for consumes tags
     */
    private void getRoutes(Messagable node) {
        ArrayList<String> consumes = node.getConsumes();            //Retrieve list of nodes current node requires data from.
        for (String tag : consumes) {                      //For each tag...
            if (this.routes.containsKey(tag)) {                 // If the current tag exists in the routes...
                if (!this.routes.get(tag).contains(node.getName())) {      //  If no route exists from tagged node to current node...
                    this.routes.get(tag).add(node.getName());          //   Get the routes from tagged node and add a route to current node.
                    LOG.debug(
                            "Added message route: " + tag + " --> " + node.getName() + "");
                }
            } else {                              // Otherwise...
                ArrayList<String> newRoute = new ArrayList();          //  Create a new route list.
                newRoute.add(node.getName());                  //  Add current node to the new route list.
                this.routes.put(tag, newRoute);                 //  Add new route list to overall list of routes from tag to the new route list.
                LOG.debug(
                        "Added message route: " + tag + " --> " + node.getName() + "");
            }
        }
    }

    /**
     * Register a node with the MessageRouter for use during execution.
     *
     * @param node The node to register.
     * @throws RouterRegistrationException Thrown upon registration failure.
     */
    public void register(Messagable node) throws RouterRegistrationException {

        //Note: This method can be reduced in size.
        if (node == null) {                           //Null registration error case.
            throw new RouterRegistrationException(
                    "Attempt to register null pointer.");
        }
        boolean isInput = (node instanceof InputConnection);
        boolean isOutput = (node instanceof OutputConnection);
        boolean isModel = (node instanceof ModelConnection);
        if (isInput) {
            if (this.inputNodes.contains(node)) {       //Duplicate InputConnection error case.
                throw new RouterRegistrationException(
                        "Attempted to register duplicate InputConnection.");
            } else {                              //Add new InputConnection.
                this.inputNodes.add((InputConnection) node);
            }
        }
        if (isOutput) {
            if (this.outputNodes.contains(node)) {      //Duplicate OutputConnection error case.
                throw new RouterRegistrationException(
                        "Attempted to register duplicate OutputConnection.");
            } else {                              //Add new OutputConnection.
                this.outputNodes.add((OutputConnection) node);
            }
        }
        if (isModel) {
            if (this.ModelNodes.contains(node)) {       //Duplicate ModelConnection error case.
                throw new RouterRegistrationException(
                        "Attempted to register duplicate ModelConnection.");
            } else {                              //Add new ModelConnection.
                this.ModelNodes.add((ModelConnection) node);
            }
        }
        if (!isInput && !isOutput && !isModel) {
            if (this.unknownNodes.contains(node)) {               //Duplicate generic node error case.
                throw new RouterRegistrationException(
                        "Attempted to register duplicate node.");
            } else {                              //Add new generic node.
                this.unknownNodes.add(node);
            }
        }
        this.addNode(node);
    }

    /**
     * Deregister a given node from the MessageRouter.
     *
     * @param node The node to deregister.
     * @throws RouterRegistrationException Throws exception upon deregistration
     * error.
     */
    public void deregister(Messagable node) throws RouterRegistrationException {
        if (node == null) {                           //Null removal error case.
            throw new RouterRegistrationException(
                    "Attempted to deregister null pointer.");
        } else if (!this.containsNode(node)) {                 //Nonexistent node removal error case.
            throw new RouterRegistrationException(
                    "Attempted to deregister a node that does not exist.");
        }
        //Verify instance type of node.
        boolean isInput = (node instanceof InputConnection);
        boolean isOutput = (node instanceof OutputConnection);
        boolean isModel = (node instanceof ModelConnection);

        //Remove node from node type listing.
        if (isInput) {
            this.inputNodes.remove(node);
        }
        if (isOutput) {
            this.outputNodes.remove(node);
        }
        if (isModel) {
            this.ModelNodes.remove(node);
        }
        if (!isInput && !isOutput && !isModel) {
            this.unknownNodes.remove(node);
        }

        //Remove node from generalized listing.
        this.removeNode(node.getName());
    }

    /**
     * Get list of registered names.
     *
     * @return the list of registered names
     */
    public CopyOnWriteArrayList<String> getRegisteredNames() {
        ///! @bug Get registered names is unimplemented?
        return null;
    }

    /**
     * Return list of registered InputConnections.
     *
     * @return The list of registered InputConnections.
     */
    public CopyOnWriteArrayList<InputConnection> getRegisteredInputConnections() {
        return new CopyOnWriteArrayList(this.inputNodes);
    }

    /**
     * Return the list of registered OutputConnections.
     *
     * @return The list of registered OutputConnections.
     */
    public CopyOnWriteArrayList<OutputConnection> getRegisteredOutputConnections() {
        return new CopyOnWriteArrayList(this.outputNodes);
    }

    /**
     * Return the list of registered ModelConnections.
     *
     * @return The list of registered ModelConnections.
     */
    public CopyOnWriteArrayList<ModelConnection> getRegisteredModels() {
        return new CopyOnWriteArrayList(this.ModelNodes);
    }

    /**
     * Return the list of unknown nodes.
     *
     * @return The list of unknown nodes.
     */
    public CopyOnWriteArrayList<Messagable> getRegisteredUnknownNodes() {
        return new CopyOnWriteArrayList(this.unknownNodes);
    }
}
