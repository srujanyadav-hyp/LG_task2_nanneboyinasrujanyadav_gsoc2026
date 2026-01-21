import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

//=========================================== SERVICE TO INTERACT WITH LG RIG ===========================================
class LgService {
  SSHClient? _client;

  // ==========================================
  //  CONNECTION SETUP TO LG
  // ==========================================
  Future<bool> connectToLG(
    String ip,
    String username,
    String password,
    int port,
  ) async {
    try {
      final socket = await SSHSocket.connect(ip, port);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      //  WAIT HERE until the password is actually verified!
      await _client!.authenticated;

      print("✅ Connected to $ip");
      return true;
    } catch (e) {
      print("❌ Connection Failed: $e");
      return false;
    }
  }

  // ==========================================
  //  HELPER FUNCTIONS
  // ==========================================
  Future<void> _execute(String command) async {
    if (_client == null || _client!.isClosed) return;
    try {
      await _client!.execute(command);
    } catch (e) {
      print("❌ Exec Error: $e");
    }
  }

  Future<void> _uploadFile(String content, String filename) async {
    if (_client == null || _client!.isClosed) return;
    try {
      final sftp = await _client!.sftp();
      final file = await sftp.open(
        '/var/www/html/$filename',
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.write(Stream.value(Uint8List.fromList(content.codeUnits)));
      await _execute('chmod 644 /var/www/html/$filename');
    } catch (e) {
      print("❌ Upload Error: $e");
    }
  }

  // Calculate the Leftmost screen number
  int _getLeftScreen(int totalScreens) {
    if (totalScreens == 1) return 1;
    return (totalScreens / 2).floor() + 2;
  }

  // ==========================================
  //  SEND LOGO (To Left Slave)
  // ==========================================
  Future<void> sendLogo(int totalScreens) async {
    // 1. Upload the image file first (Offline support)
    try {
      // Fetch the raw image file from the app's assets into memory
      final ByteData data = await rootBundle.load('assets/lg_logo.png');

      // Transform the raw memory data into a list of bytes (Uint8List)
      //  This is required because the SFTP function cannot read raw ByteData directly.
      final Uint8List bytes = data.buffer.asUint8List();

      final sftp = await _client!.sftp();
      final file = await sftp.open(
        '/var/www/html/lg_logo.png',
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      await file.write(Stream.value(bytes));
      await _execute('chmod 644 /var/www/html/lg_logo.png');
    } catch (e) {
      print("⚠️ Could not upload image assets: $e");
    }

    //  Determine Left Screen Number
    int screenNum = _getLeftScreen(totalScreens);

    //  Create KML for the Slave Screen
    String logoKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>LG Logo</name>
    <ScreenOverlay>
      <name>LogoOverlay</name>
      <Icon>
        <href>http://lg1:81/lg_logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="0.3" y="0" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>''';

    //  Send to the specific  Left Slave Screen
    await _uploadFile(logoKml, 'kml/slave_$screenNum.kml');
    print("✅ Logo sent to Screen $screenNum");
  }

  // ==========================================
  //   SEND PYRAMID (To Master)
  // ==========================================
  Future<void> sendPyramid() async {
    double lat = 17.6868;
    double lng = 83.2185;
    double size = 0.005;
    double height = 500;

    String pyramidKml =
        '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Srujan Pyramid</name>
    <Style id="pStyle">
      <PolyStyle><color>7f00ff00</color><outline>1</outline></PolyStyle>
    </Style>
    <Placemark><name>Face1</name><styleUrl>#pStyle</styleUrl><Polygon><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>${lng - size},${lat - size},0 ${lng + size},${lat - size},0 $lng,$lat,$height ${lng - size},${lat - size},0</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
    <Placemark><name>Face2</name><styleUrl>#pStyle</styleUrl><Polygon><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>${lng + size},${lat - size},0 ${lng + size},${lat + size},0 $lng,$lat,$height ${lng + size},${lat - size},0</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
    <Placemark><name>Face3</name><styleUrl>#pStyle</styleUrl><Polygon><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>${lng + size},${lat + size},0 ${lng - size},${lat + size},0 $lng,$lat,$height ${lng + size},${lat + size},0</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
    <Placemark><name>Face4</name><styleUrl>#pStyle</styleUrl><Polygon><altitudeMode>relativeToGround</altitudeMode><outerBoundaryIs><LinearRing><coordinates>${lng - size},${lat + size},0 ${lng - size},${lat - size},0 $lng,$lat,$height ${lng - size},${lat + size},0</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
  </Document>
</kml>''';

    // Upload KML
    await _uploadFile(pyramidKml, 'pyramid.kml');
    // Link it in Master kmls.txt
    await _execute('echo "http://lg1:81/pyramid.kml" > /var/www/html/kmls.txt');
    print("✅ Pyramid sent to Master");
  }

  // ==========================================
  //  FLY TO HOME CITY
  // ==========================================
  Future<void> flyToVizag() async {
    String flyCmd =
        'flytoview=<LookAt><longitude>83.2185</longitude><latitude>17.6868</latitude><heading>0</heading><tilt>60</tilt><range>2000</range><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>';
    await _execute('echo "$flyCmd" > /tmp/query.txt');
  }

  // ==========================================
  //  CLEANING TOOLS
  // ==========================================
  Future<void> cleanLogos(int totalScreens) async {
    String blank =
        '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>';
    int screenNum = _getLeftScreen(totalScreens);
    await _uploadFile(blank, 'kml/slave_$screenNum.kml');
    print(" Logo Cleaned");
  }

  Future<void> cleanKmls() async {
    await _execute('echo "" > /var/www/html/kmls.txt');
    print(" KMLs Cleaned");
  }
}
