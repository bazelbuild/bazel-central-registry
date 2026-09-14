const assert = require("assert");
const path = require("path");

// rules_js runs from the output tree, where hello.node (a generated file) sits
// next to the copied entry point.
const addon = require(path.join(__dirname, "hello.node"));

const expected = "hello from node-addon-api";
const actual = addon.hello();

assert.strictEqual(
  actual,
  expected,
  `addon.hello() returned "${actual}", expected "${expected}"`,
);

console.log("addon test passed:", actual);
