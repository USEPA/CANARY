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

/**
 * Provides exceptions for errors occurring within the initialization of a SeMe
 * object.
 *
 * @author David Hart
 */
public class InitializationException extends Exception {

    /**
     * Creates a new instance of <code>InitializationException</code> without
     * detail message.
     */
    public InitializationException() {
    }

    /**
     * Constructs an instance of <code>InitializationException</code> with the
     * specified detail message.
     *
     * @param msg the detail message.
     */
    public InitializationException(String msg) {
        super(msg);
    }
}
