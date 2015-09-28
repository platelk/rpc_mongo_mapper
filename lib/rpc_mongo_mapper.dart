library rpc_mongo_mapper;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:rpc/rpc.dart';
import 'package:rpc/common.dart';
import 'package:rpc/src/parser.dart';
import 'package:rpc/src/config.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:amqp_rpc_binder/amqp_rpc_binder.dart';

part 'src/mongo_mapper.dart';