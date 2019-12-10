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
package gov.sandia.seme.util;

import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.framework.Components;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.Messagable;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.Step;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.PriorityBlockingQueue;
import org.apache.log4j.Logger;

/**
 * Provides an ABC implementation of the basic Messagable interface.
 *
 * @htmlonly
 * @author Nathanael Rackley, nprackl
 * @endhtmlonly
 */
public abstract class MessagableImpl implements Messagable {

    /**
     * The debug status flag.
     */
    protected boolean debug = false;
    static final Logger LOG = Logger.getLogger(MessagableImpl.class);

    /**
     * Configuration options and metadata.
     */
    protected final HashMap<String, Object> metaData = new HashMap();

    /**
     * Name of the connection object.
     */
    public String name;

    /**
     * Tags which are consumed by this connection.
     */
    protected ArrayList<String> consumes;

    /**
     * The delay between processing.
     */
    protected int delay;

    /**
     * The current Step.
     */
    protected Step currentStep;

    /**
     * The number of times this object has been called or run.
     */
    protected int iterations = -1;

    /**
     * The tags that this connection produces.
     */
    protected ArrayList<String> produces;

    /**
     * Any prerequisite connections that must complete before this connection
     * runs.
     */
    protected ArrayList<String> prerequisites;

    /**
     * Running status.
     */
    protected volatile boolean running;			//Set default flag for running.

    /**
     * A buffer in case the inbox or outbox fills.
     */
    protected PriorityBlockingQueue<Message> buffer = new PriorityBlockingQueue();			//Output Buffer

    /**
     * The inbox for messages to be consumed.
     */
    protected PriorityBlockingQueue<Message> inbox = new PriorityBlockingQueue();			//Input Queue

    /**
     * The output for messages which have been produced.
     */
    protected PriorityBlockingQueue<Message> outbox = new PriorityBlockingQueue();			//Output Queue

    /**
     * A list of processed Steps.
     */
    protected ArrayList<Step> steps;

    /**
     * The location string.
     */
    protected String location;

    /**
     * Status for receiving status updates from the prerequisite connections.
     */
    protected boolean[] recvdStatusForCurrentStep;

    /**
     * A copy of the controller's base Step.
     */
    protected Step baseStep;

    /**
     * Does this connection run if a null Step is passed to it?.
     */
    protected boolean nullStepOkay = false;

    /**
     * A link to the components factory.
     */
    protected Components componentFactory = new Components();

    @Override
    public Components getComponentFactory() {
        return componentFactory;
    }

    @Override
    public void setComponentFactory(Components componentFactory) {
        this.componentFactory = componentFactory;
    }

    /**
     * Constructor for messagable with name and delay.
     * @param label name for this messagable
     * @param delay default execution delay between loops
     */
    public MessagableImpl(String label, int delay) {
        this.name = label;
        this.delay = delay;
        this.consumes = new ArrayList();
        this.produces = new ArrayList();
    }

    /**
     * Constructor for blank messagable.
     */
    public MessagableImpl() {
        this.name = "undefined";
        this.delay = 1;
        this.consumes = new ArrayList();
        this.produces = new ArrayList();
    }

    @Override
    public Descriptor getConfiguration() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void initialize() throws InitializationException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public boolean isNullStepOkay() {
        return nullStepOkay;
    }

    @Override
    public void setNullStepOkay(boolean nullStepOkay) {
        this.nullStepOkay = nullStepOkay;
    }

    @Override
    public ArrayList<String> getPrerequisites() {
        return prerequisites;
    }

    @Override
    public void setPrerequisites(ArrayList<String> prerequisites) {
        this.prerequisites = prerequisites;
    }

    @Override
    public void addPrerequisite(String prereq) {
        this.prerequisites.add(prereq);
    }

    @Override
    public void removePrerequisite(String prereq) {
        this.prerequisites.remove(prereq);
    }

    @Override
    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String getName() {
        return this.name;

    }

    @Override
    public void addConsumes(String name) {
        //TODO: FixMe. Add handling for null insert and duplicate insert.
        this.consumes.add(name);
    }

    @Override
    public void addMessageToInbox(Message msg) {
        //TODO: Fixme. Add null handling for message insertion.
        if (debug) {
            System.out.println("Inbox size: " + this.inbox.size());
        }
        if (debug) {
            System.out.println(
                    name + ": Adding message to inbox." + msg.getData().toString());
        }
        this.inbox.put(msg);
        if (debug) {
            System.out.println("Inbox size: " + this.inbox.size());
        }
    }

    @Override
    public void addProduces(String tag) {
        //ToDo: Fixme. Duplicate insertion and null insertion handling.
        this.produces.add(tag);
    }

    @Override
    public ArrayList<String> getConsumes() {
        return consumes;
    }

    @Override
    public void setConsumes(ArrayList<String> consumes) {
        this.consumes = consumes;
    }

    @Override
    public PriorityBlockingQueue getInboxHandle() {
        return this.inbox;
    }

    @Override
    public Message getMessageFromOutbox() {
        return this.outbox.poll();
    }

    @Override
    public PriorityBlockingQueue getOutboxHandle() {
        return this.outbox;
    }

    @Override
    public ArrayList<String> getProduces() {
        return this.produces;
    }

    @Override
    public void setProduces(ArrayList<String> taglist) {
        //TODO: Fixme. Do we need to add null handling for taglist.
        this.produces = (ArrayList<String>) taglist.clone();
    }

    @Override
    public Message pollMessageFromInbox() {
        return this.inbox.poll();
    }

