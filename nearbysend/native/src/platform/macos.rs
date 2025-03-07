use std::process::Command;

// 获取macOS版本
pub fn get_macos_version() -> Result<String, String> {
    let output = Command::new("sw_vers")
        .arg("-productVersion")
        .output()
        .map_err(|e| format!("Failed to execute command: {}", e))?;
    
    if output.status.success() {
        let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok(version)
    } else {
        Err(format!("Command failed with status: {}", output.status))
    }
}

// 获取设备名称
pub fn get_device_name() -> Result<String, String> {
    let output = Command::new("scutil")
        .args(["--get", "ComputerName"])
        .output()
        .map_err(|e| format!("Failed to execute command: {}", e))?;
    
    if output.status.success() {
        let name = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok(name)
    } else {
        Err(format!("Command failed with status: {}", output.status))
    }
}

// 检查蓝牙是否启用
pub fn is_bluetooth_enabled() -> Result<bool, String> {
    let output = Command::new("defaults")
        .args(["read", "/Library/Preferences/com.apple.Bluetooth", "ControllerPowerState"])
        .output()
        .map_err(|e| format!("Failed to execute command: {}", e))?;
    
    if output.status.success() {
        let state = String::from_utf8_lossy(&output.stdout).trim();
        Ok(state == "1")
    } else {
        // 如果命令失败，可能是因为没有权限或其他原因
        // 默认返回false
        Ok(false)
    }
}

// 检查WiFi是否启用
pub fn is_wifi_enabled() -> Result<bool, String> {
    let output = Command::new("networksetup")
        .args(["-getairportpower", "en0"])
        .output()
        .map_err(|e| format!("Failed to execute command: {}", e))?;
    
    if output.status.success() {
        let output_str = String::from_utf8_lossy(&output.stdout).to_string();
        Ok(output_str.contains("On"))
    } else {
        // 如果命令失败，可能是因为没有权限或其他原因
        // 默认返回false
        Ok(false)
    }
}
