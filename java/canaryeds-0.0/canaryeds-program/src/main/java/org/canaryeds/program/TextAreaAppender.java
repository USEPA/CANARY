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

import javax.swing.JTextArea;
import org.apache.log4j.EnhancedPatternLayout;
import org.apache.log4j.spi.LoggingEvent;

/**
 * Provide a Log4j appender that writes to a JTextArea.
 * 
 * @internal
 * @author dbhart
 */
public class TextAreaAppender extends org.apache.log4j.AppenderSkeleton {

    private JTextArea textArea;

    public TextAreaAppender() {
        super();
        this.layout = new EnhancedPatternLayout("[%d{HH:mm:ss.SSS} %6p %16.16c{1}] - %m%n");
    }

    /**
     * Create with an existing text area.
     * @param textArea the JTextArea to write to
     */
    public TextAreaAppender(JTextArea textArea) {
        super();
        this.layout = new EnhancedPatternLayout("[%d{HH:mm:ss.SSS} %6p %16.16c{1}] - %m%n");
        this.textArea = textArea;
    }

    @Override
    public void close() throws SecurityException {
    }

    /**
     Get the value of textArea
     
     @return the value of textArea
     */
    public JTextArea getTextArea() {
        return textArea;
    }

    /**
     Set the value of textArea
     
     @param textArea new value of textArea
     */
    public void setTextArea(JTextArea textArea) {
        this.textArea = textArea;
    }

    @Override
    public boolean requiresLayout() {
        return true;
    }

    @Override
    protected void append(LoggingEvent event) {
        String message = layout.format(event);
        textArea.append(message);
        textArea.repaint();
    }
}
