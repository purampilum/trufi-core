import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../blocs/bloc_provider.dart';
import '../composite_subscription.dart';

class LocationProviderBloc implements BlocBase {
  static LocationProviderBloc of(BuildContext context) {
    return BlocProvider.of<LocationProviderBloc>(context);
  }

  LocationProviderBloc() {
    _locationProvider = LocationProvider(
      onLocationChanged: _inLocationUpdate.add,
    );
  }

  LocationProvider _locationProvider;

  final _locationUpdateController = rx.BehaviorSubject<LatLng>();

  Sink<LatLng> get _inLocationUpdate => _locationUpdateController.sink;

  Stream<LatLng> get outLocationUpdate => _locationUpdateController.stream;

  // Dispose

  @override
  void dispose() {
    _locationProvider.dispose();
    _locationUpdateController.close();
  }

  // Methods

  void start() async {
    _locationProvider.start();
  }

  void stop() async {
    _locationProvider.stop();
  }

  // Getter

  Future<LatLng> get currentLocation async {
    LatLng location;
    try {
      GeolocationStatus status = await _locationProvider.status;
      if (status == GeolocationStatus.granted) {
        location = await _locationProvider.currentLocation;
        if (location == null) {
          print("Location provider: No current location");
        }
      } else {
        print("Location provider: Permission not granted");
      }
    } catch (e) {
      print("Location provider: ${e.toString()}");
    }
    return location;
  }

  Future<GeolocationStatus> get status async => _locationProvider.status;
}

class LocationProvider {
  LocationProvider({
    this.onLocationChanged,
  });

  final ValueChanged<LatLng> onLocationChanged;

  final CompositeSubscription _subscriptions = CompositeSubscription();
  final Geolocator _geolocator = Geolocator();
  final LocationOptions _locationOptions = LocationOptions(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  start() async {
    // Check permission status
    final status = await _geolocator.checkGeolocationPermissionStatus();
    if (status != GeolocationStatus.granted) {
      return;
    }

    // Subscribe to location updates
    _subscriptions.cancel();
    _subscriptions.add(
      (_geolocator.getPositionStream(_locationOptions)).listen(
        (position) => _handleOnLocationChanged(position),
      ),
    );
  }

  stop() async {
    _subscriptions.cancel();
  }

  void _handleOnLocationChanged(Position value) {
    if (onLocationChanged != null) {
      onLocationChanged(LatLng(value.latitude, value.longitude));
    }
  }

  // Dispose

  dispose() {
    _subscriptions.cancel();
  }

  // Getter

  Future<LatLng> get currentLocation async {
    Position position = await _geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position != null
        ? LatLng(position.latitude, position.longitude)
        : null;
  }

  Future<GeolocationStatus> get status async {
    return _geolocator.checkGeolocationPermissionStatus();
  }
}
