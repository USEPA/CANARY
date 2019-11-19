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
 * @if (doxyDev && !doxyDevSemeNoModel)
 * @page devModelConnections Developing Model Connections
 * 
 * @endif
 */
/**
 * Interface that extends the Messagable class to provide model evaluation
 * functionality. Specifically, ModelConnections consume VALUE and/or RESULT
 * type Messages, and they produce RESULT type Messages which are fed to the
 * MessageRouter for delivery. ModelConnections are always tied to the current
 * Step.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public interface ModelConnection extends Messagable {

    /**
     * Execute the model, and retrieve an integer status code. Like Unix, a
     * value of 0 is considered to be normal execution, any other value
     * indicates an error. Errors will be logged.
     *
     * @return an Unix-like integer status code
     */
    public int evaluateModel();

}
