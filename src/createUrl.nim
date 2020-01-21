import asyncdispatch, atoz/dynamodb_20120810, awslambda, httpclient, json, nanoid, os

let
  URLS_TABLE_NAME = getEnv("URLS_TABLE_NAME")
  URL_INDEX_NAME = getEnv("URL_INDEX_NAME")

proc handler(event: JsonNode, context: LambdaContext): Future[JsonNode] {.async.} =
  ## Return short URL if already shortened; otherwise create a new short URL.
  let url = event{"queryStringParameters", "url"}.getStr()
  if url == "":
    let body = %* {"message": "query parameter `url` required"}
    return %* {"statusCode": 400, "body": $body}

  let
    queryParams = %* {
      "TableName": URLS_TABLE_NAME,
      "IndexName": URL_INDEX_NAME,
      "KeyConditionExpression": "#url = :url",
      "ExpressionAttributeNames": {"#url": "url"},
      "ExpressionAttributeValues": {":url": {"S": url}},
      "ProjectionExpression": "id",
      "Limit": 1}
    queryResponse = await query.call(queryParams).issueRequest()

  if not queryResponse.code.is2xx:
    raise newException(Exception, await queryResponse.body)

  let body = (await queryResponse.body).parseJson()

  if body["Count"].getInt() > 0:
    return %* {"statusCode": 200, "body": $body["Items"][0]}

  let
    putParams = %* {
      "TableName": URLS_TABLE_NAME,
      "Item": {
        "id": {"S": nanoid.generate(size=7)},
        "url": {"S": url},
        "hits": {"M": {}}
      }
    }
    putResponse = await putItem.call(putParams).issueRequest()

  if not putResponse.code.is2xx:
    raise newException(Exception, await putResponse.body)

  return %* {"statusCode": 201, "body": $putParams}


when isMainModule:
  startLambda(proc (event: JsonNode, context: LambdaContext): JsonNode = waitFor handler(event, context))
