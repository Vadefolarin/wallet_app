import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/utilities/failure.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/proposal_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_models.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:web3dart/web3dart.dart';

import 'EthereumTransaction.dart';

abstract class MetaMaskService {
  Future<void> openLinkInBrowser({required String link});

  Future<Either<Failure, ConnectResponse>> connectWithMetamaskWallet({
    required Function(SessionEvent session) onSessionUpdate,
    required Function(String uri) onDisplayUri,
  });

  Uri? formatNativeUrl(String? appUrl, String wcUri);
}

class MetaMaskServiceImp implements MetaMaskService {
  @override
  Future<Either<Failure, ConnectResponse>> connectWithMetamaskWallet({
    required Function(SessionEvent session) onSessionUpdate,
    required Function(String uri) onDisplayUri,
  }) async {
    var deepLink = "metamask://wc?uri=";
    try {
      Web3App wcClient = await createWeb3Instance();
      ConnectResponse resp = await wcClient.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(

            chains: ["eip155:1"], // Ethereum chain
            methods: ['personal_sign', 'eth_sign', 'eth_sendTransaction'], // Requestable Methods
            events: [], // Requestable Events
          )
        },
      );
      Uri? uri = resp.uri;
      final link = formatNativeUrl(deepLink, uri.toString());

      onDisplayUri(link.toString());

      return Right(resp);
    } catch (e) {
      Left(ConnectivityFailure(e.toString()));
    }
    return Left(ConnectivityFailure("error".toString()));
  }

  Future<Web3App> createWeb3Instance() async {
    Web3App wcClient = await Web3App.createInstance(
      projectId: '',
      metadata: const PairingMetadata(
        redirect: Redirect(),
        name: 'dApp (Requester)',
        description: 'A dapp that can request that transactions be signed',
        url: 'https://walletconnect.com',
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
      ),
    );

    return wcClient;
  }

  @override
  Uri? formatNativeUrl(String? deepLink, String wcUri) {
    String safeAppUrl = deepLink ?? "";

    if (deepLink != null && deepLink.isNotEmpty) {
      if (!safeAppUrl.contains('://')) {
        safeAppUrl = deepLink.replaceAll('/', '').replaceAll(':', '');
        safeAppUrl = '$safeAppUrl://';
      }
    }

    String encodedWcUrl = Uri.encodeComponent(wcUri);
    log('Encoded WC URL: $encodedWcUrl');

    return Uri.parse('$safeAppUrl$encodedWcUrl');
  }

  @override
  Future<void> openLinkInBrowser({required String link}) async {
    var uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}