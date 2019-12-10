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
import java.util.concurrent.PriorityBlockingQueue;

/**
 * Interface that must be satisfied for any class that will interact with the
 * MessageRouter. All connections-type objects must implement this interface,
 * and the InputConnection, ModelConnection, and OutputConnection interfaces are
 * the preferred interfaces for development. Unless there is an issue with
 * multiple inheritance, the MessagableImpl can be extended to
 * avoid reinventing the wheel; the developer can focus on the Input, Model and
 * Output specific methods instead. Messagable objects that do not also
 * implement one of the above connections interfaces are run at the start of the
 * Engine's call method, and there is no special monitoring that the generic
 * tasks have completed before the input, model, and output tasks are runs.
 * Running generic Messagable tasks is not a supported feature.
 *
 * @htmlonly
 * @author Nathanael Rackley, nprackl
 * @endhtmlonly
 */
public interface Messagable extends Describable {

    /**
     * Add a message to the outbox.
     *
     * @param messagePar the message to post to the outbox
     */
    public void pushMessageToOutbox(Message messagePar);

    /**
     * Get the next message from the inbox.
     *
     * @return the next message (or null)
     */
    public Message pollMessageFromInbox();

    /**
     * Get the next message from the inbox with a step value equal to (or less
     * than) the Step provided.
     *
     * @param stepPar the step to use for comparison
     * @return the next message (or null)
     */
    public Message pollMessageFromInbox(Step stepPar);

    /**
     * Remove a message from the outbox. This function is used by the
     * MessageRouter.
     *
     * @return a message from the outbox
     */
    public Message getMessageFromOutbox();

    /**
     * Add message to the inbox. This function is used by the MessageRouter.
     *
     * @param messagePar the message to be added to the inbox
     */
    public void addMessageToInbox(Message messagePar);

    /**
     * Get the handle to the inbox queue.
     *
     * @return the handle to the inbox
     */
    public PriorityBlockingQueue getInboxHandle();

    /**
     * Get the handle to the outbox queue.
     *
     * @return the handle to the outbox
     */
    public PriorityBlockingQueue getOutboxHandle();

    /**
     * Set the value of name.
     *
     * @param name the value of name
     */
    public void setName(String name);

    /**
     * Get the value of name.
     *
     * @return the value of name
     */
    public String getName();

    /**
     * Get the list of tags this connection consumes.
     *
     * @return the list of tags consumed
     */
    public ArrayList<String> getConsumes();

    /**
     * Get the list of tags this connection produces.
     *
     * @return the list of tags produced
     */
    public ArrayList<String> getProduces();

    /**
     * Set the value of the currentStep.
     *
     * @param stepPar the value of currentStep
     */
    public void setCurrentStep(Step stepPar);

    /**
     * Get the value of the currentStep.
     *
     * @return the value of the currentStep
     */
    public Step getCurrentStep();

    /**
     * Initialize the connection object.
     *
     * @throws InitializationException
     */
    public void initialize() throws InitializationException;

    /**
     * Add a tag to the list of consumes.
     *
     * @param name the tag to be added to consumes
     */
    public void addConsumes(String name);

    /**
     * Add a tag to the list of produces.
     *
     * @param name the tag to be added to produces
     */
    public void addProduces(String name);

    /**
     * Set the value of consumes.
     *
     * @param consumes the list of consumes tags
     */
    public void setConsumes(ArrayList<String> consumes);

    /**
     * Set the value of produces.
     *
     * @param produces the list of produces tags
     */
    public void setProduces(ArrayList<String> produces);

    /**
     * Remove a tag from the list of consumes.
     *
     * @param name the tag to be removed from consumes
     */
    public void removeConsumes(String name);

    /**
     * Remove a tag from the list of produces.
     *
     * @param name the tag to be removed from produces
     */
    public void removeProduces(String name);

    /**
     * Configure the Messagable connection object using the Descriptor provided.
     *
     * @param desc the configuring Descriptor
     * @throws ConfigurationException
     */
    public void configure(Descriptor desc) throws ConfigurationException;

    /**
     * Get the configuration object.
     *
     * @return configuration inside a descriptor object
     */
    public Descriptor getConfiguration();

    /**
     * Get the value of prerequisites.
     *
     * @return the value of prerequisites
     */
    public ArrayList<String> getPrerequisites();

    /**
     * Set the value of prerequisites. Prerequisites provides a list of
     * Messagable objects, by name, that must be run prior to the component
     * described here.
     *
     * @param prerequisites the value of prerequisites
     */
    public void setPrerequisites(ArrayList<String> prerequisites);

    /**
     * Add a value to the list of prerequisites.
     *
     * @param prereq value to be added from prerequisites
     */
    public void addPrerequisite(String prereq);

    /**
     * Remove a value from the list of prerequisites.
     *
     * @param prereq value to be removed from prerequisites
     */
    public void removePrerequisite(String prereq);

    /**
     * Set the value of baseStep.
     *
     * @param step the value of baseStep
     */
    public void setBaseStep(Step step);

    /**
     * Get the value of baseStep.
     *
     * @return the value of baseStep
     */
    public Step getBaseStep();

    /**
     * Get the value of componentFactory.
     *
     * @return the value of componentFactory
     */
    public Components getComponentFactory();

    /**
     * Set the value of componentFactory.
     *
     * @param factory the value of componentFactory
     */
    public void setComponentFactory(Components factory);

    /**
     * Get the value of nullStepOkay.
     *
     * @return the value of nullStepOkay
     */
    public boolean isNullStepOkay();

    /**
     * Set the value of nullStepOkay.
     *
     * @param nullStepOkay new value of nullStepOkay
     */
    public void setNullStepOkay(boolean nullStepOkay);

    /**
     * Return a list of strings based on an integer status code.
     *
     * @param code the status code to be parsed
     * @return string representations for the status
     */
    public String[] parseStatusCode(int code);
}
