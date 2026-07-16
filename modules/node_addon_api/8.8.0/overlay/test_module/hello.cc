#include <napi.h>

namespace {

Napi::String Hello(const Napi::CallbackInfo& info) {
  return Napi::String::New(info.Env(), "hello from node-addon-api");
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("hello", Napi::Function::New(env, Hello));
  return exports;
}

}  // namespace

NODE_API_MODULE(hello, Init)
