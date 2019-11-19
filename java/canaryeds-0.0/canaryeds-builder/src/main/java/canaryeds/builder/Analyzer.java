/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package canaryeds.builder;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import static java.lang.Math.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.SimpleTimeZone;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

/**
 *
 * @author dbhart
 */
public class Analyzer {

    private static final Logger LOG = Logger.getLogger(Analyzer.class.getName());
    private ArrayList<String> tags = null;
    private int stepColumn = -1;
    private int tagColumn = -1;
    private int valueColumn = -1;
    private int qualityColumn = -1;
    private FileFormat dataFormat = FileFormat.SPREADSHEET;
    private String stepFormat = "MM/dd/yyyy HH:mm:ss";
    private char fieldSep = ',';
    private File dataFile = null;
    private ArrayList<String> dataLines = new ArrayList();
    private int numHeaderLines = 0;
    private long stepMin = Long.MAX_VALUE;
    private long stepMax = Long.MIN_VALUE;
    private long stepDel = Long.MAX_VALUE;
    private String stepFieldName = null;
    private ArrayList<SimpleChannelDefn> channelDefs = null;

    public class SimpleChannelDefn {

        @Override
        public String toString() {
            return valType + " Field \'" + name + "\': [" + minValue + ", " + delValue + ", " + maxValue + "]";
        }

        public SimpleChannelDefn(String name, FieldFormat valType, double minValue, double maxValue, double delValue) {
            this.name = name;
            this.valType = valType;
            this.minValue = minValue;
            this.maxValue = maxValue;
            this.delValue = delValue;
        }
        public String name;
        public FieldFormat valType;
        public double minValue;
        public double maxValue;
        public double delValue;
    }

    /**
     * Get the value of numHeaderLines
     *
     * @return the value of numHeaderLines
     */
    public int getNumHeaderLines() {
        return numHeaderLines;
    }

    /**
     * Set the value of numHeaderLines
     *
     * @param numHeaderLines new value of numHeaderLines
     */
    public void setNumHeaderLines(int numHeaderLines) {
        if (this.numHeaderLines != numHeaderLines) {
            this.numHeaderLines = numHeaderLines;
            LOG.info("Set number of header lines (before column titles): " + numHeaderLines);
        }
    }

    public int getTagColumn() {
        return tagColumn;
    }

    public void setTagColumn(int tagColumn) {
        if (this.tagColumn != tagColumn) {
            if (tagColumn < 0 && this.tagColumn >= 0) {
                LOG.info("Tag column unset");
            } else if (tagColumn >= 0) {
                LOG.info("Tag contained in column: " + tagColumn);
            }
            this.tagColumn = tagColumn;
        }
    }

    public int getValueColumn() {
        return valueColumn;
    }

    public void setValueColumn(int valueColumn) {
        if (this.valueColumn != valueColumn) {
            if (valueColumn < 0 && this.valueColumn >= 0) {
                LOG.info("Value column unset");
            } else if (valueColumn >= 0) {
                LOG.info("Value contained in column: " + valueColumn);
            }
            this.valueColumn = valueColumn;
        }
    }

    public int getQualityColumn() {
        return qualityColumn;
    }

    public void setQualityColumn(int qualityColumn) {
        if (this.qualityColumn != qualityColumn) {
            if (qualityColumn < 0 && this.qualityColumn >= 0) {
                LOG.info("Quality column unset");
            } else if (qualityColumn >= 0) {
                LOG.info("Quality contained in column: " + qualityColumn);
            }
            this.qualityColumn = qualityColumn;
        }
    }

    /**
     * Get the value of dataFile
     *
     * @return the value of dataFile
     */
    public File getDataFile() {
        return dataFile;
    }

