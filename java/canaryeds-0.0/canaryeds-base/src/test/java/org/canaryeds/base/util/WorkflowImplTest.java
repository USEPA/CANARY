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
package org.canaryeds.base.util;

import org.canaryeds.base.util.WorkflowImpl;
import gov.sandia.seme.framework.Descriptor;
import gov.sandia.seme.framework.ConfigurationException;
import java.util.HashMap;
import static org.apache.commons.math3.util.FastMath.abs;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class WorkflowImplTest {

    public WorkflowImplTest() {
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

    /**
     * Test of WorkflowImpl#nextpow2 method.
     */
    @Test
    public void testNextpow2() {
        System.out.println("nextpow2");
        int a = 0;
        WorkflowImplImpl instance = new WorkflowImplImpl();
        int expResult = 0;
        int result = instance.nextpow2(a);
        assertEquals(expResult, result);
        a = 3;
        expResult = 2;
        result = instance.nextpow2(a);
        assertEquals(expResult, result);
        a = 12;
        expResult = 4;
        result = instance.nextpow2(a);
        assertEquals(expResult, result);
        a = 65;
        expResult = 7;
        result = instance.nextpow2(a);
        assertEquals(expResult, result);
        a = 982;
        expResult = 10;
        result = instance.nextpow2(a);
        assertEquals(expResult, result);
    }

    /**
     * Test of WorkflowImpl#lpc method.
     */
    @Test
    public void testLpc() {
        System.out.println("lpc");
        double[] x = new double[]{0.8426, -2.6605, 1.1679, 0.3274, 1.8538, -1.7725, 1.7967, 0.1373, -0.3391, 0.3014, 0.1029, -1.0099, -1.2268, 0.7716, 1.1388, 0.5029, -1.6959, 0.5082, 0.4487, -0.2086, 1.2980, -0.2725, -0.8186, 1.4288, -1.1357, 0.3869, 1.0949, -0.1035, 0.7628, -2.1777, 0.5989, 1.0353, -0.0382, 0.0485, -1.1692, 1.6772, -0.8977, -0.4086, -0.7575, 2.2593, -0.1343, -1.0344, 0.2153, 2.3289, -1.3186, -0.2463, 0.0617, 0.4643, -0.4559, 0.5453, 0.7717, 0.4494, -0.3881, 0.0310, -0.0077, -0.8968, 1.4967, -0.7020, -0.9499, -0.5886, 0.3638, 0.0799, 1.8061, -0.3529};
        int N = x.length - 1;
        WorkflowImplImpl instance = new WorkflowImplImpl();
        double[] expResult = new double[]{1.000000000000000,
            0.620107950344060,
            0.527938571101240,
            0.497305626605425,
            0.213859986484930,
            0.225024881496800,
            0.325633935736778,
            0.216753828017343,
            0.141043574118883,
            0.280773470620997,
            0.148734633233402,
            -0.078304087191435,
            -0.070772369589752,
            -0.213753899906261,
            -0.166703350501319,
            -0.074333256044645,
            -0.123449426365743,
            -0.381468141560142,
            -0.249664160861102,
            -0.341567496636653,
            -0.416572587670717,
            -0.383906123373960,
            -0.407402104074372,
            -0.452568578151603,
            -0.332907729319391,
            -0.294442081301130,
            -0.389647123799711,
            -0.155061136518447,
            -0.190204314761456,
            -0.290926486516290,
            -0.113390055537497,
            -0.118060419665929,
            0.073388136219047,
            0.069212711534056,
            0.254778483672472,
            0.123322435383378,
            0.016568472047782,
            0.076014005328805,
            0.180295963030891,
            0.146940058524118,
            0.308748833895435,
            0.306235446702390,
            0.195369636910920,
            0.129111792661449,
            0.061094902076374,
            -0.000228054566220,
            0.106381888889644,
            0.026813738590130,
            0.019605784253109,
            0.026914663953862,
            0.074580445264444,
            0.041336057403394,
            0.096395615130765,
            0.065949660372258,
            0.062135670822400,
            0.105961275005481,
            0.028539017735844,
            -0.047255143681437,
            -0.103416420215018,
            -0.045853960615556,
            -0.056454697460982,
            0.016591808183457,
            -0.003997145699417,
            -0.116475036813622};
        double[] result = instance.lpc(x, N);
        for (int i = 1; i < N; i++) {
            double diff = abs(expResult[i] - result[i - 1]);
            assertEquals(diff, 0.0, 1e-6);
        }
    }

    /**
     * Test of WorkflowImpl#predEstim method.
     */
    @Test
    public void testPredEstim() {
        System.out.println("predEstim");
        double[] b = new double[]{1.000000000000000,
            0.620107950344060,
            0.527938571101240,
            0.497305626605425,
            0.213859986484930,
            0.225024881496800,
            0.325633935736778,
            0.216753828017343,
            0.141043574118883,
            0.280773470620997,
            0.148734633233402,
            -0.078304087191435,
            -0.070772369589752,
            -0.213753899906261,
            -0.166703350501319,
            -0.074333256044645,
            -0.123449426365743,
            -0.381468141560142,
            -0.249664160861102,
            -0.341567496636653,
            -0.416572587670717,
            -0.383906123373960,
            -0.407402104074372,
            -0.452568578151603,
            -0.332907729319391,
            -0.294442081301130,
            -0.389647123799711,
            -0.155061136518447,
            -0.190204314761456,
            -0.290926486516290,
            -0.113390055537497,
            -0.118060419665929,
            0.073388136219047,
            0.069212711534056,
            0.254778483672472,
            0.123322435383378,
            0.016568472047782,
            0.076014005328805,
            0.180295963030891,
            0.146940058524118,
            0.308748833895435,
            0.306235446702390,
            0.195369636910920,
            0.129111792661449,
            0.061094902076374,
            -0.000228054566220,
            0.106381888889644,
            0.026813738590130,
            0.019605784253109,
            0.026914663953862,
            0.074580445264444,
            0.041336057403394,
            0.096395615130765,
            0.065949660372258,
            0.062135670822400,
            0.105961275005481,
            0.028539017735844,
            -0.047255143681437,
            -0.103416420215018,
            -0.045853960615556,
            -0.056454697460982,
            0.016591808183457,
            -0.003997145699417,
            -0.116475036813622};
        double[] x = new double[]{0.8426, -2.6605, 1.1679, 0.3274, 1.8538, -1.7725, 1.7967, 0.1373, -0.3391, 0.3014, 0.1029, -1.0099, -1.2268, 0.7716, 1.1388, 0.5029, -1.6959, 0.5082, 0.4487, -0.2086, 1.2980, -0.2725, -0.8186, 1.4288, -1.1357, 0.3869, 1.0949, -0.1035, 0.7628, -2.1777, 0.5989, 1.0353, -0.0382, 0.0485, -1.1692, 1.6772, -0.8977, -0.4086, -0.7575, 2.2593, -0.1343, -1.0344, 0.2153, 2.3289, -1.3186, -0.2463, 0.0617, 0.4643, -0.4559, 0.5453, 0.7717, 0.4494, -0.3881, 0.0310, -0.0077, -0.8968, 1.4967, -0.7020, -0.9499, -0.5886, 0.3638, 0.0799, 1.8061, -0.3529};
        WorkflowImplImpl instance = new WorkflowImplImpl();
        double expResult = -0.213611277481411;
        double result = instance.predEstim(b, x);
        assertEquals(expResult, result, 1e-6);
    }

    private class WorkflowImplImpl extends WorkflowImpl {

        @Override
        public HashMap evaluateWorkflow(int index) {
            throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
        }

        @Override
        public void configure(Descriptor desc) throws ConfigurationException {
            throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
        }

        @Override
        public Descriptor getConfiguration() {
            throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
        }
    }

}
