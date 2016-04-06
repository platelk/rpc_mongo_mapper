part of rpc_mongo_mapper;

///
 /// [beforeHandler] is the handler call before each action
 /// Somme of the field can be null depend of which method call the beforeHandler
 ///
 /// Note : if you return anything, the return will be directly use as return of the request
 ///
typedef beforeHandler(String id, var filter, var data);

///
 /// [afterHandler] is the handler call after each action
 /// Somme of the field can be null depend of which method call the afterHandler
 ///
 /// Note : if you return anything, the return will be directly use as return of the request
 ///
typedef afterHandler(var data);

///
 /// [MongoMapper] is a mongodb mapper for [rpc](https://pub.dartlang.org/packages/rpc) package.
 ///
 /// It's provide simple operation on the collection [MongoMapper.collec] like :
 ///
 ///  * **GET /data** -> returns the list of data in the collection
 ///  * **GET /data/:id** -> return a element from its id in the collection
 ///  * **POST /data** -> Create a new entry in the collection
 ///  * **PUT /data** -> Update a entry in the collection
 ///  * **DELETE /data** -> Delete entries that match the filter in the collection
 ///  * **DELETE /data/:id** -> Delete the entry that match the id in the collection
 ///  * **PATCH /data/:id** -> Update some filed of the entry specified by :id
 ///
 /// The filter syntax use is a Map with each key represent a field name inside the collection then :
 ///
 ///  * a value, so the '.eq' matcher will be use
 ///  * a map of matcher with their parameters
 ///
 /// example:
 ///
 ///  * To filter age greater than 30 and lower than 45 the filter will be write :
 ///
 ///     `?filter={"age":{"gt":"30","lt":"45"}}`
 ///
 ///  * If we want only age equal to 42:
 ///
 ///     `?filter={"age":"42"}`
 ///
 /// the available filter are :
 ///
 ///  * 'gte' -> greater than
 ///  * 'gte'* -> greater or equal to
 ///  * 'lt' -> lower than
 ///  * 'lte' -> lower or equal to
 ///  * 'eq' -> equal to
 ///  * 'ne' -> not equal to
 ///  * 'match' -> match the given regexp
 ///
class MongoMapper<T> {
  static const String accessKey = "data";
  ApiConfigSchema apiConfigSchema;
  String name;
  DbCollection collec;

  List<beforeHandler> beforeGet = [];
  List<beforeHandler> beforePut = [];
  List<beforeHandler> beforePost = [];
  List<beforeHandler> beforeDelete = [];
  List<beforeHandler> beforePatch = [];

  List<afterHandler> afterGet = [];
  List<afterHandler> afterPut = [];
  List<afterHandler> afterPost = [];
  List<afterHandler> afterDelete = [];
  List<afterHandler> afterPatch = [];

  /// [new MongoMapper] will create a new instance and will use [T] as Type to convert JSON data from mongodb
  ///
  /// [this.collec] is the name of the collection that will be use to search / create / update inside mongodb
  MongoMapper({this.collec}) {
    ApiParser parser = new ApiParser();
    apiConfigSchema = parser.parseSchema(reflectClass(T), false);
    name = apiConfigSchema.schemaName;
  }

   /// [MongoMapper.toJson] use the [rpc] package transformation to JSON function to transform your object to JSON object
   ///
  toJson(T obj) {
    var json = apiConfigSchema.toResponse(obj);
    json["_id"] = json["id"];
    if (json["_id"] == null)
      json.remove("_id");
    return json;
  }

   /// [MongoMapper.toJson] use the [rpc] package transformation from JSON function to transform your JSON object to a new instance of your type T
   ///
  fromJson(var json) {
    try {
      json["id"] = GetStringId(json["_id"]);
      json.remove("_id");
      return apiConfigSchema.fromRequest(json);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      throw new InternalServerError('Impossible to convert body');
    }
  }

  before(beforeHandler handler) {
    beforeDelete.add(handler);
    beforeGet.add(handler);
    beforePatch.add(handler);
    beforePost.add(handler);
    beforePut.add(handler);
  }

  after(afterHandler handler) {
    afterDelete.add(handler);
    afterGet.add(handler);
    afterPatch.add(handler);
    afterPost.add(handler);
    afterPut.add(handler);
  }

  SelectorBuilder _createFilter(String filter, {var id, int limit}) {
    var w = where;
    var obj = JSON.decode(filter == null ? "{}" : filter);
    if (id != null) {
      w.id(GetObjectId(id));
    }
    if (obj["id"] != null) {
      w.id(GetObjectId(obj["id"]));
      obj.remove("id");
    }
    if (obj["_id"] != null) {
      w.id(GetObjectId(obj["_id"]));
      obj.remove("_id");
    }

    if (obj is Map) {
      obj.forEach((var key, var value) {
        if (value is Map) {
          value.forEach((var k, var v) {
            if (k == 'lt') w.lt(key, v);
            else if (k == "gt") w.gt(key, v);
            else if (k == "gte") w.gte(key, v);
            else if (k == "lte") w.lte(key, v);
            else if (k == "eq") w.eq(key, v);
            else if (k == "ne") w.ne(key, v);
            else if (k == "match") w.match(key, v);
          });
        } else {
          w.eq(key, value);
        }
      });
    }
    if (limit != null) w.limit(limit);
    return w;
  }

  applyHandler(List handlers, List arg) {
    var ret;
    for (var f in handlers) {
      ret = Function.apply(f, arg);
      if (ret != null) {
        return ret;
      }
    }
    return null;
  }

