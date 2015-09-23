# Changelog

## 0.1.0
- **GET /data** -> returns the list of data in the collection
- **GET /data/:id** -> return a element from its id in the collection
- **POST /data** -> Create a new entry in the collection
- **PUT /data** -> Update a entry in the collection
- **DELETE /data** -> Delete entries that match the filter in the collection
- **DELETE /data/:id** -> Delete the entry that match the id in the collection
- **PATCH /data/:id** -> Update some filed of the entry specified by :id
- Provide filter syntax base on [mongo_dart]() filters