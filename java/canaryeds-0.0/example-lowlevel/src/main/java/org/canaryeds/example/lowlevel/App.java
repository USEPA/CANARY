package org.canaryeds.example.lowlevel;

import gov.sandia.seme.framework.Descriptor;
import org.canaryeds.base.Station;
import org.canaryeds.base.EDSComponents;
import org.canaryeds.base.EventRecord;
import org.canaryeds.base.util.CustomResolver;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.InitializationException;
import gov.sandia.seme.framework.Message;
import gov.sandia.seme.framework.MessageType;
import gov.sandia.seme.framework.Step;
import gov.sandia.seme.util.IntegerStep;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;
import org.yaml.snakeyaml.representer.Representer;

/**
 * Demo to create a low-level API access to CanaryEDS 5.0.
 *
 * This demo uses a hard-coded filename, \c 'lowLevelDemo.yml', that will
 * obviously need to be changed for a particular application. As long as \c
 * config is a HashMap that has contents of similar structure to the example
 * file, any method of creation or retrieval is acceptable.
 *
 * The demo application will read in the configuration file and configure the
 * CanaryEDS Station object(s) defined therein. This demo will then load random
 * data into the station for 100 steps. This will give the Station's workflow
 * time to establish a baseline. The demo with then, with a sudden step
 * function, increase the values for one of the data channels and decrease
 * values for a different channel. The demo with then run the station for
 * another 100 steps, allowing a 'baseline change' to occur. At the end of these
 * 100 steps, the methods of extracting EventRecords from the station is shown,
 * followed by proper the shutdown procedure.
 *
 * @author David B. Hart
 */
public class App {

