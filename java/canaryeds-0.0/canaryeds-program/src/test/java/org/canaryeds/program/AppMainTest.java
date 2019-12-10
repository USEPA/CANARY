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

package org.canaryeds.program;

import org.canaryeds.program.AppMain;
import java.awt.event.ActionEvent;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

public class AppMainTest {
    
    static AppMain app;
    
    public AppMainTest() {
    }
    
    @BeforeClass
    public static void setUpClass() {
        app = new AppMain();
        app.validate();
    }
    
    @AfterClass
    public static void tearDownClass() {
        app.dispose();
    }
    
    @Before
    public void setUp() {
    }
    
    @After
    public void tearDown() {
    }

    /**
     * @test Test of openConfigfile method, of class AppMain.
     */
    @Test
    public void testInit() {
        System.out.println("<init>");
        // TODO review the generated test code and remove the default call to fail.
        app.getComponents();
    }
    
}
