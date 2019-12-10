/*
 * Copyright 2014 Sandia Corporation.
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
 */
package gov.sandia.seme.framework;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

public class SeMeExceptionTest {

    public SeMeExceptionTest() {
    }

    @BeforeClass
    public static void setUpClass() {
    }

    @AfterClass
    public static void tearDownClass() {
    }

    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

    @Test
    public void testConfigurationException() {
        try {
            throw new ConfigurationException();
        } catch (ConfigurationException ex) {
            assertEquals(ex.getMessage(), null);
        }
        try {
            throw new ConfigurationException("My Message");
        } catch (ConfigurationException ex) {
            assertEquals(true, ex.getMessage().contains("My Message"));
        }
    }

    @Test
    public void testDataOutOfFrameException() {
        try {
            throw new DataOutOfFrameException();
        } catch (DataOutOfFrameException ex) {
            assertEquals(ex.getMessage(), null);
        }
        try {
            throw new DataOutOfFrameException("My Message");
        } catch (DataOutOfFrameException ex) {
            assertEquals(true, ex.getMessage().contains("My Message"));
        }
    }

    @Test
    public void testInitializationException() {
        try {
            throw new InitializationException();
        } catch (InitializationException ex) {
            assertEquals(ex.getMessage(), null);
        }
        try {
            throw new InitializationException("My Message");
        } catch (InitializationException ex) {
            assertEquals(true, ex.getMessage().contains("My Message"));
        }
    }

    @Test
    public void testInvalidComponentClassException() {
        try {
            throw new InvalidComponentClassException();
        } catch (InvalidComponentClassException ex) {
            assertEquals(ex.getMessage(), null);
        }
        try {
            throw new InvalidComponentClassException("My Message");
        } catch (InvalidComponentClassException ex) {
            assertEquals(true, ex.getMessage().contains("My Message"));
        }
        String component, className, cause;
        component = "String1";
        className = "String2";
        cause = "String3";
        try {
            throw new InvalidComponentClassException(component, className, cause);
        } catch (InvalidComponentClassException ex) {
            assertEquals(true, ex.getMessage().contains("Attempt to create a CANARY-EDS " + component + " component of type '"
                    + className + "' failed: " + cause));
        }
    }

    @Test
    public void testRouterRegistrationException() {
        try {
            throw new RouterRegistrationException();
        } catch (RouterRegistrationException ex) {
            assertEquals(ex.getMessage(), null);
        }
        try {
            throw new RouterRegistrationException("My Message");
        } catch (RouterRegistrationException ex) {
            assertEquals(true, ex.getMessage().contains("My Message"));
        }
    }

}
