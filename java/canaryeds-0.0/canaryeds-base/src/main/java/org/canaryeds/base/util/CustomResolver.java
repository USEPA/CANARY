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
package org.canaryeds.base.util;

import org.yaml.snakeyaml.nodes.Tag;
import org.yaml.snakeyaml.resolver.Resolver;

/**
 * Do not resolve timestamps in SnakeYAML parser. The date/time implicit resolver
 * in SnakeYAML works too well -- specifically, it associates timezone information
 * and formatting that may be wrong, because the correct format is specified within
 * the configuration file. Therefore, it is better to simply read in dates/times 
 * as strings and do the conversion within the Step class.
 * 
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class CustomResolver extends Resolver {

    /**
     * Add the default resolvers except for TIMESTAMP.
     */
    @Override
    protected void addImplicitResolvers() {
        addImplicitResolver(Tag.BOOL, BOOL, "yYnNtTfFoO");
        /*
         * INT must be before FLOAT because the regular expression for FLOAT
         * matches INT (see issue 130)
         * http://code.google.com/p/snakeyaml/issues/detail?id=130
         */
        addImplicitResolver(Tag.INT, INT, "-+0123456789");
        addImplicitResolver(Tag.FLOAT, FLOAT, "-+0123456789.");
        addImplicitResolver(Tag.MERGE, MERGE, "<");
        addImplicitResolver(Tag.NULL, NULL, "~nN\0");
        addImplicitResolver(Tag.NULL, EMPTY, null);
        //addImplicitResolver(Tag.TIMESTAMP, TIMESTAMP, "0123456789");
        addImplicitResolver(Tag.VALUE, VALUE, "=");
        // The following implicit resolver is only for documentation
        // purposes.
        // It cannot work
        // because plain scalars cannot start with '!', '&', or '*'.
        addImplicitResolver(Tag.YAML, YAML, "!&*");
    }
}
