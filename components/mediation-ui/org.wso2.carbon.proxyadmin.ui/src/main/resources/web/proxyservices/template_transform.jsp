<!--
 ~ Copyright (c) 2005-2010, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 ~
 ~ WSO2 Inc. licenses this file to you under the Apache License,
 ~ Version 2.0 (the "License"); you may not use this file except
 ~ in compliance with the License.
 ~ You may obtain a copy of the License at
 ~
 ~    http://www.apache.org/licenses/LICENSE-2.0
 ~
 ~ Unless required by applicable law or agreed to in writing,
 ~ software distributed under the License is distributed on an
 ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 ~ KIND, either express or implied.  See the License for the
 ~ specific language governing permissions and limitations
 ~ under the License.
 -->
<%@ page import="org.wso2.carbon.proxyadmin.ui.client.ProxyServiceAdminClient" %>
<%@ page import="org.wso2.carbon.utils.ServerConstants" %>
<%@ page import="org.wso2.carbon.CarbonConstants" %>
<%@ page import="org.apache.axis2.context.ConfigurationContext" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIUtil" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIMessage" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="org.wso2.carbon.proxyadmin.stub.types.carbon.ProxyData" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar" prefix="carbon" %>

<jsp:include page="../resources/resources-i18n-ajaxprocessor.jsp"/>
<!-- Dependencies -->
<script type="text/javascript" src="../yui/build/yahoo-dom-event/yahoo-dom-event.js"></script>
<script type="text/javascript" src="../yui/build/container/container_core-min.js"></script>

<!-- Connection handling lib -->
<script type="text/javascript" src="../yui/build/yahoo/yahoo-min.js"></script>
<script type="text/javascript" src="../yui/build/event/event-min.js"></script>
<script type="text/javascript" src="../yui/build/connection/connection-min.js"></script>
<script type="text/javascript" src="../resources/js/resource_util.js"></script>
<script type="text/javascript" src="../yui/build/utilities/utilities.js"></script>
<script type="text/javascript" src="../ajax/js/prototype.js"></script>
<script type="text/javascript" src="../sequences/js/registry-browser.js"></script>
<!-- Source File -->
<script type="text/javascript" src="../sequences/js/registry-browser.js"></script>
<script type="text/javascript" src="../yui/build/menu/menu-min.js"></script>
<script type="text/javascript" src="../admin/js/main.js"></script>

<fmt:bundle basename="org.wso2.carbon.proxyadmin.ui.i18n.Resources">

<carbon:breadcrumb
        label="service.proxy.menu.text"
        resourceBundle="org.wso2.carbon.proxyadmin.ui.i18n.Resources"
        topPage="true"
        request="<%=request%>"/>

<carbon:jsi18n
            resourceBundle="org.wso2.carbon.proxyadmin.ui.i18n.JSResources"
            request="<%=request%>"
            i18nObjectName="proxyi18n"/>

<script type="text/javascript" src="inc/utils.js"></script>
<script type="text/javascript" src="js/proxyservices.js"></script>
<script type="text/javascript" src="../admin/js/interaction_blocker.js"></script>

<script type="text/javascript">
    jQuery(document).ready(function() {
        jQuery("#proxy_form").validate({
            submitHandler: function(form) {
                proxy_form.action = "template_transform.jsp";
                proxy_form.submit();
                return true;
            }
        });
    });

    function enableResponseTransform(select) {
        if (select.checked) {
            showElem('responseXsltSelect');
        } else {
            hideElem('responseXsltSelect');
        }
    }
</script>

<%
    String proxyName = null;
    String xsltKey = null;
    boolean transformResponses = false;
    String responseXsltKey = null;

    boolean submitted = "true".equals(request.getParameter("formSubmitted"));
    if (submitted) {
        try {
            proxyName = request.getParameter("proxyName");
            if (proxyName == null || "".equals(proxyName)) {
                throw new Exception("The proxy service name has not been specified");
            }

            xsltKey = request.getParameter("reqXsltKey");

            transformResponses = request.getParameter("transformResponses") != null;
            if (transformResponses) {
                responseXsltKey = request.getParameter("resXsltKey");
                if (responseXsltKey == null || "".equals(responseXsltKey)) {
                    throw new Exception("XSLT for the responses has not been specified");
                }
            }

            String backendServerURL = CarbonUIUtil.getServerURL(config.getServletContext(), session);
            ConfigurationContext configContext =
                    (ConfigurationContext) config.getServletContext().getAttribute(CarbonConstants.CONFIGURATION_CONTEXT);
            String cookie = (String) session.getAttribute(ServerConstants.ADMIN_SERVICE_COOKIE);
            ProxyServiceAdminClient client = new ProxyServiceAdminClient(
                    configContext, backendServerURL, cookie, request.getLocale());

            ProxyData proxy = new ProxyData();
            proxy.setStartOnLoad(true);
            proxy.setName(proxyName);
            if (xsltKey != null && !"".equals(xsltKey)) {
                proxy.setInSeqXML("<inSequence xmlns=\"http://ws.apache.org/ns/synapse\">" +
                        "<xslt key=\"" + xsltKey +"\"/></inSequence>");
            }
            if (responseXsltKey != null) {
                proxy.setOutSeqXML("<outSequence xmlns=\"http://ws.apache.org/ns/synapse\">" +
                        "<xslt key=\"" + responseXsltKey +"\"/><send/></outSequence>");
            } else {
                proxy.setOutSeqXML("<outSequence xmlns=\"http://ws.apache.org/ns/synapse\">" +
                        "<send/></outSequence>");
            }

            request.setAttribute("proxyDataObject", proxy);
%>
<jsp:include page="inc/endpoint_processer.jsp"/>
<%
            if (request.getAttribute("proxyCreationError") != null) {
                throw new Exception((String) request.getAttribute("proxyCreationError"));
            }
%>
<jsp:include page="inc/publish_wsdl_processer.jsp"/>
<%
            if (request.getAttribute("proxyCreationError") != null) {
                throw new Exception((String) request.getAttribute("proxyCreationError"));
            }
%>
<jsp:include page="inc/transports_processer.jsp"/>
<%
            if (request.getAttribute("proxyCreationError") != null) {
                throw new Exception((String) request.getAttribute("proxyCreationError"));
            }
            client.addProxy(proxy);
            ResourceBundle bundle = ResourceBundle.getBundle("org.wso2.carbon.proxyadmin.ui.i18n.Resources");
            CarbonUIMessage.sendCarbonUIMessage(
                    bundle.getString("proxy.add.success") + " " + proxy.getName(),
                    CarbonUIMessage.INFO, request);
%>
    <script type="text/javascript">
        proxyCreated('<%=proxyName%>');
    </script>
<%
        } catch (Exception e) {
            String cause;
            if (e.getCause() != null) {
                cause = e.getCause().getMessage();
                cause = cause.replaceAll("\n|\\r|\\t|\\f", "");
            } else {
                cause = e.getMessage();
            }
%>
    <script type="text/javascript">
        CARBON.showErrorDialog('<%=cause%>');
    </script>
<%
        } finally {
            request.removeAttribute("proxyDataObject");
            request.removeAttribute("proxyCreationError");
        }
    }
