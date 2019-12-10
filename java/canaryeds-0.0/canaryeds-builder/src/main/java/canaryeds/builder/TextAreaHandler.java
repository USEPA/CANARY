/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package canaryeds.builder;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.logging.LogRecord;
import javax.swing.JTextArea;

/**
 *
 * @author dbhart
 */
public class TextAreaHandler extends java.util.logging.Handler {

    private JTextArea textArea;

    /**
     * Get the value of textArea
     *
     * @return the value of textArea
     */
    public JTextArea getTextArea() {
        return textArea;
    }

    /**
     * Set the value of textArea
     *
     * @param textArea new value of textArea
     */
    public void setTextArea(JTextArea textArea) {
        this.textArea = textArea;
    }

    public TextAreaHandler() {
        super();
    }

    public TextAreaHandler(JTextArea textArea) {
        super();
        this.textArea = textArea;
    }

    @Override
    public void publish(LogRecord record) {
        StringWriter text = new StringWriter();
        PrintWriter out = new PrintWriter(text);
        out.println(textArea.getText());
        SimpleDateFormat format = new SimpleDateFormat();
        Date recDate = new Date(record.getMillis());
        out.printf("[%s] %10s %s -> %s", format.format(recDate), "[" + record.getLevel()
                + "]:", record.getSourceMethodName(), record.getMessage());
        textArea.setText(text.toString());
    }

    @Override
    public void flush() {
        textArea.repaint();
    }

    @Override
    public void close() throws SecurityException {
    }
}