    /**
     * Set the value of dataFile
     *
     * @param dataFile new value of dataFile
     */
    public void setDataFile(File dataFile) {
        try {
            this.dataFile = dataFile;
            this.dataLines = new ArrayList();
            LOG.info("Set data file to: " + dataFile.getName());
            FileReader inFile;
            BufferedReader reader;
            try {
                inFile = new FileReader(dataFile);
            } catch (FileNotFoundException ex) {
                LOG.log(Level.SEVERE, "File not found (that's weird ...)", ex);
                return;
            }
            reader = new BufferedReader(inFile);
            String line = "";
            while (line != null) {
                try {
                    line = reader.readLine();
                    if (line != null) {
                        this.dataLines.add(line);
                    }
                } catch (IOException ex) {
                    LOG.log(Level.SEVERE, "Error reading lines from file: " + dataFile.getName(), ex);
                    line = null;
                }
            }
            LOG.info("Read " + this.dataLines.size() + " lines from file: " + dataFile.getName());
            reader.close();
            inFile.close();
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Failed to open file for analysis: " + dataFile.getName(), ex);
        }
    }

    public String[] getFields(int line) {
        if (this.dataLines.isEmpty()) {
            return null;
        }
        String sep = new String() + this.getFieldSep();
        return this.dataLines.get(line).split(sep);
    }

    /**
     * Get the value of fieldSep
     *
     * @return the value of fieldSep
     */
    public char getFieldSep() {
        return fieldSep;
    }

    /**
     * Set the value of fieldSep
     *
     * @param fieldSep new value of fieldSep
     */
    public void setFieldSep(char fieldSep) {
        this.fieldSep = fieldSep;
        LOG.info("Field separator set to: " + fieldSep);
    }

    /**
     * Get the value of stepFormat
     *
     * @return the value of stepFormat
     */
    public String getStepFormat() {
        return stepFormat;
    }

    /**
     * Set the value of stepFormat
     *
     * @param stepFormat new value of stepFormat
     */
    public void setStepFormat(String stepFormat) {
        this.stepFormat = stepFormat;
        LOG.info("Step format set to: " + stepFormat);
    }

    /**
     * Get the value of dataFormat
     *
     * @return the value of dataFormat
     */
    public FileFormat getDataFormat() {
        return dataFormat;
    }

    /**
     * Set the value of dataFormat
     *
     * @param dataFormat new value of dataFormat
     */
    public void setDataFormat(FileFormat dataFormat) {
        if (this.dataFormat != dataFormat) {
            this.dataFormat = dataFormat;
            LOG.info("Data format set to: " + dataFormat.toString());
        }
    }

    /**
     * Get the value of stepColumn
     *
     * @return the value of stepColumn
     */
    public int getStepColumn() {
        return stepColumn;
    }

    /**
     * Set the value of stepColumn
     *
     * @param stepColumn new value of stepColumn
     */
    public void setStepColumn(int stepColumn) {
        if (this.stepColumn != stepColumn && stepColumn >= 0) {
            this.stepColumn = stepColumn;
            LOG.info("Step contained in column: " + stepColumn);
        }
    }

    /**
     * Get the value of tags
     *
     * @return the value of tags
     */
    public ArrayList<String> getTags() {
        return tags;
    }

    /**
     * Set the value of tags
     *
     * @param tags new value of tags
     */
    public void setTags(ArrayList<String> tags) {
        this.tags = tags;
    }

    void setLogHandler(TextAreaHandler handler) {
        LOG.addHandler(handler);
    }

    /**
     * The dataFormat of the data file to build from.
     */
    public enum FileFormat {

        /**
         * One column per tag, one row per step.
         */
        SPREADSHEET,
        /**
         * One row per tag per step.
         */
        TABLE,
    }

    public enum FieldFormat {

        UNKNOWN,
        DATE,
        INTEGER,
        DOUBLE,
        STRING,
    }

