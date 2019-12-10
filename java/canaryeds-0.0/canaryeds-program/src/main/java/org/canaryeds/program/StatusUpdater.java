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

import org.canaryeds.base.CANARY;
import gov.sandia.seme.framework.Controller;
import javax.swing.JLabel;

/**
 * Provides a link to the status field of the GUI.
 * 
 * @internal
 * @author David Hart, dbhart
 */
public class StatusUpdater implements Runnable {

    private final JLabel statusField;
    private final CANARY canaryEDS;
    private final Controller controller;

    /**
     * Create a new StatusUpdater object. Once created, this object should be 
     * submitted to a ScheduledExecutionService.
     * 
     * @param statusField handle to the status field to be updated
     * @param canaryEDS handle to the CANARY object to be monitored
     * @param controller handle to the Controller object to be monitored
     */
    public StatusUpdater(JLabel statusField, CANARY canaryEDS, Controller controller) {
        this.statusField = statusField;
        this.canaryEDS = canaryEDS;
        this.controller = controller;
    }
    
    @Override
    public void run() {
        if (controller.isPaused()) {
            statusField.setText("Paused.");
        } else if (controller.isRunning()) {
            statusField.setText("Running - current step is "+canaryEDS.getCurrentStep().toString()+ ".");
        } else {
            statusField.setText("Stopped.");
        }
        statusField.repaint();
    }
    
}
