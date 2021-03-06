/*
 * Copyright 2016 Huawei Technologies Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.openo.sdno.testframework.moco;

import static com.github.dreamhead.moco.HttpsCertificate.certificate;
import static com.github.dreamhead.moco.Moco.file;
import static com.github.dreamhead.moco.Moco.httpsServer;

import com.github.dreamhead.moco.HttpServer;

/**
 * Class of Moco HttpsServer.<br>
 * 
 * @author
 * @version SDNO 0.5 Jun 15, 2016
 */
public class MocoHttpsServer extends MocoServer {

    private static final String CERT_FILE = MocoHttpsServer.class.getClassLoader().getResource("cert.jks").getPath();

    /**
     * Constructor<br>
     * 
     * @since SDNO 0.5
     */
    public MocoHttpsServer() {
        super();
    }

    /**
     * Constructor<br>
     * 
     * @param port The port to set
     * @since SDNO 0.5
     */
    public MocoHttpsServer(int port) {
        super(port);
    }

    @Override
    public HttpServer createServer(int port) {
        return httpsServer(port, certificate(file(CERT_FILE), "mocohttps", "mocohttps"));
    }

    @Override
    public HttpServer createServer() {
        return httpsServer(serverConfig.getMocoHttpsPort(), certificate(file(CERT_FILE), "mocohttps", "mocohttps"));
    }
}
