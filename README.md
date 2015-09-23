# rpc_mongo_mapper
Dart library to provide CRUD operation on a mongodb with rpc

## Features

MongoMapper is a mongodb mapper for [rpc](https://pub.dartlang.org/packages/rpc) package.

It's provide simple operation on the collection [MongoMapper.collec] like :

- **GET /data** -> returns the list of data in the collection
- **GET /data/:id** -> return a element from its id in the collection
- **POST /data** -> Create a new entry in the collection
- **PUT /data** -> Update a entry in the collection
- **DELETE /data** -> Delete entries that match the filter in the collection
- **DELETE /data/:id** -> Delete the entry that match the id in the collection
- **PATCH /data/:id** -> Update some filed of the entry specified by :id

##### Note
the 'data' at the end can't be directly change at the moment, due the the need of a compile time constant.

## Example

```dart

// ...

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

// your main

```

## Filters

The filter syntax use is a Map with each key represent a field name inside the collection then :

- a value, so the '.eq' matcher will be use
- a map of matcher with their parameters

example:

- To filter age greater than 30 and lower than 45 the filter will be write :

  `?filter={"age":{"gt":"30","lt":"45"}}`

- If we want only age equal to 42:

  `?filter={"age":"42"}`

the available filter are :

* 'gte' -> greater than
* 'gte' -> greater or equal to
* 'lt' -> lower than
* 'lte' -> lower or equal to
* 'eq' -> equal to
* 'ne' -> not equal to
* 'match' -> match the given regexp

## Authors
- Kevin PLATEL <platel.kevin@gmail.com>
