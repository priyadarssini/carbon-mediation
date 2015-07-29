/*
 * Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.carbon.inbound.endpoint.protocol.mqtt;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.eclipse.paho.client.mqttv3.MqttAsyncClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;

import java.util.Properties;
import java.util.concurrent.Semaphore;

public class MqttConnectionConsumer {
    private static final Log log = LogFactory.getLog(MqttListener.class);
    private MqttAsyncClient mqttAsyncClient;
    private MqttConnectOptions connectOptions;
    private MqttConnectionFactory confac;
    private Properties mqttProperties;
    private volatile Semaphore taskSuspensionSemaphore = new Semaphore(0);
    private MqttConnectionListener connectionListener;

    public MqttConnectionConsumer(MqttConnectOptions connectOptions, MqttAsyncClient mqttAsyncClient,
                                  MqttConnectionFactory confac, Properties mqttProperties) {
        this.connectOptions = connectOptions;
        this.mqttAsyncClient = mqttAsyncClient;
        this.confac = confac;
        this.mqttProperties = mqttProperties;
    }

    public void execute() {
        if (mqttAsyncClient != null) {
            if (mqttAsyncClient.isConnected()) {
                //do nothing just return
                return;
            } else {
                try {
                    connectionListener = new MqttConnectionListener(this);
                    mqttAsyncClient.connect(connectOptions, connectionListener);

                    this.acquireTaskSuspension();

                    if (mqttAsyncClient.isConnected()) {
                        int qosLevel = Integer.parseInt(mqttProperties
                                .getProperty(MqttConstants.MQTT_QOS));
                        if (confac.getTopic() != null) {
                            mqttAsyncClient.subscribe(confac.getTopic(), qosLevel);
                        }
                        log.info("Connected to the remote server.");
                    }
                } catch (MqttException ex) {
                    log.error("Error while trying to subscribe to the remote ");
                } catch (InterruptedException ex) {
                    log.error("Error while trying to subscribe to the remote ");
                }
            }
        }
    }

    public void shutdown() {
        taskSuspensionSemaphore.release();
        if (connectionListener != null) {
            this.connectionListener.shutdown();
        }
    }

    public MqttConnectOptions getConnectOptions() {
        return connectOptions;
    }

    public MqttAsyncClient getMqttAsyncClient() {
        return mqttAsyncClient;
    }

    public MqttConnectionFactory getMqttConnectionFactory() {
        return confac;
    }

    public Properties getMqttProperties() {
        return mqttProperties;
    }

    public void releaseTaskSuspension(){
        taskSuspensionSemaphore.release();
    }

    public void acquireTaskSuspension() throws InterruptedException{
        taskSuspensionSemaphore.acquire();
    }
}
