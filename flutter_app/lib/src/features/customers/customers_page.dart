import 'package:flutter/material.dart';
import '../../shared/irkop_ui.dart';
class CustomersPage extends StatelessWidget{const CustomersPage({super.key,this.businessId});final String? businessId;@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Pelanggan',title:'Data Pelanggan',subtitle:'Kelola pelanggan dan riwayat hubungan bisnis.',icon:Icons.people_outline,action:'Terhubung ke database'),
 const SizedBox(height:20),
 Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person_add_alt_1_outlined)),title:const Text('Pelanggan Baru'),subtitle:const Text('Form input pelanggan akan menjadi tahap berikutnya.'),trailing:const Icon(Icons.chevron_right))),
 const SizedBox(height:12),
 const EmptyStateCard(icon:Icons.people_outline,title:'Belum ada pelanggan',subtitle:'Saat pelanggan ditambahkan ke transaksi atau database, datanya akan muncul di sini.'),
 ]);}
