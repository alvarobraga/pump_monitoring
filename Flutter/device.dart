library aws_iot_device;

import 'dart:async';

import 'package:amazon_cognito_identity_dart/sig_v4.dart';
//import 'package:amazon_cognito_identity_dart/sigv4.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:tuple/tuple.dart';

class AWSIoTDevice {
	final _SERVICE_NAME = 'iotdevicegateway';
	final _AWS4_REQUEST = 'aws4_request';
	final _AWS4_HMAC_SHA256 = 'AWS4-HMAC-SHA256';
	final _SCHEME = 'wss://';

	String _region;
	String _accessKeyId;
	String _secretAccessKey;
	String _sessionToken;
	String _host;
	bool _logging;

	var _onConnected;
	var _onDisconnected;
	var _onSubscribed;
	var _onSubscribeFail;
	var _onUnsubscribed;

	get onConnected => _onConnected;

	set onConnected(val) => _client?.onConnected = _onConnected = val;

	get onDisconnected => _onDisconnected;

	set onDisconnected(val) => _client?.onDisconnected = _onDisconnected = val;

	get onSubscribed => _onSubscribed;

	set onSubscribed(val) => _client?.onSubscribed = _onSubscribed = val;

	get onSubscribeFail => _onSubscribeFail;

	set onSubscribeFail(val) => _client?.onSubscribeFail = _onSubscribeFail = val;

	get onUnsubscribed => _onUnsubscribed;

	set onUnsubscribed(val) => _client?.onUnsubscribed = _onUnsubscribed = val;

	get connectionStatus => _client?.connectionStatus;

	MqttClient _client;

	StreamController<Tuple2<String, String>> _messagesController =
	StreamController<Tuple2<String, String>>();

	Stream<Tuple2<String, String>> get messages => _messagesController.stream;

	AWSIoTDevice(
		this._region,
		this._accessKeyId,
		this._secretAccessKey,
		this._sessionToken,
		String host, {
			bool logging: false,
			var onConnected: null,
			var onDisconnected: null,
			var onSubscribed: null,
			var onSubscribeFail: null,
			var onUnsubscribed: null,
		}) {
		_logging = logging;
		_onConnected = onConnected;
		_onDisconnected = onDisconnected;
		_onSubscribed = onSubscribed;
		_onSubscribeFail = onSubscribeFail;
		_onUnsubscribed = onUnsubscribed;

		if (host.contains('amazonaws.com')) {
			_host = host.split('.').first;
		} else {
			_host = host;
		}
	}

	Future<Null> connect(String clientId) async {
		if (_client == null) {
			_prepare(clientId);
		}

		try {
			await _client.connect();
		} on Exception catch (e) {
			_client.disconnect();
			throw e;
		}
		_client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
			for (MqttReceivedMessage<MqttMessage> message in c) {
				final MqttPublishMessage recMess = message.payload;
				final String pt =
				MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
				_messagesController.add(Tuple2<String, String>(message.topic, pt));
			}
		});
	}

	_prepare(String clientId) {
		final url = _prepareWebSocketUrl();
		_client = MqttClient(url, clientId);
		_client.logging(on: _logging);
		_client.useWebSocket = true;
		_client.port = 443;
		_client.connectionMessage =
			MqttConnectMessage().withClientIdentifier(clientId).keepAliveFor(300);
		_client.keepAlivePeriod = 300;
		if (_onConnected != null) {
			_client.onConnected = _onConnected;
		}

		if (_onUnsubscribed != null) {
			_client.onUnsubscribed = _onUnsubscribed;
		}

		if (_onSubscribeFail != null) {
			_client.onSubscribeFail = _onSubscribeFail;
		}

		if (_onSubscribed != null) {
			_client.onSubscribed = _onSubscribed;
		}

		if (_onDisconnected != null) {
			_client.onDisconnected = _onDisconnected;
		}
	}

	_prepareWebSocketUrl() {
		if (_region == null) {
			throw new Exception('Invalid region');
		}

		if (_accessKeyId == null) {
			throw new Exception('Invalid accessKeyId');
		}

		if (_secretAccessKey == null) {
			throw new Exception('Invalid secretAccessKey');
		}

		if (_sessionToken == null) {
			throw new Exception('Invalid sessionToken');
		}

		if (_host == null) {
			throw new Exception('Invalid host');
		}

		final sigv4 = SigV4();
		final now = _generateDatetime(); //'20190103T172404Z'; //
		final hostname = _buildHostname();

		final List creds = [
			this._accessKeyId,
			_getDate(now),
			this._region,
			this._SERVICE_NAME,
			this._AWS4_REQUEST,
		];

		const payload = '';

		const path = '/mqtt';

		final queryParams = Map<String, String>.from({
			'X-Amz-Algorithm': _AWS4_HMAC_SHA256,
			'X-Amz-Credential': creds.join('/'),
			'X-Amz-Date': now,
			'X-Amz-SignedHeaders': 'host',
		});

//		final canonicalQueryString = sigv4.buildCanonicalQueryString(queryParams);
		final canonicalQueryString = sigv4.call_buildCanonicalQueryString(queryParams);
//		final request = sigv4.buildCanonicalRequest(
		final request = sigv4.call_buildCanonicalRequest(
			'GET',
			path,
			queryParams,
			Map.from({
				'host': hostname,
			}),
			payload);

//		final hashedCanonicalRequest = sigv4.hashCanonicalRequest(request);
		final hashedCanonicalRequest = sigv4.call_hashCanonicalRequest(request);
//		final stringToSign = sigv4.buildStringToSign(
//			now,
//			sigv4.buildCredentialScope(now, _region, _SERVICE_NAME),
//			hashedCanonicalRequest);
		final stringToSign = sigv4.call_buildStringToSign(
				now,
				sigv4.call_buildCredentialScope(now, _region, _SERVICE_NAME),
				hashedCanonicalRequest);

//		final signingKey = sigv4.calculateSigningKey(
//			_secretAccessKey, now, _region, _SERVICE_NAME);
		final signingKey = sigv4.call_calculateSigningKey(
				_secretAccessKey, now, _region, _SERVICE_NAME);

//		final signature = sigv4.calculateSignature(signingKey, stringToSign);
		final signature = sigv4.call_calculateSignature(signingKey, stringToSign);

		final finalParams =
			'${canonicalQueryString}&X-Amz-Signature=${signature}&X-Amz-Security-Token=${Uri.encodeComponent(_sessionToken)}';

		return '${_SCHEME}${hostname}${path}?${finalParams}';
	}

	String _generateDatetime() {
		return new DateTime.now()
			.toUtc()
			.toString()
			.replaceAll(new RegExp(r'\.\d*Z$'), 'Z')
			.replaceAll(new RegExp(r'[:-]|\.\d{3}'), '')
			.split(' ')
			.join('T');
	}

	String _getDate(String dateTime) {
		return dateTime.substring(0, 8);
	}

	String _buildHostname() {
		return '${_host}.iot.${_region}.amazonaws.com';
	}

	void publishMessage(String topic, String payload) {
		final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
		builder.addString(payload);
		_client.publishMessage(topic, MqttQos.atMostOnce, builder.payload);
	}

	void disconnect() {
		return _client.disconnect();
	}

	Subscription subscribe(String topic,
		[MqttQos qosLevel = MqttQos.atMostOnce]) {
		return _client?.subscribe(topic, qosLevel);
	}

	unsubscribe(String topic) {
		_client?.unsubscribe(topic);
	}
}
