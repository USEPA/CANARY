/*
 * DummyAlgorithm.java
 *
 * Created on October 15, 2008, 1:29 PM
 *
 * To change this template, choose Tools | Options and locate the template under
 * the Source Creation and Management node. Right-click the template and choose
 * Open. You can then make changes to the template in the Source Editor.
 */

import java.util.Vector;

/**
 *
 * @author dbhart
 */
public class DummyAlgorithm {
    /** None of the variables are defined in the API */
    protected double threshold;
    protected int windowsize;
    protected Vector lastData;
    protected Vector thisData;
    protected Vector residuals;
    protected Vector probabilities;
    
    /** Creates a new instance of DummyAlgorithm */
    public DummyAlgorithm() {
    }
    
    /** The following functions are all defined by the API */
    public void setWindow( int winsize) {
        windowsize = winsize;
    }
    
    public void setThreshold( double thold ) {
        threshold = thold;
    }
    
    public void newData( Vector v ) {
        lastData = thisData;
        thisData = v;
    }
    
    public int processData ( ) {
        residuals = thisData;
        probabilities = lastData;
        return 0;
    }
    
    public Vector getResiduals ( ) {
        return residuals;
    }
    
    public Vector getProbabilities ( ) {
        return probabilities;
    }
    
    /** The following functions are not defined by the API */
    
}
