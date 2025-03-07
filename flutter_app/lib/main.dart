import 'package:flutter/material.dart';
import 'dart:io';
import 'package:udp/udp.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearbySend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class Device {
  final String name;
  final String ipAddress;
  final int port;

  Device({required this.name, required this.ipAddress, required this.port});

  @override
  String toString() {
    return '$name ($ipAddress:$port)';
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Device> nearbyDevices = [];
  Device? selectedDevice;
  bool isLoading = false;
  UDP? udpSocket;

  @override
  void initState() {
    super.initState();
    initUdp();
  }

  @override
  void dispose() {
    udpSocket?.close();
    super.dispose();
  }

  Future<void> initUdp() async {
    udpSocket = await UDP.bind(Endpoint.any(port: Port(12345)));
    
    // 监听来自附近设备的响应
    udpSocket!.asStream().listen((datagram) {
      if (datagram != null && datagram.data != null) {
        final String message = String.fromCharCodes(datagram.data);
        if (message.startsWith('DEVICE:')) {
          final deviceInfo = message.substring(7); // 去掉 'DEVICE:' 前缀
          final parts = deviceInfo.split(':');
          if (parts.length >= 2) {
            final ipAddress = parts[0];
            final port = int.tryParse(parts[1]) ?? 12346;
            final device = Device(
              name: 'Device at $ipAddress',
              ipAddress: ipAddress,
              port: port,
            );
            
            setState(() {
              if (!nearbyDevices.any((d) => d.ipAddress == device.ipAddress)) {
                nearbyDevices.add(device);
              }
            });
          }
        }
      }
    });
    
    discoverDevices();
  }

  Future<void> discoverDevices() async {
    setState(() {
      nearbyDevices.clear();
      selectedDevice = null;
    });
    
    // 发送发现消息
    udpSocket?.send(
      'DISCOVER'.codeUnits,
      Endpoint.broadcast(port: Port(12345)),
    );
  }

  Future<void> pickAndSendFile() async {
    if (selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先选择一个设备')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        Uint8List fileBytes = await file.readAsBytes();
        
        // 发送文件到选定的设备
        Socket socket = await Socket.connect(
          selectedDevice!.ipAddress,
          selectedDevice!.port,
        );
        socket.add(fileBytes);
        await socket.close();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件发送成功')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件发送失败: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NearbySend'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: nearbyDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(nearbyDevices[index].toString()),
                  onTap: () {
                    setState(() {
                      selectedDevice = nearbyDevices[index];
                    });
                  },
                  selected: selectedDevice == nearbyDevices[index],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : pickAndSendFile,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('选择并发送文件'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: discoverDevices,
        tooltip: '刷新设备列表',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
