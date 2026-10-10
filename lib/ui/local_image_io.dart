import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider? localImage(String uri) =>
    uri.startsWith('file:') ? FileImage(File.fromUri(Uri.parse(uri))) : null;
