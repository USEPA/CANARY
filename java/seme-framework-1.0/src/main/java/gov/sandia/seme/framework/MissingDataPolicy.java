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
 * Defines how data comes into SeMe from connectors. Generally, only one data
 * style is used for each Engine; if the style is CHANGES for one connection,
 * and TYPICAL for another, the style can be assigned on a
 * connection-by-connection basis.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public enum MissingDataPolicy {

    /**
     * Data is provided at every step. If no data is provided, it is missing and
     * should be omitted.
     */
    TYPICAL, /**
     * Data is provided only when a value changes. If no data is provided, the
     * last value should be repeated.
     */
    CHANGES, /**
     * Data handling is based on the DataChannel implementation.
     */
    CHANNEL

}
