import 'package:flutter/material.dart';
import 'package:wallet_app/views/webview_screen/webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ValueNotifier<bool> _currentIndexNotifier;
  @override
  void initState() {
    _currentIndexNotifier = ValueNotifier(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ValueListenableBuilder(
      valueListenable: _currentIndexNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            InkWell(
              onTap: () {
                _currentIndexNotifier.value = !_currentIndexNotifier.value;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebviewScreen(),
                  ),
                );

                // _currentIndexNotifier.value
                //     ? Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const WebviewScreen(),
                //         ),
                //       )
                //     : Navigator.pop(context);
              },
              child: Center(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color:
                        _currentIndexNotifier.value ? Colors.blue : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentIndexNotifier.value
                          ? Colors.blue
                          : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _currentIndexNotifier.value ? 'Connect' : 'Disconnect',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'token: ${_currentIndexNotifier.value ? '9.1823' : '----'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'matic: ${_currentIndexNotifier.value ? '0.0001' : '----'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    ));
  }
}
