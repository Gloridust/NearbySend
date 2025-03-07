mod discovery;
mod connection;
mod transfer;
mod security;
mod platform;

pub mod api;

// 重新导出API模块
pub use api::*;

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
