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
package org.canaryeds.program;

import org.canaryeds.base.CANARY;
import gov.sandia.seme.framework.ConfigurationException;
import gov.sandia.seme.framework.Controller;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.ResourceBundle;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.ArgumentParserException;
import net.sourceforge.argparse4j.inf.Namespace;
import org.apache.log4j.Level;

/**
 * <p>
 * @author dbhart
 */
public class AppMain extends javax.swing.JFrame {

    private BufferedImage icon = null;
    private File configFile;
    private static final org.apache.log4j.Logger LOG = org.apache.log4j.Logger.getLogger(
            "gov.sandia");
    private static final ResourceBundle messages = java.util.ResourceBundle.getBundle(
            "org.canaryeds.base.app");
    private CANARY eds;
    private Controller ctrl;
    private static String[] args = new String[]{};
    private static ScheduledExecutorService statusMonitor = Executors.newSingleThreadScheduledExecutor();

    /**
     * Creates new form CanaryEDS
     */
    public AppMain() {
        this.eds = new CANARY();
        try {
            icon = ImageIO.read(this.getClass().getResource("/org/canaryeds/base/icon.png"));
        } catch (IOException ex) {
        }
        initComponents();
        LOG.addAppender(new TextAreaAppender(logTextArea));
        LOG.setLevel(Level.INFO);
        try {
            ArgumentParser parser = CANARY.getNewParser();
            parser = CANARY.addArguments(parser);
            Namespace res = parser.parseArgs(args);
                Level eLevel = eds.setup(res);
                LOG.setLevel(eLevel);
                org.apache.log4j.Logger.getRootLogger().setLevel(eLevel);
                if (eLevel == Level.OFF) {
                    this.logLevelCBox.setSelectedIndex(0);
                } else if (eLevel == Level.FATAL) {
                    this.logLevelCBox.setSelectedIndex(1);
                } else if (eLevel == Level.ERROR) {
                    this.logLevelCBox.setSelectedIndex(2);
                } else if (eLevel == Level.WARN) {
                    this.logLevelCBox.setSelectedIndex(3);
                } else if (eLevel == Level.INFO) {
                    this.logLevelCBox.setSelectedIndex(4);
                } else if (eLevel == Level.DEBUG) {
                    this.logLevelCBox.setSelectedIndex(5);
                } else if (eLevel == Level.TRACE) {
                    this.logLevelCBox.setSelectedIndex(6);
                } else if (eLevel == Level.ALL) {
                    this.logLevelCBox.setSelectedIndex(7);
                }
            String cmdLineCfgFile = res.getString("configfile");
            if (cmdLineCfgFile != null) {
                configFile = new File(cmdLineCfgFile);
                //This is where a real application would open the file.
                LOG.info(
                        "Opening configuration file specified on command line: " + configFile.getName() + ".");
                this.configfileTextField.setText(configFile.getName());
                HashMap config = eds.parseConfigFile(
                        configFile.getAbsolutePath());
                if (config == null) {
                    throw new ConfigurationException(
                            "Failed to load the configuration file: " + configFile.getName());
                } else {
                    eds.configure(config);
                }
            }
            if (res.getBoolean("run")) {
                this.startExecution(null);
            }
        } catch (ConfigurationException ex) {
            LOG.error(
                    "Failed to load the configuration file specified on the command line: " + configFile.getName(),
                    ex);
        } catch (ArgumentParserException ex) {
            LOG.error(
                    "Failed to parse command line arguments", ex);
        }
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        bindingGroup = new org.jdesktop.beansbinding.BindingGroup();

        logScrollPane = new javax.swing.JScrollPane();
        logTextArea = new javax.swing.JTextArea();
        logAreaLabel = new javax.swing.JLabel();
        logLevelLabel = new javax.swing.JLabel();
        logLevelCBox = new javax.swing.JComboBox();
        configfileLabel = new javax.swing.JLabel();
        configfileTextField = new javax.swing.JTextField();
        startButton = new javax.swing.JButton();
        pauseButton = new javax.swing.JToggleButton();
        cancelButton = new javax.swing.JButton();
        statusLabel = new javax.swing.JLabel();
        statusText = new javax.swing.JLabel();
        menuBar = new javax.swing.JMenuBar();
        fileMenu = new javax.swing.JMenu();
        openMenuItem = new javax.swing.JMenuItem();
        saveMenuItem = new javax.swing.JMenuItem();
        saveAsMenuItem = new javax.swing.JMenuItem();
        exitMenuItem = new javax.swing.JMenuItem();
        runMenu = new javax.swing.JMenu();
        startMenuItem = new javax.swing.JMenuItem();
        pauseMenuItem = new javax.swing.JCheckBoxMenuItem();
        cancelMenuItem = new javax.swing.JMenuItem();
        helpMenu = new javax.swing.JMenu();
        contentsMenuItem = new javax.swing.JMenuItem();
        aboutMenuItem = new javax.swing.JMenuItem();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("CANARY-EDS");
        setIconImage(this.icon);
        setName("canaryedsApp"); // NOI18N

        logTextArea.setEditable(false);
        logTextArea.setColumns(20);
        logTextArea.setFont(new java.awt.Font("Lucida Console", 0, 12)); // NOI18N
        logTextArea.setLineWrap(true);
        logTextArea.setRows(5);
        logTextArea.setToolTipText("Message and progress log. Set log level above.");
        logTextArea.setWrapStyleWord(true);
        logScrollPane.setViewportView(logTextArea);

        logAreaLabel.setLabelFor(logTextArea);
        logAreaLabel.setText("Message and Progress Log");

        logLevelLabel.setLabelFor(logLevelCBox);
        logLevelLabel.setText("Log Level");

        logLevelCBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "OFF", "FATAL", "ERROR", "WARN", "INFO", "DEBUG", "TRACE", "ALL" }));
        logLevelCBox.setSelectedIndex(4);
        logLevelCBox.setToolTipText("Set the log level for future events");
        logLevelCBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                logLevelCBoxActionPerformed(evt);
            }
        });

        configfileLabel.setLabelFor(configfileTextField);
        configfileLabel.setText("Configuration file:");

        configfileTextField.setEditable(false);
        configfileTextField.setToolTipText("The configuration file to run");

        startButton.setIcon(new javax.swing.ImageIcon(getClass().getResource("/org/canaryeds/program/icon.png"))); // NOI18N
        startButton.setText("Start");
        startButton.setToolTipText("Start running CANARY-EDS 5.0");
        startButton.setName(""); // NOI18N
        startButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                startButtonActionPerformed(evt);
            }
        });

        pauseButton.setText("Pause Execution");

        org.jdesktop.beansbinding.Binding binding = org.jdesktop.beansbinding.Bindings.createAutoBinding(org.jdesktop.beansbinding.AutoBinding.UpdateStrategy.READ_WRITE, pauseMenuItem, org.jdesktop.beansbinding.ELProperty.create("${selected}"), pauseButton, org.jdesktop.beansbinding.BeanProperty.create("selected"));
        bindingGroup.addBinding(binding);

        pauseButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                pauseButtonActionPerformed(evt);
            }
        });

        cancelButton.setText("Cancel Execution");
        cancelButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cancelButtonActionPerformed(evt);
            }
        });

        statusLabel.setLabelFor(statusText);
        statusLabel.setText("Status:");

        statusText.setFont(new java.awt.Font("Tahoma", 1, 11)); // NOI18N

        fileMenu.setMnemonic('f');
        fileMenu.setText("File");

        openMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_O, java.awt.event.InputEvent.CTRL_MASK));
        openMenuItem.setMnemonic('o');
        openMenuItem.setText("Open Configuration");
        openMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                openMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(openMenuItem);

        saveMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, java.awt.event.InputEvent.CTRL_MASK));
        saveMenuItem.setMnemonic('s');
        saveMenuItem.setText("Save Configuration");
        saveMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(saveMenuItem);

        saveAsMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, java.awt.event.InputEvent.SHIFT_MASK | java.awt.event.InputEvent.CTRL_MASK));
        saveAsMenuItem.setMnemonic('a');
        saveAsMenuItem.setText("Save Log Area");
        saveAsMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveAsMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(saveAsMenuItem);

        exitMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_Q, java.awt.event.InputEvent.CTRL_MASK));
        exitMenuItem.setMnemonic('x');
        exitMenuItem.setText("Exit");
        exitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                exitMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(exitMenuItem);

        menuBar.add(fileMenu);

        runMenu.setText("Run");

        startMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_R, java.awt.event.InputEvent.CTRL_MASK));
        startMenuItem.setText("Start Execution");
        startMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                startMenuItemActionPerformed(evt);
            }
        });
        runMenu.add(startMenuItem);

        pauseMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_P, java.awt.event.InputEvent.CTRL_MASK));
        pauseMenuItem.setText("Pause Execution");
        pauseMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                pauseMenuItemActionPerformed(evt);
            }
        });
        runMenu.add(pauseMenuItem);

        cancelMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_C, java.awt.event.InputEvent.CTRL_MASK));
        cancelMenuItem.setText("Cancel Execution");
        cancelMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                cancelMenuItemActionPerformed(evt);
            }
        });
        runMenu.add(cancelMenuItem);

        menuBar.add(runMenu);

        helpMenu.setMnemonic('h');
        helpMenu.setText("Help");

        contentsMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F1, 0));
        contentsMenuItem.setMnemonic('c');
        contentsMenuItem.setText("Contents");
        helpMenu.add(contentsMenuItem);

        aboutMenuItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F1, java.awt.event.InputEvent.CTRL_MASK));
        aboutMenuItem.setMnemonic('a');
        aboutMenuItem.setText("About");
        aboutMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                aboutMenuItemActionPerformed(evt);
            }
        });
        helpMenu.add(aboutMenuItem);

        menuBar.add(helpMenu);

        setJMenuBar(menuBar);

        org.jdesktop.layout.GroupLayout layout = new org.jdesktop.layout.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(layout.createSequentialGroup()
                .addContainerGap()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(logScrollPane)
                    .add(layout.createSequentialGroup()
                        .add(configfileLabel)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(configfileTextField))
                    .add(layout.createSequentialGroup()
                        .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                            .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.TRAILING, false)
                                .add(layout.createSequentialGroup()
                                    .add(logLevelLabel)
                                    .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                                    .add(logLevelCBox, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                                .add(logAreaLabel))
                            .add(layout.createSequentialGroup()
                                .add(statusLabel)
                                .addPreferredGap(org.jdesktop.layout.LayoutStyle.UNRELATED)
                                .add(statusText, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 354, Short.MAX_VALUE)))
                        .add(18, 18, 18)
                        .add(startButton)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                            .add(cancelButton, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 146, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                            .add(pauseButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(org.jdesktop.layout.GroupLayout.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                    .add(configfileTextField, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(configfileLabel))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(layout.createSequentialGroup()
                        .add(5, 5, 5)
                        .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                            .add(statusLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(statusText, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                            .add(logLevelCBox, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                            .add(logLevelLabel))
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(logAreaLabel))
                    .add(layout.createSequentialGroup()
                        .add(pauseButton)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .add(cancelButton))
                    .add(startButton))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(logScrollPane, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 450, Short.MAX_VALUE)
                .addContainerGap())
        );

        bindingGroup.bind();

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void exitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_exitMenuItemActionPerformed
        try {
            ctrl.stopExecution();
            eds.shutdown();
        while (!statusMonitor.isShutdown()) {
            statusMonitor.shutdown();
        }
        } catch (Exception ex) {
            Logger.getLogger(AppMain.class.getName()).log(
                    java.util.logging.Level.SEVERE, null, ex);
        }
        LOG.info(messages.getString("exit.success"));
        System.exit(0);
    }//GEN-LAST:event_exitMenuItemActionPerformed

    private void logLevelCBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_logLevelCBoxActionPerformed
        LOG.setLevel(org.apache.log4j.Level.toLevel(
                (String) this.logLevelCBox.getSelectedItem(),
                org.apache.log4j.Level.INFO));
    }//GEN-LAST:event_logLevelCBoxActionPerformed

    private void openMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_openMenuItemActionPerformed
        openConfigfile();
    }//GEN-LAST:event_openMenuItemActionPerformed

    private void startButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_startButtonActionPerformed
        startExecution(evt);
    }//GEN-LAST:event_startButtonActionPerformed

    private void startMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_startMenuItemActionPerformed
        startExecution(evt);
    }//GEN-LAST:event_startMenuItemActionPerformed

    private void pauseButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_pauseButtonActionPerformed
        pauseExecution(evt);
    }//GEN-LAST:event_pauseButtonActionPerformed

    private void pauseMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_pauseMenuItemActionPerformed
        pauseExecution(evt);
    }//GEN-LAST:event_pauseMenuItemActionPerformed

    private void cancelButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cancelButtonActionPerformed
        cancelExecution(evt);
    }//GEN-LAST:event_cancelButtonActionPerformed

    private void cancelMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_cancelMenuItemActionPerformed
        cancelExecution(evt);
    }//GEN-LAST:event_cancelMenuItemActionPerformed

    private void saveAsMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveAsMenuItemActionPerformed
        JFileChooser saveFile = new JFileChooser();
        // save the LOG file
        //saveFile.setCurrentDirectory(dataFile);
        saveFile.setDialogTitle("Save log panel as file");
