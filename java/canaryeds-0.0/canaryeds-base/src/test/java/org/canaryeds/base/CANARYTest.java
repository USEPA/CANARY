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
package org.canaryeds.base;

import org.canaryeds.base.CANARY;
import gov.sandia.seme.framework.Controller;
import gov.sandia.seme.framework.ModelConnection;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
import org.apache.log4j.Level;
import org.junit.After;
import org.junit.AfterClass;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class CANARYTest {

    static CopyOnWriteArrayList<ModelConnection> stationsV5mvnn;
    static CopyOnWriteArrayList<ModelConnection> stationsV5lpcf;
    static URL v5mvnn = CANARYTest.class.getResource(
            "/gov/sandia/canaryeds/v5config.yml");
    static URL v5lpcf = CANARYTest.class.getResource(
            "/gov/sandia/canaryeds/v5lpcf.yml");
    static URL stationCSV = CANARYTest.class.getResource(
            "/gov/sandia/canaryeds/Tutorial_Station_B.csv");

    public CANARYTest() {
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
     * Tests the CANARY class and the workflows.MVNN_BED class.
     */
    @Test
    public void testShortMVNN() {
        String testName = "testShortMVNN";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException | ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

    /**
     * Tests the CANARY class and the workflows.LPCF_BED class.
     */
    @Test
    public void testShortLPCF() {
        String testName = "testShortLPCF";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException | ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

    @Test
    public void testNoBED() {
        String testName = "testNoBED";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException ex) {
            assertEquals("Workflow could not be configured: Failed to configure the workflow!",ex.getMessage());
        } catch (ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }
    
    @Test
    public void testMixedWorkflowTypes() {
        String testName = "testMixedWorkflowTypes";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException | ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

    @Test
    public void testMissingWorkflowOptions() {
        String testName = "testMissingWorkflowOptions";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException ex) {
            assertEquals("Workflow could not be configured: Failed to configure the workflow!",ex.getMessage());
        } catch (ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

    
    @Test
    public void testMissingWorkflow() {
        String testName = "testMissingWorkflow";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (ConfigurationException ex) {
            System.out.println(ex.getMessage());
            assertEquals("Trying to configure a non-existant workflow!",ex.getMessage());
        } catch (InitializationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

    
    @Test
    public void testWrongSignal() {
        String testName = "testWrongSignal";
        try {
            System.out.println("--- "+testName+" ---");
            CANARY eds = new CANARY();
            InputStream is = CANARYTest.class.getResource("/gov/sandia/canaryeds/"+testName+".yml").openStream();
            HashMap config = eds.parseYAMLStream(is);
            HashMap stationB_In = (HashMap) ((Map) ((Map) config.get(
                    "connections")).get("stationb_in")).get("text.CSVReaderWide");
            stationB_In.put("location", stationCSV);
            eds.configure(config);
            eds.initialize();
            Controller ctrl = eds.getController();
            ctrl.run();
            eds.shutdown();
        } catch (InitializationException | ConfigurationException | IOException ex) {
            fail("The test caused an exception: " + ex.getMessage());
        }
    }

}
