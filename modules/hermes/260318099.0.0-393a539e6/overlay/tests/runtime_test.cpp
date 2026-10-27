#include <hermes/hermes.h>

#include <iostream>
#include <memory>

int main() {
  // JSError retains runtime values until its catch handler finishes.
  std::unique_ptr<facebook::hermes::HermesRuntime> runtime;
  try {
    runtime = facebook::hermes::makeHermesRuntime();
    auto result = runtime->evaluateJavaScript(
        std::make_shared<facebook::jsi::StringBuffer>(
            "JSON.stringify([1, 2].map(x => x + 1)) === '[2,3]' && "
            "Promise.resolve(42) instanceof Promise && "
            "/\\p{Letter}/u.test('A')"),
        "smoke.js");
    auto proxyResult = runtime->evaluateJavaScript(
        std::make_shared<facebook::jsi::StringBuffer>(R"JS(
(function () {
  function check(condition, message) {
    if (!condition) throw new Error(message);
  }
  let reads = 0;
  const prototype = {};
  const newTarget = new Proxy(function Target() {}, {
    get(target, key, receiver) {
      if (key === 'prototype') { reads++; return prototype; }
      return Reflect.get(target, key, receiver);
    }
  });
  const returned = {};
  const target = function Target() {};
  const trapped = new Proxy(target, {
    construct(actual, args, actualNewTarget) {
      check(actual === target && actualNewTarget === newTarget, 'construct targets');
      check(args.length === 2 && args[0] === 1 && args[1] === 2, 'construct arguments');
      return returned;
    }
  });
  check(Reflect.construct(trapped, [1, 2], newTarget) === returned, 'trap result');
  check(reads === 0, 'construct trap must not read newTarget.prototype');

  const order = [];
  const orderedNewTarget = new Proxy(function Target() {}, {
    get(target, key, receiver) {
      if (key === 'prototype') order.push('prototype');
      return Reflect.get(target, key, receiver);
    }
  });
  const forwarded = new Proxy(function Target() { this.value = 42; }, {
    get construct() { order.push('trap'); return undefined; }
  });
  const instance = Reflect.construct(forwarded, [], orderedNewTarget);
  check(instance.value === 42, 'forwarded base receiver');
  check(Object.getPrototypeOf(instance) === orderedNewTarget.prototype, 'forwarded prototype');
  check(order.slice(0, 2).join(',') === 'trap,prototype', 'trap lookup before allocation');

  reads = 0;
  class Derived extends null {
    constructor() { return Object.create(new.target.prototype); }
  }
  const derived = new Proxy(Derived, {});
  check(Object.getPrototypeOf(Reflect.construct(derived, [], newTarget)) === prototype,
        'forwarded derived receiver');
  check(reads === 1, 'derived constructor owns prototype access');

  reads = 0;
  const nested = new Proxy(new Proxy(function Target() {}, {}), {});
  check(Object.getPrototypeOf(Reflect.construct(nested, [], newTarget)) === prototype,
        'nested proxy prototype');
  check(reads === 1, 'nested proxies allocate once');
  return true;
})()
)JS"),
        "proxy-construction.js");
    return result.isBool() && result.getBool() && proxyResult.isBool() &&
            proxyResult.getBool() ? 0 : 1;
  } catch (const std::exception &error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
