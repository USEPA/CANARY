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

import gov.sandia.seme.framework.InputConnection;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.MessagableImpl;

/**
 * A dummy implementation of the InputConnection Messageable object for use with software testing.
 * @author nprackl
 */
public class DummyInputConnection  extends MessagableImpl implements InputConnection {
    
    public DummyInputConnection(String label, int delay) {
        super(label, delay);
    }

    @Override
    public int readInputAndProduceMessages() {
        return 0;
    }

    @Override
    public int readInputAndProduceMessages(Step stepPar) {
        return 1;
    }

    @Override
    public boolean isInputConstrainedToCurrentStep() {
        return true;
    }

    @Override
    public void setInputConstrainedToCurrentStep(boolean contrain) {
    }

    @Override
    public String getSourceLocation() {
        return "testLoc";
    }

    @Override
    public void setSourceLocation(String location) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }


    
}
