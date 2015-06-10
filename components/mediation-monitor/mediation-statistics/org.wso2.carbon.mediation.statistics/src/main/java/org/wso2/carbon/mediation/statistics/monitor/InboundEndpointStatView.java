package org.wso2.carbon.mediation.statistics.monitor;

/**
 * Created by priyakishok on 5/22/15.
 */
public class InboundEndpointStatView implements InboundEndpointStatViewMBean{
    private long transactionsInLastMin;
    private boolean active = true;

    public long getTransactionsIn() {
        return transactionsInLastMin;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public void setTransactionsInLastMin(long transactionsInLastMin) {
        this.transactionsInLastMin = transactionsInLastMin;
    }

    public void reset() {
        transactionsInLastMin = 0;
        active = true;
    }
}