%>

<jsp:include page="inc/metadata.jsp"/>

<div id="middle">
    <h2><fmt:message key="transform"/></h2>
    <div id="workArea">
        <p>
            <fmt:message key="transform.desc"/>
        </p>
        &nbsp;
        <form id="proxy_form" method="POST" action="">
            <input type="hidden" name="formSubmitted" value="true"/>
            <table cellpadding="0" cellspacing="0" border="0" class="styledLeft noBorders">
                <thead>
                <tr>
                    <th colspan="2"><fmt:message key="proxy.settings"/></th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td colspan="2" style="padding-bottom:10px;">
                        <table>
                            <tr>
                                <td style="width:130px;"><fmt:message key="proxy.service.name"/><span class="required">*</span></td>
                                <td><input id="proxy_name" class="required" minlength="2" type="text" name="proxyName" size="40" onkeypress="return validateProxyNameText(event)"/></td>
                            </tr>
                            <jsp:include page="inc/endpoint_select.jsp"/>
                            <tr>
                                <td><fmt:message key="req.xslt"/></td>
                                <td>
                                    <table class="normal" style="padding-left:0px">
                                        <tr>
                                            <td style="padding-left:0px !important">
                                                <input type="text" id="reqXsltKey"
                                                       name="reqXsltKey" size="40"
                                                       readonly="true"/>
                                            </td>
                                            <td>
                                                <a href="#"
                                                   class="registry-picker-icon-link"
                                                   style="padding-left:20px"
                                                   onclick="showRegistryBrowser('reqXsltKey', '/_system/config');"><fmt:message key="conf.registry"/></a>
                                            </td>
                                            <td>
                                                <a href="#"
                                                   class="registry-picker-icon-link"
                                                   style="padding-left:20px"
                                                   onclick="showRegistryBrowser('reqXsltKey', '/_system/governance');"><fmt:message key="gov.registry"/></a>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                            <tr>
                                <td><fmt:message key="transform.res"/></td>
                                <td><input type="checkbox" id="transformResponses" name="transformResponses" onchange="enableResponseTransform(this);"/></td>
                            </tr>
                            <tr id="responseXsltSelect" style="display:none;">
                                <td><fmt:message key="res.xslt"/></td>
                                <td>
                                    <table class="normal" style="padding-left:0px">
                                        <tr>
                                            <td style="padding-left:0px !important">
                                                <input type="text" id="resXsltKey"
                                                       name="resXsltKey" size="40"
                                                       readonly="true"/>
                                            </td>
                                            <td>
                                                <a href="#"
                                                   class="registry-picker-icon-link"
                                                   style="padding-left:20px"
                                                   onclick="showRegistryBrowser('resXsltKey', '/_system/config');"><fmt:message key="conf.registry"/></a>
                                            </td>
                                            <td>
                                                <a href="#"
                                                   class="registry-picker-icon-link"
                                                   style="padding-left:20px"
                                                   onclick="showRegistryBrowser('resXsltKey', '/_system/governance');"><fmt:message key="gov.registry"/></a>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <jsp:include page="inc/publish_wsdl.jsp"/>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <jsp:include page="inc/transports.jsp"/>
                    </td>
                </tr>
                <tr>
                    <td colspan="2" class="buttonRow">
                        <input class="button submit" type="submit" value="<fmt:message key="create"/>" />
                        <button class="button" onclick="templatesHome(); return false;"><fmt:message key="cancel"/></button>
                    </td>
                </tr>
                </tbody>
            </table>
        </form>
    </div>
</div>

<%
    if (submitted) {
        if (proxyName != null) {
%>
    <script type="text/javascript">
        document.getElementById('proxy_name').value = '<%=proxyName%>';
    </script>
<%
        }

        if (transformResponses) {
%>
    <script type="text/javascript">
        var chk = document.getElementById('transformResponses');
        chk.checked = 'true';
        enableResponseTransform(chk);
    </script>
<%
        }
    }
%>

</fmt:bundle>