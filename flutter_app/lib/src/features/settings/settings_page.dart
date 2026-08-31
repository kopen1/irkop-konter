import 'package:flutter/material.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/data/business_context_repository.dart';
import '../../shared/irkop_ui.dart';
class SettingsPage extends StatelessWidget{const SettingsPage({super.key,this.businessContext});final BusinessContext? businessContext;@override Widget build(BuildContext context){final ctx=businessContext;return ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Bisnis',title:'Pengaturan',subtitle:'Kelola informasi bisnis dan akses aplikasi.',icon:Icons.settings_outlined,action:'Owner control'),
 const SizedBox(height:18),
 Card(child:Column(children:[
 ListTile(leading:const Icon(Icons.business_outlined),title:Text(ctx?.businessName??'IRKOP Demo'),subtitle:const Text('Nama bisnis')),
 const Divider(height:1),ListTile(leading:const Icon(Icons.storefront_outlined),title:Text(ctx?.outletName??'Mode Demo'),subtitle:const Text('Outlet aktif')),
 ])),
 const SizedBox(height:12),
 Card(child:Column(children:[
 const ListTile(leading:Icon(Icons.devices_outlined),title:Text('Perangkat & Slot'),subtitle:Text('Persiapan untuk sistem lisensi')),
 const Divider(height:1),const ListTile(leading:Icon(Icons.cloud_outlined),title:Text('Koneksi Database'),subtitle:Text('Supabase')),
 ])),
 const SizedBox(height:18),FilledButton.tonalIcon(onPressed:()=>AuthRepository().signOut(),icon:const Icon(Icons.logout),label:const Text('Keluar dari akun')),
 ]);}}
