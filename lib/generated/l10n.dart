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
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Confirm`
  String get Confirm {
    return Intl.message('Confirm', name: 'Confirm', desc: '', args: []);
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message('Cancel', name: 'Cancel', desc: '', args: []);
  }

  /// `Open`
  String get open {
    return Intl.message('Open', name: 'open', desc: '', args: []);
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Show`
  String get Show {
    return Intl.message('Show', name: 'Show', desc: '', args: []);
  }

  /// `Hide`
  String get Hide {
    return Intl.message('Hide', name: 'Hide', desc: '', args: []);
  }

  /// `Auto`
  String get auto {
    return Intl.message('Auto', name: 'auto', desc: '', args: []);
  }

  /// `Language`
  String get Language {
    return Intl.message('Language', name: 'Language', desc: '', args: []);
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
    return Intl.message('Light', name: 'Light', desc: '', args: []);
  }

  /// `Dark`
  String get Dark {
    return Intl.message('Dark', name: 'Dark', desc: '', args: []);
  }

  /// `Setting`
  String get Setting {
    return Intl.message('Setting', name: 'Setting', desc: '', args: []);
  }

  /// `Theme Style`
  String get Theme_Style {
    return Intl.message('Theme Style', name: 'Theme_Style', desc: '', args: []);
  }

  /// `Theme Color`
  String get Theme_Color {
    return Intl.message('Theme Color', name: 'Theme_Color', desc: '', args: []);
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
    return Intl.message('Font Family', name: 'Font_Family', desc: '', args: []);
  }

  /// `Font Size`
  String get Font_Size {
    return Intl.message('Font Size', name: 'Font_Size', desc: '', args: []);
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
    return Intl.message('Password', name: 'Password', desc: '', args: []);
  }

  /// `Face`
  String get Face {
    return Intl.message('Face', name: 'Face', desc: '', args: []);
  }

  /// `Fingerprint`
  String get Fingerprint {
    return Intl.message('Fingerprint', name: 'Fingerprint', desc: '', args: []);
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
    return Intl.message('Timeline', name: 'Timeline', desc: '', args: []);
  }

  /// `Global`
  String get Global {
    return Intl.message('Global', name: 'Global', desc: '', args: []);
  }

  /// `Default tab`
  String get Default_tab {
    return Intl.message('Default tab', name: 'Default_tab', desc: '', args: []);
  }

  /// `Posts`
  String get Posts {
    return Intl.message('Posts', name: 'Posts', desc: '', args: []);
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
    return Intl.message('Mentions', name: 'Mentions', desc: '', args: []);
  }

  /// `Notes`
  String get Notes {
    return Intl.message('Notes', name: 'Notes', desc: '', args: []);
  }

  /// `Users`
  String get Users {
    return Intl.message('Users', name: 'Users', desc: '', args: []);
  }

  /// `Topics`
  String get Topics {
    return Intl.message('Topics', name: 'Topics', desc: '', args: []);
  }

  /// `Search`
  String get Search {
    return Intl.message('Search', name: 'Search', desc: '', args: []);
  }

  /// `Request`
  String get Request {
    return Intl.message('Request', name: 'Request', desc: '', args: []);
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
    return Intl.message('Network', name: 'Network', desc: '', args: []);
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

  /// `Forbid profile picture`
  String get Forbid_profile_picture {
    return Intl.message(
      'Forbid profile picture',
      name: 'Forbid_profile_picture',
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
    return Intl.message('Notice', name: 'Notice', desc: '', args: []);
  }

  /// `Write a message`
  String get Write_a_message {
    return Intl.message(
      'Write a message',
      name: 'Write_a_message',
      desc: '',
      args: [],
    );
  }

  /// `Add to known list`
  String get Add_to_known_list {
    return Intl.message(
      'Add to known list',
      name: 'Add_to_known_list',
      desc: '',
      args: [],
    );
  }

  /// `Buy me a coffee!`
  String get Buy_me_a_coffee {
    return Intl.message(
      'Buy me a coffee!',
      name: 'Buy_me_a_coffee',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get Donate {
    return Intl.message('Donate', name: 'Donate', desc: '', args: []);
  }

  /// `What's happening?`
  String get What_s_happening {
    return Intl.message(
      'What\'s happening?',
      name: 'What_s_happening',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get Send {
    return Intl.message('Send', name: 'Send', desc: '', args: []);
  }

  /// `Please input event id`
  String get Please_input_event_id {
    return Intl.message(
      'Please input event id',
      name: 'Please_input_event_id',
      desc: '',
      args: [],
    );
  }

  /// `Please input user pubkey`
  String get Please_input_user_pubkey {
    return Intl.message(
      'Please input user pubkey',
      name: 'Please_input_user_pubkey',
      desc: '',
      args: [],
    );
  }

  /// `Please input lnbc text`
  String get Please_input_lnbc_text {
    return Intl.message(
      'Please input lnbc text',
      name: 'Please_input_lnbc_text',
      desc: '',
      args: [],
    );
  }

  /// `Please input Topic text`
  String get Please_input_Topic_text {
    return Intl.message(
      'Please input Topic text',
      name: 'Please_input_Topic_text',
      desc: '',
      args: [],
    );
  }

  /// `Text can't contain blank space`
  String get Text_can_t_contain_blank_space {
    return Intl.message(
      'Text can\'t contain blank space',
      name: 'Text_can_t_contain_blank_space',
      desc: '',
      args: [],
    );
  }

  /// `Text can't contain new line`
  String get Text_can_t_contain_new_line {
    return Intl.message(
      'Text can\'t contain new line',
      name: 'Text_can_t_contain_new_line',
      desc: '',
      args: [],
    );
  }

  /// `replied`
  String get replied {
    return Intl.message('replied', name: 'replied', desc: '', args: []);
  }

  /// `boosted`
  String get boosted {
    return Intl.message('boosted', name: 'boosted', desc: '', args: []);
  }

  /// `liked`
  String get liked {
    return Intl.message('liked', name: 'liked', desc: '', args: []);
  }

  /// `key has been copy!`
  String get key_has_been_copy {
    return Intl.message(
      'key has been copy!',
      name: 'key_has_been_copy',
      desc: '',
      args: [],
    );
  }

  /// `Input dirtyword.`
  String get Input_dirtyword {
    return Intl.message(
      'Input dirtyword.',
      name: 'Input_dirtyword',
      desc: '',
      args: [],
    );
  }

  /// `Word can't be null.`
  String get Word_can_t_be_null {
    return Intl.message(
      'Word can\'t be null.',
      name: 'Word_can_t_be_null',
      desc: '',
      args: [],
    );
  }

  /// `Blocks`
  String get Blocks {
    return Intl.message('Blocks', name: 'Blocks', desc: '', args: []);
  }

  /// `Dirtywords`
  String get Dirtywords {
    return Intl.message('Dirtywords', name: 'Dirtywords', desc: '', args: []);
  }

  /// `loading`
  String get loading {
    return Intl.message('loading', name: 'loading', desc: '', args: []);
  }

  /// `Account Manager`
  String get Account_Manager {
    return Intl.message(
      'Account Manager',
      name: 'Account_Manager',
      desc: '',
      args: [],
    );
  }

  /// `Add Account`
  String get Add_Account {
    return Intl.message('Add Account', name: 'Add_Account', desc: '', args: []);
  }

  /// `Input account private key`
  String get Input_account_private_key {
    return Intl.message(
      'Input account private key',
      name: 'Input_account_private_key',
      desc: '',
      args: [],
    );
  }

  /// `Add account and login?`
  String get Add_account_and_login {
    return Intl.message(
      'Add account and login?',
      name: 'Add_account_and_login',
      desc: '',
      args: [],
    );
  }

  /// `Wrong Private Key format`
  String get Wrong_Private_Key_format {
    return Intl.message(
      'Wrong Private Key format',
      name: 'Wrong_Private_Key_format',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get Filter {
    return Intl.message('Filter', name: 'Filter', desc: '', args: []);
  }

  /// `Relays`
  String get Relays {
    return Intl.message('Relays', name: 'Relays', desc: '', args: []);
  }

  /// `Key Backup`
  String get Key_Backup {
    return Intl.message('Key Backup', name: 'Key_Backup', desc: '', args: []);
  }

  /// `Please do not disclose or share the key to anyone.`
  String get Please_do_not_disclose_or_share_the_key_to_anyone {
    return Intl.message(
      'Please do not disclose or share the key to anyone.',
      name: 'Please_do_not_disclose_or_share_the_key_to_anyone',
      desc: '',
      args: [],
    );
  }

  /// `Nostrmo developers will never require a key from you.`
  String get Nostromo_developers_will_never_require_a_key_from_you {
    return Intl.message(
      'Nostrmo developers will never require a key from you.',
      name: 'Nostromo_developers_will_never_require_a_key_from_you',
      desc: '',
      args: [],
    );
  }

  /// `Please keep the key properly for account recovery.`
  String get Please_keep_the_key_properly_for_account_recovery {
    return Intl.message(
      'Please keep the key properly for account recovery.',
      name: 'Please_keep_the_key_properly_for_account_recovery',
      desc: '',
      args: [],
    );
  }

  /// `Backup and Safety tips`
  String get Backup_and_Safety_tips {
    return Intl.message(
      'Backup and Safety tips',
      name: 'Backup_and_Safety_tips',
      desc: '',
      args: [],
    );
  }

  /// `The key is a random string that resembles your account password. Anyone with this key can access and control your account.`
  String get The_key_is_a_random_string_that_resembles_ {
    return Intl.message(
      'The key is a random string that resembles your account password. Anyone with this key can access and control your account.',
      name: 'The_key_is_a_random_string_that_resembles_',
      desc: '',
      args: [],
    );
  }

  /// `Copy Key`
  String get Copy_Key {
    return Intl.message('Copy Key', name: 'Copy_Key', desc: '', args: []);
  }

  /// `Copy Hex Key`
  String get Copy_Hex_Key {
    return Intl.message(
      'Copy Hex Key',
      name: 'Copy_Hex_Key',
      desc: '',
      args: [],
    );
  }

  /// `Please check the tips.`
  String get Please_check_the_tips {
    return Intl.message(
      'Please check the tips.',
      name: 'Please_check_the_tips',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get Login {
    return Intl.message('Login', name: 'Login', desc: '', args: []);
  }

  /// `Generate a new private key`
  String get Generate_a_new_private_key {
    return Intl.message(
      'Generate a new private key',
      name: 'Generate_a_new_private_key',
      desc: '',
      args: [],
    );
  }

  /// `I accept the`
  String get I_accept_the {
    return Intl.message(
      'I accept the',
      name: 'I_accept_the',
      desc: '',
      args: [],
    );
  }

  /// `terms of user`
  String get terms_of_user {
    return Intl.message(
      'terms of user',
      name: 'terms_of_user',
      desc: '',
      args: [],
    );
  }

  /// `Private key is null.`
  String get Private_key_is_null {
    return Intl.message(
      'Private key is null.',
      name: 'Private_key_is_null',
      desc: '',
      args: [],
    );
  }

  /// `Please accept the terms.`
  String get Please_accept_the_terms {
    return Intl.message(
      'Please accept the terms.',
      name: 'Please_accept_the_terms',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get Submit {
    return Intl.message('Submit', name: 'Submit', desc: '', args: []);
  }

  /// `Display Name`
  String get Display_Name {
    return Intl.message(
      'Display Name',
      name: 'Display_Name',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get Name {
    return Intl.message('Name', name: 'Name', desc: '', args: []);
  }

  /// `About`
  String get About {
    return Intl.message('About', name: 'About', desc: '', args: []);
  }

  /// `Picture`
  String get Picture {
    return Intl.message('Picture', name: 'Picture', desc: '', args: []);
  }

  /// `Banner`
  String get Banner {
    return Intl.message('Banner', name: 'Banner', desc: '', args: []);
  }

  /// `Website`
  String get Website {
    return Intl.message('Website', name: 'Website', desc: '', args: []);
  }

  /// `Nip05`
  String get Nip05 {
    return Intl.message('Nip05', name: 'Nip05', desc: '', args: []);
  }

  /// `Lud16`
  String get Lud16 {
    return Intl.message('Lud16', name: 'Lud16', desc: '', args: []);
  }

  /// `Input relay address.`
  String get Input_relay_address {
    return Intl.message(
      'Input relay address.',
      name: 'Input_relay_address',
      desc: '',
      args: [],
    );
  }

  /// `Address can't be null.`
  String get Address_can_t_be_null {
    return Intl.message(
      'Address can\'t be null.',
      name: 'Address_can_t_be_null',
      desc: '',
      args: [],
    );
  }

  /// `or`
  String get or {
    return Intl.message('or', name: 'or', desc: '', args: []);
  }

  /// `Empty text may be ban by relays.`
  String get Empty_text_may_be_ban_by_relays {
    return Intl.message(
      'Empty text may be ban by relays.',
      name: 'Empty_text_may_be_ban_by_relays',
      desc: '',
      args: [],
    );
  }

  /// `Note loading...`
  String get Note_loading {
    return Intl.message(
      'Note loading...',
      name: 'Note_loading',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get Following {
    return Intl.message('Following', name: 'Following', desc: '', args: []);
  }

  /// `Read`
  String get Read {
    return Intl.message('Read', name: 'Read', desc: '', args: []);
  }

  /// `Write`
  String get Write {
    return Intl.message('Write', name: 'Write', desc: '', args: []);
  }

  /// `Copy current Url`
  String get Copy_current_Url {
    return Intl.message(
      'Copy current Url',
      name: 'Copy_current_Url',
      desc: '',
      args: [],
    );
  }

  /// `Copy init Url`
  String get Copy_init_Url {
    return Intl.message(
      'Copy init Url',
      name: 'Copy_init_Url',
      desc: '',
      args: [],
    );
  }

  /// `Open in browser`
  String get Open_in_browser {
    return Intl.message(
      'Open in browser',
      name: 'Open_in_browser',
      desc: '',
      args: [],
    );
  }

  /// `Copy success!`
  String get Copy_success {
    return Intl.message(
      'Copy success!',
      name: 'Copy_success',
      desc: '',
      args: [],
    );
  }

  /// `Boost`
  String get Boost {
    return Intl.message('Boost', name: 'Boost', desc: '', args: []);
  }

  /// `Quote`
  String get Quote {
    return Intl.message('Quote', name: 'Quote', desc: '', args: []);
  }

  /// `Replying`
  String get Replying {
    return Intl.message('Replying', name: 'Replying', desc: '', args: []);
  }

  /// `Copy Note Json`
  String get Copy_Note_Json {
    return Intl.message(
      'Copy Note Json',
      name: 'Copy_Note_Json',
      desc: '',
      args: [],
    );
  }

  /// `Copy Note Pubkey`
  String get Copy_Note_Pubkey {
    return Intl.message(
      'Copy Note Pubkey',
      name: 'Copy_Note_Pubkey',
      desc: '',
      args: [],
    );
  }

  /// `Copy Note Id`
  String get Copy_Note_Id {
    return Intl.message(
      'Copy Note Id',
      name: 'Copy_Note_Id',
      desc: '',
      args: [],
    );
  }

  /// `Detail`
  String get Detail {
    return Intl.message('Detail', name: 'Detail', desc: '', args: []);
  }

  /// `Share`
  String get Share {
    return Intl.message('Share', name: 'Share', desc: '', args: []);
  }

  /// `Broadcast`
  String get Broadcast {
    return Intl.message('Broadcast', name: 'Broadcast', desc: '', args: []);
  }

  /// `Block`
  String get Block {
    return Intl.message('Block', name: 'Block', desc: '', args: []);
  }

  /// `Delete`
  String get Delete {
    return Intl.message('Delete', name: 'Delete', desc: '', args: []);
  }

  /// `Metadata can not be found.`
  String get Metadata_can_not_be_found {
    return Intl.message(
      'Metadata can not be found.',
      name: 'Metadata_can_not_be_found',
      desc: '',
      args: [],
    );
  }

  /// `not found`
  String get not_found {
    return Intl.message('not found', name: 'not_found', desc: '', args: []);
  }

  /// `Gen invoice code error.`
  String get Gen_invoice_code_error {
    return Intl.message(
      'Gen invoice code error.',
      name: 'Gen_invoice_code_error',
      desc: '',
      args: [],
    );
  }

  /// `Notices`
  String get Notices {
    return Intl.message('Notices', name: 'Notices', desc: '', args: []);
  }

  /// `Please input search content`
  String get Please_input_search_content {
    return Intl.message(
      'Please input search content',
      name: 'Please_input_search_content',
      desc: '',
      args: [],
    );
  }

  /// `Open User page`
  String get Open_User_page {
    return Intl.message(
      'Open User page',
      name: 'Open_User_page',
      desc: '',
      args: [],
    );
  }

  /// `Open Note detail`
  String get Open_Note_detail {
    return Intl.message(
      'Open Note detail',
      name: 'Open_Note_detail',
      desc: '',
      args: [],
    );
  }

  /// `Search User from cache`
  String get Search_User_from_cache {
    return Intl.message(
      'Search User from cache',
      name: 'Search_User_from_cache',
      desc: '',
      args: [],
    );
  }

  /// `Open Event from cache`
  String get Open_Event_from_cache {
    return Intl.message(
      'Open Event from cache',
      name: 'Open_Event_from_cache',
      desc: '',
      args: [],
    );
  }

  /// `Search pubkey event`
  String get Search_pubkey_event {
    return Intl.message(
      'Search pubkey event',
      name: 'Search_pubkey_event',
      desc: '',
      args: [],
    );
  }

  /// `Search note content`
  String get Search_note_content {
    return Intl.message(
      'Search note content',
      name: 'Search_note_content',
      desc: '',
      args: [],
    );
  }

  /// `Data`
  String get Data {
    return Intl.message('Data', name: 'Data', desc: '', args: []);
  }

  /// `Delete Account`
  String get Delete_Account {
    return Intl.message(
      'Delete Account',
      name: 'Delete_Account',
      desc: '',
      args: [],
    );
  }

  /// `We will try to delete you infomation. When you login with this Key again, you will lose your data.`
  String get Delete_Account_Tips {
    return Intl.message(
      'We will try to delete you infomation. When you login with this Key again, you will lose your data.',
      name: 'Delete_Account_Tips',
      desc: '',
      args: [],
    );
  }

  /// `Lnurl and Lud16 can't found.`
  String get Lnurl_and_Lud16_can_t_found {
    return Intl.message(
      'Lnurl and Lud16 can\'t found.',
      name: 'Lnurl_and_Lud16_can_t_found',
      desc: '',
      args: [],
    );
  }

  /// `Add now`
  String get Add_now {
    return Intl.message('Add now', name: 'Add_now', desc: '', args: []);
  }

  /// `Input Sats num to gen lightning invoice`
  String get Input_Sats_num_to_gen_lightning_invoice {
    return Intl.message(
      'Input Sats num to gen lightning invoice',
      name: 'Input_Sats_num_to_gen_lightning_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Input Sats num`
  String get Input_Sats_num {
    return Intl.message(
      'Input Sats num',
      name: 'Input_Sats_num',
      desc: '',
      args: [],
    );
  }

  /// `Number parse error`
  String get Number_parse_error {
    return Intl.message(
      'Number parse error',
      name: 'Number_parse_error',
      desc: '',
      args: [],
    );
  }

  /// `Input`
  String get Input {
    return Intl.message('Input', name: 'Input', desc: '', args: []);
  }

  /// `Topic`
  String get Topic {
    return Intl.message('Topic', name: 'Topic', desc: '', args: []);
  }

  /// `Note Id`
  String get Note_Id {
    return Intl.message('Note Id', name: 'Note_Id', desc: '', args: []);
  }

  /// `User Pubkey`
  String get User_Pubkey {
    return Intl.message('User Pubkey', name: 'User_Pubkey', desc: '', args: []);
  }

  /// `Translate`
  String get Translate {
    return Intl.message('Translate', name: 'Translate', desc: '', args: []);
  }

  /// `Translate Source Language`
  String get Translate_Source_Language {
    return Intl.message(
      'Translate Source Language',
      name: 'Translate_Source_Language',
      desc: '',
      args: [],
    );
  }

  /// `Translate Target Language`
  String get Translate_Target_Language {
    return Intl.message(
      'Translate Target Language',
      name: 'Translate_Target_Language',
      desc: '',
      args: [],
    );
  }

  /// `Begin to download translate model`
  String get Begin_to_download_translate_model {
    return Intl.message(
      'Begin to download translate model',
      name: 'Begin_to_download_translate_model',
      desc: '',
      args: [],
    );
  }

  /// `Upload fail.`
  String get Upload_fail {
    return Intl.message(
      'Upload fail.',
      name: 'Upload_fail',
      desc: '',
      args: [],
    );
  }

  /// `notes updated`
  String get notes_updated {
    return Intl.message(
      'notes updated',
      name: 'notes_updated',
      desc: '',
      args: [],
    );
  }

  /// `Add this relay to local?`
  String get Add_this_relay_to_local {
    return Intl.message(
      'Add this relay to local?',
      name: 'Add_this_relay_to_local',
      desc: '',
      args: [],
    );
  }

  /// `Broadcast When Boost`
  String get Broadcast_When_Boost {
    return Intl.message(
      'Broadcast When Boost',
      name: 'Broadcast_When_Boost',
      desc: '',
      args: [],
    );
  }

  /// `Find clouded relay list, do you want to download it?`
  String get Find_clouded_relay_list_do_you_want_to_download {
    return Intl.message(
      'Find clouded relay list, do you want to download it?',
      name: 'Find_clouded_relay_list_do_you_want_to_download',
      desc: '',
      args: [],
    );
  }

  /// `Input can not be null`
  String get Input_can_not_be_null {
    return Intl.message(
      'Input can not be null',
      name: 'Input_can_not_be_null',
      desc: '',
      args: [],
    );
  }

  /// `Input parse error`
  String get Input_parse_error {
    return Intl.message(
      'Input parse error',
      name: 'Input_parse_error',
      desc: '',
      args: [],
    );
  }

  /// `You had voted with`
  String get You_had_voted_with {
    return Intl.message(
      'You had voted with',
      name: 'You_had_voted_with',
      desc: '',
      args: [],
    );
  }

  /// `Close at`
  String get Close_at {
    return Intl.message('Close at', name: 'Close_at', desc: '', args: []);
  }

  /// `Zap num can not smaller then`
  String get Zap_num_can_not_smaller_then {
    return Intl.message(
      'Zap num can not smaller then',
      name: 'Zap_num_can_not_smaller_then',
      desc: '',
      args: [],
    );
  }

  /// `Zap num can not bigger then`
  String get Zap_num_can_not_bigger_then {
    return Intl.message(
      'Zap num can not bigger then',
      name: 'Zap_num_can_not_bigger_then',
      desc: '',
      args: [],
    );
  }

  /// `min zap num`
  String get min_zap_num {
    return Intl.message('min zap num', name: 'min_zap_num', desc: '', args: []);
  }

  /// `max zap num`
  String get max_zap_num {
    return Intl.message('max zap num', name: 'max_zap_num', desc: '', args: []);
  }

  /// `poll option info`
  String get poll_option_info {
    return Intl.message(
      'poll option info',
      name: 'poll_option_info',
      desc: '',
      args: [],
    );
  }

  /// `add poll option`
  String get add_poll_option {
    return Intl.message(
      'add poll option',
      name: 'add_poll_option',
      desc: '',
      args: [],
    );
  }

  /// `Forbid`
  String get Forbid {
    return Intl.message('Forbid', name: 'Forbid', desc: '', args: []);
  }

  /// `Sign fail`
  String get Sign_fail {
    return Intl.message('Sign fail', name: 'Sign_fail', desc: '', args: []);
  }

  /// `Method`
  String get Method {
    return Intl.message('Method', name: 'Method', desc: '', args: []);
  }

  /// `Content`
  String get Content {
    return Intl.message('Content', name: 'Content', desc: '', args: []);
  }

  /// `Use lightning wallet scan and send sats.`
  String get Use_lightning_wallet_scan_and_send_sats {
    return Intl.message(
      'Use lightning wallet scan and send sats.',
      name: 'Use_lightning_wallet_scan_and_send_sats',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get Any {
    return Intl.message('Any', name: 'Any', desc: '', args: []);
  }

  /// `Lightning Invoice`
  String get Lightning_Invoice {
    return Intl.message(
      'Lightning Invoice',
      name: 'Lightning_Invoice',
      desc: '',
      args: [],
    );
  }

  /// `Pay`
  String get Pay {
    return Intl.message('Pay', name: 'Pay', desc: '', args: []);
  }

  /// `There should be an universe here`
  String get There_should_be_an_universe_here {
    return Intl.message(
      'There should be an universe here',
      name: 'There_should_be_an_universe_here',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get More {
    return Intl.message('More', name: 'More', desc: '', args: []);
  }

  /// `Add a Note`
  String get Add_a_Note {
    return Intl.message('Add a Note', name: 'Add_a_Note', desc: '', args: []);
  }

  /// `Home`
  String get Home {
    return Intl.message('Home', name: 'Home', desc: '', args: []);
  }

  /// `Globals`
  String get Globals {
    return Intl.message('Globals', name: 'Globals', desc: '', args: []);
  }

  /// `Begin to load Contact History`
  String get Begin_to_load_Contact_History {
    return Intl.message(
      'Begin to load Contact History',
      name: 'Begin_to_load_Contact_History',
      desc: '',
      args: [],
    );
  }

  /// `Recovery`
  String get Recovery {
    return Intl.message('Recovery', name: 'Recovery', desc: '', args: []);
  }

  /// `Source`
  String get Source {
    return Intl.message('Source', name: 'Source', desc: '', args: []);
  }

  /// `Image save success`
  String get Image_save_success {
    return Intl.message(
      'Image save success',
      name: 'Image_save_success',
      desc: '',
      args: [],
    );
  }

  /// `Send fail`
  String get Send_fail {
    return Intl.message('Send fail', name: 'Send_fail', desc: '', args: []);
  }

  /// `Web Appbar`
  String get Web_Appbar {
    return Intl.message('Web Appbar', name: 'Web_Appbar', desc: '', args: []);
  }

  /// `Show web`
  String get Show_web {
    return Intl.message('Show web', name: 'Show_web', desc: '', args: []);
  }

  /// `Web Utils`
  String get Web_Utils {
    return Intl.message('Web Utils', name: 'Web_Utils', desc: '', args: []);
  }

  /// `Input Comment`
  String get Input_Comment {
    return Intl.message(
      'Input Comment',
      name: 'Input_Comment',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get Optional {
    return Intl.message('Optional', name: 'Optional', desc: '', args: []);
  }

  /// `Notify`
  String get Notify {
    return Intl.message('Notify', name: 'Notify', desc: '', args: []);
  }

  /// `Content warning`
  String get Content_warning {
    return Intl.message(
      'Content warning',
      name: 'Content_warning',
      desc: '',
      args: [],
    );
  }

  /// `This note contains sensitive content`
  String get This_note_contains_sensitive_content {
    return Intl.message(
      'This note contains sensitive content',
      name: 'This_note_contains_sensitive_content',
      desc: '',
      args: [],
    );
  }

  /// `Please input title`
  String get Please_input_title {
    return Intl.message(
      'Please input title',
      name: 'Please_input_title',
      desc: '',
      args: [],
    );
  }

  /// `Table Mode`
  String get Table_Mode {
    return Intl.message('Table Mode', name: 'Table_Mode', desc: '', args: []);
  }

  /// `Hour`
  String get Hour {
    return Intl.message('Hour', name: 'Hour', desc: '', args: []);
  }

  /// `Minute`
  String get Minute {
    return Intl.message('Minute', name: 'Minute', desc: '', args: []);
  }

  /// `Add Custom Emoji`
  String get Add_Custom_Emoji {
    return Intl.message(
      'Add Custom Emoji',
      name: 'Add_Custom_Emoji',
      desc: '',
      args: [],
    );
  }

  /// `Input Custom Emoji Name`
  String get Input_Custom_Emoji_Name {
    return Intl.message(
      'Input Custom Emoji Name',
      name: 'Input_Custom_Emoji_Name',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get Custom {
    return Intl.message('Custom', name: 'Custom', desc: '', args: []);
  }

  /// `Followed Tags`
  String get Followed_Tags {
    return Intl.message(
      'Followed Tags',
      name: 'Followed_Tags',
      desc: '',
      args: [],
    );
  }

  /// `From`
  String get From {
    return Intl.message('From', name: 'From', desc: '', args: []);
  }

  /// `Followed Communities`
  String get Followed_Communities {
    return Intl.message(
      'Followed Communities',
      name: 'Followed_Communities',
      desc: '',
      args: [],
    );
  }

  /// `Followed`
  String get Followed {
    return Intl.message('Followed', name: 'Followed', desc: '', args: []);
  }

  /// `Auto Open Sensitive Content`
  String get Auto_Open_Sensitive_Content {
    return Intl.message(
      'Auto Open Sensitive Content',
      name: 'Auto_Open_Sensitive_Content',
      desc: '',
      args: [],
    );
  }

  /// `Goal Amount In Sats`
  String get Goal_Amount_In_Sats {
    return Intl.message(
      'Goal Amount In Sats',
      name: 'Goal_Amount_In_Sats',
      desc: '',
      args: [],
    );
  }

  /// `Relay Mode`
  String get Relay_Mode {
    return Intl.message('Relay Mode', name: 'Relay_Mode', desc: '', args: []);
  }

  /// `Event Sign Check`
  String get Event_Sign_Check {
    return Intl.message(
      'Event Sign Check',
      name: 'Event_Sign_Check',
      desc: '',
      args: [],
    );
  }

  /// `Fast Mode`
  String get Fast_Mode {
    return Intl.message('Fast Mode', name: 'Fast_Mode', desc: '', args: []);
  }

  /// `Base Mode`
  String get Base_Mode {
    return Intl.message('Base Mode', name: 'Base_Mode', desc: '', args: []);
  }

  /// `WebRTC Permission`
  String get WebRTC_Permission {
    return Intl.message(
      'WebRTC Permission',
      name: 'WebRTC_Permission',
      desc: '',
      args: [],
    );
  }

  /// `Get Public Key`
  String get NIP07_getPublicKey {
    return Intl.message(
      'Get Public Key',
      name: 'NIP07_getPublicKey',
      desc: '',
      args: [],
    );
  }

  /// `Sign Event`
  String get NIP07_signEvent {
    return Intl.message(
      'Sign Event',
      name: 'NIP07_signEvent',
      desc: '',
      args: [],
    );
  }

  /// `Get Relays`
  String get NIP07_getRelays {
    return Intl.message(
      'Get Relays',
      name: 'NIP07_getRelays',
      desc: '',
      args: [],
    );
  }

  /// `Encrypt`
  String get NIP07_encrypt {
    return Intl.message('Encrypt', name: 'NIP07_encrypt', desc: '', args: []);
  }

  /// `Decrypt`
  String get NIP07_decrypt {
    return Intl.message('Decrypt', name: 'NIP07_decrypt', desc: '', args: []);
  }

  /// `Lightning payment`
  String get NIP07_lightning {
    return Intl.message(
      'Lightning payment',
      name: 'NIP07_lightning',
      desc: '',
      args: [],
    );
  }

  /// `Show more`
  String get Show_more {
    return Intl.message('Show more', name: 'Show_more', desc: '', args: []);
  }

  /// `Limit Note Height`
  String get Limit_Note_Height {
    return Intl.message(
      'Limit Note Height',
      name: 'Limit_Note_Height',
      desc: '',
      args: [],
    );
  }

  /// `Add to private bookmark`
  String get Add_to_private_bookmark {
    return Intl.message(
      'Add to private bookmark',
      name: 'Add_to_private_bookmark',
      desc: '',
      args: [],
    );
  }

  /// `Add to public bookmark`
  String get Add_to_public_bookmark {
    return Intl.message(
      'Add to public bookmark',
      name: 'Add_to_public_bookmark',
      desc: '',
      args: [],
    );
  }

  /// `Remove from private bookmark`
  String get Remove_from_private_bookmark {
    return Intl.message(
      'Remove from private bookmark',
      name: 'Remove_from_private_bookmark',
      desc: '',
      args: [],
    );
  }

  /// `Remove from public bookmark`
  String get Remove_from_public_bookmark {
    return Intl.message(
      'Remove from public bookmark',
      name: 'Remove_from_public_bookmark',
      desc: '',
      args: [],
    );
  }

  /// `Bookmark`
  String get Bookmark {
    return Intl.message('Bookmark', name: 'Bookmark', desc: '', args: []);
  }

  /// `Private`
  String get Private {
    return Intl.message('Private', name: 'Private', desc: '', args: []);
  }

  /// `Public`
  String get Public {
    return Intl.message('Public', name: 'Public', desc: '', args: []);
  }

  /// `Creator`
  String get Creator {
    return Intl.message('Creator', name: 'Creator', desc: '', args: []);
  }

  /// `Wear`
  String get Wear {
    return Intl.message('Wear', name: 'Wear', desc: '', args: []);
  }

  /// `Private Direct Message is a new message type that some clients do not yet support.`
  String get Private_DM_Notice {
    return Intl.message(
      'Private Direct Message is a new message type that some clients do not yet support.',
      name: 'Private_DM_Notice',
      desc: '',
      args: [],
    );
  }

  /// `Local Relay`
  String get LocalRelay {
    return Intl.message('Local Relay', name: 'LocalRelay', desc: '', args: []);
  }

  /// `My Relays`
  String get MyRelays {
    return Intl.message('My Relays', name: 'MyRelays', desc: '', args: []);
  }

  /// `Temp Relays`
  String get TempRelays {
    return Intl.message('Temp Relays', name: 'TempRelays', desc: '', args: []);
  }

  /// `Url`
  String get Url {
    return Intl.message('Url', name: 'Url', desc: '', args: []);
  }

  /// `Owner`
  String get Owner {
    return Intl.message('Owner', name: 'Owner', desc: '', args: []);
  }

  /// `Contact`
  String get Contact {
    return Intl.message('Contact', name: 'Contact', desc: '', args: []);
  }

  /// `Soft`
  String get Soft {
    return Intl.message('Soft', name: 'Soft', desc: '', args: []);
  }

  /// `Version`
  String get Version {
    return Intl.message('Version', name: 'Version', desc: '', args: []);
  }

  /// `Relay Info`
  String get Relay_Info {
    return Intl.message('Relay Info', name: 'Relay_Info', desc: '', args: []);
  }

  /// `DMs`
  String get DMs {
    return Intl.message('DMs', name: 'DMs', desc: '', args: []);
  }

  /// `Close Private DM`
  String get Close_Private_DM {
    return Intl.message(
      'Close Private DM',
      name: 'Close_Private_DM',
      desc: '',
      args: [],
    );
  }

  /// `Open Private DM`
  String get Open_Private_DM {
    return Intl.message(
      'Open Private DM',
      name: 'Open_Private_DM',
      desc: '',
      args: [],
    );
  }

  /// `Image or Video`
  String get Image_or_Video {
    return Intl.message(
      'Image or Video',
      name: 'Image_or_Video',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get Take_photo {
    return Intl.message('Take photo', name: 'Take_photo', desc: '', args: []);
  }

  /// `Take video`
  String get Take_video {
    return Intl.message('Take video', name: 'Take_video', desc: '', args: []);
  }

  /// `Custom Emoji`
  String get Custom_Emoji {
    return Intl.message(
      'Custom Emoji',
      name: 'Custom_Emoji',
      desc: '',
      args: [],
    );
  }

  /// `Emoji`
  String get Emoji {
    return Intl.message('Emoji', name: 'Emoji', desc: '', args: []);
  }

  /// `Mention User`
  String get Mention_User {
    return Intl.message(
      'Mention User',
      name: 'Mention_User',
      desc: '',
      args: [],
    );
  }

  /// `Hashtag`
  String get Hashtag {
    return Intl.message('Hashtag', name: 'Hashtag', desc: '', args: []);
  }

  /// `Sensitive Content`
  String get Sensitive_Content {
    return Intl.message(
      'Sensitive Content',
      name: 'Sensitive_Content',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get Subject {
    return Intl.message('Subject', name: 'Subject', desc: '', args: []);
  }

  /// `Delay Send`
  String get Delay_Send {
    return Intl.message('Delay Send', name: 'Delay_Send', desc: '', args: []);
  }

  /// `Poll`
  String get Poll {
    return Intl.message('Poll', name: 'Poll', desc: '', args: []);
  }

  /// `Zap Goals`
  String get Zap_Goals {
    return Intl.message('Zap Goals', name: 'Zap_Goals', desc: '', args: []);
  }

  /// `Data Sync Mode`
  String get Data_Sync_Mode {
    return Intl.message(
      'Data Sync Mode',
      name: 'Data_Sync_Mode',
      desc: '',
      args: [],
    );
  }

  /// `Backup my notes`
  String get Backup_my_notes {
    return Intl.message(
      'Backup my notes',
      name: 'Backup_my_notes',
      desc: '',
      args: [],
    );
  }

  /// `Import notes`
  String get Import_notes {
    return Intl.message(
      'Import notes',
      name: 'Import_notes',
      desc: '',
      args: [],
    );
  }

  /// `File save success`
  String get File_save_success {
    return Intl.message(
      'File save success',
      name: 'File_save_success',
      desc: '',
      args: [],
    );
  }

  /// `Sync Upload`
  String get Sync_Upload {
    return Intl.message('Sync Upload', name: 'Sync_Upload', desc: '', args: []);
  }

  /// `Upload num`
  String get Upload_num {
    return Intl.message('Upload num', name: 'Upload_num', desc: '', args: []);
  }

  /// `Send interval`
  String get Send_interval {
    return Intl.message(
      'Send interval',
      name: 'Send_interval',
      desc: '',
      args: [],
    );
  }

  /// `Select relay to upload`
  String get Select_relay_to_upload {
    return Intl.message(
      'Select relay to upload',
      name: 'Select_relay_to_upload',
      desc: '',
      args: [],
    );
  }

  /// `Please select relays`
  String get Please_select_relays {
    return Intl.message(
      'Please select relays',
      name: 'Please_select_relays',
      desc: '',
      args: [],
    );
  }

  /// `Follow set`
  String get Follow_set {
    return Intl.message('Follow set', name: 'Follow_set', desc: '', args: []);
  }

  /// `Follow set name edit`
  String get Follow_set_name_edit {
    return Intl.message(
      'Follow set name edit',
      name: 'Follow_set_name_edit',
      desc: '',
      args: [],
    );
  }

  /// `Input follow set name`
  String get Input_follow_set_name {
    return Intl.message(
      'Input follow set name',
      name: 'Input_follow_set_name',
      desc: '',
      args: [],
    );
  }

  /// `Edit name`
  String get Edit_name {
    return Intl.message('Edit name', name: 'Edit_name', desc: '', args: []);
  }

  /// `Edit`
  String get Edit {
    return Intl.message('Edit', name: 'Edit', desc: '', args: []);
  }

  /// `Thread Mode`
  String get Thread_Mode {
    return Intl.message('Thread Mode', name: 'Thread_Mode', desc: '', args: []);
  }

  /// `Max Sub Notes`
  String get Max_Sub_Notes {
    return Intl.message(
      'Max Sub Notes',
      name: 'Max_Sub_Notes',
      desc: '',
      args: [],
    );
  }

  /// `Full Mode`
  String get Full_Mode {
    return Intl.message('Full Mode', name: 'Full_Mode', desc: '', args: []);
  }

  /// `Trace Mode`
  String get Trace_Mode {
    return Intl.message('Trace Mode', name: 'Trace_Mode', desc: '', args: []);
  }

  /// `Please input the max sub notes number`
  String get Please_input_the_max_sub_notes_number {
    return Intl.message(
      'Please input the max sub notes number',
      name: 'Please_input_the_max_sub_notes_number',
      desc: '',
      args: [],
    );
  }

  /// `Show more replies`
  String get Show_more_replies {
    return Intl.message(
      'Show more replies',
      name: 'Show_more_replies',
      desc: '',
      args: [],
    );
  }

  /// `This operation cannot be undo`
  String get This_operation_cannot_be_undo {
    return Intl.message(
      'This operation cannot be undo',
      name: 'This_operation_cannot_be_undo',
      desc: '',
      args: [],
    );
  }

  /// `Data Length`
  String get Data_Length {
    return Intl.message('Data Length', name: 'Data_Length', desc: '', args: []);
  }

  /// `File Size`
  String get File_Size {
    return Intl.message('File Size', name: 'File_Size', desc: '', args: []);
  }

  /// `Clear All Data`
  String get Clear_All_Data {
    return Intl.message(
      'Clear All Data',
      name: 'Clear_All_Data',
      desc: '',
      args: [],
    );
  }

  /// `Clear Not My Data`
  String get Clear_Not_My_Data {
    return Intl.message(
      'Clear Not My Data',
      name: 'Clear_Not_My_Data',
      desc: '',
      args: [],
    );
  }

  /// `File is too big for NIP-95`
  String get File_is_too_big_for_NIP_95 {
    return Intl.message(
      'File is too big for NIP-95',
      name: 'File_is_too_big_for_NIP_95',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get Address {
    return Intl.message('Address', name: 'Address', desc: '', args: []);
  }

  /// `Lightning Address`
  String get Lightning_Address {
    return Intl.message(
      'Lightning Address',
      name: 'Lightning_Address',
      desc: '',
      args: [],
    );
  }

  /// `Hide Relay Notices`
  String get Hide_Relay_Notices {
    return Intl.message(
      'Hide Relay Notices',
      name: 'Hide_Relay_Notices',
      desc: '',
      args: [],
    );
  }

  /// `Popular Users`
  String get Popular_Users {
    return Intl.message(
      'Popular Users',
      name: 'Popular_Users',
      desc: '',
      args: [],
    );
  }

  /// `Split and Transfer Zap`
  String get Split_and_Transfer_Zap {
    return Intl.message(
      'Split and Transfer Zap',
      name: 'Split_and_Transfer_Zap',
      desc: '',
      args: [],
    );
  }

  /// `The support client will split and transfer zaps to the users you had added.`
  String get Split_Zap_Tip {
    return Intl.message(
      'The support client will split and transfer zaps to the users you had added.',
      name: 'Split_Zap_Tip',
      desc: '',
      args: [],
    );
  }

  /// `Add User`
  String get Add_User {
    return Intl.message('Add User', name: 'Add_User', desc: '', args: []);
  }

  /// `Zap number not enough`
  String get Zap_number_not_enough {
    return Intl.message(
      'Zap number not enough',
      name: 'Zap_number_not_enough',
      desc: '',
      args: [],
    );
  }

  /// `NWC is Nostr Wallet Connect, with NWC Setting you zap within the app.`
  String get NWC_TIP1 {
    return Intl.message(
      'NWC is Nostr Wallet Connect, with NWC Setting you zap within the app.',
      name: 'NWC_TIP1',
      desc: '',
      args: [],
    );
  }

  /// `NWC URL is like`
  String get NWC_TIP2 {
    return Intl.message(
      'NWC URL is like',
      name: 'NWC_TIP2',
      desc: '',
      args: [],
    );
  }

  /// `PLease input NWC URL`
  String get PLease_input_NWC_URL {
    return Intl.message(
      'PLease input NWC URL',
      name: 'PLease_input_NWC_URL',
      desc: '',
      args: [],
    );
  }

  /// `is sending`
  String get is_sending {
    return Intl.message('is sending', name: 'is_sending', desc: '', args: []);
  }

  /// `Image service path`
  String get Image_service_path {
    return Intl.message(
      'Image service path',
      name: 'Image_service_path',
      desc: '',
      args: [],
    );
  }

  /// `Card Color`
  String get Card_Color {
    return Intl.message('Card Color', name: 'Card_Color', desc: '', args: []);
  }

  /// `Main Font Color`
  String get Main_Font_Color {
    return Intl.message(
      'Main Font Color',
      name: 'Main_Font_Color',
      desc: '',
      args: [],
    );
  }

  /// `Hint Font Color`
  String get Hint_Font_Color {
    return Intl.message(
      'Hint Font Color',
      name: 'Hint_Font_Color',
      desc: '',
      args: [],
    );
  }

  /// `Background Image`
  String get Background_Image {
    return Intl.message(
      'Background Image',
      name: 'Background_Image',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get Image {
    return Intl.message('Image', name: 'Image', desc: '', args: []);
  }

  /// `Download`
  String get Download {
    return Intl.message('Download', name: 'Download', desc: '', args: []);
  }

  /// `Pubkey`
  String get Pubkey {
    return Intl.message('Pubkey', name: 'Pubkey', desc: '', args: []);
  }

  /// `Color`
  String get Color {
    return Intl.message('Color', name: 'Color', desc: '', args: []);
  }

  /// `Login fail`
  String get Login_fail {
    return Intl.message('Login fail', name: 'Login_fail', desc: '', args: []);
  }

  /// `You are logged in in read-only mode.`
  String get Readonly_login_tip {
    return Intl.message(
      'You are logged in in read-only mode.',
      name: 'Readonly_login_tip',
      desc: '',
      args: [],
    );
  }

  /// `Login With Android Signer`
  String get Login_With_Android_Signer {
    return Intl.message(
      'Login With Android Signer',
      name: 'Login_With_Android_Signer',
      desc: '',
      args: [],
    );
  }

  /// `Read Only`
  String get Read_Only {
    return Intl.message('Read Only', name: 'Read_Only', desc: '', args: []);
  }

  /// `Login With NIP07 Extension`
  String get Login_With_NIP07_Extension {
    return Intl.message(
      'Login With NIP07 Extension',
      name: 'Login_With_NIP07_Extension',
      desc: '',
      args: [],
    );
  }

  /// `Group`
  String get Group {
    return Intl.message('Group', name: 'Group', desc: '', args: []);
  }

  /// `Groups`
  String get Groups {
    return Intl.message('Groups', name: 'Groups', desc: '', args: []);
  }

  /// `Admins`
  String get Admins {
    return Intl.message('Admins', name: 'Admins', desc: '', args: []);
  }

  /// `Members`
  String get Members {
    return Intl.message('Members', name: 'Members', desc: '', args: []);
  }

  /// `Relay`
  String get Relay {
    return Intl.message('Relay', name: 'Relay', desc: '', args: []);
  }

  /// `GroupId`
  String get GroupId {
    return Intl.message('GroupId', name: 'GroupId', desc: '', args: []);
  }

  /// `public`
  String get public {
    return Intl.message('public', name: 'public', desc: '', args: []);
  }

  /// `private`
  String get private {
    return Intl.message('private', name: 'private', desc: '', args: []);
  }

  /// `closed`
  String get closed {
    return Intl.message('closed', name: 'closed', desc: '', args: []);
  }

  /// `Chat`
  String get Chat {
    return Intl.message('Chat', name: 'Chat', desc: '', args: []);
  }

  /// `Add`
  String get Add {
    return Intl.message('Add', name: 'Add', desc: '', args: []);
  }

  /// `Join Group`
  String get Join_Group {
    return Intl.message('Join Group', name: 'Join_Group', desc: '', args: []);
  }

  /// `Create Group`
  String get Create_Group {
    return Intl.message(
      'Create Group',
      name: 'Create_Group',
      desc: '',
      args: [],
    );
  }

  /// `Cache Relay`
  String get Cache_Relay {
    return Intl.message('Cache Relay', name: 'Cache_Relay', desc: '', args: []);
  }

  /// `Normal`
  String get Normal {
    return Intl.message('Normal', name: 'Normal', desc: '', args: []);
  }

  /// `Cache`
  String get Cache {
    return Intl.message('Cache', name: 'Cache', desc: '', args: []);
  }

  /// `Copy`
  String get Copy {
    return Intl.message('Copy', name: 'Copy', desc: '', args: []);
  }

  /// `Please input summary`
  String get Please_input_summary {
    return Intl.message(
      'Please input summary',
      name: 'Please_input_summary',
      desc: '',
      args: [],
    );
  }

  /// `Show Window`
  String get Show_Window {
    return Intl.message('Show Window', name: 'Show_Window', desc: '', args: []);
  }

  /// `Exit App`
  String get Exit_App {
    return Intl.message('Exit App', name: 'Exit_App', desc: '', args: []);
  }

  /// `Note`
  String get Note {
    return Intl.message('Note', name: 'Note', desc: '', args: []);
  }

  /// `Article`
  String get Article {
    return Intl.message('Article', name: 'Article', desc: '', args: []);
  }

  /// `Media`
  String get Media {
    return Intl.message('Media', name: 'Media', desc: '', args: []);
  }

  /// `Zap Goal`
  String get Zap_Goal {
    return Intl.message('Zap Goal', name: 'Zap_Goal', desc: '', args: []);
  }

  /// `Reply`
  String get Reply {
    return Intl.message('Reply', name: 'Reply', desc: '', args: []);
  }

  /// `New note receive`
  String get New_note_receive {
    return Intl.message(
      'New note receive',
      name: 'New_note_receive',
      desc: '',
      args: [],
    );
  }

  /// `New Message receive`
  String get New_message_receive {
    return Intl.message(
      'New Message receive',
      name: 'New_message_receive',
      desc: '',
      args: [],
    );
  }

  /// `Mentioned note notice`
  String get Mentioned_note_notice {
    return Intl.message(
      'Mentioned note notice',
      name: 'Mentioned_note_notice',
      desc: '',
      args: [],
    );
  }

  /// `Follow note notice`
  String get Follow_note_notice {
    return Intl.message(
      'Follow note notice',
      name: 'Follow_note_notice',
      desc: '',
      args: [],
    );
  }

  /// `Message notice`
  String get Message_notice {
    return Intl.message(
      'Message notice',
      name: 'Message_notice',
      desc: '',
      args: [],
    );
  }

  /// `Note Client Tag`
  String get Note_Client_Tag {
    return Intl.message(
      'Note Client Tag',
      name: 'Note_Client_Tag',
      desc: '',
      args: [],
    );
  }

  /// `Which added with client tag in your notes, you can not see it but someone can`
  String get Note_Client_Tag_Des {
    return Intl.message(
      'Which added with client tag in your notes, you can not see it but someone can',
      name: 'Note_Client_Tag_Des',
      desc: '',
      args: [],
    );
  }

  /// `Note Tail`
  String get Note_Tail {
    return Intl.message('Note Tail', name: 'Note_Tail', desc: '', args: []);
  }

  /// `Which will auto added when you are sending notes.`
  String get Note_Tail_Des {
    return Intl.message(
      'Which will auto added when you are sending notes.',
      name: 'Note_Tail_Des',
      desc: '',
      args: [],
    );
  }

  /// `Input too long`
  String get Input_too_long {
    return Intl.message(
      'Input too long',
      name: 'Input_too_long',
      desc: '',
      args: [],
    );
  }

  /// `You are not in this group, please join it first!`
  String get Join_group_notice {
    return Intl.message(
      'You are not in this group, please join it first!',
      name: 'Join_group_notice',
      desc: '',
      args: [],
    );
  }

  /// `You haven't added this group, please add it first!`
  String get Add_group_notice {
    return Intl.message(
      'You haven\'t added this group, please add it first!',
      name: 'Add_group_notice',
      desc: '',
      args: [],
    );
  }

  /// `Remove Cache`
  String get Remove_Cache {
    return Intl.message(
      'Remove Cache',
      name: 'Remove_Cache',
      desc: '',
      args: [],
    );
  }

  /// `Remove media cache`
  String get Remove_media_cache {
    return Intl.message(
      'Remove media cache',
      name: 'Remove_media_cache',
      desc: '',
      args: [],
    );
  }

  /// `Remove meta cache`
  String get Remove_meta_cache {
    return Intl.message(
      'Remove meta cache',
      name: 'Remove_meta_cache',
      desc: '',
      args: [],
    );
  }

  /// `Remove relay cache`
  String get Remove_relay_cache {
    return Intl.message(
      'Remove relay cache',
      name: 'Remove_relay_cache',
      desc: '',
      args: [],
    );
  }

  /// `Tags Spam Filter`
  String get Tags_Spam_Filter {
    return Intl.message(
      'Tags Spam Filter',
      name: 'Tags_Spam_Filter',
      desc: '',
      args: [],
    );
  }

  /// `Wallet`
  String get Wallet {
    return Intl.message('Wallet', name: 'Wallet', desc: '', args: []);
  }

  /// `Receive`
  String get Receive {
    return Intl.message('Receive', name: 'Receive', desc: '', args: []);
  }

  /// `Balance`
  String get Balance {
    return Intl.message('Balance', name: 'Balance', desc: '', args: []);
  }

  /// `Last Transactions`
  String get Last_Transactions {
    return Intl.message(
      'Last Transactions',
      name: 'Last_Transactions',
      desc: '',
      args: [],
    );
  }

  /// `Comment`
  String get Comment {
    return Intl.message('Comment', name: 'Comment', desc: '', args: []);
  }

  /// `Generate Invoice`
  String get Generate_Invoice {
    return Intl.message(
      'Generate Invoice',
      name: 'Generate_Invoice',
      desc: '',
      args: [],
    );
  }

  /// `QrCode`
  String get QrCode {
    return Intl.message('QrCode', name: 'QrCode', desc: '', args: []);
  }

  /// `Send Zap`
  String get Send_Zap {
    return Intl.message('Send Zap', name: 'Send_Zap', desc: '', args: []);
  }

  /// `Next`
  String get Next {
    return Intl.message('Next', name: 'Next', desc: '', args: []);
  }

  /// `Scan`
  String get Scan {
    return Intl.message('Scan', name: 'Scan', desc: '', args: []);
  }

  /// `Input a Lightning Address, Lightning Invoice or LNURL`
  String get Wallet_send_tips {
    return Intl.message(
      'Input a Lightning Address, Lightning Invoice or LNURL',
      name: 'Wallet_send_tips',
      desc: '',
      args: [],
    );
  }

  /// `Updated`
  String get Updated {
    return Intl.message('Updated', name: 'Updated', desc: '', args: []);
  }

  /// `Created by`
  String get Created_by {
    return Intl.message('Created by', name: 'Created_by', desc: '', args: []);
  }

  /// `Starter packs`
  String get Starter_packs {
    return Intl.message(
      'Starter packs',
      name: 'Starter_packs',
      desc: '',
      args: [],
    );
  }

  /// `Open Relay`
  String get Open_Relay {
    return Intl.message('Open Relay', name: 'Open_Relay', desc: '', args: []);
  }

  /// `All`
  String get All {
    return Intl.message('All', name: 'All', desc: '', args: []);
  }

  /// `You`
  String get You {
    return Intl.message('You', name: 'You', desc: '', args: []);
  }

  /// `Images`
  String get Images {
    return Intl.message('Images', name: 'Images', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'bg'),
      Locale.fromSubtags(languageCode: 'cs'),
      Locale.fromSubtags(languageCode: 'da'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'el'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'et'),
      Locale.fromSubtags(languageCode: 'fi'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'hu'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'nl'),
      Locale.fromSubtags(languageCode: 'pl'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'ro'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'sl'),
      Locale.fromSubtags(languageCode: 'sv'),
      Locale.fromSubtags(languageCode: 'th'),
      Locale.fromSubtags(languageCode: 'vi'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
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
