use std::net::{UdpSocket, SocketAddr, TcpListener, TcpStream};
use std::io::{Read, Write};
use std::thread;
use std::fs::File;
use std::path::Path;
use std::time::Duration;

fn handle_client(mut stream: TcpStream) -> std::io::Result<()> {
    let mut buffer = Vec::new();
    stream.read_to_end(&mut buffer)?;
    println!("接收到文件: {} 字节", buffer.len());
    
    // 保存文件
    let file_path = format!("received_file_{}.bin", chrono::Local::now().format("%Y%m%d%H%M%S"));
    let mut file = File::create(Path::new(&file_path))?;
    file.write_all(&buffer)?;
    println!("文件已保存到: {}", file_path);
    
    Ok(())
}

fn main() -> std::io::Result<()> {
    // 启动 TCP 监听器线程
    thread::spawn(|| {
        let listener = TcpListener::bind("0.0.0.0:12346").expect("无法绑定 TCP 端口");
        println!("TCP 监听器已启动，等待文件传输...");
        
        for stream in listener.incoming() {
            match stream {
                Ok(stream) => {
                    if let Err(e) = handle_client(stream) {
                        println!("处理客户端错误: {}", e);
                    }
                }
                Err(e) => {
                    println!("接受连接错误: {}", e);
                }
            }
        }
    });
    
    // 启动 UDP 广播线程
    let socket = UdpSocket::bind("0.0.0.0:12345")?;
    socket.set_broadcast(true)?;
    
    let local_addr = socket.local_addr()?;
    println!("UDP 广播已启动，本地地址: {}", local_addr);
    
    // 定期发送广播
    thread::spawn(move || {
        let broadcast_addr: SocketAddr = "255.255.255.255:12345".parse().unwrap();
        loop {
            if let Err(e) = socket.send_to(format!("DEVICE:{}", local_addr).as_bytes(), broadcast_addr) {
                println!("发送广播错误: {}", e);
            }
            thread::sleep(Duration::from_secs(5));
        }
    });
    
    // 接收来自附近设备的响应
    let recv_socket = UdpSocket::bind("0.0.0.0:12345")?;
    let mut buf = [0; 1024];
    
    println!("等待设备发现...");
    loop {
        match recv_socket.recv_from(&mut buf) {
            Ok((size, src)) => {
                let response = String::from_utf8_lossy(&buf[..size]);
                println!("发现设备: {} - 响应: {}", src, response);
                
                // 回复设备
                if response.starts_with("DISCOVER") {
                    let local_addr = recv_socket.local_addr()?;
                    if let Err(e) = recv_socket.send_to(format!("DEVICE:{}", local_addr).as_bytes(), src) {
                        println!("回复设备错误: {}", e);
                    }
                }
            }
            Err(e) => {
                println!("接收广播错误: {}", e);
            }
        }
    }
}
