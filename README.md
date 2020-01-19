# serverless-nim-sample
A sample REST API running on Nim/Serverless Framework/DynamoDB

## Usage

Invoke locally: `sls invoke local -f FUNCTION_NAME --data {} --context {}`

Deploy: `sls deploy -f FUNCTION_NAME`

Invoke: `sls invoke -f FUNCTION_NAME --data {}`

# TODO
- [ ] `serverless-offline` with local DynamoDB
- [ ] local integration tests against local DynamoDB
- [ ] CI/CD
