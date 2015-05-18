/*
*  Copyright (c) 2005-2014, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
*/
package org.wso2.carbon.inbound.endpoint.protocol.cxf.wsrm.interceptor;

import org.apache.axiom.om.OMElement;
import org.apache.axiom.soap.SOAPEnvelope;
import org.apache.axiom.soap.SOAPHeader;
import org.apache.axiom.soap.SOAPHeaderBlock;
import org.apache.cxf.binding.soap.interceptor.SoapPreProtocolOutInterceptor;
import org.apache.cxf.helpers.IOUtils;
import org.apache.cxf.interceptor.Fault;
import org.apache.cxf.io.CachedOutputStream;
import org.apache.cxf.message.Message;
import org.apache.cxf.phase.AbstractPhaseInterceptor;
import org.apache.cxf.phase.Phase;
import org.apache.log4j.Logger;
import org.apache.synapse.util.PayloadHelper;
import org.wso2.carbon.inbound.endpoint.protocol.cxf.wsrm.utils.RMConstants;
import org.wso2.carbon.inbound.endpoint.protocol.cxf.wsrm.utils.SOAPEnvelopeCreator;

import javax.xml.namespace.QName;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Iterator;

/**
 * Intercepts the outbound message and sets the SOAPBody and some of the SOAPHeaders
 */
public class ResponseInterceptor extends AbstractPhaseInterceptor<Message> {

    private static final Logger logger = Logger.getLogger(ResponseInterceptor.class);

    public ResponseInterceptor() {
        super(Phase.PRE_STREAM);
        addBefore(SoapPreProtocolOutInterceptor.class.getName());
    }

    /**
     * Handles the outbound response to the client
     *
     * @param message Response message
     * @throws Fault
     */
    public void handleMessage(Message message) throws Fault {

        boolean isOutbound;
        isOutbound = message == message.getExchange().getOutMessage()
                || message == message.getExchange().getOutFaultMessage();

        //If the response came through Synapse, it is handled here
        if (Boolean.TRUE.equals(message.get(RMConstants.CXF_RM_SYNAPSE_MEDIATED)) && isOutbound) {

            OutputStream os = message.getContent(OutputStream.class);
            CachedOutputStream cs = new CachedOutputStream();
            message.setContent(OutputStream.class, cs);
            /*
             * Executes the interceptors in the interceptor chain following this interceptor,
             * and then returns to this.
             */
            message.getInterceptorChain().doIntercept(message);

            CachedOutputStream cashedOutputStream = null;
            InputStream replaceInStream = null;
            try {
                cs.flush();
                cashedOutputStream = (CachedOutputStream) message.getContent(OutputStream.class);
                //Create the SOAPEnvelope of the response generated by CXF
                SOAPEnvelope cxfOutEnvelope = SOAPEnvelopeCreator.getSOAPEnvelopeFromStream(cashedOutputStream.getInputStream());
                cashedOutputStream.flush();

                //Merge the CXF generated response and the response from the backend service
                SOAPEnvelope result = changeOutboundMessage(cxfOutEnvelope, message);
                replaceInStream = org.apache.commons.io.IOUtils.toInputStream(result.toString(), "UTF-8");
                IOUtils.copy(replaceInStream, os);
                os.flush();
                message.setContent(OutputStream.class, os);
            } catch (IOException ioe) {
                logger.error("Error while processing the response message through the response interceptor", ioe);
                throw new Fault(new Exception("Error while processing the response"));
            } finally {
                org.apache.commons.io.IOUtils.closeQuietly(cs);
                org.apache.commons.io.IOUtils.closeQuietly(cashedOutputStream);
                org.apache.commons.io.IOUtils.closeQuietly(os);
                org.apache.commons.io.IOUtils.closeQuietly(replaceInStream);
            }
        }
    }

    /**
     * Sets the SOAPBody of the SOAPEnvelope that comes from the endpoint (originalEnvelope) to
     * the SOAPBody of the
     * SOAPEnvelope created by CXF. Then adds the headers from the originalEnvelope to the
     * SOAPEnvelope created by CXF
     *
     * @param cxfOutEnvelope SOAPEnvelope created by CXF
     * @param message        CXF out message
     * @return The modified SOAPEnvelope
     */
    private SOAPEnvelope changeOutboundMessage(SOAPEnvelope cxfOutEnvelope, Message message) {

        SOAPEnvelope originalEnvelope = (SOAPEnvelope) message.get(RMConstants.SOAP_ENVELOPE);
        SOAPHeader soapHeader = originalEnvelope.getHeader();

        if (soapHeader != null) {
            Iterator it = soapHeader.examineAllHeaderBlocks();
            //Add the SOAPHeaders of the originalEnvelope to the cxfOutEnvelope
            if (it != null) {
                while (it.hasNext()) {
                    SOAPHeaderBlock block = (SOAPHeaderBlock) it.next();
                    QName name = block.getQName();
                /*
                 * If the cxfOutEnvelope already has those headers, they will be replaced
                 */
                    OMElement existingHeader = cxfOutEnvelope.getHeader().getFirstChildWithName(name);
                    if (existingHeader != null) {
                        existingHeader.detach();
                    }
                    cxfOutEnvelope.getHeader().addChild(block);
                }
            }
        }

        try {
            OMElement originalResponseBody = originalEnvelope.getBody().getFirstElement();
            if (originalResponseBody != null) {
                PayloadHelper.setXMLPayload(cxfOutEnvelope, originalResponseBody);
            }
        } catch (Exception e) {
            logger.error(
                    "Could not merge the CXF generated response body and response body sent from the back end service",
                    e);
        }
        return cxfOutEnvelope;
    }
}
