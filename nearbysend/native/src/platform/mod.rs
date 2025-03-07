// 平台特定模块
#[cfg(target_os = "macos")]
pub mod macos;

#[cfg(target_os = "android")]
pub mod android;

#[cfg(target_os = "ios")]
pub mod ios;

#[cfg(target_os = "windows")]
pub mod windows;

// 获取平台名称
pub fn get_platform_name() -> &'static str {
    match std::env::consts::OS {
        "macos" => "macOS",
        "android" => "Android",
        "ios" => "iOS",
        "windows" => "Windows",
        _ => "Unknown",
    }
}

// 获取平台版本
pub fn get_platform_version() -> String {
    #[cfg(target_os = "macos")]
    {
        return macos::get_macos_version().unwrap_or_else(|_| "Unknown".to_string());
    }
    
    #[cfg(target_os = "android")]
    {
        return android::get_android_version().unwrap_or_else(|_| "Unknown".to_string());
    }
    
    #[cfg(target_os = "ios")]
    {
        return ios::get_ios_version().unwrap_or_else(|_| "Unknown".to_string());
    }
    
    #[cfg(target_os = "windows")]
    {
        return windows::get_windows_version().unwrap_or_else(|_| "Unknown".to_string());
    }
    
    "Unknown".to_string()
}
