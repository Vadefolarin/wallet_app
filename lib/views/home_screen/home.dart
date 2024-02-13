// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:ffi';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:wallet_app/services/metamask_service.dart';
import 'package:wallet_app/services/EthereumTransaction.dart';
import 'package:wallet_app/views/webview_screen/webview_screen.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Web3App? _web3app;
  SessionData? _sessionData;
  // ignore: unused_field
  final bool _isConnected = false;
  var token = '';
  String maticAmount = '';
  String celtAmount = '';
  late Web3Client web3client;
  late DeployedContract contract;
  String? account;
  String contractAddress = "0x3a31275aA3a516FAA6C0325aA7bDDD2FbCBBa666";
  String testAddress = '0xA32Ed59011F366632fb2D03a7A0Cade4cf11E4Ee';

  late ValueNotifier<bool> _currentIndexNotifier;
  @override
  void initState() {
    _currentIndexNotifier = ValueNotifier(false);

    // _initWalletConnect();

    super.initState();
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abi, "CELT"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String name, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(name);
    final result = await web3client.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<dynamic> submit(
      String name, List<dynamic> args, BuildContext context) async {
    final contract = await loadContract();
    final encoded = contract.function("transfer").encodeCall(args);
    return encoded;
  }

  Future transferToken(BuildContext context) async {
    BigInt bigAmount = BigInt.from(10e18);
    EthereumAddress toAddress = EthereumAddress.fromHex(testAddress);
    var response = await submit("transfer", [toAddress, bigAmount], context);
    return response;
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
                            web3client = Web3Client(
                                'https://polygon-mumbai.infura.io/v3/d0f4119a707544e7b1fcbc93c9bf659e',
                                Client());
                            EthereumAddress address =
                                EthereumAddress.fromHex(account);
                            EtherAmount etherBalance =
                                await web3client.getBalance(address);
                            setState(() {
                              maticAmount = etherBalance
                                  .getValueInUnit(EtherUnit.ether)
                                  .toString();
                            });

                            token = web3client
                                .getTransactionCount(address)
                                .toString();

                            print(
                                '+++===Matic balance at address: ${etherBalance.getValueInUnit(EtherUnit.ether)}');
                            // ignore: use_build_context_synchronously
                            // var response = await transferToken(context);
                            EthereumAddress toAddress =
                                EthereumAddress.fromHex(testAddress);
                            var response =
                                await query('balanceOf', [toAddress]);
                            print('++++++++CELT Balance: $response');
                            setState(() {
                              celtAmount = response[0].toString();
                            });
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
                    'token: ${_currentIndexNotifier.value ? celtAmount : '----'}',
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
