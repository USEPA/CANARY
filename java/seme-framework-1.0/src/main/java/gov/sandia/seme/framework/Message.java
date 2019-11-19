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

import java.io.Serializable;
import java.util.HashMap;

/**
 * @if doxyDev
 * @page devMessages Accessing and Creating Messages
 * 
 * @endif
 */
/**
 * Provides content for SeMe messaging framework. This class contains the data
 * required for routing between *-Connection objects. A Message can also be
 * represented as a HashMap, allowing JSON/YAML to be used. To do this, the tag,
 * step and type attributes are added as key:value pairs to the data HashMap.
 * These keys should not be set within the data portion of a Message object, as
 * they will be ignored/overwritten by the object's fields.
 *
 * @htmlonly
 * @author Nathanael Rackley, nprackl
 * @endhtmlonly
 */
public class Message implements Comparable<Object>, Serializable {

    private static final long serialVersionUID = 5937823552032320765L;

    HashMap data;
    String tag;
    Step step;
    MessageType type;

    public Message() {
        this.type = null;
        this.tag = null;
        this.data = null;
        this.step = null;
    }

    /**
     * Constructor with auto-populating date. Generates message with a null
     * Step.
     * 
     * @param type the message type
     * @param name tag tag (SCADA or other)
     * @param value content of message
     */
    public Message(MessageType type, String name, HashMap value) {
        this.type = type;
        this.tag = name;
        this.data = value;
        this.step = null;
    }

    /**
     * Generates message with a specific step.
     * 
     * @param type the message type
     * @param name tag tag (SCADA or other)
     * @param value content of the message
     * @param step the message date/time
     */
    public Message(MessageType type, String name, HashMap value, Step step) {
        this.type = type;
        this.tag = name;
        this.data = value;
        this.step = step;
    }

    /**
     * Compare to another Message.
     * 
     * @param arg0 message to be compared
     * @return comparison result
     */
    @Override
    public int compareTo(Object arg0) {
        Message m = (Message) arg0;
        return this.step.compareTo(m.step);
    }

    /**
     * Implement comparable by Step.
     * 
     * @param arg0 step to be compared
     * @return comparison result
     */
    public int compareTo(Step arg0) {
        return this.step.compareTo(arg0);
    }

    /**
     * Get the data field of the message.
     */
    public HashMap getData() {
        return data;
    }

    /**
     * Get the data field of the message.
     */
    public void setData(HashMap data) {
        this.data = data;
    }

    /**
     * Get the tag field of the message.
     */
    public String getTag() {
        return tag;
    }

    /**
     * Get the tag field of the message.
     */
    public void setTag(String tag) {
        this.tag = tag;
    }

    /**
     * Get the step field of the message.
     */
    public Step getStep() {
        return step;
    }

    /**
     * Get the step field of the message.
     */
    public void setStep(Step step) {
        this.step = step;
    }

    /**
     * Get the type field of the message.
     */
    public MessageType getType() {
        return type;
    }

    /**
     * Get the type field of the message.
     */
    public void setType(MessageType type) {
        this.type = type;
    }

    @Override
    public String toString() {
        return "Message{" + "tag=" + tag + ", step=" + step + ", type=" + type + ", data=" + data + '}';
    }
}
