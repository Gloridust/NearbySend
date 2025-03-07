use quinn::{Endpoint, ServerConfig, ClientConfig};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::Mutex;
use crate::Result;

pub struct Connection {
    server: Mutex<Option<Endpoint>>,
    client: Mutex<Option<Endpoint>>,
}

impl Connection {
    pub fn new() -> Result<Self> {
        Ok(Self {
            server: Mutex::new(None),
            client: Mutex::new(None),
        })
    }

    pub async fn start_server(&self, addr: SocketAddr) -> Result<()> {
        let mut server = self.server.lock().await;
        let (server_config, _server_cert) = configure_server()?;
        let endpoint = Endpoint::server(server_config, addr)?;
        *server = Some(endpoint);
        Ok(())
    }

    pub async fn connect(&self, addr: SocketAddr) -> Result<()> {
        let mut client = self.client.lock().await;
        let client_config = configure_client()?;
        let endpoint = Endpoint::client("0.0.0.0:0".parse().unwrap())?;
        endpoint.connect(client_config, addr, "localhost")?;
        *client = Some(endpoint);
        Ok(())
    }
}

fn configure_server() -> Result<(ServerConfig, Vec<u8>)> {
    let cert = rcgen::generate_simple_self_signed(vec!["localhost".into()])?;
    let cert_der = cert.serialize_der()?;
    let priv_key = cert.serialize_private_key_der();
    let cert_chain = vec![cert_der.clone()];
    
    let mut server_config = ServerConfig::with_single_cert(cert_chain, priv_key)?;
    Arc::get_mut(&mut server_config.transport)
        .unwrap()
        .max_concurrent_uni_streams(0_u8.into());

    Ok((server_config, cert_der))
}

fn configure_client() -> Result<ClientConfig> {
    let mut client_config = ClientConfig::new(Arc::new(rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_custom_certificate_verifier(Arc::new(SkipServerVerification))
        .with_no_client_auth()));

    Arc::get_mut(&mut client_config.transport)
        .unwrap()
        .max_concurrent_uni_streams(0_u8.into());

    Ok(client_config)
}

struct SkipServerVerification;

impl rustls::client::ServerCertVerifier for SkipServerVerification {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::Certificate,
        _intermediates: &[rustls::Certificate],
        _server_name: &rustls::ServerName,
        _scts: &mut dyn Iterator<Item = &[u8]>,
        _ocsp_response: &[u8],
        _now: std::time::SystemTime,
    ) -> Result<rustls::client::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::ServerCertVerified::assertion())
    }
} 