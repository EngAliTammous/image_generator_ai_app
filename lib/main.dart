import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:brain_fusion/brain_fusion.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Generator',
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  TextEditingController text = TextEditingController();
  final AI ai = AI();

  Future<Uint8List> generate(String query) async {
    Uint8List image = await ai.runAI(query, AIStyle.anime, Resolution.r16x9);
    return image;
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = GlobalKey();
    Uint8List? pngBytes;

    SnackBar getResultSnackBar(ShareResult result) {
      return SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Share result: ${result.status}"),
            if (result.status == ShareResultStatus.success)
              Text("Shared to: ${result.raw}")
          ],
        ),
      );
    }

    void _onShareXFileFromAssets(BuildContext context, ByteData? data) async {
      final box = context.findRenderObject() as RenderBox?;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      // final data = await rootBundle.load('assets/flutter_logo.png');
      final buffer = data!.buffer;
      final shareResult = await Share.shareXFiles(
        [
          XFile.fromData(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            name: 'screen_shot.png',
            mimeType: 'image/png',
          ),
        ],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );

      scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
    }

    Future<void> capturePng() async {
      RenderRepaintBoundary? boundary = globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        print("Error: RenderRepaintBoundary is null.");
        return;
      }

      if (kDebugMode) {
        print("Waiting for boundary to be painted.");
      }

      await Future.delayed(const Duration(milliseconds: 20));
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print("Error: ByteData is null.");
        return;
      }

      pngBytes = byteData.buffer.asUint8List();
      if (kDebugMode) {
        print(pngBytes);
      }

      _onShareXFileFromAssets(context, byteData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Generator'),
        leadingWidth: 50,
        leading: InkWell(
          onTap: () async {
            await capturePng();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration:
                const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: const Icon(
              Icons.share,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            generate(text.text);
          });
        },
        label: const Text('Generate Image'),
        icon: const Icon(Icons.image),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(

                child: SizedBox(
                //  height: 100,

                  child: TextField(
                    controller: text,
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus!.unfocus();
                    },
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Enter your query...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onLongPress: () {
                  setState(() {
                    text.text = '';
                  });
                },
                onPressed: () {
                  setState(() {
                    generate(text.text);
                  });
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.deepPurple, // Button background color
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 24.0), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8.0), // Button border radius
                  ),
                ),
                child: const Text(
                  'Generate Image',
                  style: TextStyle(
                    fontSize: 18.0, // Adjust the font size
                    fontWeight: FontWeight.bold, // Apply bold text
                    color: Colors.white, // Text color
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              RepaintBoundary(
                key: globalKey,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  ),
                  child: Center(
                    child: FutureBuilder<Uint8List>(
                      future: generate(text.text),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError){
                          if(snapshot.hasError.toString().contains('Internet'))
                            {
                              return const Text('Check internet connection');

                            }else if(snapshot.hasError.toString().contains('400')) {
                            return const Text('Enter description correctly');

                          }
                          return const Text('Enter description to generate image');

                        } else if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: 400,
                            height: 400,
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
