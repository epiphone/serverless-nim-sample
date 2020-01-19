import asyncdispatch, atoz/dynamodb_20120810, awslambda, httpclient, json, os

let
  URLS_TABLE_NAME = getEnv("URLS_TABLE_NAME")
  URL_INDEX_NAME = getEnv("URL_INDEX_NAME")

proc handler(event: JsonNode, context: LambdaContext): Future[JsonNode] {.async.} =
  let url = event{"queryStringParameters", "url"}.getStr()
  if url == "":
    let body = %* {"message": "query parameter `url` required"}
    return %* {"statusCode": 400, "body": $body}

  let queryBody = %* {
    "TableName": URLS_TABLE_NAME,
    "IndexName": URL_INDEX_NAME,
    "KeyConditionExpression": "#url = :url",
    "ExpressionAttributeNames": {"#url": "url"},
    "ExpressionAttributeValues": {":url": {"S": url}},
    "ProjectionExpression": "id",
    "Limit": 1}

  let
    headers = %* {"X-Amz-Security-Token": os.getEnv("AWS_SESSION_TOKEN")}
    request = query.call(nil, nil, headers, nil, queryBody)
    response = await request.issueRequest()

  if response.code.is2xx:
    return %* {"statusCode": 200, "body": await response.body}
  else:
    raise newException(Exception, await response.body)

  return %* {"statusCode": 201, "body": $event}


when isMainModule:
  startLambda(proc (event: JsonNode, context: LambdaContext): JsonNode = waitFor handler(
      event, context))