    /**
     * Analyze the file to set up the configuration options.
     */
    public boolean analyze() {
        // TODO code application logic here
        // Request CSV file to process
        // Ask what dataFormat (wide sheet or long table)
        // Ask about header rows (or assume there are 0 header rows before the titles)
        // Ask about title row (or assume the first row)
        //  Read the title row, creating a HashMap of blank ArrayList based on tag
        channelDefs = new ArrayList();
        HashMap<String, ArrayList<Double>> myValues = new HashMap();
        ArrayList<Date> mySteps = new ArrayList();
        SimpleDateFormat myStepFormat = new SimpleDateFormat(stepFormat);
        FieldFormat[] myFieldFormats = new FieldFormat[0];
        String[] fieldNames = getFields(numHeaderLines);
        switch (dataFormat) {
            case SPREADSHEET:
                String[] fieldValues = getFields(numHeaderLines);
                if (fieldValues.length < 2) {
                    LOG.severe("Your list of tags seems too short. Did you select the right file/format? Aborting ...");
                    return false;
                }
                if (fieldValues.length < stepColumn || stepColumn < 0) {
                    LOG.severe("You selected a column that does not exist for your Step field. Aborting ...");
                    return false;
                }
                String stepField = fieldValues[stepColumn];
                stepFieldName = stepField;
                for (int iTag = 0; iTag < fieldValues.length; iTag++) {
                    if (iTag == stepColumn) {
                        continue;
                    }
                    myValues.put(fieldValues[iTag], new ArrayList<Double>());
                }
                myFieldFormats = new FieldFormat[fieldValues.length];
                for (int iField = 0; iField < fieldValues.length; iField++) {
                    if (iField == stepColumn) {
                        myFieldFormats[iField] = FieldFormat.DATE;
                    } else {
                        myFieldFormats[iField] = FieldFormat.UNKNOWN;
                    }
                }
                for (int iLine = numHeaderLines + 1; iLine < dataLines.size(); iLine++) {
                    fieldValues = getFields(iLine);
                    String stepVal = fieldValues[stepColumn];
                    try {
                        Date stepDate = myStepFormat.parse(stepVal);
                        mySteps.add(stepDate);
                    } catch (ParseException ex) {
                        LOG.log(Level.SEVERE, "Error parsing Step as Date on line " + (iLine + 1) + ": " + stepVal, ex);
                        return false;
                    }
                    for (int jTag = 0; jTag < fieldValues.length; jTag++) {
                        if (jTag == stepColumn) {
                            continue;
                        }
                        String value;
                        FieldFormat curFormat;
                        value = fieldValues[jTag].toLowerCase();
                        if (value.contains("nan") || value.contains("#n/a")
                                || value.contains("null") || value.contains("none")
                                || value.contains("na")) {
                            continue;
                        }
                        curFormat = myFieldFormats[jTag];
                        Object curValue = null;
                        if (value.length() > 0) {
                            try {
                                Integer testInt = Integer.parseInt(value);
                                if (curFormat != FieldFormat.DOUBLE) {
                                    myFieldFormats[jTag] = FieldFormat.INTEGER;
                                }
                                myValues.get(fieldNames[jTag]).add(testInt.doubleValue());
                            } catch (NumberFormatException ex) {
                                try {
                                    Double testDouble = Double.parseDouble(value);
                                    myFieldFormats[jTag] = FieldFormat.DOUBLE;
                                    myValues.get(fieldNames[jTag]).add(testDouble.doubleValue());
                                } catch (NumberFormatException ex2) {
                                    if (curFormat == FieldFormat.UNKNOWN) {
                                        if (value.contains("a")
                                                || value.contains("\"")
                                                || value.contains("\'")
                                                || value.contains("i")
                                                || value.contains("o")
                                                || value.contains("u")) {
                                            myFieldFormats[jTag] = FieldFormat.STRING;
                                            LOG.info("Field " + jTag + " is a STRING field based on the contents: ''" + value + "''");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            // Ask for the Step type and dataFormat (or interpret, from the current locale)
            // Create a HashMap of <String tag, ArrayList<String> values>
            // Read all values from the file
        }
        for (int iFld = 0; iFld < myFieldFormats.length; iFld++) {
            FieldFormat curFormat = myFieldFormats[iFld];
            if (curFormat == FieldFormat.UNKNOWN) {
                curFormat = FieldFormat.STRING;
            }
            //LOG.info("Field " + iFld + " is a " + myFieldFormats[iFld] + " field.");
            // Do analysis of values
            if (curFormat == FieldFormat.DATE) {
                long firstStep;
                long lastStep;
                long prevStep;
                long thisStep;
                long delta = Long.MAX_VALUE;
                firstStep = mySteps.get(0).getTime();
                thisStep = firstStep;
                lastStep = firstStep;
                for (Iterator it = mySteps.iterator(); it.hasNext();) {
                    prevStep = thisStep;
                    Date nextStep = (Date) it.next();
                    thisStep = nextStep.getTime();
                    lastStep = thisStep;
                    if ((abs(thisStep - prevStep) > 0)) {
                        delta = min(abs(thisStep - prevStep), delta);
                    }
                }
                stepMin = firstStep;
                stepMax = lastStep;
                stepDel = delta;
                SimpleChannelDefn stepChannel = new SimpleChannelDefn(fieldNames[iFld], FieldFormat.DATE, firstStep, lastStep, delta);
                LOG.info("Timing definition: " + stepChannel.toString());
            } else if (curFormat == FieldFormat.DOUBLE || curFormat == FieldFormat.INTEGER) {
                double minValue;
                double maxValue;
                double epsValue;
                double lastVal;
                double resVal;
                DescriptiveStatistics rawValues = new DescriptiveStatistics();
                DescriptiveStatistics residuals = new DescriptiveStatistics();
                ArrayList<Double> values = myValues.get(fieldNames[iFld]);
                try {
                    lastVal = values.get(0);
                    for (Double val : values) {
                        resVal = abs(val - lastVal);
                        rawValues.addValue(val.doubleValue());
                        if (resVal > 0) {
                            residuals.addValue(resVal);
                        }
                    }
                } catch (Exception E) {
                }
                minValue = rawValues.getMin();
                maxValue = rawValues.getMax();
                epsValue = residuals.getMin();
                SimpleChannelDefn myChannel = new SimpleChannelDefn(fieldNames[iFld], myFieldFormats[iFld], minValue, maxValue, epsValue);
                LOG.info("DataChannel definition: " + myChannel.toString());
                channelDefs.add(myChannel);
            } else {
                LOG.warning("Skipping tag \'" + fieldNames[iFld] + "\' because it has no numeric data or is string data");
            }
        }
        // Process each ArrayList of values, determining the following things:
        //   aside from NA, NaN, #N/A, null, or other non-number strings, is this a string field
        //   if this is a string field, can we get a set of valid strings?
        //   is this an integer or a double valued field (look for exponential dataFormat, decimal points)
        //   smallest non-zero difference (sigma_0)
        //   minimum and maximum values (vr_min, vr_max)
        return true;
    }

    public HashMap getV4Config() {
        /*  run mode: BATCH
         control type: INTERNAL
         control messenger: null
         driver files: null
         */
        HashMap cfgCanary = new HashMap();
        cfgCanary.put("run mode", "BATCH");
        cfgCanary.put("control type", "INTERNAL");
        cfgCanary.put("control messenger", null);
        cfgCanary.put("driver files", null);
        /*
         timing options:
         dynamic start-stop: off
         date-time format: mm/dd/yyyy HH:MM:SS
         date-time start:  02/21/2006 00:00:00
         date-time stop:   04/30/2006 23:40:00
         data interval: 00:20:00
         message interval: 00:00:01
         */
        HashMap cfgTiming = new HashMap();
        String matlabStepFormat = stepFormat;
        matlabStepFormat = matlabStepFormat.replaceAll("m", "P");
        matlabStepFormat = matlabStepFormat.replaceAll("M", "m");
        matlabStepFormat = matlabStepFormat.replaceAll("P", "M");
        matlabStepFormat = matlabStepFormat.replaceAll("s", "S");
        cfgTiming.put("dynamic start-stop", false);
        cfgTiming.put("date-time format", matlabStepFormat);
        SimpleDateFormat df = new SimpleDateFormat(stepFormat);
        cfgTiming.put("date-time start", df.format(new Date(this.stepMin)));
        cfgTiming.put("date-time stop", df.format(new Date(this.stepMax)));
        df = new SimpleDateFormat("HH:mm:ss");
        df.setTimeZone(new SimpleTimeZone(0, "UTC"));
        cfgTiming.put("data interval", df.format(new Date(this.stepDel)));
        cfgTiming.put("message interval", "00:00:01");

        /*
         data sources:
         - id: csvfile
         type       : csv
         location   : ../sample_data/test_station_d.csv
         enabled    : yes
         timestep options:
         field: "TIME_STEP"
         dataFormat: "mm/dd/yyyy HH:MM"
         */
        ArrayList cfgDataSources = new ArrayList();
        HashMap hmDS = new HashMap();
        hmDS.put("id", "csvfile");
        hmDS.put("type", "csv");
        hmDS.put("location", dataFile.getName());
        hmDS.put("enabled", true);
        HashMap dsTO = new HashMap();
        hmDS.put("timestep options", dsTO);
        dsTO.put("field", stepFieldName);
        dsTO.put("format", matlabStepFormat);
        cfgDataSources.add(hmDS);

        /*
         * signals:
         * - id: TEST_CL
         * * SCADA tag: D_CL2_VAL
         * * evaluation type: wq
         * * parameter type: CL2
         * * ignore changes: none
         * * data options:
         * * * precision: 0.0035
         * * * units: 'Mg/L'
         * * * valid range: [0.01, 5]
         * * * set points: [-.inf, 3]
         */
        ArrayList cfgSignals = new ArrayList();
        for (SimpleChannelDefn defn : channelDefs) {
            HashMap sigHM = new HashMap();
            sigHM.put("id", defn.name);
            sigHM.put("SCADA tag", defn.name);
            sigHM.put("evaluation type", "wq");
            sigHM.put("parameter type", "UNKN");
            sigHM.put("ignore changes", "none");
            HashMap datOpt = new HashMap();
            String description = new String();
            description = "Type=" + defn.valType.toString() + ", ";
            if (defn.valType == FieldFormat.DOUBLE) {
                description += String.format("min=%.3f, max=%.3f, delta=%.3g",
                        defn.minValue, defn.maxValue, defn.delValue);
            } else if (defn.valType == FieldFormat.INTEGER) {
                description += String.format("min=%d, max=%d, delta=%d",
                        new Double(defn.minValue).intValue(),
                        new Double(defn.maxValue).intValue(),
                        new Double(defn.delValue).intValue());
            }
            sigHM.put("description", description);
            sigHM.put("data options", datOpt);
            defn.delValue = max(defn.delValue, 0.01);
            datOpt.put("precision", defn.delValue);
            ArrayList<Double> valRng = new ArrayList();
            valRng.add(Double.NEGATIVE_INFINITY);
            valRng.add(Double.POSITIVE_INFINITY);
            ArrayList<Double> setPts = new ArrayList();
            setPts.add(Double.NEGATIVE_INFINITY);
            setPts.add(Double.POSITIVE_INFINITY);
            datOpt.put("valid range", valRng);
            datOpt.put("set-points", setPts);
            cfgSignals.add(sigHM);
        }
        /*algorithms:
         - id: RESIDUAL_TEST
         type: LPCF
         history window: 60
         outlier threshold: .inf
         event threshold: .inf
         event timeout: 5
         event window save: 30
         */
        ArrayList cfgAlgorithms = new ArrayList();
        HashMap lpcfEntry = new HashMap();
        HashMap mvnnEntry = new HashMap();
        HashMap BED;
        int histWindow = (int) (86400000 / this.stepDel);
        int eventTimeOut = (int) (3600000 / this.stepDel);
        int bedWindow = (int) (3600000 / this.stepDel);
        int eventWinSave = eventTimeOut + bedWindow + bedWindow;
        lpcfEntry.put("id", "test_lpcf");
        lpcfEntry.put("type", "LPCF");
        lpcfEntry.put("history window", histWindow);
        lpcfEntry.put("outlier threshold", 1.2);
        lpcfEntry.put("event threshold", 0.94);
        lpcfEntry.put("event timeout", eventTimeOut);
        lpcfEntry.put("event window save", eventWinSave);
        BED = new HashMap();
        BED.put("outlier probability", 0.5);
        BED.put("window", bedWindow);
        lpcfEntry.put("BED", BED);
        mvnnEntry.put("id", "test_mvnn");
        mvnnEntry.put("type", "MVNN");
        mvnnEntry.put("history window", histWindow);
        mvnnEntry.put("outlier threshold", 1.2);
        mvnnEntry.put("event threshold", 0.94);
        mvnnEntry.put("event timeout", eventTimeOut);
        mvnnEntry.put("event window save", eventWinSave);
        BED = new HashMap();
        BED.put("outlier probability", 0.5);
        BED.put("window", bedWindow);
        mvnnEntry.put("BED", BED);
        cfgAlgorithms.add(lpcfEntry);
        cfgAlgorithms.add(mvnnEntry);
        /*monitoring stations:
         - id: StationD
         station id number: 1
         station tag name: StationD
         location id number: 4
         enabled: yes
         inputs:
         - id: csvfile
         outputs:
         - id: outputfiles
         signals:
         - id: CAL_StationD
         - id: TEST_CL
         - id: TEST_PH
         - id: TEST_TEMP
         - id: TEST_COND
         - id: TEST_TURB
         - id: TEST_TOC
         - id: TEST_PUMPS
         - id: RATIO_PH_CL2
         algorithms:
         - id: RESIDUAL_TEST
         */
        ArrayList cfgMonStations = new ArrayList();
        HashMap station = new HashMap();
        cfgMonStations.add(station);
        station.put("id", "NEW_STATION");
        station.put("station id number", 1);
        station.put("station tag name", "NEW_STATION_TAG");
        station.put("location id number", 1);
        station.put("enabled", true);
        ArrayList stnInputs = new ArrayList();
        station.put("inputs", stnInputs);
        HashMap inpId = new HashMap();
        inpId.put("id", "csvfile");
        stnInputs.add(inpId);
        ArrayList stnOutputs = new ArrayList();
        station.put("outputs", stnOutputs);
        ArrayList stnSignals = new ArrayList();
        for (SimpleChannelDefn defn : channelDefs) {
            HashMap sigHM = new HashMap();
            sigHM.put("id", defn.name);
            stnSignals.add(sigHM);
        }
        station.put("signals", stnSignals);
        ArrayList algs = new ArrayList();
        HashMap algLPCF = new HashMap();
        algLPCF.put("id", "test_lpcf");
        algs.add(algLPCF);
        HashMap algMVNN = new HashMap();
        algMVNN.put("id", "test_mvnn");
        algs.add(algMVNN);
        station.put("algorithms", algs);

        HashMap config = new HashMap();
        config.put("canary", cfgCanary);
        config.put("timing options", cfgTiming);
        config.put("data sources", cfgDataSources);
        config.put("signals", cfgSignals);
        config.put("algorithms", cfgAlgorithms);
        config.put("monitoring stations", cfgMonStations);
        return config;
    }
}
