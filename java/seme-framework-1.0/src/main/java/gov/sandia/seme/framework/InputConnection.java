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

/**
 * @if doxyDev
 * @page devInputConnections Developing Input Connections
 * 
 * @endif
 */
/**
 * Interface that extends a Messagable class to provide data input
 * functionality. Specifically, InputConnections create Messages of type \em value
 * which are fed to the MessageRouter for delivery. InputConnections can be tied
 * to the current Step. If constrained to the current Step, then only messages
 * that fall in the current bin will be created and submitted to the router. If
 * not, then all messages created by reading the input, regardless of their Step
 * value, will be submitted for routing.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface InputConnection extends Messagable {

    /**
     * Process all available input data and send as messages.
     *
     * @return number of messages processed
     */
    public int readInputAndProduceMessages();

    /**
     * Process only data up to the specified Step and send as messages.
     *
     * @param stepPar maximum Step value to have to be processed
     * @return number of messages processed
     */
    public int readInputAndProduceMessages(Step stepPar);

    /**
     * Is the input constrained only to current step value.
     *
     * @return constraint setting
     */
    public boolean isInputConstrainedToCurrentStep();

    /**
     * Set the input to be constrained to current step, or all available
     * messages.
     *
     * @param contrain true or false
     */
    public void setInputConstrainedToCurrentStep(boolean contrain);

    /**
     * Get the file/URL from where the data is being read.
     *
     * @return file path or URL string
     */
    public String getSourceLocation();

    /**
     * Set the file/URL from where the data is being read.
     *
     * @param location file path or URL string
     */
    public void setSourceLocation(String location);

}
