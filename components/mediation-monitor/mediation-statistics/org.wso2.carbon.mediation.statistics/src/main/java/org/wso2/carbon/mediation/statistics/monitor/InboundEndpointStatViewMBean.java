package org.wso2.carbon.mediation.statistics.monitor;

/**
 * Created by priyakishok on 5/22/15.
 */
public interface InboundEndpointStatViewMBean {

    public long getTransactionsIn();

    public boolean isActive();

    public void reset();
}
