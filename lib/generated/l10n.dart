// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Comfirm`
  String get Comfirm {
    return Intl.message(
      'Comfirm',
      name: 'Comfirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message(
      'Cancel',
      name: 'Cancel',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get open {
    return Intl.message(
      'Open',
      name: 'open',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Show`
  String get Show {
    return Intl.message(
      'Show',
      name: 'Show',
      desc: '',
      args: [],
    );
  }

  /// `Hide`
  String get Hide {
    return Intl.message(
      'Hide',
      name: 'Hide',
      desc: '',
      args: [],
    );
  }

  /// `Auto`
  String get auto {
    return Intl.message(
      'Auto',
      name: 'auto',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get Language {
    return Intl.message(
      'Language',
      name: 'Language',
      desc: '',
      args: [],
    );
  }

  /// `Follow System`
  String get Follow_System {
    return Intl.message(
      'Follow System',
      name: 'Follow_System',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get Light {
    return Intl.message(
      'Light',
      name: 'Light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get Dark {
    return Intl.message(
      'Dark',
      name: 'Dark',
      desc: '',
      args: [],
    );
  }

  /// `Setting`
  String get Setting {
    return Intl.message(
      'Setting',
      name: 'Setting',
      desc: '',
      args: [],
    );
  }

  /// `Theme Style`
  String get Theme_Style {
    return Intl.message(
      'Theme Style',
      name: 'Theme_Style',
      desc: '',
      args: [],
    );
  }

  /// `Theme Color`
  String get Theme_Color {
    return Intl.message(
      'Theme Color',
      name: 'Theme_Color',
      desc: '',
      args: [],
    );
  }

  /// `Default Color`
  String get Default_Color {
    return Intl.message(
      'Default Color',
      name: 'Default_Color',
      desc: '',
      args: [],
    );
  }

  /// `Custom Color`
  String get Custom_Color {
    return Intl.message(
      'Custom Color',
      name: 'Custom_Color',
      desc: '',
      args: [],
    );
  }

  /// `Image Compress`
  String get Image_Compress {
    return Intl.message(
      'Image Compress',
      name: 'Image_Compress',
      desc: '',
      args: [],
    );
  }

  /// `Don't Compress`
  String get Dont_Compress {
    return Intl.message(
      'Don\'t Compress',
      name: 'Dont_Compress',
      desc: '',
      args: [],
    );
  }

  /// `Font Family`
  String get Font_Family {
    return Intl.message(
      'Font Family',
      name: 'Font_Family',
      desc: '',
      args: [],
    );
  }

  /// `Default Font Family`
  String get Default_Font_Family {
    return Intl.message(
      'Default Font Family',
      name: 'Default_Font_Family',
      desc: '',
      args: [],
    );
  }

  /// `Custom Font Family`
  String get Custom_Font_Family {
    return Intl.message(
      'Custom Font Family',
      name: 'Custom_Font_Family',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Lock`
  String get Privacy_Lock {
    return Intl.message(
      'Privacy Lock',
      name: 'Privacy_Lock',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get Password {
    return Intl.message(
      'Password',
      name: 'Password',
      desc: '',
      args: [],
    );
  }

  /// `Face`
  String get Face {
    return Intl.message(
      'Face',
      name: 'Face',
      desc: '',
      args: [],
    );
  }

  /// `Fingerprint`
  String get Fingerprint {
    return Intl.message(
      'Fingerprint',
      name: 'Fingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to turn off the privacy lock`
  String get Please_authenticate_to_turn_off_the_privacy_lock {
    return Intl.message(
      'Please authenticate to turn off the privacy lock',
      name: 'Please_authenticate_to_turn_off_the_privacy_lock',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to turn on the privacy lock`
  String get Please_authenticate_to_turn_on_the_privacy_lock {
    return Intl.message(
      'Please authenticate to turn on the privacy lock',
      name: 'Please_authenticate_to_turn_on_the_privacy_lock',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to use app`
  String get Please_authenticate_to_use_app {
    return Intl.message(
      'Please authenticate to use app',
      name: 'Please_authenticate_to_use_app',
      desc: '',
      args: [],
    );
  }

  /// `Authenticat need`
  String get Authenticat_need {
    return Intl.message(
      'Authenticat need',
      name: 'Authenticat_need',
      desc: '',
      args: [],
    );
  }

  /// `Verify error`
  String get Verify_error {
    return Intl.message(
      'Verify error',
      name: 'Verify_error',
      desc: '',
      args: [],
    );
  }

  /// `Verify failure`
  String get Verify_failure {
    return Intl.message(
      'Verify failure',
      name: 'Verify_failure',
      desc: '',
      args: [],
    );
  }

  /// `Default index`
  String get Default_index {
    return Intl.message(
      'Default index',
      name: 'Default_index',
      desc: '',
      args: [],
    );
  }

  /// `Timeline`
  String get Timeline {
    return Intl.message(
      'Timeline',
      name: 'Timeline',
      desc: '',
      args: [],
    );
  }

  /// `Global`
  String get Global {
    return Intl.message(
      'Global',
      name: 'Global',
      desc: '',
      args: [],
    );
  }

  /// `Default tab`
  String get Default_tab {
    return Intl.message(
      'Default tab',
      name: 'Default_tab',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get Posts {
    return Intl.message(
      'Posts',
      name: 'Posts',
      desc: '',
      args: [],
    );
  }

  /// `Posts & Replies`
  String get Posts_and_replies {
    return Intl.message(
      'Posts & Replies',
      name: 'Posts_and_replies',
      desc: '',
      args: [],
    );
  }

  /// `Mentions`
  String get Mentions {
    return Intl.message(
      'Mentions',
      name: 'Mentions',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get Notes {
    return Intl.message(
      'Notes',
      name: 'Notes',
      desc: '',
      args: [],
    );
  }

  /// `Users`
  String get Users {
    return Intl.message(
      'Users',
      name: 'Users',
      desc: '',
      args: [],
    );
  }

  /// `Topics`
  String get Topics {
    return Intl.message(
      'Topics',
      name: 'Topics',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get Search {
    return Intl.message(
      'Search',
      name: 'Search',
      desc: '',
      args: [],
    );
  }

  /// `Request`
  String get Request {
    return Intl.message(
      'Request',
      name: 'Request',
      desc: '',
      args: [],
    );
  }

  /// `Link preview`
  String get Link_preview {
    return Intl.message(
      'Link preview',
      name: 'Link_preview',
      desc: '',
      args: [],
    );
  }

  /// `Video preview in list`
  String get Video_preview_in_list {
    return Intl.message(
      'Video preview in list',
      name: 'Video_preview_in_list',
      desc: '',
      args: [],
    );
  }

  /// `Network`
  String get Network {
    return Intl.message(
      'Network',
      name: 'Network',
      desc: '',
      args: [],
    );
  }

  /// `The network will take effect the next time the app is launched`
  String get network_take_effect_tip {
    return Intl.message(
      'The network will take effect the next time the app is launched',
      name: 'network_take_effect_tip',
      desc: '',
      args: [],
    );
  }

  /// `Image service`
  String get Image_service {
    return Intl.message(
      'Image service',
      name: 'Image_service',
      desc: '',
      args: [],
    );
  }

  /// `Forbid image`
  String get Forbid_image {
    return Intl.message(
      'Forbid image',
      name: 'Forbid_image',
      desc: '',
      args: [],
    );
  }

  /// `Forbid video`
  String get Forbid_video {
    return Intl.message(
      'Forbid video',
      name: 'Forbid_video',
      desc: '',
      args: [],
    );
  }

  /// `Please input`
  String get Please_input {
    return Intl.message(
      'Please input',
      name: 'Please_input',
      desc: '',
      args: [],
    );
  }

  /// `Notice`
  String get Notice {
    return Intl.message(
      'Notice',
      name: 'Notice',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
