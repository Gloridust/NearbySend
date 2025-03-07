use btleplug::api::{Central, Manager as _, Peripheral, ScanFilter};
use btleplug::platform::{Manager, Adapter};
use std::time::Duration;
use tokio::time;
use crate::Result;

pub struct Discovery {
    adapter: Adapter,
}

impl Discovery {
    pub fn new() -> Result<Self> {
        let manager = Manager::new()?;
        let adapters = manager.adapters()?;
        let adapter = adapters.into_iter().next()
            .ok_or_else(|| crate::Error::Discovery("没有找到蓝牙适配器".into()))?;
        
        Ok(Self { adapter })
    }

    pub async fn start(&self) -> Result<()> {
        self.adapter.start_scan(ScanFilter::default())?;
        Ok(())
    }

    pub async fn stop(&self) -> Result<()> {
        self.adapter.stop_scan()?;
        Ok(())
    }

    pub async fn get_devices(&self) -> Result<Vec<btleplug::platform::Peripheral>> {
        time::sleep(Duration::from_secs(2)).await;
        let peripherals = self.adapter.peripherals().await?;
        Ok(peripherals)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_discovery() {
        let discovery = Discovery::new().expect("Failed to create discovery");
        discovery.start().await.expect("Failed to start discovery");
        let devices = discovery.get_devices().await.expect("Failed to get devices");
        println!("Found {} devices", devices.len());
        discovery.stop().await.expect("Failed to stop discovery");
    }
}