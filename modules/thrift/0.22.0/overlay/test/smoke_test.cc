#include <thrift/TConfiguration.h>
#include <thrift/protocol/TCompactProtocol.h>
#include <thrift/transport/TBufferTransports.h>

#include <cstdint>
#include <memory>
#include <string>

int main() {
  auto configuration = std::make_shared<apache::thrift::TConfiguration>();
  auto transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>(configuration);
  apache::thrift::protocol::TCompactProtocol protocol(transport);

  protocol.writeI32(42);
  protocol.writeString("apache-thrift");

  std::int32_t number = 0;
  std::string text;
  protocol.readI32(number);
  protocol.readString(text);

  return number == 42 && text == "apache-thrift" ? 0 : 1;
}
