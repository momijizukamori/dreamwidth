const $RefParser = require("@apidevtools/json-schema-ref-parser");
const YAML = require('yaml');

$RefParser.dereference("icons_all.yaml", (err, schema) => {
  if (err) {
    console.error(err);
  }
  else {
    // `schema` is just a normal JavaScript object that contains your entire JSON Schema,
    // including referenced files, combined into a single object
    console.log(YAML.stringify(schema));
  }
})
