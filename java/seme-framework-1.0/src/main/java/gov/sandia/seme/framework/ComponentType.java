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
 * Provides enumerated constants for the component type a Descriptor object
 * represents. The values of CONTROLLER and DATACHANNEL should be used for their
 * respective classes, while MESSAGABLE should be used for any of
 * InputConnection, ModelConnection, or OutputConnection. A value of
 * SUBCOMPONENT indicates that descriptor is for a generic Describable object,
 * and that the program using the framework will know how to handle the class
 * specified in the Descriptor.
 * @htmlonly
 * @author David Hart, dbhart
 * @see Describable
 * @see Descriptor
 * @endhtmlonly
 */
public enum ComponentType {

    /**
     * Descriptor holds the configuration for a Controller object.
     */
    CONTROLLER,
    /**
     * Descriptor holds the configuration for a Messagable (Input-, Model-, or
     * OutputConnection) object.
     */
    MESSAGABLE,
    /**
     * Descriptor holds the configuration for DataChannel object.
     */
    DATACHANNEL,
    /**
     * Descriptor holds the configuration for a generic Describable object.
     */
    SUBCOMPONENT

}