    public static void main(String[] args) {
        System.out.println("This is a low-level CanaryEDS API test.");
        // Set the loggers to ALL output.
        Logger.getGlobal().setLevel(Level.ALL);
        org.apache.log4j.Logger.getRootLogger().setLevel(org.apache.log4j.Level.ALL);

        // Create the CanaryEDS components and lists that we will need to access
        EDSComponents edsFactory = new EDSComponents();
        HashMap config = null;
        HashMap<String, Descriptor> stnDescriptors = null;
        ArrayList<Station> myStations = null;
        String stnName = null;
        Descriptor stnConfig = null;
        Station curStation = null;
        HashMap data = null;
        Step myStep = null;
        Message myMessage = null;
        String jsonMessage = null;

        // This demo will read the configuraiton from the file 'lowLevelDemo.yml'
        try {
            File cfgFile = new File("lowLevelDemo.yml");
            FileInputStream is = new FileInputStream(cfgFile.getAbsoluteFile());
            Yaml yaml = new Yaml(new Constructor(), new Representer(),
                    new DumperOptions(), new CustomResolver());
            config = (HashMap) yaml.load(is);
        } catch (FileNotFoundException ex) {
            Logger.getLogger(App.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println("Failed to open the file 'lowLevelDemo.yml'. Demo has failed. Exiting.");
            System.exit(1);
        } // end try

        // Do the configuration and setup
        try {
            // Initialize the list of stations you will be using
            myStations = new ArrayList();
            // Get the station descriptors from the configuration hash map
            stnDescriptors = edsFactory.getConnectionDescriptors(config);
            // For each of the stations defined in the configuration object ...
            for (Iterator<String> it = stnDescriptors.keySet().iterator();
                    it.hasNext();) {
                // Get the station name from the key as \c stnName
                stnName = it.next();
                // Get the station descriptor object as \c stnConfig
                stnConfig = stnDescriptors.get(stnName);
                // Create a new Station() object as \c curStation
                curStation = new Station(stnName, 1);
                // Set the component factor to use the CANARY specific object
                curStation.setComponentFactory(edsFactory);
                // Configure the station with the \c stnConfig descriptor
                curStation.configure(stnConfig);
                // Initialize the station
                curStation.initialize();
                // Set the base step FIXME: TODO: This should be in CONFIGURATION
                curStation.setBaseStep(new IntegerStep(0, 1, 1, "#"));
                // Add the configured, initialized station to the list \c myStations
                myStations.add(curStation);
            } // end for
        } catch (ConfigurationException ex) {
            // Configuration file formatting errors get caught here
            Logger.getLogger(App.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println("Demo has failed during Station configuration. Exiting.");
            System.exit(2);
        } catch (InitializationException ex) {
            // Bad initialization values get caught here
            Logger.getLogger(App.class.getName()).log(Level.SEVERE, null, ex);
            System.out.println("Demo has failed during Station initialization. Exiting.");
            System.exit(3);
        } // end try

        for (int i = 0; i < 100; i++) {
            for (Station thisStation : myStations) {
                myStep = thisStation.getBaseStep();
                myStep.setIndex(myStep.getIndex() + 1);
                thisStation.setCurrentStep(myStep);
                // Loading the random data into messages for 100 steps, printing results
                // to stdout
                // Add new data
                data = new HashMap();
                data.put("value", new Random().nextDouble() + 15.0);
                myMessage = new Message(MessageType.VALUE, "demoChannel1", data, myStep);
                thisStation.getInboxHandle().add(myMessage);
                // Add new data
                data = new HashMap();
                data.put("value", new Random().nextDouble() + 22.0);
                myMessage = new Message(MessageType.VALUE, "demoChannel2", data, myStep);
                thisStation.getInboxHandle().add(myMessage);
                // Add new data
                data = new HashMap();
                data.put("value", new Random().nextDouble() + 77.0);
                myMessage = new Message(MessageType.VALUE, "demoChannel3", data, myStep);
                thisStation.getInboxHandle().add(myMessage);
                // Add new data
                data = new HashMap();
                data.put("value", new Random().nextDouble() + 1.0);
                myMessage = new Message(MessageType.VALUE, "demoChannel4", data, myStep);
                thisStation.getInboxHandle().add(myMessage);
                // Evaluate the algorithms and read the result
                int result = thisStation.evaluateModel();
                myMessage = thisStation.getMessageFromOutbox();
                System.out.println(myMessage);
            }
        }
        // Loading the shifted random data into messages for 100 steps, printing
        // results to stdout.
        for (int i = 0; i < 100; i++) {
            for (Station thisStation : myStations) {
                myStep = thisStation.getBaseStep();
                myStep.setIndex(myStep.getIndex() + 1);
                // Loading the random data into messages for 100 steps, printing results
                // to stdout. However, we are adding data using JSON strings this time!
                // Add new data
                jsonMessage = "{\"type\": \"VALUE\","
                        + " \"tag\": \"demoChannel1\", "
                        + "\"step\": \"" + myStep.toString() + "\", "
                        + "\"data\": {\"value\": "
                        + (new Double(new Random().nextDouble() + 12.0)).toString() + "}}";
                if (i == 0) {System.out.println(jsonMessage);}
                thisStation.pushJSONtoInbox(jsonMessage);

                // Add new data
                jsonMessage = "{\"type\": \"VALUE\","
                        + " \"tag\": \"demoChannel2\", "
                        + "\"step\": \"" + myStep.toString() + "\", "
                        + "\"data\": {\"value\": "
                        + (new Double(new Random().nextDouble() + 25.0)).toString() + "}}";
                if (i == 0) {System.out.println(jsonMessage);}
                thisStation.pushJSONtoInbox(jsonMessage);

                // Add new data
                jsonMessage = "{\"type\": \"VALUE\","
                        + " \"tag\": \"demoChannel3\", "
                        + "\"step\": \"" + myStep.toString() + "\", "
                        + "\"data\": {\"value\": "
                        + (new Double(new Random().nextDouble() + 77.0 + i)).toString() + "}}";
                if (i == 0) {System.out.println(jsonMessage);}
                thisStation.pushJSONtoInbox(jsonMessage);

                // Add new data
                jsonMessage = "{\"type\": \"VALUE\","
                        + " \"tag\": \"demoChannel4\", "
                        + "\"step\": \"" + myStep.toString() + "\", "
                        + "\"data\": {\"value\": "
                        + (new Double(new Random().nextDouble() + 1.0 - 1 * 0.1)).toString() + "}}";
                if (i == 0) {System.out.println(jsonMessage);}
                thisStation.pushJSONtoInbox(jsonMessage);

                // Evaluate the algorithms and read the result
                int result = thisStation.evaluateModel();

                // Read a message as a JSON formatted string (for string-only API interfacing)
                // the timeout version of the call is commented below.
                // jsonMessage = thisStation.popJSONfromOutbox(1, TimeUnit.MINUTES);
                jsonMessage = thisStation.popJSONfromOutbox();
                
                if (i == 0) {System.out.println(jsonMessage);}
            }
        }

        // Extracting any EventRecords and printing them to stdout.
        for (Station thisStation : myStations) {
            ArrayList<EventRecord> events = thisStation.getEvents();
            for (EventRecord thisEvent : events) {
                System.out.println(thisEvent.summarize());
                System.out.println(thisEvent.toString());
            }
        }

        // Exit the demo
        System.out.println("Demo has completed successfully.");
        System.exit(0);
    }
}