//        int status = saveFile.showSaveDialog(datafileFormatOptionsPanel);
//        if (status == JFileChooser.APPROVE_OPTION) {
        configFile = saveFile.getSelectedFile();
        //           this.configfileNameTextField.setText(configFile.getName());
        LOG.info(
                "Set configuration file to be saved as: " + configFile.getName());
//        } else {
        LOG.info("Save of configuration file cancelled.");
        //       }
    }//GEN-LAST:event_saveAsMenuItemActionPerformed

    private void saveMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveMenuItemActionPerformed
        JFileChooser saveFile = new JFileChooser();
        // save the CONFIG file
        //saveFile.setCurrentDirectory(dataFile);
        saveFile.setDialogTitle("Save configuration file");
//        int status = saveFile.showSaveDialog(datafileFormatOptionsPanel);
//        if (status == JFileChooser.APPROVE_OPTION) {
        configFile = saveFile.getSelectedFile();
        //           this.configfileNameTextField.setText(configFile.getName());
        LOG.info(
                "Set configuration file to be saved as: " + configFile.getName());
//        } else {
        LOG.info("Save of configuration file cancelled.");
        //       }
    }//GEN-LAST:event_saveMenuItemActionPerformed

    private void aboutMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aboutMenuItemActionPerformed
        AboutDialog.main(new String[]{""});
    }//GEN-LAST:event_aboutMenuItemActionPerformed

    /**
     * Open a configuration file.
     */
    public void openConfigfile() {
        JFileChooser openFile = new JFileChooser();
        openFile.addChoosableFileFilter(new FileNameExtensionFilter(
                "CANARY-EDS configuration file",
                new String[]{"edsy", "edsj", "yml", "json"}));
        int returnVal = openFile.showOpenDialog(null);
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            try {
                eds = new CANARY();
                configFile = openFile.getSelectedFile();
                ArgumentParser parser = CANARY.getNewParser();
                parser = CANARY.addArguments(parser);
                Namespace res = parser.parseArgs(args);
                eds.setup(res);
                //This is where a real application would open the file.
                LOG.info("Opening: " + configFile.getName() + ".");
                this.configfileTextField.setText(configFile.getName());
                HashMap config = eds.parseConfigFile(
                        configFile.getAbsolutePath());
                if (config == null) {
                    throw new ConfigurationException(
                            "Failed to load the configuration file: " + configFile.getName());
                } else {
                    eds.configure(config);
                }
                statusText.setText("Ready");
            } catch (ConfigurationException ex) {
                LOG.error(
                        "Failed to load the configuration file: " + configFile.getName(),
                        ex);
            } catch (ArgumentParserException ex) {
                Logger.getLogger(AppMain.class.getName()).log(
                        java.util.logging.Level.SEVERE,
                        null, ex);
            }
        } else {
            LOG.info("Open command cancelled by user.");
        }
    }

    /**
     * Start CANARY-EDS execution. Calls the {@link launch} method with the full
     * path of the configuration file as a parameter.
     * <p>
     * @param evt
     */
    public void startExecution(java.awt.event.ActionEvent evt) {
        try {
            // TODO create a GUI to startExecution/stop/save CANARY
            statusText.setText("Starting Up");
            // Set command line options and configuration file on eds object
            //   loading configuration file returns a org.canaryeds.core.ControllerImpl
            //   object
            eds.initialize();
            ctrl = eds.getController();
            new Thread(ctrl).start();
            StatusUpdater status = new StatusUpdater(statusText,eds,ctrl);
            statusMonitor.scheduleAtFixedRate(status, 1, 1, TimeUnit.SECONDS);
            // Run the CANARY-EDS program, the logic of which is going to be
            //   contained in the ControllerImpl control object
            //statusText.setText("Running");
            // Shutdown and clean up any remaining threads, etc.
        } catch (ConfigurationException ex) {
            LOG.fatal(messages.getString("err.config"), ex);
            LOG.info(messages.getString("exit.failure"));
        } catch (Exception ex) {
            LOG.fatal(messages.getString("err.unknown"), ex);
            LOG.info(messages.getString("exit.error"));
        }
    }

    /**
     * Pause CANARY-EDS execution. This can be un-paused by calling this
     * function a second time.
     * <p>
     * @param evt
     */
    public void pauseExecution(java.awt.event.ActionEvent evt) {
        if (pauseButton.isSelected()) {
            //eds.pauseExecution();
            //statusText.setText("Paused ...");
        } else {
            //eds.resumeExecution();
            //statusText.setText("Running");
        }
    }

    /**
     * Cancel CANARY-EDS execution. Use a pop-up modal dialog to verify
     * cancellation before actually canceling.
     * <p>
     * @param evt
     */
    public void cancelExecution(java.awt.event.ActionEvent evt) {
        ctrl.stopExecution();
        eds.shutdown();
        while (!statusMonitor.isShutdown()) {
            statusMonitor.shutdown();
        }
        statusText.setText("Cancelled.");
    }

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /*
         * Set the Nimbus look and feel
         */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /*
         * If Nimbus (introduced in Java SE 6) is not available, stay with the
         * default look and feel. For details see
         * http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;

                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(AppMain.class
                    .getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(AppMain.class
                    .getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(AppMain.class
                    .getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(AppMain.class
                    .getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>
        AppMain.args = args;
        /*
         * Create and display the form
         */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new AppMain().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JMenuItem aboutMenuItem;
    private javax.swing.JButton cancelButton;
    private javax.swing.JMenuItem cancelMenuItem;
    private javax.swing.JLabel configfileLabel;
    private javax.swing.JTextField configfileTextField;
    private javax.swing.JMenuItem contentsMenuItem;
    private javax.swing.JMenuItem exitMenuItem;
    private javax.swing.JMenu fileMenu;
    private javax.swing.JMenu helpMenu;
    private javax.swing.JLabel logAreaLabel;
    private javax.swing.JComboBox logLevelCBox;
    private javax.swing.JLabel logLevelLabel;
    private javax.swing.JScrollPane logScrollPane;
    private javax.swing.JTextArea logTextArea;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JMenuItem openMenuItem;
    private javax.swing.JToggleButton pauseButton;
    private javax.swing.JCheckBoxMenuItem pauseMenuItem;
    private javax.swing.JMenu runMenu;
    private javax.swing.JMenuItem saveAsMenuItem;
    private javax.swing.JMenuItem saveMenuItem;
    private javax.swing.JButton startButton;
    private javax.swing.JMenuItem startMenuItem;
    private javax.swing.JLabel statusLabel;
    private javax.swing.JLabel statusText;
    private org.jdesktop.beansbinding.BindingGroup bindingGroup;
    // End of variables declaration//GEN-END:variables
}
