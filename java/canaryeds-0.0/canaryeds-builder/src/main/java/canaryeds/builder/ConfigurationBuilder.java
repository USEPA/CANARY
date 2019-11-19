/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package canaryeds.builder;

import java.awt.image.BufferedImage;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;

/**
 *
 * @author dbhart
 */
public class ConfigurationBuilder extends javax.swing.JFrame {

    private static final Logger LOG = Logger.getLogger(ConfigurationBuilder.class.getName());
    private Analyzer analyzer = new Analyzer();
    JFileChooser openFile = null;
    JFileChooser saveFile = null;
    File dataFile = null;
    File configFile = null;
    HashMap config = null;

    /**
     * Creates new form ConfigurationBuilder
     */
    public ConfigurationBuilder() {
        initComponents();
        dataFormatButtonGroup.add(rowPerValueFormatRadioButton);
        dataFormatButtonGroup.add(rowPerStepFormatRadioButton);
        configFormatButtonGroup.add(configfileV4FormatRadioButton);
        configFormatButtonGroup.add(configfileV5FormatRadioButton);
        TextAreaHandler handler = new TextAreaHandler(this.messageLogTextArea);
        LOG.addHandler(handler);
        analyzer.setLogHandler(handler);
        BufferedImage img;
        try {
            img = ImageIO.read(this.getClass().getResource("/icon.png"));
            this.setIconImage(img);
        } catch (IOException ex) {
            Logger.getLogger(ConfigurationBuilder.class.getName()).log(Level.SEVERE, null, ex);
        }
        //this.setName("CANARY-EDS Configuration File Builder");
    }

    private void updateFieldSep() {
        String contents = fieldSepTextField.getText();
        if (contents.length() > 0) {
            analyzer.setFieldSep(contents.charAt(0));
        }
    }

    private void updateFieldList(JComboBox comboBox, int index) {
        String[] listVals = analyzer.getFields((Integer) this.numHeaderLinesSpinner.getValue());
        if (listVals != null) {
            this.datafileFieldsPreviewList.setListData(listVals);
            comboBox.removeAllItems();
            comboBox.addItem("-- do not use / not enough fields --");
            for (int i = 0; i < listVals.length; i++) {
                comboBox.addItem(listVals[i]);
                if (comboBox.getItemCount() > index) {
                    comboBox.setSelectedIndex(index);
                } else {
                    comboBox.setSelectedIndex(0);
                }
            }
        }
    }

    private void updateStepFieldList() {
        String[] listVals = analyzer.getFields((Integer) this.numHeaderLinesSpinner.getValue());
        if (listVals != null) {
            this.datafileFieldsPreviewList.setListData(listVals);
            stepFieldComboBox.removeAllItems();
            for (int i = 0; i < listVals.length; i++) {
                stepFieldComboBox.addItem(listVals[i]);
                stepFieldComboBox.setSelectedIndex(0);
            }
        }
    }

    private void updateSampleStepValue() {
        String[] nextVals = analyzer.getFields((Integer) this.numHeaderLinesSpinner.getValue() + 1);
        int selIdx = stepFieldComboBox.getSelectedIndex();
        if (nextVals != null) {
            if (nextVals.length > selIdx) {
                sampleStepTextField1.setText(nextVals[selIdx]);
            }
        }
    }

    private void setDataFormat() {
        if (rowPerStepFormatRadioButton.isSelected()) {
            analyzer.setDataFormat(Analyzer.FileFormat.SPREADSHEET);
            disableRowFormat();
        } else {
            analyzer.setDataFormat(Analyzer.FileFormat.TABLE);
            enableRowFormat();
        }
        updateRowFormatFields();
    }

    private void updateRowFormatFields() {
        analyzer.setTagColumn(tagFieldComboBox.getSelectedIndex() - 1);
        analyzer.setValueColumn(valueFieldComboBox.getSelectedIndex() - 1);
        analyzer.setQualityColumn(qualFieldComboBox.getSelectedIndex() - 1);
    }

    private void disableRowFormat() {
        qualFieldComboBox.removeAllItems();
        tagFieldComboBox.removeAllItems();
        valueFieldComboBox.removeAllItems();
        qualFieldComboBox.addItem("not available in this data format");
        tagFieldComboBox.addItem("not available in this data format");
        valueFieldComboBox.addItem("not available in this data format");
        qualFieldComboBox.setEnabled(false);
        tagFieldComboBox.setEnabled(false);
        valueFieldComboBox.setEnabled(false);
        qualFieldLabel.setEnabled(false);
        tagFieldLabel.setEnabled(false);
        valueFieldLabel.setEnabled(false);
    }

    private void enableRowFormat() {
        qualFieldComboBox.setEnabled(true);
        tagFieldComboBox.setEnabled(true);
        valueFieldComboBox.setEnabled(true);
        qualFieldLabel.setEnabled(true);
        tagFieldLabel.setEnabled(true);
        valueFieldLabel.setEnabled(true);
        qualFieldComboBox.removeAllItems();
        tagFieldComboBox.removeAllItems();
        valueFieldComboBox.removeAllItems();
        if (openFile == null) {
            qualFieldComboBox.addItem("data file not yet loaded ...");
            tagFieldComboBox.addItem("data file not yet loaded ...");
            valueFieldComboBox.addItem("data file not yet loaded ...");
        } else {
            this.updateFieldList(tagFieldComboBox, 2);
            this.updateFieldList(valueFieldComboBox, 3);
            this.updateFieldList(qualFieldComboBox, 4);
        }
    }

