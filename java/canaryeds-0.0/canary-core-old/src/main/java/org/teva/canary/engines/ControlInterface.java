/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package org.teva.canary.engines;

import org.teva.canary.data.Message;

/**
 *
 * @author dbhart
 */
public interface ControlInterface {
    public Message recvMesssage();
    public void sendMessage(Message message);
    public int configure(String filename);
    public int configureControl(String config);
    public int connect();
    public int connectAs(String username);
    public int connectAs(String username, String password);
    public int disconnect();
    public boolean isConnected();
    public boolean isDisconnected();
    public boolean setSaveMessages(boolean saveFlag);
    public boolean setSaveLocation(String filename);
    public void saveMessages();
    public void getMessage(Integer messageId);
}