    @Override
    public void pushMessageToOutbox(Message m) {
        if (m == null) {														//Empty/null message generated.
//      if (debug) {
//        System.out.println("The message is null.");			//Default handling... debug output.
//      }
        } else {																//Message generated.
            //If a message is generated, we attempt to push to the buffer/output queue.
            if (this.buffer.isEmpty()) {										//If the buffer is empty...
                if (!this.outbox.offer(m)) {									//Try to add to outbox.
                    this.buffer.put(m);										//Put message in buffer if outbox is full. Wait if necessary.
                }
            } else {															//If the buffer is NOT empty...
                this.buffer.put(m);											//Add current item to buffer. Wait if necessary.
                //Attempt to dump all items from buffer into the outbox.
                //A note to future generations: This method should probably be optimized in the future.
                Message tm = this.buffer.peek();							//Grab pointer to first message in buffer.
                while ((this.outbox.offer(tm)) && (!this.buffer.isEmpty())) {	//Try to add to outbox if buffer isn't empty.
                    this.buffer.remove();									//If successful, remove first message in buffer.
                    if (!this.buffer.isEmpty()) {							//If buffer isn't empty....
                        tm = this.buffer.peek();							//Grab pointer to first message in buffer.
                    }
                }
            }
      //Thread debug output with buffer sizes and message contents.
            //if (debug) {
            //  System.out.println("Node \"" + getName() + "\n Message Contents: " + m.data.toString() + "\n" + " Inbox Size: " + this.inbox.size() + "\n" + " Outbox Size: " + this.outbox.size() + "\n" + " Buffer Size: " + this.buffer.size());
            //}
        }
    }

    @Override
    public void removeConsumes(String name) {
        //TODO: Fixme. Add null removal handling.
        this.consumes.remove(name);
    }

    @Override
    public void removeProduces(String tag) {
        this.produces.remove(tag);
    }

    @Override
    public void setCurrentStep(Step stepPar) {
        currentStep = stepPar;
    }

    @Override
    public Step getCurrentStep() {
        return currentStep;
    }

    @Override
    public void configure(Descriptor config) throws ConfigurationException{
        this.name = config.getName();
        for (String consume : config.getConsumesTags()) {
            addConsumes(consume);
        }
        for (String produce : config.getProducesTags()) {
            addProduces(produce);
        }
        setName(config.getName());
        HashMap options = config.getOptions();
        if (options != null) {
            for (Object key : options.keySet()) {
                this.setOpt((String) key, options.get(key));
            }
        }
    }

    @Override
    public Message pollMessageFromInbox(Step step) {
        if (step == null && !this.nullStepOkay) {
      // if stepsAreSynchronized, we can't read messages from the inbox
            // without a step to process -- return null in that case
            return null;
        }
        Message temp = this.inbox.peek();
        if (temp == null) {
            return null;
        }
        if (step == null) {
            this.inbox.remove(temp);
            return temp;
        } else if (temp.getStep().compareTo(step) < 1) { //Is this correct? I thought compareTo referenced a zero.
            this.inbox.remove(temp);
            return temp;
        }
        return null;
    }

    @Override
    public Step getBaseStep() {
        return baseStep;
    }

    @Override
    public void setBaseStep(Step baseStep) {
        this.baseStep = baseStep;
    }

    @Override
    public String[] parseStatusCode(int code) {
        if (code == 0) {
            return new String[]{"0", "SUCCESS"};
        } else {
            return BinaryEncodedStatus.parseCode(code);
        }
    }

    enum BinaryEncodedStatus {

        WARNING(1),
        ERROR(2),
        FATAL(4);

        private final int code;

        BinaryEncodedStatus(int code) {
            this.code = code;
        }

        public int code() {
            return code;
        }

        public static String[] parseCode(int code) {
            ArrayList<String> res = new ArrayList();
            res.add(Integer.toString(code));
            for (BinaryEncodedStatus s : BinaryEncodedStatus.values()) {
                if ((code & s.code()) > 0) {
                    res.add(s.toString());
                }
            }
            String[] a = new String[res.size()];
            return res.toArray(a);
        }

    }

    @Override
    public double[] getDoubleArrayOpt(String name) {
        try {
            return (double[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public double getDoubleOpt(String name) {
        return ((Number) metaData.get(name)).doubleValue();
    }

    @Override
    public int[] getIntegerArrayOpt(String name) {
        try {
            return (int[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public int getIntegerOpt(String name) {
        return ((Number) metaData.get(name)).intValue();
    }

    @Override
    public Object getMetaData() {
        return new HashMap(this.metaData);
    }

    @Override
    public void setMetaData(Object metaData) {
        this.metaData.clear();
        this.metaData.putAll((Map) metaData);
    }

    @Override
    public Object getOpt(String name) {
        return metaData.get(name);
    }

    @Override
    public String[] getOptKeys() {
        return (String[]) metaData.keySet().toArray();
    }

    @Override
    public String[] getStringArrayOpt(String name) {
        try {
            return (String[]) metaData.get(name);
        } catch (ClassCastException ex) {
            return null;
        }
    }

    @Override
    public String getStringOpt(String name) {
        return (String) metaData.get(name);
    }

    @Override
    public void setDoubleArrayOpt(String name, double[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setDoubleOpt(String name, double val) {
        metaData.put(name, val);
    }

    @Override
    public void setIntegerArrayOpt(String name, int[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setIntegerOpt(String name, int val) {
        metaData.put(name, val);
    }

    @Override
    public void setOpt(String name, Object val) {
        metaData.put(name, val);
    }

    @Override
    public void setStringArrayOpt(String name, String[] values) {
        metaData.put(name, values);
    }

    @Override
    public void setStringOpt(String name, String val) {
        metaData.put(name, val);
    }

}
