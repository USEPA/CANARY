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

import org.canaryeds.program.AboutDialog;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

public class AboutDialogTest {

    static AboutDialog aboutDialog = new AboutDialog(new javax.swing.JFrame(), true);

    public AboutDialogTest() {
    }

    @BeforeClass
    public static void setUpClass() {
        aboutDialog.validate();
    }

    @AfterClass
    public static void tearDownClass() {
        aboutDialog.dispose();
    }

    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

    /**
     * @test Test of getReturnStatus method, of class AboutDialog.
     */
    @Test
    public void testGetReturnStatus() {
        System.out.println("getReturnStatus");
        int expResult = 0;
        int result = aboutDialog.getReturnStatus();
        assertEquals(expResult, result);
    }

}
