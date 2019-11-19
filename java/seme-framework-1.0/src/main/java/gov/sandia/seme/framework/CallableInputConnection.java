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

import java.util.concurrent.Callable;

/**
 * A Callable class that has a predefined call function customized for
 * InputConnection objects. The Engine creates a new instance of this class for
 * every InputConnection during its call() routine. The InputConnection must be
 * registered with the MessageRouter to be executed by the Engine. Because this
 * class implements Callable, the Engine submits it to a multi-thread
 * ExecutionService, rather than creating a new Thread directly.
 * 
 * @warning Improper use could cause the InputConnection to fail silently.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public final class CallableInputConnection implements Callable<String> {

    private final InputConnection conn;

    /**
     * Create a new Callable based on an InputConnection.
     * @param conn InputConnection object to run
     */
    public CallableInputConnection(InputConnection conn) {
        this.conn = conn;
    }

    /**
     * Calls the readInputAndProduceMessages function based on the current step.
     *
     * @return returns a result status string
     * @throws Exception any exception that occurs is re-thrown
     */
    @Override
    public final String call() throws Exception {
        int status;
        if (this.conn.isInputConstrainedToCurrentStep()) {
            status = this.conn.readInputAndProduceMessages(
                    this.conn.getCurrentStep());
        } else {
            status = this.conn.readInputAndProduceMessages();
        }
        String res = "Results: ";
        for (String s : this.conn.parseStatusCode(status)) {
            res += s + " ";
        }
        return res;
    }

}
