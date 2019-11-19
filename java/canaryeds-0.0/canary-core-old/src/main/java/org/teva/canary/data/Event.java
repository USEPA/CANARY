/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package org.teva.canary.data;

import java.util.Date;
import java.util.List;

/**
 *
 * @author dbhart
 */
public class Event {
    public Integer eventId;
    public String stationId;
    public String algorithmId;
    public Date startDate;
    public Integer duration;
    public String termCause;
    public Integer patternMatch;
    public Double patternProb;
    public List<Integer> contributing;

}
