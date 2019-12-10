/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package org.teva.canary.engines;

import org.teva.canary.data.Result;
import org.teva.canary.data.Signal;

/**
 *
 * @author dbhart
 */
public interface DataInterface {
    public Signal[][] readData();
    public Signal[] readData(String dateTime);
    public Signal[] readData(Integer index);
    public Signal[][] readData(Integer start, Integer stop);
    public Signal[][] readData(String start, String stop);
    public void writeData(String dateTime, Result[] results);
    public void writeData(Integer index, Result[] results);
    public void writeData(String start, String stop, Result[][] results);
    public void writeData(Integer start, Integer stop, Result[][] results);
    public int configure(String filename);
    public int configureControl(String config);
    public int connect();
    public int connectAs(String username);
    public int connectAs(String username, String password);
    public int disconnect();
    public boolean isConnected();
    public boolean isDisconnected();
}
