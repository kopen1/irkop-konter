import 'package:flutter/material.dart';

class IrkopSectionHeader extends StatelessWidget {
  const IrkopSectionHeader({super.key,required this.eyebrow,required this.title,required this.subtitle,required this.icon,required this.action});
  final String eyebrow,title,subtitle,action; final IconData icon;
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),color:Theme.of(context).colorScheme.primaryContainer),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:10),Expanded(child:Text(eyebrow.toUpperCase(),style:Theme.of(context).textTheme.labelMedium))]),
      const SizedBox(height:18),Text(title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
      const SizedBox(height:6),Text(subtitle),const SizedBox(height:16),
      Align(alignment:Alignment.centerLeft,child:FilledButton.tonal(onPressed:null,child:Text(action))),
    ]),
  );
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key,required this.icon,required this.title,required this.subtitle});
  final IconData icon;final String title,subtitle;
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.all(24),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
      CircleAvatar(radius:34,child:Icon(icon,size:34)),const SizedBox(height:16),
      Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:8),Text(subtitle,textAlign:TextAlign.center),
    ])),
  );
}