    private void setStepFormat() {
        analyzer.setStepFormat(stepFormatTextField.getText());
    }

    private void dumpV4ConfigurationString() {
        String output = "---\n# CANARY-EDS v4.3 configuartion file\n";
        output += "# Generated using ConfigFileBuilder v4.3\n";
        DumperOptions options = new DumperOptions();
        options.setWidth(80);
        options.setIndent(2);
        options.setPrettyFlow(true);
        options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK);
        Yaml yaml = new Yaml(options);
        HashMap fullConfig = analyzer.getV4Config();
        HashMap temp = new HashMap();
        temp.put("canary", fullConfig.get("canary"));
        output = output + "\n# controller options\n" + yaml.dump(temp);
        temp = new HashMap();
        temp.put("timing options", fullConfig.get("timing options"));
        output = output + "\n# timing options\n" + yaml.dump(temp);
        temp = new HashMap();
        temp.put("data sources", fullConfig.get("data sources"));
        output = output + "\n# inputs and outputs\n" + yaml.dump(temp);
        temp = new HashMap();
        temp.put("signals", fullConfig.get("signals"));
        output = output + "\n# data channels (SCADA signals)\n" + yaml.dump(temp);
        temp = new HashMap();
        temp.put("algorithms", fullConfig.get("algorithms"));
        output = output + "\n# event detection algorithm settings\n" + yaml.dump(temp);
        temp = new HashMap();
        temp.put("monitoring stations", fullConfig.get("monitoring stations"));
        output = output + "\n# monitoring stations (logical groups of all the above)\n" + yaml.dump(temp);
        this.configfileEditorPane.setText(output);
        LOG.info("Default settings output to configuration editor.");
    }

    private void saveConfigFile() {
        int status;
        if (configFile == null) {
            status = saveAsDialog();
        } else {
            status = JFileChooser.APPROVE_OPTION;
        }
        if (status == JFileChooser.APPROVE_OPTION) {
            FileWriter outFile;
            BufferedWriter writer;
            try {
                outFile = new FileWriter(configFile);
                writer = new BufferedWriter(outFile);
                writer.write(configfileEditorPane.getText());
                writer.flush();
                writer.close();
                outFile.close();
                LOG.info("Configuration file saved to: " + configFile.getName());
            } catch (IOException ex) {
                LOG.log(Level.SEVERE, "Configuration file save failed!", ex);
            }
        } else {
            LOG.info("Save of configuration file cancelled.");
        }
    }

    private int saveAsDialog() {
        saveFile = new JFileChooser();
        saveFile.setCurrentDirectory(dataFile);
        saveFile.setDialogTitle("Save configuration file");
        int status = saveFile.showSaveDialog(datafileFormatOptionsPanel);
        if (status == JFileChooser.APPROVE_OPTION) {
            configFile = saveFile.getSelectedFile();
            this.configfileNameTextField.setText(configFile.getName());
            LOG.info("Set configuration file to be saved as: " + configFile.getName());
        } else {
            LOG.info("Save of configuration file cancelled.");
        }
        return status;
    }

    private void openDataFile() {
        openFile = new JFileChooser();
        openFile.addChoosableFileFilter(new FileNameExtensionFilter("Comma-Separated Values (CSV) file", new String[]{"csv"}));
        openFile.addChoosableFileFilter(new FileNameExtensionFilter("Tab-Separated values file", new String[]{"tab"}));
        openFile.addChoosableFileFilter(new FileNameExtensionFilter("Formatted text file", new String[]{"prn"}));
        openFile.addChoosableFileFilter(new FileNameExtensionFilter("Any text-formatted data file", new String[]{"csv", "tab", "dat", "prn", "txt"}));
        int returnVal = openFile.showOpenDialog(null);
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            dataFile = openFile.getSelectedFile();
            //This is where a real application would open the file.
            LOG.info("Opening: " + dataFile.getName() + ".");
            this.datafileNameTextField.setText(dataFile.getName());
            analyzer.setDataFile(dataFile);
        } else {
            LOG.info("Open command cancelled by user.");
        }
        updateStepFieldList();
        setDataFormat();
        updateFieldSep();
        this.optionsAndSettingsTabbedPane.setSelectedIndex(0);
        //updateSampleStepValue();
    }

    private void chooseFieldSep() {
        int index = fieldSepComboBox.getSelectedIndex();
        switch (index) {
            case 0:
                fieldSepTextField.setEnabled(false);
                fieldSepTextField.setText(",");
                updateFieldSep();
                updateStepFieldList();
                setDataFormat();
                updateSampleStepValue();
                break;
            case 1:
                fieldSepTextField.setEnabled(false);
                fieldSepTextField.setText(";");
                updateFieldSep();
                updateStepFieldList();
                setDataFormat();
                updateSampleStepValue();
                break;
            case 2:
                fieldSepTextField.setEnabled(false);
                fieldSepTextField.setText(" ");
                updateFieldSep();
                updateStepFieldList();
                setDataFormat();
                updateSampleStepValue();
                break;
            case 3:
                fieldSepTextField.setEnabled(false);
                fieldSepTextField.setText("\t");
                analyzer.setFieldSep('\t');
                updateFieldSep();
                updateStepFieldList();
                setDataFormat();
                updateSampleStepValue();
                break;
            case 4:
                fieldSepTextField.setEnabled(true);
                String contents = fieldSepTextField.getText();
                if (contents.contentEquals("\t")) {
                    fieldSepTextField.setText("");
                }
                fieldSepComboBox.transferFocus();
                break;
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

        dataFormatButtonGroup = new javax.swing.ButtonGroup();
        configFormatButtonGroup = new javax.swing.ButtonGroup();
        filenamePanel = new javax.swing.JPanel();
        datafileNameLabel = new javax.swing.JLabel();
        configfileNameLabel = new javax.swing.JLabel();
        datafileNameTextField = new javax.swing.JTextField();
        configfileNameTextField = new javax.swing.JTextField();
        messageLogPanel = new javax.swing.JPanel();
        messageLogScrollPane = new javax.swing.JScrollPane();
        messageLogTextArea = new javax.swing.JTextArea();
        optionsAndSettingsTabbedPane = new javax.swing.JTabbedPane();
        datafileOptionsTabSplitPane = new javax.swing.JSplitPane();
        datafileFormatOptionsPanel = new javax.swing.JPanel();
        numHeaderLinesSpinner = new javax.swing.JSpinner();
        numHeaderLinesLabel = new javax.swing.JLabel();
        fieldSepComboBox = new javax.swing.JComboBox();
        fieldSepLabel = new javax.swing.JLabel();
        fieldSepTextField = new javax.swing.JTextField();
        datafileFormatLabel = new javax.swing.JLabel();
        rowPerStepFormatRadioButton = new javax.swing.JRadioButton();
        rowPerValueFormatRadioButton = new javax.swing.JRadioButton();
        stepFieldComboBox = new javax.swing.JComboBox();
        stepFieldLabel = new javax.swing.JLabel();
        stepFormatTextField = new javax.swing.JTextField();
        stepFormatLabel = new javax.swing.JLabel();
        tagFieldLabel = new javax.swing.JLabel();
        tagFieldComboBox = new javax.swing.JComboBox();
        valueFieldLabel = new javax.swing.JLabel();
        valueFieldComboBox = new javax.swing.JComboBox();
        qualFieldLabel = new javax.swing.JLabel();
        qualFieldComboBox = new javax.swing.JComboBox();
        analyzeAndGenerateConfigButton = new javax.swing.JButton();
        datafileFieldsPreviewPanel = new javax.swing.JPanel();
        datafileFieldsPreviewScrollPane = new javax.swing.JScrollPane();
        datafileFieldsPreviewList = new javax.swing.JList();
        datafileFieldsPreviewTitleLabel = new javax.swing.JLabel();
        sampleStepLabel = new javax.swing.JLabel();
        sampleStepTextField1 = new javax.swing.JTextField();
        configfileEditorSplitPane = new javax.swing.JSplitPane();
        configfileEditorButtonsPanel = new javax.swing.JPanel();
        configfileV4FormatRadioButton = new javax.swing.JRadioButton();
        configfileV5FormatRadioButton = new javax.swing.JRadioButton();
        resetConfigfileButton = new javax.swing.JButton();
        saveButton = new javax.swing.JButton();
        saveAsButton = new javax.swing.JButton();
        configfileEditorTextPanel = new javax.swing.JPanel();
        configfileEditorScrollPane = new javax.swing.JScrollPane();
        configfileEditorPane = new javax.swing.JEditorPane();
        menuBar = new javax.swing.JMenuBar();
        fileMenu = new javax.swing.JMenu();
        openMenuItem = new javax.swing.JMenuItem();
        saveMenuItem = new javax.swing.JMenuItem();
        saveAsMenuItem = new javax.swing.JMenuItem();
        exitMenuItem = new javax.swing.JMenuItem();
        editMenu = new javax.swing.JMenu();
        cutMenuItem = new javax.swing.JMenuItem();
        copyMenuItem = new javax.swing.JMenuItem();
        pasteMenuItem = new javax.swing.JMenuItem();
        deleteMenuItem = new javax.swing.JMenuItem();
        helpMenu = new javax.swing.JMenu();
        contentsMenuItem = new javax.swing.JMenuItem();
        aboutMenuItem = new javax.swing.JMenuItem();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("CANARY-EDS Configuration File Builder");

        filenamePanel.setBorder(javax.swing.BorderFactory.createLineBorder(new java.awt.Color(0, 0, 0)));

        datafileNameLabel.setText("Data file to analyze");

        configfileNameLabel.setText("Configuration file");

        datafileNameTextField.setEditable(false);
        datafileNameTextField.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        datafileNameTextField.setText("None selected");
        datafileNameTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                datafileNameTextFieldActionPerformed(evt);
            }
        });

        configfileNameTextField.setEditable(false);
        configfileNameTextField.setHorizontalAlignment(javax.swing.JTextField.TRAILING);
        configfileNameTextField.setText("None selected");
        configfileNameTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                configfileNameTextFieldActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout filenamePanelLayout = new org.jdesktop.layout.GroupLayout(filenamePanel);
        filenamePanel.setLayout(filenamePanelLayout);
        filenamePanelLayout.setHorizontalGroup(
            filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(filenamePanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(datafileNameLabel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 140, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(configfileNameLabel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 140, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.UNRELATED)
                .add(filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(datafileNameTextField)
                    .add(configfileNameTextField))
                .addContainerGap())
        );
        filenamePanelLayout.setVerticalGroup(
            filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(filenamePanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(datafileNameTextField)
                    .add(datafileNameLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .add(filenamePanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(configfileNameTextField, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(configfileNameLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );

        messageLogPanel.setBorder(javax.swing.BorderFactory.createTitledBorder("Message and Progress Log"));

        messageLogTextArea.setColumns(20);
        messageLogTextArea.setRows(5);
        messageLogTextArea.setText("--- CANARY-EDS Configuration Builder ---");
        messageLogScrollPane.setViewportView(messageLogTextArea);

        org.jdesktop.layout.GroupLayout messageLogPanelLayout = new org.jdesktop.layout.GroupLayout(messageLogPanel);
        messageLogPanel.setLayout(messageLogPanelLayout);
        messageLogPanelLayout.setHorizontalGroup(
            messageLogPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(messageLogPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(messageLogScrollPane)
                .addContainerGap())
        );
        messageLogPanelLayout.setVerticalGroup(
            messageLogPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(messageLogPanelLayout.createSequentialGroup()
                .add(messageLogScrollPane, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 94, Short.MAX_VALUE)
                .addContainerGap())
        );

        datafileOptionsTabSplitPane.setDividerLocation(402);

        numHeaderLinesSpinner.setModel(new javax.swing.SpinnerNumberModel(0, 0, 99, 1));
        numHeaderLinesSpinner.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                numHeaderLinesSpinnerStateChanged(evt);
            }
        });

        numHeaderLinesLabel.setText("Number of header lines before column titles");

        fieldSepComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Comma ( , )", "Semi-colon ( ; )", "Space (   )", "Tab ( \t )", "Custom ..." }));
        fieldSepComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                fieldSepComboBoxActionPerformed(evt);
            }
        });

        fieldSepLabel.setText("Field separator:");

        fieldSepTextField.setText(",");
        fieldSepTextField.setEnabled(false);
        fieldSepTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                fieldSepTextFieldActionPerformed(evt);
            }
        });
        fieldSepTextField.addFocusListener(new java.awt.event.FocusAdapter() {
            public void focusLost(java.awt.event.FocusEvent evt) {
                fieldSepTextFieldFocusLost(evt);
            }
        });
        fieldSepTextField.addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyReleased(java.awt.event.KeyEvent evt) {
                fieldSepTextFieldKeyReleased(evt);
            }
        });

        datafileFormatLabel.setText("File Format:");

        rowPerStepFormatRadioButton.setSelected(true);
        rowPerStepFormatRadioButton.setText("One row per step");
        rowPerStepFormatRadioButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                rowPerStepFormatRadioButtonActionPerformed(evt);
            }
        });

        rowPerValueFormatRadioButton.setText("One tag per row");
        rowPerValueFormatRadioButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                rowPerValueFormatRadioButtonActionPerformed(evt);
            }
        });

        stepFieldComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "data file not yet loaded ..." }));
        stepFieldComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                stepFieldComboBoxActionPerformed(evt);
            }
        });

        stepFieldLabel.setText("Step field:");

        stepFormatTextField.setText("MM/dd/yyyy HH:mm:ss");
        stepFormatTextField.setToolTipText("<html>\n<table>\n<tr><th>Letter</th><th>Date or Time Component</th><th>Presentation</th><th>Examples</th></tr>\n<tr><td>G </td><td>Era designator </td><td>Text </td><td>AD</td></tr>\n<tr><td>y </td><td>Year </td><td>Year </td><td>1996; 96</td></tr>\n<tr><td>M </td><td>Month in year </td><td>Month </td><td>July; Jul; 07</td></tr>\n<tr><td>w </td><td>Week in year </td><td>Number </td><td>27</td></tr>\n<tr><td>W </td><td>Week in month </td><td>Number </td><td>2</td></tr>\n<tr><td>D </td><td>Day in year </td><td>Number </td><td>189</td></tr>\n<tr><td>d </td><td>Day in month </td><td>Number </td><td>10</td></tr>\n<tr><td>F </td><td>Day of week in month </td><td>Number </td><td>2</td></tr>\n<tr><td>E </td><td>Day in week </td><td>Text </td><td>Tuesday; Tue</td></tr>\n<tr><td>a </td><td>Am/pm marker </td><td>Text </td><td>PM</td></tr>\n<tr><td>H </td><td>Hour in day (0-23) </td><td>Number </td><td>0</td></tr>\n<tr><td>k </td><td>Hour in day (1-24) </td><td>Number </td><td>24</td></tr>\n<tr><td>K </td><td>Hour in am/pm (0-11) </td><td>Number </td><td>0</td></tr>\n<tr><td>h </td><td>Hour in am/pm (1-12) </td><td>Number </td><td>12</td></tr>\n<tr><td>m </td><td>Minute in hour </td><td>Number </td><td>30</td></tr>\n<tr><td>s </td><td>Second in minute </td><td>Number </td><td>55</td></tr>\n<tr><td>S </td><td>Millisecond </td><td>Number </td><td>978</td></tr>\n<tr><td>z </td><td>Time zone </td><td>General time zone </td><td>Pacific Standard Time; PST; GMT-08:00</td></tr>\n<tr><td>Z </td><td>Time zone </td><td>RFC 822 time zone </td><td>-0800 </td></tr>\n</html>");
        stepFormatTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                stepFormatTextFieldActionPerformed(evt);
            }
        });
        stepFormatTextField.addFocusListener(new java.awt.event.FocusAdapter() {
            public void focusLost(java.awt.event.FocusEvent evt) {
                stepFormatTextFieldFocusLost(evt);
            }
        });

        stepFormatLabel.setText("Step format:");

        tagFieldLabel.setText("Tag field:");
        tagFieldLabel.setEnabled(false);

        tagFieldComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "not available in this data format" }));
        tagFieldComboBox.setEnabled(false);
        tagFieldComboBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                tagFieldComboBoxItemStateChanged(evt);
            }
        });
        tagFieldComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                tagFieldComboBoxActionPerformed(evt);
            }
        });

        valueFieldLabel.setText("Value field:");
        valueFieldLabel.setEnabled(false);

        valueFieldComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "not available in this data format" }));
        valueFieldComboBox.setEnabled(false);
        valueFieldComboBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                valueFieldComboBoxItemStateChanged(evt);
            }
        });
        valueFieldComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                valueFieldComboBoxActionPerformed(evt);
            }
        });

        qualFieldLabel.setText("Quality field:");
        qualFieldLabel.setEnabled(false);

        qualFieldComboBox.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "not available in this data format" }));
        qualFieldComboBox.setEnabled(false);
        qualFieldComboBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                qualFieldComboBoxItemStateChanged(evt);
            }
        });
        qualFieldComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                qualFieldComboBoxActionPerformed(evt);
            }
        });

        analyzeAndGenerateConfigButton.setText("Analyze Data and Generate Configuration");
        analyzeAndGenerateConfigButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                analyzeAndGenerateConfigButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout datafileFormatOptionsPanelLayout = new org.jdesktop.layout.GroupLayout(datafileFormatOptionsPanel);
        datafileFormatOptionsPanel.setLayout(datafileFormatOptionsPanelLayout);
        datafileFormatOptionsPanelLayout.setHorizontalGroup(
            datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(datafileFormatOptionsPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(analyzeAndGenerateConfigButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(datafileFormatOptionsPanelLayout.createSequentialGroup()
                        .add(numHeaderLinesSpinner, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(numHeaderLinesLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                    .add(org.jdesktop.layout.GroupLayout.TRAILING, datafileFormatOptionsPanelLayout.createSequentialGroup()
                        .add(fieldSepLabel)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(fieldSepComboBox, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                        .add(fieldSepTextField, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                    .add(org.jdesktop.layout.GroupLayout.TRAILING, datafileFormatOptionsPanelLayout.createSequentialGroup()
                        .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, stepFormatLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, stepFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, datafileFormatLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, tagFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, valueFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(qualFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 157, Short.MAX_VALUE))
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.UNRELATED)
                        .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                            .add(qualFieldComboBox, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(valueFieldComboBox, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(tagFieldComboBox, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, datafileFormatOptionsPanelLayout.createSequentialGroup()
                                .add(rowPerStepFormatRadioButton)
                                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                                .add(rowPerValueFormatRadioButton))
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, stepFieldComboBox, 0, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .add(org.jdesktop.layout.GroupLayout.TRAILING, stepFormatTextField))))
                .addContainerGap())
        );
        datafileFormatOptionsPanelLayout.setVerticalGroup(
            datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(datafileFormatOptionsPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(numHeaderLinesLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(numHeaderLinesSpinner))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                    .add(fieldSepLabel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 27, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(fieldSepComboBox, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                    .add(fieldSepTextField, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.BASELINE)
                        .add(rowPerStepFormatRadioButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .add(rowPerValueFormatRadioButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                    .add(datafileFormatLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(stepFieldComboBox)
                    .add(stepFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(stepFormatTextField)
                    .add(stepFormatLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(tagFieldComboBox)
                    .add(tagFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(valueFieldComboBox)
                    .add(valueFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFormatOptionsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(qualFieldComboBox)
                    .add(qualFieldLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(analyzeAndGenerateConfigButton)
                .addContainerGap())
        );

        datafileOptionsTabSplitPane.setLeftComponent(datafileFormatOptionsPanel);

        datafileFieldsPreviewList.setModel(new javax.swing.AbstractListModel() {
            String[] strings = { "datafile not yet loaded ..." };
            public int getSize() { return strings.length; }
            public Object getElementAt(int i) { return strings[i]; }
        });
        datafileFieldsPreviewScrollPane.setViewportView(datafileFieldsPreviewList);

        datafileFieldsPreviewTitleLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        datafileFieldsPreviewTitleLabel.setText("Field names read in from data file");

        sampleStepLabel.setText("Sample Step value:");

        sampleStepTextField1.setEditable(false);

        org.jdesktop.layout.GroupLayout datafileFieldsPreviewPanelLayout = new org.jdesktop.layout.GroupLayout(datafileFieldsPreviewPanel);
        datafileFieldsPreviewPanel.setLayout(datafileFieldsPreviewPanelLayout);
        datafileFieldsPreviewPanelLayout.setHorizontalGroup(
            datafileFieldsPreviewPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(datafileFieldsPreviewPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(datafileFieldsPreviewPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(datafileFieldsPreviewScrollPane)
                    .add(datafileFieldsPreviewTitleLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 284, Short.MAX_VALUE)
                    .add(datafileFieldsPreviewPanelLayout.createSequentialGroup()
                        .add(sampleStepLabel)
                        .addPreferredGap(org.jdesktop.layout.LayoutStyle.UNRELATED)
                        .add(sampleStepTextField1)))
                .addContainerGap())
        );
        datafileFieldsPreviewPanelLayout.setVerticalGroup(
            datafileFieldsPreviewPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(org.jdesktop.layout.GroupLayout.TRAILING, datafileFieldsPreviewPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(datafileFieldsPreviewTitleLabel)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFieldsPreviewScrollPane, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 247, Short.MAX_VALUE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(datafileFieldsPreviewPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING, false)
                    .add(sampleStepTextField1)
                    .add(sampleStepLabel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );

        datafileOptionsTabSplitPane.setRightComponent(datafileFieldsPreviewPanel);

        optionsAndSettingsTabbedPane.addTab("Data File Options", datafileOptionsTabSplitPane);

        configfileEditorSplitPane.setDividerLocation(620);

        configfileV4FormatRadioButton.setSelected(true);
        configfileV4FormatRadioButton.setText("v4.3 format");

        configfileV5FormatRadioButton.setText("v5 format");
        configfileV5FormatRadioButton.setEnabled(false);

        resetConfigfileButton.setText("Reset");
        resetConfigfileButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                resetConfigfileButtonActionPerformed(evt);
            }
        });

        saveButton.setText("Save");
        saveButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveButtonActionPerformed(evt);
            }
        });

        saveAsButton.setText("Save as ...");
        saveAsButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveAsButtonActionPerformed(evt);
            }
        });

        org.jdesktop.layout.GroupLayout configfileEditorButtonsPanelLayout = new org.jdesktop.layout.GroupLayout(configfileEditorButtonsPanel);
        configfileEditorButtonsPanel.setLayout(configfileEditorButtonsPanelLayout);
        configfileEditorButtonsPanelLayout.setHorizontalGroup(
            configfileEditorButtonsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(configfileEditorButtonsPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(configfileEditorButtonsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
                    .add(configfileV4FormatRadioButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(configfileV5FormatRadioButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(resetConfigfileButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(saveAsButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(saveButton, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        configfileEditorButtonsPanelLayout.setVerticalGroup(
            configfileEditorButtonsPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(configfileEditorButtonsPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(configfileV4FormatRadioButton)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(configfileV5FormatRadioButton)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(resetConfigfileButton)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED, 174, Short.MAX_VALUE)
                .add(saveButton)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(saveAsButton)
                .addContainerGap())
        );

        configfileEditorSplitPane.setRightComponent(configfileEditorButtonsPanel);

        configfileEditorPane.setFont(new java.awt.Font("Lucida Console", 0, 12)); // NOI18N
        configfileEditorScrollPane.setViewportView(configfileEditorPane);

        org.jdesktop.layout.GroupLayout configfileEditorTextPanelLayout = new org.jdesktop.layout.GroupLayout(configfileEditorTextPanel);
        configfileEditorTextPanel.setLayout(configfileEditorTextPanelLayout);
        configfileEditorTextPanelLayout.setHorizontalGroup(
            configfileEditorTextPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(configfileEditorTextPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(configfileEditorScrollPane)
                .addContainerGap())
        );
        configfileEditorTextPanelLayout.setVerticalGroup(
            configfileEditorTextPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(configfileEditorTextPanelLayout.createSequentialGroup()
                .addContainerGap()
                .add(configfileEditorScrollPane, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 293, Short.MAX_VALUE)
                .addContainerGap())
        );

        configfileEditorSplitPane.setLeftComponent(configfileEditorTextPanel);

        optionsAndSettingsTabbedPane.addTab("Configuration File", configfileEditorSplitPane);

        fileMenu.setMnemonic('f');
        fileMenu.setText("File");

        openMenuItem.setMnemonic('o');
        openMenuItem.setText("Open");
        openMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                openMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(openMenuItem);

        saveMenuItem.setMnemonic('s');
        saveMenuItem.setText("Save");
        saveMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(saveMenuItem);

        saveAsMenuItem.setMnemonic('a');
        saveAsMenuItem.setText("Save As ...");
        saveAsMenuItem.setDisplayedMnemonicIndex(5);
        saveAsMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                saveAsMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(saveAsMenuItem);

        exitMenuItem.setMnemonic('x');
        exitMenuItem.setText("Exit");
        exitMenuItem.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                exitMenuItemActionPerformed(evt);
            }
        });
        fileMenu.add(exitMenuItem);

        menuBar.add(fileMenu);

        editMenu.setMnemonic('e');
        editMenu.setText("Edit");

        cutMenuItem.setMnemonic('t');
        cutMenuItem.setText("Cut");
        editMenu.add(cutMenuItem);

        copyMenuItem.setMnemonic('y');
        copyMenuItem.setText("Copy");
        editMenu.add(copyMenuItem);

        pasteMenuItem.setMnemonic('p');
        pasteMenuItem.setText("Paste");
        editMenu.add(pasteMenuItem);

        deleteMenuItem.setMnemonic('d');
        deleteMenuItem.setText("Delete");
        editMenu.add(deleteMenuItem);

        menuBar.add(editMenu);

        helpMenu.setMnemonic('h');
        helpMenu.setText("Help");

        contentsMenuItem.setMnemonic('c');
        contentsMenuItem.setText("Contents");
        helpMenu.add(contentsMenuItem);

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
            .add(org.jdesktop.layout.GroupLayout.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .add(layout.createParallelGroup(org.jdesktop.layout.GroupLayout.TRAILING)
                    .add(optionsAndSettingsTabbedPane, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 717, Short.MAX_VALUE)
                    .add(filenamePanel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .add(org.jdesktop.layout.GroupLayout.LEADING, messageLogPanel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(org.jdesktop.layout.GroupLayout.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .add(filenamePanel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(optionsAndSettingsTabbedPane)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(messageLogPanel, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void exitMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_exitMenuItemActionPerformed
        System.exit(0);
    }//GEN-LAST:event_exitMenuItemActionPerformed

    private void fieldSepComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_fieldSepComboBoxActionPerformed
        chooseFieldSep();
    }//GEN-LAST:event_fieldSepComboBoxActionPerformed

    private void fieldSepTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_fieldSepTextFieldActionPerformed
        updateFieldSep();
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_fieldSepTextFieldActionPerformed

    private void fieldSepTextFieldFocusLost(java.awt.event.FocusEvent evt) {//GEN-FIRST:event_fieldSepTextFieldFocusLost
        updateFieldSep();
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_fieldSepTextFieldFocusLost

    private void fieldSepTextFieldKeyReleased(java.awt.event.KeyEvent evt) {//GEN-FIRST:event_fieldSepTextFieldKeyReleased
        updateFieldSep();
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_fieldSepTextFieldKeyReleased

    private void stepFieldComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_stepFieldComboBoxActionPerformed
        analyzer.setStepColumn(stepFieldComboBox.getSelectedIndex());
        try {
            updateSampleStepValue();
        } catch (Exception e) {
        }
    }//GEN-LAST:event_stepFieldComboBoxActionPerformed

    private void tagFieldComboBoxItemStateChanged(java.awt.event.ItemEvent evt) {//GEN-FIRST:event_tagFieldComboBoxItemStateChanged
        updateRowFormatFields();
    }//GEN-LAST:event_tagFieldComboBoxItemStateChanged

    private void tagFieldComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_tagFieldComboBoxActionPerformed
        //
    }//GEN-LAST:event_tagFieldComboBoxActionPerformed

    private void stepFormatTextFieldFocusLost(java.awt.event.FocusEvent evt) {//GEN-FIRST:event_stepFormatTextFieldFocusLost
        setStepFormat();
    }//GEN-LAST:event_stepFormatTextFieldFocusLost

    private void stepFormatTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_stepFormatTextFieldActionPerformed
        setStepFormat();
    }//GEN-LAST:event_stepFormatTextFieldActionPerformed

    private void valueFieldComboBoxItemStateChanged(java.awt.event.ItemEvent evt) {//GEN-FIRST:event_valueFieldComboBoxItemStateChanged
        updateRowFormatFields();
    }//GEN-LAST:event_valueFieldComboBoxItemStateChanged

    private void valueFieldComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_valueFieldComboBoxActionPerformed
        //
    }//GEN-LAST:event_valueFieldComboBoxActionPerformed

    private void qualFieldComboBoxItemStateChanged(java.awt.event.ItemEvent evt) {//GEN-FIRST:event_qualFieldComboBoxItemStateChanged
        updateRowFormatFields();
    }//GEN-LAST:event_qualFieldComboBoxItemStateChanged

    private void qualFieldComboBoxActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_qualFieldComboBoxActionPerformed
        //
    }//GEN-LAST:event_qualFieldComboBoxActionPerformed

    private void analyzeAndGenerateConfigButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_analyzeAndGenerateConfigButtonActionPerformed
        boolean success = analyzer.analyze();
        if (success) {
            dumpV4ConfigurationString();
            this.optionsAndSettingsTabbedPane.setSelectedIndex(1);
        } else {
            java.awt.Toolkit.getDefaultToolkit().beep();
        }
    }//GEN-LAST:event_analyzeAndGenerateConfigButtonActionPerformed

    private void configfileNameTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_configfileNameTextFieldActionPerformed
        configFile = null;
        this.datafileNameTextField.setText("None selected");
        saveConfigFile();
    }//GEN-LAST:event_configfileNameTextFieldActionPerformed

    private void openMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_openMenuItemActionPerformed
        openDataFile();
    }//GEN-LAST:event_openMenuItemActionPerformed

    private void saveAsMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveAsMenuItemActionPerformed
        configFile = null;
        this.datafileNameTextField.setText("None selected");
        saveConfigFile();
    }//GEN-LAST:event_saveAsMenuItemActionPerformed

    private void saveMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveMenuItemActionPerformed
        saveConfigFile();
    }//GEN-LAST:event_saveMenuItemActionPerformed

    private void aboutMenuItemActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aboutMenuItemActionPerformed
        AboutDialog.main(new String[]{""});
    }//GEN-LAST:event_aboutMenuItemActionPerformed

    private void numHeaderLinesSpinnerStateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_numHeaderLinesSpinnerStateChanged
        analyzer.setNumHeaderLines(((Integer) numHeaderLinesSpinner.getValue()).intValue());
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_numHeaderLinesSpinnerStateChanged

    private void datafileNameTextFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_datafileNameTextFieldActionPerformed
        // TODO add your handling code here:
        openDataFile();
    }//GEN-LAST:event_datafileNameTextFieldActionPerformed

    private void resetConfigfileButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_resetConfigfileButtonActionPerformed
        LOG.info("Reverting changes back to defaults from data file analysis.");
        dumpV4ConfigurationString();
    }//GEN-LAST:event_resetConfigfileButtonActionPerformed

    private void saveButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveButtonActionPerformed
        saveConfigFile();
    }//GEN-LAST:event_saveButtonActionPerformed

    private void saveAsButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_saveAsButtonActionPerformed
        configFile = null;
        this.configfileNameTextField.setText("None selected");
        saveConfigFile();
    }//GEN-LAST:event_saveAsButtonActionPerformed

    private void rowPerStepFormatRadioButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_rowPerStepFormatRadioButtonActionPerformed
        updateFieldSep();
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_rowPerStepFormatRadioButtonActionPerformed

    private void rowPerValueFormatRadioButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_rowPerValueFormatRadioButtonActionPerformed
        updateFieldSep();
        updateStepFieldList();
        setDataFormat();
        updateSampleStepValue();
    }//GEN-LAST:event_rowPerValueFormatRadioButtonActionPerformed

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(ConfigurationBuilder.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(ConfigurationBuilder.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(ConfigurationBuilder.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(ConfigurationBuilder.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new ConfigurationBuilder().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JMenuItem aboutMenuItem;
    private javax.swing.JButton analyzeAndGenerateConfigButton;
    private javax.swing.ButtonGroup configFormatButtonGroup;
    private javax.swing.JPanel configfileEditorButtonsPanel;
    private javax.swing.JEditorPane configfileEditorPane;
    private javax.swing.JScrollPane configfileEditorScrollPane;
    private javax.swing.JSplitPane configfileEditorSplitPane;
    private javax.swing.JPanel configfileEditorTextPanel;
    private javax.swing.JLabel configfileNameLabel;
    private javax.swing.JTextField configfileNameTextField;
    private javax.swing.JRadioButton configfileV4FormatRadioButton;
    private javax.swing.JRadioButton configfileV5FormatRadioButton;
    private javax.swing.JMenuItem contentsMenuItem;
    private javax.swing.JMenuItem copyMenuItem;
    private javax.swing.JMenuItem cutMenuItem;
    private javax.swing.ButtonGroup dataFormatButtonGroup;
    private javax.swing.JList datafileFieldsPreviewList;
    private javax.swing.JPanel datafileFieldsPreviewPanel;
    private javax.swing.JScrollPane datafileFieldsPreviewScrollPane;
    private javax.swing.JLabel datafileFieldsPreviewTitleLabel;
    private javax.swing.JLabel datafileFormatLabel;
    private javax.swing.JPanel datafileFormatOptionsPanel;
    private javax.swing.JLabel datafileNameLabel;
    private javax.swing.JTextField datafileNameTextField;
    private javax.swing.JSplitPane datafileOptionsTabSplitPane;
    private javax.swing.JMenuItem deleteMenuItem;
    private javax.swing.JMenu editMenu;
    private javax.swing.JMenuItem exitMenuItem;
    private javax.swing.JComboBox fieldSepComboBox;
    private javax.swing.JLabel fieldSepLabel;
    private javax.swing.JTextField fieldSepTextField;
    private javax.swing.JMenu fileMenu;
    private javax.swing.JPanel filenamePanel;
    private javax.swing.JMenu helpMenu;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JPanel messageLogPanel;
    private javax.swing.JScrollPane messageLogScrollPane;
    private javax.swing.JTextArea messageLogTextArea;
    private javax.swing.JLabel numHeaderLinesLabel;
    private javax.swing.JSpinner numHeaderLinesSpinner;
    private javax.swing.JMenuItem openMenuItem;
    private javax.swing.JTabbedPane optionsAndSettingsTabbedPane;
    private javax.swing.JMenuItem pasteMenuItem;
    private javax.swing.JComboBox qualFieldComboBox;
    private javax.swing.JLabel qualFieldLabel;
    private javax.swing.JButton resetConfigfileButton;
    private javax.swing.JRadioButton rowPerStepFormatRadioButton;
    private javax.swing.JRadioButton rowPerValueFormatRadioButton;
    private javax.swing.JLabel sampleStepLabel;
    private javax.swing.JTextField sampleStepTextField1;
    private javax.swing.JButton saveAsButton;
    private javax.swing.JMenuItem saveAsMenuItem;
    private javax.swing.JButton saveButton;
    private javax.swing.JMenuItem saveMenuItem;
    private javax.swing.JComboBox stepFieldComboBox;
    private javax.swing.JLabel stepFieldLabel;
    private javax.swing.JLabel stepFormatLabel;
    private javax.swing.JTextField stepFormatTextField;
    private javax.swing.JComboBox tagFieldComboBox;
    private javax.swing.JLabel tagFieldLabel;
    private javax.swing.JComboBox valueFieldComboBox;
    private javax.swing.JLabel valueFieldLabel;
    // End of variables declaration//GEN-END:variables
}
