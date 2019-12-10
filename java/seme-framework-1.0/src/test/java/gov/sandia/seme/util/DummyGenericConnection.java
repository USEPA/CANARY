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

import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.MessageType;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.MessagableImpl;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.PriorityBlockingQueue;

/**
 * A dummy implementation of a generic Messageable object for use with software testing.
 * @author nprackl
 */
public class DummyGenericConnection  extends MessagableImpl {
    private int count = 0;
    public DummyGenericConnection(String label, int delay) {
        super(label, delay);
    }
    
    /**
     * For testing only. Transfers entire inbox into outbox.
     */
    public void moveInboxToOutbox(){
        System.out.println("   " + this.name + ": Push to Outbox");
        while(!this.inbox.isEmpty()){
            Message msg = this.inbox.poll();
            msg.setTag(this.name);
            this.pushMessageToOutbox(msg);
        }
    }
    
    /**
     * For testing only. Generates a message counter in the inbox.
     */
    public void generateCounterMessage(){
        System.out.println("   " + this.name +": Generating MSG in Inbox");   
        this.count++;
        HashMap<String, Integer> cntr = new HashMap();
        cntr.put("counter", this.count);
        Message msg = new Message(MessageType.VALUE, this.name, cntr);
        msg.setStep(new IntegerStep(0, 1, this.count, null));
        this.addMessageToInbox(msg);
    }
    
    public Message getCounterMessage(){
        System.out.println("   " + this.name +": Generating MSG");   
        this.count++;
        HashMap<String, Integer> cntr = new HashMap();
        cntr.put("counter", this.count);
        Message msg = new Message(MessageType.VALUE, this.name, cntr);
        msg.setStep(new IntegerStep(0, 1, this.count, null));
        return msg;
    }
    
    public void clearBoxes(){
        this.inbox  = new PriorityBlockingQueue();
        this.outbox = new PriorityBlockingQueue();
    }
    
    public int getInboxSize(){
        return this.inbox.size();
    }
    
    public int getOutboxSize(){
        return this.outbox.size();
    }
    
    public String reportBoxSize(){
        return this.name + "[I:" + this.getInboxSize() + " O:" + this.getOutboxSize()+"]";
    }
    
                

}
