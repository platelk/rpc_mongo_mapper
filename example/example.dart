import 'dart:io';

import 'package:rpc/rpc.dart';
import 'package:rpc_mongo_mapper/rpc_mongo_mapper.dart';
import 'package:mongo_dart/mongo_dart.dart';

class Job {
  String id;
  String jobTitle;
}

@ApiClass(
    version: "v1",
    name: "job",
    title: 'job managment service'
)
class JobService {
  var db;

  @ApiResource(name: "managment/") // the name don't matter
  MongoMapper<Job> jobs = new MongoMapper<Job>();

  JobService() {
    db = new Db("mongodb://localhost:27017/myproject");
    db.open().then((_) {
      jobs.collec = db.collection("jobs");
    });
  }
}
final ApiServer _apiServer = new ApiServer();

main() async {
  _apiServer.addApi(new JobService());
  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8080);
  server.listen(_apiServer.httpRequestHandler);
}
