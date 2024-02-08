import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wallet_app/services/metamask_service.dart';
import 'package:wallet_app/views/webview_screen/webview_screen.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Web3App? _web3app;
  SessionData? _sessionData;
  final bool _isConnected = false;
  var token = '';
  String maticAmount = '';

  late ValueNotifier<bool> _currentIndexNotifier;
  @override
  void initState() {
    _currentIndexNotifier = ValueNotifier(false);

    // _initWalletConnect();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://google.com'));
    return Scaffold(
        // key: _messangerKey,
        body: ValueListenableBuilder(
      valueListenable: _currentIndexNotifier,
      builder: (context, value, child) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _currentIndexNotifier.value =
                          !_currentIndexNotifier.value;
                      if (_currentIndexNotifier.value) {
                        MetaMaskServiceImp().connectWithMetamaskWallet(
                          onSessionUpdate: (session) {
                            setState(() {
                              print('session ${session.data()}-+++++++++++++=');
                            });
                          },
                          onDisplayUri: (uri) {
                            launchUrlString(uri,
                                mode: LaunchMode.externalApplication);
                          },
                        ).then((result) {
                          result.fold((failure) {
                            print('Failed to connect: $failure');
                          }, (connectResponse) async {
                            print('Updated session+++++++++ $connectResponse');
                            _sessionData = await connectResponse.session.future;
                            final String account = NamespaceUtils.getAccount(
                              _sessionData!
                                  .namespaces.values.first.accounts.first,
                            );
                            print('account ++++++++--------$account');
                            final client = Web3Client(
                                'https://polygon-mumbai.infura.io/v3/d0f4119a707544e7b1fcbc93c9bf659e',
                                Client());
                            EthereumAddress address =
                                EthereumAddress.fromHex(account);
                            EtherAmount etherBalance =
                                await client.getBalance(address);
                            setState(() {
                              maticAmount = etherBalance
                                  .getValueInUnit(EtherUnit.ether)
                                  .toString();
                            });

                            token =
                                client.getTransactionCount(address).toString();

                            print(
                                '+++===Ether balance at address: ${etherBalance.getValueInUnit(EtherUnit.ether)}');
                          });
                        });
                      } else {} // disconnect},
                    },
                    child: Container(
                      // height: 50,
                      // width: 50,
                      decoration: BoxDecoration(
                        color: _currentIndexNotifier.value
                            ? Colors.blue
                            : Colors.red,
                        shape: BoxShape.rectangle,
                      ),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Center(
                        child: Text(
                          _currentIndexNotifier.value ? 'Connected' : 'Connect',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'token: ${_currentIndexNotifier.value ? '' : '----'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 70),
                  Text(
                    'matic: ${_currentIndexNotifier.value ? maticAmount : '----'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(20),
                  child: WebViewWidget(
                    controller: _currentIndexNotifier.value == true
                        ? controller
                        : WebViewController.fromPlatformCreationParams(
                            const PlatformWebViewControllerCreationParams(),
                          ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    ));
  }

  // void _connectWithWallet(String deepLink) {
  //   connectWallet(deepLink).then((_) {
  //     setState(() => _logs += '✅ connected\n\n');
  //     requestAuthWithWallet(deepLink).then((_) {
  //       setState(() => _logs += '✅ authenticated\n\n');
  //     }).catchError((error) {
  //       setState(() => _logs += '❌ auth error $error\n\n');
  //     });
  //   }).catchError((error) {
  //     setState(() => _logs += '❌ connection error $error\n\n');
  //   });
  // }
}