 /// [getModel] return a list of <T> object that match the specified filters
 ///
 /// access : GET http://<server_ip>:<server_port>/<your>/<api>/<path>/data?filter=<your filter>&limit=<limit_nb_entry>
 ///
  @ApiMethod(path: "${accessKey}", method: 'GET')
  @Register()
  Future<List<T>> getModel({String filter, int limit}) async {
    var ret = applyHandler(beforeGet, [null, filter, null]);

    if (ret != null) return ret;

    Stream<Map> cursor = collec.find(_createFilter(filter, limit: limit));
    List<T> l = [];
    await cursor.forEach((element) {
      var e = fromJson(element);
      l.add(e);
    });

    ret = applyHandler(afterGet, [l]);
    if (ret != null) return ret;

    return l;
  }

   /// [getModelById] return a <T> object that match the specified id
   ///
   /// access : GET http://<server_ip>:<server_port>/<your>/<api>/<path>/data/<id>?filter=<your filter>&limit=<limit_nb_entry>
   ///
  @ApiMethod(path: "${accessKey}/{id}", method: 'GET')
  @Register()
  Future<T> getModelById(String id, {String filter, int limit}) async {
    var ret = applyHandler(beforeGet, [id, filter, null]);
    if (ret != null) return ret;

    var json;
    json = await collec.findOne(_createFilter(filter, limit: limit, id: id));

    if (json == null) {
      throw new NotFoundError("no object with id : ${id}");
    }
    T obj = fromJson(json);

    ret = applyHandler(afterGet, [obj]);
    if (ret != null) return ret;

    return obj;
  }

   /// [postModel] create a new entry inside your collection with the JSON representation of the object inside the body
   ///
   /// return the new entry
   ///
   /// access : POST http://<server_ip>:<server_port>/<your>/<api>/<path>/data
   ///
  @ApiMethod(path: accessKey, method: 'POST')
  @Register()
  Future<T> postModel(T model) async {
    var ret = applyHandler(beforePost, [null, null, model]);
    if (ret != null) return ret;

    var json = toJson(model);
    var tmp = await collec.insert(json);
    tmp = await collec.findOne(json);
    T m = fromJson(tmp);

    ret = applyHandler(beforeGet, [m]);
    if (ret != null) return ret;

    return m;
  }

   /// [deleteModel] delete entries inside your collection that match the given filter
   ///
   /// access : DELETE http://<server_ip>:<server_port>/<your>/<api>/<path>/data?filter=<your_filter>
   ///
  @ApiMethod(path: accessKey, method: 'DELETE')
  @Register()
  Future<T> deleteModel({String filter}) async {
    var ret = applyHandler(beforeDelete, [null, filter, null]);
    if (ret != null) return ret;

    T m = fromJson(await collec.remove(_createFilter(filter)));

    ret = applyHandler(afterDelete, [m]);
    if (ret != null) return ret;
    return m;
  }

   /// [deleteModelId] delete a entry inside your collection that match the given id
   ///
   /// access : DELETE http://<server_ip>:<server_port>/<your>/<api>/<path>/data?filter=<your_filter>
   ///
  @ApiMethod(path: "${accessKey}/{id}", method: 'DELETE')
  @Register()
  Future<Map<String, String>> deleteModelId(String id) async {
    var ret = applyHandler(beforeDelete, [id, null, null]);
    if (ret != null) return ret;

    await collec.remove(_createFilter("{}", id: id));

    ret = applyHandler(afterDelete, [null]);
    if (ret != null) return ret;

    return {"status": "OK"};
  }

   /// [updateModel] Update a specific model with the JSON representation provided in the body
   ///
   /// access : PUT http://<server_ip>:<server_port>/<your>/<api>/<path>/data
   ///
  @ApiMethod(path: "${accessKey}/{id}", method: 'PUT')
  @Register()
  Future<T> updateModel(String id, T model) async {
    var ret = applyHandler(beforePut, [null, null, model]);
    if (ret != null) return ret;

    try {
      var tmp = await collec.findOne(_createFilter("{}", id: id));
      tmp.addAll(toJson(model));
      if (tmp["_id"] != null && tmp["_id"] is String)
        tmp["_id"] = StringToId(tmp["_id"]);
      tmp = await collec.save(tmp);
    } catch (e, stackTrace) {
      print("${e}, ${stackTrace}");
      throw new InternalServerError('Error updating data');
    }


    ret = applyHandler(afterPut, [model]);
    if (ret != null) return ret;

    return model;
  }

   /// [updateModel] Update the model with the given ID with the JSON representation provided in the body
   ///
   /// access : PATCH http://<server_ip>:<server_port>/<your>/<api>/<path>/data
   ///
  @ApiMethod(path: "${accessKey}/{id}", method: 'PATCH')
  @Register()
  VoidMessage patchModel(String id, T model) {
    collec.update(_createFilter("{}", id: id), toJson(model));
    return null;
  }
}

/// [StrongToId] convert a HexString format id into a [ObjectId]
ObjectId StringToId (String id) => new ObjectId.fromHexString(id);

/// [GetObjectId] return a [ObjectId] from [id]
///
/// [GetObjectId] will return the [ObjectId] id representation of [id].
///  * If id is an [ObjectId], it will return id
///  * If id is a [String], it will return the [ObjectId] conversion of the [String]
ObjectId GetObjectId (var id) => id is ObjectId ? id : StringToId(id);

/// [GetStringId] return a [String] representation of [id]
///
/// [GetStringId] will return the [String] id representation of [id].
///  * If id is an [String], it will return id
///  * If id is a [ObjectId], it will return the hex [String] representation of the [ObjectId]
String GetStringId (var id) => id is ObjectId ? IdToHexString(id) : id;

/// [IdToHexString] convert a [ObjectId] to a [String]
String IdToHexString (ObjectId id) => id.toHexString();